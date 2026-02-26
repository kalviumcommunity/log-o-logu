import 'package:flutter/material.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';

/// Logs tab — shows a placeholder for the guard activity/entry log.
class GuardLogsTab extends StatelessWidget {
  const GuardLogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entry Logs',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlack,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'A history of visitor entries and exits',
              style: TextStyle(color: AppTheme.greyText),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 72,
                      color: AppTheme.greyText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Logs coming soon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.greyText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Entry & exit history will appear here\nonce the feature is enabled.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
