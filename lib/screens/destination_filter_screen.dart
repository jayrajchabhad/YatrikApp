import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/auth_session.dart';
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
  static const _propertyTypes = ['Hotel', 'Villa', 'Apartment', 'Resort'];

  final _searchController = TextEditingController();
  final _resultsKey = GlobalKey();
  final Set<String> _savedHotelIds = {};
  final _user = currentFirebaseUserOrNull();
  StreamSubscription<List<Hotel>>? _savedSubscription;
  String _propertyType = 'All';
  double _minimumRating = 0;
  late final Stream<List<Hotel>> _hotels = widget.repository.watchHotels();

  @override
  void initState() {
    super.initState();
    final user = _user;
    if (user != null) {
      _savedSubscription = widget.repository.watchSavedHotels(user.uid).listen((
        hotels,
      ) {
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

  Future<void> _toggleSaved(Hotel hotel) async {
    final user = _user;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to save a stay.')));
      return;
    }
    try {
      await widget.repository.setHotelSaved(
        user.uid,
        hotel.id,
        !_savedHotelIds.contains(hotel.id),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update saved stay: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _propertyType = 'All';
      _minimumRating = 0;
    });
  }

  void _showResults() {
    final targetContext = _resultsKey.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        title: const Text('Yatrik'),
      ),
      body: StreamBuilder<List<Hotel>>(
        stream: _hotels,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Message(
              'Could not load stays: ${snapshot.error}',
              isError: true,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allHotels = snapshot.data!;
          final hotels = _filter(allHotels);
          final destination = _destinationTitle(hotels);
          final description = hotels.isEmpty
              ? 'Try another destination or adjust your filters to find a stay.'
              : hotels.first.description.isNotEmpty
              ? hotels.first.description
              : 'Explore stays in ${hotels.first.location} and find a place for your next journey.';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'City, landmark, or hotel name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
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
              const SizedBox(height: 12),
              _buildFilterPanel(),
              const SizedBox(height: 22),
              const Text(
                'SELECTED DESTINATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                destination,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Container(key: _resultsKey),
              if (hotels.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    'No stays match these filters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...hotels.map((hotel) => _hotelCard(context, hotel)),
            ],
          );
        },
      ),
    );
  }

  String _destinationTitle(List<Hotel> hotels) {
    final search = _searchController.text.trim();
    if (search.isNotEmpty) return search;
    if (hotels.isEmpty) return 'No matching stays';
    return hotels.first.location.split('·').first.trim();
  }

  Widget _buildFilterPanel() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'STAR RATING',
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
              runSpacing: 8,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final selected = _minimumRating == rating;
                return ChoiceChip(
                  label: Text('$rating ★'),
                  selected: selected,
                  onSelected: (_) => setState(
                    () => _minimumRating = selected ? 0 : rating.toDouble(),
                  ),
                  selectedColor: AppColors.primaryNavy,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primaryNavy
                        : AppColors.borderLight,
                  ),
                  showCheckmark: false,
                );
              }),
            ),
            const SizedBox(height: 14),
            const Text(
              'PROPERTY TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.8,
              children: _propertyTypes
                  .map((type) => _propertyTypeButton(type))
                  .toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _showResults,
                child: const Text('SHOW RESULTS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertyTypeButton(String type) {
    final selected = _propertyType == type;
    return OutlinedButton(
      onPressed: () => setState(() => _propertyType = selected ? 'All' : type),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.primaryNavy : Colors.white,
        foregroundColor: selected ? Colors.white : AppColors.textPrimary,
        side: BorderSide(
          color: selected ? AppColors.primaryNavy : AppColors.borderLight,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _hotelCard(BuildContext context, Hotel hotel) {
    final saved = _savedHotelIds.contains(hotel.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AppImages.buildImage(
                pathOrUrl: hotel.imageUrl.trim().isEmpty
                    ? AppImages.assetAzureVista
                    : hotel.imageUrl.trim(),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: saved ? 'Remove saved stay' : 'Save stay',
                    onPressed: () => _toggleSaved(hotel),
                    icon: Icon(
                      saved ? Icons.favorite : Icons.favorite_border,
                      color: saved ? Colors.red : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
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
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.accentGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hotel.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${hotel.propertyType} · ${hotel.location}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '₹${hotel.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const TextSpan(
                              text: ' / night',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
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
                      child: const Text('View Details'),
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
