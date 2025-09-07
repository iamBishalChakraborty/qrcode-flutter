import 'package:flutter/material.dart';

import '../models/scan_item.dart';
import 'scanner_tab.dart';
import 'generate_tab.dart';
import 'history_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final GlobalKey<HistoryTabState> _historyKey = GlobalKey<HistoryTabState>();

  void _onItemSaved(ScanItem item) {
    _historyKey.currentState?.refresh();
    final preview = item.content.length > 30 ? '${item.content.substring(0, 30)}…' : item.content;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to history: $preview')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ScannerTab(onSaved: _onItemSaved),
      GenerateTab(onSaved: _onItemSaved),
      HistoryTab(key: _historyKey),
    ];

    final titles = ['Scan', 'Generate', 'History'];

    return Scaffold(
      appBar: AppBar(
        title: Text('QR & Barcode • ${titles[_index]}'),
        actions: [
          if (_index == 2)
            IconButton(
              tooltip: 'Clear history',
              onPressed: () async {
                await _historyKey.currentState?.clearAll();
              },
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.qr_code_2), label: 'Generate'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}