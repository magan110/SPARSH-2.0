import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'All_Tokens.dart';

class TokenScanPage extends StatefulWidget {
  const TokenScanPage({super.key});

  @override
  State<TokenScanPage> createState() => _TokenScanPageState();
}

class _TokenScanPageState extends State<TokenScanPage>
    with TickerProviderStateMixin {
  MobileScannerController? _cameraController;
  String? _scannedValue;
  String? _pinValidationMessage;
  bool _isTokenValid = false;
  int _remainingAttempts = 3;
  final List<TextEditingController> pinControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  List<FocusNode> pinFocusNodes = List.generate(3, (_) => FocusNode());
  bool _isTorchOn = false;
  bool _isProcessingScan = false;
  DateTime? _lastScanTime;

  final Set<String> _recentlyScannedTokens = {};
  final Map<String, DateTime> _lastScanTimeMap = {};
  final Map<String, DateTime> _lastErrorMessageTimeMap = {};
  final Set<String> _maxAttemptsReachedTokens = {};
  final Set<String> _validatedTokens = {};
  final List<TokenCard> _attemptedCards = [];
  String? _apiAutoPin;
  final bool _showMaxAttemptsError = false;
  Map<String, dynamic> _tokenDetails = {};

  late AnimationController _animationController;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _scanLineController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  @override
  void dispose() {
    _cameraController?.stop();
    _cameraController?.dispose();
    for (var node in pinFocusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      if (_cameraController != null) {
        await _cameraController?.stop();
        _cameraController?.dispose();
      }
      setState(() {
        _cameraController = MobileScannerController(
          detectionSpeed: DetectionSpeed.unrestricted,
          facing: CameraFacing.back,
          formats: [BarcodeFormat.qrCode],
          torchEnabled: false,
        );
      });
      await _cameraController?.start();
    } catch (e) {
      print('Camera initialization error: $e');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _initializeCamera();
      });
    }
  }

  Future<void> _validateToken(String token) async {
    // Prevent duplicate scans within a short time frame
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 1000) {
      return;
    }
    _lastScanTime = now;

    // Check if we're already processing a scan
    if (_isProcessingScan) return;

    setState(() {
      _isProcessingScan = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      // For demo purposes, we'll simulate a successful validation
      // In real implementation, this would make an API call
      setState(() {
        _scannedValue = token;
        _isTokenValid = true;
        _tokenDetails = {
          'Token ID': token,
          'Valid Until': '2024-12-31',
          'Amount': '100',
          'Handling Fee': '5',
          'Status': 'Active',
        };
      });

      // Show PIN dialog for validation
      _showPinDialog(token);
    } catch (e) {
      print('Token validation error: $e');
    } finally {
      setState(() {
        _isProcessingScan = false;
      });
    }
  }

  Future<void> _fetchTokenDetails(String token) async {
    // Implementation for fetching token details from API
    // This would typically make an HTTP request
  }

  Future<void> _validatePin(String token, String pin) async {
    // Implementation for PIN validation
    // This would typically make an API request to validate the PIN
  }

  void _addAttemptedToken(String token, String pin, bool isValid) {
    setState(() {
      _attemptedCards.add(
        TokenCard(
          token: token,
          id: _tokenDetails['Token ID'] ?? '',
          date: _tokenDetails['Valid Until'] ?? '',
          value: _tokenDetails['Amount'] ?? '',
          handling: _tokenDetails['Handling Fee'] ?? '',
          isValid: isValid,
          pin: pin,
          additionalDetails: _tokenDetails.cast<String, String>(),
        ),
      );
    });
  }

  void _restartScan() {
    setState(() {
      _scannedValue = null;
      _isTokenValid = false;
      _pinValidationMessage = null;
      _remainingAttempts = 3;
      _isProcessingScan = false;
    });
  }

  Future<void> _submitAllTokens() async {
    if (_attemptedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tokens to submit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Simulate API submission
      await Future.delayed(const Duration(seconds: 2));

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All tokens submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the attempted cards
      setState(() {
        _attemptedCards.clear();
      });
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting tokens: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTokenSummaryPopup() {
    // Implementation for showing token summary popup
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(padding: const EdgeInsets.all(8), child: Text(value)),
      ],
    );
  }

  void _showMaxRetryDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Maximum Attempts Reached'),
            content: const Text(
              'You have reached the maximum number of PIN attempts for this token.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showPinDialog(String token) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter PIN for token: $token'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) {
                    return SizedBox(
                      width: 50,
                      child: TextField(
                        controller: pinControllers[index],
                        focusNode: pinFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: const InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 2) {
                            pinFocusNodes[index + 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  String pin = pinControllers.map((c) => c.text).join();
                  Navigator.of(context).pop();
                  _addAttemptedToken(token, pin, true); // For demo, always true
                  _restartScan();
                },
                child: const Text('Submit'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Enhanced Scanner View with 3D Effects
              Container(
                height: 270,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.7),
                      blurRadius: 15,
                      offset: const Offset(-5, -5),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade800, Colors.blue.shade600],
                  ),
                ),
                child: Stack(
                  children: [
                    // Camera Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child:
                          _cameraController != null
                              ? MobileScanner(
                                controller: _cameraController,
                                onDetect: (capture) {
                                  final barcode = capture.barcodes.first;
                                  if (barcode.rawValue != null &&
                                      barcode.format == BarcodeFormat.qrCode) {
                                    _validateToken(barcode.rawValue!);
                                  }
                                },
                                scanWindow: Rect.largest,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, child) {
                                  return Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Camera error. Please check permissions.',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  );
                                },
                              )
                              : const Center(
                                child: CircularProgressIndicator(),
                              ),
                    ),

                    // Scanner Frame with 3D Effect
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Corner markers
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    left: BorderSide(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    right: BorderSide(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    left: BorderSide(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    right: BorderSide(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Animated Scan Line
                            AnimatedBuilder(
                              animation: _scanLineAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  top: 220 * _scanLineAnimation.value - 2,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.white,
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Flashlight Button with 3D Effect
                    Positioned(
                      right: 20,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.5),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 8,
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isTorchOn ? Icons.flash_off : Icons.flash_on,
                              color: Colors.blue.shade800,
                              size: 30,
                            ),
                            onPressed: () {
                              _cameraController?.toggleTorch().then((_) {
                                setState(() {
                                  _isTorchOn = !_isTorchOn;
                                });
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    // Processing Overlay
                    if (_isProcessingScan)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Navigation Tabs with 3D Effect
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.9),
                      blurRadius: 10,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: _buildTopNav(context, 'Details'),
              ),

              const SizedBox(height: 16),

              // Token List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.9),
                        blurRadius: 10,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_attemptedCards.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Token/PIN Attempts:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ..._attemptedCards,
                      // Only show the submit button if there are token cards
                      if (_attemptedCards.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade600,
                                  Colors.green.shade400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.7),
                                  blurRadius: 10,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _submitAllTokens,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.save, size: 24),
                              label: const Text(
                                'Submit All Tokens',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(BuildContext context, String activeTab) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            context,
            'Details',
            activeTab == 'Details',
            const Text('Details'),
          ),
          _navItem(
            context,
            'All Tokens',
            activeTab == 'All Tokens',
            const AllTokens(),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String label,
    bool isActive,
    Widget targetPage,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            if (label == 'All Tokens') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllTokens()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => targetPage),
              );
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient:
                isActive
                    ? LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.7),
                        blurRadius: 8,
                        offset: const Offset(-2, -2),
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TokenCard extends StatefulWidget {
  final String token;
  final String id;
  final String date;
  final String value;
  final String handling;
  final bool isValid;
  final String pin;
  final Map<String, String>? additionalDetails;
  final bool initiallyExpanded;

  const TokenCard({
    super.key,
    required this.token,
    required this.id,
    required this.date,
    required this.value,
    required this.handling,
    required this.isValid,
    required this.pin,
    this.additionalDetails,
    this.initiallyExpanded = false,
  });

  @override
  State<TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<TokenCard> with TickerProviderStateMixin {
  late bool isExpanded;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded || widget.isValid;

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    if (isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  Future<void> _submitTokenToAllTokens(BuildContext context) async {
    // Implementation for submitting token to all tokens
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> fields) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ...fields.map((field) {
            String? value = widget.additionalDetails?[field];
            if (value != null && value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$field: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: Text(value, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: widget.isValid ? Colors.green.shade300 : Colors.red.shade300,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Card Header with 3D Effect
            InkWell(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                  if (isExpanded) {
                    _expandController.forward();
                  } else {
                    _expandController.reverse();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient:
                      widget.isValid
                          ? LinearGradient(
                            colors: [
                              Colors.green.shade700,
                              Colors.green.shade500,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : LinearGradient(
                            colors: [Colors.red.shade700, Colors.red.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          widget.isValid
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.7),
                      blurRadius: 8,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.token,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.expand_more,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card Content with Animation
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child:
                    widget.isValid
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main token information in a card with 3D effect
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.9),
                                    blurRadius: 8,
                                    offset: const Offset(-2, -2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Token ID row
                                  if (widget.id.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Token ID: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              widget.id,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Valid until row
                                  if (widget.date.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Valid Until: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              widget.date,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Amount row
                                  if (widget.value.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Amount: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '₹${widget.value}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Handling fee row
                                  if (widget.handling.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Handling Fee: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            '₹${widget.handling}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // PIN row
                                  Row(
                                    children: [
                                      const Text(
                                        'PIN: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Container(
                                        width: 60,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade700,
                                              Colors.blue.shade500,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(-1, -1),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          widget.pin,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Display additional details if available
                            if (widget.additionalDetails != null &&
                                widget.additionalDetails!.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  const Divider(height: 1, thickness: 1),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Token Details:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Group details into sections with all the requested parameters
                                  _buildDetailSection('Basic Information', [
                                    'Token ID',
                                    'Valid Until',
                                    'Status',
                                    'Secondary Status',
                                    'Token Type',
                                    'Expiry Flag',
                                    'PIN Required',
                                  ]),
                                  const SizedBox(height: 12),
                                  _buildDetailSection('Financial Information', [
                                    'Amount',
                                    'Handling Fee',
                                    'Discount',
                                    'Total Amount',
                                    'Additional Amount',
                                  ]),
                                  const SizedBox(height: 12),
                                  _buildDetailSection('Usage Information', [
                                    'Scan Count',
                                    'Scan Allowed',
                                    'Scanned By',
                                  ]),
                                  const SizedBox(height: 12),
                                  _buildDetailSection(
                                    'Administrative Information',
                                    ['Updated By', 'Secondary Update ID'],
                                  ),
                                ],
                              ),

                            const SizedBox(height: 16),

                            // Status indicator with 3D effect
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade700,
                                      Colors.green.shade500,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withAlpha(100),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.7),
                                      blurRadius: 10,
                                      offset: const Offset(-2, -2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Token Accepted',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Submit button with 3D effect
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade700,
                                      Colors.blue.shade500,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.7),
                                      blurRadius: 10,
                                      offset: const Offset(-2, -2),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _submitTokenToAllTokens(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.send, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Submit Token',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Error - ${widget.token}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Please check with IT or Company Officer',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text(
                                  'Tried PIN: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    widget.pin,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.7),
                                      blurRadius: 6,
                                      offset: const Offset(-1, -1),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Rejected',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
