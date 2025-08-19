import 'dart:convert';
import 'package:flutter/material.dart';

// import 'package:free_map/free_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:flutter_map/flutter_map.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/dsr_activity_service.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'dsr_exception_entry.dart';
import 'package:learning2/core/services/session_manager.dart';

class DsrVisitScreen extends StatefulWidget {
  final String? docuNumb;
  const DsrVisitScreen({super.key, this.docuNumb});

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
  String? kycStatus = '';
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
  String _loginId = '';

  // Dynamic lists
  List<Map<String, String>> productList = [];
  List<TextEditingController> productQtyControllers = [];
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

  // Averages (from API)
  Map<String, String> last3MonthsAvg = {
    'JK_WC': '',
    'JK_WCP': '',
    'AS_WC': '',
    'AS_WCP': '',
    'OT_WC': '',
    'OT_WCP': '',
  };
  Map<String, String> currentMonthBW = {
    'BW_WC': '',
    'BW_WCP': '',
    'BW_VAP': '',
  };

  // Last 3 months average BW (from API)
  Map<String, String> last3MonthBW = {'BW_WC': '', 'BW_WCP': '', 'BW_VAP': ''};

  final _formKey = GlobalKey<FormState>();

  // Service
  final DSRActivityService _dsrService = DSRActivityService();

  @override
  void initState() {
    super.initState();
    _loadLoginId();
    _fetchDropdowns();
    _fetchOtherDropdowns();

    if (widget.docuNumb != null) {
      processType = 'U'; // Set to update mode if docuNumb is provided
      _fetchDSRDetailsForEdit(widget.docuNumb!);
    } else {
      // Add one row by default for each dynamic list only in add mode
      if (productList.isEmpty) addProductRow();
      if (giftList.isEmpty) addGiftRow();
      if (marketSkuList.isEmpty) addMarketSkuRow();
      marketNameController.text = marketName ?? '';
      nameController.text = name ?? '';
      kycStatusController.text = kycStatus ?? '';
      wcEnrolmentController.text = wcEnrolment ?? '';
      wcpEnrolmentController.text = wcpEnrolment ?? '';
      vapEnrolmentController.text = vapEnrolment ?? '';
      wcStockController.text = wcStock ?? '';
      wcpStockController.text = wcpStock ?? '';
      vapStockController.text = vapStock ?? '';
      slWcVolumeController.text = slWcVolume ?? '';
      slWpVolumeController.text = slWpVolume ?? '';
      jkWcController.text = last3MonthsAvg['JK_WC'] ?? '';
      jkWcpController.text = last3MonthsAvg['JK_WCP'] ?? '';
      asWcController.text = last3MonthsAvg['AS_WC'] ?? '';
      asWcpController.text = last3MonthsAvg['AS_WCP'] ?? '';
      otWcController.text = last3MonthsAvg['OT_WC'] ?? '';
      otWcpController.text = last3MonthsAvg['OT_WCP'] ?? '';
      bwWcController.text = last3MonthBW['BW_WC'] ?? '';
      bwWcpController.text = last3MonthBW['BW_WCP'] ?? '';
      bwVapController.text = last3MonthBW['BW_VAP'] ?? '';
      currentWcController.text = currentMonthBW['BW_WC'] ?? '';
      currentWcpController.text = currentMonthBW['BW_WCP'] ?? '';
      currentVapController.text = currentMonthBW['BW_VAP'] ?? '';
    }
  }

  Future<void> _loadLoginId() async {
    _loginId = await SessionManager.getLoginId() ?? '';
    if (mounted) setState(() {});
  }

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

  // Pending DSR entries for Update/Delete mode
  List<Map<String, dynamic>> pendingDSREntries = [];
  bool isPendingDSRLoading = false;
  String? pendingDSRError;
  String? selectedPendingDSR;

  final TextEditingController marketNameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController kycStatusController = TextEditingController();
  final TextEditingController wcEnrolmentController = TextEditingController();
  final TextEditingController wcpEnrolmentController = TextEditingController();
  final TextEditingController vapEnrolmentController = TextEditingController();
  final TextEditingController wcStockController = TextEditingController();
  final TextEditingController wcpStockController = TextEditingController();
  final TextEditingController vapStockController = TextEditingController();
  final TextEditingController slWcVolumeController = TextEditingController();
  final TextEditingController slWpVolumeController = TextEditingController();
  final TextEditingController jkWcController = TextEditingController();
  final TextEditingController jkWcpController = TextEditingController();
  final TextEditingController asWcController = TextEditingController();
  final TextEditingController asWcpController = TextEditingController();
  final TextEditingController otWcController = TextEditingController();
  final TextEditingController otWcpController = TextEditingController();
  final TextEditingController bwWcController = TextEditingController();
  final TextEditingController bwWcpController = TextEditingController();
  final TextEditingController bwVapController = TextEditingController();
  final TextEditingController currentWcController = TextEditingController();
  final TextEditingController currentWcpController = TextEditingController();
  final TextEditingController currentVapController = TextEditingController();
  final TextEditingController tileAdhesiveStockController =
      TextEditingController();
  final TextEditingController issueDetailController = TextEditingController();

  // Market SKU controllers for dynamic list
  List<TextEditingController> marketSkuProductControllers = [];
  List<TextEditingController> marketSkuPriceBControllers = [];
  List<TextEditingController> marketSkuPriceCControllers = [];

  // Gift distribution controllers for dynamic list
  List<TextEditingController> giftQtyControllers = [];
  List<TextEditingController> giftNarationControllers = [];

  // Remarks controller
  final TextEditingController remarksController = TextEditingController();

  // Location related variables

  bool isLoadingLocation = false;
  String? locationError;

  final List<String> pendingIssueDetails = [
    'Token',
    'Scheme',
    'Product',
    'Other',
  ];
  final List<String> cityReasons = [
    'Network Issue',
    'Battery Low',
    'Mobile Not working',
    'Location not capturing',
    'Wrong Location OF Retailer',
    'Wrong Location Captured',
  ];
  final List<String> tileAdhesiveOptions = ['YES', 'NO'];

  // Helper to add product row
  void addProductRow() {
    setState(() {
      productList.add({'category': '', 'sku': '', 'qty': ''});
      productQtyControllers.add(TextEditingController());
    });
  }

  void removeProductRow(int index) {
    setState(() {
      productList.removeAt(index);
      productQtyControllers[index].dispose();
      productQtyControllers.removeAt(index);
    });
  }

  // Helper to add gift row
  void addGiftRow() {
    setState(() {
      giftList.add({'giftType': '', 'qty': '', 'naration': ''});

      // Create controllers for the new row
      giftQtyControllers.add(TextEditingController());
      giftNarationControllers.add(TextEditingController());
    });
  }

  void removeGiftRow(int index) {
    setState(() {
      giftList.removeAt(index);

      // Dispose controllers for the removed row
      if (index < giftQtyControllers.length) {
        giftQtyControllers[index].dispose();
        giftQtyControllers.removeAt(index);
      }
      if (index < giftNarationControllers.length) {
        giftNarationControllers[index].dispose();
        giftNarationControllers.removeAt(index);
      }
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

      // Create controllers for the new row
      marketSkuProductControllers.add(TextEditingController());
      marketSkuPriceBControllers.add(TextEditingController());
      marketSkuPriceCControllers.add(TextEditingController());
    });
  }

  void removeMarketSkuRow(int index) {
    setState(() {
      marketSkuList.removeAt(index);

      // Dispose controllers for the removed row
      if (index < marketSkuProductControllers.length) {
        marketSkuProductControllers[index].dispose();
        marketSkuProductControllers.removeAt(index);
      }
      if (index < marketSkuPriceBControllers.length) {
        marketSkuPriceBControllers[index].dispose();
        marketSkuPriceBControllers.removeAt(index);
      }
      if (index < marketSkuPriceCControllers.length) {
        marketSkuPriceCControllers[index].dispose();
        marketSkuPriceCControllers.removeAt(index);
      }
    });
  }

  // Helper to safely get dropdown value
  String? _dropdownValue(
    String? value,
    List<Map<String, dynamic>> options, {
    String valueKey = 'value',
  }) {
    if (value == null) return null;

    // Treat empty/whitespace selections as no selection
    if (value.trim().isEmpty) return null;

    // Handle different possible key structures and ignore empty values
    final values =
        options
            .map((e) {
              final v =
                  e[valueKey]?.toString() ??
                  e['Code']?.toString() ??
                  e['code']?.toString() ??
                  e['value']?.toString() ??
                  '';
              return v.trim();
            })
            .where((v) => v.isNotEmpty)
            .toSet();

    return values.contains(value.trim()) ? value.trim() : null;
  }

