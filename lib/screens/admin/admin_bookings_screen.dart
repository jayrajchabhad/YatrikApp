import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/hotel_repository.dart';
import '../date_guest_picker_screen.dart';
import '../../theme/app_theme.dart';

Future<void> showAdminNewBookingSheet(
  BuildContext context,
  HotelRepository repository,
) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AdminBookingEditor(repository: repository),
  );
  if (created == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Booking request created.')));
  }
}

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

  Future<void> _showFilterSheet() async {
    final filter = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingFilterSheet(initialFilter: _filter),
    );
    if (filter != null && mounted) setState(() => _filter = filter);
  }

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
            final pendingCount = allBookings
                .where((booking) => booking.status == 'PENDING')
                .length;
            final bookingValue = allBookings
                .where((booking) => booking.status != 'CANCELLED')
                .fold<double>(0, (total, booking) => total + booking.total);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const Text(
                  'Reservations & Bookings',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Monitor reservation requests and room availability.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                _SummaryCard(
                  label: 'TOTAL BOOKINGS',
                  value: '${allBookings.length}',
                  icon: Icons.calendar_month_outlined,
                ),
                _SummaryCard(
                  label: 'NEW RESERVATIONS',
                  value: '$pendingCount',
                  subtitle: '$pendingCount pending approval',
                  icon: Icons.event_available_outlined,
                ),
                _SummaryCard(
                  label: 'BOOKING VALUE · DEMO',
                  value: '₹${bookingValue.toStringAsFixed(2)}',
                  subtitle: 'Not paid or processed by this demo',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Confirmed', 'Pending', 'Cancelled']
                              .map(
                                (filter) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(filter),
                                    selected: _filter == filter,
                                    onSelected: (_) =>
                                        setState(() => _filter = filter),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Filter bookings',
                      onPressed: _showFilterSheet,
                      icon: const Icon(Icons.filter_list),
                    ),
                    const SizedBox(width: 6),
                    FilledButton.icon(
                      onPressed: () => showAdminNewBookingSheet(
                        context,
                        widget.repository,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(
                          AppColors.inputBackground,
                        ),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 76,
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('BOOKING ID')),
                          DataColumn(label: Text('GUEST')),
                          DataColumn(label: Text('HOTEL')),
                          DataColumn(label: Text('DATES')),
                          DataColumn(label: Text('AMOUNT')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: bookings.map(_bookingRow).toList(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  DataRow _bookingRow(Booking booking) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            booking.id.isEmpty ? '—' : '#${booking.id.substring(0, booking.id.length.clamp(0, 8))}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(
          SizedBox(
            width: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.guestName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  booking.guestEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 145,
            child: Text(
              booking.hotelTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Text(
            '${booking.checkIn}\n${booking.checkOut}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
        DataCell(Text('₹${booking.total.toStringAsFixed(2)}')),
        DataCell(_StatusBadge(booking.status)),
        DataCell(
          PopupMenuButton<String>(
            tooltip: 'Booking actions',
            onSelected: (action) {
              if (action == 'delete') {
                _deleteBooking(booking);
              } else {
                _updateStatus(booking, action);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'PENDING', child: Text('Mark pending')),
              PopupMenuItem(value: 'CONFIRMED', child: Text('Confirm')),
              PopupMenuItem(value: 'CANCELLED', child: Text('Cancel')),
              PopupMenuItem(value: 'COMPLETED', child: Text('Complete')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ),
      ],
    );
  }
}

class _BookingFilterSheet extends StatefulWidget {
  const _BookingFilterSheet({required this.initialFilter});

  final String initialFilter;

  @override
  State<_BookingFilterSheet> createState() => _BookingFilterSheetState();
}

class _BookingFilterSheetState extends State<_BookingFilterSheet> {
  late String _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF9F7FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter Bookings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _filter = 'All'),
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'STATUS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['All', 'Confirmed', 'Pending', 'Cancelled']
                  .map(
                    (filter) => ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _filter),
                child: const Text('APPLY FILTERS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBookingEditor extends StatefulWidget {
  const _AdminBookingEditor({required this.repository});

  final HotelRepository repository;

  @override
  State<_AdminBookingEditor> createState() => _AdminBookingEditorState();
}

class _AdminBookingEditorState extends State<_AdminBookingEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _hotelId;
  String? _roomId;
  late DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  late DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  int _adults = 2;
  int _children = 0;
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

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
    if (result == null || !mounted) return;
    setState(() {
      _checkIn = result.checkInDate;
      _checkOut = result.checkOutDate;
      _adults = result.adults;
      _children = result.children;
    });
  }

  Future<void> _createBooking(Hotel hotel, RoomType room) async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _errorMessage = 'Sign in with an admin account first.');
      return;
    }
    if (_checkOut.difference(_checkIn).inDays <= 0) {
      setState(() => _errorMessage = 'Select a valid check-out date.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    final nights = _checkOut.difference(_checkIn).inDays;
    try {
      await widget.repository.createBooking(
        Booking(
          userId: user.uid,
          guestName: _nameController.text.trim(),
          guestEmail: _emailController.text.trim(),
          hotelId: hotel.id,
          hotelTitle: hotel.title,
          hotelLocation: hotel.location,
          hotelImageUrl: hotel.imageUrl,
          roomId: room.id,
          roomTitle: room.title,
          checkIn: _dateString(_checkIn),
          checkOut: _dateString(_checkOut),
          adults: _adults,
          children: _children,
          total: room.price * nights,
          paymentMethod: 'Pay at Hotel',
        ),
      );
      if (mounted) Navigator.pop(context, true);
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F7FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Create New Booking',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Guest Full Name'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Guest Email'),
              validator: (value) {
                final email = value?.trim() ?? '';
                return email.contains('@') ? null : 'Enter a valid email.';
              },
            ),
            const SizedBox(height: 10),
            _buildHotelSelector(),
            const SizedBox(height: 10),
            _buildDateButton(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            const Text(
              'New reservations are created as pending and stored under this admin account, not the guest account. The total uses the selected room rate; no payment is processed.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelSelector() {
    return StreamBuilder<List<Hotel>>(
      stream: widget.repository.watchHotels(),
      builder: (context, hotelSnapshot) {
        if (hotelSnapshot.hasError) {
          return _Message(
            'Could not load hotels: ${hotelSnapshot.error}',
            isError: true,
          );
        }
        if (!hotelSnapshot.hasData) {
          return const LinearProgressIndicator();
        }
        final hotels = hotelSnapshot.data!;
        if (hotels.isEmpty) {
          return const Text('Add a hotel before creating a booking.');
        }
        final hotel = hotels.firstWhere(
          (item) => item.id == _hotelId,
          orElse: () => hotels.first,
        );
        if (_hotelId != hotel.id) _hotelId = hotel.id;

        return Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: hotel.id,
              decoration: const InputDecoration(labelText: 'Select Hotel'),
              items: hotels
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                      _hotelId = value;
                      _roomId = null;
                    }),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<RoomType>>(
              stream: widget.repository.watchRooms(hotelId: hotel.id),
              builder: (context, roomSnapshot) {
                if (roomSnapshot.hasError) {
                  return _Message(
                    'Could not load rooms: ${roomSnapshot.error}',
                    isError: true,
                  );
                }
                if (!roomSnapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                final rooms = roomSnapshot.data!;
                if (rooms.isEmpty) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No room categories are available for this hotel.'),
                  );
                }
                final room = rooms.firstWhere(
                  (item) => item.id == _roomId,
                  orElse: () => rooms.first,
                );
                if (_roomId != room.id) _roomId = room.id;
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: room.id,
                      decoration: const InputDecoration(labelText: 'Room Type'),
                      items: rooms
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                '${item.title} · ₹${item.price.toStringAsFixed(0)}/night · ${item.units} left',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _roomId = value),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Estimated total: ₹${(room.price * _checkOut.difference(_checkIn).inDays).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving || room.units <= 0
                            ? null
                            : () => _createBooking(hotel, room),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('CREATE BOOKING REQUEST'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateButton() {
    return OutlinedButton.icon(
      onPressed: _saving ? null : _pickDates,
      icon: const Icon(Icons.calendar_month_outlined),
      label: Text(
        '${_dateString(_checkIn)} - ${_dateString(_checkOut)} · $_adults adults, $_children children',
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(icon, size: 30, color: AppColors.borderLight),
        ],
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'CONFIRMED' => const Color(0xFF16834A),
      'CANCELLED' => const Color(0xFFB42318),
      'COMPLETED' => AppColors.textSecondary,
      _ => const Color(0xFFB7791F),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: isError ? Colors.red : AppColors.textSecondary),
    ),
  );
}

String _dateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
