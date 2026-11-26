import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/hotel_repository.dart';
import '../resources/app_images.dart';
import '../theme/app_theme.dart';
import 'booking_confirmation_screen.dart';

class ReviewBookingScreen extends StatefulWidget {
  const ReviewBookingScreen({
    super.key,
    required this.hotel,
    required this.room,
    this.repository = const FirestoreHotelRepository(),
  });

  final Hotel hotel;
  final RoomType room;
  final HotelRepository repository;

  @override
  State<ReviewBookingScreen> createState() => _ReviewBookingScreenState();
}

class _ReviewBookingScreenState extends State<ReviewBookingScreen> {
  late DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  late DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  int _adults = 2;
  int _children = 0;
  String _paymentMethod = 'Pay at property';
  bool _saving = false;
  String? _errorMessage;

  int get _nights => _checkOut.difference(_checkIn).inDays;
  double get _total => widget.room.price * _nights;

  Future<void> _pickDates() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 2),
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
    );
    if (picked == null) return;
    setState(() {
      _checkIn = picked.start;
      _checkOut = picked.end;
    });
  }

  Future<void> _createBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _errorMessage = 'Sign in before creating a booking.');
      return;
    }
    if (_nights <= 0) {
      setState(() => _errorMessage = 'Choose a check-out date after check-in.');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    final booking = Booking(
      userId: user.uid,
      guestName: user.displayName ?? user.email ?? 'Traveler',
      guestEmail: user.email ?? '',
      hotelId: widget.hotel.id,
      hotelTitle: widget.hotel.title,
      hotelLocation: widget.hotel.location,
      hotelImageUrl: widget.hotel.imageUrl,
      roomId: widget.room.id,
      roomTitle: widget.room.title,
      checkIn: _dateString(_checkIn),
      checkOut: _dateString(_checkOut),
      adults: _adults,
      children: _children,
      total: _total,
      paymentMethod: _paymentMethod,
    );
    try {
      final id = await widget.repository.createBooking(booking);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BookingConfirmationScreen(booking: booking.withId(id)),
        ),
      );
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not create booking: ${error.message ?? error.code}',
        );
      }
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on ArgumentError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message?.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.hotel.imageUrl.trim().isEmpty
        ? AppImages.assetAzureVista
        : widget.hotel.imageUrl.trim();
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Review booking')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppImages.buildImage(
                  pathOrUrl: imagePath,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hotel.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${widget.room.title} · ${widget.hotel.location}'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickDates,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          '${_dateString(_checkIn)} — ${_dateString(_checkOut)} ($_nights nights)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _guestCounter(
                        label: 'Adults',
                        value: _adults,
                        onChanged: (value) => setState(() => _adults = value),
                        minimum: 1,
                      ),
                      _guestCounter(
                        label: 'Children',
                        value: _children,
                        onChanged: (value) => setState(() => _children = value),
                        minimum: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment method',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Demo only: this selection is saved with the booking. No payment is processed.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _paymentMethod,
            decoration: const InputDecoration(
              labelText: 'Payment choice',
              filled: true,
              fillColor: Colors.white,
            ),
            items: const ['Pay at property', 'Demo card', 'Demo UPI']
                .map(
                  (method) =>
                      DropdownMenuItem(value: method, child: Text(method)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _paymentMethod = value);
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _summaryRow(
                    '₹${widget.room.price.toStringAsFixed(0)} × $_nights nights',
                    '₹${_total.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 24),
                  _summaryRow(
                    'Total (no payment processed)',
                    '₹${_total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _createBooking,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Create booking'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestCounter({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required int minimum,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value <= minimum ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value'),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

String _dateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
