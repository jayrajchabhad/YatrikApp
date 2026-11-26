import 'package:flutter/material.dart';

import '../../data/hotel_repository.dart';
import '../edit_profile_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({
    super.key,
    this.repository = const FirestoreHotelRepository(),
  });

  final HotelRepository repository;

  @override
  Widget build(BuildContext context) => EditProfileScreen(
    repository: repository,
  );
}
