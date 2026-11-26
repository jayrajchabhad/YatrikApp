import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/hotel_repository.dart';
import '../../resources/app_images.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_upload_field.dart';

class AdminInventoryScreen extends StatelessWidget {
  const AdminInventoryScreen({
    super.key,
    this.repository = const FirestoreHotelRepository(),
  });

  final HotelRepository repository;

  Future<void> _editRoom(
    BuildContext context,
    List<Hotel> hotels, {
    RoomType? room,
  }) async {
    if (hotels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a hotel before creating room inventory.'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _RoomEditorSheet(repository: repository, hotels: hotels, room: room),
    );
  }

  Future<void> _deleteRoom(BuildContext context, RoomType room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete room category?'),
        content: Text('Remove ${room.title} from ${room.hotelTitle}?'),
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
      await repository.deleteRoom(room.id);
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete room: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  Future<void> _addStarterRooms(BuildContext context) async {
    try {
      final added = await repository.addStarterRoomsForHotelsWithoutRooms();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'Every hotel already has a room category.'
                : 'Added starter rooms for $added hotels.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not add starter rooms: ${error.message ?? error.code}',
          ),
        ),
      );
    }
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
        title: const Text('Room Inventory'),
      ),
      body: StreamBuilder<List<Hotel>>(
        stream: repository.watchHotels(),
        builder: (context, hotelSnapshot) {
          if (hotelSnapshot.hasError) {
            return _ErrorText(
              message: 'Could not load hotels: ${hotelSnapshot.error}',
            );
          }
          if (!hotelSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hotels = hotelSnapshot.data!;
          return StreamBuilder<List<RoomType>>(
            stream: repository.watchRooms(),
            builder: (context, roomSnapshot) {
              if (roomSnapshot.hasError) {
                return _ErrorText(
                  message: 'Could not load inventory: ${roomSnapshot.error}',
                );
              }
              if (!roomSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final rooms = roomSnapshot.data!;
              final hotelsWithRooms = rooms.map((room) => room.hotelId).toSet();
              final hotelsWithoutRooms = hotels
                  .where((hotel) => !hotelsWithRooms.contains(hotel.id))
                  .length;
              final totalUnits = rooms.fold<int>(
                0,
                (total, room) => total + room.units,
              );
              final averageRate = rooms.isEmpty
                  ? 0.0
                  : rooms.fold<double>(0, (total, room) => total + room.price) /
                        rooms.length;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _InventoryMetricCard(
                    label: 'TOTAL INVENTORY',
                    value: '$totalUnits units',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _InventoryMetricCard(
                    label: 'AVERAGE NIGHTLY RATE',
                    value: '₹${averageRate.toStringAsFixed(0)}',
                    subtitle:
                        '${rooms.length} categories across ${hotels.length} hotels',
                    icon: Icons.currency_rupee_rounded,
                  ),
                  if (hotelsWithoutRooms > 0) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$hotelsWithoutRooms ${hotelsWithoutRooms == 1 ? 'hotel has' : 'hotels have'} no room category',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add a sample Standard Room so these stays can be booked.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => _addStarterRooms(context),
                              icon: const Icon(Icons.add_home_outlined),
                              label: const Text('Add missing rooms'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _editRoom(context, hotels),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add category'),
                      ),
                    ],
                  ),
                  if (rooms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No room categories yet. Add one to make a hotel bookable.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ...rooms.map(
                      (room) => Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppImages.buildImage(
                              pathOrUrl: room.imageUrl.trim().isEmpty
                                  ? AppImages.assetStandardRoom
                                  : room.imageUrl.trim(),
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
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (action) {
                                          if (action == 'edit') {
                                            _editRoom(
                                              context,
                                              hotels,
                                              room: room,
                                            );
                                          } else {
                                            _deleteRoom(context, room);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    room.hotelTitle,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (room.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      room.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const Divider(height: 22),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _InventoryField(
                                          label: 'UNIT COUNT',
                                          value: '${room.units}',
                                        ),
                                      ),
                                      Expanded(
                                        child: _InventoryField(
                                          label: 'NIGHTLY RATE',
                                          value:
                                              '₹${room.price.toStringAsFixed(0)}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => _editRoom(
                                        context,
                                        hotels,
                                        room: room,
                                      ),
                                      child: const Text('VIEW DETAILS'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final hotels = await repository.watchHotels().first;
            if (!context.mounted) return;
            await _editRoom(context, hotels);
          } catch (error) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not load hotels: $error')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
    );
  }
}

class _InventoryMetricCard extends StatelessWidget {
  const _InventoryMetricCard({
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
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
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
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
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

class _InventoryField extends StatelessWidget {
  const _InventoryField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

class _RoomEditorSheet extends StatefulWidget {
  const _RoomEditorSheet({
    required this.repository,
    required this.hotels,
    this.room,
  });

  final HotelRepository repository;
  final List<Hotel> hotels;
  final RoomType? room;

  @override
  State<_RoomEditorSheet> createState() => _RoomEditorSheetState();
}

class _RoomEditorSheetState extends State<_RoomEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _hotelId;
  late final _titleController = TextEditingController(
    text: widget.room?.title ?? '',
  );
  late final _priceController = TextEditingController(
    text: widget.room?.price.toString() ?? '',
  );
  late final _unitsController = TextEditingController(
    text: widget.room?.units.toString() ?? '1',
  );
  late final _descriptionController = TextEditingController(
    text: widget.room?.description ?? '',
  );
  late final _imageController = TextEditingController(
    text: widget.room?.imageUrl ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hotelId = widget.room?.hotelId ?? widget.hotels.first.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _unitsController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final hotel = widget.hotels.firstWhere((item) => item.id == _hotelId);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveRoom(
        RoomType(
          id: widget.room?.id ?? '',
          hotelId: hotel.id,
          hotelTitle: hotel.title,
          title: _titleController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          units: int.parse(_unitsController.text.trim()),
          description: _descriptionController.text.trim(),
          imageUrl: _imageController.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? error.code);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.room == null ? 'Add room category' : 'Edit room category',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _hotelId,
              decoration: const InputDecoration(labelText: 'Hotel'),
              items: widget.hotels
                  .map(
                    (hotel) => DropdownMenuItem(
                      value: hotel.id,
                      child: Text(hotel.title),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _hotelId = value);
                    },
            ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Room category'),
              validator: _required,
            ),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price per night (INR)',
              ),
              validator: (value) {
                final price = double.tryParse(value?.trim() ?? '');
                return price == null || price <= 0
                    ? 'Enter a positive price.'
                    : null;
              },
            ),
            TextFormField(
              controller: _unitsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Available units'),
              validator: (value) {
                final units = int.tryParse(value?.trim() ?? '');
                return units == null || units < 0 ? 'Enter 0 or more.' : null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            ImageUploadField(
              storageFolder: 'room-images',
              initialImageUrl: _imageController.text,
              onUploaded: (url) => _imageController.text = url,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Save room'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    ),
  );
}
