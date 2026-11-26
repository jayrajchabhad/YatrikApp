import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/auth_session.dart';
import '../data/hotel_repository.dart';
import '../theme/app_theme.dart';
import 'booking_confirmation_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({
    super.key,
    this.repository = const FirestoreHotelRepository(),
  });

  final HotelRepository repository;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedTab = 0;
  static const _tabs = ['Upcoming', 'Completed', 'Cancelled'];

  List<Booking> _forTab(List<Booking> bookings) => bookings.where((booking) {
    if (booking.status == 'CANCELLED') return _selectedTab == 2;
    final checkout = DateTime.tryParse(booking.checkOut);
    final isCompleted = checkout != null && checkout.isBefore(DateTime.now());
    return _selectedTab == 1 ? isCompleted : !isCompleted;
  }).toList();

  Future<void> _cancelBooking(Booking booking) async {
    try {
      await widget.repository.updateBookingStatus(booking.id, 'CANCELLED');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not cancel booking: ${error.message ?? error.code}',
          ),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = currentFirebaseUserOrNull();
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Sign in to view your bookings.'))
            : StreamBuilder<List<Booking>>(
                stream: widget.repository.watchBookings(userId: user.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load bookings: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final bookings = _forTab(snapshot.data!);
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'My Bookings',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your reservations are synced with your account.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: List.generate(_tabs.length, (index) {
                          final selected = _selectedTab == index;
                          return Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _selectedTab = index),
                              child: Text(
                                _tabs[index],
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selected
                                      ? AppColors.primaryNavy
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const Divider(),
                      const SizedBox(height: 12),
                      if (bookings.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'No ${_tabs[_selectedTab].toLowerCase()} bookings.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...bookings.map(_buildBookingCard),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final canCancel =
        booking.status != 'CANCELLED' && booking.status != 'COMPLETED';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking.hotelImageUrl.isNotEmpty)
            Image.network(
              booking.hotelImageUrl,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 170,
                child: Icon(Icons.hotel_outlined, size: 48),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.hotelTitle,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Chip(label: Text(booking.status)),
                  ],
                ),
                Text(
                  booking.hotelLocation,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text('${booking.checkIn} — ${booking.checkOut}'),
                Text(
                  '${booking.adults} adults, ${booking.children} children · ${booking.roomTitle}',
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${booking.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingConfirmationScreen(booking: booking),
                        ),
                      ),
                      child: const Text('View voucher'),
                    ),
                    if (canCancel)
                      TextButton(
                        onPressed: () => _cancelBooking(booking),
                        child: const Text(
                          'Cancel booking',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
