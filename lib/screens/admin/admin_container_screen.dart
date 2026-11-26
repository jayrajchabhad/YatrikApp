import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/auth_session.dart';
import '../../data/hotel_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../main_container_screen.dart';
import '../welcome_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_hotels_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_inventory_screen.dart';

class AdminContainerScreen extends StatefulWidget {
  final int initialIndex;
  final HotelRepository hotelRepository;

  const AdminContainerScreen({
    super.key,
    this.initialIndex = 0,
    this.hotelRepository = const FirestoreHotelRepository(),
  });

  @override
  State<AdminContainerScreen> createState() => _AdminContainerScreenState();
}

class _AdminContainerScreenState extends State<AdminContainerScreen> {
  late int _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      AdminDashboardScreen(
        repository: widget.hotelRepository,
        onAddHotel: () => setState(() => _currentIndex = 1),
        onOpenBookings: () => setState(() => _currentIndex = 2),
      ),
      AdminHotelsScreen(repository: widget.hotelRepository),
      AdminBookingsScreen(repository: widget.hotelRepository),
      AdminProfileScreen(repository: widget.hotelRepository),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = currentFirebaseUserOrNull();
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Open navigation menu',
            icon: const Icon(Icons.menu, color: AppColors.primaryDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Yatrik Admin',
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
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 26,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? user?.email ?? 'Admin',
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Senior Hospitality Admin',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Admin Portal Active',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Options List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 12, top: 8, bottom: 8),
                      child: Text(
                        'MANAGEMENT & ANALYTICS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    _buildDrawerItem(
                      title: 'Dashboard Overview',
                      icon: Icons.grid_view_rounded,
                      isSelected: _currentIndex == 0,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 0);
                      },
                    ),
                    _buildDrawerItem(
                      title: 'Master of Hotels',
                      icon: Icons.domain_outlined,
                      isSelected: _currentIndex == 1,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 1);
                      },
                    ),
                    _buildDrawerItem(
                      title: 'Reservations & Bookings',
                      icon: Icons.event_note_outlined,
                      isSelected: _currentIndex == 2,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 2);
                      },
                    ),
                    _buildDrawerItem(
                      title: 'Room Inventory & Rates',
                      icon: Icons.inventory_2_outlined,
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminInventoryScreen(
                              repository: widget.hotelRepository,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      title: 'Reviews & Ratings',
                      icon: Icons.star_rate_outlined,
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminReviewsScreen(
                              repository: widget.hotelRepository,
                            ),
                          ),
                        );
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: AppColors.borderLight),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 12, bottom: 8),
                      child: Text(
                        'ACCOUNT & SYSTEM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    _buildDrawerItem(
                      title: 'Admin Profile',
                      icon: Icons.person_outline,
                      isSelected: _currentIndex == 3,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 3);
                      },
                    ),
                    _buildDrawerItem(
                      title: 'Switch to User App',
                      icon: Icons.swap_horiz_rounded,
                      isSelected: false,
                      textColor: AppColors.primaryNavy,
                      iconColor: AppColors.primaryNavy,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainContainerScreen(),
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
                        navigator.pop();
                        await FirebaseAuth.instance.signOut();
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
      bottomNavigationBar: AdminBottomNav(
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? AppColors.inputBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: Icon(
            icon,
            color:
                iconColor ??
                (isSelected ? AppColors.primaryDark : AppColors.primaryDark),
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
