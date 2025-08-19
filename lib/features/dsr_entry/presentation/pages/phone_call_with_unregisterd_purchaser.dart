import 'dart:io';
import 'package:flutter/material.dart';
import 'package:learning2/core/services/session_manager.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
// Removed direct http/json; now using centralized DsrApiService + DsrEntryDto.
import '../../../../core/services/dsr_api_service.dart';
import 'dsr_entry.dart';

class PhoneCallWithUnregisterdPurchaser extends StatefulWidget {
  const PhoneCallWithUnregisterdPurchaser({super.key});

  @override
  State<PhoneCallWithUnregisterdPurchaser> createState() =>
      _PhoneCallWithUnregisterdPurchaserState();
}

class _PhoneCallWithUnregisterdPurchaserState
    extends State<PhoneCallWithUnregisterdPurchaser>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();

  // Process dropdown
  String? _processItem = 'Select';
  List<String> _processdropdownItems = ['Select'];

  // Dates
  final TextEditingController _submissionDateController =
      TextEditingController();
  final TextEditingController _reportDateController = TextEditingController();

  // Area Code dropdown (fetched)
  String? _areaCode = 'Select';
  List<Map<String, String>> _areaCodes = [
    {'code': 'Select', 'name': 'Select'},
  ];
  bool _loadingAreaCodes = false; // used in dropdown builder

  // Mobile No
  final TextEditingController _mobileController = TextEditingController();

  // Purchaser / Retailer dropdown (fetched)
  String? _purchaserType = 'Select';
  List<Map<String, String>> _purchasers = [
    {'code': 'Select', 'name': 'Select'},
  ];
  bool _loadingPurchasers = false; // used in dropdown builder

  // Party Name
  final TextEditingController _partyNameController = TextEditingController();

  // Counter Type dropdown
  String? _counterType = 'Select';
  final List<String> _counterTypes = ['Select', 'Type A', 'Type B'];

  // Pin Code
  final TextEditingController _pinCodeController = TextEditingController();

  // District
  final TextEditingController _districtController = TextEditingController();

  // Visited City
  final TextEditingController _visitedCityController = TextEditingController();

  // Name & Designation
  final TextEditingController _nameDesigController = TextEditingController();

  // Topics discussed
  final TextEditingController _topicsController = TextEditingController();

  // Images
  List<File?> _selectedImages = [null];

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

    _setSubmissionDateToToday();
    _fetchProcessTypes();
    _fetchAreaCodes();
    _fetchPurchasers();
  }

  Future<void> _fetchProcessTypes() async {
    try {
      final list = await DsrApiService.getProcessTypes();
      if (!mounted) return;
      setState(() => _processdropdownItems = ['Select', ...list]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _processdropdownItems = ['Select', 'Add', 'Update']);
    }
    _processItem = 'Select';
  }

  Future<void> _fetchAreaCodes() async {
    setState(() => _loadingAreaCodes = true);
    try {
      final data = await DsrApiService.getAreaCodes();
      final processed =
          data
              .map((e) {
                final code =
                    (e['Code'] ?? e['code'] ?? e['AreaCode'] ?? '').toString();
                final name = (e['Name'] ?? e['name'] ?? code).toString();
                return {'code': code, 'name': name};
              })
              .where((m) => m['code']!.isNotEmpty)
              .toList();
      if (!mounted) return;
      setState(
        () =>
            _areaCodes = [
              {'code': 'Select', 'name': 'Select'},
              ...processed,
            ],
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () =>
            _areaCodes = [
              {'code': 'Select', 'name': 'Select'},
            ],
      );
    } finally {
      if (mounted) setState(() => _loadingAreaCodes = false);
    }
  }

  Future<void> _fetchPurchasers() async {
    setState(() => _loadingPurchasers = true);
    try {
      final data = await DsrApiService.getPurchaserOptions();
      final processed =
          data
              .map((e) {
                final code = (e['Code'] ?? e['code'] ?? '').toString();
                final name =
                    (e['Description'] ?? e['description'] ?? '').toString();
                return {'code': code, 'name': name};
              })
              .where((m) => m['code']!.isNotEmpty)
              .toList();
      if (!mounted) return;
      setState(
        () =>
            _purchasers = [
              {'code': 'Select', 'name': 'Select'},
              ...processed,
            ],
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () =>
            _purchasers = [
              {'code': 'Select', 'name': 'Select'},
            ],
      );
    } finally {
      if (mounted) setState(() => _loadingPurchasers = false);
    }
  }

  // (Autofill for update not implemented in UI yet; could be added with process type Update.)

  @override
  void dispose() {
    _fadeController.dispose();
    _submissionDateController.dispose();
    _reportDateController.dispose();
    _mobileController.dispose();
    _partyNameController.dispose();
    _pinCodeController.dispose();
    _districtController.dispose();
    _visitedCityController.dispose();
    _nameDesigController.dispose();
    _topicsController.dispose();
    super.dispose();
  }

  void _setSubmissionDateToToday() {
    final today = DateTime.now();
    _submissionDateController.text = DateFormat('yyyy-MM-dd').format(today);
  }

  Future<void> _pickReportDate() async {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10), // Allow any past date (last 10 years)
      lastDate: now, // Only allow up to today
    );
    if (picked != null) {
      if (picked.isBefore(threeDaysAgo)) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Please Put Valid DSR Date.'),
                content: const Text(
                  'You Can submit DSR only Last Three Days. If You want to submit back date entry Please enter Exception entry (Path : Transcation --> DSR Exception Entry). Take Approval from concerned and Fill DSR Within 3 days after approval.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to exception entry
                    },
                    child: const Text('Go to Exception Entry'),
                  ),
                ],
              ),
        );
        return;
      }
      setState(() {
        _reportDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Removed unused generic date picker

  Future<void> _pickImage(int index) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _selectedImages[index] = File(pickedFile.path));
    }
  }

  void _showImageDialog(File imageFile) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.contain,
                  image: FileImage(imageFile),
                ),
              ),
            ),
          ),
    );
  }

  void _onSubmit({required bool exitAfter}) async {
    if (!_formKey.currentState!.validate()) return;

    late DateTime submissionDate;
    late DateTime reportDate;
    try {
      submissionDate = DateTime.parse(_submissionDateController.text.trim());
      reportDate = DateTime.parse(_reportDateController.text.trim());
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final loginId = await SessionManager.getLoginId() ?? '';
    final dto = DsrEntryDto(
      activityType: 'Phone Call with Unregistered Purchasers',
      submissionDate: submissionDate,
      reportDate: reportDate,
      createId: loginId,
      dsrParam: '61',
      processType: _processItem == 'Update' ? 'U' : 'A',
      docuNumb: _processItem == 'Update' ? null : null,
      dsrRem01: _mobileController.text,
      dsrRem02: _partyNameController.text,
      dsrRem03: _counterType ?? '',
      dsrRem04: _pinCodeController.text,
      dsrRem05: _districtController.text,
      dsrRem06: _visitedCityController.text,
      dsrRem07: _nameDesigController.text,
      dsrRem08: _topicsController.text,
      areaCode: _areaCode ?? '',
      purchaser: _purchaserType ?? '',
      purchaserCode: '',
    );
    bool success = false;
    try {
      if (_processItem == 'Update') {
        await DsrApiService.updateDsr(dto);
      } else {
        await DsrApiService.submitDsr(dto);
      }
      success = true;
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _processItem == 'Update'
                ? 'Updated successfully.'
                : 'Submitted successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      if (exitAfter) {
        Navigator.of(context).pop();
      } else {
        _clearForm();
      }
    }
  }

  void _clearForm() {
    setState(() {
      _processItem = 'Select';
      _submissionDateController.clear();
      _reportDateController.clear();
      _areaCode = 'Select';
      _mobileController.clear();
      _purchaserType = 'Select';
      _partyNameController.clear();
      _counterType = 'Select';
      _pinCodeController.clear();
      _districtController.clear();
      _visitedCityController.clear();
      _nameDesigController.clear();
      _topicsController.clear();
      _selectedImages = [null];
    });
    _formKey.currentState?.reset();
    _setSubmissionDateToToday();
  }

  // Removed submit helper (handled by DsrApiService)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Phone Call with Unregistered Purchasers',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DsrEntry()),
              ),
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
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_in_talk,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Phone Call with Unregistered Purchasers',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record details of your phone call with unregistered purchasers',
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
                  // Process Type Section
                  _buildSectionTitle('Process Type'),
                  const SizedBox(height: 8),
                  _buildProcessTypeDropdown(),
                  const SizedBox(height: 24),
                  // Date Fields Section
                  _buildSectionTitle('Date Information'),
                  const SizedBox(height: 8),
                  _buildDateField(
                    'Submission Date',
                    _submissionDateController,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(
                    'Report Date',
                    _reportDateController,
                    onTap: _pickReportDate,
                  ),
                  const SizedBox(height: 24),
                  // Location Information Section
                  _buildSectionTitle('Location Information'),
                  const SizedBox(height: 8),
                  _buildAreaCodeDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Mobile No',
                    _mobileController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildPurchaserDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Party Name',
                    _partyNameController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    'Counter Type',
                    _counterType,
                    _counterTypes,
                    (val) => setState(() => _counterType = val),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Pin Code',
                    _pinCodeController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: lookup pin code
                      },
                      child: const Text(
                        'Update Pincode',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('District', _districtController),
                  const SizedBox(height: 16),
                  _buildTextField('Visited City', _visitedCityController),
                  const SizedBox(height: 24),
                  // Meeting Details Section
                  _buildSectionTitle('Meeting Details'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    'Name & Designation of Person',
                    _nameDesigController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Topics discussed during meeting',
                    _topicsController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  // Image Upload Section
                  _buildSectionTitle('Upload Images'),
                  const SizedBox(height: 8),
                  ..._buildImageUploadSection(),
                  const SizedBox(height: 32),
                  // Submit Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _onSubmit(exitAfter: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Submit & New',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _onSubmit(exitAfter: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Submit & Exit',
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAreaCodeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child:
              _loadingAreaCodes
                  ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : DropdownButton<String>(
                    isExpanded: true,
                    value: _areaCode,
                    underline: Container(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    items:
                        _areaCodes
                            .map(
                              (m) => DropdownMenuItem(
                                value: m['code'],
                                child: Text(m['name'] ?? m['code']!),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      setState(() => _areaCode = v);
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildPurchaserDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child:
              _loadingPurchasers
                  ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : DropdownButton<String>(
                    isExpanded: true,
                    value: _purchaserType,
                    underline: Container(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    items:
                        _purchasers
                            .map(
                              (m) => DropdownMenuItem(
                                value: m['code'],
                                child: Text(m['name'] ?? m['code']!),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      setState(() => _purchaserType = v);
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildProcessTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _processItem,
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
        hintText: 'Select process type',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      ),
      items:
          _processdropdownItems
              .map((it) => DropdownMenuItem(value: it, child: Text(it)))
              .toList(),
      onChanged: (val) => setState(() => _processItem = val),
      validator:
          (v) =>
              v == null || v == 'Select'
                  ? 'Please select a Process Type'
                  : null,
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    VoidCallback? onTap,
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
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
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
            hintText: 'Select date',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            suffixIcon:
                readOnly
                    ? const Icon(Icons.lock, color: Colors.grey)
                    : const Icon(Icons.calendar_today, color: Colors.blue),
          ),
          validator:
              (val) =>
                  val == null || val.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
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
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            underline: Container(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            items:
                items
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
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
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          validator:
              (val) =>
                  val == null || val.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }

  List<Widget> _buildImageUploadSection() {
    return [
      ...List.generate(_selectedImages.length, (i) {
        final file = _selectedImages[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: file != null ? Colors.green : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Document ${i + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (file != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Uploaded',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickImage(i),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(color: Colors.blue),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            file != null ? Icons.refresh : Icons.upload_file,
                            size: 18,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            file != null ? 'Replace' : 'Upload',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (file != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showImageDialog(file),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(color: Colors.green),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 18,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'View',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedImages.removeAt(i);
                        });
                      },
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }),
      if (_selectedImages.length < 3)
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedImages.add(null);
              });
            },
            icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
            label: const Text(
              'Add More Image',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ),
    ];
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
                    'Phone Call with Unregistered Purchasers Help',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fill in all the required fields to record your phone call with unregistered purchasers. '
                    'Make sure to select the correct process type (Add/Update) and provide accurate location information.',
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
