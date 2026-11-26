import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/hotel_repository.dart';
import '../resources/app_images.dart';
import '../theme/app_theme.dart';
import 'booking_confirmation_screen.dart';
import 'date_guest_picker_screen.dart';

class ReviewBookingScreen extends StatefulWidget {
  const ReviewBookingScreen({
    super.key,
    required this.hotel,
    required this.room,
    this.repository = const FirestoreHotelRepository(),
    this.initialCheckIn,
    this.initialCheckOut,
    this.initialAdults = 2,
    this.initialChildren = 0,
  });

  final Hotel hotel;
  final RoomType room;
  final HotelRepository repository;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final int initialAdults;
  final int initialChildren;

  @override
  State<ReviewBookingScreen> createState() => _ReviewBookingScreenState();
}

class _ReviewBookingScreenState extends State<ReviewBookingScreen> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _adults;
  late int _children;
  String _paymentMethod = 'Credit / Debit Card (demo)';
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkIn =
        widget.initialCheckIn ?? DateTime.now().add(const Duration(days: 1));
    _checkOut =
        widget.initialCheckOut ?? DateTime.now().add(const Duration(days: 3));
    _adults = widget.initialAdults;
    _children = widget.initialChildren;
  }

  int get _nights => _checkOut.difference(_checkIn).inDays;
  double get _total => widget.room.price * _nights;

  Future<void> _pickDates() async {
    final result = await Navigator.push<DatePickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => DateGuestPickerScreen(
          initialStartDate: _checkIn,
          initialEndDate: _checkOut,
          initialAdults: _adults,
          initialChildren: _children,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _checkIn = result.checkInDate;
      _checkOut = result.checkOutDate;
      _adults = result.adults;
      _children = result.children;
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
      appBar: AppBar(title: const Text('Yatrik')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text(
            'Review Booking',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppImages.buildImage(
                  pathOrUrl: imagePath,
                  height: 150,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.room.title} · ${widget.hotel.location}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _dateSummary(
                              label: 'CHECK-IN',
                              value: _dateString(_checkIn),
                            ),
                          ),
                          Container(
                            height: 42,
                            width: 1,
                            color: AppColors.borderLight,
                          ),
                          Expanded(
                            child: _dateSummary(
                              label: 'CHECK-OUT',
                              value: _dateString(_checkOut),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Change dates',
                            onPressed: _pickDates,
                            icon: const Icon(Icons.edit_calendar_outlined),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$_adults Adults, $_children Children · $_nights nights',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showGuestPicker(context),
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Demo only. Your selection is saved with the reservation; no payment is processed.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _paymentOption(
            title: 'Credit / Debit Card',
            subtitle: 'Visa, Mastercard, Amex (demo only)',
            value: 'Credit / Debit Card (demo)',
            icon: Icons.credit_card_outlined,
          ),
          const SizedBox(height: 10),
          _paymentOption(
            title: 'UPI Payment',
            subtitle: 'Google Pay, PhonePe, Paytm (demo only)',
            value: 'UPI Payment (demo)',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 10),
          _paymentOption(
            title: 'Pay at Hotel',
            subtitle: 'No immediate charge; pay upon arrival',
            value: 'Pay at Hotel',
            icon: Icons.hotel_outlined,
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _summaryRow(
                    '₹${widget.room.price.toStringAsFixed(0)} × $_nights nights',
                    '₹${_total.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 10),
                  _summaryRow('Service fee', '₹0'),
                  const SizedBox(height: 10),
                  _summaryRow('Taxes & surcharges', '₹0'),
                  const Divider(height: 24),
                  _summaryRow(
                    'TOTAL (DEMO)',
                    '₹${_total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _createBooking,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('CONFIRM BOOKING'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateSummary({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final selected = _paymentMethod == value;
    return InkWell(
      onTap: _saving ? null : () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accentGold : AppColors.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.accentGold : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: AppColors.primaryNavy, size: 21),
          ],
        ),
      ),
    );
  }

  Future<void> _showGuestPicker(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Guests'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _guestCounter(
                label: 'Adults',
                value: _adults,
                minimum: 1,
                onChanged: (value) {
                  setState(() => _adults = value);
                  setDialogState(() {});
                },
              ),
              _guestCounter(
                label: 'Children',
                value: _children,
                minimum: 0,
                onChanged: (value) {
                  setState(() => _children = value);
                  setDialogState(() {});
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
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
