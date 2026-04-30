import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color primaryColor = Color(0xFF003366);
const double cardPadding = 12;

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final int _pageSize = 10;
  int _currentPage = 0;

  String _searchId = '';
  String _selectedBlock = 'All';
  List<String> _blocks = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Edit all student info in one dialog
  void _editStudent(String docId, Map<String, dynamic> data) {
    final firstController = TextEditingController(text: data['firstName']);
    final middleController = TextEditingController(text: data['middleName']);
    final lastController = TextEditingController(text: data['lastName']);
    final idController = TextEditingController(text: data['id']);
    final courseController = TextEditingController(text: data['course']);
    final yearController = TextEditingController(text: data['yearLevel']);
    final sexController = TextEditingController(text: data['sex']);
    final blockController = TextEditingController(text: data['block']);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Edit Student'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextField('ID', idController),
                  _buildTextField('First Name', firstController),
                  _buildTextField('Middle Name', middleController),
                  _buildTextField('Last Name', lastController),
                  _buildTextField('Course', courseController),
                  _buildTextField('Year Level', yearController),
                  _buildTextField('Sex', sexController),
                  _buildTextField('Block', blockController),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('teachers')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('students')
                      .doc(docId)
                      .update({
                        'id': idController.text,
                        'firstName': firstController.text,
                        'middleName': middleController.text,
                        'lastName': lastController.text,
                        'course': courseController.text,
                        'yearLevel': yearController.text,
                        'sex': sexController.text,
                        'block': blockController.text,
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  /// Delete student
  Future<void> _deleteStudent(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Student'),
            content: const Text(
              'Are you sure you want to delete this student?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('students')
          .doc(docId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Student deleted')));
    }
  }

  /// Build search & filter UI outside StreamBuilder
  Widget _buildSearchFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: _searchFocus,
              controller: _searchController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Search by Student ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchId = value.trim();
                  _currentPage = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedBlock,
              decoration: InputDecoration(
                labelText: 'Filter by Block',
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              items:
                  ['All', ..._blocks].map((block) {
                    return DropdownMenuItem(value: block, child: Text(block));
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedBlock = value;
                    _currentPage = 0;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = FirebaseAuth.instance.currentUser!.uid;
    final studentsStream =
        FirebaseFirestore.instance
            .collection('teachers')
            .doc(teacherId)
            .collection('students')
            .snapshots();

    return Column(
      children: [
        _buildSearchFilter(),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: studentsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No students found"));
              }

              // Load block dropdown dynamically
              if (_blocks.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final blocksSet =
                      snapshot.data!.docs
                          .map(
                            (doc) =>
                                (doc.data() as Map<String, dynamic>)['block'] ??
                                '',
                          )
                          .toSet();
                  if (mounted) {
                    setState(() {
                      _blocks =
                          blocksSet
                              .where((b) => (b as String).isNotEmpty)
                              .map((b) => b as String)
                              .toList();
                    });
                  }
                });
              }

              final allStudents = snapshot.data!.docs;

              // Apply search & block filter
              final filteredStudents =
                  allStudents.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final idValue = (data['id'] ?? '').toString();
                    final idMatch =
                        _searchId.isEmpty || idValue.contains(_searchId);
                    final blockMatch =
                        _selectedBlock == 'All' ||
                        (data['block'] ?? '') == _selectedBlock;
                    return idMatch && blockMatch;
                  }).toList();

              final totalPages = (filteredStudents.length / _pageSize).ceil();
              final students =
                  filteredStudents
                      .skip(_currentPage * _pageSize)
                      .take(_pageSize)
                      .toList();

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final data =
                            students[index].data() as Map<String, dynamic>;
                        final docId = students[index].id;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(cardPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${data['firstName'] ?? ''} ${data['middleName'] ?? ''} ${data['lastName'] ?? ''}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    _buildBadge("ID: ${data['id'] ?? ''}"),
                                    _buildBadge(
                                      "Course: ${data['course'] ?? ''}",
                                    ),
                                    _buildBadge(
                                      "Year: ${data['yearLevel'] ?? ''}",
                                    ),
                                    _buildBadge("Sex: ${data['sex'] ?? ''}"),
                                    _buildBadge(
                                      "Block: ${data['block'] ?? ''}",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed:
                                          () => _editStudent(docId, data),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteStudent(docId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed:
                                _currentPage > 0
                                    ? () => setState(() => _currentPage--)
                                    : null,
                          ),
                          Text("${_currentPage + 1} / $totalPages"),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed:
                                _currentPage < totalPages - 1
                                    ? () => setState(() => _currentPage++)
                                    : null,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
