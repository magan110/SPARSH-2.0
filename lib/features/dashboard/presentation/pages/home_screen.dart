// File: lib/screens/home_screen.dart
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:learning2/features/dashboard/presentation/pages/notification_screen.dart';
import 'package:learning2/features/dashboard/presentation/pages/profile_screen.dart';
import 'package:learning2/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:learning2/features/dashboard/presentation/pages/schema.dart';
import 'package:learning2/features/dashboard/presentation/pages/token_scan.dart';
import 'package:learning2/features/dsr_entry/presentation/pages/dsr_entry.dart';
import 'accounts_statement_page.dart';
import 'activity_summary_page.dart';
import 'package:learning2/features/dashboard/presentation/pages/employee_dashboard_page.dart';
import 'package:learning2/features/dashboard/presentation/widgets/app_drawer.dart';
import 'package:learning2/routes/navigation_registry.dart';
import 'grc_lead_entry_page.dart';
import 'painter_kyc_tracking_page.dart';
import 'retailer_registration_page.dart';
import 'scheme_document_page.dart';
import 'universal_outlet_registration_page.dart';
import 'mail_screen.dart';
import 'package:learning2/core/constants/fonts.dart';
import 'package:learning2/core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  // List of searchable items
  List<_SearchItem> get _searchItems =>
      appRoutes
          .map((route) => _SearchItem(route.title, route.type, route.builder))
          .toList();
  List<_SearchItem> _filteredSearchItems = [];
  // Main screens
  final List<Widget> _screens = [
    const HomeContent(),
    const DashboardScreen(),
    const MailScreen(),
    const ProfilePage(),
  ];
  Widget _currentScreen = const HomeContent();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateCurrentScreen(int index, {Widget? screen}) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
        _currentScreen = screen ?? _screens[index];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          _updateCurrentScreen(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildModernAppBar(),
        drawer: const AppDrawer(),
        body: Stack(
          children: [_currentScreen, _buildModernSearchOverlay(context)],
        ),
        bottomNavigationBar: _buildModernBottomNav(),
      ),
    );
  }

  /// Modern AppBar with clean design
  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.blue.shade700, size: 22),
                const SizedBox(width: 6),
                Text(
                  'SPARSH',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.grey.shade700),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                size: 24,
                color: Colors.grey.shade700,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.search, size: 24, color: Colors.grey.shade700),
          onPressed: () {
            setState(() {
              _isSearchVisible = true;
            });
          },
        ),
      ],
    );
  }

  /// Modern search overlay with glassmorphism effect
  Widget _buildModernSearchOverlay(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isSearchVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Visibility(
        visible: _isSearchVisible,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.4),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade500),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search reports, screens...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _filteredSearchItems =
                                  value.isEmpty
                                      ? []
                                      : _searchItems
                                          .where(
                                            (item) =>
                                                item.title
                                                    .toLowerCase()
                                                    .contains(
                                                      value.toLowerCase(),
                                                    ) ||
                                                item.type
                                                    .toLowerCase()
                                                    .contains(
                                                      value.toLowerCase(),
                                                    ),
                                          )
                                          .toList();
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade500),
                        onPressed: () {
                          setState(() {
                            _isSearchVisible = false;
                            _searchController.clear();
                            _filteredSearchItems = [];
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (_filteredSearchItems.isNotEmpty)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredSearchItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredSearchItems[index];
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            title: Text(item.title),
                            subtitle: Text(item.type),
                            onTap: () {
                              setState(() {
                                _isSearchVisible = false;
                                _searchController.clear();
                                _filteredSearchItems = [];
                              });
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => item.builder(ctx),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Modern bottom navigation with pill-shaped design
  Widget _buildModernBottomNav() {
    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            Icons.home_outlined,
            Icons.home,
            "Home",
            0,
            Colors.blue,
          ),
          _buildNavItem(
            Icons.dashboard_outlined,
            Icons.dashboard,
            "Dashboard",
            1,
            Colors.purple,
          ),
          _buildScanButton(),
          _buildNavItem(
            Icons.add_task, // Changed from description to add_task
            Icons.add_task, // Changed from description to add_task
            "DSR", // Changed from Scheme to DSR
            3,
            Colors.purple, // Changed from orange to purple
          ),
          _buildNavItem(
            Icons.person_outline,
            Icons.person,
            "Profile",
            4,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
    Color color,
  ) {
    final isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 3) {
            _updateCurrentScreen(
              index,
              screen: const DsrEntry(),
            ); // Changed from Schema to DsrEntry
          } else if (index == 4) {
            _updateCurrentScreen(index, screen: const ProfilePage());
          } else {
            _updateCurrentScreen(index);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? color : Colors.grey.shade500,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? color : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () {
        _updateCurrentScreen(2, screen: const TokenScanPage());
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 24,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(delay: 1000.ms, duration: 1800.ms)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 1000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.05, 1.05),
                end: const Offset(1, 1),
                duration: 1000.ms,
              ),
          const SizedBox(height: 4),
          const Text(
            "Scan",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class for search items
class _SearchItem {
  final String title;
  final String type;
  final Widget Function(BuildContext) builder;
  _SearchItem(this.title, this.type, this.builder);
}

/// Redesigned HomeContent with modern card-based layout
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;
  final List<String> _bannerImagePaths = [
    'assets/image1.png',
    'assets/image21.jpg',
    'assets/image22.jpg',
    'assets/image23.jpg',
    'assets/image24.jpg',
  ];
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (_bannerImagePaths.length > 1) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_pageController.hasClients) {
        timer.cancel();
        return;
      }
      if (_currentIndex < _bannerImagePaths.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernBanner(),
          const SizedBox(height: 24),
          _buildSectionTitle("Features"),
          const SizedBox(height: 12),
          _buildFeatureTabs(),
          const SizedBox(height: 24),
          _buildFeatureGrid(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBanner() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _bannerImagePaths.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.asset(
                    _bannerImagePaths[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildFeatureTabs() {
    final List<String> tabs = [
      "All",
      "Registration",
      "Documents",
      "Tracking",
      "Reports",
    ];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.blue.shade700
                              : Colors.grey.shade600,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final List<Map<String, dynamic>> features = [
      {
        'icon': 'assets/painter_kyc_tracking.png',
        'label': 'Painter KYC\nTracking',
        'fallbackIcon': Icons.track_changes_sharp,
      },
      {
        'icon': 'assets/painter_kyc_registration.png',
        'label': 'Painter KYC\nRegistration',
        'fallbackIcon': Icons.app_registration,
      },
      {
        'icon': 'assets/universal_outlets_registration.png',
        'label': 'Universal Outlets\nRegistration',
        'fallbackIcon': Icons.store,
      },
      {
        'icon': 'assets/retailer_registration.png',
        'label': 'Retailer\nRegistration',
        'fallbackIcon': Icons.person_add,
      },
      {
        'icon': 'assets/accounts_statement.png',
        'label': 'Accounts\nStatement',
        'fallbackIcon': Icons.account_balance,
      },
      {
        'icon': 'assets/information_document.png',
        'label': 'Information\nDocument',
        'fallbackIcon': Icons.description,
      },
      {
        'icon': 'assets/rpl_outlet_tracker.png',
        'label': 'RPL Outlet\nTracker',
        'fallbackIcon': Icons.location_on,
      },
      {
        'icon': 'assets/scheme_document.png',
        'label': 'Scheme\nDocument',
        'fallbackIcon': Icons.library_books,
      },
      {
        'icon': 'assets/activity_summary.png',
        'label': 'Activity\nSummary',
        'fallbackIcon': Icons.summarize,
      },
      {
        'icon': 'assets/purchaser_360.png',
        'label': 'Purchaser\n360',
        'fallbackIcon': Icons.people,
      },
      {
        'icon': 'assets/employee_dashboard.png',
        'label': 'Employee\nDashBoard',
        'fallbackIcon': Icons.dashboard,
      },
      {
        'icon': 'assets/grc_lead_entry.png',
        'label': 'GRC\nLead Entry',
        'fallbackIcon': Icons.edit_note,
      },
    ];
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: features.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(
          feature['icon']!,
          feature['label']!,
          index,
          feature['fallbackIcon']!,
        );
      },
    );
  }

  Widget _buildFeatureCard(
    String iconPath,
    String label,
    int index,
    IconData fallbackIcon,
  ) {
    // Define colors for different features
    final List<Color> featureColors = [
      Colors.blue.shade400,
      Colors.blue.shade400,
      Colors.blue.shade400,
      Colors.blue.shade400,
      Colors.blue.shade400,
      Colors.blue.shade400,
      Colors.blue.shade400,
      Colors.blue.shade400,
      Colors.blue.shade400,
      Colors.blue.shade400,
      Colors.blue.shade400,
      Colors.blue.shade400,
    ];
    // Get color for this feature based on index
    final Color featureColor = featureColors[index % featureColors.length];
    return GestureDetector(
      onTap: () {
        if (label.contains('Painter KYC\nTracking')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PainterKycTrackingPage()),
          );
        } else if (label.contains('Universal Outlets\nRegistration')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UniversalOutletRegistrationPage(),
            ),
          );
        } else if (label.contains('Retailer\nRegistration')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RetailerRegistrationPage()),
          );
        } else if (label.contains('Accounts\nStatement')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccountsStatementPage()),
          );
        } else if (label.contains('Scheme\nDocument')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SchemeDocumentPage()),
          );
        } else if (label.contains('Activity\nSummary')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActivitySummaryPage()),
          );
        } else if (label.contains('Employee\nDashBoard')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeDashboardPage()),
          );
        } else if (label.contains('GRC\nLead Entry')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GrcLeadEntryPage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3D Icon Container with fallback
            Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [featureColor, featureColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: featureColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.grey.shade100],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          iconPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to icon if image fails to load
                            return Icon(
                              fallbackIcon,
                              color: Colors.blue.shade600,
                              size: 30,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                )
                .animate(
                  target: index.toDouble(),
                ) // Animate each card with a delay based on index
                .fadeIn(duration: 600.ms, delay: (index * 100).ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .shimmer(
                  delay: 1200.ms,
                  duration: 1800.ms,
                  color: featureColor.withOpacity(0.3),
                )
                .then(delay: 3000.ms)
                .moveY(
                  begin: 0,
                  end: -5,
                  duration: 1000.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .moveY(
                  begin: -5,
                  end: 0,
                  duration: 1000.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 12),
            // Fixed text overflow issue
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// HorizontalMenu remains unchanged
class HorizontalMenu extends StatefulWidget {
  const HorizontalMenu({super.key});
  @override
  State<HorizontalMenu> createState() => _HorizontalMenuState();
}

class _HorizontalMenuState extends State<HorizontalMenu> {
  String selected = "Quick Menu";
  final List<String> menuItems = [
    "Quick Menu",
    "Document",
    "Registration",
    "Entertainment",
    "Painter",
    "Attendance",
  ];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final label = menuItems[index];
          final isSelected = selected == label;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected ? Colors.blue : Colors.white,
                foregroundColor: isSelected ? Colors.white : Colors.blue,
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onPressed: () {
                setState(() {
                  selected = label;
                });
              },
              child: Text(label, style: Fonts.body),
            ),
          );
        },
      ),
    );
  }
}
