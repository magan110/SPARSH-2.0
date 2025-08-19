import 'dart:io';
import 'package:flutter/material.dart';
import 'package:learning2/core/services/session_manager.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
// Refactored to use centralized DsrApiService (no direct http/json here).
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/document_number_storage.dart';
import 'dsr_entry.dart';
import 'dsr_exception_entry.dart';
import '../../../../core/services/dsr_api_service.dart';

// Removed ApiConstants (deprecated after service abstraction).

class CheckSamplingAtSite extends StatefulWidget {
  const CheckSamplingAtSite({super.key});

  @override
  State<CheckSamplingAtSite> createState() => _CheckSamplingAtSiteState();
}

class _CheckSamplingAtSiteState extends State<CheckSamplingAtSite>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();

  // Geolocation
  Position? _currentPosition;

  // Process type dropdown state
  String? _processItem = 'Select';
  List<String> _processdropdownItems = const ['Select'];
  // Removed unused _processTypeError.

  // Document-number dropdown state
  bool _loadingDocs = false;
  List<String> _documentNumbers = [];
  String? _selectedDocuNumb;

  // Product, quality, status dropdowns
  List<String> _productNames = ['Select'];
  String? _selectedProductName = 'Select';
  bool _isLoadingProductNames = true;

  List<String> _qualityOptions = ['Select'];
  String? _qualityItem = 'Select';
  bool _isLoadingQualityOptions = true;

  List<String> _statusOptions = ['Select'];
  String? _statusItem = 'Select';
  bool _isLoadingStatusOptions = true;

  // Text controllers
  final _submissionDateController = TextEditingController();
  final _reportDateController = TextEditingController();
  final _siteController = TextEditingController();
  final _potentialController = TextEditingController();
  final _applicatorController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _mobileController = TextEditingController();

  // Images
  final List<File?> _selectedImages = [null];
  final ImagePicker _picker = ImagePicker();

  // Document number
  final _documentNumberController = TextEditingController();
  // Removed unused _documentNumber (updates use dropdown only).

  // Dynamic field config for activity type
  final Map<String, List<Map<String, String>>> activityFieldConfig = {
    "Visit to Get / Check Sampling at Site": [
      {"label": "Site Name", "key": "siteName", "rem": "dsrRem01"},
      {"label": "Product Name", "key": "productName", "rem": "dsrRem02"},
      {"label": "Potential (MT)", "key": "potential", "rem": "dsrRem03"},
      {"label": "Applicator Name", "key": "applicatorName", "rem": "dsrRem04"},
      {"label": "Quality of Sample", "key": "quality", "rem": "dsrRem05"},
      {"label": "Status of Sample", "key": "status", "rem": "dsrRem06"},
      {"label": "Contact Name", "key": "contactName", "rem": "dsrRem07"},
      {"label": "Mobile Number", "key": "mobile", "rem": "dsrRem08"},
    ],
  };

  // Dynamic controllers for text fields
  final Map<String, TextEditingController> _controllers = {};

  String get _selectedActivityType => "Visit to Get / Check Sampling at Site";

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
    _fetchProductNames();
    _fetchQualityOptions();
    _fetchStatusOptions();
    _setSubmissionDateToToday();
    _initControllersForActivity(_selectedActivityType);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _submissionDateController.dispose();
    _reportDateController.dispose();
    _siteController.dispose();
    _potentialController.dispose();
    _applicatorController.dispose();
    _contactNameController.dispose();
    _mobileController.dispose();
    _documentNumberController.dispose();

    // Dispose dynamic controllers
    for (final c in _controllers.values) {
      c.dispose();
    }

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

  void _initControllersForActivity(String activityType) {
    final config = activityFieldConfig[activityType] ?? [];
    for (final field in config) {
      if (field['key'] != 'productName' &&
          field['key'] != 'quality' &&
          field['key'] != 'status') {
        _controllers[field['key']!] = TextEditingController();
      }
    }
  }

  Future<void> _loadInitialDocumentNumber() async {
    await DocumentNumberStorage.loadDocumentNumber(
      DocumentNumberKeys.checkSamplingSite,
    ); // kept for parity; value unused after refactor
  }

  Future<void> _fetchProcessTypes() async {
    try {
      final list = await DsrApiService.getProcessTypes();
      final normalized = list.isNotEmpty ? list : ['Add', 'Update'];
      setState(() {
        _processdropdownItems = ['Select', ...normalized];
        _processItem = 'Select';
      });
    } catch (_) {
      setState(() {
        _processdropdownItems = ['Select', 'Add', 'Update'];
        _processItem = 'Select';
      });
    }
  }

  Future<void> _fetchDocumentNumbers() async {
    setState(() {
      _loadingDocs = true;
      _documentNumbers = [];
      _selectedDocuNumb = null;
    });
    try {
      final docs = await DsrApiService.getDocumentNumbers(
        '31',
      ); // corrected dsrParam
      setState(() => _documentNumbers = docs);
    } catch (_) {
      // swallow
    } finally {
      if (mounted) setState(() => _loadingDocs = false);
    }
  }

  Future<void> _autofill(String docuNumb) async {
    try {
      final data = await DsrApiService.autofill(docuNumb);
      if (data == null) return;
      final config = activityFieldConfig[_selectedActivityType] ?? [];
      for (final field in config) {
        final remKey = field['rem'];
        final value = (data[remKey] ?? '').toString();
        if (field['key'] == 'productName') {
          if (!_productNames.contains(value) && value.isNotEmpty) {
            setState(() => _productNames = [..._productNames, value]);
          }
          _selectedProductName = value.isEmpty ? 'Select' : value;
        } else if (field['key'] == 'quality') {
          if (!_qualityOptions.contains(value) && value.isNotEmpty) {
            setState(() => _qualityOptions = [..._qualityOptions, value]);
          }
          _qualityItem = value.isEmpty ? 'Select' : value;
        } else if (field['key'] == 'status') {
          if (!_statusOptions.contains(value) && value.isNotEmpty) {
            setState(() => _statusOptions = [..._statusOptions, value]);
          }
          _statusItem = value.isEmpty ? 'Select' : value;
        } else {
          _controllers[field['key']!]?.text = value;
        }
      }
      final sub =
          (data['SubmissionDate'] ?? data['submissionDate'] ?? '').toString();
      final rep = (data['ReportDate'] ?? data['reportDate'] ?? '').toString();
      setState(() {
        if (sub.isNotEmpty)
          _submissionDateController.text = sub.substring(0, 10);
        if (rep.isNotEmpty) _reportDateController.text = rep.substring(0, 10);
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _fetchProductNames() async {
    setState(() => _isLoadingProductNames = true);
    try {
      final list = await DsrApiService.getProductOptions();
      setState(() {
        _productNames = ['Select', ...list];
      });
    } catch (_) {
      setState(() => _productNames = ['Select']);
    } finally {
      if (mounted) setState(() => _isLoadingProductNames = false);
    }
  }

  Future<void> _fetchQualityOptions() async {
    setState(() => _isLoadingQualityOptions = true);
    try {
      final list = await DsrApiService.getQualityOptions();
      setState(() => _qualityOptions = ['Select', ...list]);
    } catch (_) {
      setState(() => _qualityOptions = ['Select']);
    } finally {
      if (mounted) setState(() => _isLoadingQualityOptions = false);
    }
  }

  Future<void> _fetchStatusOptions() async {
    setState(() => _isLoadingStatusOptions = true);
    try {
      final list = await DsrApiService.getStatusOptions();
      setState(() => _statusOptions = ['Select', ...list]);
    } catch (_) {
      setState(() => _statusOptions = ['Select']);
    } finally {
      if (mounted) setState(() => _isLoadingStatusOptions = false);
    }
  }

  void _onProcessTypeChanged(String? value) {
    setState(() {
      _processItem = value;
    });
    if (value == 'Update') {
      _fetchDocumentNumbers();
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
      firstDate: DateTime(now.year - 10),
      lastDate: now,
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

  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages[index] = File(pickedFile.path);
      });
    }
  }

  void _addImageRow() {
    if (_selectedImages.length < 3) {
      setState(() {
        _selectedImages.add(null);
      });
    }
  }

  void _removeImageRow(int index) {
    if (_selectedImages.length > 1) {
      setState(() {
        _selectedImages.removeAt(index);
      });
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

  Future<void> _onSubmit({required bool exitAfter}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) await _initGeolocation();

    // Build DTO using centralized model
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

    final config = activityFieldConfig[_selectedActivityType] ?? [];
    String rem01 = '',
        rem02 = '',
        rem03 = '',
        rem04 = '',
        rem05 = '',
        rem06 = '',
        rem07 = '',
        rem08 = '';
    for (final field in config) {
      final key = field['key'];
      final rem = field['rem'];
      String value;
      if (key == 'productName')
        value = _selectedProductName ?? '';
      else if (key == 'quality')
        value = _qualityItem ?? '';
      else if (key == 'status')
        value = _statusItem ?? '';
      else
        value = _controllers[key!]!.text;
      switch (rem) {
        case 'dsrRem01':
          rem01 = value;
          break;
        case 'dsrRem02':
          rem02 = value;
          break;
        case 'dsrRem03':
          rem03 = value;
          break;
        case 'dsrRem04':
          rem04 = value;
          break;
        case 'dsrRem05':
          rem05 = value;
          break;
        case 'dsrRem06':
          rem06 = value;
          break;
        case 'dsrRem07':
          rem07 = value;
          break;
        case 'dsrRem08':
          rem08 = value;
          break;
      }
    }

    final loginId = await SessionManager.getLoginId() ?? '';
    final dto = DsrEntryDto(
      activityType: _selectedActivityType,
      submissionDate: submissionDate,
      reportDate: reportDate,
      createId: loginId,
      dsrParam: '31', // corrected param
      processType: _processItem == 'Update' ? 'U' : 'A',
      docuNumb: _processItem == 'Update' ? _selectedDocuNumb : null,
      dsrRem01: rem01,
      dsrRem02: rem02,
      dsrRem03: rem03,
      dsrRem04: rem04,
      dsrRem05: rem05,
      dsrRem06: rem06,
      dsrRem07: rem07,
      dsrRem08: rem08,
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
      _selectedProductName = 'Select';
      _qualityItem = 'Select';
      _statusItem = 'Select';
      _selectedImages.clear();
      _selectedImages.add(null);

      // Clear dynamic controllers
      for (final c in _controllers.values) {
        c.clear();
      }
    });
    _formKey.currentState?.reset();
  }

  // Removed server-side document number generation (handled elsewhere if needed).

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Check Sampling at Site',
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
                            Icons.science,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Check Sampling at Site',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record details of your site visit for sampling',
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

                  // Dynamic Fields Section
                  _buildSectionTitle('Sampling Details'),
                  const SizedBox(height: 8),
                  ..._buildDynamicFields(),
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
      onChanged: _onProcessTypeChanged,
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

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    bool isLoading = false,
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
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child:
              isLoading
                  ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : DropdownButton<String>(
                    isExpanded: true,
                    value: value,
                    underline: Container(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    items:
                        items
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                    onChanged: onChanged,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ),
        ),
      ],
    );
  }

  List<Widget> _buildDynamicFields() {
    final config = activityFieldConfig[_selectedActivityType] ?? [];
    return config.map((field) {
      if (field['key'] == 'productName') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownField(
              field['label']!,
              _selectedProductName,
              _productNames,
              (val) => setState(() => _selectedProductName = val),
              isLoading: _isLoadingProductNames,
            ),
            const SizedBox(height: 16),
          ],
        );
      } else if (field['key'] == 'quality') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownField(
              field['label']!,
              _qualityItem,
              _qualityOptions,
              (val) => setState(() => _qualityItem = val),
              isLoading: _isLoadingQualityOptions,
            ),
            const SizedBox(height: 16),
          ],
        );
      } else if (field['key'] == 'status') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownField(
              field['label']!,
              _statusItem,
              _statusOptions,
              (val) => setState(() => _statusItem = val),
              isLoading: _isLoadingStatusOptions,
            ),
            const SizedBox(height: 16),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              field['label']!,
              _controllers[field['key']!]!,
              keyboardType:
                  field['key'] == 'potential' || field['key'] == 'mobile'
                      ? TextInputType.number
                      : TextInputType.text,
            ),
            const SizedBox(height: 16),
          ],
        );
      }
    }).toList();
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
    List<Widget> widgets = List.generate(_selectedImages.length, (i) {
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
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
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
            if (file != null)
              GestureDetector(
                onTap: () => _showImageDialog(file),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(file),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
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
                          Icon(Icons.visibility, size: 18, color: Colors.green),
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
                ],
                if (_selectedImages.length > 1) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _removeImageRow(i),
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Align(
          alignment: Alignment.center,
          child: OutlinedButton.icon(
            onPressed: _addImageRow,
            icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
            label: const Text(
              'Add Document',
              style: TextStyle(color: Colors.blue),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );

    return widgets;
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
                    'Sampling Help',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fill in all the required fields to record your site visit for sampling. '
                    'Make sure to select the correct process type (Add/Update) and provide accurate sampling details.',
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
