-- Family Spend — initial schema
--
-- Data model for a lightweight, family-only money tracker.
--   families  : a household, identified by a short invite code
--   profiles  : one row per auth user, linked to a family
--   entries   : the shared ledger — expenses and transfers
--
-- Auth is "name + password" with no email verification: the app maps a name to
-- a synthetic email under the hood, and a BEFORE INSERT trigger pre-confirms the
-- account so signup returns a usable session immediately.

-- =========================================================
-- Tables
-- =========================================================

create table if not exists public.families (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  invite_code text not null unique default upper(substr(md5(random()::text), 1, 6)),
  created_at  timestamptz not null default now()
);

create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  family_id    uuid references public.families(id) on delete set null,
  display_name text not null,
  created_at   timestamptz not null default now()
);

create table if not exists public.entries (
  id           uuid primary key default gen_random_uuid(),
  family_id    uuid not null references public.families(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  type         text not null check (type in ('expense', 'transfer')),
  amount       numeric(12, 2) not null check (amount > 0),
  occurred_on  date not null default current_date,
  note         text,
  recipient_id uuid references public.profiles(id) on delete set null,
  photo_url    text,
  created_at   timestamptz not null default now(),
  constraint transfer_needs_recipient
    check (type <> 'transfer' or recipient_id is not null)
);

create index if not exists entries_family_created_idx
  on public.entries (family_id, created_at desc);
create index if not exists profiles_family_idx
  on public.profiles (family_id);

-- =========================================================
-- Helper: the caller's family id.
-- SECURITY DEFINER so it bypasses RLS on profiles, which avoids the
-- infinite recursion you'd get from a policy that reads the same table.
-- =========================================================
create or replace function public.current_family_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select family_id from public.profiles where id = auth.uid();
$$;

-- =========================================================
-- New auth user -> create a profile automatically.
-- display_name comes from the signup metadata (the name the user typed).
-- =========================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'display_name', ''), split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =========================================================
-- Auto-confirm new users (no email verification — it's just for family).
-- Setting email_confirmed_at makes the account usable right away.
-- =========================================================
create or replace function public.auto_confirm_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.email_confirmed_at is null then
    new.email_confirmed_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_auto_confirm on auth.users;
create trigger on_auth_user_auto_confirm
  before insert on auth.users
  for each row execute function public.auto_confirm_user();

-- =========================================================
-- RPCs for creating / joining a family.
-- SECURITY DEFINER so a brand-new user (not yet in any family) can look up a
-- family by invite code and attach themselves, without needing a broad RLS
-- read policy on families.
-- =========================================================
create or replace function public.create_family(family_name text)
returns public.families
language plpgsql
security definer
set search_path = public
as $$
declare
  new_family public.families;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.families (name)
  values (coalesce(nullif(trim(family_name), ''), 'My Family'))
  returning * into new_family;

  update public.profiles
    set family_id = new_family.id
    where id = auth.uid();

  return new_family;
end;
$$;

create or replace function public.join_family(code text)
returns public.families
language plpgsql
security definer
set search_path = public
as $$
declare
  target public.families;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select * into target
    from public.families
    where invite_code = upper(trim(code));

  if target.id is null then
    raise exception 'No family found with invite code %', code;
  end if;

  update public.profiles
    set family_id = target.id
    where id = auth.uid();

  return target;
end;
$$;

-- =========================================================
-- Row level security
-- =========================================================
alter table public.families enable row level security;
alter table public.profiles enable row level security;
alter table public.entries  enable row level security;

-- families: you can see your own family (create/join go through the RPCs above)
drop policy if exists families_select_own on public.families;
create policy families_select_own on public.families
  for select using (id = public.current_family_id());

-- profiles: see yourself and everyone in your family
drop policy if exists profiles_select_self_or_family on public.profiles;
create policy profiles_select_self_or_family on public.profiles
  for select using (id = auth.uid() or family_id = public.current_family_id());

drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles
  for insert with check (id = auth.uid());

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- entries: read anything in your family; only write your own rows
drop policy if exists entries_select_family on public.entries;
create policy entries_select_family on public.entries
  for select using (family_id = public.current_family_id());

drop policy if exists entries_insert_own on public.entries;
create policy entries_insert_own on public.entries
  for insert with check (
    family_id = public.current_family_id() and user_id = auth.uid()
  );

drop policy if exists entries_update_own on public.entries;
create policy entries_update_own on public.entries
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists entries_delete_own on public.entries;
create policy entries_delete_own on public.entries
  for delete using (user_id = auth.uid());

-- =========================================================
-- Realtime: stream new entries to every family member live
-- =========================================================
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'entries'
  ) then
    alter publication supabase_realtime add table public.entries;
  end if;
end $$;

-- =========================================================
-- Storage: receipt photos.
-- Public bucket for simple display via public URL; uploads are restricted to
-- authenticated users writing into their own family's folder (<family_id>/...).
-- =========================================================
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', true)
on conflict (id) do nothing;

drop policy if exists receipts_read_all on storage.objects;
create policy receipts_read_all on storage.objects
  for select using (bucket_id = 'receipts');

drop policy if exists receipts_insert_own_family on storage.objects;
create policy receipts_insert_own_family on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = public.current_family_id()::text
  );

drop policy if exists receipts_delete_own_family on storage.objects;
create policy receipts_delete_own_family on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = public.current_family_id()::text
  );
