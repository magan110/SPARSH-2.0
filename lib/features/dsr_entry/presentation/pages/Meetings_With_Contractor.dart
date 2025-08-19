import 'dart:io';
import 'package:flutter/material.dart';
import 'package:learning2/core/services/session_manager.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
// Removed direct http/json usage; now using DsrApiService abstraction.
import 'package:geolocator/geolocator.dart';
import 'package:learning2/core/utils/document_number_storage.dart';
import '../../../../core/services/dsr_api_service.dart';
import 'dsr_entry.dart';
import 'dsr_exception_entry.dart';

class MeetingsWithContractor extends StatefulWidget {
  const MeetingsWithContractor({super.key});

  @override
  State<MeetingsWithContractor> createState() => _MeetingsWithContractorState();
}

class _MeetingsWithContractorState extends State<MeetingsWithContractor>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();

  // Geolocation
  Position? _currentPosition;

  // Process type dropdown state
  String? _processItem = 'Select';
  List<String> _processdropdownItems = const ['Select'];

  // Document-number dropdown state
  bool _loadingDocs = false;
  List<String> _documentNumbers = [];
  String? _selectedDocuNumb;

  // Dynamic data
  List<Map<String, String>> _areaCodes = [];
  List<Map<String, String>> _purchasers = [];
  List<Map<String, String>> _purchaserCodes = [];

  // Selected values
  String? _selectedAreaCode = 'Select';
  String? _selectedPurchaser = 'Select';
  String? _selectedPurchaserCode = 'Select';

  // Loading states
  bool _isLoadingAreaCodes = true;
  bool _isLoadingPurchasers = false;
  bool _isLoadingPurchaserCodes = false;

  final TextEditingController _submissionDateController =
      TextEditingController();
  final TextEditingController _reportDateController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  // Dynamic field config for activity type
  final Map<String, List<Map<String, String>>> activityFieldConfig = {
    "Meetings with Contractor / Stockist": [
      {"label": "New Orders Received", "key": "newOrders", "rem": "dsrRem01"},
      {
        "label": "Ugai Recovery Plans",
        "key": "ugaiRecovery",
        "rem": "dsrRem02",
      },
      {
        "label": "Any Purchaser Grievances",
        "key": "grievance",
        "rem": "dsrRem03",
      },
      {"label": "Any Other Points", "key": "otherPoint", "rem": "dsrRem04"},
    ],
  };

  // Dynamic controllers for text fields
  final Map<String, TextEditingController> _controllers = {};

  // Action remarks
  final List<int> _actionRows = [0];
  final List<TextEditingController> _actionPointsControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _closerDateControllers = [
    TextEditingController(),
  ];

  List<File?> _selectedImages = [null];
  final _documentNumberController = TextEditingController();
  String get _selectedActivityType => "Meetings with Contractor / Stockist";

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
    _fetchPurchasers();
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

    // Dispose dynamic controllers
    for (final c in _controllers.values) {
      c.dispose();
    }

    // Dispose action remarks controllers
    for (final c in _actionPointsControllers) {
      c.dispose();
    }
    for (final c in _closerDateControllers) {
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
      _controllers[field['key']!] = TextEditingController();
    }
  }

  Future<void> _loadInitialDocumentNumber() async {
    final savedDocNumber = await DocumentNumberStorage.loadDocumentNumber(
      DocumentNumberKeys.meetingsContractor,
    );
    if (savedDocNumber != null) {
      setState(() {
        // previously stored in _documentNumber (removed)
      });
    }
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
      final docs = await DsrApiService.getDocumentNumbers('13');
      setState(() => _documentNumbers = docs);
    } catch (_) {
      /* swallow */
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
        _controllers[field['key']!]?.text =
            (data[field['rem']] ?? '').toString();
      }
      setState(() {
        final sub =
            (data['SubmissionDate'] ?? data['submissionDate'] ?? '').toString();
        final rep = (data['ReportDate'] ?? data['reportDate'] ?? '').toString();
        if (sub.isNotEmpty)
          _submissionDateController.text = sub.substring(0, 10);
        if (rep.isNotEmpty) _reportDateController.text = rep.substring(0, 10);
        final areaCode =
            (data['AreaCode'] ?? data['areaCode'] ?? 'Select').toString();
        final purchaserFlag =
            (data['Purchaser'] ?? data['purchaser'] ?? 'Select').toString();
        final purchaserCode =
            (data['PurchaserCode'] ?? data['purchaserCode'] ?? 'Select')
                .toString();
        // Ensure the codes exist in the respective lists; if not keep as Select until lists fetched
        if (_areaCodes.any((a) => a['code'] == areaCode)) {
          _selectedAreaCode = areaCode;
        } else {
          _selectedAreaCode = 'Select';
        }
        if (_purchasers.any((p) => p['code'] == purchaserFlag)) {
          _selectedPurchaser = purchaserFlag;
        } else {
          _selectedPurchaser = 'Select';
        }
        if (_purchaserCodes.any((c) => c['code'] == purchaserCode)) {
          _selectedPurchaserCode = purchaserCode;
        } else {
          _selectedPurchaserCode = 'Select';
        }
      });
    } catch (_) {
      /* ignore */
    }
  }

  Future<void> _fetchAreaCodes() async {
    setState(() => _isLoadingAreaCodes = true);
    try {
      final list = await DsrApiService.getAreaCodes();
      final seen = <String>{};
      final processed =
          list
              .map((e) {
                final code =
                    (e['Code'] ?? e['code'] ?? e['AreaCode'] ?? '')
                        .toString()
                        .trim();
                final name = (e['Name'] ?? e['name'] ?? code).toString().trim();
                return {'code': code, 'name': name};
              })
              .where((m) => m['code']!.isNotEmpty)
              .where((m) {
                if (seen.contains(m['code'])) return false;
                seen.add(m['code']!);
                return true;
              })
              .toList();
      setState(() {
        _areaCodes = [
          {'code': 'Select', 'name': 'Select'},
          ...processed,
        ];
        final codes = _areaCodes.map((a) => a['code']).toSet();
        if (!codes.contains(_selectedAreaCode)) _selectedAreaCode = 'Select';
      });
    } catch (_) {
      setState(() {
        _areaCodes = [
          {'code': 'Select', 'name': 'Select'},
        ];
      });
    } finally {
      if (mounted) setState(() => _isLoadingAreaCodes = false);
    }
  }

  Future<void> _fetchPurchasers() async {
    setState(() {
      _isLoadingPurchasers = true;
      _selectedPurchaser = 'Select';
      _selectedPurchaserCode = 'Select';
      _purchaserCodes = [
        {'code': 'Select', 'name': 'Select'},
      ];
    });
    try {
      final list = await DsrApiService.getPurchaserOptions();
      final seen = <String>{};
      final processed =
          list
              .map((e) {
                final code = (e['Code'] ?? e['code'] ?? '').toString();
                final name =
                    (e['Description'] ?? e['description'] ?? '').toString();
                return {'code': code, 'name': name};
              })
              .where((m) {
                if (m['code']!.isEmpty || seen.contains(m['code']))
                  return false;
                seen.add(m['code']!);
                return true;
              })
              .toList();
      setState(() {
        _purchasers = [
          {'code': 'Select', 'name': 'Select'},
          ...processed,
        ];
      });
    } catch (_) {
      setState(
        () =>
            _purchasers = [
              {'code': 'Select', 'name': 'Select'},
            ],
      );
    } finally {
      if (mounted) setState(() => _isLoadingPurchasers = false);
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
      // Resolve display names to actual codes
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
      List purchaserCodesList = [];
      if (data.containsKey('PurchaserCodes')) {
        purchaserCodesList = data['PurchaserCodes'] as List;
      } else if (data.containsKey('purchaserCodes')) {
        purchaserCodesList = data['purchaserCodes'] as List;
      }
      final purchaserCodes =
          purchaserCodesList
              .where((item) => item is Map)
              .map((item) => item as Map)
              .map(
                (item) => {
                  'code':
                      (item['code'] ?? item['Code'] ?? '').toString().trim(),
                  'name':
                      (item['name'] ??
                              item['Name'] ??
                              item['code'] ??
                              item['Code'] ??
                              '')
                          .toString()
                          .trim(),
                },
              )
              .where((m) => m['code']!.isNotEmpty)
              .toList();
      if (purchaserCodes.isEmpty) {
        setState(() {
          _purchaserCodes = [
            {'code': 'Select', 'name': 'Select'},
          ];
          _isLoadingPurchaserCodes = false;
        });
      } else {
        setState(() {
          _purchaserCodes = [
            {'code': 'Select', 'name': 'Select'},
            ...purchaserCodes,
          ];
          _isLoadingPurchaserCodes = false;
        });
      }
    } catch (e) {
      setState(() {
        _purchaserCodes = [
          {'code': 'Select', 'name': 'Select'},
        ];
        _isLoadingPurchaserCodes = false;
      });
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

  void _onAreaCodeChanged(String? value) {
    setState(() {
      _selectedAreaCode = value;
      _selectedPurchaser = 'Select';
      _selectedPurchaserCode = 'Select';
    });
    if (value != null && value != 'Select') {
      _fetchPurchasers();
    }
  }

  void _onPurchaserChanged(String? value) {
    setState(() {
      _selectedPurchaser = value;
      _selectedPurchaserCode = 'Select';
    });
    if (value != null && value != 'Select') {
      _fetchPurchaserCodes(value);
    }
  }

  void _onPurchaserCodeChanged(String? value) {
    setState(() {
      _selectedPurchaserCode = value;
    });
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

  void _addActionRow() {
    setState(() {
      _actionRows.add(_actionRows.length);
      _actionPointsControllers.add(TextEditingController());
      _closerDateControllers.add(TextEditingController());
    });
  }

  void _removeActionRow() {
    if (_actionRows.length <= 1) return;
    setState(() {
      _actionRows.removeLast();
      _actionPointsControllers.removeLast();
      _closerDateControllers.removeLast();
    });
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

  void _addImageRow() {
    setState(() {
      _selectedImages.add(null);
    });
  }

  void _removeImageRow(int index) {
    if (_selectedImages.length <= 1) return;
    setState(() {
      _selectedImages.removeAt(index);
    });
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

    // Build DTO using model
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
    String rem01 = '', rem02 = '', rem03 = '', rem04 = '';
    for (final field in config) {
      final key = field['key'];
      final rem = field['rem'];
      final value = _controllers[key]!.text;
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
      }
    }
    // Action remarks mapped into remaining dsrRem05..08 if needed (limit to first 4 action rows)
    String rem05 = '', rem06 = '', rem07 = '', rem08 = '';
    if (_actionPointsControllers.isNotEmpty)
      rem05 = _actionPointsControllers[0].text; // action point 1
    if (_closerDateControllers.isNotEmpty)
      rem06 = _closerDateControllers[0].text; // closer date 1
    if (_actionPointsControllers.length > 1)
      rem07 = _actionPointsControllers[1].text; // action point 2
    if (_closerDateControllers.length > 1)
      rem08 = _closerDateControllers[1].text; // closer date 2

    final loginId = await SessionManager.getLoginId() ?? '';
    final dto = DsrEntryDto(
      activityType: _selectedActivityType,
      submissionDate: submissionDate,
      reportDate: reportDate,
      createId: loginId,
      dsrParam: '13',
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
      _selectedImages = [null];

      // Clear dynamic controllers
      for (final c in _controllers.values) {
        c.clear();
      }

      // Reset action remarks
      _actionRows.clear();
      _actionRows.add(0);
      for (final c in _actionPointsControllers) {
        c.dispose();
      }
      for (final c in _closerDateControllers) {
        c.dispose();
      }
      _actionPointsControllers.clear();
      _actionPointsControllers.add(TextEditingController());
      _closerDateControllers.clear();
      _closerDateControllers.add(TextEditingController());
    });
    _formKey.currentState?.reset();
  }

  // Specialized dropdown builders with code as value
  Widget _buildAreaCodeDropdown() {
    return _buildDropdownField(
      'Area Code',
      _selectedAreaCode,
      _areaCodes.map((a) => a['code']!).toList(),
      (val) {
        if (val == null) return;
        _onAreaCodeChanged(val);
      },
      isLoading: _isLoadingAreaCodes,
    );
  }

  Widget _buildPurchaserFlagDropdown() {
    return _buildDropdownField(
      'Purchaser Type',
      _selectedPurchaser,
      _purchasers.map((p) => p['code']!).toList(),
      (val) {
        if (val == null) return;
        _onPurchaserChanged(val);
      },
      isLoading: _isLoadingPurchasers,
    );
  }

  Widget _buildPurchaserCodeDropdown() {
    final items =
        _purchaserCodes.map((c) {
          if (c['code'] == 'Select') return 'Select';
          return c['code']!; // value only the code
        }).toList();
    return _buildDropdownField(
      'Purchaser Code',
      _selectedPurchaserCode,
      items,
      (val) {
        if (val == null) return;
        _onPurchaserCodeChanged(val);
      },
      isLoading: _isLoadingPurchaserCodes,
    );
  }

  // Override generic field to show labels mapping when building menu items
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

  // Removed unused document number fetch helper (centralized elsewhere if needed)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Meeting With Contractor',
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
                            Icons.groups,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Meeting With Contractor',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record details of your meeting with contractor or stockist',
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
                  _buildPurchaserFlagDropdown(),
                  const SizedBox(height: 16),
                  _buildPurchaserCodeDropdown(),
                  const SizedBox(height: 24),

                  // Dynamic Fields Section
                  _buildSectionTitle('Meeting Details'),
                  const SizedBox(height: 8),
                  ..._buildDynamicFields(),
                  const SizedBox(height: 24),

                  // Action Remarks Section
                  _buildSectionTitle('Action Remarks'),
                  const SizedBox(height: 8),
                  _buildActionRemarksSection(),
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

  // (Old generic _buildDropdownField removed; using customized version above)

  List<Widget> _buildDynamicFields() {
    final config = activityFieldConfig[_selectedActivityType] ?? [];
    return config.map((field) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            field['label']!,
            _controllers[field['key']!]!,
            maxLines:
                field['key'] == 'ugaiRecovery' ||
                        field['key'] == 'grievance' ||
                        field['key'] == 'otherPoint'
                    ? 3
                    : 1,
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
          validator:
              (val) =>
                  val == null || val.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }

  Widget _buildActionRemarksSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Action Points',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Closer Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(width: 48),
              ],
            ),
          ),

          // Action rows
          ...List.generate(_actionRows.length, (index) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _actionPointsControllers[index],
                          maxLines: 2,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
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
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            hintText: 'Enter action points',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'This field is required'
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _closerDateControllers[index],
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                _closerDateControllers[index].text = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(picked);
                              });
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
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
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            hintText: 'Select date',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              color: Colors.blue,
                            ),
                          ),
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'This field is required'
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_actionRows.length > 1)
                        IconButton(
                          onPressed: () => _removeActionRow(),
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                if (index < _actionRows.length - 1) const Divider(height: 1),
              ],
            );
          }),

          // Add button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _addActionRow,
                icon: const Icon(Icons.add, color: Colors.blue),
                label: const Text(
                  'Add Action',
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
        ],
      ),
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
                    'Meeting Help',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fill in all the required fields to record your meeting with contractor or stockist. '
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
