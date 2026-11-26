import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/hotel_repository.dart';
import '../data/auth_session.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.repository = const FirestoreHotelRepository(),
  });

  final HotelRepository repository;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _profileLoaded = false;
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save(User user) async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter your name.');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.saveProfile(
        UserProfile(
          uid: user.uid,
          name: _nameController.text.trim(),
          email: user.email ?? '',
          phone: _phoneController.text.trim(),
        ),
      );
      await user.updateDisplayName(_nameController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not update account: ${error.message ?? error.code}',
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not save profile: ${error.message ?? error.code}',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = currentFirebaseUserOrNull();
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view and edit your profile.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: widget.repository.watchProfile(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not load profile: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (!snapshot.hasData &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final profile = snapshot.data;
            if (!_profileLoaded) {
              _nameController.text = profile?.name ?? user.displayName ?? '';
              _phoneController.text = profile?.phone ?? '';
              _profileLoaded = true;
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: CircleAvatar(
                    radius: 46,
                    child: Icon(Icons.person, size: 52),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: user.email ?? '',
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email address (managed by sign-in)',
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : () => _save(user),
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Save changes'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
