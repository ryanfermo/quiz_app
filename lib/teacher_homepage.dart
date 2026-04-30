import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz_cite_admin/assessment_manager_page.dart';
import 'package:quiz_cite_admin/teacher_cms.dart';
import 'package:quiz_cite_admin/teacher_import_students.dart';
import 'package:quiz_cite_admin/teacher_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_dashboard.dart';
import 'dart:convert';
import 'login_screen.dart';

const Color primaryColor = Color(0xFF003366);
const Color accentColor = Color(0xFFFFCC00);

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _selectedIndex = 0;
  final _pages = [
    const DashboardPage(),
    const ProfilePage(),
    const StudentImportPage(),
    const CMSPage(),
    const AssessmentManagerPage(),
  ];

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Drawer / Sidebar
          Container(
            width: 250,
            color: primaryColor,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('teachers')
                            .doc(_currentUser?.uid)
                            .snapshots(),
                    builder: (context, snapshot) {
                      String name = "Teacher";
                      String email = _currentUser?.email ?? "No Email";
                      ImageProvider? image;

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;

                        name = data['name'] ?? "Teacher";

                        if (data['profilePicBase64'] != null) {
                          image = MemoryImage(
                            base64Decode(data['profilePicBase64']),
                          );
                        }
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: image,
                            child:
                                image == null
                                    ? Icon(
                                      Icons.person,
                                      size: 40,
                                      color: primaryColor,
                                    )
                                    : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                _buildDrawerItem(Icons.dashboard, "Dashboard", 0),
                _buildDrawerItem(Icons.person, "Profile", 1),
                _buildDrawerItem(Icons.upload_file, "Students", 2),
                _buildDrawerItem(Icons.assignment, "Question Bank", 3),
                _buildDrawerItem(Icons.assignment_turned_in, "Assessments", 4),
                const Spacer(),
                _buildDrawerItem(Icons.logout, "Logout", -1, isLogout: true),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(24),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String label,
    int index, {
    bool isLogout = false,
  }) {
    final selected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      selected: selected,
      selectedTileColor: accentColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: accentColor.withValues(alpha: 0.2),
      onTap: () async {
        if (isLogout) {
          await _signOut();
        } else {
          setState(() => _selectedIndex = index);
        }
      },
    );
  }
}
