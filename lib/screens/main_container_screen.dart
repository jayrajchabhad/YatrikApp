import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_session.dart';
import '../data/hotel_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import 'welcome_screen.dart';
import 'explore_screen.dart';
import 'my_bookings_screen.dart';
import 'saved_escapes_screen.dart';
import 'destination_filter_screen.dart';
import 'edit_profile_screen.dart';
import 'admin/admin_login_screen.dart';

class MainContainerScreen extends StatefulWidget {
  final int initialIndex;
  final HotelRepository hotelRepository;

  const MainContainerScreen({
    super.key,
    this.initialIndex = 0,
    this.hotelRepository = const FirestoreHotelRepository(),
  });

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      ExploreScreen(hotelRepository: widget.hotelRepository),
      MyBookingsScreen(repository: widget.hotelRepository),
      SavedEscapesScreen(repository: widget.hotelRepository),
      EditProfileScreen(repository: widget.hotelRepository),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = currentFirebaseUserOrNull();
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Open navigation menu',
          icon: const Icon(Icons.menu, color: AppColors.primaryDark),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Yatrik',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer Header
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(color: AppColors.primaryNavy),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yatrik',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Member: ${user?.displayName ?? user?.email ?? 'Guest'}',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Menu List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    _buildDrawerItem(
                      title: 'Explore Sanctuaries',
                      icon: Icons.explore_outlined,
                      isSelected: _currentIndex == 0,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 0);
                      },
                    ),
                    _buildDrawerItem(
                      title: 'My Bookings',
                      icon: Icons.calendar_month_outlined,
                      isSelected: _currentIndex == 1,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 1);
                      },
                    ),
                    _buildDrawerItem(
                      title: 'Saved Escapes',
                      icon: Icons.favorite_border,
                      isSelected: _currentIndex == 2,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 2);
                      },
                    ),
                    _buildDrawerItem(
                      title: 'Filter & Search Destinations',
                      icon: Icons.filter_list_rounded,
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DestinationFilterScreen(
                              repository: widget.hotelRepository,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      title: 'Edit Profile',
                      icon: Icons.person_outline,
                      isSelected: _currentIndex == 3,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 3);
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: AppColors.borderLight),
                    ),
                    _buildDrawerItem(
                      title: 'Switch to Admin Portal',
                      icon: Icons.admin_panel_settings_outlined,
                      isSelected: false,
                      textColor: AppColors.primaryNavy,
                      iconColor: AppColors.primaryNavy,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      title: 'Sign Out',
                      icon: Icons.logout_rounded,
                      isSelected: false,
                      textColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        navigator.pop();
                        try {
                          await FirebaseAuth.instance.signOut();
                        } on FirebaseAuthException catch (error) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not sign out: ${error.message ?? error.code}',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        if (!mounted) return;
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const WelcomeScreen(),
                          ),
                          (_) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDrawerItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            iconColor ??
            (isSelected ? AppColors.accentGold : AppColors.primaryDark),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color:
              textColor ??
              (isSelected ? AppColors.accentGold : AppColors.textPrimary),
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.inputBackground,
      onTap: onTap,
    );
  }
}
