import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/glass_theme.dart';

class RequestAppointmentScreen extends StatefulWidget {
  const RequestAppointmentScreen({super.key});

  @override
  State<RequestAppointmentScreen> createState() => _RequestAppointmentScreenState();
}

class _RequestAppointmentScreenState extends State<RequestAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedOfficer;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _purposeController = TextEditingController();

  final List<String> _mockOfficers = [
    'Cmdr. Hasan (Security)',
    'Lt. Cmdr. Rahman (Operations)',
    'Capt. Ahmed (Logistics)'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: GlassTheme.primaryViolet,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: GlassTheme.primaryViolet,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null && _selectedOfficer != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment Request Submitted!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Request Appointment', style: TextStyle(color: GlassTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: GlassTheme.textPrimary),
      ),
      body: Container(
        decoration: GlassTheme.backgroundGradient,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Schedule a Visit',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: GlassTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select an officer and time for your visit to BCGHQ.',
                    style: TextStyle(fontSize: 16, color: GlassTheme.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  
                  // Officer Selection
                  DropdownButtonFormField<String>(
                    decoration: GlassTheme.inputDecoration('Select Officer', LucideIcons.user),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: GlassTheme.textPrimary, fontSize: 16),
                    initialValue: _selectedOfficer,
                    items: _mockOfficers.map((String officer) {
                      return DropdownMenuItem<String>(
                        value: officer,
                        child: Text(officer),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedOfficer = newValue;
                      });
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Selection
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: GlassTheme.inputDecoration('Select Date', LucideIcons.calendar),
                      child: Text(
                        _selectedDate == null 
                            ? 'Tap to select date' 
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          color: _selectedDate == null ? GlassTheme.textSecondary : GlassTheme.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Time Selection
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: GlassTheme.inputDecoration('Select Time', LucideIcons.clock),
                      child: Text(
                        _selectedTime == null 
                            ? 'Tap to select time' 
                            : _selectedTime!.format(context),
                        style: TextStyle(
                          color: _selectedTime == null ? GlassTheme.textSecondary : GlassTheme.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Purpose
                  TextFormField(
                    controller: _purposeController,
                    decoration: GlassTheme.inputDecoration('Purpose of Visit', LucideIcons.fileText),
                    style: const TextStyle(color: GlassTheme.textPrimary),
                    maxLines: 3,
                    validator: (value) => value!.isEmpty ? 'Please enter purpose' : null,
                  ),
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlassTheme.primaryViolet,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _submitRequest,
                      child: const Text(
                        'Submit Request',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
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
}
