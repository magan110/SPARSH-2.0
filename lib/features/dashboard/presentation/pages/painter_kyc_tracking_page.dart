// File: lib/report_filter_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A clean, minimalist report filter screen with improved UI/UX
class PainterKycTrackingPage extends StatefulWidget {
  const PainterKycTrackingPage({super.key});
  @override
  State<PainterKycTrackingPage> createState() => _PainterKycTrackingPageState();
}

class _PainterKycTrackingPageState extends State<PainterKycTrackingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // List of report types
  final List<String> _reportTypes = [
    'Zone Wise',
    'Logical State Wise',
    'Area Wise',
    'Employee Wise',
    'Incentive Employee Wise',
    'Incentive Employee Wise Dashboard',
    'Incentive Zonal Casc',
    'Incentive Area Casc',
  ];

  String? _selectedReportType;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();

    // Set default values
    if (_reportTypes.contains('Incentive Employee Wise Dashboard')) {
      _selectedReportType = 'Incentive Employee Wise Dashboard';
    } else {
      _selectedReportType = _reportTypes.first;
    }

    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));
    _startDateController.text = _dateFormatter.format(sevenDaysAgo);
    _endDateController.text = _dateFormatter.format(now);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime initialDate;
    try {
      initialDate = _dateFormatter.parse(controller.text);
    } catch (_) {
      initialDate = DateTime.now();
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = _dateFormatter.format(picked);
      });
    }
  }

  String _formattedTimestamp() {
    DateTime now = DateTime.now();
    String datePart = _dateFormatter.format(now);
    String timePart = DateFormat('HH:mm:ss').format(now);
    return 'As on $datePart at $timePart';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Painter KYC Tracking',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.filter_alt,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Report Filters',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select your report type and date range to generate the report',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Filter Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 600;
                        return isMobile
                            ? _buildMobileLayout()
                            : _buildTabletDesktopLayout();
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Timestamp
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formattedTimestamp(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Report Type Dropdown
        _buildReportTypeDropdown(),
        const SizedBox(height: 20),

        // Date Fields
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                controller: _startDateController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'End Date',
                controller: _endDateController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Go Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleGo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Generate Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletDesktopLayout() {
    return Column(
      children: [
        // Report Type Dropdown
        _buildReportTypeDropdown(),
        const SizedBox(height: 20),

        // Date Fields and Button Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: _buildDateField(
                label: 'Start Date',
                controller: _startDateController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _buildDateField(
                label: 'End Date',
                controller: _endDateController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _handleGo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Go',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedReportType,
          validator:
              (value) => value == null ? 'Please select a report type' : null,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: 'Select report type',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          items:
              _reportTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedReportType = value;
            });
          },
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDate(context, controller),
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select a date';
                }
                return null;
              },
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: 'DD/MM/YYYY',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                suffixIcon: const Icon(
                  Icons.calendar_today,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleGo() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sel = _selectedReportType ?? '(none)';
    final sd = _startDateController.text;
    final ed = _endDateController.text;

    debugPrint('Go pressed → report: $sel, start: $sd, end: $ed');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating report: $sel'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Report Filter Help',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select a report type and date range to generate your report. '
                    'The start date must be before the end date.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
