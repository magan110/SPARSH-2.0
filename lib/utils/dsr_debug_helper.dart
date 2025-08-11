import 'dart:convert';

class DSRDebugHelper {
  static void logDocumentNumber(String context, String? docNumber) {
    print('DSR DEBUG [$context] - Document Number Analysis:');
    print('  Raw value: ${docNumber == null ? "NULL" : "\"$docNumber\""}');
    print('  Length: ${docNumber?.length ?? 0}');
    print('  Is null: ${docNumber == null}');
    print('  Is empty: ${docNumber?.isEmpty ?? true}');
    print('  Trimmed length: ${docNumber?.trim().length ?? 0}');
    print(
      '  Is only spaces: ${docNumber != null ? RegExp(r'^\s*$').hasMatch(docNumber) : false}',
    );
    print('  Char codes: ${docNumber?.codeUnits ?? []}');
    print('  Valid: ${_isValidDocumentNumber(docNumber)}');
    print('');
  }

  static bool _isValidDocumentNumber(String? docNumber) {
    return docNumber != null &&
        docNumber.isNotEmpty &&
        docNumber.trim().isNotEmpty &&
        !RegExp(r'^\s*$').hasMatch(docNumber);
  }

  static void logActivityDetails(List<Map<String, dynamic>> activityDetails) {
    print('DSR DEBUG - Activity Details Analysis:');
    print('  Total activities: ${activityDetails.length}');

    for (int i = 0; i < activityDetails.length; i++) {
      final activity = activityDetails[i];
      final docNumber = activity['docuNumb']?.toString();
      final seqNumber = activity['seqNumb']?.toString();

      print('  Activity $i:');
      print('    DocuNumb: ${docNumber == null ? "NULL" : "\"$docNumber\""}');
      print('    DocuNumb length: ${docNumber?.length ?? 0}');
      print('    DocuNumb valid: ${_isValidDocumentNumber(docNumber)}');
      print('    SeqNumb: ${seqNumber == null ? "NULL" : "\"$seqNumber\""}');
      print('    MrktData: ${activity['mrktData']}');
      print('    Primary Key: ($docNumber, $seqNumber)');
    }
    print('');
  }

  static void logDSRData(Map<String, dynamic> dsrData) {
    print('DSR DEBUG - Complete DSR Data Analysis:');
    final mainDoc = (dsrData['DocuNumb'] ?? dsrData['docuNumb'])?.toString();
    print('  Main DocuNumb: $mainDoc');
    print('  Main DocuNumb length: ${mainDoc?.length ?? 0}');
    print('  Main DocuNumb valid: ${_isValidDocumentNumber(mainDoc)}');

    if (dsrData['activityDetails'] is List) {
      // Safely convert dynamic list to List<Map<String, dynamic>>
      final rawList = dsrData['activityDetails'] as List;
      final List<Map<String, dynamic>> activities = [];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          activities.add(item);
        } else if (item is Map) {
          activities.add(Map<String, dynamic>.from(item));
        }
      }
      logActivityDetails(activities);
    }

    print(
      '  Full JSON (first 500 chars): ${json.encode(dsrData).substring(0, 500)}...',
    );
    print('');
  }

  static String generateDebugDocumentNumber(String areaCode) {
    final now = DateTime.now().toUtc();

    // Handle empty area code
    if (areaCode.isEmpty) {
      areaCode = 'DBG';
    }

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
    final docNumber = 'DSR$areaCodePadded$timestamp';

    // Ensure it's exactly 16 characters
    final finalDocNumber =
        docNumber.length > 16
            ? docNumber.substring(0, 16)
            : docNumber.padRight(16, '0');

    print(
      'DSR DEBUG - Generated document number: "$finalDocNumber" (${finalDocNumber.length} chars)',
    );
    return finalDocNumber;
  }

  static void validateBeforeSubmission(Map<String, dynamic> dsrData) {
    print('DSR DEBUG - PRE-SUBMISSION VALIDATION:');

    final procType = dsrData['procType']?.toString() ?? 'A';
    print('  Process Type: $procType');

    // Check main document number
    final mainDocNumber =
        (dsrData['DocuNumb'] ?? dsrData['docuNumb'])?.toString();
    print('  Main document number validation:');
    logDocumentNumber('MAIN_DOC', mainDocNumber);

    // For Add operations (procType 'A'), allow empty document numbers
    // as the API will generate them
    if (procType == 'A') {
      print(
        '  ✓ Add operation: Empty document numbers allowed for API generation',
      );
    } else {
      // For Update/Delete operations, validate document numbers are not empty
      if (!_isValidDocumentNumber(mainDocNumber)) {
        throw Exception(
          'VALIDATION FAILED: Main document number is invalid for Update/Delete operation',
        );
      }
    }

    // Check activity details
    if (dsrData['dsrActivityDtls'] is List) {
      final activities = dsrData['dsrActivityDtls'] as List;
      print('  Activity details validation:');

      for (int i = 0; i < activities.length; i++) {
        final activity = activities[i] as Map<String, dynamic>;
        final actDocNumber = activity['docuNumb']?.toString();
        final seqNumber = activity['seqNumb']?.toString();

        print('    Activity $i:');

        // For Add operations, allow empty document numbers in activity details
        if (procType == 'A') {
          print(
            '      ✓ Add operation: Empty document number allowed - SeqNumb: "$seqNumber"',
          );
        } else {
          // For Update/Delete operations, validate document numbers
          if (!_isValidDocumentNumber(actDocNumber)) {
            throw Exception(
              'VALIDATION FAILED: Activity $i has invalid document number: "$actDocNumber"',
            );
          }
          print(
            '      ✓ Valid - DocuNumb: "$actDocNumber", SeqNumb: "$seqNumber"',
          );
        }

        if (seqNumber == null || seqNumber.trim().isEmpty) {
          throw Exception(
            'VALIDATION FAILED: Activity $i has invalid sequence number: "$seqNumber"',
          );
        }
      }
    }

    print('  ✓ ALL VALIDATIONS PASSED');
    print('');
  }

  static void logDSRSubmission(Map<String, dynamic> dsrData) {
    print('DSR DEBUG - SUBMISSION DATA:');
    logDSRData(dsrData);
  }

  static void logAPIResponse(int statusCode, String body, String endpoint) {
    print('DSR DEBUG - API RESPONSE [$endpoint]:');
    print('  Status Code: $statusCode');
    print('  Response Body: $body');
    print('  Success: ${statusCode == 200}');

    if (statusCode != 200 && body.contains('PRIMARY KEY constraint')) {
      print('  ⚠️  PRIMARY KEY CONSTRAINT VIOLATION DETECTED!');

      // Try to extract the duplicate key value
      final regex = RegExp(r'duplicate key value is \(([^)]+)\)');
      final match = regex.firstMatch(body);
      if (match != null) {
        final keyValue = match.group(1);
        print('  ⚠️  Duplicate key value: "$keyValue"');

        // Analyze the key value
        if (keyValue != null) {
          final parts = keyValue.split(',').map((s) => s.trim()).toList();
          if (parts.length >= 2) {
            final docNumber = parts[0];
            final seqNumber = parts[1];
            print(
              '  ⚠️  Document Number: "$docNumber" (${docNumber.length} chars)',
            );
            print('  ⚠️  Sequence Number: "$seqNumber"');
            print(
              '  ⚠️  Document Number is spaces only: ${RegExp(r'^\s*$').hasMatch(docNumber)}',
            );
          }
        }
      }
    }
    print('');
  }
}
