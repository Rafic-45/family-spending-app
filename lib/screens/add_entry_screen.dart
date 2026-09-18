import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../format.dart';
import '../models/member.dart';
import '../services/entries_service.dart';

/// Form for logging a new expense or transfer.
class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({
    super.key,
    required this.familyId,
    required this.recipients,
  });

  final String familyId;
  final List<Member> recipients;

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

enum _Type { expense, transfer }

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _entriesService = EntriesService();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  _Type _type = _Type.expense;
  DateTime _date = DateTime.now();
  String? _recipientId;
  Uint8List? _photoBytes;
  String _photoExt = 'jpg';
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 70,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final name = file.name;
    final ext = name.contains('.') ? name.split('.').last : 'jpg';
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _photoExt = ext;
    });
  }

  void _choosePhotoSource() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _snack('Enter a valid amount.');
      return;
    }
    if (_type == _Type.transfer && _recipientId == null) {
      _snack('Choose who you sent it to.');
      return;
    }

    setState(() => _saving = true);
    try {
      String? photoUrl;
      if (_photoBytes != null) {
        photoUrl = await _entriesService.uploadReceipt(
          familyId: widget.familyId,
          bytes: _photoBytes!,
          fileExtension: _photoExt,
        );
      }
      if (_type == _Type.expense) {
        await _entriesService.addExpense(
          familyId: widget.familyId,
          amount: amount,
          date: _date,
          note: _noteController.text,
          photoUrl: photoUrl,
        );
      } else {
        await _entriesService.addTransfer(
          familyId: widget.familyId,
          amount: amount,
          date: _date,
          recipientId: _recipientId!,
          note: _noteController.text,
          photoUrl: photoUrl,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Could not save: $e');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isTransfer = _type == _Type.transfer;
    final noRecipients = isTransfer && widget.recipients.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Add entry')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<_Type>(
                  segments: const [
                    ButtonSegment(
                      value: _Type.expense,
                      icon: Text('💸'),
                      label: Text('Expense'),
                    ),
                    ButtonSegment(
                      value: _Type.transfer,
                      icon: Text('🔄'),
                      label: Text('Transfer'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(formatDateFull(_date)),
                  ),
                ),
                const SizedBox(height: 16),
                if (isTransfer) ...[
                  if (noRecipients)
                    _hint(
                      'No family members to send to yet. Share your invite code '
                      'so someone can join, then transfers will show up here.',
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _recipientId,
                      decoration: const InputDecoration(
                        labelText: 'Sent to',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: widget.recipients
                          .map((m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(m.displayName),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _recipientId = v),
                    ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    hintText:
                        isTransfer ? 'e.g. Allowance' : 'e.g. Groceries',
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                _photoSection(),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: (_saving || noRecipients) ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(_saving ? 'Saving…' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoSection() {
    if (_photoBytes == null) {
      return OutlinedButton.icon(
        onPressed: _choosePhotoSource,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Attach a photo (optional)'),
      );
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            _photoBytes!,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Text('Photo attached')),
        TextButton(
          onPressed: () => setState(() => _photoBytes = null),
          child: const Text('Remove'),
        ),
      ],
    );
  }

  Widget _hint(String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: theme.textTheme.bodyMedium),
    );
  }
}
