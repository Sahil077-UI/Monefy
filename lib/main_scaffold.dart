import 'package:flutter/material.dart';

import 'main.dart';
import 'pages/groups_page.dart';
import 'pages/insights_page.dart';
import 'pages/settings_page.dart';
import 'theme/app_colors.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;

  // Keep pages alive with IndexedStack so state (scroll, selected month,
  // loaded data) is preserved when switching tabs.
  final List<Widget> pages = const [
    HomePage(),
    GroupsPage(),
    InsightsPage(),
    SettingsPage(),
  ];

  void onTabSelected(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The pages themselves supply their own Scaffold with AppBar,
      // so this Scaffold's body is just the IndexedStack.
      body: IndexedStack(index: currentIndex, children: pages),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabSelected,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.folder_rounded, color: AppColors.primary),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(
              Icons.insights_rounded,
              color: AppColors.primary,
            ),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(
              Icons.settings_rounded,
              color: AppColors.primary,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
