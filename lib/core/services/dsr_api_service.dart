import 'dart:convert';
import 'package:http/http.dart' as http;

/// Centralized DSR / Exception API service.
/// Single source of base URL & endpoints (10.4.64.23).
class DsrApiService {
  static const String _base = 'http://10.4.64.23/api/DsrTry';
  static final http.Client _client = http.Client();

  // ---------- low level helpers ----------
  static Uri _u(String suffix) => Uri.parse('$_base$suffix');

  static dynamic _decodeBody(http.Response r) {
    if (r.body.isEmpty) return null;
    try {
      return jsonDecode(r.body);
    } catch (_) {
      return r.body;
    }
  }

  static void _ensure(http.Response r, Set<int> expect) {
    if (!expect.contains(r.statusCode)) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }

  static Future<dynamic> _get(String path, {Set<int> ok = const {200}}) async {
    final resp = await _client.get(_u(path));
    _ensure(resp, ok);
    return _decodeBody(resp);
  }

  static Future<dynamic> _post(
    String path,
    Object? body, {
    int expect = 201,
  }) async {
    final resp = await _client.post(
      _u(path),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _ensure(resp, {expect});
    return _decodeBody(resp);
  }

  static Future<dynamic> _put(
    String path,
    Object? body, {
    Set<int> expect = const {204},
  }) async {
    final resp = await _client.put(
      _u(path),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _ensure(resp, expect);
    return _decodeBody(resp);
  }

  // ---------- Lookups / dropdown data ----------
  static Future<List<String>> getProcessTypes() async {
    final data = await _get('/getProcessTypes');
    if (data is List) {
      return data
          .map(
            (e) =>
                (e is Map
                        ? (e['Description'] ??
                            e['description'] ??
                            e['Code'] ??
                            e['code'])
                        : e)
                    .toString(),
          )
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getAreaCodes() async {
    final data = await _get('/getAreaCodes');
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  static Future<List<Map<String, dynamic>>> getPurchaserOptions() async {
    final data = await _get('/getPurchaserOptions');
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  static Future<List<String>> getQualityOptions() async {
    final data = await _get('/getQualityOptions');
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  static Future<List<String>> getStatusOptions() async {
    final data = await _get('/getStatusOptions');
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  static Future<List<String>> getProductOptions() async {
    final data = await _get('/getProductOptions');
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  static Future<List<String>> getBtlActivityTypes() async {
    final data = await _get('/getBtlActivityTypes');
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  static Future<List<String>> getDocumentNumbers(String dsrParam) async {
    final data = await _get('/getDocumentNumbers?dsrParam=$dsrParam');
    if (data is List) {
      return data
          .map(
            (e) =>
                (e is Map
                        ? (e['DocuNumb'] ??
                            e['docuNumb'] ??
                            e['DocumentNumber'] ??
                            e['documentNumber'])
                        : e)
                    .toString(),
          )
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getDocumentDetails(
    String docuNumb,
  ) async {
    final data = await _get('/getDocumentDetails?docuNumb=$docuNumb');
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  static Future<String?> generateDocumentNumber(String areaCode) async {
    final data = await _post('/generateDocumentNumber', areaCode, expect: 200);
    if (data is Map && data['DocumentNumber'] != null)
      return data['DocumentNumber'].toString();
    return null;
  }

  static Future<Map<String, dynamic>> getApprovalAuthority(
    String loginId,
  ) async {
    final data = await _get('/getApprovalAuthority?loginId=$loginId');
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> getExceptionMetadata({
    String procType = 'N',
  }) async {
    final data = await _get('/getExceptionMetadata?procType=$procType');
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> getEmployee(String loginId) async {
    final data = await _get('/getEmployee?loginId=$loginId');
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> getPurchaserCode(
    String areaCode,
    String purchaserFlag,
  ) async {
    final data = await _get(
      '/getPurchaserCode?areaCode=$areaCode&purchaserFlag=$purchaserFlag',
    );
    if (data is Map<String, dynamic>) return data;
    if (data is List) {
      return {'PurchaserCodes': data};
    }
    return <String, dynamic>{};
  }

  static Future<List<dynamic>> getEmployees({
    required String loginId,
    String procType = 'N',
    String emplCode = '',
  }) async {
    final data = await _get(
      '/getEmployees?procType=$procType&loginId=$loginId&emplCode=$emplCode',
    );
    return data is List ? data : <dynamic>[];
  }

  static Future<List<dynamic>> getExceptionHistory({
    required String loginId,
    String procType = 'N',
  }) async {
    final data = await _get(
      '/getExceptionHistory?procType=$procType&loginId=$loginId',
    );
    return data is List ? data : <dynamic>[];
  }

  // ---------- Submit / Update DSR ----------
  static Future<void> submitDsr(DsrEntryDto dto) async {
    await _post('', dto.toJson()); // expects 201
  }

  static Future<void> updateDsr(DsrEntryDto dto) async {
    await _put('/update', dto.toJson()); // expects 204
  }

  // ---------- Exceptions submit (new / approval) ----------
  static Future<void> submitExceptions(ExceptionSubmitModel model) async {
    // Server returns 201 for new, 200 for approvals; accept both.
    final resp = await http.post(
      _u('/submitExceptions'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(model.toJson()),
    );
    if (!(resp.statusCode == 201 || resp.statusCode == 200)) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
  }
}

// ------------ Data Models (client side) ------------

class DsrEntryDto {
  final String activityType;
  final DateTime submissionDate;
  final DateTime reportDate;
  final String createId;
  final String dsrParam; // maps to DsrParam
  final String processType; // A = Add, U = Update
  final String? docuNumb; // for update
  final String dsrRem01;
  final String dsrRem02;
  final String dsrRem03;
  final String dsrRem04;
  final String dsrRem05;
  final String dsrRem06;
  final String dsrRem07;
  final String dsrRem08;
  final String latitude;
  final String longitude;
  final String purchaser; // cusRtlFl
  final String purchaserCode; // cusRtlCd
  final String areaCode;

  const DsrEntryDto({
    required this.activityType,
    required this.submissionDate,
    required this.reportDate,
    required this.createId,
    required this.dsrParam,
    this.processType = 'A',
    this.docuNumb,
    this.dsrRem01 = '',
    this.dsrRem02 = '',
    this.dsrRem03 = '',
    this.dsrRem04 = '',
    this.dsrRem05 = '',
    this.dsrRem06 = '',
    this.dsrRem07 = '',
    this.dsrRem08 = '',
    this.latitude = '',
    this.longitude = '',
    this.purchaser = '',
    this.purchaserCode = '',
    this.areaCode = '',
  });

  Map<String, dynamic> toJson() => {
    'ActivityType': activityType,
    'SubmissionDate': _d(submissionDate),
    'ReportDate': _d(reportDate),
    'CreateId': createId,
    'DsrParam': dsrParam,
    'ProcessType': processType,
    'DocuNumb': docuNumb,
    'dsrRem01': dsrRem01,
    'dsrRem02': dsrRem02,
    'dsrRem03': dsrRem03,
    'dsrRem04': dsrRem04,
    'dsrRem05': dsrRem05,
    'dsrRem06': dsrRem06,
    'dsrRem07': dsrRem07,
    'dsrRem08': dsrRem08,
    'latitude': latitude,
    'longitude': longitude,
    'Purchaser': purchaser,
    'PurchaserCode': purchaserCode,
    'AreaCode': areaCode,
  }..removeWhere((_, v) => v == null || (v is String && v.isEmpty));

  static String _d(DateTime dt) => dt.toIso8601String().split('T').first;
}

class ExceptionItem {
  final String pendWith;
  final String userCode;
  final String excpType; // D
  final String excpDate; // dd/MM/yyyy or yyyy-MM-dd
  final String excpRemk;
  final String statFlag; // A/R for approval

  const ExceptionItem({
    this.pendWith = '',
    required this.userCode,
    required this.excpDate,
    this.excpType = 'D',
    this.excpRemk = '',
    this.statFlag = '',
  });

  Map<String, dynamic> toJson() => {
    'PendWith': pendWith,
    'UserCode': userCode,
    'ExcpType': excpType,
    'ExcpDate': excpDate,
    'ExcpRemk': excpRemk,
    'StatFlag': statFlag,
  }..removeWhere((_, v) => v == null || (v is String && v.isEmpty));
}

class ExceptionSubmitModel {
  final String procType; // N or A
  final String createId;
  final List<ExceptionItem> items;

  const ExceptionSubmitModel({
    required this.procType,
    required this.createId,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'ProcType': procType,
    'CreateId': createId,
    'Items': items.map((e) => e.toJson()).toList(),
  };
}
