import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/hotel_repository.dart';
import '../../resources/app_images.dart';
import '../../theme/app_theme.dart';

class AdminHotelsScreen extends StatefulWidget {
  const AdminHotelsScreen({
    super.key,
    this.repository = const FirestoreHotelRepository(),
  });

  final HotelRepository repository;

  @override
  State<AdminHotelsScreen> createState() => _AdminHotelsScreenState();
}

class _AdminHotelsScreenState extends State<AdminHotelsScreen> {
  late final Stream<List<Hotel>> _hotelStream;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _hotelStream = widget.repository.watchHotels();
  }

  Future<void> _openAddHotelForm() async {
    final wasAdded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HotelEditorSheet(repository: widget.repository),
    );

    if (wasAdded == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hotel saved successfully.')),
      );
    }
  }

  Future<void> _openEditHotelForm(Hotel hotel) async {
    final wasUpdated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _HotelEditorSheet(repository: widget.repository, hotel: hotel),
    );
    if (wasUpdated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hotel updated successfully.')),
      );
    }
  }

  Future<void> _deleteHotel(Hotel hotel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete hotel?'),
        content: Text('Remove ${hotel.title} from the catalog?'),
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
      await widget.repository.deleteHotel(hotel.id);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete hotel: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  Future<void> _seedDemoCatalog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add demo hotels and rooms?'),
        content: const Text(
          'This adds sample listings and room categories that do not already '
          'exist. Existing records will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add demo data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSeeding = true);
    try {
      final addedCount = await widget.repository.seedDemoCatalog();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            addedCount == 0
                ? 'Demo records already exist; nothing was changed.'
                : 'Added $addedCount demo catalog records (hotels and rooms).',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not add demo data: ${error.message ?? error.code}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddHotelForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Hotel'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Master of\nHotels',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add hotel listings to Firestore and manage the stays shown in Explore.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSeeding ? null : _seedDemoCatalog,
                  icon: _isSeeding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    _isSeeding
                        ? 'Adding demo data…'
                        : 'Add demo hotels & rooms',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildHotelList(),
              const SizedBox(height: 84),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotelList() {
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
            'No hotels yet. Tap Add Hotel to create the first listing.',
            style: TextStyle(color: AppColors.textSecondary),
          );
        }

        return Column(
          children: [
            for (final hotel in hotels) ...[
              _buildHotelCard(
                hotel,
                onEdit: () => _openEditHotelForm(hotel),
                onDelete: () => _deleteHotel(hotel),
              ),
              const SizedBox(height: 20),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHotelCard(
    Hotel hotel, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final imagePath = hotel.imageUrl.trim().isEmpty
        ? AppImages.assetAzureVista
        : hotel.imageUrl.trim();

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
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hotel.propertyType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
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
                Text(
                  'ID: ${hotel.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hotel.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hotel.location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, size: 17),
                        const SizedBox(width: 4),
                        Text(
                          hotel.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      '₹${hotel.price.toStringAsFixed(0)} / night',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
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

class _HotelEditorSheet extends StatefulWidget {
  const _HotelEditorSheet({required this.repository, this.hotel});

  final HotelRepository repository;
  final Hotel? hotel;

  @override
  State<_HotelEditorSheet> createState() => _HotelEditorSheetState();
}

class _HotelEditorSheetState extends State<_HotelEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(
    text: widget.hotel?.title ?? '',
  );
  late final _locationController = TextEditingController(
    text: widget.hotel?.location ?? '',
  );
  late final _ratingController = TextEditingController(
    text: (widget.hotel?.rating ?? 4.5).toString(),
  );
  late final _priceController = TextEditingController(
    text: widget.hotel?.price.toString() ?? '',
  );
  late final _imageUrlController = TextEditingController(
    text: widget.hotel?.imageUrl ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.hotel?.description ?? '',
  );
  late final _typeController = TextEditingController(
    text: widget.hotel?.propertyType ?? 'Hotel',
  );
  late final _amenitiesController = TextEditingController(
    text: widget.hotel?.amenities.join(', ') ?? '',
  );
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _ratingController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  Future<void> _saveHotel() async {
    if (!_formKey.currentState!.validate()) return;

    final rating = double.tryParse(_ratingController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    if (rating == null || price == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final hotel = Hotel(
        id: widget.hotel?.id ?? '',
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        rating: rating,
        price: price,
        imageUrl: _imageUrlController.text.trim(),
        description: _descriptionController.text.trim(),
        propertyType: _typeController.text.trim(),
        amenities: _amenitiesController.text
            .split(',')
            .map((amenity) => amenity.trim())
            .where((amenity) => amenity.isNotEmpty)
            .toList(),
      );
      if (widget.hotel == null) {
        await widget.repository.addHotel(hotel);
      } else {
        await widget.repository.updateHotel(hotel);
      }
      if (mounted) Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not add hotel: ${error.message ?? error.code}';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.hotel == null ? 'Add a hotel' : 'Edit hotel',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _typeController,
                label: 'Stay type (Hotel, Resort, Villa...)',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                label: 'Hotel name',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _ratingController,
                label: 'Rating (0–5)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final rating = double.tryParse(value?.trim() ?? '');
                  if (rating == null || rating < 0 || rating > 5) {
                    return 'Enter a rating from 0 to 5.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _priceController,
                label: 'Price per night (INR)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');
                  if (price == null || price <= 0) {
                    return 'Enter a price greater than zero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _imageUrlController,
                label: 'Image URL (optional)',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description (optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _amenitiesController,
                label: 'Amenities (comma separated)',
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveHotel,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.hotel == null ? 'Save hotel' : 'Update hotel',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required.';
    return null;
  }
}
