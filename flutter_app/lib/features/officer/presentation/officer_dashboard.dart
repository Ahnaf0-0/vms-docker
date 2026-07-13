import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/glass_theme.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  // Mock Data
  final List<Map<String, dynamic>> _appointments = [
    {
      "id": 1,
      "visitor_name": "Ahnaf",
      "purpose": "Security Audit",
      "date": "14-07-2026",
      "time": "10:00 AM",
      "status": "Pending",
      "is_blacklisted": false,
    },
    {
      "id": 2,
      "visitor_name": "Rahim",
      "purpose": "Vendor Delivery",
      "date": "14-07-2026",
      "time": "11:30 AM",
      "status": "Approved",
      "is_blacklisted": false,
    },
    {
      "id": 3,
      "visitor_name": "Suspicious User",
      "purpose": "Unclear",
      "date": "15-07-2026",
      "time": "02:00 PM",
      "status": "Pending",
      "is_blacklisted": true,
    }
  ];

  void _updateStatus(int id, String newStatus) {
    setState(() {
      final index = _appointments.indexWhere((app) => app['id'] == id);
      if (index != -1) {
        _appointments[index]['status'] = newStatus;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Appointment $newStatus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Officer Dashboard', style: TextStyle(color: GlassTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: GlassTheme.textPrimary),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Container(
        decoration: GlassTheme.backgroundGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointments',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: GlassTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final app = _appointments[index];
                      return _buildAppointmentCard(app);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> app) {
    Color statusColor;
    switch (app['status']) {
      case 'Approved':
        statusColor = Colors.green;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      case 'Postponed':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    app['visitor_name'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlassTheme.textPrimary),
                  ),
                  if (app['is_blacklisted']) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.alertTriangle, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text('Blacklisted', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  app['status'],
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 16, color: GlassTheme.textSecondary),
              const SizedBox(width: 8),
              Text('${app['date']} at ${app['time']}', style: const TextStyle(color: GlassTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.fileText, size: 16, color: GlassTheme.textSecondary),
              const SizedBox(width: 8),
              Text(app['purpose'], style: const TextStyle(color: GlassTheme.textSecondary)),
            ],
          ),
          
          if (app['status'] == 'Pending') ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _updateStatus(app['id'], 'Approved'),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _updateStatus(app['id'], 'Cancelled'),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _updateStatus(app['id'], 'Postponed'),
                    child: const Text('Postpone'),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
