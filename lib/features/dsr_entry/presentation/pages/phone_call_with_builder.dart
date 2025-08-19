// File: lib/phone_call_with_builder.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
// Removed direct http/json lookups; using DsrApiService for all network operations.
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/document_number_storage.dart';
import '../../../../core/services/dsr_api_service.dart';
import 'dsr_entry.dart';
import 'dsr_exception_entry.dart';
import 'package:learning2/core/services/session_manager.dart';

class PhoneCallWithBuilder extends StatefulWidget {
  const PhoneCallWithBuilder({super.key});
  @override
  State<PhoneCallWithBuilder> createState() => _PhoneCallWithBuilderState();
}

class _PhoneCallWithBuilderState extends State<PhoneCallWithBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();

  // Geolocation
  Position? _currentPosition;

  // Dynamic data
  List<Map<String, String>> _areaCodes = [];
  List<Map<String, String>> _purchasers = [];
  List<Map<String, String>> _purchaserCodes = [];

  // Selected values
  String? _selectedAreaCode = 'Select';
  String? _selectedPurchaser = 'Select';
  String? _selectedPurchaserCode = 'Select';

  // Loading states
  bool _isLoadingAreaCodes = false;
  bool _isLoadingPurchasers = false;
  bool _isLoadingPurchaserCodes = false;

  final TextEditingController _submissionDateController =
      TextEditingController();
  final TextEditingController _reportDateController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  // Dynamic field config for activity type
  final Map<String, List<Map<String, String>>> activityFieldConfig = {
    "Phone Call with Builder /Stockist": [
      {"label": "Site Name", "key": "siteName", "rem": "dsrRem01"},
      {
        "label": "Contractor Working at Site",
        "key": "contractorName",
        "rem": "dsrRem02",
      },
      {"label": "Met With", "key": "metWith", "rem": "dsrRem03"},
      {
        "label": "Name and Designation of Person",
        "key": "nameDesg",
        "rem": "dsrRem04",
      },
      {"label": "Topic Discussed", "key": "topic", "rem": "dsrRem05"},
      {
        "label": "Ugai Recovery Plans",
        "key": "ugaiRecovery",
        "rem": "dsrRem06",
      },
      {
        "label": "Any Purchaser Grievances",
        "key": "grievance",
        "rem": "dsrRem07",
      },
      {"label": "Any Other Point", "key": "otherPoint", "rem": "dsrRem08"},
    ],
  };

  // Dynamic controllers for text fields
  final Map<String, TextEditingController> _controllers = {};
  String? _metWithItem = 'Select';
  final List<String> _metWithItems = ['Select', 'Builder', 'Contractor'];
  List<File?> _selectedImages = [null];
  final _documentNumberController = TextEditingController();
  String get _selectedActivityType => "Phone Call with Builder /Stockist";

  // Add/Update process type state
  String? _processItem = 'Select';
  List<String> _processdropdownItems = ['Select', 'Add', 'Update'];

  // Document-number dropdown state
  bool _loadingDocs = false;
  List<String> _documentNumbers = [];
  String? _selectedDocuNumb;
  bool _showGlobalLoader = false; // global centered loading overlay

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
    _fetchAreaCodes();
    _setSubmissionDateToToday();
    _initControllersForActivity(_selectedActivityType);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _submissionDateController.dispose();
    _reportDateController.dispose();
    _codeController.dispose();
    _documentNumberController.dispose();
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
      if (field['key'] != 'metWith') {
        _controllers[field['key']!] = TextEditingController();
      }
    }
  }

  Future<void> _loadInitialDocumentNumber() async {
    final savedDocNumber = await DocumentNumberStorage.loadDocumentNumber(
      DocumentNumberKeys.phoneCallBuilder,
    );
    if (savedDocNumber != null) {
      setState(() {
        // Previously stored in _documentNumber (removed as unused)
      });
    }
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

  Future<void> _fetchDocumentNumbers() async {
    setState(() {
      _loadingDocs = true;
      _showGlobalLoader = true;
      _documentNumbers = [];
      _selectedDocuNumb = null;
    });
    try {
      final docs = await DsrApiService.getDocumentNumbers('12');
      if (!mounted) return;
      setState(() => _documentNumbers = docs);
    } catch (_) {
      /* swallow */
    } finally {
      if (mounted)
        setState(() {
          _loadingDocs = false;
          _showGlobalLoader = false;
        });
    }
  }

  Future<void> _autofill(String docuNumb) async {
    setState(() => _showGlobalLoader = true);
    try {
      final data = await DsrApiService.autofill(docuNumb);
      if (data == null) return;
      final activityData = data;
      final areaCode =
          (activityData['areaCode'] ?? activityData['AreaCode'] ?? '')
              .toString();
      final purchaserFlag =
          (activityData['purchaser'] ?? activityData['Purchaser'] ?? '')
              .toString();
      final purchaserCode =
          (activityData['purchaserCode'] ?? activityData['PurchaserCode'] ?? '')
              .toString();

      // Load dependent dropdown data sequence so that selection widgets have values
      if (areaCode.isNotEmpty) {
        await _fetchPurchasers(areaCode);
        if (purchaserFlag.isNotEmpty) {
          await _fetchPurchaserCodes(purchaserFlag);
        }
      }

      if (!mounted) return;
      setState(() {
        _submissionDateController.text = (activityData['SubmissionDate'] ??
                activityData['submissionDate'] ??
                '')
            .toString()
            .substring(0, 10);
        _reportDateController.text = (activityData['ReportDate'] ??
                activityData['reportDate'] ??
                '')
            .toString()
            .substring(0, 10);
        final config = activityFieldConfig[_selectedActivityType] ?? [];
        for (final field in config) {
          final remKey = field['rem'];
          final dataVal = activityData[remKey] ?? '';
          if (field['key'] == 'metWith') {
            _metWithItem =
                dataVal.toString().isEmpty ? 'Select' : dataVal.toString();
          } else {
            _controllers[field['key']!]!.text = dataVal.toString();
          }
        }
        if (areaCode.isNotEmpty && _areaCodes.any((m) => m['code'] == areaCode))
          _selectedAreaCode = areaCode;
        else
          _selectedAreaCode = 'Select';
        if (purchaserFlag.isNotEmpty &&
            _purchasers.any((m) => m['code'] == purchaserFlag))
          _selectedPurchaser = purchaserFlag;
        else
          _selectedPurchaser = 'Select';
        if (purchaserCode.isNotEmpty &&
            _purchaserCodes.any((m) => m['code'] == purchaserCode))
          _selectedPurchaserCode = purchaserCode;
        else
          _selectedPurchaserCode = 'Select';
      });
    } catch (e) {
      debugPrint('Autofill error: $e');
    } finally {
      if (mounted) setState(() => _showGlobalLoader = false);
    }
  }

  Future<void> _fetchAreaCodes() async {
    setState(() => _isLoadingAreaCodes = true);
    try {
      final data = await DsrApiService.getAreaCodes();
      if (data.isEmpty) {
        setState(() {
          _areaCodes = [
            {'code': 'Select', 'name': 'Select'},
          ];
          _isLoadingAreaCodes = false;
        });
        return;
      }
      final processedAreaCodes =
          data
              .map((item) {
                final code =
                    (item['Code'] ?? item['code'] ?? item['AreaCode'] ?? '')
                        .toString()
                        .trim();
                final name =
                    (item['Name'] ?? item['name'] ?? code).toString().trim();
                return {'code': code, 'name': name};
              })
              .where((m) => m['code']!.isNotEmpty)
              .toList();
      final seen = <String>{};
      final uniqueAreaCodes = [
        {'code': 'Select', 'name': 'Select'},
        ...processedAreaCodes.where((m) {
          if (seen.contains(m['code'])) return false;
          seen.add(m['code']!);
          return true;
        }),
      ];
      if (!mounted) return;
      setState(() {
        _areaCodes = uniqueAreaCodes;
        _isLoadingAreaCodes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _areaCodes = [
          {'code': 'Select', 'name': 'Select'},
        ];
        _isLoadingAreaCodes = false;
      });
    }
  }

  Future<void> _fetchPurchasers(String areaCode) async {
    if (areaCode == 'Select') {
      setState(() {
        _purchasers = [
          {'code': 'Select', 'name': 'Select'},
        ];
        _selectedPurchaser = 'Select';
        _selectedPurchaserCode = 'Select';
        _purchaserCodes = [
          {'code': 'Select', 'name': 'Select'},
        ];
      });
      return;
    }

    setState(() {
      _isLoadingPurchasers = true;
      _selectedPurchaser = 'Select';
      _selectedPurchaserCode = 'Select';
      _purchaserCodes = [
        {'code': 'Select', 'name': 'Select'},
      ];
    });

    try {
      final data = await DsrApiService.getPurchaserOptions();
      final seen = <String>{};
      final unique = [
        {'code': 'Select', 'name': 'Select'},
        ...data
            .map((item) {
              return {
                'code': (item['Code'] ?? item['code'] ?? '').toString(),
                'name':
                    (item['Description'] ?? item['description'] ?? '')
                        .toString(),
              };
            })
            .where((m) {
              if (m['code']!.isEmpty || seen.contains(m['code'])) return false;
              seen.add(m['code']!);
              return true;
            }),
      ];
      if (!mounted) return;
      setState(() {
        _purchasers = unique;
        _isLoadingPurchasers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _purchasers = [
          {'code': 'Select', 'name': 'Select'},
        ];
        _isLoadingPurchasers = false;
      });
    }
  }

  Future<void> _fetchPurchaserCodes(String purchaserCode) async {
    if (purchaserCode == 'Select' || _selectedAreaCode == 'Select') {
      setState(() {
        _purchaserCodes = [
          {'code': 'Select', 'name': 'Select'},
        ];
        _selectedPurchaserCode = 'Select';
      });
      return;
    }

    setState(() {
      _isLoadingPurchaserCodes = true;
      _selectedPurchaserCode = 'Select';
    });
    try {
      String resolvedAreaCode = '';
      for (final a in _areaCodes) {
        if (a['name'] == _selectedAreaCode || a['code'] == _selectedAreaCode) {
          resolvedAreaCode = a['code'] ?? '';
          break;
        }
      }
      String resolvedPurchaserFlag = '';
      for (final p in _purchasers) {
        if (p['name'] == purchaserCode || p['code'] == purchaserCode) {
          resolvedPurchaserFlag = p['code'] ?? '';
          break;
        }
      }
      final data = await DsrApiService.getPurchaserCode(
        resolvedAreaCode,
        resolvedPurchaserFlag,
      );
      List list = [];
      if (data.containsKey('PurchaserCodes'))
        list = data['PurchaserCodes'];
      else if (data.containsKey('purchaserCodes'))
        list = data['purchaserCodes'];
      final parsed =
          list
              .where((e) => e is Map)
              .map((e) {
                final m = e as Map;
                final code = (m['code'] ?? m['Code'] ?? '').toString().trim();
                final name = (m['name'] ?? m['Name'] ?? code).toString().trim();
                return {'code': code, 'name': name};
              })
              .where((m) => m['code']!.isNotEmpty)
              .toList();
      if (!mounted) return;
      setState(() {
        _purchaserCodes = [
          {'code': 'Select', 'name': 'Select'},
          ...parsed,
        ];
        _isLoadingPurchaserCodes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _purchaserCodes = [
          {'code': 'Select', 'name': 'Select'},
        ];
        _isLoadingPurchaserCodes = false;
      });
    }
  }

  // Dropdown builders reintroduced after overlay integration
  Widget _buildAreaCodeDropdown() {
    final items = _areaCodes.map((m) => m['code']!).toList();
    if (!items.contains('Select')) items.insert(0, 'Select');
    return _buildDropdownField('Area Code', _selectedAreaCode, items, (val) {
      setState(() => _selectedAreaCode = val);
      if (val != null) {
        if (val == 'Select') {
          setState(() {
            _purchasers = [
              {'code': 'Select', 'name': 'Select'},
            ];
            _selectedPurchaser = 'Select';
            _purchaserCodes = [
              {'code': 'Select', 'name': 'Select'},
            ];
            _selectedPurchaserCode = 'Select';
          });
        } else {
          _fetchPurchasers(val);
        }
      }
    }, isLoading: _isLoadingAreaCodes);
  }

  Widget _buildPurchaserTypeDropdown() {
    final items = _purchasers.map((m) => m['code']!).toList();
    if (!items.contains('Select')) items.insert(0, 'Select');
    return _buildDropdownField('Purchaser Type', _selectedPurchaser, items, (
      val,
    ) {
      setState(() => _selectedPurchaser = val);
      if (val != null && val != 'Select') {
        _fetchPurchaserCodes(val);
      }
    }, isLoading: _isLoadingPurchasers);
  }

  Widget _buildPurchaserCodeDropdown() {
    final items = _purchaserCodes.map((m) => m['code']!).toList();
    if (!items.contains('Select')) items.insert(0, 'Select');
    return _buildDropdownField(
      'Purchaser Code',
      _selectedPurchaserCode,
      items,
      (val) {
        setState(() => _selectedPurchaserCode = val);
      },
      isLoading: _isLoadingPurchaserCodes,
    );
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
                  'You Can submit DSR only Last Three Days. If You want to submit back date entry Please enter Exception Entry (Path : Transcation --> DSR Exception Entry). Take Approval from concerned and Fill DSR Within 3 days after approval.',
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
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImages[index] = File(pickedFile.path);
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
    String rem01 = '';
    String rem02 = '';
    String rem03 = '';
    String rem04 = '';
    String rem05 = '';
    String rem06 = '';
    String rem07 = '';
    String rem08 = '';
    for (final field in config) {
      final val =
          field['key'] == 'metWith'
              ? (_metWithItem ?? '')
              : (_controllers[field['key']!]?.text ?? '');
      switch (field['rem']) {
        case 'dsrRem01':
          rem01 = val;
          break;
        case 'dsrRem02':
          rem02 = val;
          break;
        case 'dsrRem03':
          rem03 = val;
          break;
        case 'dsrRem04':
          rem04 = val;
          break;
        case 'dsrRem05':
          rem05 = val;
          break;
        case 'dsrRem06':
          rem06 = val;
          break;
        case 'dsrRem07':
          rem07 = val;
          break;
        case 'dsrRem08':
          rem08 = val;
          break;
      }
    }
    final loginId = await SessionManager.getLoginId() ?? '';
    final dto = DsrEntryDto(
      activityType: _selectedActivityType,
      submissionDate: submissionDate,
      reportDate: reportDate,
      createId: loginId,
      dsrParam: '12',
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
      areaCode: _selectedAreaCode ?? '',
      purchaser: _selectedPurchaser ?? '',
      purchaserCode: _selectedPurchaserCode ?? '',
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
      _selectedDocuNumb = null;
      _submissionDateController.clear();
      _reportDateController.clear();
      _selectedAreaCode = 'Select';
      _selectedPurchaser = 'Select';
      _selectedPurchaserCode = 'Select';
      _codeController.clear();
      _metWithItem = 'Select';
      _selectedImages = [null];
      for (final c in _controllers.values) {
        c.clear();
      }
    });
    _formKey.currentState?.reset();
  }

  // Removed unused document number generation method (centralized elsewhere if needed)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Phone Call With Builder',
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
      body: Stack(
        children: [
          SafeArea(
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
                              'Phone Call With Builder',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Record details of your phone call with builder or stockist',
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

                      // Location Information Section
                      _buildSectionTitle('Location Information'),
                      const SizedBox(height: 8),
                      _buildAreaCodeDropdown(),
                      const SizedBox(height: 16),
                      _buildPurchaserTypeDropdown(),
                      const SizedBox(height: 16),
                      _buildPurchaserCodeDropdown(),
                      const SizedBox(height: 24),

                      // Dynamic Fields Section
                      _buildSectionTitle('Call Details'),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
          if (_showGlobalLoader)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
        if (val == 'Update') await _fetchDocumentNumbers();
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
                        items.map((item) {
                          String display = item;
                          if (label == 'Area Code' && item != 'Select') {
                            final match = _areaCodes.firstWhere(
                              (a) => a['code'] == item,
                              orElse: () => {'code': item, 'name': item},
                            );
                            display = '${match['code']} - ${match['name']}';
                          } else if (label == 'Purchaser Type' &&
                              item != 'Select') {
                            final match = _purchasers.firstWhere(
                              (p) => p['code'] == item,
                              orElse: () => {'code': item, 'name': item},
                            );
                            display = '${match['code']} - ${match['name']}';
                          } else if (label == 'Purchaser Code' &&
                              item != 'Select') {
                            final match = _purchaserCodes.firstWhere(
                              (c) => c['code'] == item,
                              orElse: () => {'code': item, 'name': item},
                            );
                            display = '${match['code']} - ${match['name']}';
                          }
                          return DropdownMenuItem(
                            value: item,
                            child: Text(display),
                          );
                        }).toList(),
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
      if (field['key'] == 'metWith') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownField(
              field['label']!,
              _metWithItem,
              _metWithItems,
              (val) => setState(() => _metWithItem = val),
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
              maxLines:
                  field['key'] == 'topic' ||
                          field['key'] == 'ugaiRecovery' ||
                          field['key'] == 'grievance' ||
                          field['key'] == 'otherPoint'
                      ? 3
                      : 1,
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
    return List.generate(_selectedImages.length, (i) {
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
    }).toList();
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
                    'Phone Call Help',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fill in all the required fields to record your phone call with builder or stockist. '
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
