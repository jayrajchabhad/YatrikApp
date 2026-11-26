// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yatrik/data/hotel_repository.dart';
import 'package:yatrik/main.dart';
import 'package:yatrik/screens/admin/admin_container_screen.dart';
import 'package:yatrik/screens/admin/admin_hotels_screen.dart';
import 'package:yatrik/screens/admin/admin_inventory_screen.dart';
import 'package:yatrik/screens/main_container_screen.dart';

Widget _mainContainerApp() {
  return MaterialApp(
    home: MainContainerScreen(hotelRepository: _FakeHotelRepository()),
  );
}

void main() {
  testWidgets('Yatrik app loads the welcome screen', (tester) async {
    await tester.pumpWidget(const YatrikApp());

    expect(find.text('Yatrik'), findsAtLeastNWidgets(1));
    expect(find.text('GET STARTED'), findsOneWidget);
  });

  testWidgets(
    'User navigation drawer opens and bookings tab shows sign-in gate',
    (tester) async {
      await tester.pumpWidget(_mainContainerApp());

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScaffoldState>(find.byType(Scaffold).first).isDrawerOpen,
        isTrue,
      );
      await tester.tapAt(const Offset(600, 300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bookings'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to view your bookings.'), findsOneWidget);
    },
  );

  testWidgets('Admin navigation drawer opens', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminContainerScreen(hotelRepository: _FakeHotelRepository()),
      ),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Overview'), findsAtLeastNWidgets(1));
  });

  testWidgets('Admin can submit a hotel listing', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeHotelRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdminHotelsScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Hotel'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hotel name'),
      'Demo Stay',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Location'),
      'Jaipur, India',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price per night (INR)'),
      '2500',
    );
    await tester.tap(find.text('Save hotel'));
    await tester.pumpAndSettle();

    expect(repository.addedHotel?['title'], 'Demo Stay');
    expect(repository.addedHotel?['location'], 'Jaipur, India');
    expect(repository.addedHotel?['rating'], 4.5);
    expect(repository.addedHotel?['price'], 2500);
  });

  testWidgets('Admin can add room inventory for a hotel', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeHotelRepository();
    await tester.pumpWidget(
      MaterialApp(home: AdminInventoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add room'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Room category'),
      'Standard',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price per night (INR)'),
      '2800',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Available units'),
      '5',
    );
    await tester.tap(find.text('Save room'));
    await tester.pumpAndSettle();

    expect(repository.savedRoom?.hotelId, 'hotel-1');
    expect(repository.savedRoom?.title, 'Standard');
    expect(repository.savedRoom?.price, 2800);
    expect(repository.savedRoom?.units, 5);
  });

  testWidgets('Home shows recommendations and resort listings', (tester) async {
    await tester.pumpWidget(_mainContainerApp());
    await tester.pumpAndSettle();

    expect(find.text('Recommended for You'), findsOneWidget);
    expect(find.text('Azure Vista Resort'), findsOneWidget);
    expect(find.text('Azure Haven Resort'), findsOneWidget);
  });

  testWidgets('Saved escapes require a signed-in account', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_mainContainerApp());
    await tester.tap(find.text('Wishlist'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to see saved stays.'), findsOneWidget);
  });

  testWidgets('Destination filter route has a working back control', (
    tester,
  ) async {
    await tester.pumpWidget(_mainContainerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('City, Landmark, or Name'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Recommended for You'), findsOneWidget);
    expect(find.text('Azure Vista Resort'), findsOneWidget);
  });
}

class _FakeHotelRepository implements HotelRepository {
  Map<String, Object?>? addedHotel;
  RoomType? savedRoom;
  final List<Hotel> _hotelList = [
    const Hotel(
      id: 'hotel-1',
      title: 'Azure Vista Resort',
      location: 'Oia, Santorini • 200m to Beach',
      rating: 4.9,
      price: 4500,
      imageUrl: '',
    ),
    const Hotel(
      id: 'hotel-2',
      title: 'Alpine Glass Loft',
      location: 'Zermatt, Switzerland • Ski-in Access',
      rating: 4.8,
      price: 3200,
      imageUrl: '',
    ),
    const Hotel(
      id: 'hotel-3',
      title: 'Azure Haven Resort',
      location: 'Male Atoll, Maldives • Overwater Bungalow',
      rating: 4.9,
      price: 8500,
      imageUrl: '',
    ),
  ];

  @override
  Stream<List<Hotel>> watchHotels() => Stream.value(_hotelList);

  @override
  Future<void> addHotel(Hotel hotel) async {
    addedHotel = hotel.toMap();
    _hotelList.add(hotel);
  }

  @override
  Future<void> updateHotel(Hotel hotel) async {}

  @override
  Future<void> deleteHotel(String id) async {}

  @override
  Stream<List<RoomType>> watchRooms({String? hotelId}) =>
      Stream.value(const []);

  @override
  Future<void> saveRoom(RoomType room) async {
    savedRoom = room;
  }

  @override
  Future<void> deleteRoom(String id) async {}

  @override
  Stream<List<Booking>> watchBookings({String? userId}) =>
      Stream.value(const []);

  @override
  Future<String> createBooking(Booking booking) async => 'booking-1';

  @override
  Future<void> updateBookingStatus(String id, String status) async {}

  @override
  Future<void> deleteBooking(String id) async {}

  @override
  Stream<List<Review>> watchReviews({String? hotelId}) =>
      Stream.value(const []);

  @override
  Future<void> addReview(Review review) async {}

  @override
  Future<void> deleteReview(String id) async {}

  @override
  Stream<UserProfile?> watchProfile(String uid) => Stream.value(null);

  @override
  Future<void> saveProfile(UserProfile profile) async {}

  @override
  Stream<List<Hotel>> watchSavedHotels(String uid) => Stream.value(const []);

  @override
  Future<void> setHotelSaved(String uid, String hotelId, bool saved) async {}
}
