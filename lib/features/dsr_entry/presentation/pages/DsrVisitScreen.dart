import 'package:flutter/material.dart';
import 'package:learning2/features/dashboard/presentation/pages/edit_kyc_screen.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/dsr_activity_service.dart';
import 'package:dropdown_search/dropdown_search.dart';

class DsrVisitScreen extends StatefulWidget {
  const DsrVisitScreen({super.key});

  @override
  State<DsrVisitScreen> createState() => _DsrVisitScreenState();
}

class _DsrVisitScreenState extends State<DsrVisitScreen> {
  // Form controllers and variables
  String processType = 'A';
  String? documentNo;
  String? purchaserType;
  String? areaCode;
  String? purchaserCode;
  String? kycStatus = 'Verified';
  String? reportDate;
  String? marketName;
  String? displayContest;
  String? pendingIssue;
  String? pendingIssueDetail;
  String? issueDetail;
  String? wcEnrolment;
  String? wcpEnrolment;
  String? vapEnrolment;
  String? wcStock;
  String? wcpStock;
  String? vapStock;
  String? slWcVolume;
  String? slWpVolume;
  String? orderExecutionDate;
  String? remarks;
  String? cityReason;
  String? tileAdhesiveSeller;
  String? tileAdhesiveStock;
  String? name = '';
  String? kycEditUrl;

  // Dynamic lists
  List<Map<String, String>> productList = [];
  List<Map<String, String>> giftList = [];
  List<Map<String, String>> marketSkuList = [];

  // Brands selling checkboxes
  Map<String, bool> brandsWc = {
    'BW': false,
    'JK': false,
    'RK': false,
    'OT': false,
  };
  Map<String, bool> brandsWcp = {
    'BW': false,
    'JK': false,
    'AP': false,
    'BG': false,
    'AC': false,
    'PM': false,
    'OT': false,
  };

  // Averages (mock data)
  Map<String, String> last3MonthsAvg = {
    'JK_WC': '0',
    'JK_WCP': '0',
    'AS_WC': '0',
    'AS_WCP': '0',
    'OT_WC': '0',
    'OT_WCP': '0',
  };
  Map<String, String> currentMonthBW = {
    'BW_WC': '0.00',
    'BW_WCP': '0.00',
    'BW_VAP': '0.00',
  };

  Map<String, String> last3MonthBW = {
    'BW_WC': '0.00',
    'BW_WCP': '0.00',
    'BW_VAP': '0.00',
  };

  final _formKey = GlobalKey<FormState>();

  // Service
  final DSRActivityService _dsrService = DSRActivityService();

  // Dynamic dropdown data
  List<Map<String, dynamic>> purchaserTypeOptions = [];
  List<Map<String, dynamic>> areaCodeOptions = [];
  List<Map<String, dynamic>> exceptionReasonOptions = [];
  List<Map<String, dynamic>> giftTypeOptions = [];
  List<Map<String, dynamic>> brandOptions = [];
  List<Map<String, dynamic>> productCategoryOptions = [];
  Map<String, List<Map<String, dynamic>>> productsByCategory = {};

  bool isPurchaserTypeLoading = true;
  bool isAreaCodeLoading = true;
  bool isExceptionReasonLoading = true;
  bool isGiftTypeLoading = true;
  bool isBrandLoading = true;
  bool isProductCategoryLoading = true;
  Map<String, bool> isProductLoading = {};

  String? purchaserTypeError;
  String? areaCodeError;
  String? exceptionReasonError;
  String? giftTypeError;
  String? brandError;
  String? productCategoryError;
  Map<String, String?> productError = {};

  List<Map<String, dynamic>> purchaserCodeOptions = [];
  bool isPurchaserCodeLoading = false;
  String? purchaserCodeError;

  final TextEditingController marketNameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController kycStatusController = TextEditingController();

  // Mock data for dropdowns
  // final List<String> documentNoList = ['Doc001', 'Doc002', 'Doc003'];
  // final List<String> purchaserTypeList = [
  //   'Retailer',
  //   'Rural Retailer',
  //   'Stockiest',
  //   'Direct Dealer',
  //   'Rural Stockiest',
  //   'AD',
  //   'UBS',
  // ];
  // final List<String> areaCodeList = ['Area1', 'Area2', 'Area3'];
  final List<String> pendingIssueDetails = ['Token', 'Scheme', 'Product', 'Other'];
  final List<String> cityReasons = [
    'Network Issue',
    'Battery Low',
    'Mobile Not working',
    'Location not capturing',
    'Wrong Location OF Retailer',
    'Wrong Location Captured',
  ];
  final List<String> tileAdhesiveOptions = ['YES', 'NO'];

