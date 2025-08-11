import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learning2/features/authentication/presentation/pages/login_screen.dart';

import '../../../../core/theme/app_theme.dart';

class WorkerAppDrawer extends StatefulWidget {
  const WorkerAppDrawer({super.key});

  @override
  State<WorkerAppDrawer> createState() => _WorkerAppDrawerState();
}

class _WorkerAppDrawerState extends State<WorkerAppDrawer> {
  // Selected category
  String _selectedCategory = 'Accounts';

  // List of categories
  final List<String> _categories = [
    'Accounts',
    'HR&Admin',
    'General',
    'Personnel',
    'Employee',
  ];

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdminLoggedIn', false);
    await prefs.setBool('isLoggedIn', false);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: SparshTheme.cardBackground,
        child: Column(
          children: [
            // Drawer header with Birla White
            DrawerHeader(
              decoration: const BoxDecoration(
                color: SparshTheme.primaryBlueAccent,
                gradient: SparshTheme.drawerHeaderGradient,
                boxShadow: SparshShadows.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error handling for image loading is good
                  SizedBox(
                    width: 700,
                    child: Image.asset(
                      'assets/logo.png', // Ensure this asset exists in pubspec.yaml
                      height: 97,
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading drawer header image: $error');
                        return const Icon(
                          Icons.business,
                          size: 60,
                          color: Colors.white,
                        ); // Placeholder icon
                      },
                    ),
                  ),
                  const SizedBox(height: SparshSpacing.sm),
                  const Text(
                    'Birla White',
                    style: SparshTypography.heading2,
                  ),
                ],
              ),
            ),

            // Categories list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;

                  return Container(
                    color: isSelected ? SparshTheme.lightBlueBackground : SparshTheme.cardBackground,
                    child: ListTile(
                      title: Text(
                        category,
                        style: isSelected ? SparshTypography.bodyBold : SparshTypography.body,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            // Logout option
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: SparshTheme.errorRed),
              title: Text(
                'Logout',
                style: SparshTypography.bodyBold.copyWith(color: SparshTheme.errorRed),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
