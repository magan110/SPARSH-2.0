import 'dart:convert';
import 'package:http/http.dart' as http;

class DSRActivityService {
  static const String baseUrl = 'http://192.168.36.25';

  Future<List<Map<String, dynamic>>> getCustomerTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/api/DSRActivity/GetCustomerTypes'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load customer types');
    }
  }

  Future<List<Map<String, dynamic>>> getAreas(String loginId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/DSRActivity/GetAreas/$loginId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load areas');
    }
  }

  Future<List<Map<String, dynamic>>> getAllAreas() async {
    final response = await http.get(Uri.parse('$baseUrl/api/DSRActivity/GetAreas'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load all areas');
    }
  }

  Future<List<Map<String, dynamic>>> getCustomers({
    required String areaCode,
    required String customerType,
    String searchText = '',
  }) async {
    final uri = Uri.parse('$baseUrl/api/DSRActivity/GetCustomers')
        .replace(queryParameters: {
      'areaCode': areaCode,
      'customerType': customerType,
      'searchText': searchText,
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load customers');
    }
  }

  Future<List<Map<String, dynamic>>> getProductCategories() async {
    final String baseUrl = 'http://192.168.36.25';
    final url = Uri.parse('$baseUrl/api/DSRActivity/GetProductCategories');
    print('Fetching product categories from: ' + url.toString());
    try {
      final response = await http.get(url);
      print('ProductCategories status: ' + response.statusCode.toString());
      print('ProductCategories response: ' + response.body);
      if (response.statusCode != 200) {
        throw Exception('HTTP error: ${response.statusCode}');
      }
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load product categories');
      }
    } catch (e) {
      print('Error in getProductCategories: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getProducts({
    required String category,
    String areaCode = '',
  }) async {
    final uri = Uri.parse('$baseUrl/api/DSRActivity/GetProducts')
        .replace(queryParameters: {
      'category': category,
      'areaCode': areaCode,
    });
    print('Fetching products from: ' + uri.toString());
    try {
      final response = await http.get(uri);
      print('Products response: ' + response.body);
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch products');
      }
    } catch (e) {
      print('Error in getProducts: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGiftTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/api/DSRActivity/GetGiftTypes'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load gift types');
    }
  }

  Future<List<Map<String, dynamic>>> getExceptionReasons() async {
    final response = await http.get(Uri.parse('$baseUrl/api/DSRActivity/GetExceptionReasons'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load exception reasons');
    }
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    final response = await http.get(Uri.parse('$baseUrl/api/DSRActivity/GetBrands'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Failed to load brands');
    }
  }

  Future<List<Map<String, dynamic>>> getPurchaserCodes({
    required String areaCode,
    required String purchaserType,
    String searchText = '',
  }) async {
    final String baseUrl = 'http://192.168.36.25';
    final url = Uri.parse('$baseUrl/api/DSRActivity/GetPurchaserCodes?areaCode=$areaCode&purChaserType=$purchaserType&searchText=$searchText');
    print('Fetching purchaser codes from: ' + url.toString());
    final response = await http.get(
      url,
      // Add headers if needed
    );
    print('PurchaserCodes response: ' + response.body);
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch purchaser codes');
    }
  }

  Future<Map<String, dynamic>> saveDSR(Map<String, dynamic> dsrData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/DSRActivity/SaveDSR'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(dsrData),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to save DSR');
    }
  }
} 