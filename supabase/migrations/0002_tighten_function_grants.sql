-- Tighten EXECUTE grants on SECURITY DEFINER functions (security advisor cleanup).
--
-- Supabase grants EXECUTE on public functions directly to the `anon` and
-- `authenticated` roles (via default privileges), so revoking from PUBLIC alone
-- isn't enough — we revoke from those roles too, then grant back only what's needed.
--
--   * trigger functions (handle_new_user, auto_confirm_user): not callable at all;
--     triggers run them regardless of EXECUTE grants.
--   * helpers/RPCs (current_family_id, create_family, join_family): only signed-in
--     users need them (current_family_id is used inside RLS policies).

revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.auto_confirm_user() from public, anon, authenticated;

revoke all on function public.current_family_id() from public, anon, authenticated;
grant execute on function public.current_family_id() to authenticated;

revoke all on function public.create_family(text) from public, anon, authenticated;
grant execute on function public.create_family(text) to authenticated;

revoke all on function public.join_family(text) from public, anon, authenticated;
grant execute on function public.join_family(text) to authenticated;
