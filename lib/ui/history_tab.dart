import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../data/history_repository.dart';
import '../models/scan_item.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => HistoryTabState();
}

class HistoryTabState extends State<HistoryTab> {
  List<ScanItem> _items = [];
  final _fmt = DateFormat.yMMMd().add_jm();

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final loaded = await HistoryRepository.load();
    setState(() => _items = loaded);
  }

  Future<void> clearAll() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This will remove all saved items.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      await HistoryRepository.clear();
      await refresh();
      messenger.showSnackBar(const SnackBar(content: Text('History cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.history, size: 96, color: Colors.grey),
            SizedBox(height: 8),
            Text('No history yet'),
            SizedBox(height: 4),
            Text('Scan a code or generate a QR to save here', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, index) {
        final item = _items[index];
        return Dismissible(
          key: ValueKey('${item.timestamp.toIso8601String()}_${item.content.hashCode}'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) async {
            final messenger = ScaffoldMessenger.of(context);
            await HistoryRepository.removeAt(index);
            setState(() => _items.removeAt(index));
            messenger.showSnackBar(const SnackBar(content: Text('Deleted')));
          },
          child: ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: Text(
              item.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${_fmt.format(item.timestamp)} • ${item.format}'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'copy':
                    final messenger = ScaffoldMessenger.of(ctx);
                    await Clipboard.setData(ClipboardData(text: item.content));
                    messenger.showSnackBar(const SnackBar(content: Text('Copied')));
                    break;
                  case 'share':
                    await Share.share(item.content);
                    break;
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem<String>(value: 'copy', child: ListTile(leading: Icon(Icons.copy), title: Text('Copy'))),
                PopupMenuItem<String>(value: 'share', child: ListTile(leading: Icon(Icons.share), title: Text('Share'))),
              ],
            ),
          ),
        );
      },
    );
  }
}