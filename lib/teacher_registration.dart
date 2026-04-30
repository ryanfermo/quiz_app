import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TeacherRegistrationPage extends StatefulWidget {
  final VoidCallback? onNavigateHome;
  const TeacherRegistrationPage({super.key, this.onNavigateHome});

  @override
  State<TeacherRegistrationPage> createState() =>
      _TeacherRegistrationPageState();
}

class _TeacherRegistrationPageState extends State<TeacherRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController(text: 'CITE');
  String _gender = 'Male';

  bool _isSaving = false;

  String _generatePassword(String name, String phone) {
    final shortName = name.replaceAll(' ', '').toLowerCase();
    final last4Phone =
        phone.length >= 4 ? phone.substring(phone.length - 4) : phone;
    return '$shortName$last4Phone@UCU';
  }

  Future<void> _registerTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    final autoPassword = _generatePassword(
      _nameCtrl.text.trim(),
      _phoneCtrl.text.trim(),
    );
    _passwordCtrl.text = autoPassword;

    setState(() => _isSaving = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: autoPassword,
          );

      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(userCredential.user!.uid)
          .set({
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'department': _departmentCtrl.text,
            'gender': _gender,
            'address': _addressCtrl.text.trim(),
            'role': 'teacher',
            'lastLogin': null,
            'createdAt': FieldValue.serverTimestamp(),
          });

      Fluttertoast.showToast(
        msg: 'Teacher registered! Password: $autoPassword',
      );

      _nameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _phoneCtrl.clear();
      _addressCtrl.clear();
      _departmentCtrl.text = 'CITE';
      _gender = 'Male';
      setState(() {});
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? 'Error');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Register Teacher',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Name
                  TextFormField(
                    controller: _nameCtrl,
                    validator: (v) => v!.isEmpty ? 'Enter name' : null,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password (auto-generated)
                  AbsorbPointer(
                    absorbing: true,
                    child: TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Password (Auto-generated)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneCtrl,
                    validator: (v) => v!.isEmpty ? 'Enter phone' : null,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Department (always CITE)
                  TextFormField(
                    controller: _departmentCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.school),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gender
                  DropdownButtonFormField<String>(
                    value: _gender,
                    items:
                        ['Male', 'Female', 'Other']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => _gender = val!),
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.wc),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  TextFormField(
                    controller: _addressCtrl,
                    validator: (v) => v!.isEmpty ? 'Enter address' : null,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _registerTeacher,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFF003366),
                      ),
                      child:
                          _isSaving
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
