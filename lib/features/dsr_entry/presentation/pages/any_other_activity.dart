import 'dart:io';
import 'package:flutter/material.dart';
import 'package:learning2/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/document_number_storage.dart';
import 'dsr_entry.dart';
import 'dsr_exception_entry.dart';

class AnyOtherActivity extends StatefulWidget {
  const AnyOtherActivity({super.key});

  @override
  State<AnyOtherActivity> createState() => _AnyOtherActivityState();
}

class _AnyOtherActivityState extends State<AnyOtherActivity>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  
  // 1) CONTROLLERS for dropdowns and dates
  String? _processItem = 'Select';
  List<String> _processdropdownItems = ['Select'];
  bool _isLoadingProcessTypes = true;
  String? _processTypeError;
  
  // NEW: Document-number dropdown state
  bool _loadingDocs = false;
  List<String> _documentNumbers = [];
  String? _selectedDocuNumb;
  
  // Geolocation
  Position? _currentPosition;
  
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _reportDateController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _selectedReportDate;
  
  // 2) CONTROLLERS for activity text fields
  final TextEditingController _activity1Controller = TextEditingController();
  final TextEditingController _activity2Controller = TextEditingController();
  final TextEditingController _activity3Controller = TextEditingController();
  final TextEditingController _anyOtherPointsController = TextEditingController();
  
  // 3) IMAGE UPLOAD state (up to 3)
  final List<int> _uploadRows = [0];
  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _selectedImages = [null];
  
  // 4) Document-number persistence
  final _documentNumberController = TextEditingController();
  String? _documentNumber;
  
  // 5) Config: dsrParam for this activity
  String param = '60';

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
    _dateController.dispose();
    _reportDateController.dispose();
    _activity1Controller.dispose();
    _activity2Controller.dispose();
    _activity3Controller.dispose();
    _anyOtherPointsController.dispose();
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
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = pos;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  // Load any saved document number
  Future<void> _loadInitialDocumentNumber() async {
    final saved = await DocumentNumberStorage.loadDocumentNumber(DocumentNumberKeys.anyOtherActivity);
    if (saved != null) {
      setState(() {
        _documentNumber = saved;
        _documentNumberController.text = saved;
      });
    }
  }

  Future<void> _fetchProcessTypes() async {
    setState(() {
      _isLoadingProcessTypes = true;
      _processTypeError = null;
    });
    try {
      final url = Uri.parse('http://10.4.64.23/api/DsrTry/getProcessTypes');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List processTypesList = [];
        if (data is List) {
          processTypesList = data;
        } else if (data is Map &&
            (data['ProcessTypes'] != null || data['processTypes'] != null)) {
          processTypesList =
              (data['ProcessTypes'] ?? data['processTypes']) as List;
        }
        final processTypes = processTypesList
            .map<String>((type) {
              if (type is Map) {
                return type['Description']?.toString() ??
                    type['description']?.toString() ??
                    '';
              } else {
                return type.toString();
              }
            })
            .where((desc) => desc.isNotEmpty)
            .toList();
        setState(() {
          _processdropdownItems = ['Select', ...processTypes];
          _processItem = 'Select';
          _isLoadingProcessTypes = false;
        });
      } else {
        throw Exception('Failed to load process types.');
      }
    } catch (e) {
      setState(() {
        _processdropdownItems = ['Select'];
        _processItem = 'Select';
        _isLoadingProcessTypes = false;
        _processTypeError = 'Failed to load process types.';
      });
    }
  }

  // Fetch docuNumb list when Update selected
  Future<void> _fetchDocumentNumbers() async {
    setState(() {
      _loadingDocs = true;
      _documentNumbers = [];
      _selectedDocuNumb = null;
    });
    final uri = Uri.parse(
      'http://10.4.64.23/api/DsrTry/getDocumentNumbers?dsrParam=$param'
    );
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        setState(() {
          _documentNumbers = data
            .map((e) {
              return (e['DocuNumb']
                   ?? e['docuNumb']
                   ?? e['DocumentNumber']
                   ?? e['documentNumber']
                   ?? '').toString();
            })
            .where((s) => s.isNotEmpty)
            .toList();
        });
      }
    } catch (_) {
      // ignore errors
    } finally {
      setState(() { _loadingDocs = false; });
    }
  }

  // DATE PICKERS
  void _setSubmissionDateToToday() {
    final today = DateTime.now();
    _selectedDate = today;
    _dateController.text = DateFormat('yyyy-MM-dd').format(today);
  }

  Future<void> _pickReportDate() async {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final pick = await showDatePicker(
      context: context,
      initialDate: _selectedReportDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (pick != null) {
      if (pick.isBefore(threeDaysAgo)) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Please Put Valid DSR Date.'),
            content: const Text(
              'You Can submit DSR only Last Three Days. If You want to submit back date entry Please enter Exception entry (Path : Transcation --> DSR Exception Entry). Take Approval from concerned and Fill DSR Within 3 days after approval.'
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DsrExceptionEntryPage()),
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
        _selectedReportDate = pick;
        _reportDateController.text = DateFormat('yyyy-MM-dd').format(pick);
      });
    }
  }

  // IMAGE PICKER
  Future<void> _pickImage(int idx) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _selectedImages[idx] = file);
    }
  }

  void _showImageDialog(XFile file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.contain,
              image: FileImage(File(file.path)),
            ),
          ),
        ),
      ),
    );
  }

  void _addRow() {
    if (_uploadRows.length < 3) {
      setState(() {
        _uploadRows.add(_uploadRows.length);
        _selectedImages.add(null);
      });
    }
  }

  void _removeRow() {
    if (_uploadRows.length > 1) {
      setState(() {
        _uploadRows.removeLast();
        _selectedImages.removeLast();
      });
    }
  }

  // SUBMIT / UPDATE
  Future<void> _onSubmit({required bool exitAfter}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) await _initGeolocation();
    
    final dsrData = {
      'ActivityType':   'Any Other Activity',
      'SubmissionDate': _selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'ReportDate':     _selectedReportDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'dsrRem01':       _activity1Controller.text,
      'dsrRem02':       _activity2Controller.text,
      'dsrRem03':       _activity3Controller.text,
      'dsrRem04':       _anyOtherPointsController.text,
      'latitude':       _currentPosition?.latitude.toString() ?? '',
      'longitude':      _currentPosition?.longitude.toString() ?? '',
      'DsrParam':       param,
      'DocuNumb':       _processItem == 'Update' ? _selectedDocuNumb : null,
      'ProcessType':    _processItem == 'Update' ? 'U' : 'A',
      'CreateId':       '2948',
      'UpdateId':       '2948',
    };
    
    try {
      final url = Uri.parse(
        'http://10.4.64.23/api/DsrTry/${_processItem == 'Update' ? 'update' : ''}'
      );
      final resp = _processItem == 'Update'
          ? await http.put(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(dsrData),
            )
          : await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(dsrData),
            );
      final success = (_processItem == 'Update' && resp.statusCode == 204) ||
                      (_processItem != 'Update' && resp.statusCode == 201);
      
      if (!success) {
        print('Error submitting DSR: Status ${resp.statusCode}\nBody: ${resp.body}');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? exitAfter
                  ? '${_processItem == 'Update' ? 'Updated' : 'Submitted'} successfully. Exiting...'
                  : '${_processItem == 'Update' ? 'Updated' : 'Submitted'} successfully. Ready for new entry.'
              : 'Error: ${resp.body}'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      if (success) {
        if (exitAfter) {
          Navigator.of(context).pop();
        } else {
          _clearForm();
        }
      }
    } catch (e) {
      print('Exception during submit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exception: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _processItem = 'Select';
      _selectedDocuNumb = null;
      _dateController.clear();
      _reportDateController.clear();
      _selectedDate = null;
      _selectedReportDate = null;
      _activity1Controller.clear();
      _activity2Controller.clear();
      _activity3Controller.clear();
      _anyOtherPointsController.clear();
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

  Future<void> submitDsrEntry(Map<String, dynamic> dsrData) async {
    final url = Uri.parse('http://10.4.64.23/api/DsrTry');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dsrData),
    );
    // existing debug prints...
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
          'Any Other Activity',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.push(
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
                            Icons.miscellaneous_services,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Any Other Activity',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record details of any other activities not covered elsewhere',
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
                    _dateController,
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
                    _activity1Controller,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Activity Details 2',
                    _activity2Controller,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Activity Details 3',
                    _activity3Controller,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Any Other Points',
                    _anyOtherPointsController,
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
                            _processItem == 'Update' ? 'Update & New' : 'Submit & New',
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
                            _processItem == 'Update' ? 'Update & Exit' : 'Submit & Exit',
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
      items: _processdropdownItems
          .map((it) => DropdownMenuItem(value: it, child: Text(it)))
          .toList(),
      onChanged: (val) async {
        setState(() {
          _processItem = val;
        });
        if (val == 'Update') await _fetchDocumentNumbers();
      },
      validator: (v) => v == null || v == 'Select'
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
      items: _documentNumbers
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: (v) async {
        setState(() => _selectedDocuNumb = v);
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
            suffixIcon: readOnly
                ? const Icon(Icons.lock, color: Colors.grey)
                : const Icon(Icons.calendar_today, color: Colors.blue),
          ),
          validator: (val) =>
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
          validator: (val) =>
              val == null || val.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }

  List<Widget> _buildImageUploadSection() {
    return [
      ..._uploadRows.map((idx) {
        final file = _selectedImages[idx];
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
                    'Document ${idx + 1}',
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickImage(idx),
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
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedImages.removeAt(idx);
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
      if (_uploadRows.length < 3)
        Center(
          child: TextButton.icon(
            onPressed: _addRow,
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Any Other Activity Help',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fill in all the required fields to record your activity details. '
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