  // Mock data for last billing date as per Tally
  final List<Map<String, String>> lastBillingData = [
    {'product': 'White Cement', 'date': '16 Nov 2023', 'qty': '0.65000'},
    {'product': 'Water Proofing Compound', 'date': '22 Jul 2023', 'qty': '0.01500'},
  ];

  // Helper to add product row
  void addProductRow() {
    setState(() {
      productList.add({
        'product': '',
        'sku': '',
        'qty': '',
      });
    });
  }

  void removeProductRow(int index) {
    setState(() {
      productList.removeAt(index);
    });
  }

  // Helper to add gift row
  void addGiftRow() {
    setState(() {
      giftList.add({
        'giftType': '',
        'qty': '',
      });
    });
  }

  void removeGiftRow(int index) {
    setState(() {
      giftList.removeAt(index);
    });
  }

  // Helper to add market SKU row
  void addMarketSkuRow() {
    setState(() {
      marketSkuList.add({
        'brand': '',
        'product': '',
        'priceB': '',
        'priceC': '',
      });
    });
  }

  void removeMarketSkuRow(int index) {
    setState(() {
      marketSkuList.removeAt(index);
    });
  }

  // Helper to safely get dropdown value
  String? _dropdownValue(String? value, List<Map<String, dynamic>> options) {
    if (value == null) return null;
    final values = options.map((e) => e['value']?.toString()).toSet();
    return values.contains(value) ? value : null;
  }

  @override
  void initState() {
    super.initState();
    // Add one row by default for each dynamic list
    if (productList.isEmpty) addProductRow();
    if (giftList.isEmpty) addGiftRow();
    if (marketSkuList.isEmpty) addMarketSkuRow();
    _fetchDropdowns();
    _fetchOtherDropdowns();
    marketNameController.text = marketName ?? '';
    nameController.text = name ?? '';
    kycStatusController.text = kycStatus ?? '';
  }

  Future<void> _fetchDropdowns() async {
    setState(() {
      isPurchaserTypeLoading = true;
      isAreaCodeLoading = true;
      purchaserTypeError = null;
      areaCodeError = null;
    });
    try {
      final purchaserTypes = await _dsrService.getCustomerTypes();
      setState(() {
        purchaserTypeOptions = purchaserTypes;
        isPurchaserTypeLoading = false;
      });
    } catch (e) {
      setState(() {
        purchaserTypeError = 'Failed to load purchaser types';
        isPurchaserTypeLoading = false;
      });
    }
    try {
      final areas = await _dsrService.getAllAreas();
      setState(() {
        areaCodeOptions = areas;
        isAreaCodeLoading = false;
      });
    } catch (e) {
      setState(() {
        areaCodeError = 'Failed to load area codes';
        isAreaCodeLoading = false;
      });
    }
  }

  Future<void> _fetchOtherDropdowns() async {
    setState(() {
      isExceptionReasonLoading = true;
      isGiftTypeLoading = true;
      isBrandLoading = true;
      isProductCategoryLoading = true;
      exceptionReasonError = null;
      giftTypeError = null;
      brandError = null;
      productCategoryError = null;
    });
    try {
      final reasons = await _dsrService.getExceptionReasons();
      setState(() {
        exceptionReasonOptions = reasons;
        isExceptionReasonLoading = false;
      });
    } catch (e) {
      setState(() {
        exceptionReasonError = 'Failed to load exception reasons';
        isExceptionReasonLoading = false;
      });
    }
    try {
      final gifts = await _dsrService.getGiftTypes();
      setState(() {
        giftTypeOptions = gifts;
        isGiftTypeLoading = false;
      });
    } catch (e) {
      setState(() {
        giftTypeError = 'Failed to load gift types';
        isGiftTypeLoading = false;
      });
    }
    try {
      final brands = await _dsrService.getBrands();
      setState(() {
        brandOptions = brands;
        isBrandLoading = false;
      });
    } catch (e) {
      setState(() {
        brandError = 'Failed to load brands';
        isBrandLoading = false;
      });
    }
    try {
      final categories = await _dsrService.getProductCategories();
      setState(() {
        productCategoryOptions = categories;
        isProductCategoryLoading = false;
      });
    } catch (e) {
      setState(() {
        productCategoryError = 'Failed to load product categories';
        isProductCategoryLoading = false;
      });
    }
  }

