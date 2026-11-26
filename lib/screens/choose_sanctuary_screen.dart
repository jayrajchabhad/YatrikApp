import 'package:flutter/material.dart';

import '../data/hotel_repository.dart';
import '../resources/app_images.dart';
import '../theme/app_theme.dart';
import 'review_booking_screen.dart';

class ChooseSanctuaryScreen extends StatelessWidget {
  const ChooseSanctuaryScreen({
    super.key,
    required this.hotel,
    this.repository = const FirestoreHotelRepository(),
    this.initialCheckIn,
    this.initialCheckOut,
    this.initialAdults = 2,
    this.initialChildren = 0,
  });

  final Hotel hotel;
  final HotelRepository repository;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final int initialAdults;
  final int initialChildren;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : Builder(
                builder: (context) => IconButton(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        title: const Text('Yatrik'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<RoomType>>(
        stream: repository.watchRooms(hotelId: hotel.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _RoomMessage(
              message: 'Could not load rooms: ${snapshot.error}',
              isError: true,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const Text(
                'AVAILABLE ACCOMMODATIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose Your\nSanctuary',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Choose a room at ${hotel.title} that suits your journey.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              if (rooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: _RoomMessage(
                    message: 'No rooms have been added to this stay yet.',
                  ),
                )
              else
                ...rooms.map(
                  (room) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _RoomCard(
                      hotel: hotel,
                      room: room,
                      repository: repository,
                      initialCheckIn: initialCheckIn,
                      initialCheckOut: initialCheckOut,
                      initialAdults: initialAdults,
                      initialChildren: initialChildren,
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

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.hotel,
    required this.room,
    required this.repository,
    required this.initialCheckIn,
    required this.initialCheckOut,
    required this.initialAdults,
    required this.initialChildren,
  });

  final Hotel hotel;
  final RoomType room;
  final HotelRepository repository;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final int initialAdults;
  final int initialChildren;

  @override
  Widget build(BuildContext context) {
    final fallbackAsset =
        room.title.toLowerCase().contains('deluxe') ||
            room.title.toLowerCase().contains('suite')
        ? AppImages.assetDeluxeOcean
        : AppImages.assetStandardRoom;
    final imagePath = room.imageUrl.trim().isEmpty
        ? fallbackAsset
        : room.imageUrl.trim();
    final detailText = room.amenities.isNotEmpty
        ? room.amenities.take(2).join(' · ')
        : room.description;
    final isAvailable = room.units > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AppImages.buildImage(
                pathOrUrl: imagePath,
                fallbackUrl: hotel.imageUrl,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isAvailable ? 'Available now' : 'Sold out',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            detailText.isEmpty ? hotel.location : detailText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${room.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          '/ NIGHT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (room.units > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${room.units} rooms available',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: !isAvailable
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewBookingScreen(
                                hotel: hotel,
                                room: room,
                                repository: repository,
                                initialCheckIn: initialCheckIn,
                                initialCheckOut: initialCheckOut,
                                initialAdults: initialAdults,
                                initialChildren: initialChildren,
                              ),
                            ),
                          ),
                    child: const Text(
                      'SELECT ROOM',
                      style: TextStyle(fontSize: 13, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomMessage extends StatelessWidget {
  const _RoomMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Text(
    message,
    textAlign: TextAlign.center,
    style: TextStyle(color: isError ? Colors.red : AppColors.textSecondary),
  );
}
