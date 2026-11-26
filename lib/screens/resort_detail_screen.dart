import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/hotel_repository.dart';
import '../resources/app_images.dart';
import '../theme/app_theme.dart';
import 'choose_sanctuary_screen.dart';
import 'date_guest_picker_screen.dart';
import 'review_booking_screen.dart';

class ResortDetailScreen extends StatefulWidget {
  const ResortDetailScreen({
    super.key,
    required this.hotel,
    this.repository = const FirestoreHotelRepository(),
  });

  final Hotel hotel;
  final HotelRepository repository;

  @override
  State<ResortDetailScreen> createState() => _ResortDetailScreenState();
}

class _ResortDetailScreenState extends State<ResortDetailScreen> {
  String? _selectedRoomId;
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  int _adults = 2;
  int _children = 0;

  int get _nights => _checkOut.difference(_checkIn).inDays;

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

  RoomType? _selectedRoom(List<RoomType> rooms) {
    for (final room in rooms) {
      if (room.units > 0 && room.id == _selectedRoomId) return room;
    }
    for (final room in rooms) {
      if (room.units > 0) return room;
    }
    return null;
  }

  Future<void> _writeReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in before writing a review.')),
      );
      return;
    }

    final commentController = TextEditingController();
    double rating = 5;
    final reviewText = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Write a review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<double>(
                initialValue: rating,
                decoration: const InputDecoration(labelText: 'Rating'),
                items: const [1, 2, 3, 4, 5]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value.toDouble(),
                        child: Text('${value.toString()} stars'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => rating = value);
                },
              ),
              TextField(
                controller: commentController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Your comments'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = commentController.text.trim();
                if (text.isNotEmpty) Navigator.pop(context, '$rating|$text');
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    commentController.dispose();
    if (reviewText == null) return;
    final parts = reviewText.split('|');
    try {
      await widget.repository.addReview(
        Review(
          userId: user.uid,
          userName: user.displayName ?? 'Traveler',
          hotelId: widget.hotel.id,
          hotelTitle: widget.hotel.title,
          rating: double.parse(parts.first),
          comment: parts.skip(1).join('|'),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not submit review: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final imagePath = hotel.imageUrl.trim().isEmpty
        ? AppImages.assetAzureVista
        : hotel.imageUrl.trim();
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: Text(hotel.title)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppImages.buildImage(
            pathOrUrl: imagePath,
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${hotel.propertyType} · ${hotel.location}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.accentGold),
                    const SizedBox(width: 4),
                    Text(
                      hotel.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      'From ₹${hotel.price.toStringAsFixed(0)} / night',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (hotel.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(hotel.description),
                ],
                if (hotel.amenities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hotel.amenities
                        .map((amenity) => Chip(label: Text(amenity)))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select your room',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChooseSanctuaryScreen(
                            hotel: hotel,
                            repository: widget.repository,
                          ),
                        ),
                      ),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<RoomType>>(
                  stream: widget.repository.watchRooms(hotelId: hotel.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Could not load rooms: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rooms = snapshot.data!;
                    if (rooms.isEmpty) {
                      return const Text(
                        'No rooms are available for this hotel yet. Check back later.',
                        style: TextStyle(color: AppColors.textSecondary),
                      );
                    }
                    final selectedRoom = _selectedRoom(rooms);
                    return Column(
                      children: [
                        ...rooms.map(
                          (room) => _roomCard(
                            room,
                            selected: selectedRoom?.id == room.id,
                          ),
                        ),
                        if (selectedRoom != null)
                          _bookingSummary(selectedRoom),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Guest reviews',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _writeReview,
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Write review'),
                    ),
                  ],
                ),
                StreamBuilder<List<Review>>(
                  stream: widget.repository.watchReviews(hotelId: hotel.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Could not load reviews: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.isEmpty) {
                      return const Text(
                        'No reviews yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      );
                    }
                    return Column(
                      children: snapshot.data!
                          .map(
                            (review) => Card(
                              margin: const EdgeInsets.only(top: 10),
                              child: ListTile(
                                title: Text(review.userName),
                                subtitle: Text(review.comment),
                                trailing: Text(
                                  '${review.rating.toStringAsFixed(1)} ★',
                                  style: const TextStyle(
                                    color: AppColors.accentGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomCard(RoomType room, {required bool selected}) {
    final fallbackAsset =
        room.title.toLowerCase().contains('deluxe') ||
            room.title.toLowerCase().contains('suite')
        ? AppImages.assetDeluxeOcean
        : AppImages.assetStandardRoom;
    return Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected ? AppColors.primaryNavy : AppColors.borderLight,
        width: selected ? 1.5 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppImages.buildImage(
          pathOrUrl: room.imageUrl.trim().isEmpty
              ? fallbackAsset
              : room.imageUrl.trim(),
          fallbackUrl: widget.hotel.imageUrl,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
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
                      room.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Text(
                    '₹${room.price.toStringAsFixed(0)} / night',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (room.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  room.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                room.units > 0 ? '${room.units} available' : 'Sold out',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: room.units <= 0
                      ? null
                      : () => setState(() => _selectedRoomId = room.id),
                  child: Text(selected ? 'SELECTED' : 'SELECT ROOM'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }

  Widget _bookingSummary(RoomType room) => Card(
    margin: const EdgeInsets.only(top: 6),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR STAY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CHECK-IN',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(_dateString(_checkIn)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CHECK-OUT',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(_dateString(_checkOut)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Change dates and guests',
                onPressed: _pickDates,
                icon: const Icon(Icons.edit_calendar_outlined),
              ),
            ],
          ),
          Text(
            '$_adults Adults, $_children Children · $_nights nights',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(child: Text('₹${room.price.toStringAsFixed(0)} × $_nights nights')),
              Text(
                '₹${(room.price * _nights).toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: room.units <= 0
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewBookingScreen(
                          hotel: widget.hotel,
                          room: room,
                          repository: widget.repository,
                          initialCheckIn: _checkIn,
                          initialCheckOut: _checkOut,
                          initialAdults: _adults,
                          initialChildren: _children,
                        ),
                      ),
                    ),
              child: const Text('BOOK NOW'),
            ),
          ),
        ],
      ),
    ),
  );

  String _dateString(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
}