  Future<void> _fetchProductsForCategory(String category) async {
    isProductLoading[category] = true;
    productError[category] = null;
    setState(() {});
    try {
      final products = await _dsrService.getProducts(category: category);
      productsByCategory[category] = products;
      isProductLoading[category] = false;
      setState(() {});
    } catch (e) {
      productError[category] = 'Failed to load products';
      isProductLoading[category] = false;
      setState(() {});
    }
  }

  bool isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);
    final loginId = 'testuser'; // Replace with actual loginId
    try {
      // Collect a representative subset of form data for demo
      final dsrData = {
        'ProcType': processType, // 'A', 'U', 'D'
        'DocuNumb': documentNo,
        'DocuDate': reportDate,
        'AreaCode': areaCode,
        'CusRtlFl': purchaserType,
        'CusRtlCd': purchaserCode,
        'MrktName': marketName,
        'PendIsue': pendingIssue,
        'PndIsuDt': pendingIssueDetail,
        'IsuDetal': issueDetail,
        'CreateId': loginId,
        // Add more fields as needed
      };
      final result = await _dsrService.saveDSR(dsrData);
      setState(() => isSubmitting = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Submitted successfully!')),
        );
        // Optionally reset form or navigate
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Submission failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycStatusOptions = ['Verified', 'Not Verified'];
    final validKycStatus = kycStatusOptions.contains(kycStatus) ? kycStatus : null;

    final displayContestOptions = ['Y', 'N', 'NA'];
    final displayContestLabels = {'Y': 'Yes', 'N': 'No', 'NA': 'NA'};
    final validDisplayContest = displayContestOptions.contains(displayContest) ? displayContest : null;

    final pendingIssueOptions = ['Y', 'N'];
    final pendingIssueLabels = {'Y': 'Yes', 'N': 'No'};
    final validPendingIssue = pendingIssueOptions.contains(pendingIssue) ? pendingIssue : null;

    final kycStatusDisplayMap = {'Y': 'Yes', 'N': 'No'};

    // Before building Product Category dropdown
    print('ProductCategoryOptions: ' + productCategoryOptions.toString());
    // Before building Gift Type dropdown
    print('GiftTypeOptions: ' + giftTypeOptions.toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text('DSR Visit Entry'),
        elevation: 4,
        backgroundColor: SparshTheme.primaryBlue,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
      ),
      backgroundColor: SparshTheme.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SparshSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Process Type ---
                const _SectionHeader(icon: Icons.settings, label: 'Process Type'),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'A',
                            groupValue: processType,
                            onChanged: (v) => setState(() => processType = v!),
                          ),
                          const Text('Add'),
                          Radio<String>(
                            value: 'U',
                            groupValue: processType,
                            onChanged: (v) => setState(() => processType = v!),
                          ),
                          const Text('Update'),
                          Radio<String>(
                            value: 'D',
                            groupValue: processType,
                            onChanged: (v) => setState(() => processType = v!),
                          ),
                          const Text('Delete'),
                        ],
                      ),
                      if (processType != 'A')
                        const SizedBox(),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Purchaser/Retailer Type, Area Code, Purchaser Code, Name, KYC ---
                const _SectionHeader(icon: Icons.person, label: 'Basic Details'),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isPurchaserTypeLoading
                          ? const LinearProgressIndicator()
                          : purchaserTypeError != null
                              ? Text(purchaserTypeError!, style: const TextStyle(color: Colors.red))
                              : DropdownButtonFormField<String>(
                                  value: _dropdownValue(purchaserType, purchaserTypeOptions),
                                  decoration: _fantasticInputDecoration('Purchaser / Retailer Type *'),
                                  items: purchaserTypeOptions
                                      .map((e) => DropdownMenuItem<String>(
                                            value: e['value']?.toString() ?? '',
                                            child: Text(e['text']?.toString() ?? e['value']?.toString() ?? ''),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => purchaserType = v ?? ''),
                                  validator: (v) => v == null ? 'Required' : null,
                                ),
                      const SizedBox(height: SparshSpacing.sm),
                      isAreaCodeLoading
                          ? const LinearProgressIndicator()
                          : areaCodeError != null
                              ? Text(areaCodeError!, style: const TextStyle(color: Colors.red))
                              : DropdownButtonFormField<String>(
                                  value: _dropdownValue(areaCode, areaCodeOptions),
                                  decoration: _fantasticInputDecoration('Area Code *'),
                                  items: areaCodeOptions
                                      .map((e) => DropdownMenuItem<String>(
                                            value: e['value']?.toString() ?? '',
                                            child: Text(e['text']?.toString() ?? e['value']?.toString() ?? ''),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => areaCode = v ?? ''),
                                  validator: (v) => v == null ? 'Required' : null,
                                ),
                      const SizedBox(height: SparshSpacing.sm),
                      // Purchaser Code Dropdown with Search
                      DropdownSearch<Map<String, dynamic>>(
                        asyncItems: (String filter) async {
                          if (areaCode == null || purchaserType == null) return <Map<String, dynamic>>[];
                          setState(() => isPurchaserCodeLoading = true);
                          try {
                            final results = await _dsrService.getPurchaserCodes(
                              areaCode: areaCode!,
                              purchaserType: purchaserType!,
                              searchText: filter,
                            );
                            setState(() => isPurchaserCodeLoading = false);
                            print('PurchaserCodeOptions: ' + results.toString());
                            return results.cast<Map<String, dynamic>>();
                          } catch (e) {
                            setState(() {
                              isPurchaserCodeLoading = false;
                              purchaserCodeError = e.toString();
                            });
                            return <Map<String, dynamic>>[];
                          }
                        },
                        itemAsString: (item) => item?['text'] ?? '',
                        onChanged: (item) {
                          setState(() {
                            purchaserCode = item?['value'];
                            print('Selected purchaserCode: ' + (purchaserCode ?? 'null'));
                            name = item?['name'];
                            kycStatus = item?['kycStatus'];
                            marketName = item?['marketName'];
                            nameController.text = name ?? '';
                            marketNameController.text = marketName ?? '';
                            // Show Yes/No instead of Y/N
                            if (kycStatus == 'Y' || kycStatus == 'N') {
                              kycStatusController.text = kycStatusDisplayMap[kycStatus!] ?? kycStatus!;
                            } else {
                              kycStatusController.text = kycStatus ?? '';
                            }
                            // ...set other fields as needed
                          });
                        },
                        selectedItem: purchaserCodeOptions.any((e) => e['value'] == purchaserCode)
                          ? purchaserCodeOptions.firstWhere((e) => e['value'] == purchaserCode)
                          : null,
                        validator: (Map<String, dynamic>? v) => v == null ? 'Required' : null,
                        dropdownBuilder: (context, selectedItem) => Text(selectedItem?['text'] ?? ''),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          itemBuilder: (context, item, isSelected) => ListTile(
                            title: Text(item['text'] ?? ''),
                            subtitle: Text(item['address'] ?? ''),
                          ),
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: _fantasticInputDecoration('Purchaser Code *', icon: Icons.search),
                        ),
                        compareFn: (item, selectedItem) => item['value'] == selectedItem?['value'],
                      ),
                      if (purchaserCodeError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            purchaserCodeError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: nameController,
                        decoration: _fantasticInputDecoration('Name'),
                        onChanged: (v) => name = v,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Report Date, Market Name, Display Contest, Pending Issues ---
                const _SectionHeader(icon: Icons.event_note, label: 'Details'),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: kycStatusController,
                        readOnly: true,
                        decoration: _fantasticInputDecoration('KYC Status'),
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        decoration: _fantasticInputDecoration('Report Date *', icon: Icons.calendar_today),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 3)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              reportDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                            });
                          }
                        },
                        controller: TextEditingController(text: reportDate),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: marketNameController,
                        decoration: _fantasticInputDecoration('Market Name (Location Or Road Name) *'),
                        onChanged: (v) => marketName = v,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      // Participation of Display Contest (vertical)
                      const Text('Participation of Display Contest *', style: SparshTypography.bodyBold),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: displayContestOptions.map((opt) => Row(
                          children: [
                            Radio<String>(
                              value: opt,
                              groupValue: validDisplayContest,
                              onChanged: (v) => setState(() => displayContest = v),
                            ),
                            Text(displayContestLabels[opt] ?? opt),
                          ],
                        )).toList(),
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      // Any Pending Issues (vertical)
                      const Text('Any Pending Issues (Yes/No) *', style: SparshTypography.bodyBold),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: pendingIssueOptions.map((opt) => Row(
                          children: [
                            Radio<String>(
                              value: opt,
                              groupValue: pendingIssue == 'Y' || pendingIssue == 'N' ? pendingIssue : null,
                              onChanged: (v) => setState(() => pendingIssue = v),
                            ),
                            Text(pendingIssueLabels[opt] ?? opt),
                          ],
                        )).toList(),
                      ),
                      if (pendingIssue == 'Y') ...[
                        DropdownButtonFormField<String>(
                          value: pendingIssueDetail,
                          decoration: _fantasticInputDecoration('If Yes, pending issue details *'),
                          items: pendingIssueDetails
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setState(() => pendingIssueDetail = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        TextFormField(
                          decoration: _fantasticInputDecoration('If Yes, Specify Issue'),
                          onChanged: (v) => issueDetail = v,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Enrolment Slab ---
                const _SectionHeader(icon: Icons.bar_chart, label: 'Enrolment Slab (in MT)'),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: _fantasticInputDecoration('WC'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => wcEnrolment = v,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        decoration: _fantasticInputDecoration('WCP'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => wcpEnrolment = v,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        decoration: _fantasticInputDecoration('VAP'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => vapEnrolment = v,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- BW Stocks Availability ---
                const _SectionHeader(icon: Icons.inventory, label: 'BW Stocks Availability (in MT)'),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: _fantasticInputDecoration('WC'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => wcStock = v,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        decoration: _fantasticInputDecoration('WCP'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => wcpStock = v,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        decoration: _fantasticInputDecoration('VAP'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => vapStock = v,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Brands Selling ---
                const _SectionHeader(icon: Icons.check_box, label: 'Brands Selling'),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('WC (Industry Volume)', style: SparshTypography.bodyBold),
                      isBrandLoading
                          ? const LinearProgressIndicator()
                          : brandError != null
                              ? Text(brandError!, style: const TextStyle(color: Colors.red))
                              : Wrap(
                                  spacing: SparshSpacing.sm,
                                  children: brandOptions
                                      .map((brand) {
                                    final code = brand['value']?.toString() ?? '';
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: brandsWc[code] ?? false,
                                          onChanged: (v) => setState(() => brandsWc[code] = v ?? false),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.sm)),
                                        ),
                                        Text(brand['text']?.toString() ?? code),
                                      ],
                                    );
                                  }).toList(),
                                ),
                      TextFormField(
                        decoration: _fantasticInputDecoration('WC Industry Volume in (MT)'),
                        onChanged: (v) => slWcVolume = v,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      const Text('WCP (Industry Volume)', style: SparshTypography.bodyBold),
                      isBrandLoading
                          ? const LinearProgressIndicator()
                          : brandError != null
                              ? Text(brandError!, style: const TextStyle(color: Colors.red))
                              : Wrap(
                                  spacing: SparshSpacing.sm,
                                  children: brandOptions
                                      .map((brand) {
                                    final code = brand['value']?.toString() ?? '';
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: brandsWcp[code] ?? false,
                                          onChanged: (v) => setState(() => brandsWcp[code] = v ?? false),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.sm)),
                                        ),
                                        Text(brand['text']?.toString() ?? code),
                                      ],
                                    );
                                  }).toList(),
                                ),
                      TextFormField(
                        decoration: _fantasticInputDecoration('WCP Industry Volume in (MT)'),
                        onChanged: (v) => slWpVolume = v,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Last 3 Months Average ---
                const _SectionHeader(icon: Icons.timeline, label: 'Last 3 Months Average'),
                _FantasticCard(
                  child: Table(
                    border: TableBorder.all(color: SparshTheme.borderGrey),
                    children: [
                      const TableRow(children: [
                        SizedBox(),
                        Center(child: Text('WC Qty', style: SparshTypography.bodyBold)),
                        Center(child: Text('WCP Qty', style: SparshTypography.bodyBold)),
                      ]),
                      TableRow(children: [
                        const Center(child: Text('JK')),
                        TextFormField(
                          initialValue: last3MonthsAvg['JK_WC'],
                          decoration: _fantasticInputDecoration(''),
                          onChanged: (v) => last3MonthsAvg['JK_WC'] = v,
                        ),
                        TextFormField(
                          initialValue: last3MonthsAvg['JK_WCP'],
                          decoration: _fantasticInputDecoration(''),
                          onChanged: (v) => last3MonthsAvg['JK_WCP'] = v,
                        ),
                      ]),
                      TableRow(children: [
                        const Center(child: Text('Asian')),
                        TextFormField(
                          initialValue: last3MonthsAvg['AS_WC'],
                          decoration: _fantasticInputDecoration(''),
                          onChanged: (v) => last3MonthsAvg['AS_WC'] = v,
                        ),
                        TextFormField(
                          initialValue: last3MonthsAvg['AS_WCP'],
                          decoration: _fantasticInputDecoration(''),
                          onChanged: (v) => last3MonthsAvg['AS_WCP'] = v,
                        ),
                      ]),
                      TableRow(children: [
                        const Center(child: Text('Other')),
                        TextFormField(
                          initialValue: last3MonthsAvg['OT_WC'],
                          decoration: _fantasticInputDecoration(''),
                          onChanged: (v) => last3MonthsAvg['OT_WC'] = v,
                        ),
                        TextFormField(
                          initialValue: last3MonthsAvg['OT_WCP'],
                          decoration: _fantasticInputDecoration(''),
                          onChanged: (v) => last3MonthsAvg['OT_WCP'] = v,
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Current Month - BW ---
                const _SectionHeader(icon: Icons.calendar_month, label: 'Last 3 Months Average - BW (in MT)'),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: currentMonthBW['BW_WC'],
                        decoration: _fantasticInputDecoration('WC'),
                        readOnly: true,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        initialValue: currentMonthBW['BW_WCP'],
                        decoration: _fantasticInputDecoration('WCP'),
                        readOnly: true,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        initialValue: currentMonthBW['BW_VAP'],
                        decoration: _fantasticInputDecoration('VAP'),
                        readOnly: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: SparshSpacing.sm),
                // --- Current Month - BW ---
                const _SectionHeader(icon: Icons.calendar_month, label: 'Current Month - BW (in MT)'),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: currentMonthBW['WC'],
                        decoration: _fantasticInputDecoration('WC'),
                        readOnly: true,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        initialValue: currentMonthBW['WCP'],
                        decoration: _fantasticInputDecoration('WCP'),
                        readOnly: true,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        initialValue: currentMonthBW['VAP'],
                        decoration: _fantasticInputDecoration('VAP'),
                        readOnly: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: SparshSpacing.sm),
                // --- Order Booked in call/e meet (Dynamic List) ---
                const _SectionHeader(icon: Icons.shopping_cart, label: 'Order Booked in call/e meet'),
                _FantasticCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Order Booked in call/e meet', style: SparshTypography.bodyBold),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: addProductRow,
                          ),
                        ],
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: productList.length,
                        itemBuilder: (context, idx) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                isProductCategoryLoading
                                    ? const LinearProgressIndicator()
                                    : productCategoryError != null
                                        ? Text(productCategoryError!, style: const TextStyle(color: Colors.red))
                                        : DropdownButtonFormField<String>(
                                            value: _dropdownValue(productList[idx]['category'], productCategoryOptions),
                                            decoration: _fantasticInputDecoration('Product Category'),
                                            items: productCategoryOptions
                                                .map((e) => DropdownMenuItem<String>(
                                                      value: e['Code']?.toString() ?? '',
                                                      child: Text('${e['Description'] ?? e['Code'] ?? ''} (${e['Code'] ?? ''})'),
                                                    ))
                                                .toList(),
                                            onChanged: (v) async {
                                              setState(() => productList[idx]['category'] = v ?? '');
                                              if (v != null && v.isNotEmpty) {
                                                await _fetchProductsForCategory(v);
                                              }
                                            },
                                          ),
                                const SizedBox(height: SparshSpacing.xs),
                                productList[idx]['category'] == null
                                    ? const SizedBox()
                                    : isProductLoading[productList[idx]['category']] == true
                                        ? const LinearProgressIndicator()
                                        : productError[productList[idx]['category']] != null
                                            ? Text(productError[productList[idx]['category']]!, style: const TextStyle(color: Colors.red))
                                            : DropdownButtonFormField<String>(
                                                value: _dropdownValue(productList[idx]['sku'], productsByCategory[productList[idx]['category']] ?? []),
                                                decoration: _fantasticInputDecoration('SKU'),
                                                items: (productsByCategory[productList[idx]['category']] ?? [])
                                                    .map((e) => DropdownMenuItem<String>(
                                                          value: e['Code']?.toString() ?? '',
                                                          child: Text('${e['Description'] ?? e['Code'] ?? ''} (${e['Code'] ?? ''})'),
                                                        ))
                                                    .toList(),
                                                onChanged: (v) => setState(() => productList[idx]['sku'] = v ?? ''),
                                              ),
                                const SizedBox(height: SparshSpacing.xs),
                                TextFormField(
                                  decoration: _fantasticInputDecoration('Qty'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => productList[idx]['qty'] = v,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: SparshTheme.errorRed),
                                    onPressed: () => removeProductRow(idx),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Market -- WCP (Highest selling SKU) (Dynamic List) ---
                const _SectionHeader(icon: Icons.trending_up, label: 'Market -- WCP (Highest selling SKU)'),
                _FantasticCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Market -- WCP (Highest selling SKU)', style: SparshTypography.bodyBold),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: addMarketSkuRow,
                          ),
                        ],
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: marketSkuList.length,
                        itemBuilder: (context, idx) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                isBrandLoading
                                    ? const LinearProgressIndicator()
                                    : brandError != null
                                        ? Text(brandError!, style: const TextStyle(color: Colors.red))
                                        : DropdownButtonFormField<String>(
                                            value: _dropdownValue(marketSkuList[idx]['brand'], brandOptions),
                                            decoration: _fantasticInputDecoration('Brand'),
                                            items: brandOptions
                                                .map((e) => DropdownMenuItem<String>(
                                                      value: e['value']?.toString() ?? '',
                                                      child: Text('${e['text'] ?? e['value'] ?? ''} (${e['value'] ?? ''})'),
                                                    ))
                                                .toList(),
                                            onChanged: (v) => setState(() => marketSkuList[idx]['brand'] = v ?? ''),
                                          ),
                                const SizedBox(height: SparshSpacing.xs),
                                TextFormField(
                                  decoration: _fantasticInputDecoration('Product'),
                                  onChanged: (v) => marketSkuList[idx]['product'] = v,
                                ),
                                const SizedBox(height: SparshSpacing.xs),
                                TextFormField(
                                  decoration: _fantasticInputDecoration('Price - B'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => marketSkuList[idx]['priceB'] = v,
                                ),
                                const SizedBox(height: SparshSpacing.xs),
                                TextFormField(
                                  decoration: _fantasticInputDecoration('Price - C'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => marketSkuList[idx]['priceC'] = v,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: SparshTheme.errorRed),
                                    onPressed: () => removeMarketSkuRow(idx),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Gift Distribution (Dynamic List) ---
                const _SectionHeader(icon: Icons.card_giftcard, label: 'Gift Distribution'),
                _FantasticCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Gift Distribution', style: SparshTypography.bodyBold),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: addGiftRow,
                          ),
                        ],
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: giftList.length,
                        itemBuilder: (context, idx) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                isGiftTypeLoading
                                    ? const LinearProgressIndicator()
                                    : giftTypeError != null
                                        ? Text(giftTypeError!, style: const TextStyle(color: Colors.red))
                                        : DropdownButtonFormField<String>(
                                            value: _dropdownValue(giftList[idx]['giftType'], giftTypeOptions),
                                            decoration: _fantasticInputDecoration('Gift Type'),
                                            items: giftTypeOptions
                                                .map((e) => DropdownMenuItem<String>(
                                                      value: e['value']?.toString() ?? '',
                                                      child: Text('${e['text'] ?? e['value'] ?? ''} (${e['value'] ?? ''})'),
                                                    ))
                                                .toList(),
                                            onChanged: (v) => setState(() => giftList[idx]['giftType'] = v ?? ''),
                                          ),
                                const SizedBox(height: SparshSpacing.xs),
                                TextFormField(
                                  decoration: _fantasticInputDecoration('Qty'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => giftList[idx]['qty'] = v,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: SparshTheme.errorRed),
                                    onPressed: () => removeGiftRow(idx),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Tile Adhesives ---
                const _SectionHeader(icon: Icons.layers, label: 'Tile Adhesives'),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: tileAdhesiveSeller,
                        decoration: _fantasticInputDecoration('Is this Tile Adhesives seller?'),
                        items: tileAdhesiveOptions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => tileAdhesiveSeller = v),
                      ),
                      TextFormField(
                        decoration: _fantasticInputDecoration('Tile Adhesive Stock'),
                        onChanged: (v) => tileAdhesiveStock = v,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Order Execution Date, Remarks, Reason ---
                const _SectionHeader(icon: Icons.event, label: 'Order Execution & Remarks'),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: _fantasticInputDecoration('Order Execution date', icon: Icons.calendar_today),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              orderExecutionDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                            });
                          }
                        },
                        controller: TextEditingController(text: orderExecutionDate),
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        decoration: _fantasticInputDecoration('Any other Remarks'),
                        onChanged: (v) => remarks = v,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      isExceptionReasonLoading
                          ? const LinearProgressIndicator()
                          : exceptionReasonError != null
                              ? Text(exceptionReasonError!, style: const TextStyle(color: Colors.red))
                              : DropdownButtonFormField<String>(
                                  value: _dropdownValue(cityReason, exceptionReasonOptions),
                                  decoration: _fantasticInputDecoration('Select Reason'),
                                  items: exceptionReasonOptions
                                      .map((e) => DropdownMenuItem<String>(
                                            value: e['value']?.toString() ?? '',
                                            child: Text('${e['text'] ?? e['value'] ?? ''} (${e['value'] ?? ''})'),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => cityReason = v ?? ''),
                                ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Map/Location Placeholder ---
                const _SectionHeader(icon: Icons.map, label: 'Map/Location'),
                const _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: SparshSpacing.xs),
                      Text('Map/Location (to be implemented)'),
                      SizedBox(height: SparshSpacing.lg, child: Center(child: Text('Map widget placeholder'))),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Last Billing date as per Tally ---
                const _SectionHeader(icon: Icons.receipt_long, label: 'Last Billing date as per Tally'),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Table(
                        border: TableBorder.all(color: SparshTheme.borderGrey),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(1),
                        },
                        children: [
                          const TableRow(children: [
                            Padding(
                              padding: EdgeInsets.all(SparshSpacing.xs),
                              child: Text('Product', style: SparshTypography.bodyBold),
                            ),
                            Padding(
                              padding: EdgeInsets.all(SparshSpacing.xs),
                              child: Text('Date', style: SparshTypography.bodyBold),
                            ),
                            Padding(
                              padding: EdgeInsets.all(SparshSpacing.xs),
                              child: Text('Qty.', style: SparshTypography.bodyBold),
                            ),
                          ]),
                          ...lastBillingData.map((row) => TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.all(SparshSpacing.xs),
                              child: Text(row['product'] ?? ''),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(SparshSpacing.xs),
                              child: Text(row['date'] ?? ''),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(SparshSpacing.xs),
                              child: Text(row['qty'] ?? ''),
                            ),
                          ])),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.xl),
                // --- Bottom Action Buttons ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: SparshTheme.primaryBlue, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.lg)),
                        padding: const EdgeInsets.symmetric(vertical: SparshSpacing.lg),
                      ),
                      onPressed: () {
                        // TODO: Add another activity logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Add Another Activity (mock)')),
                        );
                      },
                      child: const Text('Add Another Activity', style: SparshTypography.bodyBold),
                    ),
                    const SizedBox(height: SparshSpacing.sm),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SparshTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.lg)),
                        padding: const EdgeInsets.symmetric(vertical: SparshSpacing.lg),
                      ),
                      onPressed: isSubmitting ? null : _submitForm,
                      child: const Text('Submit & Exit', style: SparshTypography.bodyBold),
                    ),
                    if (isSubmitting) const LinearProgressIndicator(),
                    const SizedBox(height: SparshSpacing.sm),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: SparshTheme.primaryBlueAccent, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.lg)),
                        padding: const EdgeInsets.symmetric(vertical: SparshSpacing.lg),
                      ),
                      onPressed: () {
                        // TODO: Show submitted data logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Show Submitted Data (mock)')),
                        );
                      },
                      child: const Text('Click to See Submitted Data', style: SparshTypography.bodyBold),
                    ),
                  ],
                ),
                const SizedBox(height: SparshSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Fantastic Section Header Widget ---
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    double fontSize = MediaQuery.of(context).size.width < 350 ? 14 : 16;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, top: SparshSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: SparshTheme.primaryBlue, size: 22),
          const SizedBox(width: SparshSpacing.xs),
          Text(
            label,
            style: SparshTypography.heading5.copyWith(fontSize: fontSize),
          ),
        ],
      ),
    );
  }
}

// --- Fantastic Card Widget ---
class _FantasticCard extends StatelessWidget {
  final Widget child;
  const _FantasticCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(SparshSpacing.md),
        child: child,
      ),
    );
  }
}

// --- Fantastic Input Decoration Helper ---
InputDecoration _fantasticInputDecoration(String label, {IconData? icon}) {
  return InputDecoration(
    labelText: label.isNotEmpty ? label : null,
    filled: true,
              fillColor: SparshTheme.lightGreyBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SparshBorderRadius.md),
      borderSide: const BorderSide(color: SparshTheme.borderGrey, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SparshBorderRadius.md),
      borderSide: const BorderSide(color: SparshTheme.borderGrey, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SparshBorderRadius.md),
      borderSide: const BorderSide(color: SparshTheme.primaryBlue, width: 2),
    ),
    suffixIcon: icon != null ? Icon(icon, size: 20) : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: SparshSpacing.md, vertical: SparshSpacing.sm),
  );
}
