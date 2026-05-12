import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class ReportContentRequest {
  const ReportContentRequest({
    required this.reason,
    this.description,
  });

  final ReportReason reason;
  final String? description;
}

Future<ReportContentRequest?> showReportContentDialog(
  BuildContext context, {
  required String title,
}) {
  return showDialog<ReportContentRequest>(
    context: context,
    builder: (ctx) => _ReportContentDialog(title: title),
  );
}

class _ReportContentDialog extends StatefulWidget {
  const _ReportContentDialog({required this.title});

  final String title;

  @override
  State<_ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends State<_ReportContentDialog> {
  ReportReason _reason = ReportReason.spam;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final description = _descriptionController.text.trim();
    Navigator.pop(
      context,
      ReportContentRequest(
        reason: _reason,
        description: description.isEmpty ? null : description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<ReportReason>(
              key: ValueKey(_reason),
              initialValue: _reason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: ReportReason.values
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(reportReasonLabel(option)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _reason = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Submit report'),
        ),
      ],
    );
  }
}
