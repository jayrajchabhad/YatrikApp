import 'package:cloud_firestore/cloud_firestore.dart';

class Hotel {
  const Hotel({
    required this.id,
    required this.title,
    required this.location,
    required this.rating,
    required this.price,
    required this.imageUrl,
    this.description = '',
    this.propertyType = 'Hotel',
    this.amenities = const [],
  });

  final String id;
  final String title;
  final String location;
  final double rating;
  final double price;
  final String imageUrl;
  final String description;
  final String propertyType;
  final List<String> amenities;

  factory Hotel.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Hotel(
      id: document.id,
      title: _readString(data, 'title', fallback: 'Untitled stay'),
      location: _readString(data, 'location'),
      rating: _readDouble(data, 'rating'),
      price: _readDouble(data, 'price'),
      imageUrl: _readString(data, 'imageUrl'),
      description: _readString(data, 'description'),
      propertyType: _readString(data, 'propertyType', fallback: 'Hotel'),
      amenities: _readStringList(data['amenities']),
    );
  }

  Map<String, Object?> toMap() => {
    'title': title,
    'location': location,
    'rating': rating,
    'price': price,
    'imageUrl': imageUrl,
    'description': description,
    'propertyType': propertyType,
    'amenities': amenities,
  };
}

class RoomType {
  const RoomType({
    required this.id,
    required this.hotelId,
    required this.hotelTitle,
    required this.title,
    required this.price,
    required this.units,
    this.description = '',
    this.imageUrl = '',
    this.amenities = const [],
  });

  final String id;
  final String hotelId;
  final String hotelTitle;
  final String title;
  final double price;
  final int units;
  final String description;
  final String imageUrl;
  final List<String> amenities;

  factory RoomType.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return RoomType(
      id: document.id,
      hotelId: _readString(data, 'hotelId'),
      hotelTitle: _readString(data, 'hotelTitle'),
      title: _readString(data, 'title', fallback: 'Room'),
      price: _readDouble(data, 'price'),
      units: _readInt(data, 'units'),
      description: _readString(data, 'description'),
      imageUrl: _readString(data, 'imageUrl'),
      amenities: _readStringList(data['amenities']),
    );
  }

  Map<String, Object?> toMap() => {
    'hotelId': hotelId,
    'hotelTitle': hotelTitle,
    'title': title,
    'price': price,
    'units': units,
    'description': description,
    'imageUrl': imageUrl,
    'amenities': amenities,
  };
}

class Booking {
  const Booking({
    this.id = '',
    required this.userId,
    required this.guestName,
    required this.guestEmail,
    required this.hotelId,
    required this.hotelTitle,
    required this.hotelLocation,
    required this.hotelImageUrl,
    required this.roomId,
    required this.roomTitle,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.total,
    required this.paymentMethod,
    this.status = 'PENDING',
    this.createdAt,
  });

  Booking withId(String bookingId) => Booking(
    id: bookingId,
    userId: userId,
    guestName: guestName,
    guestEmail: guestEmail,
    hotelId: hotelId,
    hotelTitle: hotelTitle,
    hotelLocation: hotelLocation,
    hotelImageUrl: hotelImageUrl,
    roomId: roomId,
    roomTitle: roomTitle,
    checkIn: checkIn,
    checkOut: checkOut,
    adults: adults,
    children: children,
    total: total,
    paymentMethod: paymentMethod,
    status: status,
    createdAt: createdAt,
  );

  final String id;
  final String userId;
  final String guestName;
  final String guestEmail;
  final String hotelId;
  final String hotelTitle;
  final String hotelLocation;
  final String hotelImageUrl;
  final String roomId;
  final String roomTitle;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final double total;
  final String paymentMethod;
  final String status;
  final DateTime? createdAt;

