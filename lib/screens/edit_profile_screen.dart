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
  String _photoUrl = '';

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
          photoUrl: _photoUrl,
        ),
      );
      await user.updateDisplayName(_nameController.text.trim());
      if (user.photoURL != (_photoUrl.isEmpty ? null : _photoUrl)) {
        await user.updatePhotoURL(_photoUrl.isEmpty ? null : _photoUrl);
      }
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

  Future<void> _changePhoto() async {
    final controller = TextEditingController(text: _photoUrl);
    final photoUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change profile photo'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Public image URL',
            hintText: 'https://example.com/photo.jpg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Remove'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (photoUrl != null && mounted) {
      setState(() {
        _photoUrl = photoUrl.trim();
        _errorMessage = null;
      });
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
              _photoUrl = profile?.photoUrl.isNotEmpty == true
                  ? profile!.photoUrl
                  : user.photoURL ?? '';
              _profileLoaded = true;
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: SizedBox(
                                width: 96,
                                height: 96,
                                child: _photoUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 54,
                                        color: AppColors.primaryDark,
                                      )
                                    : Image.network(
                                        _photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.person,
                                          size: 54,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Material(
                            color: AppColors.primaryDark,
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'Change profile photo',
                              onPressed: _changePhoto,
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _changePhoto,
                        child: const Text('CHANGE PROFILE PHOTO'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _ProfileFieldLabel('FULL NAME'),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),
                const _ProfileFieldLabel('PHONE NUMBER'),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),
                const _ProfileFieldLabel('EMAIL ADDRESS'),
                TextFormField(
                  initialValue: user.email ?? '',
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Email managed by sign-in',
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
                      : const Text('SAVE CHANGES'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileFieldLabel extends StatelessWidget {
  const _ProfileFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.7,
        color: AppColors.textSecondary,
      ),
    ),
  );
}
