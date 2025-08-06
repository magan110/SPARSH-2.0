import 'package:flutter/material.dart';
import 'package:learning2/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Meeting_with_new_purchaser.dart';
import 'Meetings_With_Contractor.dart';
import 'any_other_activity.dart';
import 'btl_activites.dart';
import 'check_sampling_at_site.dart';
import 'dsr_retailer_in_out.dart';
import 'internal_team_meeting.dart';
import 'office_work.dart';
import 'on_leave.dart';
import 'phone_call_with_builder.dart';
import 'phone_call_with_unregisterd_purchaser.dart';
import 'work_from_home.dart';
import 'package:learning2/features/dashboard/presentation/pages/home_screen.dart';

class DsrEntry extends StatefulWidget {
  const DsrEntry({super.key});

  @override
  State<DsrEntry> createState() => _DsrEntryState();
}

class _DsrEntryState extends State<DsrEntry> with TickerProviderStateMixin {
  final List<String> _activityItems = [
    'Personal Visit',
    'Phone Call with Builder/Stockist',
    'Meetings With Contractor / Stockist',
    'Visit to Get / Check Sampling at Site',
    'Meeting with New Purchaser(Trade Purchaser)/Retailer',
    'BTL Activities',
    'Internal Team Meetings / Review Meetings',
    'Office Work',
    'On Leave / Holiday / Off Day',
    'Work From Home',
    'Any Other Activity',
    'Phone call with Unregistered Purchasers',
  ];

  String? _selectedActivity;
  final Map<String, IconData> _activityIcons = {
    'Personal Visit': Icons.person_pin_circle,
    'Phone Call with Builder/Stockist': Icons.phone_in_talk,
    'Meetings With Contractor / Stockist': Icons.groups,
    'Visit to Get / Check Sampling at Site': Icons.fact_check,
    'Meeting with New Purchaser(Trade Purchaser)/Retailer': Icons.handshake,
    'BTL Activities': Icons.campaign,
    'Internal Team Meetings / Review Meetings': Icons.people_outline,
    'Office Work': Icons.desktop_windows,
    'On Leave / Holiday / Off Day': Icons.beach_access,
    'Work From Home': Icons.home_work,
    'Any Other Activity': Icons.miscellaneous_services,
    'Phone call with Unregistered Purchasers': Icons.call,
  };

  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateTo(String label) {
    final map = {
      'Personal Visit': () => const DsrRetailerInOut(),
      'Phone Call with Builder/Stockist': () => const PhoneCallWithBuilder(),
      'Meetings With Contractor / Stockist': () => const MeetingsWithContractor(),
      'Visit to Get / Check Sampling at Site': () => const CheckSamplingAtSite(),
      'Meeting with New Purchaser(Trade Purchaser)/Retailer': () => const MeetingWithNewPurchaser(),
      'BTL Activities': () => const BtlActivities(),
      'Internal Team Meetings / Review Meetings': () => const InternalTeamMeeting(),
      'Office Work': () => const OfficeWork(),
      'On Leave / Holiday / Off Day': () => const OnLeave(),
      'Work From Home': () => const WorkFromHome(),
      'Any Other Activity': () => const AnyOtherActivity(),
      'Phone call with Unregistered Purchasers': () => const PhoneCallWithUnregisterdPurchaser(),
    };
    final builder = map[label];
    if (builder != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: builder()),
        ),
      );
    }
  }

  Widget _buildActivityList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activityItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final label = _activityItems[i];
        final selected = _selectedActivity == label;
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - _animation.value) * 50),
              child: Opacity(
                opacity: _animation.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedActivity = label);
              _navigateTo(label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selected 
                    ? [SparshTheme.primaryBlueAccent, const Color(0xFF1976D2)]
                    : [SparshTheme.cardBackground, const Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: selected 
                      ? SparshTheme.primaryBlueAccent.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.1),
                    blurRadius: selected ? 15 : 10,
                    offset: selected ? const Offset(0, 8) : const Offset(0, 4),
                    spreadRadius: selected ? 1 : 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 10,
                    offset: const Offset(-2, -2),
                  ),
                ],
                border: Border.all(
                  color: selected ? Colors.transparent : SparshTheme.borderGrey,
                  width: selected ? 0 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: selected 
                          ? [Colors.white, const Color(0xFFE3F2FD)]
                          : [SparshTheme.primaryBlueAccent.withValues(alpha: 0.1), SparshTheme.primaryBlueAccent.withValues(alpha: 0.2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _activityIcons[label] ?? Icons.assignment,
                      size: 28,
                      color: selected ? SparshTheme.primaryBlueAccent : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : SparshTheme.primaryBlueAccent,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: SparshTheme.primaryBlueAccent,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> submitDsrEntry(Map<String, dynamic> dsrData) async {
    final url = Uri.parse('http://192.168.36.25/api/DsrTry');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dsrData),
    );
    if (response.statusCode == 201) {
      debugPrint('✅ Data inserted successfully!');
    } else {
      debugPrint('❌ Data NOT inserted! Error: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions container with 3D effect
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [SparshTheme.primaryBlueAccent, const Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: SparshTheme.primaryBlueAccent.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 10,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Text('Instructions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fill in the details below to submit your daily sales report.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Activity list with 3D cards
            Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 10,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 16),
                      child: Text('Activity Type',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: SparshTheme.textPrimary,
                          )),
                    ),
                    _buildActivityList(),
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