import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learning2/features/dashboard/presentation/pages/home_screen.dart';
import 'package:learning2/core/constants/fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LogInOtp extends StatefulWidget {
  const LogInOtp({super.key});

  @override
  State<LogInOtp> createState() => _LogInOtpState();
}

class _LogInOtpState extends State<LogInOtp>
    with SingleTickerProviderStateMixin {
  // Controllers for text fields
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isOtpSent = false;
  String _verificationId = '';
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _resendTimer = 30;
  bool _canResend = false;
  bool _isLoading = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(title, style: Fonts.bodyBold.copyWith(fontSize: 16)),
            content: Text(
              message,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
            _startResendTimer();
          } else {
            _canResend = true;
          }
        });
      }
    });
  }

  Future<void> sendOTP() async {
    if (_phoneController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter phone number");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91${_phoneController.text}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _handleSuccessfulLogin();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number';
          }
          Fluttertoast.showToast(msg: errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isOtpSent = true;
            _verificationId = verificationId;
            _isLoading = false;
          });
          _startResendTimer();
          Fluttertoast.showToast(msg: "OTP sent successfully!");

          // Focus on first OTP field
          FocusScope.of(context).requestFocus(_otpFocusNodes[0]);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: "Failed to send OTP");
    }
  }

  Future<void> verifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      Fluttertoast.showToast(msg: "Please enter complete OTP");
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      _handleSuccessfulLogin();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isVerifying = false;
      });
      String errorMessage = 'Invalid OTP';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid verification code';
      }
      Fluttertoast.showToast(msg: errorMessage);

      // Clear OTP fields on error
      for (var controller in _otpControllers) {
        controller.clear();
      }
      FocusScope.of(context).requestFocus(_otpFocusNodes[0]);
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      Fluttertoast.showToast(msg: "Verification failed");
    }
  }

  Future<void> _handleSuccessfulLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  // Handle OTP field changes
  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
    }

    // Auto-submit when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      bool allFilled = _otpControllers.every(
        (controller) => controller.text.isNotEmpty,
      );
      if (allFilled) {
        verifyOTP();
      }
    }
  }

  // Handle backspace in OTP fields
  void _onOtpBackspace(int index) {
    if (index > 0 && _otpControllers[index].text.isEmpty) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.blue.shade700),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 24.0,
                    vertical: 16.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with responsive sizing
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OTP Verification',
                                  style: Fonts.bodyBold.copyWith(
                                    fontSize: isSmallScreen ? 28 : 32,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 6 : 8),
                                Text(
                                  'Enter your mobile number to receive OTP',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 30 : 40),

                        // Card container for form
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mobile Number Field with improved design
                                  Text(
                                    'Mobile Number',
                                    style: Fonts.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Enter 10-digit mobile number',
                                        prefixIcon: Icon(
                                          Icons.phone_android,
                                          color: Colors.blue.shade700,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 14 : 16,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your mobile number';
                                        }
                                        if (value.length != 10) {
                                          return 'Please enter a valid 10-digit mobile number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  // OTP Fields with improved design
                                  if (_isOtpSent) ...[
                                    Text(
                                      'Enter OTP',
                                      style: Fonts.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 12 : 16),

                                    // OTP input fields
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        6,
                                        (index) => Container(
                                          width: isSmallScreen ? 40 : 50,
                                          height: isSmallScreen ? 50 : 60,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  _otpControllers[index]
                                                          .text
                                                          .isNotEmpty
                                                      ? Colors.blue.shade700
                                                      : Colors.grey.shade300,
                                              width:
                                                  _otpControllers[index]
                                                          .text
                                                          .isNotEmpty
                                                      ? 2
                                                      : 1,
                                            ),
                                          ),
                                          child: TextFormField(
                                            controller: _otpControllers[index],
                                            focusNode: _otpFocusNodes[index],
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                1,
                                              ),
                                            ],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 18 : 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              counterText: '',
                                            ),
                                            onChanged:
                                                (value) =>
                                                    _onOtpChanged(index, value),
                                            onFieldSubmitted:
                                                (_) => _onOtpChanged(index, ""),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: isSmallScreen ? 20 : 24),

                                    // Verify OTP Button
                                    Container(
                                      width: double.infinity,
                                      height: isSmallScreen ? 48 : 55,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isVerifying ? null : verifyOTP,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade700,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          elevation: 0,
                                          disabledBackgroundColor:
                                              Colors.blue.shade200,
                                        ),
                                        child:
                                            _isVerifying
                                                ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      'Verifying...',
                                                      style: TextStyle(
                                                        fontSize:
                                                            isSmallScreen
                                                                ? 16
                                                                : 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                : Text(
                                                  'Verify OTP',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen ? 16 : 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                      ),
                                    ).animate().fadeIn().slideY(
                                      begin: 0.2,
                                      end: 0,
                                    ),
                                  ],

                                  // Send OTP Button (only shown when OTP not sent)
                                  if (!_isOtpSent)
                                    Container(
                                      width: double.infinity,
                                      height: isSmallScreen ? 48 : 55,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : sendOTP,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade700,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          elevation: 0,
                                          disabledBackgroundColor:
                                              Colors.blue.shade200,
                                        ),
                                        child:
                                            _isLoading
                                                ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      'Sending...',
                                                      style: TextStyle(
                                                        fontSize:
                                                            isSmallScreen
                                                                ? 16
                                                                : 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                : Text(
                                                  'Send OTP',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen ? 16 : 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                      ),
                                    ).animate().fadeIn().slideY(
                                      begin: 0.2,
                                      end: 0,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 20 : 30),

                        // Resend OTP Timer/Button
                        if (_isOtpSent)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Center(
                                child: TextButton(
                                  onPressed:
                                      _canResend
                                          ? () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              _startResendTimer();
                                              _showAlertDialog(
                                                'OTP Resent',
                                                'New OTP has been sent to +91${_phoneController.text}',
                                              );
                                            }
                                          }
                                          : null,
                                  child: Text(
                                    _canResend
                                        ? 'Resend OTP'
                                        : 'Resend OTP in $_resendTimer seconds',
                                    style: TextStyle(
                                      color:
                                          _canResend
                                              ? Colors.blue.shade700
                                              : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
