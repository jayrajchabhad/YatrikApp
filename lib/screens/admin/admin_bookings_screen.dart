import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/hotel_repository.dart';
import '../../theme/app_theme.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({
    super.key,
    this.repository = const FirestoreHotelRepository(),
  });

  final HotelRepository repository;

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String _filter = 'All';

  Future<void> _updateStatus(Booking booking, String status) async {
    try {
      await widget.repository.updateBookingStatus(booking.id, status);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update booking: ${error.message ?? error.code}',
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

  Future<void> _deleteBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete booking?'),
        content: Text('Delete the booking for ${booking.guestName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteBooking(booking.id);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete booking: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: StreamBuilder<List<Booking>>(
          stream: widget.repository.watchBookings(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _Message(
                'Could not load bookings: ${snapshot.error}',
                isError: true,
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allBookings = snapshot.data!;
            final bookings = _filter == 'All'
                ? allBookings
                : allBookings
                      .where(
                        (booking) => booking.status == _filter.toUpperCase(),
                      )
                      .toList();
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Reservations & Bookings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${allBookings.length} bookings stored in Firestore',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  children:
                      ['All', 'Pending', 'Confirmed', 'Cancelled', 'Completed']
                          .map(
                            (filter) => ChoiceChip(
                              label: Text(filter),
                              selected: _filter == filter,
                              onSelected: (_) =>
                                  setState(() => _filter = filter),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
                if (bookings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No bookings for this filter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Change booking status',
                  onSelected: (status) => _updateStatus(booking, status),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'PENDING', child: Text('Pending')),
                    PopupMenuItem(value: 'CONFIRMED', child: Text('Confirmed')),
                    PopupMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                    PopupMenuItem(value: 'COMPLETED', child: Text('Completed')),
                  ],
                  child: Chip(label: Text(booking.status)),
                ),
              ],
            ),
            Text(
              '${booking.guestName} · ${booking.guestEmail}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text('${booking.roomTitle} · ${booking.hotelLocation}'),
            Text('${booking.checkIn} — ${booking.checkOut}'),
            Text('${booking.adults} adults, ${booking.children} children'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '₹${booking.total.toStringAsFixed(2)} · ${booking.paymentMethod}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete booking',
                  onPressed: () => _deleteBooking(booking),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: isError ? Colors.red : AppColors.textSecondary),
      ),
    ),
  );
}
