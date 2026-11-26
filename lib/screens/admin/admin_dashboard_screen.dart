import 'package:flutter/material.dart';

import '../../data/hotel_repository.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    this.repository = const FirestoreHotelRepository(),
    this.onAddHotel,
    this.onOpenBookings,
  });

  final HotelRepository repository;
  final VoidCallback? onAddHotel;
  final VoidCallback? onOpenBookings;

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
                final pendingCount = bookings
                    .where((booking) => booking.status == 'PENDING')
                    .length;
                final bookingValue = bookings
                    .where((booking) => booking.status != 'CANCELLED')
                    .fold<double>(0, (total, booking) => total + booking.total);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    const Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'A live view of your hospitality portfolio.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.65,
                      children: [
                        _MetricCard(
                          label: 'HOTELS',
                          value: '${hotels.length}',
                          icon: Icons.apartment_outlined,
                          color: const Color(0xFFE6F2FF),
                        ),
                        _MetricCard(
                          label: 'BOOKINGS',
                          value: '${bookings.length}',
                          icon: Icons.calendar_month_outlined,
                          color: const Color(0xFFE6F5FB),
                        ),
                        _MetricCard(
                          label: 'PENDING',
                          value: '$pendingCount',
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFFFFF3D6),
                        ),
                        _MetricCard(
                          label: 'BOOKING VALUE · DEMO',
                          value: '₹${bookingValue.toStringAsFixed(0)}',
                          icon: Icons.currency_rupee_rounded,
                          color: const Color(0xFFFFE9E3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Admin Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage listings and review customer reservations.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: onAddHotel,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add New Hotel'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: onOpenBookings,
                                    icon: const Icon(
                                      Icons.event_note_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Bookings'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recent Bookings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onOpenBookings,
                          icon: const Icon(Icons.filter_list, size: 18),
                          label: const Text('View all'),
                        ),
                      ],
                    ),
                    if (bookings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          'Bookings will appear here when travelers reserve a stay.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ...bookings.take(5).map(_RecentBookingCard.new),
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
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryDark),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _RecentBookingCard extends StatelessWidget {
  const _RecentBookingCard(this.booking);

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final guestName = booking.guestName.trim();
    final statusColor = switch (booking.status) {
      'CONFIRMED' => const Color(0xFF16834A),
      'CANCELLED' => const Color(0xFFB42318),
      'COMPLETED' => AppColors.textSecondary,
      _ => const Color(0xFFB7791F),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.inputBackground,
              child: Text(
                guestName.isEmpty
                    ? '?'
                    : guestName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.guestName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${booking.hotelTitle} · ${booking.checkIn} — ${booking.checkOut}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