  // Remove fully empty entries and de-duplicate by code (or desc when code missing)
  List<Map<String, dynamic>> _sanitizeOptions(
    List<Map<String, dynamic>> options,
  ) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final e in options) {
      final code =
          (e['Code'] ?? e['code'] ?? e['value'] ?? '').toString().trim();
      final desc =
          (e['Description'] ?? e['description'] ?? e['text'] ?? e['name'] ?? '')
              .toString()
              .trim();
      if (code.isEmpty && desc.isEmpty) continue;
      final key = code.isNotEmpty ? code : desc;
      if (seen.contains(key)) continue;
      seen.add(key);
      result.add(e);
    }
    return result;
  }

  // ---- Option helpers for pickers ----
  String _optCode(Map<String, dynamic> e) {
    return (e['Code'] ?? e['code'] ?? e['value'] ?? '').toString();
  }

  String _optText(Map<String, dynamic> e) {
    final code = _optCode(e);
    final desc =
        (e['Description'] ?? e['description'] ?? e['text'] ?? e['name'] ?? '')
            .toString();
    if (desc.isNotEmpty && code.isNotEmpty) return '$desc ($code)';
    if (desc.isNotEmpty) return desc;
    if (code.isNotEmpty) return code;
    return 'Unknown';
  }

  Future<String?> _showOptionPicker({
    required String title,
    required List<Map<String, dynamic>> options,
  }) async {
    if (options.isEmpty) return null;
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        final opts = _sanitizeOptions(options);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: SparshTypography.heading5),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: opts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final item = opts[i];
                    final code = _optCode(item);
                    final label = _optText(item);
                    return ListTile(
                      title: Text(label),
                      onTap: () => Navigator.of(ctx).pop(code),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // Location methods

  @override
  void dispose() {
    // Dispose all the individual field controllers
    marketNameController.dispose();
    nameController.dispose();
    kycStatusController.dispose();
    wcEnrolmentController.dispose();
    wcpEnrolmentController.dispose();
    vapEnrolmentController.dispose();
    wcStockController.dispose();
    wcpStockController.dispose();
    vapStockController.dispose();
    slWcVolumeController.dispose();
    slWpVolumeController.dispose();
    jkWcController.dispose();
    jkWcpController.dispose();
    asWcController.dispose();
    asWcpController.dispose();
    otWcController.dispose();
    otWcpController.dispose();
    bwWcController.dispose();
    bwWcpController.dispose();
    bwVapController.dispose();
    currentWcController.dispose();
    currentWcpController.dispose();
    currentVapController.dispose();
    tileAdhesiveStockController.dispose();
    issueDetailController.dispose();

    // Dispose product quantity controllers
    for (var controller in productQtyControllers) {
      controller.dispose();
    }
    productQtyControllers.clear();

    // Dispose market SKU controllers
    for (var controller in marketSkuProductControllers) {
      controller.dispose();
    }
    marketSkuProductControllers.clear();
    for (var controller in marketSkuPriceBControllers) {
      controller.dispose();
    }
    marketSkuPriceBControllers.clear();
    for (var controller in marketSkuPriceCControllers) {
      controller.dispose();
    }
    marketSkuPriceCControllers.clear();

    // Dispose gift distribution controllers
    for (var controller in giftQtyControllers) {
      controller.dispose();
    }
    giftQtyControllers.clear();
    for (var controller in giftNarationControllers) {
      controller.dispose();
    }
    giftNarationControllers.clear();

    // Dispose remarks controller
    remarksController.dispose();

    super.dispose();
  }

  Future<void> _fetchDSRDetailsForEdit(String docuNumb) async {
    try {
      final response = await _dsrService.getDSRForEdit(docuNumb, _loginId);

      // Check if response is successful
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to fetch DSR details');
      }

      final data = response['data'];
      final header = data['header'];
      final enrolment = data['enrolment'];
      final currentMonthBWData = data['currentMonthBW'];
      final last3MonthsAverageBW = data['last3MonthsAverageBW'];
      final customer = data['customer'];

      setState(() {
        // Header details
        documentNo = header['docuNumb']?.toString() ?? '';
        reportDate = header['docuDate']?.toString() ?? '';
        orderExecutionDate = header['ordExDat']?.toString() ?? '';
        purchaserType = header['cusRtlFl']?.toString() ?? '';
        areaCode = header['areaCode']?.toString() ?? '';
        purchaserCode = header['cusRtlCd']?.toString() ?? '';
        marketName = header['mrktName']?.toString() ?? '';
        displayContest = header['prtDsCnt']?.toString() ?? '';
        pendingIssue = header['pendIsue']?.toString() ?? '';
        pendingIssueDetail = header['pndIsuDt']?.toString() ?? '';
        issueDetail = header['isuDetal']?.toString() ?? '';
        remarks = header['dsrRem05']?.toString() ?? '';
        slWcVolume = header['slWcVlum']?.toString() ?? '';
        slWpVolume = header['slWpVlum']?.toString() ?? '';

        // Update controllers
        remarksController.text = remarks ?? '';
        issueDetailController.text = issueDetail ?? '';

        // Update industry volume controllers
        slWcVolumeController.text = slWcVolume ?? '';
        slWpVolumeController.text = slWpVolume ?? '';

        // Map cityName to dropdown options - the API returns codes, we need to handle this properly
        final cityNameValue = header['cityName']?.toString() ?? '';
        // For now, use the raw value and let the dropdown handle validation
        cityReason = cityNameValue;

        // Tile Adhesive fields
        final isTilRtlValue = header['isTilRtl']?.toString();
        if (isTilRtlValue == 'Y') {
          tileAdhesiveSeller = 'YES';
        } else if (isTilRtlValue == 'N') {
          tileAdhesiveSeller = 'NO';
        } else {
          tileAdhesiveSeller = null;
        }
        tileAdhesiveStock = header['tileStck']?.toString() ?? '';
        tileAdhesiveStockController.text = tileAdhesiveStock ?? '';

        // Customer details
        if (customer != null) {
          name = customer['name']?.toString() ?? '';
          kycStatus = customer['kycStatus']?.toString() ?? '';
          nameController.text = name ?? '';

          // Update market name from customer if not already set from header
          if (marketName?.isEmpty ?? true) {
            marketName = customer['marketName']?.toString() ?? '';
          }
          marketNameController.text = marketName ?? '';

          // Display Y/N as Yes/No for KYC Status
          if (kycStatus == 'Y') {
            kycStatusController.text = 'Yes';
          } else if (kycStatus == 'N') {
            kycStatusController.text = 'No';
          } else {
            kycStatusController.text = kycStatus ?? '';
          }
        }

        // Enrolment Slab - map from the enrolment structure
        if (enrolment != null) {
          wcEnrolment = enrolment['wcErlSlb']?.toString() ?? '';
          wcpEnrolment = enrolment['wpErlSlb']?.toString() ?? '';
          vapEnrolment = enrolment['vpErlSlb']?.toString() ?? '';

          // Update controllers
          wcEnrolmentController.text = wcEnrolment ?? '';
          wcpEnrolmentController.text = wcpEnrolment ?? '';
          vapEnrolmentController.text = vapEnrolment ?? '';
        }

        // BW Stocks Availability - map from the stockAvailability in currentMonthBW
        if (currentMonthBWData != null &&
            currentMonthBWData['stockAvailability'] != null) {
          final stockData = currentMonthBWData['stockAvailability'];
          wcStock = stockData['wcStock']?.toString() ?? '';
          wcpStock = stockData['wcpStock']?.toString() ?? '';
          vapStock = stockData['vapStock']?.toString() ?? '';
        } else {
          // Fallback if stocks are provided in header or not available
          wcStock = header['wcStock']?.toString() ?? wcStock;
          wcpStock = header['wcpStock']?.toString() ?? wcpStock;
          vapStock = header['vapStock']?.toString() ?? vapStock;
        }

        // Update controllers
        wcStockController.text = wcStock ?? '';
        wcpStockController.text = wcpStock ?? '';
        vapStockController.text = vapStock ?? '';

        // Reset brand selections then set from header arrays
        brandsWc.updateAll((key, value) => false);
        brandsWcp.updateAll((key, value) => false);

        if (header['brndSlWc'] is List) {
          final List<dynamic> brndSlWc = header['brndSlWc'];
          for (final brand in brndSlWc) {
            final brandStr = brand?.toString().trim() ?? '';
            if (brandStr.isNotEmpty && brandsWc.containsKey(brandStr)) {
              brandsWc[brandStr] = true;
            }
          }
        }

        if (header['brndSlWp'] is List) {
          final List<dynamic> brndSlWp = header['brndSlWp'];
          for (final brand in brndSlWp) {
            final brandStr = brand?.toString().trim() ?? '';
            if (brandStr.isNotEmpty && brandsWcp.containsKey(brandStr)) {
              brandsWcp[brandStr] = true;
            }
          }
        }

        // Last 3 Months Average (Competitors) - map from the competitors data
        if (last3MonthsAverageBW != null &&
            last3MonthsAverageBW['competitors'] != null) {
          final competitors = last3MonthsAverageBW['competitors'];

          if (competitors['jk'] != null) {
            last3MonthsAvg['JK_WC'] = competitors['jk']['wc']?.toString() ?? '';
            last3MonthsAvg['JK_WCP'] =
                competitors['jk']['wcp']?.toString() ?? '';
            jkWcController.text = competitors['jk']['wc']?.toString() ?? '';
            jkWcpController.text = competitors['jk']['wcp']?.toString() ?? '';
          }

          if (competitors['asian'] != null) {
            last3MonthsAvg['AS_WC'] =
                competitors['asian']['wc']?.toString() ?? '';
            last3MonthsAvg['AS_WCP'] =
                competitors['asian']['wcp']?.toString() ?? '';
            asWcController.text = competitors['asian']['wc']?.toString() ?? '';
            asWcpController.text =
                competitors['asian']['wcp']?.toString() ?? '';
          }

          if (competitors['others'] != null) {
            last3MonthsAvg['OT_WC'] =
                competitors['others']['wc']?.toString() ?? '';
            last3MonthsAvg['OT_WCP'] =
                competitors['others']['wcp']?.toString() ?? '';
            otWcController.text = competitors['others']['wc']?.toString() ?? '';
            otWcpController.text =
                competitors['others']['wcp']?.toString() ?? '';
          }
        }

        // Current Month - BW - map from the currentMonthBW data
        if (currentMonthBWData != null) {
          currentMonthBW['BW_WC'] =
              currentMonthBWData['wcCurrent']?.toString() ?? '';
          currentMonthBW['BW_WCP'] =
              currentMonthBWData['wcpCurrent']?.toString() ?? '';
          currentMonthBW['BW_VAP'] =
              currentMonthBWData['vapCurrent']?.toString() ?? '';
          currentWcController.text =
              currentMonthBWData['wcCurrent']?.toString() ?? '';
          currentWcpController.text =
              currentMonthBWData['wcpCurrent']?.toString() ?? '';
          currentVapController.text =
              currentMonthBWData['vapCurrent']?.toString() ?? '';
        }

        // Last 3 Months Average - BW - map from the last3MonthsAverageBW data
        if (last3MonthsAverageBW != null) {
          last3MonthBW['BW_WC'] =
              last3MonthsAverageBW['wcAverage']?.toString() ?? '';
          last3MonthBW['BW_WCP'] =
              last3MonthsAverageBW['wcpAverage']?.toString() ?? '';
          last3MonthBW['BW_VAP'] =
              last3MonthsAverageBW['vapAverage']?.toString() ?? '';
          bwWcController.text =
              last3MonthsAverageBW['wcAverage']?.toString() ?? '';
          bwWcpController.text =
              last3MonthsAverageBW['wcpAverage']?.toString() ?? '';
          bwVapController.text =
              last3MonthsAverageBW['vapAverage']?.toString() ?? '';
        }

        // Order Booked in call/e meet (Products) - map from orderBookedInCallMeet
        productList = [];
        // Clear existing controllers
        for (var controller in productQtyControllers) {
          controller.dispose();
        }
        productQtyControllers.clear();

        if (data['orderBookedInCallMeet'] != null &&
            data['orderBookedInCallMeet']['orders'] != null) {
          final orders =
              data['orderBookedInCallMeet']['orders'] as List<dynamic>;
          productList =
              orders
                  .map(
                    (e) => {
                      'category': e['repoCatg']?.toString() ?? '',
                      'sku': e['catgPkPr']?.toString() ?? '',
                      'qty': e['prodQnty']?.toString() ?? '',
                    },
                  )
                  .toList();

          // Create controllers for each product and set their values
          for (var product in productList) {
            final controller = TextEditingController();
            controller.text = product['qty'] ?? '';
            productQtyControllers.add(controller);
          }
        }
        if (productList.isEmpty) addProductRow(); // Ensure at least one row

        // Market -- WCP (Highest selling SKU) - map from marketWCPHighestSellingSKU
        marketSkuList = [];
        // Clear existing controllers
        for (var controller in marketSkuProductControllers) {
          controller.dispose();
        }
        marketSkuProductControllers.clear();
        for (var controller in marketSkuPriceBControllers) {
          controller.dispose();
        }
        marketSkuPriceBControllers.clear();
        for (var controller in marketSkuPriceCControllers) {
          controller.dispose();
        }
        marketSkuPriceCControllers.clear();

        if (data['marketWCPHighestSellingSKU'] != null &&
            data['marketWCPHighestSellingSKU']['marketIntelligence'] != null) {
          final marketIntell =
              data['marketWCPHighestSellingSKU']['marketIntelligence']
                  as List<dynamic>;
          marketSkuList =
              marketIntell
                  .map(
                    (e) => {
                      'brand': e['brandName']?.toString() ?? '',
                      'product': e['productCode']?.toString() ?? '',
                      'priceB': e['priceB']?.toString() ?? '',
                      'priceC': e['priceC']?.toString() ?? '',
                    },
                  )
                  .toList();

          // Create controllers for each market SKU and set their values
          for (var marketSku in marketSkuList) {
            final productController = TextEditingController();
            productController.text = marketSku['product'] ?? '';
            marketSkuProductControllers.add(productController);

            final priceBController = TextEditingController();
            priceBController.text = marketSku['priceB'] ?? '';
            marketSkuPriceBControllers.add(priceBController);

            final priceCController = TextEditingController();
            priceCController.text = marketSku['priceC'] ?? '';
            marketSkuPriceCControllers.add(priceCController);
          }
        }
        if (marketSkuList.isEmpty) addMarketSkuRow(); // Ensure at least one row

        // Gift Distribution - map from giftDistribution
        giftList = [];
        // Clear existing controllers
        for (var controller in giftQtyControllers) {
          controller.dispose();
        }
        giftQtyControllers.clear();
        for (var controller in giftNarationControllers) {
          controller.dispose();
        }
        giftNarationControllers.clear();

        if (data['giftDistribution'] != null &&
            data['giftDistribution']['gifts'] != null) {
          final gifts = data['giftDistribution']['gifts'] as List<dynamic>;
          giftList =
              gifts
                  .map(
                    (e) => {
                      'giftType': e['mrtlCode']?.toString().trim() ?? '',
                      'qty': e['isueQnty']?.toString() ?? '',
                      'naration': e['naration']?.toString() ?? '',
                    },
                  )
                  .toList();

          // Create controllers for each gift and set their values
          for (var gift in giftList) {
            final qtyController = TextEditingController();
            qtyController.text = gift['qty'] ?? '';
            giftQtyControllers.add(qtyController);

            final narationController = TextEditingController();
            narationController.text = gift['naration'] ?? '';
            giftNarationControllers.add(narationController);
          }
        }
        if (giftList.isEmpty) addGiftRow(); // Ensure at least one row

        print('DSR details loaded successfully for document: $docuNumb');
        print('Loaded data summary:');
        print('- Header: ${header != null}');
        print('- Customer: ${customer?['name']} (${customer?['code']})');
        print('- Products: ${productList.length}');
        print('- Market SKUs: ${marketSkuList.length}');
        print('- Gifts: ${giftList.length}');
        print(
          '- Brands WC: ${brandsWc.entries.where((e) => e.value).map((e) => e.key).toList()}',
        );
        print(
          '- Brands WCP: ${brandsWcp.entries.where((e) => e.value).map((e) => e.key).toList()}',
        );
      });

      // Fetch products for each category that has data in productList
      for (final product in productList) {
        final category = product['category'];
        if (category != null && category.isNotEmpty) {
          try {
            await _fetchProductsForCategory(category);
          } catch (e) {
            print('Error fetching products for category $category: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading DSR details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load DSR details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        exceptionReasonOptions = _sanitizeOptions(reasons);
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
        giftTypeOptions = _sanitizeOptions(gifts);
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
        brandOptions = _sanitizeOptions(brands);
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
      print('Product Categories API Response: $categories');
      setState(() {
        productCategoryOptions = _sanitizeOptions(categories);
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
      print('Products for category $category: $products');
      productsByCategory[category] = _sanitizeOptions(products);
      isProductLoading[category] = false;
      setState(() {});
    } catch (e) {
      productError[category] = 'Failed to load products';
      isProductLoading[category] = false;
      setState(() {});
    }
  }

  /// Handle process type change and load appropriate data
  Future<void> _onProcessTypeChanged(String newProcessType) async {
    setState(() {
      processType = newProcessType;
      selectedPendingDSR = null;
      documentNo = null;
    });

    if (processType == 'U' || processType == 'D') {
      // Load pending DSR entries for Update/Delete mode
      await _fetchPendingDSREntries();
    } else {
      // Add mode - clear form and reset lists
      _resetForm();
    }
  }

  /// Fetch pending DSR entries for the user
  Future<void> _fetchPendingDSREntries() async {
    print('_fetchPendingDSREntries called for loginId: $_loginId'); // Debug log
    setState(() {
      isPendingDSRLoading = true;
      pendingDSRError = null;
    });

    try {
      final entries = await _dsrService.getPendingDSR(_loginId);
      print('Pending DSR entries received: $entries'); // Debug log
      print('Number of entries: ${entries.length}'); // Debug log

      // Debug: print each entry structure
      for (int i = 0; i < entries.length; i++) {
        print('Entry $i: ${entries[i]}');
        print('Entry $i keys: ${entries[i].keys.toList()}');
      }

      setState(() {
        pendingDSREntries = entries;
        isPendingDSRLoading = false;
      });
    } catch (e) {
      print('Error fetching pending DSR entries: $e'); // Debug log
      setState(() {
        pendingDSRError = 'Failed to load pending DSR entries: $e';
        isPendingDSRLoading = false;
      });
    }
  }

  /// Reset form to default state for Add mode
  void _resetForm() {
    setState(() {
      documentNo = null;
      purchaserType = null;
      areaCode = null;
      purchaserCode = null;
      marketName = null;
      displayContest = null;
      pendingIssue = null;
      pendingIssueDetail = null;
      issueDetail = null;
      wcEnrolment = null;
      wcpEnrolment = null;
      vapEnrolment = null;
      wcStock = null;
      wcpStock = null;
      vapStock = null;
      slWcVolume = null;
      slWpVolume = null;
      orderExecutionDate = null;
      remarks = null;
      cityReason = null;
      tileAdhesiveSeller = null;
      tileAdhesiveStock = null;
      tileAdhesiveStockController.clear();
      name = '';
      kycStatus = '';

      // Clear lists and add default rows
      productList.clear();
      // Clear and dispose product quantity controllers
      for (var controller in productQtyControllers) {
        controller.dispose();
      }
      productQtyControllers.clear();

      // Clear and dispose market SKU controllers
      for (var controller in marketSkuProductControllers) {
        controller.dispose();
      }
      marketSkuProductControllers.clear();
      for (var controller in marketSkuPriceBControllers) {
        controller.dispose();
      }
      marketSkuPriceBControllers.clear();
      for (var controller in marketSkuPriceCControllers) {
        controller.dispose();
      }
      marketSkuPriceCControllers.clear();

      // Clear and dispose gift controllers
      for (var controller in giftQtyControllers) {
        controller.dispose();
      }
      giftQtyControllers.clear();
      for (var controller in giftNarationControllers) {
        controller.dispose();
      }
      giftNarationControllers.clear();

      giftList.clear();
      marketSkuList.clear();
      addProductRow();
      addGiftRow();
      addMarketSkuRow();

      // Reset controllers
      marketNameController.clear();
      nameController.clear();
      kycStatusController.text = kycStatus ?? '';
      wcEnrolmentController.clear();
      wcpEnrolmentController.clear();
      vapEnrolmentController.clear();
      wcStockController.clear();
      wcpStockController.clear();
      vapStockController.clear();
      slWcVolumeController.clear();
      slWpVolumeController.clear();
      jkWcController.clear();
      jkWcpController.clear();
      asWcController.clear();
      asWcpController.clear();
      otWcController.clear();
      otWcpController.clear();
      bwWcController.clear();
      bwWcpController.clear();
      bwVapController.clear();
      currentWcController.clear();
      currentWcpController.clear();
      currentVapController.clear();
      remarksController.clear();
      issueDetailController.clear();

      // Reset checkboxes
      brandsWc.updateAll((key, value) => false);
      brandsWcp.updateAll((key, value) => false);
    });
  }

  String _generateFrontendFallbackDocNumber(String areaCode) {
    final now = DateTime.now().toUtc();

    // Format: DSR + AreaCode(3) + YYMMDDHHMMSS
    final year = (now.year % 100).toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    final timestamp = '$year$month$day$hour$minute$second';
    final areaCodePadded =
        areaCode.length >= 3
            ? areaCode.substring(0, 3)
            : areaCode.padRight(3, '0');
    final fallbackDocNumber = 'DSR$areaCodePadded$timestamp';

    // Ensure it's exactly 16 characters
    final finalDocNumber =
        fallbackDocNumber.length > 16
            ? fallbackDocNumber.substring(0, 16)
            : fallbackDocNumber.padRight(16, '0');

    return finalDocNumber;
  }

  bool isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    try {
      // Guard: Do not allow submission if Report Date is 3 or more days old
      DateTime? _parseReportDate(String? s) {
        if (s == null || s.trim().isEmpty) return null;
        final t = s.trim();
        // Try DD/MM/YYYY
        final m = RegExp(r'^(\d{2})\/(\d{2})\/(\d{4})$').firstMatch(t);
        if (m != null) {
          final day = int.tryParse(m.group(1)!);
          final mon = int.tryParse(m.group(2)!);
          final yr = int.tryParse(m.group(3)!);
          if (day != null && mon != null && yr != null) {
            return DateTime(yr, mon, day);
          }
        }
        // Try ISO-like (YYYY-MM-DD or with time)
        try {
          final iso = t.contains('T') ? t.split('T').first : t.split(' ').first;
          return DateTime.parse(iso);
        } catch (_) {}
        return null;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selected = _parseReportDate(reportDate);
      if (selected != null) {
        final sel = DateTime(selected.year, selected.month, selected.day);
        final diffDays = today.difference(sel).inDays;
        if (diffDays >= 3) {
          // 3 or more days old: block submission
          setState(() => isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Submission blocked: Report Date must be within the last 3 days .',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // For new DSR (processType = 'A'), generate document number from backend
      // For update/delete operations, use the selected pending DSR document number
      String docNumber = '';

      if (processType == 'A') {
        // Add mode - generate new document number
        // Validate that areaCode is available for document generation
        if (areaCode == null || areaCode!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Area Code is required for document generation'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isSubmitting = false);
          return;
        }

        // Try to generate document number from backend
        try {
          print(
            'DSR Visit Screen - Generating document number from backend for area: $areaCode',
          );
          final generatedDocNumber = await _dsrService.generateDocumentNumber(
            areaCode!,
          );

          if (generatedDocNumber != null &&
              generatedDocNumber.isNotEmpty &&
              generatedDocNumber.trim().isNotEmpty) {
            docNumber = generatedDocNumber.trim();
            print(
              'DSR Visit Screen - Using backend generated document number: "$docNumber"',
            );
          } else {
            // Backend failed or returned empty/spaces, use fallback frontend generation
            print(
              'DSR Visit Screen - Backend document generation failed, using fallback method',
            );
            docNumber = _generateFrontendFallbackDocNumber(areaCode!);
            print(
              'DSR Visit Screen - Generated fallback document number: "$docNumber"',
            );
          }
        } catch (e) {
          print(
            'DSR Visit Screen - Error calling backend document generation: $e, using fallback method',
          );
          // Fallback to frontend generation
          docNumber = _generateFrontendFallbackDocNumber(areaCode!);
          print(
            'DSR Visit Screen - Generated fallback document number: "$docNumber"',
          );
        }

        // For Add operations, keep document number empty for API generation
        docNumber = '';
        print(
          'DSR Visit Screen - Add operation: using empty document number for API generation',
        );
      } else {
        // Update/Delete mode - use the selected pending DSR document number
        if (selectedPendingDSR == null || selectedPendingDSR!.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please select a DSR document for Update/Delete operation',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isSubmitting = false);
          return;
        }

        docNumber = selectedPendingDSR!.trim();
        print(
          'DSR Visit Screen - Using selected pending DSR document number: "$docNumber"',
        );
      }

      print('Process Type: $processType');
      print(
        'Document Number being sent: "$docNumber" (length: ${docNumber.length})',
      );

      // Filter and validate products data - structure for dptDSRActvtDtl table
      final List<Map<String, dynamic>> productsData =
          productList
              .where(
                (p) =>
                    p['category'] != null &&
                    p['category']!.isNotEmpty &&
                    p['sku'] != null &&
                    p['sku']!.isNotEmpty &&
                    p['qty'] != null &&
                    p['qty']!.isNotEmpty,
              )
              .toList()
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key;
                final p = entry.value;
                return {
                  'seqNumb': (index + 1).toString().padLeft(
                    3,
                    '0',
                  ), // Sequence number starting from 001
                  'docuNumb': docNumber, // Document number for each activity
                  'repoCatg': p['category']?.toString() ?? '', // Category code
                  'catgPack': p['sku']?.toString() ?? '', // SKU/Product code
                  'prodQnty': p['qty']?.toString() ?? '', // Quantity as string
                  'projQnty': '', // Default value as string
                  'actnRemk': '', // Remarks
                  'mrktData': '05', // Market data type for products
                  'targetDt': null, // Target date
                  'statFlag': 'N', // Status flag
                };
              })
              .toList();

      print('Products data to be sent: $productsData');
      print('Number of products: ${productsData.length}');

      // Filter and validate market intelligence data
      final List<Map<String, dynamic>> marketIntelligenceData =
          marketSkuList
              .where(
                (m) =>
                    m['brand'] != null &&
                    m['brand']!.isNotEmpty &&
                    m['product'] != null &&
                    m['product']!.isNotEmpty,
              )
              .map(
                (m) => {
                  'BrandName': m['brand']?.toString() ?? '',
                  'ProductCode': m['product']?.toString() ?? '',
                  'PriceB': m['priceB']?.toString() ?? '',
                  'PriceC': m['priceC']?.toString() ?? '',
                },
              )
              .toList();

      print('Market intelligence data to be sent: $marketIntelligenceData');

      // Filter and validate gift distribution data - structure for dptGiftDist table
      final List<Map<String, dynamic>> giftDistributionData =
          giftList
              .where(
                (g) =>
                    g['giftType'] != null &&
                    g['giftType']!.isNotEmpty &&
                    g['qty'] != null &&
                    g['qty']!.isNotEmpty,
              )
              .toList()
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key;
                final g = entry.value;
                return {
                  'seqNumb': (productsData.length + index + 1)
                      .toString()
                      .padLeft(3, '0'), // Continue sequence after products
                  'docuNumb': docNumber, // Document number for each activity
                  'repoCatg':
                      g['giftType']?.toString() ??
                      '', // Gift/Material code as category
                  'catgPack':
                      g['giftType']?.toString() ??
                      '', // Gift/Material code as pack
                  'prodQnty': g['qty']?.toString() ?? '', // Quantity as string
                  'projQnty': '', // Default value
                  'actnRemk':
                      g['naration']?.toString() ?? '', // Description/remarks
                  'mrktData': '06', // Market data type for gifts
                  'targetDt': null, // Target date
                  'statFlag': 'N', // Status flag
                };
              })
              .toList();

      print('Gift distribution data to be sent: $giftDistributionData');
      print('Number of gifts: ${giftDistributionData.length}');

      // Ensure we have valid data structure - even if lists are empty, they should be present
      final Map<String, dynamic> dsrData = {
        'ProcType': processType,
        'DocuNumb':
            docNumber, // Use empty string for new DSR, existing for update/delete
        'DocuDate': reportDate ?? '',
        'OrdExDat': orderExecutionDate ?? '',
        'DsrParam': '04', // Default DSR parameter
        'CusRtlFl': purchaserType ?? '',
        'AreaCode': areaCode ?? '',
        'CusRtlCd': purchaserCode ?? '',
        'MrktName': marketName ?? '',
        'PendIsue': pendingIssue ?? 'N',
        'PndIsuDt': pendingIssueDetail ?? '',
        'IsuDetal': issueDetail ?? '',
        'DsrRem05': remarks ?? '',
        'BrndSlWc':
            brandsWc.entries.where((e) => e.value).map((e) => e.key).toList(),
        'BrndSlWp':
            brandsWcp.entries.where((e) => e.value).map((e) => e.key).toList(),
        'PrtDsCnt': displayContest ?? 'N',
        'SlWcVlum': slWcVolume ?? '',
        'SlWpVlum': slWpVolume ?? '',
        'DeptCode': '', // Default
        'PendWith': '', // Default
        'CreateId': _loginId,
        'FinlRslt': '', // Location capture
        'GeoLatit': '', // GPS coordinates
        'GeoLongt': '', // GPS coordinates
        'LtLgDist': '', // Distance
        'CityName': cityReason ?? '',
        'CusRtTyp': purchaserType ?? '',
        'IsTilRtl': tileAdhesiveSeller ?? 'NO',
        'TileStck': double.tryParse(tileAdhesiveStock ?? ''),

        // Enrolment Slabs - ensure they are numbers
        'WcErlSlb': wcEnrolment ?? '',
        'WpErlSlb': wcpEnrolment ?? '',
        'VpErlSlb': vapEnrolment ?? '',

        // BW Stock - ensure they are numbers
        'BwStkWcc': wcStock ?? '',
        'BwStkWcp': wcpStock ?? '',
        'BwStkVap': vapStock ?? '',

        // Market Averages (Competitors) - ensure they are numbers
        'JkAvgWcc': last3MonthsAvg['JK_WC'] ?? '',
        'JkAvgWcp': last3MonthsAvg['JK_WCP'] ?? '',
        'AsAvgWcc': last3MonthsAvg['AS_WC'] ?? '',
        'AsAvgWcp': last3MonthsAvg['AS_WCP'] ?? '',
        'OtAvgWcc': last3MonthsAvg['OT_WC'] ?? '',
        'OtAvgWcp': last3MonthsAvg['OT_WCP'] ?? '',
      };

      // Combine products and gifts into a single activity details array
      // Both go into dptDSRActvtDtl table with different mrktData values
      final List<Map<String, dynamic>> activityDetails = [
        ...productsData,
        ...giftDistributionData,
      ];

      // Validate and ensure all activity details have proper document numbers and sequence numbers
      for (int i = 0; i < activityDetails.length; i++) {
        final activity = activityDetails[i];

        // Ensure document number is set and not empty
        if (activity['docuNumb'] == null ||
            activity['docuNumb'].toString().trim().isEmpty) {
          activity['docuNumb'] = docNumber;
        }

        // Ensure sequence number is properly formatted
        if (activity['seqNumb'] == null ||
            activity['seqNumb'].toString().trim().isEmpty) {
          activity['seqNumb'] = (i + 1).toString().padLeft(3, '0');
        }

        // For Add operations (processType 'A'), allow empty document numbers
        // as the API will generate them. For Update/Delete, validate document numbers.
        if (processType != 'A') {
          // Only validate document numbers for Update/Delete operations
          final activityDocNumber = activity['docuNumb'].toString().trim();
          if (activityDocNumber.isEmpty ||
              RegExp(r'^\s*$').hasMatch(activityDocNumber)) {
            throw Exception(
              'Activity detail at index $i has empty document number for $processType operation',
            );
          }
        }

        print(
          'Activity $i: DocuNumb="${activity['docuNumb']}", SeqNumb="${activity['seqNumb']}", MrktData="${activity['mrktData']}"',
        );
      }

      // Add the activity details to the DSR data
      dsrData['activityDetails'] =
          activityDetails.isNotEmpty ? activityDetails : [];
      dsrData['marketIntelligence'] =
          marketIntelligenceData.isNotEmpty ? marketIntelligenceData : [];

      print('Complete DSR data to be sent: ${json.encode(dsrData)}');

      final result = await _dsrService.saveDSR(dsrData);
      setState(() => isSubmitting = false);

      print('Server response: $result');

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Submitted successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Optionally reset form or navigate
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Submission failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if form should be read-only (Delete mode)
    final bool isReadOnly = processType == 'D';

    final displayContestOptions = ['Y', 'N', 'NA'];
    final displayContestLabels = {'Y': 'Yes', 'N': 'No', 'NA': 'NA'};
    final validDisplayContest =
        displayContestOptions.contains(displayContest) ? displayContest : null;

    final pendingIssueOptions = ['Y', 'N'];
    final pendingIssueLabels = {'Y': 'Yes', 'N': 'No'};

    final kycStatusDisplayMap = {'Y': 'Yes', 'N': 'No'};

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
                const _SectionHeader(
                  icon: Icons.settings,
                  label: 'Process Type',
                ),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: SparshSpacing.sm, // gap between adjacent chips
                        runSpacing: 4.0, // gap between lines
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'A',
                                groupValue: processType,
                                onChanged: (v) {
                                  if (v != null) _onProcessTypeChanged(v);
                                },
                              ),
                              const Text('Add'),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'U',
                                groupValue: processType,
                                onChanged: (v) {
                                  if (v != null) _onProcessTypeChanged(v);
                                },
                              ),
                              const Text('Update'),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'D',
                                groupValue: processType,
                                onChanged: (v) {
                                  if (v != null) _onProcessTypeChanged(v);
                                },
                              ),
                              const Text('Delete'),
                            ],
                          ),
                        ],
                      ),
                      if (processType == 'U' || processType == 'D') ...[
                        const SizedBox(height: 12),
                        isPendingDSRLoading
                            ? const LinearProgressIndicator()
                            : pendingDSRError != null
                            ? Text(
                              pendingDSRError!,
                              style: const TextStyle(color: Colors.red),
                            )
                            : DropdownButtonFormField<String>(
                              value: selectedPendingDSR,
                              decoration: _fantasticInputDecoration(
                                processType == 'U'
                                    ? 'Select DSR to Update *'
                                    : 'Select DSR to Delete *',
                              ),
                              items:
                                  pendingDSREntries.map((entry) {
                                    final docNum =
                                        entry['value']?.toString() ?? '';
                                    final docDate =
                                        entry['docuDate']?.toString() ?? '';
                                    final datePart = docDate.split('T').first;
                                    return DropdownMenuItem<String>(
                                      value: docNum,
                                      child: Text('$docNum ($datePart)'),
                                    );
                                  }).toList(),
                              onChanged: (v) async {
                                if (pendingDSREntries.isEmpty) {
                                  // Show a message that there are no entries
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No pending DSR entries available for update/delete',
                                      ),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => selectedPendingDSR = v);
                                if (v != null && v.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        backgroundColor: Colors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 20,
                                            horizontal: 25,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const CircularProgressIndicator(),
                                              const SizedBox(width: 25),
                                              const Text(
                                                "Loading details...",
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                  try {
                                    await _fetchDSRDetailsForEdit(v);
                                    Navigator.of(
                                      context,
                                    ).pop(); // Close the dialog
                                  } catch (e) {
                                    Navigator.of(
                                      context,
                                    ).pop(); // Close the dialog on error
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error loading details: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              validator:
                                  pendingDSREntries.isEmpty
                                      ? (v) =>
                                          'No pending DSR entries available'
                                      : (v) =>
                                          v == null || v.isEmpty
                                              ? 'Required'
                                              : null,
                            ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Purchaser/Retailer Type, Area Code, Purchaser Code, Name, KYC ---
                const _SectionHeader(
                  icon: Icons.person,
                  label: 'Basic Details',
                ),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isPurchaserTypeLoading
                          ? const LinearProgressIndicator()
                          : purchaserTypeError != null
                          ? Text(
                            purchaserTypeError!,
                            style: const TextStyle(color: Colors.red),
                          )
                          : DropdownButtonFormField<String>(
                            value: _dropdownValue(
                              purchaserType,
                              purchaserTypeOptions,
                            ),
                            decoration: _fantasticInputDecoration(
                              'Purchaser / Retailer Type *',
                            ),
                            items:
                                purchaserTypeOptions
                                    .map(
                                      (e) => DropdownMenuItem<String>(
                                        value: e['value']?.toString() ?? '',
                                        child: Text(
                                          e['text']?.toString() ??
                                              e['value']?.toString() ??
                                              '',
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                isReadOnly
                                    ? null
                                    : (v) =>
                                        setState(() => purchaserType = v ?? ''),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                      const SizedBox(height: SparshSpacing.sm),
                      isAreaCodeLoading
                          ? const LinearProgressIndicator()
                          : areaCodeError != null
                          ? Text(
                            areaCodeError!,
                            style: const TextStyle(color: Colors.red),
                          )
                          : DropdownButtonFormField<String>(
                            value: _dropdownValue(areaCode, areaCodeOptions),
                            decoration: _fantasticInputDecoration(
                              'Area Code *',
                            ),
                            items:
                                areaCodeOptions
                                    .map(
                                      (e) => DropdownMenuItem<String>(
                                        value: e['value']?.toString() ?? '',
                                        child: Text(
                                          e['text']?.toString() ??
                                              e['value']?.toString() ??
                                              '',
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                isReadOnly
                                    ? null
                                    : (v) => setState(() => areaCode = v ?? ''),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                      const SizedBox(height: SparshSpacing.sm),
                      // Purchaser Code Dropdown with Search
                      DropdownSearch<Map<String, dynamic>>(
                        enabled: !isReadOnly,
                        asyncItems: (String filter) async {
                          if (areaCode == null || purchaserType == null)
                            return <Map<String, dynamic>>[];
                          setState(() => isPurchaserCodeLoading = true);
                          try {
                            final results = await _dsrService.getPurchaserCodes(
                              areaCode: areaCode!,
                              purchaserType: purchaserType!,
                              searchText: filter,
                            );
                            setState(() => isPurchaserCodeLoading = false);
                            print(
                              'PurchaserCodeOptions: ' + results.toString(),
                            );
                            return results.cast<Map<String, dynamic>>();
                          } catch (e) {
                            setState(() {
                              isPurchaserCodeLoading = false;
                              purchaserCodeError = e.toString();
                            });
                            return <Map<String, dynamic>>[];
                          }
                        },
                        itemAsString: (item) => item['text'] ?? '',
                        onChanged: (item) async {
                          setState(() {
                            purchaserCode = item?['value'];
                            name = item?['name'];
                            kycStatus = item?['kycStatus'];
                            marketName = item?['marketName'];
                            nameController.text = name ?? '';
                            marketNameController.text = marketName ?? '';
                            // Show Yes/No instead of Y/N
                            if (kycStatus == 'Y' || kycStatus == 'N') {
                              kycStatusController.text =
                                  kycStatusDisplayMap[kycStatus!] ?? kycStatus!;
                            } else {
                              kycStatusController.text = kycStatus ?? '';
                            }
                          });
                          if (purchaserCode != null &&
                              purchaserType != null &&
                              areaCode != null) {
                            try {
                              final customerDetails = await _dsrService
                                  .getCustomerDetails(
                                    purchaserCode!,
                                    purchaserType!,
                                    areaCode!,
                                  );
                              final salesHistory = await _dsrService
                                  .getCustomerSalesHistory(
                                    purchaserCode!,
                                    purchaserType!,
                                  );

                              setState(() {
                                // Update basic details from customerDetails (if not already set by dropdown)
                                name = customerDetails['name'] ?? name;
                                kycStatus =
                                    customerDetails['kycStatus'] ?? kycStatus;
                                marketName =
                                    customerDetails['marketName'] ?? marketName;
                                nameController.text = name ?? '';
                                marketNameController.text = marketName ?? '';
                                if (kycStatus == 'Y' || kycStatus == 'N') {
                                  kycStatusController.text =
                                      kycStatusDisplayMap[kycStatus!] ??
                                      kycStatus!;
                                } else {
                                  kycStatusController.text = kycStatus ?? '';
                                }

                                // Update sales history and stock
                                final last3MonthsAvgData =
                                    salesHistory['last3MonthsAverage'];
                                last3MonthsAvg['JK_WC'] =
                                    last3MonthsAvgData['wc']?.toString() ?? '';
                                last3MonthsAvg['JK_WCP'] =
                                    last3MonthsAvgData['wcp']?.toString() ??
                                    '0';
                                // Assuming 'VAP' is not part of JK/Asian/Other averages, keep as 0 or handle if needed
                                last3MonthsAvg['AS_WC'] =
                                    '0'; // No specific Asian data from this endpoint
                                last3MonthsAvg['AS_WCP'] = '';
                                last3MonthsAvg['OT_WC'] =
                                    ''; // No specific Other data from this endpoint
                                last3MonthsAvg['OT_WCP'] = '';

                                final currentMonthData =
                                    salesHistory['currentMonth'];
                                currentMonthBW['BW_WC'] =
                                    currentMonthData['wc']?.toString() ?? '';
                                currentMonthBW['BW_WCP'] =
                                    currentMonthData['wcp']?.toString() ?? '';
                                currentMonthBW['BW_VAP'] =
                                    currentMonthData['vap']?.toString() ?? '';

                                final stockData = salesHistory['stock'];
                                wcStock = stockData['wc']?.toString() ?? '';
                                wcpStock = stockData['wcp']?.toString() ?? '';
                                vapStock = stockData['vap']?.toString() ?? '';
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to load customer details or sales history: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        selectedItem:
                            purchaserCode != null
                                ? {
                                  'value': purchaserCode,
                                  'text': '$purchaserCode - ${name ?? ''}',
                                  'name': name,
                                  'address': marketName ?? '',
                                  'kycStatus': kycStatus,
                                  'marketName': marketName,
                                }
                                : null,
                        validator:
                            (Map<String, dynamic>? v) =>
                                v == null ? 'Required' : null,
                        dropdownBuilder:
                            (context, selectedItem) =>
                                Text(selectedItem?['text'] ?? ''),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          itemBuilder:
                              (context, item, isSelected) => ListTile(
                                title: Text(item['text'] ?? ''),
                                subtitle: Text(item['address'] ?? ''),
                              ),
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: _fantasticInputDecoration(
                            'Purchaser Code *',
                            icon: Icons.search,
                          ),
                        ),
                        compareFn:
                            (item, selectedItem) =>
                                item['value'] == selectedItem['value'],
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
                        readOnly: isReadOnly,
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
                        decoration: _fantasticInputDecoration(
                          'Report Date *',
                          icon: Icons.calendar_today,
                        ),
                        readOnly: true,
                        onTap: () async {
                          if (isReadOnly) return;
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(now.year, now.month, now.day),
                            firstDate: DateTime(
                              2000,
                              1,
                              1,
                            ), // allow all past dates
                            lastDate: DateTime(
                              now.year,
                              now.month,
                              now.day,
                            ), // no future dates
                          );
                          if (picked != null) {
                            setState(() {
                              reportDate =
                                  "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                            });

                            // Show popup only if date is older than last 3 days
                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            final sel = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                            final diffDays = today.difference(sel).inDays;
                            if (diffDays >= 3) {
                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Exception Entry'),
                                      content: const Text(
                                        'You selected a date older than 3 days.\nIf this requires approval, proceed to DSR Exception Entry.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        const DsrExceptionEntryPage(),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Go to DSR Exception Entry',
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            }
                          }
                        },
                        controller: TextEditingController(text: reportDate),
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: marketNameController,
                        decoration: _fantasticInputDecoration(
                          'Market Name (Location Or Road Name) *',
                        ),
                        readOnly: isReadOnly,
                        onChanged: (v) => marketName = v,
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      // Participation of Display Contest (vertical)
                      const Text(
                        'Participation of Display Contest *',
                        style: SparshTypography.bodyBold,
                      ),
                      Wrap(
                        spacing: SparshSpacing.sm,
                        runSpacing: 4.0,
                        children:
                            displayContestOptions
                                .map(
                                  (opt) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<String>(
                                        value: opt,
                                        groupValue: validDisplayContest,
                                        onChanged:
                                            isReadOnly
                                                ? null
                                                : (v) => setState(
                                                  () => displayContest = v,
                                                ),
                                      ),
                                      Text(displayContestLabels[opt] ?? opt),
                                    ],
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      // Any Pending Issues (vertical)
                      const Text(
                        'Any Pending Issues (Yes/No) *',
                        style: SparshTypography.bodyBold,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            pendingIssueOptions
                                .map(
                                  (opt) => Row(
                                    children: [
                                      Radio<String>(
                                        value: opt,
                                        groupValue: pendingIssue,
                                        onChanged:
                                            isReadOnly
                                                ? null
                                                : (v) => setState(
                                                  () => pendingIssue = v,
                                                ),
                                      ),
                                      Text(pendingIssueLabels[opt] ?? opt),
                                    ],
                                  ),
                                )
                                .toList(),
                      ),
                      if (pendingIssue == 'Y') ...[
                        DropdownButtonFormField<String>(
                          value: pendingIssueDetail,
                          decoration: _fantasticInputDecoration(
                            'If Yes, pending issue details *',
                          ),
                          items:
                              pendingIssueDetails
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              isReadOnly
                                  ? null
                                  : (v) =>
                                      setState(() => pendingIssueDetail = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: issueDetailController,
                          decoration: _fantasticInputDecoration(
                            'If Yes, Specify Issue',
                          ),
                          readOnly: isReadOnly,
                          onChanged: (v) => issueDetail = v,
                          validator:
                              (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Enrolment Slab ---
                const _SectionHeader(
                  icon: Icons.bar_chart,
                  label: 'Enrolment Slab (in MT)',
                ),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: wcEnrolmentController,
                        decoration: _fantasticInputDecoration('WC'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => wcEnrolment = v,
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: wcpEnrolmentController,
                        decoration: _fantasticInputDecoration('WCP'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => wcpEnrolment = v,
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: vapEnrolmentController,
                        decoration: _fantasticInputDecoration('VAP'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => vapEnrolment = v,
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- BW Stocks Availability ---
                const _SectionHeader(
                  icon: Icons.inventory,
                  label: 'BW Stocks Availability (in MT)',
                ),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: wcStockController,
                        decoration: _fantasticInputDecoration('WC'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => wcStock = v,
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: wcpStockController,
                        decoration: _fantasticInputDecoration('WCP'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => wcpStock = v,
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: vapStockController,
                        decoration: _fantasticInputDecoration('VAP'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => vapStock = v,
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Brands Selling ---
                const _SectionHeader(
                  icon: Icons.check_box,
                  label: 'Brands Selling',
                ),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WC (Industry Volume)',
                        style: SparshTypography.bodyBold,
                      ),
                      isBrandLoading
                          ? const LinearProgressIndicator()
                          : brandError != null
                          ? Text(
                            brandError!,
                            style: const TextStyle(color: Colors.red),
                          )
                          : Wrap(
                            spacing: SparshSpacing.sm,
                            children:
                                brandOptions.map((brand) {
                                  final code = brand['value']?.toString() ?? '';
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: brandsWc[code] ?? false,
                                        onChanged:
                                            isReadOnly
                                                ? null
                                                : (v) => setState(
                                                  () =>
                                                      brandsWc[code] =
                                                          v ?? false,
                                                ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            SparshBorderRadius.sm,
                                          ),
                                        ),
                                      ),
                                      Text(brand['text']?.toString() ?? code),
                                    ],
                                  );
                                }).toList(),
                          ),
                      TextFormField(
                        controller: slWcVolumeController,
                        decoration: _fantasticInputDecoration(
                          'WC Industry Volume in (MT)',
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => slWcVolume = v,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      const Text(
                        'WCP (Industry Volume)',
                        style: SparshTypography.bodyBold,
                      ),
                      isBrandLoading
                          ? const LinearProgressIndicator()
                          : brandError != null
                          ? Text(
                            brandError!,
                            style: const TextStyle(color: Colors.red),
                          )
                          : Wrap(
                            spacing: SparshSpacing.sm,
                            children:
                                brandOptions.map((brand) {
                                  final code = brand['value']?.toString() ?? '';
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: brandsWcp[code] ?? false,
                                        onChanged:
                                            isReadOnly
                                                ? null
                                                : (v) => setState(
                                                  () =>
                                                      brandsWcp[code] =
                                                          v ?? false,
                                                ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            SparshBorderRadius.sm,
                                          ),
                                        ),
                                      ),
                                      Text(brand['text']?.toString() ?? code),
                                    ],
                                  );
                                }).toList(),
                          ),
                      TextFormField(
                        controller: slWpVolumeController,
                        decoration: _fantasticInputDecoration(
                          'WCP Industry Volume in (MT)',
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => slWpVolume = v,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Last 3 Months Average ---
                const _SectionHeader(
                  icon: Icons.timeline,
                  label: 'Last 3 Months Average',
                ),
                _FantasticCard(
                  child: Table(
                    border: TableBorder.all(color: SparshTheme.borderGrey),
                    children: [
                      const TableRow(
                        children: [
                          SizedBox(),
                          Center(
                            child: Text(
                              'WC Qty',
                              style: SparshTypography.bodyBold,
                            ),
                          ),
                          Center(
                            child: Text(
                              'WCP Qty',
                              style: SparshTypography.bodyBold,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Center(child: Text('JK')),
                          TextFormField(
                            controller: jkWcController,
                            decoration: _fantasticInputDecoration(''),
                            keyboardType: TextInputType.number,
                            readOnly: isReadOnly,
                            onChanged: (v) => last3MonthsAvg['JK_WC'] = v,
                          ),
                          TextFormField(
                            controller: jkWcpController,
                            decoration: _fantasticInputDecoration(''),
                            keyboardType: TextInputType.number,
                            readOnly: isReadOnly,
                            onChanged: (v) => last3MonthsAvg['JK_WCP'] = v,
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Center(child: Text('Asian')),
                          TextFormField(
                            controller: asWcController,
                            decoration: _fantasticInputDecoration(''),
                            keyboardType: TextInputType.number,
                            readOnly: isReadOnly,
                            onChanged: (v) => last3MonthsAvg['AS_WC'] = v,
                          ),
                          TextFormField(
                            controller: asWcpController,
                            decoration: _fantasticInputDecoration(''),
                            keyboardType: TextInputType.number,
                            readOnly: isReadOnly,
                            onChanged: (v) => last3MonthsAvg['AS_WCP'] = v,
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Center(child: Text('Other')),
                          TextFormField(
                            controller: otWcController,
                            decoration: _fantasticInputDecoration(''),
                            keyboardType: TextInputType.number,
                            readOnly: isReadOnly,
                            onChanged: (v) => last3MonthsAvg['OT_WC'] = v,
                          ),
                          TextFormField(
                            controller: otWcpController,
                            decoration: _fantasticInputDecoration(''),
                            keyboardType: TextInputType.number,
                            readOnly: isReadOnly,
                            onChanged: (v) => last3MonthsAvg['OT_WCP'] = v,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Last 3 Months Average - BW ---
                const _SectionHeader(
                  icon: Icons.calendar_month,
                  label: 'Last 3 Months Average - BW (in MT)',
                ),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: bwWcController,
                        decoration: _fantasticInputDecoration('WC'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => last3MonthBW['BW_WC'] = v,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: bwWcpController,
                        decoration: _fantasticInputDecoration('WCP'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => last3MonthBW['BW_WCP'] = v,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: bwVapController,
                        decoration: _fantasticInputDecoration('VAP'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => last3MonthBW['BW_VAP'] = v,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: SparshSpacing.sm),
                // --- Current Month - BW ---
                const _SectionHeader(
                  icon: Icons.calendar_month,
                  label: 'Current Month - BW (in MT)',
                ),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: currentWcController,
                        decoration: _fantasticInputDecoration('WC'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => currentMonthBW['BW_WC'] = v,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: currentWcpController,
                        decoration: _fantasticInputDecoration('WCP'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => currentMonthBW['BW_WCP'] = v,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: currentVapController,
                        decoration: _fantasticInputDecoration('VAP'),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => currentMonthBW['BW_VAP'] = v,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: SparshSpacing.sm),
                // --- Order Booked in call/e meet (Dynamic List) ---
                const _SectionHeader(
                  icon: Icons.shopping_cart,
                  label: 'Order Booked in call/e meet',
                ),
                _FantasticCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Order Booked in call/e meet',
                              style: SparshTypography.bodyBold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: isReadOnly ? null : addProductRow,
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
                                    ? Text(
                                      productCategoryError!,
                                      style: const TextStyle(color: Colors.red),
                                    )
                                    : DropdownButtonFormField<String>(
                                      value: _dropdownValue(
                                        productList[idx]['category'],
                                        productCategoryOptions,
                                        valueKey: 'Code',
                                      ),
                                      decoration: _fantasticInputDecoration(
                                        'Product Category',
                                      ),
                                      isExpanded: true,
                                      selectedItemBuilder: (_) {
                                        final items = _sanitizeOptions(
                                          productCategoryOptions,
                                        );
                                        return items.map((e) {
                                          final label = _optText(e);
                                          return Text(
                                            label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }).toList();
                                      },
                                      items:
                                          _sanitizeOptions(
                                            productCategoryOptions,
                                          ).map((e) {
                                            final code = _optCode(e);
                                            final label = _optText(e);
                                            return DropdownMenuItem<String>(
                                              value:
                                                  code.isNotEmpty
                                                      ? code
                                                      : e.toString(),
                                              child: Text(
                                                label,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                      onChanged:
                                          isReadOnly
                                              ? null
                                              : (v) async {
                                                setState(() {
                                                  productList[idx]['category'] =
                                                      v ?? '';
                                                  productList[idx]['sku'] = '';
                                                });
                                                if (v != null && v.isNotEmpty) {
                                                  await _fetchProductsForCategory(
                                                    v,
                                                  );
                                                }
                                              },
                                    ),
                                const SizedBox(height: SparshSpacing.xs),
                                productList[idx]['category'] == null
                                    ? const SizedBox()
                                    : isProductLoading[productList[idx]['category']] ==
                                        true
                                    ? const LinearProgressIndicator()
                                    : productError[productList[idx]['category']] !=
                                        null
                                    ? Text(
                                      productError[productList[idx]['category']]!,
                                      style: const TextStyle(color: Colors.red),
                                    )
                                    : GestureDetector(
                                      onTap:
                                          (!isReadOnly &&
                                                  (productList[idx]['category']
                                                          ?.isNotEmpty ??
                                                      false))
                                              ? () async {
                                                final category =
                                                    productList[idx]['category']!;
                                                // If products for the category are still loading
                                                if (isProductLoading[category] ==
                                                    true) {
                                                  _showSnack(
                                                    'Loading SKUs, please wait...',
                                                  );
                                                  return;
                                                }
                                                // If there was a load error
                                                if (productError[category] !=
                                                    null) {
                                                  _showSnack(
                                                    productError[category]!,
                                                    color: Colors.red,
                                                  );
                                                  return;
                                                }
                                                // If list is empty, try to fetch
                                                if ((productsByCategory[category] ??
                                                        [])
                                                    .isEmpty) {
                                                  await _fetchProductsForCategory(
                                                    category,
                                                  );
                                                  if ((productsByCategory[category] ??
                                                          [])
                                                      .isEmpty) {
                                                    _showSnack(
                                                      'No SKUs found for selected category',
                                                      color: Colors.orange,
                                                    );
                                                    return;
                                                  }
                                                }

                                                final opts =
                                                    productsByCategory[category] ??
                                                    [];
                                                final picked =
                                                    await _showOptionPicker(
                                                      title:
                                                          'Select Product SKU',
                                                      options: opts,
                                                    );
                                                if (picked != null) {
                                                  setState(() {
                                                    productList[idx]['sku'] =
                                                        picked;
                                                  });
                                                }
                                              }
                                              : null,
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          readOnly: true,
                                          decoration: _fantasticInputDecoration(
                                            'Product SKU',
                                          ),
                                          controller: TextEditingController(
                                            text: () {
                                              final sku =
                                                  productList[idx]['sku'] ?? '';
                                              final opts =
                                                  productsByCategory[productList[idx]['category']] ??
                                                  [];
                                              final m = _sanitizeOptions(
                                                opts,
                                              ).firstWhere(
                                                (e) => _optCode(e) == sku,
                                                orElse: () => const {},
                                              );
                                              return m.isEmpty
                                                  ? ''
                                                  : _optText(m);
                                            }(),
                                          ),
                                          maxLines: 1,
                                          style: const TextStyle(
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                const SizedBox(height: SparshSpacing.xs),
                                TextFormField(
                                  controller: () {
                                    if (productQtyControllers.length <= idx) {
                                      final c = TextEditingController(
                                        text: productList[idx]['qty'] ?? '',
                                      );
                                      productQtyControllers.add(c);
                                    }
                                    return productQtyControllers[idx];
                                  }(),
                                  decoration: _fantasticInputDecoration('Qty'),
                                  keyboardType: TextInputType.number,
                                  readOnly: isReadOnly,
                                  onChanged: (v) => productList[idx]['qty'] = v,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: SparshTheme.errorRed,
                                    ),
                                    // Disable delete in read-only mode
                                    onPressed:
                                        isReadOnly
                                            ? null
                                            : () => removeProductRow(idx),
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
                const _SectionHeader(
                  icon: Icons.trending_up,
                  label: 'Market -- WCP (Highest selling SKU)',
                ),
                _FantasticCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Market -- WCP (Highest selling SKU)',
                              style: SparshTypography.bodyBold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: isReadOnly ? null : addMarketSkuRow,
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
                                    ? Text(
                                      brandError!,
                                      style: const TextStyle(color: Colors.red),
                                    )
                                    : DropdownButtonFormField<String>(
                                      value: _dropdownValue(
                                        marketSkuList[idx]['brand'],
                                        brandOptions,
                                      ),
                                      decoration: _fantasticInputDecoration(
                                        'Brand',
                                      ),
                                      items:
                                          brandOptions
                                              .map(
                                                (e) => DropdownMenuItem<String>(
                                                  value:
                                                      e['value']?.toString() ??
                                                      '',
                                                  child: Text(
                                                    '${e['text'] ?? e['value'] ?? ''} (${e['value'] ?? ''})',
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          isReadOnly
                                              ? null
                                              : (v) => setState(
                                                () =>
                                                    marketSkuList[idx]['brand'] =
                                                        v ?? '',
                                              ),
                                    ),
                                const SizedBox(height: SparshSpacing.xs),
                                TextFormField(
                                  controller:
                                      marketSkuProductControllers.length > idx
                                          ? marketSkuProductControllers[idx]
                                          : null,
                                  decoration: _fantasticInputDecoration(
                                    'Product',
                                  ),
                                  readOnly: isReadOnly,
                                  onChanged:
                                      (v) => marketSkuList[idx]['product'] = v,
                                ),
                                const SizedBox(height: SparshSpacing.xs),
                                TextFormField(
                                  controller:
                                      marketSkuPriceBControllers.length > idx
                                          ? marketSkuPriceBControllers[idx]
                                          : null,
                                  decoration: _fantasticInputDecoration(
                                    'Price - B',
                                  ),
                                  keyboardType: TextInputType.number,
                                  readOnly: isReadOnly,
                                  onChanged:
                                      (v) => marketSkuList[idx]['priceB'] = v,
                                ),
                                const SizedBox(height: SparshSpacing.xs),
                                TextFormField(
                                  controller:
                                      marketSkuPriceCControllers.length > idx
                                          ? marketSkuPriceCControllers[idx]
                                          : null,
                                  decoration: _fantasticInputDecoration(
                                    'Price - C',
                                  ),
                                  keyboardType: TextInputType.number,
                                  readOnly: isReadOnly,
                                  onChanged:
                                      (v) => marketSkuList[idx]['priceC'] = v,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: SparshTheme.errorRed,
                                    ),
                                    onPressed:
                                        isReadOnly
                                            ? null
                                            : () => removeMarketSkuRow(idx),
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
                const _SectionHeader(
                  icon: Icons.card_giftcard,
                  label: 'Gift Distribution',
                ),
                _FantasticCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Gift Distribution',
                              style: SparshTypography.bodyBold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: isReadOnly ? null : addGiftRow,
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
                                    ? Text(
                                      giftTypeError!,
                                      style: const TextStyle(color: Colors.red),
                                    )
                                    : DropdownButtonFormField<String>(
                                      value: _dropdownValue(
                                        giftList[idx]['giftType'],
                                        giftTypeOptions,
                                      ),
                                      decoration: _fantasticInputDecoration(
                                        'Gift Type',
                                      ),
                                      items:
                                          giftTypeOptions
                                              .map(
                                                (e) => DropdownMenuItem<String>(
                                                  value:
                                                      e['value']?.toString() ??
                                                      '',
                                                  child: Text(
                                                    '${e['text'] ?? e['value'] ?? ''} (${e['value'] ?? ''})',
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          isReadOnly
                                              ? null
                                              : (v) => setState(
                                                () =>
                                                    giftList[idx]['giftType'] =
                                                        v ?? '',
                                              ),
                                    ),
                                const SizedBox(height: SparshSpacing.xs),
                                TextFormField(
                                  controller:
                                      giftQtyControllers.length > idx
                                          ? giftQtyControllers[idx]
                                          : null,
                                  decoration: _fantasticInputDecoration('Qty'),
                                  keyboardType: TextInputType.number,
                                  readOnly: isReadOnly,
                                  onChanged: (v) => giftList[idx]['qty'] = v,
                                ),
                                const SizedBox(height: SparshSpacing.xs),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: SparshTheme.errorRed,
                                    ),
                                    onPressed:
                                        isReadOnly
                                            ? null
                                            : () => removeGiftRow(idx),
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
                const _SectionHeader(
                  icon: Icons.layers,
                  label: 'Tile Adhesives',
                ),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: tileAdhesiveSeller,
                        decoration: _fantasticInputDecoration(
                          'Is this Tile Adhesives seller?',
                        ),
                        items:
                            tileAdhesiveOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            isReadOnly
                                ? null
                                : (v) => setState(() => tileAdhesiveSeller = v),
                      ),
                      TextFormField(
                        controller: tileAdhesiveStockController,
                        decoration: _fantasticInputDecoration(
                          'Tile Adhesive Stock',
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: isReadOnly,
                        onChanged: (v) => tileAdhesiveStock = v,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                // --- Order Execution Date, Remarks, Reason ---
                const _SectionHeader(
                  icon: Icons.event,
                  label: 'Order Execution & Remarks',
                ),
                _FantasticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: _fantasticInputDecoration(
                          'Order Execution date',
                          icon: Icons.calendar_today,
                        ),
                        readOnly: true,
                        onTap: () async {
                          if (isReadOnly) return;
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              orderExecutionDate =
                                  "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                            });
                          }
                        },
                        controller: TextEditingController(
                          text: orderExecutionDate,
                        ),
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: remarksController,
                        decoration: _fantasticInputDecoration(
                          'Any other Remarks',
                        ),
                        readOnly: isReadOnly,
                        onChanged: (v) => remarks = v,
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      isExceptionReasonLoading
                          ? const LinearProgressIndicator()
                          : exceptionReasonError != null
                          ? Text(
                            exceptionReasonError!,
                            style: const TextStyle(color: Colors.red),
                          )
                          : (() {
                            final opts = _sanitizeOptions(
                              exceptionReasonOptions,
                            );
                            if (opts.isEmpty) {
                              return const Text(
                                'No reasons available',
                                style: TextStyle(color: Colors.orange),
                              );
                            }
                            return DropdownButtonFormField<String>(
                              value: _dropdownValue(
                                cityReason,
                                exceptionReasonOptions,
                                valueKey: 'Code',
                              ),
                              decoration: _fantasticInputDecoration(
                                'Select Reason',
                              ),
                              isExpanded: true,
                              selectedItemBuilder:
                                  (_) =>
                                      opts.map((e) {
                                        final label = _optText(e);
                                        return Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      }).toList(),
                              items:
                                  opts.map((e) {
                                    final code = _optCode(e);
                                    final label = _optText(e);
                                    return DropdownMenuItem<String>(
                                      value:
                                          code.isNotEmpty ? code : e.toString(),
                                      child: Text(
                                        label.isNotEmpty ? label : 'Unknown',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  isReadOnly
                                      ? null
                                      : (v) =>
                                          setState(() => cityReason = v ?? ''),
                            );
                          })(),
                    ],
                  ),
                ),
                const SizedBox(height: SparshSpacing.xl),

                // --- Bottom Action Buttons ---
                const SizedBox(height: SparshSpacing.xl),
                // --- Bottom Action Buttons ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            processType == 'D'
                                ? SparshTheme.errorRed
                                : SparshTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            SparshBorderRadius.lg,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: SparshSpacing.lg,
                        ),
                      ),
                      onPressed: isSubmitting ? null : _submitForm,
                      child: Text(
                        processType == 'A'
                            ? 'Submit & Exit'
                            : processType == 'U'
                            ? 'Update & Exit'
                            : 'Delete & Exit',
                        style: SparshTypography.bodyBold,
                      ),
                    ),
                    if (isSubmitting) const LinearProgressIndicator(),
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
          Flexible(
            child: Text(
              label,
              style: SparshTypography.heading5.copyWith(fontSize: fontSize),
            ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SparshBorderRadius.lg),
      ),
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
    contentPadding: const EdgeInsets.symmetric(
      horizontal: SparshSpacing.md,
      vertical: SparshSpacing.sm,
    ),
  );
}
