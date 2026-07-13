import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/glass_theme.dart';

class VisitorQRScreen extends StatelessWidget {
  final String qrToken;
  final String officerName;
  final String purpose;
  final String date;

  const VisitorQRScreen({
    super.key,
    required this.qrToken,
    required this.officerName,
    required this.purpose,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Your Gate Pass',
            style: TextStyle(color: GlassTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: GlassTheme.textPrimary),
      ),
      body: Container(
        decoration: GlassTheme.backgroundGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.shieldCheck,
                            size: 40, color: Colors.green),
                        const SizedBox(height: 12),
                        const Text(
                          'Appointment Approved',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: GlassTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Show this QR code at the gate',
                          style: TextStyle(
                              fontSize: 14, color: GlassTheme.textSecondary),
                        ),
                        const SizedBox(height: 24),

                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: GlassTheme.primaryViolet
                                    .withValues(alpha: 0.15),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: qrToken,
                            version: QrVersions.auto,
                            size: 220,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.circle,
                              color: GlassTheme.primaryViolet,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: GlassTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Appointment details
                        _detailRow(LucideIcons.briefcase, 'Officer', officerName),
                        const SizedBox(height: 12),
                        _detailRow(LucideIcons.fileText, 'Purpose', purpose),
                        const SizedBox(height: 12),
                        _detailRow(LucideIcons.calendar, 'Date', date),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: GlassTheme.textSecondary),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(
                color: GlassTheme.textSecondary,
                fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: GlassTheme.textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
