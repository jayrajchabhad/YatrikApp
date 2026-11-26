import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/hotel_repository.dart';
import '../../data/auth_session.dart';
import '../../theme/app_theme.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({
    super.key,
    this.repository = const FirestoreHotelRepository(),
  });

  final HotelRepository repository;

  Future<void> _editProfile(
    BuildContext context,
    User user,
    UserProfile? profile,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminProfileEditor(
        repository: repository,
        user: user,
        profile: profile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = currentFirebaseUserOrNull();
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Sign in with an admin account to view this profile.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: repository.watchProfile(user.uid),
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
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Admin Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 42,
                  child: Text(
                    (profile?.name ?? user.displayName ?? user.email ?? 'A')
                        .characters
                        .first
                        .toUpperCase(),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(height: 20),
                _ProfileRow(
                  label: 'Name',
                  value: profile?.name ?? user.displayName ?? '',
                ),
                _ProfileRow(label: 'Email', value: user.email ?? ''),
                _ProfileRow(label: 'Phone', value: profile?.phone ?? ''),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _editProfile(context, user, profile),
                  child: const Text('Edit profile'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminProfileEditor extends StatefulWidget {
  const _AdminProfileEditor({
    required this.repository,
    required this.user,
    required this.profile,
  });

  final HotelRepository repository;
  final User user;
  final UserProfile? profile;

  @override
  State<_AdminProfileEditor> createState() => _AdminProfileEditorState();
}

class _AdminProfileEditorState extends State<_AdminProfileEditor> {
  late final _nameController = TextEditingController(
    text: widget.profile?.name ?? widget.user.displayName ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.profile?.phone ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveProfile(
        UserProfile(
          uid: widget.user.uid,
          name: _nameController.text.trim(),
          email: widget.user.email ?? '',
          phone: _phoneController.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = error.message ?? error.code);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: Text(value.isEmpty ? 'Not provided' : value),
  );
}