  factory Booking.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAtValue = data['createdAt'];
    return Booking(
      id: document.id,
      userId: _readString(data, 'userId'),
      guestName: _readString(data, 'guestName'),
      guestEmail: _readString(data, 'guestEmail'),
      hotelId: _readString(data, 'hotelId'),
      hotelTitle: _readString(data, 'hotelTitle', fallback: 'Stay'),
      hotelLocation: _readString(data, 'hotelLocation'),
      hotelImageUrl: _readString(data, 'hotelImageUrl'),
      roomId: _readString(data, 'roomId'),
      roomTitle: _readString(data, 'roomTitle', fallback: 'Room'),
      checkIn: _readString(data, 'checkIn'),
      checkOut: _readString(data, 'checkOut'),
      adults: _readInt(data, 'adults', fallback: 1),
      children: _readInt(data, 'children'),
      total: _readDouble(data, 'total'),
      paymentMethod: _readString(data, 'paymentMethod'),
      status: _readString(data, 'status', fallback: 'PENDING'),
      createdAt: createdAtValue is Timestamp ? createdAtValue.toDate() : null,
    );
  }

  Map<String, Object?> toMap() => {
    'userId': userId,
    'guestName': guestName,
    'guestEmail': guestEmail,
    'hotelId': hotelId,
    'hotelTitle': hotelTitle,
    'hotelLocation': hotelLocation,
    'hotelImageUrl': hotelImageUrl,
    'roomId': roomId,
    'roomTitle': roomTitle,
    'checkIn': checkIn,
    'checkOut': checkOut,
    'adults': adults,
    'children': children,
    'total': total,
    'paymentMethod': paymentMethod,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class Review {
  const Review({
    this.id = '',
    required this.userId,
    required this.userName,
    required this.hotelId,
    required this.hotelTitle,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String hotelId;
  final String hotelTitle;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  factory Review.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAtValue = data['createdAt'];
    return Review(
      id: document.id,
      userId: _readString(data, 'userId'),
      userName: _readString(data, 'userName', fallback: 'Traveler'),
      hotelId: _readString(data, 'hotelId'),
      hotelTitle: _readString(data, 'hotelTitle', fallback: 'Stay'),
      rating: _readDouble(data, 'rating'),
      comment: _readString(data, 'comment'),
      createdAt: createdAtValue is Timestamp ? createdAtValue.toDate() : null,
    );
  }

  Map<String, Object?> toMap() => {
    'userId': userId,
    'userName': userName,
    'hotelId': hotelId,
    'hotelTitle': hotelTitle,
    'rating': rating,
    'comment': comment,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl = '',
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;

  factory UserProfile.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return UserProfile(
      uid: document.id,
      name: _readString(data, 'name'),
      email: _readString(data, 'email'),
      phone: _readString(data, 'phone'),
      photoUrl: _readString(data, 'photoUrl'),
    );
  }

  Map<String, Object?> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

const demoHotels = <Hotel>[
  Hotel(
    id: 'demo_alpine_glass_loft',
    title: 'Alpine Glass Loft',
    location: 'Zermatt, Switzerland · Ski-in Access',
    rating: 4.8,
    price: 3200,
    imageUrl:
        'https://images.unsplash.com/photo-1518780664697-55e3ad937233?q=80&w=1000&auto=format&fit=crop',
    description:
        'A private mountain hideaway framed by alpine peaks, designed for slow mornings and effortless access to the slopes.',
    propertyType: 'Villa',
    amenities: ['Mountain view', 'Fireplace', 'Ski access', 'Breakfast'],
  ),
  Hotel(
    id: 'demo_azure_haven_resort',
    title: 'Azure Haven Resort',
    location: 'Malé Atoll, Maldives · Overwater Bungalow',
    rating: 4.9,
    price: 8500,
    imageUrl:
        'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?q=80&w=1000&auto=format&fit=crop',
    description:
        'Overwater villas, clear lagoon views, and private-island hospitality create a serene escape in the heart of the Maldives.',
    propertyType: 'Resort',
    amenities: ['Private beach', 'Ocean view', 'Snorkelling', 'Spa'],
  ),
  Hotel(
    id: 'demo_villa_seraphina',
    title: 'Villa Seraphina',
    location: 'Positano, Italy · Amalfi Coast',
    rating: 4.8,
    price: 6900,
    imageUrl:
        'https://images.unsplash.com/photo-1533105079780-92b9be482077?q=80&w=1000&auto=format&fit=crop',
    description:
        'A coastal villa surrounded by lemon groves and pastel rooftops, with a terrace made for long evenings above the sea.',
    propertyType: 'Villa',
    amenities: ['Sea view', 'Terrace', 'Breakfast', 'Pool'],
  ),
  Hotel(
    id: 'demo_aman_i_khas',
    title: 'Aman-i-Khas',
    location: 'Sawai Madhopur, Rajasthan · India',
    rating: 4.9,
    price: 14250,
    imageUrl:
        'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?q=80&w=1000&auto=format&fit=crop',
    description:
        'An intimate wilderness camp near Ranthambore, pairing quiet luxury with guided days among the forest and its wildlife.',
    propertyType: 'Resort',
    amenities: ['Safari access', 'Private tent', 'Dining', 'Pool'],
  ),
];

const demoRooms = <RoomType>[
  RoomType(
    id: 'demo_alpine_glass_loft',
    hotelId: 'demo_alpine_glass_loft',
    hotelTitle: 'Alpine Glass Loft',
    title: 'Glass Loft',
    price: 3200,
    units: 5,
    description: 'Panoramic mountain view · King bed · Fireplace',
    imageUrl:
        'https://images.unsplash.com/photo-1618773928121-c32242e63f39?q=80&w=900&auto=format&fit=crop',
    amenities: ['King bed', 'Fireplace', 'Mountain view'],
  ),
  RoomType(
    id: 'demo_alpine_glass_suite',
    hotelId: 'demo_alpine_glass_loft',
    hotelTitle: 'Alpine Glass Loft',
    title: 'Alpine View Suite',
    price: 5400,
    units: 2,
    description: 'Private terrace · King bed · Ski storage',
    imageUrl:
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?q=80&w=900&auto=format&fit=crop',
    amenities: ['Terrace', 'King bed', 'Ski storage'],
  ),
  RoomType(
    id: 'demo_azure_haven_bungalow',
    hotelId: 'demo_azure_haven_resort',
    hotelTitle: 'Azure Haven Resort',
    title: 'Overwater Bungalow',
    price: 8500,
    units: 6,
    description: 'Private deck · Lagoon access · King bed',
    imageUrl:
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?q=80&w=900&auto=format&fit=crop',
    amenities: ['Private deck', 'Lagoon access', 'King bed'],
  ),
  RoomType(
    id: 'demo_azure_haven_ocean_villa',
    hotelId: 'demo_azure_haven_resort',
    hotelTitle: 'Azure Haven Resort',
    title: 'Ocean Villa',
    price: 12500,
    units: 2,
    description: 'Private plunge pool · Oceanfront deck · Butler service',
    imageUrl:
        'https://images.unsplash.com/photo-1618773928121-c32242e63f39?q=80&w=900&auto=format&fit=crop',
    amenities: ['Plunge pool', 'Oceanfront', 'Butler service'],
  ),
  RoomType(
    id: 'demo_villa_seraphina_garden',
    hotelId: 'demo_villa_seraphina',
    hotelTitle: 'Villa Seraphina',
    title: 'Garden Suite',
    price: 6900,
    units: 4,
    description: 'Private garden · Queen bed · Terrace breakfast',
    imageUrl:
        'https://images.unsplash.com/photo-1618773928121-c32242e63f39?q=80&w=900&auto=format&fit=crop',
    amenities: ['Private garden', 'Queen bed', 'Breakfast'],
  ),
  RoomType(
    id: 'demo_aman_khas_luxury_tent',
    hotelId: 'demo_aman_i_khas',
    hotelTitle: 'Aman-i-Khas',
    title: 'Luxury Tent',
    price: 14250,
    units: 3,
    description: 'Private deck · King bed · Safari camp experience',
    imageUrl:
        'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?q=80&w=900&auto=format&fit=crop',
    amenities: ['Private deck', 'King bed', 'Safari access'],
  ),
];

abstract interface class HotelRepository {
  Stream<List<Hotel>> watchHotels();
  Future<void> addHotel(Hotel hotel);
  Future<void> updateHotel(Hotel hotel);
  Future<void> deleteHotel(String id);
  Future<int> seedDemoCatalog();

  Stream<List<RoomType>> watchRooms({String? hotelId});
  Future<void> saveRoom(RoomType room);
  Future<void> deleteRoom(String id);

  Stream<List<Booking>> watchBookings({String? userId});
  Future<String> createBooking(Booking booking);
  Future<void> updateBookingStatus(String id, String status);
  Future<void> deleteBooking(String id);

  Stream<List<Review>> watchReviews({String? hotelId});
  Future<void> addReview(Review review);
  Future<void> deleteReview(String id);

  Stream<UserProfile?> watchProfile(String uid);
  Future<void> saveProfile(UserProfile profile);
  Stream<List<Hotel>> watchSavedHotels(String uid);
  Future<void> setHotelSaved(String uid, String hotelId, bool saved);
}

class FirestoreHotelRepository implements HotelRepository {
  const FirestoreHotelRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _hotels =>
      _db.collection('hotels');
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('rooms');
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');

  @override
  Stream<List<Hotel>> watchHotels() => _hotels.snapshots().map(
    (snapshot) => snapshot.docs.map(Hotel.fromDocument).toList(),
  );

  @override
  Future<int> seedDemoCatalog() async {
    final hotelReferences = demoHotels.map((hotel) => _hotels.doc(hotel.id));
    final roomReferences = demoRooms.map((room) => _rooms.doc(room.id));

    return _db.runTransaction((transaction) async {
      final hotelSnapshots = await Future.wait(
        hotelReferences.map(transaction.get),
      );
      final roomSnapshots = await Future.wait(
        roomReferences.map(transaction.get),
      );
      var addedCount = 0;

      for (var index = 0; index < demoHotels.length; index++) {
        if (hotelSnapshots[index].exists) continue;
        transaction.set(
          _hotels.doc(demoHotels[index].id),
          demoHotels[index].toMap(),
        );
        addedCount++;
      }

      for (var index = 0; index < demoRooms.length; index++) {
        if (roomSnapshots[index].exists) continue;
        transaction.set(
          _rooms.doc(demoRooms[index].id),
          demoRooms[index].toMap(),
        );
        addedCount++;
      }

      return addedCount;
    });
  }

  @override
  Future<void> addHotel(Hotel hotel) async {
    await _hotels.add(hotel.toMap());
  }

  @override
  Future<void> updateHotel(Hotel hotel) async {
    await _hotels.doc(hotel.id).update(hotel.toMap());
  }

  @override
  Future<void> deleteHotel(String id) async {
    final rooms = await _rooms.where('hotelId', isEqualTo: id).get();
    final references = [
      ...rooms.docs.map((room) => room.reference),
      _hotels.doc(id),
    ];
    for (var start = 0; start < references.length; start += 450) {
      final batch = _db.batch();
      final end = (start + 450).clamp(0, references.length);
      for (final reference in references.sublist(start, end)) {
        batch.delete(reference);
      }
      await batch.commit();
    }
  }

  @override
  Stream<List<RoomType>> watchRooms({String? hotelId}) {
    Query<Map<String, dynamic>> query = _rooms;
    if (hotelId != null) {
      query = query.where('hotelId', isEqualTo: hotelId);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(RoomType.fromDocument).toList(),
    );
  }

  @override
  Future<void> saveRoom(RoomType room) async {
    if (room.id.isEmpty) {
      await _rooms.add(room.toMap());
    } else {
      await _rooms.doc(room.id).set(room.toMap());
    }
  }

  @override
  Future<void> deleteRoom(String id) async {
    await _rooms.doc(id).delete();
  }

  @override
  Stream<List<Booking>> watchBookings({String? userId}) {
    Query<Map<String, dynamic>> query = _bookings;
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(Booking.fromDocument).toList()..sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          }),
    );
  }

  @override
  Future<String> createBooking(Booking booking) async {
    final document = _bookings.doc();
    if (booking.userId.isEmpty || booking.roomId.isEmpty) {
      throw ArgumentError('A signed-in user and room are required to book.');
    }
    await _db.runTransaction((transaction) async {
      final roomReference = _rooms.doc(booking.roomId);
      final roomSnapshot = await transaction.get(roomReference);
      if (!roomSnapshot.exists) {
        throw StateError('This room is no longer available.');
      }
      final roomData = roomSnapshot.data()!;
      final units = _readInt(roomData, 'units');
      if (units <= 0 || _readString(roomData, 'hotelId') != booking.hotelId) {
        throw StateError('This room is no longer available for this hotel.');
      }
      transaction.update(roomReference, {
        'units': units - 1,
        'lastBookingId': document.id,
      });
      transaction.set(document, booking.toMap());
    });
    return document.id;
  }

  @override
  Future<void> updateBookingStatus(String id, String status) async {
    await _db.runTransaction((transaction) async {
      final bookingReference = _bookings.doc(id);
      final bookingSnapshot = await transaction.get(bookingReference);
      if (!bookingSnapshot.exists) {
        throw StateError('This booking no longer exists.');
      }
      final bookingData = bookingSnapshot.data()!;
      final previousStatus = _readString(bookingData, 'status');
      if (previousStatus == status) return;

      final roomId = _readString(bookingData, 'roomId');
      final roomReference = roomId.isEmpty ? null : _rooms.doc(roomId);
      final roomSnapshot = roomReference == null
          ? null
          : await transaction.get(roomReference);
      if (roomReference != null && roomSnapshot!.exists) {
        final units = _readInt(roomSnapshot.data()!, 'units');
        if (previousStatus != 'CANCELLED' && status == 'CANCELLED') {
          transaction.update(roomReference, {
            'units': units + 1,
            'lastBookingId': id,
          });
        } else if (previousStatus == 'CANCELLED' && status != 'CANCELLED') {
          if (units <= 0) {
            throw StateError(
              'No room units are available to restore this booking.',
            );
          }
          transaction.update(roomReference, {
            'units': units - 1,
            'lastBookingId': id,
          });
        }
      }
      transaction.update(bookingReference, {'status': status});
    });
  }

  @override
  Future<void> deleteBooking(String id) async {
    await _db.runTransaction((transaction) async {
      final bookingReference = _bookings.doc(id);
      final bookingSnapshot = await transaction.get(bookingReference);
      if (!bookingSnapshot.exists) return;
      final bookingData = bookingSnapshot.data()!;
      final roomId = _readString(bookingData, 'roomId');
      final roomReference = roomId.isEmpty ? null : _rooms.doc(roomId);
      final roomSnapshot = roomReference == null
          ? null
          : await transaction.get(roomReference);
      if (_readString(bookingData, 'status') != 'CANCELLED' &&
          roomReference != null &&
          roomSnapshot!.exists) {
        transaction.update(roomReference, {
          'units': _readInt(roomSnapshot.data()!, 'units') + 1,
          'lastBookingId': id,
        });
      }
      transaction.delete(bookingReference);
    });
  }

  @override
  Stream<List<Review>> watchReviews({String? hotelId}) {
    Query<Map<String, dynamic>> query = _reviews;
    if (hotelId != null) {
      query = query.where('hotelId', isEqualTo: hotelId);
    }
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(Review.fromDocument).toList()..sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          }),
    );
  }

  @override
  Future<void> addReview(Review review) async {
    await _reviews.add(review.toMap());
  }

  @override
  Future<void> deleteReview(String id) async {
    await _reviews.doc(id).delete();
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map(
        (document) =>
            document.exists ? UserProfile.fromDocument(document) : null,
      );

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _db
        .collection('users')
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  @override
  Stream<List<Hotel>> watchSavedHotels(String uid) {
    final savedRef = _db.collection('users').doc(uid).collection('savedStays');
    return savedRef.snapshots().asyncMap((savedSnapshot) async {
      final documents = await Future.wait(
        savedSnapshot.docs.map((saved) => _hotels.doc(saved.id).get()),
      );
      return documents
          .where((document) => document.exists)
          .map(
            (document) => Hotel(
              id: document.id,
              title: _readString(
                document.data()!,
                'title',
                fallback: 'Untitled stay',
              ),
              location: _readString(document.data()!, 'location'),
              rating: _readDouble(document.data()!, 'rating'),
              price: _readDouble(document.data()!, 'price'),
              imageUrl: _readString(document.data()!, 'imageUrl'),
              description: _readString(document.data()!, 'description'),
              propertyType: _readString(
                document.data()!,
                'propertyType',
                fallback: 'Hotel',
              ),
              amenities: _readStringList(document.data()!['amenities']),
            ),
          )
          .toList();
    });
  }

  @override
  Future<void> setHotelSaved(String uid, String hotelId, bool saved) async {
    final reference = _db
        .collection('users')
        .doc(uid)
        .collection('savedStays')
        .doc(hotelId);
    if (saved) {
      await reference.set({
        'hotelId': hotelId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await reference.delete();
    }
  }
}

String _readString(
  Map<String, dynamic> data,
  String key, {
  String fallback = '',
}) {
  final value = data[key];
  return value is String ? value : fallback;
}

double _readDouble(
  Map<String, dynamic> data,
  String key, {
  double fallback = 0,
}) {
  final value = data[key];
  return value is num ? value.toDouble() : fallback;
}

int _readInt(Map<String, dynamic> data, String key, {int fallback = 0}) {
  final value = data[key];
  return value is num ? value.toInt() : fallback;
}

List<String> _readStringList(Object? value) {
  if (value is! Iterable) return const [];
  return value.whereType<String>().toList();
}
