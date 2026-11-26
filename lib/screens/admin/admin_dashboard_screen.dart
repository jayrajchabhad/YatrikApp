import 'package:flutter/material.dart';

import '../../data/hotel_repository.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    this.repository = const FirestoreHotelRepository(),
  });

  final HotelRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: StreamBuilder<List<Hotel>>(
          stream: repository.watchHotels(),
          builder: (context, hotelSnapshot) {
            if (hotelSnapshot.hasError) {
              return _Message(
                'Could not load dashboard: ${hotelSnapshot.error}',
              );
            }
            if (!hotelSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return StreamBuilder<List<Booking>>(
              stream: repository.watchBookings(),
              builder: (context, bookingSnapshot) {
                if (bookingSnapshot.hasError) {
                  return _Message(
                    'Could not load bookings: ${bookingSnapshot.error}',
                  );
                }
                if (!bookingSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final hotels = hotelSnapshot.data!;
                final bookings = bookingSnapshot.data!;
                final revenue = bookings
                    .where((booking) => booking.status != 'CANCELLED')
                    .fold<double>(0, (total, booking) => total + booking.total);
                final pendingCount = bookings
                    .where((booking) => booking.status == 'PENDING')
                    .length;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Live summary from your Firestore catalog and bookings.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    _MetricCard(label: 'HOTELS', value: '${hotels.length}'),
                    _MetricCard(label: 'BOOKINGS', value: '${bookings.length}'),
                    _MetricCard(label: 'PENDING', value: '$pendingCount'),
                    _MetricCard(
                      label: 'BOOKING VALUE (DEMO)',
                      value: '₹${revenue.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Recent bookings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (bookings.isEmpty)
                      const Text(
                        'Bookings will appear here when customers reserve a stay.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ...bookings
                          .take(5)
                          .map(
                            (booking) => Card(
                              child: ListTile(
                                title: Text(booking.hotelTitle),
                                subtitle: Text(
                                  '${booking.guestName} · ${booking.checkIn} to ${booking.checkOut}',
                                ),
                                trailing: Text(booking.status),
                              ),
                            ),
                          ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      title: Text(
        label,
        style: const TextStyle(fontSize: 11, letterSpacing: 1),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
    ),
  );
}
