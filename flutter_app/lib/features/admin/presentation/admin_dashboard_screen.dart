import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/glass_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reports;
  
  // Officer creation form
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('http://192.168.101.199:8000/admin/reports'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _reports = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching reports: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createOfficer() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    final response = await http.post(
      Uri.parse('http://192.168.101.199:8000/admin/officers'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'full_name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'department': _deptController.text,
      }),
    );

    if (response.statusCode == 201) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Officer Created Successfully')));
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _deptController.clear();
        _fetchReports();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1B233D),
          bottom: const TabBar(
            indicatorColor: GlassTheme.primaryViolet,
            tabs: [
              Tab(icon: Icon(LucideIcons.barChart2), text: 'Reports'),
              Tab(icon: Icon(LucideIcons.userPlus), text: 'Create Officer'),
              Tab(icon: Icon(LucideIcons.shieldAlert), text: 'Blacklist'),
            ],
          ),
        ),
        body: Container(
          decoration: GlassTheme.backgroundGradient,
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildReportsTab(),
                  _buildCreateOfficerTab(),
                  _buildBlacklistTab(),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    if (_reports == null) return const Center(child: Text("Failed to load reports", style: TextStyle(color: Colors.white)));
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Visitors', _reports!['total_visitors'].toString(), LucideIcons.users)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Total Officers', _reports!['total_officers'].toString(), LucideIcons.briefcase)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Pending', _reports!['pending_appointments'].toString(), LucideIcons.clock, color: Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Accepted', _reports!['accepted_appointments'].toString(), LucideIcons.checkCircle, color: Colors.green)),
          ],
        ),
        const SizedBox(height: 24),
        const Text("Today's Gate Log", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...(_reports!['daily_appointments'] as List).map((app) {
          return GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app['visitor']?['full_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("To see: ${app['officer']?['full_name']}", style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Entry: ${app['entry_time'] != null ? app['entry_time'].toString().substring(11, 16) : 'N/A'}", style: const TextStyle(color: Colors.greenAccent)),
                    Text("Exit: ${app['exit_time'] != null ? app['exit_time'].toString().substring(11, 16) : 'N/A'}", style: const TextStyle(color: Colors.redAccent)),
                  ],
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color? color}) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color ?? GlassTheme.primaryViolet, size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCreateOfficerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Register New Officer", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: GlassTheme.inputDecoration('Full Name', LucideIcons.user)),
            const SizedBox(height: 16),
            TextFormField(controller: _emailController, style: const TextStyle(color: Colors.white), decoration: GlassTheme.inputDecoration('Email Address', LucideIcons.mail)),
            const SizedBox(height: 16),
            TextFormField(controller: _passwordController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: GlassTheme.inputDecoration('Temporary Password', LucideIcons.lock)),
            const SizedBox(height: 16),
            TextFormField(controller: _deptController, style: const TextStyle(color: Colors.white), decoration: GlassTheme.inputDecoration('Department / Wing', LucideIcons.building)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _createOfficer,
                style: GlassTheme.primaryButtonStyle,
                child: const Text('Create Officer Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlacklistTab() {
    if (_reports == null) return const SizedBox();
    final blacklist = _reports!['blacklisted_users'] as List;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: blacklist.length,
      itemBuilder: (context, index) {
        final user = blacklist[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(LucideIcons.userX, color: Colors.redAccent, size: 40),
              title: Text(user['full_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(user['email'], style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              trailing: const Chip(label: Text('BLACKLISTED'), backgroundColor: Colors.red),
            ),
          ),
        );
      },
    );
  }
}
