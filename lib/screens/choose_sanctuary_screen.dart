import 'package:flutter/material.dart';

import '../data/hotel_repository.dart';
import '../theme/app_theme.dart';
import 'review_booking_screen.dart';

class ChooseSanctuaryScreen extends StatelessWidget {
  const ChooseSanctuaryScreen({
    super.key,
    required this.hotel,
    this.repository = const FirestoreHotelRepository(),
  });

  final Hotel hotel;
  final HotelRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: Text(hotel.title)),
      body: StreamBuilder<List<RoomType>>(
        stream: repository.watchRooms(hotelId: hotel.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load rooms: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snapshot.data!;
          if (rooms.isEmpty) {
            return const Center(child: Text('No rooms have been added yet.'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Choose a room',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              ...rooms.map(
                (room) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(room.title),
                    subtitle: Text(
                      '₹${room.price.toStringAsFixed(0)} per night · ${room.units} available',
                    ),
                    trailing: ElevatedButton(
                      onPressed: room.units <= 0
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewBookingScreen(
                                  hotel: hotel,
                                  room: room,
                                  repository: repository,
                                ),
                              ),
                            ),
                      child: const Text('Select'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
