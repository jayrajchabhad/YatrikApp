import 'package:flutter/material.dart';

import '../data/hotel_repository.dart';
import '../resources/app_images.dart';
import '../theme/app_theme.dart';
import 'resort_detail_screen.dart';

class DestinationFilterScreen extends StatefulWidget {
  const DestinationFilterScreen({
    super.key,
    this.repository = const FirestoreHotelRepository(),
  });

  final HotelRepository repository;

  @override
  State<DestinationFilterScreen> createState() =>
      _DestinationFilterScreenState();
}

class _DestinationFilterScreenState extends State<DestinationFilterScreen> {
  final _searchController = TextEditingController();
  String _propertyType = 'All';
  double _minimumRating = 0;
  late final Stream<List<Hotel>> _hotels = widget.repository.watchHotels();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Hotel> _filter(List<Hotel> hotels) {
    final search = _searchController.text.trim().toLowerCase();
    return hotels.where((hotel) {
      final matchesSearch =
          search.isEmpty ||
          hotel.title.toLowerCase().contains(search) ||
          hotel.location.toLowerCase().contains(search);
      final matchesType =
          _propertyType == 'All' ||
          hotel.propertyType.toLowerCase() == _propertyType.toLowerCase();
      return matchesSearch && matchesType && hotel.rating >= _minimumRating;
    }).toList();
  }

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
        title: const Text('Find a stay'),
      ),
      body: StreamBuilder<List<Hotel>>(
        stream: _hotels,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load stays: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hotels = _filter(snapshot.data!);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'City, landmark, or hotel name',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _propertyType,
                            decoration: const InputDecoration(
                              labelText: 'Property type',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items:
                                const [
                                      'All',
                                      'Hotel',
                                      'Resort',
                                      'Villa',
                                      'Apartment',
                                      'Homestay',
                                    ]
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _propertyType = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<double>(
                            initialValue: _minimumRating,
                            decoration: const InputDecoration(
                              labelText: 'Min rating',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: const [0, 3, 4, 4.5]
                                .map(
                                  (rating) => DropdownMenuItem(
                                    value: rating.toDouble(),
                                    child: Text(
                                      rating == 0 ? 'Any' : '$rating+ stars',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _minimumRating = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: hotels.isEmpty
                    ? const Center(
                        child: Text(
                          'No stays match these filters.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: hotels.length,
                        itemBuilder: (context, index) =>
                            _hotelCard(context, hotels[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hotelCard(BuildContext context, Hotel hotel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImages.buildImage(
            pathOrUrl: hotel.imageUrl.trim().isEmpty
                ? AppImages.assetAzureVista
                : hotel.imageUrl.trim(),
            height: 180,
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
                        hotel.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.star, size: 16),
                    Text(hotel.rating.toStringAsFixed(1)),
                  ],
                ),
                Text(
                  '${hotel.propertyType} · ${hotel.location}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '₹${hotel.price.toStringAsFixed(0)} / night',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResortDetailScreen(
                            hotel: hotel,
                            repository: widget.repository,
                          ),
                        ),
                      ),
                      child: const Text('View details'),
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
