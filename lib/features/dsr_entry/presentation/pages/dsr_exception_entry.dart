import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learning2/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DsrExceptionEntryPage extends StatefulWidget {
  const DsrExceptionEntryPage({super.key});

  @override
  State<DsrExceptionEntryPage> createState() => _DsrExceptionEntryPageState();
}

class _DsrExceptionEntryPageState extends State<DsrExceptionEntryPage> {
  // Form state
  String? selectedExceptionType;
  final TextEditingController dateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  // API-driven state
  String? approvalAuthority;
  String? approvalAuthorityId;
  List<Map<String, dynamic>> exceptionTypes = [];
  String? employeeName;
  String? employeeCode;
  List<Map<String, dynamic>> exceptionHistory = [];
  bool isLoading = true;
  String? errorMsg;
  bool isLoadingMetadata = true;
  String? metadataError;
  bool isSubmitting = false;

  // Replace with actual loginId from your auth/session
  final String loginId = '2948';

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() { isLoading = true; errorMsg = null; });
    try {
      await Future.wait([
        fetchApprovalAuthority(),
        fetchExceptionMetadata(),
        fetchEmployee(),
        fetchExceptionHistory(),
      ]);
    } catch (e) {
      setState(() { errorMsg = e.toString(); });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  Future<void> fetchApprovalAuthority() async {
    final response = await http.get(Uri.parse('http://10.4.64.23/api/DsrTry/getApprovalAuthority?loginId=$loginId'));
    print('getApprovalAuthority: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        approvalAuthority = data['approverName'] ?? '';
        approvalAuthorityId = data['approverId'] ?? '';
      });
    } else {
      setState(() { approvalAuthority = null; approvalAuthorityId = null; });
    }
  }

  Future<void> fetchExceptionMetadata() async {
    setState(() { isLoadingMetadata = true; metadataError = null; });
    try {
      final response = await http.get(Uri.parse('http://10.4.64.23/api/DsrTry/getExceptionMetadata?procType=N'));
      print('getExceptionMetadata: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          exceptionTypes = List<Map<String, dynamic>>.from(data['exceptionTypes'] ?? []);
          isLoadingMetadata = false;
        });
        print('exceptionTypes: $exceptionTypes');
      } else {
        setState(() {
          metadataError = 'Failed to load metadata';
          isLoadingMetadata = false;
        });
      }
    } catch (e) {
      setState(() {
        metadataError = e.toString();
        isLoadingMetadata = false;
      });
    }
  }

  Future<void> fetchEmployee() async {
    final response = await http.get(Uri.parse('http://10.4.64.23/api/DsrTry/getEmployees?procType=N&loginId=$loginId'));
    print('getEmployees: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        setState(() {
          employeeName = data[0]['name'] ?? '';
          employeeCode = data[0]['userCode'] ?? '';
          dateController.text = data[0]['excpDate'] ?? '';
          remarksController.text = data[0]['remarks'] ?? '';
        });
        print('employeeName: $employeeName');
      } else {
        setState(() {
          employeeName = '';
          employeeCode = '';
        });
      }
    } else {
      setState(() { employeeName = null; employeeCode = null; });
    }
  }

  Future<void> fetchExceptionHistory() async {
    final response = await http.get(Uri.parse('http://10.4.64.23/api/DsrTry/getExceptionHistory?procType=N&loginId=$loginId'));
    print('getExceptionHistory: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        setState(() {
          exceptionHistory = List<Map<String, dynamic>>.from(data);
        });
      }
    } else {
      setState(() { exceptionHistory = []; });
    }
  }

  Future<void> submitException() async {
    if (selectedExceptionType == null || (dateController.text.isEmpty && remarksController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() { isSubmitting = true; });
    final payload = {
      'ProcType': 'N',
      'CreateId': loginId,
      'Items': [
        {
          'PendWith': approvalAuthorityId ?? '',
          'UserCode': employeeCode ?? '',
          'ExcpType': selectedExceptionType,
          'ExcpDate': dateController.text,
          'ExcpRemk': remarksController.text,
          'StatFlag': 'N',
        }
      ]
    };
    print('submitExceptions payload: ${jsonEncode(payload)}');
    final response = await http.post(
      Uri.parse('http://10.4.64.23/api/DsrTry/submitExceptions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    print('submitExceptions: ${response.statusCode} ${response.body}');
    setState(() { isSubmitting = false; });
    if (response.statusCode == 201) {
      await fetchExceptionHistory();
      setState(() {
        selectedExceptionType = null;
        dateController.clear();
        remarksController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted successfully!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: ${response.body}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (d != null) {
      dateController.text = DateFormat('dd MMM yyyy').format(d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: const Color(0xFFe3ecfb),
      appBar: AppBar(
        title: const Text('DSR Exception Entry'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : errorMsg != null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Error: $errorMsg', style: const TextStyle(color: Colors.red)),
                  )
                : SingleChildScrollView(
                    child: SizedBox(
                      width: isWide ? 1500 : double.infinity,
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Info Box
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFcbe6ff),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• Please Note Exception is valid for Late DSR Entry earlier than 3 days', style: TextStyle(fontSize: 16, color: Colors.black)),
                                    SizedBox(height: 4),
                                    Text('• DSR Entry is must after Exception Approval for Attendance Entry', style: TextStyle(fontSize: 16, color: Colors.black)),
                                    SizedBox(height: 4),
                                    Text('• Exception Validity is also 3 days after date of Exception Approval', style: TextStyle(fontSize: 16, color: Colors.black)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Warning Box
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFcbe6ff),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: '• ',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: SparshTheme.primaryBlueAccent, fontSize: 18),
                                      ),
                                      TextSpan(
                                        text: 'Dear User : DSR Exception approval is position based not supervisor based and Your Approval Authrority is : ',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700], fontSize: 18),
                                      ),
                                      TextSpan(
                                        text: approvalAuthority ?? '',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700], fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // --- MOBILE FRIENDLY VERTICAL FORM ---
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Exception Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    isLoadingMetadata
                                        ? const Center(child: CircularProgressIndicator())
                                        : metadataError != null
                                            ? Text('Error: $metadataError', style: const TextStyle(color: Colors.red))
                                            : DropdownButtonFormField<String>(
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                ),
                                                items: exceptionTypes
                                                    .map((e) => DropdownMenuItem<String>(
                                                          value: e['code']?.toString() ?? '',
                                                          child: Text(e['description']?.toString() ?? ''),
                                                        ))
                                                    .toList(),
                                                value: selectedExceptionType,
                                                onChanged: (v) {
                                                  print('selectedExceptionType: $v');
                                                  setState(() => selectedExceptionType = v);
                                                },
                                              ),
                                    const SizedBox(height: 16),
                                    const Text('Employee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: Text(employeeName ?? '', style: const TextStyle(fontSize: 16)),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Exception Date for DSR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: dateController,
                                      readOnly: true,
                                      onTap: _pickDate,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        suffixIcon: const Icon(Icons.calendar_today),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: remarksController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Submit Button
                              Center(
                                child: ElevatedButton(
                                  onPressed: isSubmitting ? null : submitException,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SparshTheme.primaryBlueAccent,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Submit'),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // History Table
                              const Text('Exception History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: SparshTheme.primaryBlueAccent)),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                                  dataRowColor: WidgetStateProperty.all(Colors.white),
                                  columnSpacing: 24,
                                  horizontalMargin: 12,
                                  dividerThickness: 1.2,
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Employee',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Exception Date for DSR',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Remarks',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Status',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Create Date',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: exceptionHistory.map((record) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(record['Employee']?.toString() ?? '')),
                                        DataCell(Text(record['ExcpDate']?.toString() ?? '')),
                                        DataCell(Text(record['Remarks']?.toString() ?? '')),
                                        DataCell(Text(record['Status']?.toString() ?? '')),
                                        DataCell(Text(record['CreateDate']?.toString() ?? '')),
                                      ],
                                    );
                                  }).toList(),
                                  border: TableBorder.all(color: Colors.grey, width: 1.2),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
