import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/glass_theme.dart';
import 'visitor_login_screen.dart';
import 'visitor_registration_screen.dart';
import '../../officer/presentation/officer_dashboard.dart';
import '../../gate/presentation/gate_scanner_screen.dart';
import '../../admin/presentation/admin_login_screen.dart';

class RolePortalScreen extends StatelessWidget {
  const RolePortalScreen({super.key});

  void _navigateToLogin(BuildContext context, String role) {
    if (role == 'visitor') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VisitorLoginScreen()),
      );
    } else if (role == 'officer') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OfficerDashboardScreen()),
      );
    } else if (role == 'security') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GateScannerScreen()),
      );
    } else if (role == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$role login not implemented yet')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: GlassTheme.backgroundGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.8),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: GlassTheme.primaryViolet.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.shieldCheck, size: 50, color: GlassTheme.primaryViolet),
                ),
                const SizedBox(height: 20),
                const Text(
                  'BCGHQ-VMS',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: GlassTheme.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bangladesh Coast Guard Headquarters\nVisitor Management System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GlassTheme.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 50),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildRoleButton(
                        icon: LucideIcons.user,
                        label: 'Visitor Login',
                        isPrimary: true,
                        onTap: () => _navigateToLogin(context, 'visitor'),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleButton(
                        icon: LucideIcons.userPlus,
                        label: 'Visitor Register',
                        isPrimary: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VisitorRegistrationScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildRoleButton(
                        icon: LucideIcons.briefcase,
                        label: 'Officer Portal',
                        isPrimary: false,
                        onTap: () => _navigateToLogin(context, 'officer'),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleButton(
                        icon: LucideIcons.scanLine,
                        label: 'Security Scanner',
                        isPrimary: false,
                        onTap: () => _navigateToLogin(context, 'security'),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleButton(
                        icon: LucideIcons.shieldAlert,
                        label: 'Admin Login',
                        isPrimary: false,
                        onTap: () => _navigateToLogin(context, 'admin'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isPrimary ? GlassTheme.primaryViolet : Colors.white.withValues(alpha: 0.6),
          border: !isPrimary ? Border.all(color: Colors.white.withValues(alpha: 0.9)) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isPrimary
              ? [BoxShadow(color: GlassTheme.primaryViolet.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isPrimary ? Colors.white : GlassTheme.primaryViolet),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : GlassTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
