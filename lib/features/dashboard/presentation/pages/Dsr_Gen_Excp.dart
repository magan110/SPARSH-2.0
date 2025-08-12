import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learning2/features/dashboard/presentation/pages/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Exception Request',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: const EmployeeExceptionRequest(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EmployeeExceptionRequest extends StatefulWidget {
  const EmployeeExceptionRequest({super.key});

  @override
  State<EmployeeExceptionRequest> createState() =>
      _EmployeeExceptionRequestState();
}

class _EmployeeExceptionRequestState extends State<EmployeeExceptionRequest> {
  final TextEditingController _employeeCodeController = TextEditingController(
    text: '', // Default empty employee code
  );
  final List<Map<String, dynamic>> _exceptions = [];
  final List<Map<String, dynamic>> _dsrRecords = [];
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final Set<int> _selectedExceptionIds = <int>{};
  int _nextExceptionId = 1;
  // Networking / API state
  // Matches ExceptionApprovalController (server) base URL
  static const String _baseUrl = 'http://10.4.64.23/api/ExceptionApproval';
  bool _loadingPending = false;
  bool _loadingHistory = false;
  bool _processingAction = false;
  String? _errorPending;
  String? _errorHistory;

  @override
  void initState() {
    super.initState();
    // Do not fetch on load if employee code empty
    _employeeCodeController.addListener(() {
      if (_employeeCodeController.text.trim().isEmpty) {
        setState(() {
          _exceptions.clear();
          _dsrRecords.clear();
          _selectedExceptionIds.clear();
          _errorPending = null;
          _errorHistory = null;
          _loadingPending = false;
          _loadingHistory = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _employeeCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Exception Request'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            // Navigate explicitly to HomeScreen as requested
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loginId.isEmpty ? null : _fetchAll,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            _buildInfoCard(),
            const SizedBox(height: 20),

            // Employee Code Input
            _buildEmployeeCodeField(),
            const SizedBox(height: 24),

            // Exceptions Section
            _buildSectionTitle('Pending Exception Requests'),
            const SizedBox(height: 12),
            _buildExceptionsList(),
            const SizedBox(height: 24),

            // DSR Records Section
            _buildSectionTitle('DSR Records (Approved/Rejected)'),
            const SizedBox(height: 12),
            _buildDsrList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exception Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Submit exception requests for employees. All exceptions require DSR date selection.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Employee Code',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _employeeCodeController,
          decoration: InputDecoration(
            hintText: 'Enter employee code',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _onSearch,
              tooltip: 'Load data for this employee code',
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onEditingComplete: _onSearch,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildExceptionsList() {
    if (_loginId.isEmpty) {
      return _buildEmptyState('Enter employee code to view pending exceptions');
    }
    // Filter exceptions to show only pending ones
    // Server already filters by employeeCode if provided; just separate status
    final pendingExceptions =
        _exceptions.where((e) => e['status'] == 'Pending').toList();

    return Column(
      children: [
        if (_loadingPending)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorPending != null)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              _errorPending!,
              style: const TextStyle(color: Colors.red),
            ),
          )
        else if (pendingExceptions.isEmpty)
          _buildEmptyState('No pending exception requests')
        else
          Column(
            children:
                pendingExceptions.map((exception) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildExceptionCard(exception),
                  );
                }).toList(),
          ),
        const SizedBox(height: 8),
        _buildApproveRejectButtons(
          _selectedExceptionIds.isEmpty || _processingAction,
        ),
      ],
    );
  }

  Widget _buildExceptionCard(Map<String, dynamic> exception) {
    final int id = exception['id'] as int;
    final bool selected = _selectedExceptionIds.contains(id);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Checkbox + Type
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: selected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedExceptionIds.add(id);
                            } else {
                              _selectedExceptionIds.remove(id);
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          exception['type'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(exception['status']),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Employee', exception['employee']),
            const SizedBox(height: 8),
            _buildInfoRow('Date', _dateFormat.format(exception['date'])),
            const SizedBox(height: 8),
            _buildInfoRow('Remarks', exception['remarks']),
          ],
        ),
      ),
    );
  }

  Widget _buildDsrList() {
    if (_loginId.isEmpty) {
      return _buildEmptyState('Enter employee code to view history');
    }
    // Filter DSR records to show only approved and rejected
    final filteredDsrRecords =
        _dsrRecords
            .where(
              (r) => r['status'] == 'Approved' || r['status'] == 'Rejected',
            )
            .toList();

    return Column(
      children: [
        if (_loadingHistory)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorHistory != null)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              _errorHistory!,
              style: const TextStyle(color: Colors.red),
            ),
          )
        else if (filteredDsrRecords.isEmpty)
          _buildEmptyState('No approved or rejected DSR records')
        else
          Column(
            children:
                filteredDsrRecords.map((record) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildDsrCard(record),
                  );
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildDsrCard(Map<String, dynamic> record) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with employee name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    record['employee'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(record['status']),
              ],
            ),
            const SizedBox(height: 16),

            // Exception Date
            _buildInfoRowWithIcon(
              'Exception Date',
              _dateFormat.format(record['exceptionDate']),
              Icons.calendar_today,
            ),
            const SizedBox(height: 8),

            // Remarks
            _buildInfoRowWithIcon('Remarks', record['remarks'], Icons.notes),
            const SizedBox(height: 8),

            // Create Date
            _buildInfoRowWithIcon(
              'Created',
              '${_dateFormat.format(record['createDate'])} at ${_timeFormat.format(record['createDate'])}',
              Icons.access_time,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithIcon(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'approved':
        chipColor = Colors.green;
        break;
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'rejected':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildApproveRejectButtons(bool disable) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: disable ? null : () => _submitDecision('approve'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Approve',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: disable ? null : () => _submitDecision('reject'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text(
                'Reject',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Networking helpers ----
  // Employee code to filter (not the approver id; approver fixed server-side as 3110)
  String get _loginId => _employeeCodeController.text.trim();

  Future<void> _fetchAll() async {
    if (_loginId.isEmpty) {
      setState(() {
        _exceptions.clear();
        _dsrRecords.clear();
        _selectedExceptionIds.clear();
      });
      return;
    }
    _selectedExceptionIds.clear();
    await Future.wait([_fetchPending(), _fetchHistory()]);
  }

  Future<void> _fetchPending() async {
    if (_loginId.isEmpty) return; // guard
    setState(() {
      _loadingPending = true;
      _errorPending = null;
    });
    try {
      final uri =
          _loginId.isEmpty
              ? Uri.parse('$_baseUrl/pending')
              : Uri.parse(
                '$_baseUrl/pending?employeeCode=${Uri.encodeQueryComponent(_loginId)}',
              );
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('Server ${resp.statusCode}: ${resp.body}');
      }
      final List list = json.decode(resp.body) as List;
      _exceptions
        ..clear()
        ..addAll(
          list.map((e) {
            // New controller returns: id, type, employee, date, remarks, status, legacyDate, createDate
            final isoDate = e['date'];
            return {
              'id': (e['id'] ?? _nextExceptionId++).hashCode,
              'type': e['type'] ?? 'Unknown',
              'employee': e['employee'] ?? '',
              // We don't receive usrCdExc in payload; tag with current filter value if provided
              'usrCdExc': _loginId.isEmpty ? '' : _loginId,
              'date': _safeParseDate(isoDate),
              'rawDate': isoDate,
              'remarks': e['remarks'] ?? '',
              'status': e['status'] ?? 'Pending',
              'legacyDate': e['legacyDate'],
              'createDateRaw': e['createDate'],
            };
          }),
        );
    } catch (e) {
      _errorPending = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loadingPending = false);
      }
    }
  }

  Future<void> _fetchHistory() async {
    if (_loginId.isEmpty) return; // guard
    setState(() {
      _loadingHistory = true;
      _errorHistory = null;
    });
    try {
      final uri =
          _loginId.isEmpty
              ? Uri.parse('$_baseUrl/history')
              : Uri.parse(
                '$_baseUrl/history?employeeCode=${Uri.encodeQueryComponent(_loginId)}',
              );
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('Server ${resp.statusCode}: ${resp.body}');
      }
      final List list = json.decode(resp.body) as List;
      _dsrRecords
        ..clear()
        ..addAll(
          list.map((e) {
            // New history returns: employee, exceptionDate, remarks, status, createDate, updateDate (optional)
            final excDate = e['exceptionDate'];
            return {
              'employee': e['employee'] ?? '',
              'usrCdExc': _loginId.isEmpty ? '' : _loginId,
              'exceptionDate': _safeParseDate(excDate),
              'remarks': e['remarks'] ?? '',
              'status': e['status'] ?? 'Unknown',
              'createDate': _safeParseDateTime(e['createDate']),
            };
          }),
        );
    } catch (e) {
      _errorHistory = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  DateTime _safeParseDate(dynamic v) {
    if (v == null) return DateTime.now();
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  DateTime _safeParseDateTime(dynamic v) => _safeParseDate(v);

  Future<void> _submitDecision(String action) async {
    if (_selectedExceptionIds.isEmpty || _processingAction) return;
    setState(() => _processingAction = true);
    final selected = _exceptions.where(
      (e) => _selectedExceptionIds.contains(e['id']),
    );
    final items = selected.map(
      (e) => {
        'UsrCdExc': _loginId, // employee code (user) whose exception row it is
        'ExcpType': e['type'],
        // Send date as yyyy-MM-dd; server accepts this per DateFormats
        'ExcpDat1': (e['rawDate'] ?? _dateFormat.format(e['date'] as DateTime)),
      },
    );
    final body = json.encode({
      'UpdateId':
          '3110', // server will override / fixed approver; included for completeness
      'Items': items.toList(),
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action in progress...')));
    try {
      final uri = Uri.parse('$_baseUrl/$action');
      final resp = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 25));
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Success: $action completed')));
        _selectedExceptionIds.clear();
        await _fetchPending();
        await _fetchHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${resp.statusCode}: ${resp.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      if (mounted) setState(() => _processingAction = false);
    }
  }

  void _onSearch() {
    FocusScope.of(context).unfocus();
    final id = _loginId;
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter employee code first.')),
      );
      return;
    }
    _fetchAll();
  }
}
