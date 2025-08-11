import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/document_number_storage.dart';
import 'dsr_entry.dart';
import 'dsr_exception_entry.dart';

class OfficeWork extends StatefulWidget {
  const OfficeWork({super.key});

  @override
  State<OfficeWork> createState() => _OfficeWorkState();
}

class _OfficeWorkState extends State<OfficeWork>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _submissionDateController = TextEditingController();
  final TextEditingController _reportDateController = TextEditingController();
  
  // Add/Update process type state
  String? _processItem = 'Select';
  List<String> _processdropdownItems = ['Select'];
  bool _isLoadingProcessTypes = true;
  String? _processTypeError;
  
  // Document-number dropdown state
  bool _loadingDocs = false;
  List<String> _documentNumbers = [];
  String? _selectedDocuNumb;
  
  // Dynamic field definitions
  List<Map<String, dynamic>> _fields = [];
  bool _isLoading = true;
  List<File?> _selectedImages = [null];
  
  final _documentNumberController = TextEditingController();
  String? _documentNumber;
  Position? _currentPosition;

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
    _initializeFields();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _submissionDateController.dispose();
    _reportDateController.dispose();
    for (final field in _fields) {
      if (field['type'] == 'text' || field['type'] == 'number') {
        field['controller'].dispose();
      }
    }
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

  // Load document number when screen initializes
  Future<void> _loadInitialDocumentNumber() async {
    final savedDocNumber = await DocumentNumberStorage.loadDocumentNumber(DocumentNumberKeys.officeWork);
    if (savedDocNumber != null) {
      setState(() {
        _documentNumber = savedDocNumber;
      });
    }
  }

  void _setSubmissionDateToToday() {
    final today = DateTime.now();
    _submissionDateController.text = DateFormat('yyyy-MM-dd').format(today);
  }

  Future<void> _initializeFields() async {
    try {
      // Fetch process types from API
      final processTypes = await _fetchProcessTypes();
      
      setState(() {
        _fields = [
          {
            'label': 'Work Related To',
            'controller': TextEditingController(),
            'type': 'text',
            'maxLines': 3,
            'key': 'dsrRem01',
          },
          {
            'label': 'No. of Hours Spent',
            'controller': TextEditingController(),
            'type': 'number',
            'key': 'dsrRem02',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching process types: $e');
      // Fallback to default fields
      setState(() {
        _fields = [
          {
            'label': 'Work Related To',
            'controller': TextEditingController(),
            'type': 'text',
            'maxLines': 3,
            'key': 'dsrRem01',
          },
          {
            'label': 'No. of Hours Spent',
            'controller': TextEditingController(),
            'type': 'number',
            'key': 'dsrRem02',
          },
        ];
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _fetchProcessTypes() async {
    setState(() { _isLoadingProcessTypes = true; _processTypeError = null; });
    try {
      final url = Uri.parse('http://10.4.64.23/api/DsrTry/getProcessTypes');
      final response = await http.get(url);
      print('ProcessTypes API status:  [33m${response.statusCode} [0m');
      print('ProcessTypes API body: ${response.body}');
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
        });
        return processTypes;
      } else {
        setState(() {
          _processTypeError = 'Failed to load process types: ${response.statusCode}';
          _processdropdownItems = ['Select'];
          _processItem = 'Select';
        });
        return ['Select'];
      }
    } catch (e) {
      setState(() {
        _processTypeError = 'Error: $e';
        _processdropdownItems = ['Select'];
        _processItem = 'Select';
      });
      return ['Select'];
    } finally {
      setState(() {
        _isLoadingProcessTypes = false;
      });
    }
    // Fallback return in case of unexpected flow
    return ['Select'];
  }

  // Fetch document numbers for Update
  Future<void> _fetchDocumentNumbers() async {
    setState(() {
      _loadingDocs = true;
      _documentNumbers = [];
      _selectedDocuNumb = null;
    });
    final uri = Uri.parse(
      'http://10.4.64.23/api/DsrTry/getDocumentNumbers?dsrParam=53' // Use correct param for this activity
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

  // Fetch details for a document number and populate fields
  Future<void> _fetchAndPopulateDetails(String docuNumb) async {
    final uri = Uri.parse('http://10.4.64.23/api/DsrTry/getDsrEntry?docuNumb=$docuNumb');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          for (final field in _fields) {
            if (field['type'] == 'text' || field['type'] == 'number') {
              field['controller'].text = data[field['key']] ?? '';
            }
          }
          if (data['SubmissionDate'] != null) {
            _submissionDateController.text = data['SubmissionDate'].toString().substring(0, 10);
          }
          if (data['ReportDate'] != null) {
            _reportDateController.text = data['ReportDate'].toString().substring(0, 10);
          }
        });
      }
    } catch (_) {}
  }

  Future<String?> _fetchDocumentNumberFromServer() async {
    try {
      final url = Uri.parse('http://10.4.64.23/api/DsrTry/generateDocumentNumber');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode('KKR'), // Hardcoded to KKR
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? documentNumber;
        if (data is Map<String, dynamic>) {
          documentNumber = data['documentNumber'] ?? data['DocumentNumber'] ?? data['docNumber'] ?? data['DocNumber'];
        } else if (data is String) {
          documentNumber = data;
        }
        
        // Save to persistent storage
        if (documentNumber != null) {
          await DocumentNumberStorage.saveDocumentNumber(DocumentNumberKeys.officeWork, documentNumber);
        }
        
        return documentNumber;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickSubmissionDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _submissionDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickReportDate() async {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10), // Allow any past date
      lastDate: now, // Restrict to today or earlier
    );
    if (picked != null) {
      // Check if picked date is before threeDaysAgo
      if (picked.isBefore(threeDaysAgo)) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Please Put Valid DSR Date.'),
            content: const Text(
              'You Can submit DSR only Last Three Days. If You want to submit back date entry Please enter Exception entry(Path : Transcation --> DSR Exception Entry). Take Approval from concerned and Fill DSR Within 3 days after approval.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
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
        _reportDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage(int index) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages[index] = File(pickedFile.path);
      });
    }
  }

  void _showImageDialog(File imageFile) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
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
    if (_currentPosition == null) {
      await _initGeolocation();
    }
    
    final dsrData = <String, dynamic>{
      'ActivityType': 'Office Work',
      'SubmissionDate': _submissionDateController.text,
      'ReportDate': _reportDateController.text,
      ...{
        for (final field in _fields)
          field['key'] as String: field['controller'].text
      },
      'Images': _selectedImages.map((file) => file?.path).toList(),
      'latitude': _currentPosition?.latitude.toString() ?? '',
      'longitude': _currentPosition?.longitude.toString() ?? '',
      'DsrParam': '53',
      'DocuNumb': _processItem == 'Update' ? _selectedDocuNumb : null,
      'ProcessType': _processItem == 'Update' ? 'U' : 'A',
      'CreateId': '2948',
      'UpdateId': '2948',
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
      _submissionDateController.clear();
      _reportDateController.clear();
      for (final field in _fields) {
        if (field['type'] == 'text' || field['type'] == 'number') {
          field['controller'].clear();
        }
      }
      _selectedImages = [null];
    });
    _formKey.currentState?.reset();
    _setSubmissionDateToToday();
  }

  // Add a method to reset the form (clear document number)
  void _resetForm() {
    setState(() {
      _documentNumber = null;
      _documentNumberController.clear();
      _processItem = 'Select';
      // Clear other form fields as needed
    });
    DocumentNumberStorage.clearDocumentNumber(DocumentNumberKeys.officeWork); // Clear from persistent storage
  }

  Future<void> submitDsrEntry(Map<String, dynamic> dsrData) async {
    final url = Uri.parse('http://10.4.64.23/api/DsrTry');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dsrData),
    );
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    if (response.statusCode == 201) {
      print('✅ Data inserted successfully!');
    } else {
      print('❌ Data NOT inserted! Error: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DsrEntry()),
            ),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: const Text('Office Work', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Office Work',
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
                            Icons.work,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Office Work',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record details of your office work activities',
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
                  // Work Details Section
                  _buildSectionTitle('Work Details'),
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
        if (v != null) await _fetchAndPopulateDetails(v);
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

  List<Widget> _buildDynamicFields() {
    return _fields.map((field) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            field['label'],
            field['controller'],
            keyboardType: field['type'] == 'number' ? TextInputType.number : TextInputType.text,
            maxLines: field['maxLines'] ?? 1,
          ),
          const SizedBox(height: 16),
        ],
      );
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
          validator: (val) =>
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
                'Office Work Help',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fill in all the required fields to record your office work details. '
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