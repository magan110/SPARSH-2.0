import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_theme.dart';
import 'DsrVisitScreen.dart';

class DsrRetailerInOut extends StatefulWidget {
  const DsrRetailerInOut({super.key});
  @override
  State<DsrRetailerInOut> createState() => _DsrRetailerInOutState();
}

class PurchaserRetailerType {
  final String code;
  final String description;
  PurchaserRetailerType({required this.code, required this.description});
  factory PurchaserRetailerType.fromJson(Map<String, dynamic> json) {
    return PurchaserRetailerType(
      code: json['code'] ?? json['Code'],
      description: json['description'] ?? json['Description'],
    );
  }
}

class AreaCodeModel {
  final String code;
  final String name;
  AreaCodeModel({required this.code, required this.name});
  factory AreaCodeModel.fromJson(Map<String, dynamic> json) {
    return AreaCodeModel(
      code: json['code'] ?? json['Code'],
      name: json['name'] ?? json['Name'],
    );
  }
}

// 3D Flip Card Widget
class FlipCard3D extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool showFront;
  final VoidCallback? onTap;
  
  const FlipCard3D({
    Key? key,
    required this.front,
    required this.back,
    this.showFront = true,
    this.onTap,
  }) : super(key: key);

  @override
  _FlipCard3DState createState() => _FlipCard3DState();
}

class _FlipCard3DState extends State<FlipCard3D>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(FlipCard3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showFront != widget.showFront) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.showFront) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isFront = _animation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(_animation.value * math.pi),
            child: isFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

