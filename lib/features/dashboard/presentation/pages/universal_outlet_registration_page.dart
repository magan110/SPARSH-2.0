// File: lib/universal_outlet_registration.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class UniversalOutletRegistrationPage extends StatefulWidget {
  const UniversalOutletRegistrationPage({super.key});
  @override
  State<UniversalOutletRegistrationPage> createState() =>
      _UniversalOutletRegistrationPageState();
}

class _UniversalOutletRegistrationPageState
    extends State<UniversalOutletRegistrationPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Controllers for text fields
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _address3Controller = TextEditingController();
  final TextEditingController _concernEmployeeController =
      TextEditingController(text: 'undefined');
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _alternateMobileController =
      TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _retailerNameController = TextEditingController();
  final TextEditingController _marketNameController = TextEditingController();
  final TextEditingController _whiteCementController = TextEditingController();
  final TextEditingController _wallCareController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();

  // Dropdown selections
  String? _selectedArea;
  String? _selectedDistrict;
  String? _selectedCity;
  String? _selectedPinCode;
  String? _selectedPaintNonPaint;
  final List<String> _selectedPaintNonPaintDetails = [];

  // Toggle for address mode: 'geo' or 'pin'
  String _addressMode = 'geo';

  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Dropdown lists
  final List<String> _areas = ['Select', 'Area A', 'Area B', 'Area C'];
  final List<String> _districts = ['select', 'District X', 'District Y'];
  final List<String> _cities = ['Select City', 'City 1', 'City 2'];
  final List<String> _pinCodes = ['-- Select Pin Code --', '400001', '400002'];
  final List<String> _paintNonPaintOptions = ['Paint', 'Non Paint'];
  final List<String> _paintNonPaintDetailsOptions = [
    'Detail 1',
    'Detail 2',
    'Detail 3',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    // Dispose all controllers
    _address1Controller.dispose();
    _address2Controller.dispose();
    _address3Controller.dispose();
    _concernEmployeeController.dispose();
    _mobileController.dispose();
    _alternateMobileController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _retailerNameController.dispose();
    _marketNameController.dispose();
    _whiteCementController.dispose();
    _wallCareController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }

  void _togglePaintNonPaintDetail(String detail) {
    setState(() {
      if (_selectedPaintNonPaintDetails.contains(detail)) {
        _selectedPaintNonPaintDetails.remove(detail);
      } else {
        _selectedPaintNonPaintDetails.add(detail);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Outlet Registration',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.store,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Register New Outlet',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please fill in the information below to register a new outlet',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Basic Information Section
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: 16),
                    _buildDropdownField('Area', _areas, _selectedArea, (value) {
                      setState(() => _selectedArea = value);
                    }),
                    const SizedBox(height: 16),
                    _buildAddressModeToggle(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Address Line 1',
                      controller: _address1Controller,
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Address Line 2',
                      controller: _address2Controller,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Address Line 3',
                      controller: _address3Controller,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Concern Employee',
                      controller: _concernEmployeeController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      'District',
                      _districts,
                      _selectedDistrict,
                      (value) {
                        setState(() => _selectedDistrict = value);
                      },
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    if (_addressMode == 'pin') ...[
                      _buildDropdownField(
                        'Pin Code',
                        _pinCodes,
                        _selectedPinCode,
                        (value) {
                          setState(() => _selectedPinCode = value);
                        },
                        validator: _validateRequired,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildDropdownField('City', _cities, _selectedCity, (
                      value,
                    ) {
                      setState() => _selectedCity = value;
                    }, validator: _validateRequired),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Mobile Number',
                      controller: _mobileController,
                      validator: _validateMobile,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Alternate Mobile',
                      controller: _alternateMobileController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),

                    // Business Details Section
                    _buildSectionTitle('Business Details'),
                    const SizedBox(height: 16),
                    _buildTextField('PAN Number', controller: _panController),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Retailer Name',
                      controller: _retailerNameController,
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Market Name',
                      controller: _marketNameController,
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'White Cement Potential (Monthly)',
                      controller: _whiteCementController,
                      validator: _validateRequired,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Wall Care Putty Potential (Monthly)',
                      controller: _wallCareController,
                      validator: _validateRequired,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildPaintNonPaintToggle(),
                    const SizedBox(height: 16),
                    _buildPaintNonPaintDetailsButton(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Contact Name',
                      controller: _contactNameController,
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    _buildImageUploadSection(),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Submit Registration',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedValue,
          validator: validator,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items:
              items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }

  Widget _buildAddressModeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address Capture Method',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _addressMode = 'geo'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _addressMode == 'geo' ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _addressMode == 'geo'
                              ? Colors.blue
                              : Colors.grey[300]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Geo Location',
                      style: TextStyle(
                        color:
                            _addressMode == 'geo'
                                ? Colors.white
                                : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _addressMode = 'pin'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _addressMode == 'pin' ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _addressMode == 'pin'
                              ? Colors.blue
                              : Colors.grey[300]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Pin Code',
                      style: TextStyle(
                        color:
                            _addressMode == 'pin'
                                ? Colors.white
                                : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaintNonPaintToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paint / Non-Paint Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children:
              _paintNonPaintOptions.map((option) {
                final bool isSelected = _selectedPaintNonPaint == option;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPaintNonPaint = option;
                          _selectedPaintNonPaintDetails.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaintNonPaintDetailsButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paint / Non-Paint Details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder:
                  (_) => Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Select Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._paintNonPaintDetailsOptions.map((detail) {
                          final bool checked = _selectedPaintNonPaintDetails
                              .contains(detail);
                          return CheckboxListTile(
                            title: Text(detail),
                            value: checked,
                            onChanged: (_) {
                              _togglePaintNonPaintDetail(detail);
                            },
                            activeColor: Colors.blue,
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedPaintNonPaintDetails.isEmpty
                      ? 'No details selected'
                      : '${_selectedPaintNonPaintDetails.length} selected',
                  style: TextStyle(
                    color:
                        _selectedPaintNonPaintDetails.isEmpty
                            ? Colors.grey[500]
                            : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Retailer Shop Image',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: implement image upload
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: const BorderSide(color: Colors.blue),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Upload Image',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: implement image view
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'View Image',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Validation functions
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    if (value.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    // Show success dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Registration Successful!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your outlet registration has been submitted successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Registration Help',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fill in all required fields marked with *. '
                    'For address capture, choose between Geo Location or Pin Code. '
                    'Upload a clear image of the retailer shop.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
