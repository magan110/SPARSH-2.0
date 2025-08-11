import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Booking',
      theme: SparshTheme.lightTheme,
      home: const MovieBooking(),
    );
  }
}

class MovieBooking extends StatefulWidget {
  const MovieBooking({super.key});

  @override
  State<MovieBooking> createState() => _MovieBookingState();
}

class _MovieBookingState extends State<MovieBooking> {
  final TextEditingController _employeeCodeController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();

  String? _selectedShowTime;
  String? _selectedPersonalOfficial;
  final Set<int> _selectedSeats = {};
  final Set<int> _bookedSeats = {};

  @override
  void dispose() {
    _employeeCodeController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SparshSpacing.lg),
      child: Row(
        children: [
          Icon(icon, color: SparshTheme.infoBlue),
          const SizedBox(width: SparshSpacing.sm),
          Text(
            title,
            style: SparshTypography.heading2,
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SparshSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SparshBorderRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(SparshBorderRadius.xl),
              boxShadow: SparshShadows.md,
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: SparshTypography.body,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: SparshSpacing.xl, vertical: SparshSpacing.md),
                hintText: hintText,
                hintStyle: const TextStyle(color: SparshTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SparshBorderRadius.xl),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String hintText,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SparshSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: SparshSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SparshBorderRadius.xl),
          boxShadow: SparshShadows.card,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            hint: Text(
              hintText,
              style: SparshTypography.body.copyWith(fontSize: 18),
            ),
            icon: const Icon(Icons.keyboard_arrow_down),
            isExpanded: true,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item, style: SparshTypography.body),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildSeat(int seatNumber) {
    Color seatColor;
    if (_bookedSeats.contains(seatNumber)) {
      seatColor = SparshTheme.seatBooked;
    } else if (_selectedSeats.contains(seatNumber)) {
      seatColor = SparshTheme.seatSelected;
    } else {
      seatColor = SparshTheme.seatAvailable;
    }

    return GestureDetector(
      onTap: () {
        if (_bookedSeats.contains(seatNumber)) return;
        setState(() {
          _selectedSeats.contains(seatNumber)
              ? _selectedSeats.remove(seatNumber)
              : _selectedSeats.add(seatNumber);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: seatColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Center(
          child: Text(
            seatNumber.toString(),
            style: SparshTypography.bodyBold.copyWith(fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatRow(int startSeat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First 2 seats
          _buildSeat(startSeat),
          const SizedBox(width: 4),
          _buildSeat(startSeat + 1),
          const SizedBox(width: SparshSpacing.sm),
          // Middle 4 seats
          _buildSeat(startSeat + 2),
          const SizedBox(width: 4),
          _buildSeat(startSeat + 3),
          const SizedBox(width: 4),
          _buildSeat(startSeat + 4),
          const SizedBox(width: 4),
          _buildSeat(startSeat + 5),
          const SizedBox(width: SparshSpacing.sm),
          // Last 2 seats
          _buildSeat(startSeat + 6),
          const SizedBox(width: 4),
          _buildSeat(startSeat + 7),
        ],
      ),
    );
  }

  Widget _buildSeatLayout() {
    return Column(
      children: [
        for (int i = 0; i < 6; i++) _buildSeatRow(i * 8 + 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Movie Booking',
          style: SparshTypography.heading2.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: SparshTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [SparshTheme.scaffoldBackground, SparshTheme.lightBlueBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: SparshSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: SparshSpacing.sm),
                _buildSectionTitle("Select Show Time and Movie", Icons.schedule),
                const SizedBox(height: SparshSpacing.sm),
                _buildStyledDropdown(
                  hintText: "Select Show Time & Movie",
                  items: ['10:00 AM - Movie A', '02:00 PM - Movie B', '06:00 PM - Movie C'],
                  selectedValue: _selectedShowTime,
                  onChanged: (value) => setState(() => _selectedShowTime = value),
                ),
                const SizedBox(height: SparshSpacing.xl),
                _buildSectionTitle("Personal / Official Guest", Icons.person_pin),
                const SizedBox(height: SparshSpacing.sm),
                _buildStyledDropdown(
                  hintText: "Personal / Official",
                  items: ['Personal', 'Official'],
                  selectedValue: _selectedPersonalOfficial,
                  onChanged: (value) => setState(() => _selectedPersonalOfficial = value),
                ),
                const SizedBox(height: SparshSpacing.xl),
                _buildSectionTitle("Employee Code", Icons.badge),
                const SizedBox(height: SparshSpacing.sm),
                _buildStyledTextField(
                  controller: _employeeCodeController,
                  hintText: 'Enter Employee Code',
                ),
                const SizedBox(height: SparshSpacing.xl),
                _buildSectionTitle("Mobile No (Entry Pass SMS)", Icons.phone),
                const SizedBox(height: SparshSpacing.sm),
                _buildStyledTextField(
                  controller: _mobileNumberController,
                  hintText: 'Enter Mobile Number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: SparshSpacing.lg),
                _buildSectionTitle("Select Seats", Icons.event_seat),
                _buildSeatLayout(),
                const SizedBox(height: SparshSpacing.lg),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedSeats.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select at least one seat')),
                        );
                        return;
                      }
                      setState(() {
                        _bookedSeats.addAll(_selectedSeats);
                        _selectedSeats.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Entry Pass(es) booked successfully!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SparshTheme.infoBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: SparshSpacing.xl, vertical: SparshSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.xl)),
                      elevation: 10,
                      shadowColor: SparshTheme.borderDarkGrey.withOpacity(0.3),
                    ),
                    child: const Text('🎟 Book Entry Pass', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: SparshSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}