class _DsrRetailerInOutState extends State<DsrRetailerInOut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  
  // State
  final String _purchaserRetailerItem = 'Select';
  AreaCodeModel? _selectedAreaCode;
  DateTime? _selectedDate;
  
  // Controllers
  final _dateController            = TextEditingController();
  final _yourLatitudeController    = TextEditingController();
  final _yourLongitudeController   = TextEditingController();
  final _custLatitudeController    = TextEditingController();
  final _custLongitudeController   = TextEditingController();
  final _codeSearchController      = TextEditingController();
  final _customerNameController    = TextEditingController();
  
  // Dropdown data
  PurchaserRetailerType? _selectedPurchaserRetailerType;
  List<PurchaserRetailerType> _purchaserRetailerTypes = [];
  bool _isLoadingPurchaserRetailerTypes = false;
  List<AreaCodeModel> _areaCodes = [];
  bool _isLoadingAreaCodes = false;
  final _formKey = GlobalKey<FormState>();
  final List<XFile?> _selectedImages = [null];
  final _picker = ImagePicker();
  
  // Colors - Using theme constants
  final _primaryColor    = SparshTheme.primaryBlueAccent;
  final _secondaryColor  = SparshTheme.primaryBlueLight;
  final _backgroundColor = SparshTheme.scaffoldBackground;
  final _cardColor       = SparshTheme.cardBackground;
  final _textColor       = SparshTheme.textPrimary;
  final _hintColor       = SparshTheme.textSecondary;
  
  List<String> _codeSearchList = [];
  String? _selectedCodeSearch;
  bool _isLoadingCodeSearch = false;
  double _calculatedDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController, curve: Curves.easeOut,
    );
    _animationController.forward();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    _fetchPurchaserRetailerTypes();
    _fetchAreaCodes();
    _captureYourLocation();
    _yourLatitudeController.addListener(_calculateDistance);
    _yourLongitudeController.addListener(_calculateDistance);
    _custLatitudeController.addListener(_calculateDistance);
    _custLongitudeController.addListener(_calculateDistance);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dateController.dispose();
    _yourLatitudeController.removeListener(_calculateDistance);
    _yourLongitudeController.removeListener(_calculateDistance);
    _custLatitudeController.removeListener(_calculateDistance);
    _custLongitudeController.removeListener(_calculateDistance);
    _yourLatitudeController.dispose();
    _yourLongitudeController.dispose();
    _custLatitudeController.dispose();
    _custLongitudeController.dispose();
    _codeSearchController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location services are disabled.';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied.';
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _updateYourLocation(String lat, String lon) {
    _yourLatitudeController.text = lat;
    _yourLongitudeController.text = lon;
    _calculateDistance();
  }

  void _updateCustomerLocation(String lat, String lon) {
    _custLatitudeController.text = lat;
    _custLongitudeController.text = lon;
    _calculateDistance();
  }

  Future<void> _captureYourLocation() async {
    try {
      final pos = await _determinePosition();
      _updateYourLocation(pos.latitude.toStringAsFixed(6), pos.longitude.toStringAsFixed(6));
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _captureCustomerLocation() async {
    try {
      final pos = await _determinePosition();
      _updateCustomerLocation(pos.latitude.toStringAsFixed(6), pos.longitude.toStringAsFixed(6));
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    _show3DDialog(
      title: 'Error',
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: threeDaysAgo,
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: SparshTheme.primaryBlueAccent,
            onPrimary: Colors.white,
            onSurface: SparshTheme.textPrimary,
          ),
          dialogTheme: const DialogThemeData(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _calculateDistance() {
    try {
      final userLat = double.tryParse(_yourLatitudeController.text) ?? 0.0;
      final userLon = double.tryParse(_yourLongitudeController.text) ?? 0.0;
      final custLat = double.tryParse(_custLatitudeController.text) ?? 0.0;
      final custLon = double.tryParse(_custLongitudeController.text) ?? 0.0;
      if (userLat != 0.0 && userLon != 0.0 && custLat != 0.0 && custLon != 0.0) {
        final distance = _calculateDistanceInMeters(userLat, userLon, custLat, custLon);
        setState(() {
          _calculatedDistance = distance;
        });
      }
    } catch (e) {
      print('Error calculating distance: $e');
    }
  }

  double _calculateDistanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    const double pi = math.pi;
    var radlat1 = pi * lat1 / 180;
    var radlat2 = pi * lat2 / 180;
    var theta = lon1 - lon2;
    var radtheta = pi * theta / 180;
    var dist = math.sin(radlat1) * math.sin(radlat2) +
               math.cos(radlat1) * math.cos(radlat2) * math.cos(radtheta);
    if (dist > 1) dist = 1;
    dist = math.acos(dist);
    dist = dist * 180 / pi;
    dist = dist * 60 * 1.1515;
    dist = dist * 1.609344 * 1000;
    return dist;
  }

  void _show3DDialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
    IconData? icon,
    Color? iconColor,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutBack,
        );
        
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..scale(curvedAnimation.value)
            ..rotateY(curvedAnimation.value * 0.5),
          child: Opacity(
            opacity: curvedAnimation.value,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SparshBorderRadius.xl),
          ),
          title: Row(
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: iconColor ?? _primaryColor,
                  size: SparshSpacing.lg,
                ),
              if (icon != null) const SizedBox(width: SparshSpacing.sm),
              Text(
                title,
                style: SparshTypography.heading5.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: content,
          actions: actions,
        );
      },
    );
  }

  void _showDistanceWarningDialog() {
    _show3DDialog(
      icon: Icons.warning_amber_rounded,
      iconColor: SparshTheme.warningOrange,
      title: 'Distance Warning',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are currently ${_calculatedDistance.toStringAsFixed(2)} meters away from the customer location.',
            style: SparshTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: SparshSpacing.sm),
          Container(
            padding: const EdgeInsets.all(SparshSpacing.md),
            decoration: BoxDecoration(
              color: SparshTheme.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(SparshBorderRadius.lg),
              border: Border.all(color: SparshTheme.warningOrange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: SparshTheme.warningOrange,
                  size: SparshSpacing.lg,
                ),
                const SizedBox(width: SparshSpacing.sm),
                Expanded(
                  child: Text(
                    'Please visit within 100 meters radius of the shop to proceed with IN entry.',
                    style: SparshTypography.bodyLarge.copyWith(
                      color: SparshTheme.warningOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SparshSpacing.sm),
          Text(
            'Current distance: ${_calculatedDistance.toStringAsFixed(2)} meters',
            style: SparshTypography.bodyMedium.copyWith(
              color: SparshTheme.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Required distance: ≤ 100 meters',
            style: SparshTypography.bodyMedium.copyWith(
              color: SparshTheme.successGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK, I Understand', style: SparshTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showExceptionEntryDialog() {
    _show3DDialog(
      icon: Icons.info_outline,
      iconColor: SparshTheme.primaryBlue,
      title: 'Exception Entry',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are currently ${_calculatedDistance.toStringAsFixed(2)} meters away from the customer location.',
            style: SparshTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: SparshSpacing.sm),
          Container(
            padding: const EdgeInsets.all(SparshSpacing.md),
            decoration: BoxDecoration(
              color: SparshTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(SparshBorderRadius.lg),
              border: Border.all(color: SparshTheme.primaryBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.navigation,
                  color: SparshTheme.primaryBlue,
                  size: SparshSpacing.lg,
                ),
                const SizedBox(width: SparshSpacing.sm),
                Expanded(
                  child: Text(
                    'Since you are outside the 100-meter radius, you will be redirected to the DSR Visit Screen for exception entry.',
                    style: SparshTypography.bodyLarge.copyWith(
                      color: SparshTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SparshSpacing.sm),
          Text(
            'Current distance: ${_calculatedDistance.toStringAsFixed(2)} meters',
            style: SparshTypography.bodyMedium.copyWith(
              color: SparshTheme.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Required distance: ≤ 100 meters',
            style: SparshTypography.bodyMedium.copyWith(
              color: SparshTheme.successGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK, I Understand', style: SparshTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DsrVisitScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: SparshTheme.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SparshBorderRadius.lg),
            ),
          ),
          child: Text('OK, I Understand', style: SparshTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _onSubmit(String entryType) {
    print('Submit pressed: $entryType, distance: $_calculatedDistance');
    if (!_formKey.currentState!.validate()) return;
    
    if (entryType == 'IN' && _calculatedDistance > 101) {
      print('Showing distance warning dialog');
      _showDistanceWarningDialog();
      return;
    }
    
    if (entryType == 'Exception' && _calculatedDistance > 101) {
      print('Showing exception entry dialog');
      _showExceptionEntryDialog();
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Form validated. Entry type: $entryType'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child, bool isFlippable = false, Widget? backContent}) {
    final cardContent = Card(
      color: _cardColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.all(SparshSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: SparshTypography.heading5.copyWith(color: _textColor)),
                ),
                if (isFlippable)
                  Icon(Icons.flip, color: _primaryColor, size: 20),
              ],
            ),
            const SizedBox(height: SparshSpacing.md),
            child,
          ],
        ),
      ),
    );

    if (isFlippable && backContent != null) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool showFront = true;
          return FlipCard3D(
            front: cardContent,
            back: Card(
              color: _cardColor,
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.xl)),
              child: Padding(
                padding: const EdgeInsets.all(SparshSpacing.lg),
                child: backContent,
              ),
            ),
            showFront: showFront,
            onTap: () => setState(() => showFront = !showFront),
          );
        },
      );
    }

    return cardContent;
  }

  InputDecoration _inputDecoration3D({String? hintText, String? labelText}) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      hintStyle: TextStyle(color: _hintColor),
      labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
      filled: true,
      fillColor: _cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SparshBorderRadius.lg),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SparshBorderRadius.lg),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SparshBorderRadius.lg),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
    );
  }

  Widget _build3DButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool _isPressed = false;
        
        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..scale(_isPressed ? 0.95 : 1.0)
              ..translate(0.0, _isPressed ? 2.0 : 0.0),
            child: ElevatedButton.icon(
              icon: icon != null ? Icon(icon, size: SparshSpacing.lg) : null,
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: SparshSpacing.md),
                child: Text(
                  label,
                  style: SparshTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SparshBorderRadius.lg),
                ),
                elevation: _isPressed ? 2 : 6,
                padding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _build3DDistanceCard() {
    return StatefulBuilder(
      builder: (context, setState) {
        double _tiltX = 0;
        double _tiltY = 0;
        
        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _tiltX = details.delta.dy * 0.01;
              _tiltY = details.delta.dx * 0.01;
            });
          },
          onPanEnd: (_) {
            setState(() {
              _tiltX = 0;
              _tiltY = 0;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_tiltX)
                ..rotateY(_tiltY),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(SparshSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _calculatedDistance > 0 
                      ? (_calculatedDistance > 101 
                        ? [SparshTheme.errorRed.withOpacity(0.08), SparshTheme.errorRed.withOpacity(0.03)]
                        : [SparshTheme.successGreen.withOpacity(0.08), SparshTheme.successGreen.withOpacity(0.03)])
                      : [SparshTheme.textTertiary.withOpacity(0.08), SparshTheme.textTertiary.withOpacity(0.03)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(SparshBorderRadius.xl),
                  border: Border.all(
                    color: _calculatedDistance > 0 
                      ? (_calculatedDistance > 101 ? SparshTheme.errorRed.withOpacity(0.2) : SparshTheme.successGreen.withOpacity(0.2))
                      : SparshTheme.textTertiary.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_calculatedDistance > 0 
                        ? (_calculatedDistance > 101 ? SparshTheme.errorRed : SparshTheme.successGreen)
                        : SparshTheme.textTertiary).withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: (_calculatedDistance > 0 
                        ? (_calculatedDistance > 101 ? SparshTheme.errorRed : SparshTheme.successGreen)
                        : SparshTheme.textTertiary).withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_calculatedDistance == 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.calculate, color: SparshTheme.primaryBlueAccent, size: SparshSpacing.lg),
                          onPressed: _calculateDistance,
                          tooltip: 'Calculate distance manually',
                        ),
                      ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(SparshSpacing.md),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _calculatedDistance > 0 
                                ? (_calculatedDistance > 101 
                                  ? [SparshTheme.errorRed.withOpacity(0.1), SparshTheme.errorRed.withOpacity(0.05)]
                                  : [SparshTheme.successGreen.withOpacity(0.1), SparshTheme.successGreen.withOpacity(0.05)])
                                : [SparshTheme.textTertiary.withOpacity(0.1), SparshTheme.textTertiary.withOpacity(0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(SparshBorderRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: (_calculatedDistance > 0 
                                  ? (_calculatedDistance > 101 ? SparshTheme.errorRed : SparshTheme.successGreen)
                                  : SparshTheme.textTertiary).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.straighten,
                            color: _calculatedDistance > 0 
                              ? (_calculatedDistance > 101 ? SparshTheme.errorRed : SparshTheme.successGreen)
                              : SparshTheme.textTertiary,
                            size: SparshSpacing.xl,
                          ),
                        ),
                        const SizedBox(width: SparshSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _calculatedDistance > 0 
                                  ? '${_calculatedDistance.toStringAsFixed(2)} meters'
                                  : 'Not calculated',
                                style: SparshTypography.heading3.copyWith(
                                  color: _calculatedDistance > 0 
                                    ? (_calculatedDistance > 101 ? SparshTheme.errorRed : SparshTheme.successGreen)
                                    : SparshTheme.textTertiary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  height: 1.2,
                                ),
                              ),
                              if (_calculatedDistance > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: SparshSpacing.sm),
                                  padding: const EdgeInsets.symmetric(horizontal: SparshSpacing.md, vertical: SparshSpacing.sm),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: (_calculatedDistance > 101 
                                        ? [SparshTheme.errorRed.withOpacity(0.1), SparshTheme.errorRed.withOpacity(0.05)]
                                        : [SparshTheme.successGreen.withOpacity(0.1), SparshTheme.successGreen.withOpacity(0.05)]),
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(SparshBorderRadius.lg),
                                    border: Border.all(
                                      color: (_calculatedDistance > 101 ? SparshTheme.errorRed : SparshTheme.successGreen).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _calculatedDistance > 101 
                                      ? 'Distance exceeds 101m limit'
                                      : 'Within acceptable range',
                                    style: SparshTypography.bodySmall.copyWith(
                                      color: _calculatedDistance > 101 ? SparshTheme.errorRed : SparshTheme.successGreen,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              if (_calculatedDistance == 0)
                                Container(
                                  margin: const EdgeInsets.only(top: SparshSpacing.sm),
                                  padding: const EdgeInsets.symmetric(horizontal: SparshSpacing.md, vertical: SparshSpacing.sm),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [SparshTheme.textTertiary.withOpacity(0.1), SparshTheme.textTertiary.withOpacity(0.05)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(SparshBorderRadius.lg),
                                    border: Border.all(
                                      color: SparshTheme.textTertiary.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Required distance: ≤ 100 meters',
                                    style: SparshTypography.bodyMedium.copyWith(
                                      color: SparshTheme.textTertiary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildElevatedButton(
      {required IconData icon, required String label, required VoidCallback onPressed}) {
    return _build3DButton(
      icon: icon,
      label: label,
      onPressed: onPressed,
      color: _secondaryColor,
    );
  }

  Widget _buildActionButton(
      {required String label, required Color color, required VoidCallback onPressed}) {
    return _build3DButton(
      label: label,
      onPressed: onPressed,
      color: color,
    );
  }

  Widget _buildImageRow(int idx) {
    final file = _selectedImages[idx];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Document ${idx + 1}',
            style: SparshTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: SparshSpacing.sm),
        Row(
          children: [
            _build3DButton(
              icon: file != null ? Icons.refresh : Icons.upload_file,
              label: file != null ? 'Replace' : 'Upload',
              onPressed: () async {
                final img = await _picker.pickImage(source: ImageSource.gallery);
                if (img != null) setState(() => _selectedImages[idx] = img);
              },
              color: _primaryColor,
            ),
            const SizedBox(width: SparshSpacing.sm),
            if (file != null)
              _build3DButton(
                icon: Icons.visibility,
                label: 'View',
                onPressed: () => _showImage(file),
                color: _secondaryColor,
              ),
            const Spacer(),
            if (_selectedImages.length > 1 && idx == _selectedImages.length - 1)
              IconButton(
                icon: const Icon(Icons.remove_circle, color: SparshTheme.errorRed),
                onPressed: () => setState(() => _selectedImages.removeLast()),
              ),
          ],
        ),
        const SizedBox(height: SparshSpacing.sm),
      ],
    );
  }

  void _showImage(XFile file) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutBack,
        );
        
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..scale(curvedAnimation.value)
            ..rotateY(curvedAnimation.value * 0.3),
          child: Opacity(
            opacity: curvedAnimation.value,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Dialog(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SparshBorderRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SparshBorderRadius.xl),
              child: Image.file(
                File(file.path),
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.6,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchPurchaserRetailerTypes() async {
    setState(() => _isLoadingPurchaserRetailerTypes = true);
    try {
      final response = await http.get(Uri.parse('http://192.168.36.25/api/PersonalVisit/getPurchaserRetailerTypes'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _purchaserRetailerTypes = data.map((e) => PurchaserRetailerType.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // Optionally show error
    } finally {
      setState(() => _isLoadingPurchaserRetailerTypes = false);
    }
  }

  Future<void> _fetchAreaCodes() async {
    setState(() => _isLoadingAreaCodes = true);
    try {
      final response = await http.get(Uri.parse('http://192.168.36.25/api/PersonalVisit/getAreaCodes'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _areaCodes = data.map((e) => AreaCodeModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // Optionally show error
    } finally {
      setState(() => _isLoadingAreaCodes = false);
    }
  }

  void _onAreaOrPurchaserRetailerChanged() {
    if (_selectedAreaCode != null && _selectedPurchaserRetailerType != null) {
      _fetchCodeSearch();
    } else {
      setState(() {
        _codeSearchList = [];
        _selectedCodeSearch = null;
      });
    }
  }

  Future<void> _fetchCodeSearch() async {
    setState(() {
      _isLoadingCodeSearch = true;
      _codeSearchList = [];
      _selectedCodeSearch = null;
    });
    try {
      final areaCode = _selectedAreaCode?.code;
      final purchaserRetailerType = _selectedPurchaserRetailerType?.code;
      if (areaCode == null || purchaserRetailerType == null) return;
      final url = 'http://192.168.36.25/api/PersonalVisit/getCodeSearch?areaCode=$areaCode&purchaserRetailerType=$purchaserRetailerType';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _codeSearchList = data.map((e) => e.toString()).toList();
        });
      }
    } catch (e) {
      // Optionally show error
    } finally {
      setState(() => _isLoadingCodeSearch = false);
    }
  }

  Future<void> _fetchCustomerDetails(String code) async {
    try {
      final url = 'http://192.168.36.25/api/PersonalVisit/fetchRetailerDetails?cusRtlCd=$code';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final details = data[0];
          setState(() {
            _customerNameController.text = details['retlName']?.toString() ?? details['custName']?.toString() ?? '';
            _custLatitudeController.text = details['latitute']?.toString() ?? '';
            _custLongitudeController.text = details['lgtitute']?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      // Optionally show error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DSR Retailer IN OUT',
                style: SparshTypography.heading5.copyWith(color: Colors.white)),
            Text('Daily Sales Report Entry',
                style: SparshTypography.body.copyWith(color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Help information for DSR Retailer IN OUT'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.md)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SparshSpacing.lg),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildCard(
                  title: 'Purchaser / Retailer',
                  child: _isLoadingPurchaserRetailerTypes
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownSearch<PurchaserRetailerType>(
                          selectedItem: _selectedPurchaserRetailerType,
                          items: _purchaserRetailerTypes,
                          itemAsString: (type) => type == null ? '' : type.description,
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: _inputDecoration3D(),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: _inputDecoration3D(hintText: 'Search Purchaser/Retailer'),
                            ),
                          ),
                          onChanged: (v) {
                            setState(() => _selectedPurchaserRetailerType = v);
                            _onAreaOrPurchaserRetailerChanged();
                          },
                          validator: (v) => (v == null) ? 'Required' : null,
                        ),
                ),
                _buildCard(
                  title: 'Area Code',
                  child: _isLoadingAreaCodes
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownSearch<AreaCodeModel>(
                          selectedItem: _selectedAreaCode,
                          items: _areaCodes,
                          itemAsString: (area) => area == null ? '' : '${area.code}-${area.name}',
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: _inputDecoration3D(),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: _inputDecoration3D(hintText: 'Search Area Code'),
                            ),
                          ),
                          onChanged: (v) {
                            setState(() => _selectedAreaCode = v);
                            _onAreaOrPurchaserRetailerChanged();
                          },
                          validator: (v) => (v == null) ? 'Required' : null,
                        ),
                ),
                _buildCard(
                  title: 'Code Search',
                  child: _isLoadingCodeSearch
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownSearch<String>(
                          selectedItem: _selectedCodeSearch,
                          items: _codeSearchList,
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: _inputDecoration3D(hintText: 'Select Code'),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: _inputDecoration3D(hintText: 'Search Code'),
                            ),
                          ),
                          onChanged: (_codeSearchList.isEmpty)
                              ? null
                              : (v) {
                                  setState(() => _selectedCodeSearch = v);
                                  if (v != null && v.isNotEmpty) {
                                    _fetchCustomerDetails(v);
                                  }
                                },
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                ),
                _buildCard(
                  title: 'Customer Details',
                  isFlippable: true,
                  backContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Information',
                        style: SparshTypography.heading5.copyWith(color: _textColor),
                      ),
                      const SizedBox(height: SparshSpacing.md),
                      Text(
                        'This section contains customer details that can be expanded with additional information such as contact details, visit history, or special notes.',
                        style: SparshTypography.bodyMedium.copyWith(color: _textColor),
                      ),
                      const SizedBox(height: SparshSpacing.md),
                      _build3DButton(
                        icon: Icons.history,
                        label: 'View Visit History',
                        onPressed: () {
                          // Add visit history functionality
                        },
                        color: _secondaryColor,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _customerNameController,
                    decoration: _inputDecoration3D(hintText: 'Customer Name'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                _buildCard(
                  title: 'Date',
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: _inputDecoration3D(hintText: 'Select Date').copyWith(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, color: SparshTheme.primaryBlueAccent),
                        onPressed: _pickDate,
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                _buildCard(
                  title: 'Your Location',
                  isFlippable: true,
                  backContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Details',
                        style: SparshTypography.heading5.copyWith(color: _textColor),
                      ),
                      const SizedBox(height: SparshSpacing.md),
                      Text(
                        'Your current location coordinates are captured automatically. Tap refresh to update your position.',
                        style: SparshTypography.bodyMedium.copyWith(color: _textColor),
                      ),
                      const SizedBox(height: SparshSpacing.md),
                      _build3DButton(
                        icon: Icons.refresh,
                        label: 'Refresh Location',
                        onPressed: _captureYourLocation,
                        color: _primaryColor,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _yourLatitudeController,
                        readOnly: true,
                        decoration: _inputDecoration3D(labelText: 'Latitude'),
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: _yourLongitudeController,
                        readOnly: true,
                        decoration: _inputDecoration3D(labelText: 'Longitude'),
                      ),
                    ],
                  ),
                ),
                _buildCard(
                  title: 'Customer Location',
                  isFlippable: true,
                  backContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Location Info',
                        style: SparshTypography.heading5.copyWith(color: _textColor),
                      ),
                      const SizedBox(height: SparshSpacing.md),
                      Text(
                        'Customer location coordinates are fetched from the database. You can also capture current location if visiting the customer.',
                        style: SparshTypography.bodyMedium.copyWith(color: _textColor),
                      ),
                      const SizedBox(height: SparshSpacing.md),
                      _build3DButton(
                        icon: Icons.my_location,
                        label: 'Capture Current Location',
                        onPressed: _captureCustomerLocation,
                        color: _secondaryColor,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _custLatitudeController,
                        readOnly: true,
                        decoration: _inputDecoration3D(labelText: 'Latitude'),
                      ),
                      const SizedBox(height: SparshSpacing.sm),
                      TextFormField(
                        controller: _custLongitudeController,
                        readOnly: true,
                        decoration: _inputDecoration3D(labelText: 'Longitude'),
                      ),
                    ],
                  ),
                ),
                _buildCard(
                  title: 'Distance',
                  child: _build3DDistanceCard(),
                ),
                const SizedBox(height: SparshSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: _build3DButton(
                    icon: Icons.login,
                    label: 'IN',
                    onPressed: () => _onSubmit('IN'),
                    color: SparshTheme.primaryBlueAccent,
                  ),
                ),
                const SizedBox(height: SparshSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: _build3DButton(
                    icon: Icons.error_outline,
                    label: 'Exception Entry',
                    onPressed: () => _onSubmit('Exception'),
                    color: SparshTheme.warningOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}