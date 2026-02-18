import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:proballdev/features/report/widgets/report_card.dart';
import 'package:proballdev/models/report_content.dart';

/// Report card with Share button that exports a screenshot to Photos.
class ReportCardWithShare extends StatefulWidget {
  const ReportCardWithShare({
    super.key,
    required this.theme,
    required this.content,
    this.showDebugPanel = false,
  });

  final ThemeData theme;
  final ReportContent content;
  final bool showDebugPanel;

  @override
  State<ReportCardWithShare> createState() => _ReportCardWithShareState();
}

class _ReportCardWithShareState extends State<ReportCardWithShare> {
  final GlobalKey _repaintKey = GlobalKey();

  Future<void> _onShare() async {
    if (kIsWeb) {
      _showSnackBar('Save to Photos is not available on web.');
      return;
    }
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      _showSnackBar('Could not capture report.');
      return;
    }

    try {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showSnackBar('Could not create image.');
        return;
      }
      final pngBytes = byteData.buffer.asUint8List();

      final permission = Platform.isAndroid ? Permission.storage : Permission.photos;
      var status = await permission.status;
      if (status.isDenied) {
        status = await permission.request();
      }
      if (!status.isGranted && !status.isLimited) {
        _showSnackBar(
          'Photo access is needed to save. Please enable in Settings.',
        );
        return;
      }

      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: 'proball_report_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (result['isSuccess'] == true) {
          _showSnackBar('Saved to Photos');
        } else {
          _showSnackBar(result['error']?.toString() ?? 'Failed to save.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to save: ${e.toString().split('\n').first}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _repaintKey,
          child: ReportCard(
            theme: widget.theme,
            content: widget.content,
            showDebugPanel: widget.showDebugPanel,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _onShare,
          icon: const Icon(Icons.share_rounded, size: 20),
          label: const Text('Share'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}
