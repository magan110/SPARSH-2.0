class TokenSummaryModel {
  static final TokenSummaryModel _instance = TokenSummaryModel._internal();
  factory TokenSummaryModel() => _instance;
  TokenSummaryModel._internal();

  int totalScan = 0;
  int validScan = 0;
  int expiredScan = 0;
  int alreadyScanned = 0;
  int invalidScan = 0;
  int totalAmount = 0;

  final List<Map<String, dynamic>> scannedTokens = [];

  void reset() {
    totalScan = 0;
    validScan = 0;
    expiredScan = 0;
    alreadyScanned = 0;
    invalidScan = 0;
    totalAmount = 0;
    scannedTokens.clear();
  }

  void addScan({
    required bool isValid,
    int value = 0,
    bool isExpired = false,
    bool isAlreadyScanned = false,
    required Map<String, dynamic> tokenDetail,
  }) {
    totalScan++;
    scannedTokens.add(tokenDetail);
    if (isValid) {
      validScan++;
      totalAmount += value;
    } else if (isExpired) {
      expiredScan++;
    } else if (isAlreadyScanned) {
      alreadyScanned++;
    } else {
      invalidScan++;
    }
  }
}
