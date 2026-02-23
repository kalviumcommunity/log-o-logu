// lib/features/invite/presentation/invite_qr_screen.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:log_o_logu/features/invite/domain/invite_model.dart';
import 'package:log_o_logu/features/invite/presentation/widgets/invite_qr_code_card.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';

class InviteQRScreen extends StatefulWidget {
  final InviteModel invite;

  const InviteQRScreen({super.key, required this.invite});

  @override
  State<InviteQRScreen> createState() => _InviteQRScreenState();
}

class _InviteQRScreenState extends State<InviteQRScreen> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _sharePass() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/invite_qr.png').create();
      await imagePath.writeAsBytes(pngBytes);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Visitor Pass for ${widget.invite.guestName}.',
      );
    } catch (e) {
      debugPrint('Error sharing invite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Visitor Pass',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.primaryBlack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            RepaintBoundary(
              key: _qrKey,
              child: InviteQRCodeCard(invite: widget.invite),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important Note',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This pass is valid for one-time entry and exit. Please keep your screen brightness high when scanning.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton.icon(
            onPressed: _sharePass,
            icon: const Icon(Icons.share, size: 20),
            label: const Text('Share Pass'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
