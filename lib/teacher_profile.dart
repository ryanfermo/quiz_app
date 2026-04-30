import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color primaryColor = Color(0xFF003366);
const Color accentColor = Color(0xFFFFCC00);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController(text: 'CITE');

  User? _user;
  String? _profilePicBase64;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(_user!.uid)
            .get();

    if (!mounted) return;

    if (doc.exists) {
      final data = doc.data()!;
      _nameCtrl.text = data['name'] ?? '';
      _departmentCtrl.text = data['department'] ?? 'CITE';
      _profilePicBase64 = data['profilePicBase64'];
      setState(() {});
    }
  }

  Future<void> _pickProfilePic() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return;

    final base64String = base64Encode(fileBytes);

    if (!mounted) return;
    setState(() => _profilePicBase64 = base64String);

    // Save Base64 to Firestore
    await FirebaseFirestore.instance
        .collection('teachers')
        .doc(_user!.uid)
        .update({'profilePicBase64': base64String});
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(_user!.uid)
          .update({'name': _nameCtrl.text.trim()});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  await _user!.updatePassword(controller.text.trim());

                  navigator.pop();

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(e.message ?? 'Error changing password'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? profileImage;
    if (_profilePicBase64 != null) {
      profileImage = MemoryImage(base64Decode(_profilePicBase64!));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Card(
                elevation: 4,
                child: Container(
                  width: 600,
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: profileImage,
                              child:
                                  profileImage == null
                                      ? const Icon(Icons.person, size: 60)
                                      : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: _pickProfilePic,
                              color: primaryColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _nameCtrl,
                          validator:
                              (v) => v!.isEmpty ? 'Enter your name' : null,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _departmentCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCC9900),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Change Password'),
                            ),

                            ElevatedButton(
                              onPressed: _isSaving ? null : _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text('Save Changes'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
