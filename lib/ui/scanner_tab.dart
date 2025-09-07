import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/scan_item.dart';
import '../data/history_repository.dart';

class ScannerTab extends StatefulWidget {
  const ScannerTab({super.key, required this.onSaved});

  final void Function(ScanItem item) onSaved;

  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _handlingDetection = false;
  bool _cameraStarted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_handlingDetection) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final raw = barcode.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _handlingDetection = true);
    await _controller.stop();

    final fmt = () {
      try {
        final f = barcode.format;
        final n = f.toString();
        final idx = n.lastIndexOf('.');
        return idx != -1 ? n.substring(idx + 1) : n;
      } catch (_) {
        return 'unknown';
      }
    }();

    final item = ScanItem(content: raw, format: fmt, timestamp: DateTime.now());

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code, size: 20),
                const SizedBox(width: 8),
                Text('Detected (${item.format})', style: Theme.of(ctx).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(ctx);
                    await Clipboard.setData(ClipboardData(text: item.content));
                    messenger.showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                  },
                ),
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share),
                  onPressed: () async {
                    await Share.share(item.content);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              item.content,
              style: Theme.of(ctx).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Save to history'),
                    onPressed: () async {
                      await HistoryRepository.add(item);
                      widget.onSaved(item);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await _controller.start();
    if (mounted) {
      setState(() => _handlingDetection = false);
    }
  }

 Future<bool> _ensureCameraPermission() async {
   final status = await Permission.camera.status;
   if (status.isGranted) return true;

   if (status.isDenied || status.isRestricted || status.isLimited) {
     final result = await Permission.camera.request();
     return result.isGranted;
   }

   if (status.isPermanentlyDenied) {
     // Optionally guide user to settings; return false so UI can show message
     return false;
   }

   return false;
 }

 Future<void> _openCamera() async {
   // Show the scanner and request permission via controller.start()
   setState(() => _cameraStarted = true);
   // Capture messenger before awaiting to avoid using context across async gaps
   final messenger = ScaffoldMessenger.of(context);

   final allowed = await _ensureCameraPermission();
   if (!allowed) {
     messenger.showSnackBar(const SnackBar(content: Text('Camera permission denied')));
     if (mounted) {
       setState(() => _cameraStarted = false);
     }
     return;
   }

   try {
     await _controller.start();
   } catch (_) {
     messenger.showSnackBar(const SnackBar(content: Text('Unable to open camera')));
     if (mounted) {
       setState(() => _cameraStarted = false);
     }
   }
 }

 @override
 Widget build(BuildContext context) {
   if (!_cameraStarted) {
     return Center(
       child: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           const Icon(Icons.qr_code_scanner, size: 120),
           const SizedBox(height: 12),
           const Text('Camera is off'),
           const SizedBox(height: 16),
           ElevatedButton.icon(
             icon: const Icon(Icons.camera_alt),
             label: const Text('Open camera'),
             onPressed: _openCamera,
           ),
         ],
       ),
     );
   }

   return Stack(
     children: [
       MobileScanner(
         controller: _controller,
         onDetect: _handleDetection,
       ),
       Positioned(
         left: 0,
         right: 0,
         bottom: 0,
         child: SafeArea(
           top: false,
           child: Container(
             margin: const EdgeInsets.all(12),
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             decoration: BoxDecoration(
               color: Colors.black.withValues(alpha: 0.4),
               borderRadius: BorderRadius.circular(12),
             ),
             child: Row(
               children: [
                 IconButton(
                   tooltip: 'Toggle torch',
                   color: Colors.white,
                   onPressed: () => _controller.toggleTorch(),
                   icon: const Icon(Icons.flash_on),
                 ),
                 const SizedBox(width: 8),
                 IconButton(
                   tooltip: 'Switch camera',
                   color: Colors.white,
                   onPressed: () => _controller.switchCamera(),
                   icon: const Icon(Icons.cameraswitch),
                 ),
                 const Spacer(),
                 if (_handlingDetection)
                   const Padding(
                     padding: EdgeInsets.symmetric(horizontal: 8.0),
                     child: SizedBox(
                       height: 18,
                       width: 18,
                       child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                     ),
                   ),
               ],
             ),
           ),
         ),
       ),
     ],
   );
 }
}