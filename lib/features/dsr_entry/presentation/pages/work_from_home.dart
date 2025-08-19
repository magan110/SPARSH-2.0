import 'dart:io';
import 'package:flutter/material.dart';
import 'package:learning2/core/services/session_manager.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
// Removed direct http usage in favor of centralized DsrApiService.
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/document_number_storage.dart';
import 'dsr_entry.dart';
import 'dsr_exception_entry.dart';
import '../../../../core/services/dsr_api_service.dart';

class WorkFromHome extends StatefulWidget {
  const WorkFromHome({super.key});

  @override
  State<WorkFromHome> createState() => _WorkFromHomeState();
}

class _WorkFromHomeState extends State<WorkFromHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();

  String? _processItem = 'Select';
  List<String> _processdropdownItems = const ['Select'];
  // loading state retained if future UI wants spinner (currently unused)
  // Removed _processTypeError (not displayed in UI).

  // Document-number dropdown state
  bool _loadingDocs = false;
  List<String> _documentNumbers = [];
  String? _selectedDocuNumb;

  // Geolocation
  Position? _currentPosition;

  final TextEditingController _submissionDateController =
      TextEditingController();
  final TextEditingController _reportDateController = TextEditingController();
  // Removed stored DateTime fields; we keep only text controllers.

  // Activity details controllers
  final TextEditingController _activityDetails1Controller =
      TextEditingController();
  final TextEditingController _activityDetails2Controller =
      TextEditingController();
  final TextEditingController _activityDetails3Controller =
      TextEditingController();
  final TextEditingController _otherPointsController = TextEditingController();

  // Image upload
  final List<int> _uploadRows = [0];
  final List<File?> _selectedImages = [null];
  final ImagePicker _picker = ImagePicker();

  // Document number
  final _documentNumberController = TextEditingController();
  // Removed unused _documentNumber (we use _selectedDocuNumb for updates).

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

    _initGeolocation();
    _loadInitialDocumentNumber();
    _fetchProcessTypes();
    _setSubmissionDateToToday();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _submissionDateController.dispose();
    _reportDateController.dispose();
    _activityDetails1Controller.dispose();
    _activityDetails2Controller.dispose();
    _activityDetails3Controller.dispose();
    _otherPointsController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _initGeolocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled.');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied.');
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = pos;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  // Load document number when screen initializes
  Future<void> _loadInitialDocumentNumber() async {
    // Previously stored document number not used after refactor.
    await DocumentNumberStorage.loadDocumentNumber(
      DocumentNumberKeys.workFromHome,
    );
  }

  Future<void> _fetchProcessTypes() async {
    // No spinner currently; could add state if desired.
    try {
      final list = await DsrApiService.getProcessTypes();
      // Expecting something like ['Add','Update'] else fallback
      final normalized = list.isNotEmpty ? list : ['Add', 'Update'];
      setState(() {
        _processdropdownItems = ['Select', ...normalized];
      });
    } catch (e) {
      // swallow; could show snackbar if desired
    } finally {
      // no-op
    }
  }

  // Fetch document numbers for Update
  Future<void> _fetchDocumentNumbers() async {
    setState(() {
      _loadingDocs = true;
      _documentNumbers = [];
      _selectedDocuNumb = null;
    });
    try {
      final docs = await DsrApiService.getDocumentNumbers('55');
      setState(() => _documentNumbers = docs);
    } catch (_) {
      // swallow
    } finally {
      if (mounted) {
        setState(() => _loadingDocs = false);
      }
    }
  }

  // Fetch details for a document number and populate fields
  Future<void> _autofill(String docuNumb) async {
    try {
      final data = await DsrApiService.autofill(docuNumb);
      if (data == null) return;
      setState(() {
        _activityDetails1Controller.text = (data['dsrRem01'] ?? '').toString();
        _activityDetails2Controller.text = (data['dsrRem02'] ?? '').toString();
        _activityDetails3Controller.text = (data['dsrRem03'] ?? '').toString();
        _otherPointsController.text = (data['dsrRem04'] ?? '').toString();
        final sub =
            (data['SubmissionDate'] ?? data['submissionDate'] ?? '').toString();
        final rep = (data['ReportDate'] ?? data['reportDate'] ?? '').toString();
        if (sub.isNotEmpty)
          _submissionDateController.text = sub.substring(0, 10);
        if (rep.isNotEmpty) _reportDateController.text = rep.substring(0, 10);
      });
    } catch (_) {
      // ignore errors for autofill
    }
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DsrExceptionEntryPage(),
                        ),
                      );
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

  // Removed unused _addRow and _removeRow helpers.

  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImages[index] = File(pickedFile.path));
    }
  }

  void _showImageDialog(File imageFile) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
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

  // Removed submitDsrEntry & resetForm (centralized service now used).

  Future<void> _onSubmit({required bool exitAfter}) async {
    if (!_formKey.currentState!.validate()) return;
    // ensure we have location
    if (_currentPosition == null) {
      await _initGeolocation();
    }

    // Build DTO
    late DateTime submissionDate;
    late DateTime reportDate;
    try {
      submissionDate = DateTime.parse(_submissionDateController.text.trim());
      reportDate = DateTime.parse(_reportDateController.text.trim());
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid date format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final loginId = await SessionManager.getLoginId() ?? '';
    final dto = DsrEntryDto(
      activityType: 'Work From Home',
      submissionDate: submissionDate,
      reportDate: reportDate,
      createId: loginId,
      dsrParam: '55',
      processType: _processItem == 'Update' ? 'U' : 'A',
      docuNumb: _processItem == 'Update' ? _selectedDocuNumb : null,
      dsrRem01: _activityDetails1Controller.text,
      dsrRem02: _activityDetails2Controller.text,
      dsrRem03: _activityDetails3Controller.text,
      dsrRem04: _otherPointsController.text,
      latitude: _currentPosition?.latitude.toString() ?? '',
      longitude: _currentPosition?.longitude.toString() ?? '',
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
      _selectedDocuNumb = null;
      _submissionDateController.clear();
      _reportDateController.clear();
      _activityDetails1Controller.clear();
      _activityDetails2Controller.clear();
      _activityDetails3Controller.clear();
      _otherPointsController.clear();
      _uploadRows
        ..clear()
        ..add(0);
      _selectedImages
        ..clear()
        ..add(null);
    });
    _formKey.currentState?.reset();
    _setSubmissionDateToToday();
  }

  // Removed document number generation (not required for Add path currently).

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Work From Home',
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
                            Icons.home_work,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Work From Home',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record details of your work from home activities',
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
                  // Document Number (for Update)
                  if (_processItem == 'Update') ...[
                    _buildSectionTitle('Document Number'),
                    const SizedBox(height: 8),
                    _loadingDocs
                        ? const Center(child: CircularProgressIndicator())
                        : _buildDocumentNumberDropdown(),
                    const SizedBox(height: 24),
                  ],
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
                  // Activity Details Section
                  _buildSectionTitle('Activity Details'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    'Activity Details 1',
                    _activityDetails1Controller,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Activity Details 2',
                    _activityDetails2Controller,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Activity Details 3',
                    _activityDetails3Controller,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Other Points',
                    _otherPointsController,
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
                          child: Text(
                            _processItem == 'Update'
                                ? 'Update & New'
                                : 'Submit & New',
                            style: const TextStyle(
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
                          child: Text(
                            _processItem == 'Update'
                                ? 'Update & Exit'
                                : 'Submit & Exit',
                            style: const TextStyle(
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
      onChanged: (val) async {
        setState(() {
          _processItem = val;
        });
        if (val == 'Update')
          await _fetchDocumentNumbers();
        else {
          // When switching back to Add, clear autofilled data except submission date.
          _selectedDocuNumb = null;
        }
      },
      validator:
          (v) =>
              v == null || v == 'Select'
                  ? 'Please select a Process Type'
                  : null,
    );
  }

  Widget _buildDocumentNumberDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDocuNumb,
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
        hintText: 'Select document number',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      ),
      items:
          _documentNumbers
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
      onChanged: (v) async {
        setState(() => _selectedDocuNumb = v);
        if (v != null) await _autofill(v);
      },
      validator: (v) => v == null ? 'Required' : null,
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
                    'Work From Home Help',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fill in all the required fields to record your work from home details. '
                    'Make sure to select the correct process type (Add/Update) and provide accurate information.',
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
