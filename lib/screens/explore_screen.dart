import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/auth_session.dart';
import '../data/hotel_repository.dart';
import '../resources/app_resources.dart';
import 'resort_detail_screen.dart';
import 'destination_filter_screen.dart';

class ExploreScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final HotelRepository hotelRepository;

  const ExploreScreen({
    super.key,
    this.onOpenDrawer,
    this.hotelRepository = const FirestoreHotelRepository(),
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final Set<String> _savedHotelIds = {};
  StreamSubscription<List<Hotel>>? _savedSubscription;
  final User? _user = currentFirebaseUserOrNull();
  late final Stream<List<Hotel>> _hotelStream;

  @override
  void initState() {
    super.initState();
    _hotelStream = widget.hotelRepository.watchHotels();
    final user = _user;
    if (user != null) {
      _savedSubscription = widget.hotelRepository
          .watchSavedHotels(user.uid)
          .listen((hotels) {
            if (!mounted) return;
            setState(() {
              _savedHotelIds
                ..clear()
                ..addAll(hotels.map((hotel) => hotel.id));
            });
          });
    }
  }

  @override
  void dispose() {
    _savedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleSaved(Hotel hotel) async {
    final user = _user;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to save a stay.')));
      return;
    }
    try {
      await widget.hotelRepository.setHotelSaved(
        user.uid,
        hotel.id,
        !_savedHotelIds.contains(hotel.id),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update saved stay: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DestinationFilterScreen(
                        repository: widget.hotelRepository,
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'City, Landmark, or Name',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section Header
              const Text(
                'Recommended for You',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Exclusive stays curated for your next adventure',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              _buildHotelList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotelList(BuildContext context) {
    return StreamBuilder<List<Hotel>>(
      stream: _hotelStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Unable to load hotels: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final hotels = snapshot.data!;
        if (hotels.isEmpty) {
          return const Text(
            'No hotels have been added yet.',
            style: TextStyle(color: AppColors.textSecondary),
          );
        }

        return Column(
          children: [
            for (final hotel in hotels) ...[
              _buildHotelCard(context, hotel),
              const SizedBox(height: 20),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHotelCard(BuildContext context, Hotel hotel) {
    final title = hotel.title;
    final imagePath = hotel.imageUrl.trim().isEmpty
        ? AppImages.assetAzureVista
        : hotel.imageUrl.trim();
    final rating = hotel.rating.toStringAsFixed(1);
    final isLiked = _savedHotelIds.contains(hotel.id);
    final location = hotel.location;
    final price = '₹${hotel.price.toStringAsFixed(0)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Heart Icon
          Stack(
            children: [
              AppImages.buildImage(
                pathOrUrl: imagePath,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: isLiked
                        ? 'Remove from saved escapes'
                        : 'Save escape',
                    onPressed: () => _toggleSaved(hotel),
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked
                          ? Colors.red.shade400
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Details Padding
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.black, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Location
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 14),
                // Price & Book Now Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(color: AppColors.textPrimary),
                          children: [
                            TextSpan(
                              text: price,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: '/night',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResortDetailScreen(
                                hotel: hotel,
                                repository: widget.hotelRepository,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
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
