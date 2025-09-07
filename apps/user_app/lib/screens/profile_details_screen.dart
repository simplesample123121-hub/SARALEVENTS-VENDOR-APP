import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/session.dart';
import '../services/profile_service.dart';
import 'package:image_picker/image_picker.dart' as img;
import 'dart:io';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileService _profileService;
  bool _loading = true;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _imageUrl;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserSession>().currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    final p = await _profileService.getProfile(user.id);
    _firstNameController.text = (p?['first_name'] ?? '') as String;
    _lastNameController.text = (p?['last_name'] ?? '') as String;
    _phoneController.text = (p?['phone_number'] ?? '') as String;
    _imageUrl = p?['image_url'] as String?;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<UserSession>().currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    await _profileService.upsertProfile(
      userId: user.id,
      email: user.email ?? '',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      imageUrl: _imageUrl,
    );
    if (mounted) {
      setState(() => _loading = false);
      Navigator.maybePop(context, true);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final user = context.read<UserSession>().currentUser;
    if (user == null) return;
    final picker = img.ImagePicker();
    img.XFile? result;
    try {
      result = await picker.pickImage(source: img.ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    } on PlatformException catch (e) {
      // Some devices/plugins fail to init gallery channel on hot-restart. Fall back to camera.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery unavailable (${e.code}). Opening camera...')),
        );
      }
      result = await picker.pickImage(source: img.ImageSource.camera, maxWidth: 1024, imageQuality: 85);
    }
    if (result == null) return;
    if (!mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final file = File(result.path);
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${result.name.substring(result.name.lastIndexOf('.'))}';
      final publicUrl = await _profileService.uploadProfileImage(
        userId: user.id,
        file: file,
        fileName: fileName,
      );
      if (!mounted) return;
      setState(() => _imageUrl = publicUrl);
      // Auto-save image_url so DB reflects the latest avatar without requiring Save button
      await _profileService.upsertProfile(
        userId: user.id,
        email: user.email ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        imageUrl: publicUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _uploadingImage ? null : () async {
                              try {
                                await _pickAndUploadImage();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to pick image: $e')),
                                  );
                                }
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Colors.grey[100],
                                  backgroundImage: (_imageUrl != null && _imageUrl!.isNotEmpty)
                                      ? NetworkImage(_imageUrl!)
                                      : null,
                                  child: (_imageUrl == null || _imageUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 44, color: Colors.black54)
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: IconButton(
                                    onPressed: _uploadingImage ? null : _pickAndUploadImage,
                                    iconSize: 22,
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                    ),
                                    icon: _uploadingImage
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.edit, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: _uploadingImage ? null : _pickAndUploadImage,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Change profile photo'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Edit your details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'First name'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter first name' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Last name'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter last name' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone number'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _save,
                            child: const Text('Save changes'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
