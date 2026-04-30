import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TeacherListPage extends StatefulWidget {
  const TeacherListPage({super.key});

  @override
  State<TeacherListPage> createState() => _TeacherListPageState();
}

class _TeacherListPageState extends State<TeacherListPage> {
  final CollectionReference _teachersRef = FirebaseFirestore.instance
      .collection('teachers');

  Future<void> _sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(msg: 'Password reset email sent to $email');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to send reset email: $e');
    }
  }

  Future<void> _deleteTeacher(String uid, String email) async {
    try {
      await _teachersRef.doc(uid).delete();
      Fluttertoast.showToast(
        msg:
            'Firestore record deleted. Auth deletion requires server-side support.',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to delete teacher: $e');
    }
  }

  void _confirmDelete(String uid, String email) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Teacher'),
            content: Text('Are you sure you want to delete $email?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteTeacher(uid, email);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _confirmPasswordReset(String email) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Password'),
            content: Text('Send password reset email to $email?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendPasswordReset(email);
                },
                child: const Text('Send'),
              ),
            ],
          ),
    );
  }

  // EDIT FIELD HELPER
  void _editField(Map<String, dynamic> teacher, String field, String uid) {
    final controller = TextEditingController(text: teacher[field] ?? '');
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Edit $field'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: field),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newValue = controller.text.trim();
                  await _teachersRef.doc(uid).update({field: newValue});
                  setState(() {
                    teacher[field] = newValue;
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teachers',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _teachersRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No teachers registered.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final uid = docs[index].id;
                    final email = data['email'] ?? '';
                    final block = data['block'] ?? '';
                    final lastLogin =
                        data['lastLogin'] != null
                            ? (data['lastLogin'] as Timestamp).toDate()
                            : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(data['name'] ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            GestureDetector(
                              onTap: () => _editField(data, 'block', uid),
                              child: Text(
                                'Block: ${block.isNotEmpty ? block : "-"}',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            if (lastLogin != null)
                              Text('Last login: ${lastLogin.toLocal()}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.email_outlined),
                              tooltip: 'Send Password Reset',
                              onPressed: () => _confirmPasswordReset(email),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete Teacher',
                              onPressed: () => _confirmDelete(uid, email),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        dense: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
