import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/glass_theme.dart';

class GateResultScreen extends StatefulWidget {
  final String qrToken;

  const GateResultScreen({super.key, required this.qrToken});

  @override
  State<GateResultScreen> createState() => _GateResultScreenState();
}

class _GateResultScreenState extends State<GateResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isValid = false;
  String _message = '';
  String _visitorName = '';
  String _purpose = '';
  String _date = '';

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _verifyQR();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _verifyQR() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.101.199:8000/verify/qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qr_token': widget.qrToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _isValid = data['valid'] == true;
          _message = data['message'] ?? '';
          if (_isValid && data['appointment'] != null) {
            final appt = data['appointment'];
            _visitorName = appt['visitor']?['full_name'] ?? 'Unknown';
            _purpose = appt['purpose'] ?? '';
            _date = appt['requested_date'] ?? '';
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _isValid = false;
          _message = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isValid = false;
        _message = 'Connection failed: $e';
      });
    }
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Verification Result',
            style: TextStyle(color: GlassTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: GlassTheme.textPrimary),
      ),
      body: Container(
        decoration: GlassTheme.backgroundGradient,
        child: SafeArea(
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: GlassTheme.primaryViolet)
                : _buildResult(),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final statusColor = _isValid ? Colors.green : Colors.red;
    final statusIcon = _isValid ? LucideIcons.circleCheck : LucideIcons.circleX;
    final statusLabel = _isValid ? 'ACCESS GRANTED' : 'ACCESS DENIED';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GlassContainer(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.1),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.4), width: 3),
                ),
                child: Icon(statusIcon, size: 50, color: statusColor),
              ),
              const SizedBox(height: 20),

              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: GlassTheme.textSecondary),
              ),

              if (_isValid) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _detailRow(LucideIcons.user, 'Visitor', _visitorName),
                const SizedBox(height: 12),
                _detailRow(LucideIcons.fileText, 'Purpose', _purpose),
                const SizedBox(height: 12),
                _detailRow(LucideIcons.calendar, 'Date', _date),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.primaryViolet,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Scan Another',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
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
