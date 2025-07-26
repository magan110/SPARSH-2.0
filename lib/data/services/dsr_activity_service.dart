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
      return _safeMapListCast(data['data']);
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
      return _safeMapListCast(data['data']);
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
      return _safeMapListCast(data['data']);
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
      return _safeMapListCast(data);
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
      return _safeMapListCast(data);
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
      return _safeMapListCast(data['data']);
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
      return _safeMapListCast(data['data']);
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
      return _safeMapListCast(data['data']);
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
    print('Fetching pending DSR entries for loginId: $loginId'); // Debug log
    final response = await http.get(
      Uri.parse('$baseUrl/api/DSRActivity/GetPendingDSR/$loginId'),
    );
    print(
      'Pending DSR API response status: ${response.statusCode}',
    ); // Debug log
    print('Pending DSR API response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Parsed API response data: $data'); // Debug log

      // Handle different possible response structures
      if (data is List) {
        return _safeMapListCast(data);
      } else if (data is Map && data['data'] != null) {
        return _safeMapListCast(data['data']);
      } else if (data is Map && data['pendingEntries'] != null) {
        return _safeMapListCast(data['pendingEntries']);
      } else {
        print('Unexpected API response structure: $data'); // Debug log
        return [];
      }
    } else {
      throw Exception(
        'Failed to load pending DSR entries: ${response.statusCode}',
      );
    }
  }

  /// Get DSR details for editing/update mode
  Future<Map<String, dynamic>> getDSRForEdit(
    String docuNumb,
    String loginId,
  ) async {
    try {
      // URL encode the document number to handle forward slashes
      final encodedDocuNumb = Uri.encodeComponent(docuNumb);
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/DSRActivity/GetDSRForEdit/$encodedDocuNumb/$loginId',
        ),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Check if the API response indicates success
        if (responseData['success'] == true) {
          return Map<String, dynamic>.from(responseData);
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch DSR details',
          );
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to load DSR details for editing',
        );
      }
    } catch (e) {
      print('Error in getDSRForEdit: $e');
      throw Exception('Failed to load DSR details: $e');
    }
  }

  /// Generate document number from backend
  Future<String?> generateDocumentNumber(String areaCode) async {
    try {
      print(
        'DSRActivityService - Generating document number for area: $areaCode',
      );

      // Return empty string to let the API handle document generation during save
      // This signals the frontend that the API will generate the document number
      print(
        'DSRActivityService - Returning empty string for API document generation',
      );
      return '';
    } catch (e) {
      print('DSRActivityService - Error generating document number: $e');
      return '';
    }
  }

  /// Save DSR Entry (Add/Update/Delete)
  Future<Map<String, dynamic>> saveDSR(Map<String, dynamic> dsrData) async {
    try {
      DSRDebugHelper.logDSRSubmission(dsrData);

      final String procType = dsrData['ProcType'] ?? 'A';
      String docNumber = dsrData['DocuNumb'] ?? '';

      // For Add operations, send empty document number to let API generate it
      if (procType == 'A') {
        docNumber = ''; // Let the API generate the document number
        print(
          'DSRActivityService - Letting API generate document number for Add operation',
        );
      } else {
        // For Update/Delete, ensure the document number is properly formatted
        if (docNumber.isNotEmpty) {
          docNumber = docNumber.trim();
          print(
            'DSRActivityService - Using existing document number: "$docNumber"',
          );
        }
      }

      // Update the document number in the data
      dsrData['DocuNumb'] = docNumber;

      DSRDebugHelper.logDocumentNumber('SAVE_DSR_MAIN', docNumber);

      print('DSRActivityService - Saving DSR with ProcType: $procType');
      print('DSRActivityService - Document Number: "$docNumber"');

      // Convert the DSR data to match the API contract
      final requestData = _convertToApiFormat(dsrData);

      // Debug: Print the exact payload being sent
      print('DSRActivityService - Complete request payload:');
      print(json.encode(requestData));

      final response = await http.post(
        Uri.parse('$baseUrl/api/DSRActivity/SaveDSR'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print('DSRActivityService - Response status: ${response.statusCode}');
      print('DSRActivityService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Extract the API-generated document number from the response
        String apiGeneratedDocNumber = responseData['docuNumb'] ?? docNumber;

        return {
          'success': responseData['success'] ?? true,
          'message':
              responseData['message'] ?? 'Operation completed successfully',
          'docuNumb': apiGeneratedDocNumber,
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

  /// Format date string for API (converts YYYY-MM-DD to DD/MM/YYYY)
  String? _formatDateForApi(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    try {
      // Try to parse the date
      DateTime date;
      if (dateString.contains('-')) {
        // Assume YYYY-MM-DD format
        date = DateTime.parse(dateString);
      } else if (dateString.contains('/')) {
        // Already in DD/MM/YYYY format
        return dateString;
      } else {
        // Unknown format, return as-is
        return dateString;
      }

      // Convert to DD/MM/YYYY format
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      print('DSRActivityService - Error formatting date "$dateString": $e');
      return dateString; // Return original if parsing fails
    }
  }

  /// Safe list casting helper to handle dynamic lists
  List<dynamic> _safeListCast(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    return [];
  }

  /// Safe list casting helper for lists of maps
  List<Map<String, dynamic>> _safeMapListCast(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    final List<Map<String, dynamic>> result = [];
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        result.add(item);
      } else if (item is Map) {
        result.add(Map<String, dynamic>.from(item));
      }
    }
    return result;
  }

  /// Convert Flutter data format to API format
  Map<String, dynamic> _convertToApiFormat(Map<String, dynamic> dsrData) {
    // Get the main document number that will be sent
    final String mainDocNumber = dsrData['DocuNumb'] ?? '';

    // Extract activity details for products and gifts - handle type casting safely
    final activityDetailsRaw = dsrData['activityDetails'] ?? [];
    final List<Map<String, dynamic>> activityDetails = [];

    // Safe casting for activity details
    if (activityDetailsRaw is List) {
      for (final item in activityDetailsRaw) {
        if (item is Map<String, dynamic>) {
          // Ensure activity detail has the same document number as main entry
          final updatedItem = Map<String, dynamic>.from(item);
          updatedItem['docuNumb'] = mainDocNumber;
          activityDetails.add(updatedItem);
        } else if (item is Map) {
          final updatedItem = Map<String, dynamic>.from(item);
          updatedItem['docuNumb'] = mainDocNumber;
          activityDetails.add(updatedItem);
        }
      }
    }

    final marketIntelligenceRaw = dsrData['marketIntelligence'] ?? [];
    final List<Map<String, dynamic>> marketIntelligence = [];

    // Safe casting for market intelligence
    if (marketIntelligenceRaw is List) {
      for (final item in marketIntelligenceRaw) {
        if (item is Map<String, dynamic>) {
          marketIntelligence.add(item);
        } else if (item is Map) {
          marketIntelligence.add(Map<String, dynamic>.from(item));
        }
      }
    }

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
      'docuDate':
          _formatDateForApi(dsrData['DocuDate']) ??
          _formatDateForApi(DateTime.now().toIso8601String().split('T')[0]),
      'ordExDat':
          _formatDateForApi(dsrData['OrdExDat']) ??
          _formatDateForApi(DateTime.now().toIso8601String().split('T')[0]),
      'dsrParam': dsrData['DsrParam'] ?? '04',
      'cusRtlFl': dsrData['CusRtlFl'] ?? '',
      'areaCode': dsrData['AreaCode'] ?? '',
      'cusRtlCd': dsrData['CusRtlCd'] ?? '',
      'mrktName': dsrData['MrktName'] ?? '',
      'pendIsue': dsrData['PendIsue'] ?? 'N',
      'pndIsuDt': _formatDateForApi(dsrData['PndIsuDt']) ?? '',
      'isuDetal': dsrData['IsuDetal'] ?? '',
      'dsrRem05': dsrData['DsrRem05'] ?? '',
      'brndSlWc': _safeListCast(dsrData['BrndSlWc']),
      'brndSlWp': _safeListCast(dsrData['BrndSlWp']),
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

      // Send activity details with document numbers synchronized
      'dsrActivityDtls': activityDetails,
      'products': products,
      'marketIntelligence': marketIntelligence,
      'giftDistribution': gifts,
    };

    DSRDebugHelper.validateBeforeSubmission(apiData);

    return apiData;
  }
}
