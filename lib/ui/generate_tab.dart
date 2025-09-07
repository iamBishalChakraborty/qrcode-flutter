import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../data/history_repository.dart';
import '../models/scan_item.dart';

class GenerateTab extends StatefulWidget {
  const GenerateTab({super.key, required this.onSaved});

  final void Function(ScanItem item) onSaved;

  @override
  State<GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends State<GenerateTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied text')));
  }

  Future<void> _share() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await Share.share(text);
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Capture UI handles before awaiting to avoid using BuildContext across async gaps
    final messenger = ScaffoldMessenger.of(context);
    final focus = FocusScope.of(context);

    final item = ScanItem(content: text, format: 'QR', timestamp: DateTime.now());
    await HistoryRepository.add(item);
    widget.onSaved(item);

    // Reset text and QR preview, close keyboard, and show confirmation
    _controller.clear();
    setState(() {});
    focus.unfocus();
    messenger.showSnackBar(const SnackBar(content: Text('Saved to history')));
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim();
    final canGenerate = text.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Text / URL',
              border: OutlineInputBorder(),
              hintText: 'Enter text to generate QR code',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (canGenerate)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: text,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
            )
          else
            Center(
              child: Opacity(
                opacity: 0.6,
                child: Column(
                  children: const [
                    Icon(Icons.qr_code_2, size: 120),
                    SizedBox(height: 8),
                    Text('QR preview will appear here'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canGenerate ? _copy : null,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canGenerate ? _share : null,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canGenerate ? _save : null,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save to history'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}