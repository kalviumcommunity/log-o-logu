// lib/features/invite/presentation/widgets/invite_qr_code_card.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:log_o_logu/features/invite/domain/invite_model.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class InviteQRCodeCard extends StatefulWidget {
  final InviteModel invite;

  const InviteQRCodeCard({super.key, required this.invite});

  @override
  State<InviteQRCodeCard> createState() => _InviteQRCodeCardState();
}

class _InviteQRCodeCardState extends State<InviteQRCodeCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update UI every second to reflect remaining time / expiry
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getTimeRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.invite.validUntil)) {
       return 'Expired';
    }
    if (now.isBefore(widget.invite.validFrom)) {
      final diff = widget.invite.validFrom.difference(now);
      return 'Starts in ${_formatDuration(diff)}';
    }
    final diff = widget.invite.validUntil.difference(now);
    return 'Expires in ${_formatDuration(diff)}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = widget.invite.isExpired;
    final isValid = widget.invite.isValid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visitor Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Colors.grey, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VISITOR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      Text(
                        widget.invite.guestName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpired 
                        ? Colors.red.withValues(alpha: 0.1)
                        : isValid
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isExpired 
                            ? Colors.red.withValues(alpha: 0.2)
                            : isValid
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle, 
                        size: 8, 
                        color: isExpired 
                            ? Colors.red 
                            : isValid 
                                ? Colors.green 
                                : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isExpired 
                            ? 'EXPIRED' 
                            : isValid 
                                ? 'VALID' 
                                : widget.invite.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isExpired 
                              ? Colors.red 
                              : isValid 
                                  ? Colors.green 
                                  : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Expiry / Countdown logic
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              _getTimeRemaining(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isExpired ? Colors.red : AppTheme.primaryBlue,
              ),
            ),
          ),
          
          // QR Code Section
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dashed Corners
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CustomPaint(
                    painter: _QRFramePainter(),
                  ),
                ),
                // The actual QR
                Opacity(
                  opacity: isExpired ? 0.1 : 1.0,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: widget.invite.inviteId,
                      version: QrVersions.auto,
                      size: 180.0,
                    ),
                  ),
                ),
                if (isExpired)
                  const Text(
                    'QR EXPIRED',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Text(
              'Valid until ${DateFormat('MMM dd, hh:mm a').format(widget.invite.validUntil)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QRFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const length = 40.0;
    
    // Top Left
    canvas.drawLine(const Offset(0, 0), const Offset(length, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, length), paint);
    
    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - length, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);
    
    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - length), paint);
    
    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - length, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
