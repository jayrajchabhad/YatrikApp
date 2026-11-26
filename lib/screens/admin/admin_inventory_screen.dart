import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/hotel_repository.dart';
import '../../theme/app_theme.dart';

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
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${rooms.fold<int>(0, (total, room) => total + room.units)} rooms across ${hotels.length} hotels',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            room.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${room.hotelTitle} · ₹${room.price.toStringAsFixed(0)}/night · ${room.units} units',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') {
                                _editRoom(context, hotels, room: room);
                              } else {
                                _deleteRoom(context, room);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
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
        label: const Text('Add room'),
      ),
    );
  }
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
            TextFormField(
              controller: _imageController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
              ),
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
