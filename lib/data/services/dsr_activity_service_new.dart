import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/dsr_debug_helper.dart';

class DSRActivityService {
  static const String baseUrl = 'http://192.168.36.25';

  /// Get Customer/Retailer types dropdown
  Future<List<Map<String, dynamic>>> getCustomerTypes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/DSRActivity/GetCustomerTypes'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load customer types');
    }
  }

  /// Get Areas dropdown - all active area codes
  Future<List<Map<String, dynamic>>> getAllAreas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/DSRActivity/GetAreas'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load areas');
    }
  }

  /// Get Purchaser Codes based on area code and purchaser/retailer type
  Future<List<Map<String, dynamic>>> getPurchaserCodes({
    required String areaCode,
    required String purchaserType,
    String searchText = '',
  }) async {
    final uri = Uri.parse('$baseUrl/api/DSRActivity/GetPurchaserCodes').replace(
      queryParameters: {
        'areaCode': areaCode,
        'purchaserType': purchaserType,
        'searchText': searchText,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load purchaser codes');
    }
  }

  /// Get Product categories dropdown
  Future<List<Map<String, dynamic>>> getProductCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/DSRActivity/GetProductCategories'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load product categories');
    }
  }

  /// Get Product SKUs for a specific category
  Future<List<Map<String, dynamic>>> getProducts({
    required String category,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/DSRActivity/products/$category/skus'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load products for category $category');
    }
  }

  /// Get Brand options for market intelligence
  Future<List<Map<String, dynamic>>> getBrands() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/DSRActivity/GetBrands'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load brands');
    }
  }

  /// Get Gift Types dropdown
  Future<List<Map<String, dynamic>>> getGiftTypes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/DSRActivity/GetGiftTypes'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load gift types');
    }
  }

  /// Get Exception Reasons dropdown
  Future<List<Map<String, dynamic>>> getExceptionReasons() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/DSRActivity/GetExceptionReasons'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load exception reasons');
    }
  }

  /// Get customer details for auto-fill when customer is selected
  Future<Map<String, dynamic>> getCustomerDetails(
    String customerCode,
    String customerType,
    String areaCode,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/api/DSRActivity/GetCustomerDetails/$customerCode/$customerType/$areaCode',
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      throw Exception('Failed to load customer details');
    }
  }

  /// Get customer sales history
  Future<Map<String, dynamic>> getCustomerSalesHistory(
    String customerCode,
    String customerType,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/api/DSRActivity/GetCustomerSalesHistory',
    ).replace(
      queryParameters: {
        'customerCode': customerCode,
        'customerType': customerType,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      throw Exception('Failed to load customer sales history');
    }
  }

  /// Get pending DSR entries for user (for update/delete dropdown)
  Future<List<Map<String, dynamic>>> getPendingDSR(String loginId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/DSRActivity/GetPendingDSR/$loginId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load pending DSR entries');
    }
  }

  /// Get DSR details for editing/update mode
  Future<Map<String, dynamic>> getDSRForEdit(
    String docuNumb,
    String loginId,
  ) async {
    // URL encode the document number to handle forward slashes
    final encodedDocuNumb = Uri.encodeComponent(docuNumb);
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/DSRActivity/GetDSRForEdit/$encodedDocuNumb/$loginId',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      throw Exception('Failed to load DSR details for editing');
    }
  }

  /// Generate document number from backend
  Future<String?> generateDocumentNumber(String areaCode) async {
    try {
      print(
        'DSRActivityService - Generating document number for area: $areaCode',
      );

      // For now, we'll let the backend handle document generation during save
      // Return null to indicate frontend should use fallback generation
      return null;
    } catch (e) {
      print('DSRActivityService - Error generating document number: $e');
      return null;
    }
  }

  /// Save DSR Entry (Add/Update/Delete)
  Future<Map<String, dynamic>> saveDSR(Map<String, dynamic> dsrData) async {
    try {
      DSRDebugHelper.logDSRSubmission(dsrData);

      final String procType = dsrData['ProcType'] ?? 'A';
      final String docNumber = dsrData['DocuNumb'] ?? '';

      DSRDebugHelper.logDocumentNumber('SAVE_DSR_MAIN', docNumber);

      print('DSRActivityService - Saving DSR with ProcType: $procType');
      print('DSRActivityService - Document Number: "$docNumber"');

      // Convert the DSR data to match the API contract
      final requestData = _convertToApiFormat(dsrData);

      final response = await http.post(
        Uri.parse('$baseUrl/api/DSRActivity/SaveDSR'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print('DSRActivityService - Response status: ${response.statusCode}');
      print('DSRActivityService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message':
              responseData['message'] ?? 'Operation completed successfully',
          'docuNumb': responseData['docuNumb'] ?? docNumber,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to save DSR entry',
        };
      }
    } catch (e) {
      print('DSRActivityService - Error saving DSR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Convert Flutter data format to API format
  Map<String, dynamic> _convertToApiFormat(Map<String, dynamic> dsrData) {
    // Extract activity details for products and gifts
    final List<Map<String, dynamic>> activityDetails =
        List<Map<String, dynamic>>.from(dsrData['activityDetails'] ?? []);
    final List<Map<String, dynamic>> marketIntelligence =
        List<Map<String, dynamic>>.from(dsrData['marketIntelligence'] ?? []);

    // Separate products and gifts from activity details
    final List<Map<String, dynamic>> products = [];
    final List<Map<String, dynamic>> gifts = [];

    for (final activity in activityDetails) {
      final String mrktData = activity['mrktData'] ?? '';
      if (mrktData == '05') {
        // Product order
        products.add({
          'repoCatg': activity['repoCatg'] ?? '',
          'catgPkPr': activity['catgPack'] ?? '',
          'prodQnty': activity['prodQnty'] ?? '0',
          'projQnty': activity['projQnty'] ?? '0',
          'actnRemk': activity['actnRemk'] ?? '',
        });
      } else if (mrktData == '06') {
        // Gift distribution
        gifts.add({
          'mrtlCode': activity['repoCatg'] ?? '',
          'isueQnty': activity['prodQnty'] ?? '0',
          'naration': activity['actnRemk'] ?? '',
        });
      }
    }

    DSRDebugHelper.logActivityDetails(activityDetails);

    final apiData = {
      'procType': dsrData['ProcType'] ?? 'A',
      'docuNumb': dsrData['DocuNumb'] ?? '',
      'docuDate': dsrData['DocuDate'] ?? '',
      'ordExDat': dsrData['OrdExDat'] ?? '',
      'dsrParam': dsrData['DsrParam'] ?? '04',
      'cusRtlFl': dsrData['CusRtlFl'] ?? '',
      'areaCode': dsrData['AreaCode'] ?? '',
      'cusRtlCd': dsrData['CusRtlCd'] ?? '',
      'mrktName': dsrData['MrktName'] ?? '',
      'pendIsue': dsrData['PendIsue'] ?? 'N',
      'pndIsuDt': dsrData['PndIsuDt'] ?? '',
      'isuDetal': dsrData['IsuDetal'] ?? '',
      'dsrRem05': dsrData['DsrRem05'] ?? '',
      'brndSlWc': dsrData['BrndSlWc'] ?? [],
      'brndSlWp': dsrData['BrndSlWp'] ?? [],
      'prtDsCnt': dsrData['PrtDsCnt'] ?? 'N',
      'slWcVlum': dsrData['SlWcVlum'] ?? '0',
      'slWpVlum': dsrData['SlWpVlum'] ?? '0',
      'deptCode': dsrData['DeptCode'] ?? '',
      'pendWith': dsrData['PendWith'] ?? '',
      'createId': dsrData['CreateId'] ?? '2948',
      'finlRslt': dsrData['FinlRslt'] ?? '',
      'geoLatit': dsrData['GeoLatit'] ?? '',
      'geoLongt': dsrData['GeoLongt'] ?? '',
      'ltLgDist': dsrData['LtLgDist'] ?? '0',
      'cityName': dsrData['CityName'] ?? '',
      'cusRtTyp': dsrData['CusRtTyp'] ?? '',
      'isTilRtl': dsrData['IsTilRtl'] ?? 'NO',
      'tileStck': dsrData['TileStck'] ?? 0,

      // Enrolment Slabs
      'wcErlSlb': dsrData['WcErlSlb'] ?? '0',
      'wpErlSlb': dsrData['WpErlSlb'] ?? '0',
      'vpErlSlb': dsrData['VpErlSlb'] ?? '0',

      // BW Stock
      'bwStkWcc': dsrData['BwStkWcc'] ?? '0',
      'bwStkWcp': dsrData['BwStkWcp'] ?? '0',
      'bwStkVap': dsrData['BwStkVap'] ?? '0',

      // Market Averages
      'jkAvgWcc': dsrData['JkAvgWcc'] ?? '0',
      'jkAvgWcp': dsrData['JkAvgWcp'] ?? '0',
      'asAvgWcc': dsrData['AsAvgWcc'] ?? '0',
      'asAvgWcp': dsrData['AsAvgWcp'] ?? '0',
      'otAvgWcc': dsrData['OtAvgWcc'] ?? '0',
      'otAvgWcp': dsrData['OtAvgWcp'] ?? '0',

      'products': products,
      'marketIntelligence': marketIntelligence,
      'giftDistribution': gifts,
    };

    DSRDebugHelper.validateBeforeSubmission(apiData);

    return apiData;
  }
}
