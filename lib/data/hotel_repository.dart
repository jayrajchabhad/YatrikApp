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

abstract interface class HotelRepository {
  Stream<List<Hotel>> watchHotels();
  Future<void> addHotel(Hotel hotel);
  Future<void> updateHotel(Hotel hotel);
  Future<void> deleteHotel(String id);

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
