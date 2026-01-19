import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/image_service.dart';
import '../../models/user_model.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImageService _imageService = ImageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  UserModel? _userData;
  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userData = await _firestoreService.getUserData(authService.currentUser!.uid);
    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  Future<void> _editName() async {
    final nameController = TextEditingController(text: _userData?.name ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await _firestoreService.updateUserName(authService.currentUser!.uid, newName);
      _loadUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
                );
                return;
              }

              Navigator.pop(context, true);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await authService.changePassword(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
      );

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _updateProfileImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final imageUrl = await _imageService.uploadProfileImage(File(image.path)
      );

      if (imageUrl != null) {
        await _firestoreService.updateUserProfileImage(
          authService.currentUser!.uid,
          imageUrl,
        );
        _loadUserData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userData == null) {
      return const Center(child: Text('Error loading profile'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: _userData!.profileImageUrl != null
                    ? NetworkImage(_userData!.profileImageUrl!)
                    : null,
                child: _userData!.profileImageUrl == null
                    ? Icon(Icons.person, size: 60, color: Colors.blue.shade700)
                    : null,
              ),
              if (_isUploadingImage)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    onPressed: _updateProfileImage,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userData!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Student',
              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(_userData!.email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: const Text('Registration Number'),
                  subtitle: Text(_userData!.regNumber.isEmpty ? 'Not set' : _userData!.regNumber),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Batch'),
                  subtitle: Text(_userData!.batch.isEmpty ? 'Not set' : _userData!.batch),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: const Text('Registered Events'),
                  subtitle: Text('${_userData!.registeredEvents.length} events'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Name'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _editName,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _changePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}