import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_list_page.dart';

const Color primaryColor = Color(0xFF003366);

class StudentImportPage extends StatefulWidget {
  const StudentImportPage({super.key});

  @override
  State<StudentImportPage> createState() => _StudentImportPageState();
}

class _StudentImportPageState extends State<StudentImportPage> {
  final _formKey = GlobalKey<FormState>();

  final _idCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _yearLevelCtrl = TextEditingController();
  final _sexCtrl = TextEditingController();
  final _blockCtrl = TextEditingController();

  final List<Map<String, String>> _students = [];
  final bool _submitted = false;

  String clean(String value) {
    value = value.trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    return value;
  }

  Future<void> _importCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;

    String content;
    final fileBytes = result.files.first.bytes;
    if (fileBytes != null) {
      content = utf8.decode(fileBytes);
    } else {
      final path = result.files.first.path;
      if (path == null) return;
      content = await File(path).readAsString();
    }

    final lines = content.split('\n');
    final imported = <Map<String, String>>[];

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 7) continue;

      imported.add({
        'id': clean(parts[1]),
        'lastName': clean(parts[2]),
        'firstName': clean(parts[3]),
        'middleName': clean(parts[4]),
        'course': clean(parts[5]),
        'yearLevel': clean(parts[6]),
        'sex': parts.length > 7 ? clean(parts[7]) : '',
        'block': parts.length > 8 ? clean(parts[8]) : '',
      });
    }

    setState(() => _students.addAll(imported));
  }

  void _addStudent() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _students.add({
        'id': _idCtrl.text.trim(),
        'firstName': _firstNameCtrl.text.trim(),
        'middleName': _middleNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'course': _courseCtrl.text.trim(),
        'yearLevel': _yearLevelCtrl.text.trim(),
        'sex': _sexCtrl.text.trim(),
        'block': _blockCtrl.text.trim(),
      });

      _idCtrl.clear();
      _firstNameCtrl.clear();
      _middleNameCtrl.clear();
      _lastNameCtrl.clear();
      _courseCtrl.clear();
      _yearLevelCtrl.clear();
      _sexCtrl.clear();
      _blockCtrl.clear();
    });
  }

  Future<void> _submitAll() async {
    final teacherId = FirebaseAuth.instance.currentUser!.uid;

    final collection = FirebaseFirestore.instance
        .collection('teachers')
        .doc(teacherId)
        .collection('students');

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var student in _students) {
        final docRef = collection.doc(student['id']);
        batch.set(docRef, student);
      }

      await batch.commit();

      setState(() {
        _students.clear();
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Students successfully saved to your account!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving students: $e')));
    }
  }

  void _editField(Map<String, String> student, String field) {
    final controller = TextEditingController(text: student[field]);
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
                onPressed: () {
                  setState(() {
                    student[field] = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
  }) {
    return SizedBox(
      width: 150,
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required ? (v) => v!.isEmpty ? 'Enter $label' : null : null,
      ),
    );
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _courseCtrl.dispose();
    _yearLevelCtrl.dispose();
    _sexCtrl.dispose();
    super.dispose();
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Import Students",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload CSV"),
            onPressed: _importCSV,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      "Add Student Manually",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTextField(_idCtrl, "Student ID", required: true),
                        _buildTextField(
                          _firstNameCtrl,
                          "First Name",
                          required: true,
                        ),
                        _buildTextField(_middleNameCtrl, "MI"),
                        _buildTextField(
                          _lastNameCtrl,
                          "Last Name",
                          required: true,
                        ),
                        _buildTextField(_courseCtrl, "Course", required: true),
                        _buildTextField(
                          _yearLevelCtrl,
                          "Year Level",
                          required: true,
                        ),
                        _buildTextField(_sexCtrl, "Sex", required: true),
                        _buildTextField(_blockCtrl, "Block", required: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _addStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      child: const Text("Add Student"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Student List",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Scrollable DataTable
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Last Name')),
                DataColumn(label: Text('First Name')),
                DataColumn(label: Text('MI')),
                DataColumn(label: Text('Course')),
                DataColumn(label: Text('Year')),
                DataColumn(label: Text('Sex')),
                DataColumn(label: Text('Block')),
                DataColumn(label: Text('Actions')),
              ],
              rows:
                  _students
                      .map(
                        (s) => DataRow(
                          cells: [
                            DataCell(
                              Text(s['id']!),
                              showEditIcon: !_submitted,
                              onTap:
                                  !_submitted
                                      ? () => _editField(s, 'id')
                                      : null,
                            ),
                            DataCell(
                              Text(s['lastName']!),
                              showEditIcon: !_submitted,
                              onTap:
                                  !_submitted
                                      ? () => _editField(s, 'lastName')
                                      : null,
                            ),
                            DataCell(
                              Text(s['firstName']!),
                              showEditIcon: !_submitted,
                              onTap:
                                  !_submitted
                                      ? () => _editField(s, 'firstName')
                                      : null,
                            ),
                            DataCell(
                              Text(s['middleName']!),
                              showEditIcon: !_submitted,
                              onTap:
                                  !_submitted
                                      ? () => _editField(s, 'middleName')
                                      : null,
                            ),
                            DataCell(
                              Text(s['course']!),
                              showEditIcon: !_submitted,
                              onTap:
                                  !_submitted
                                      ? () => _editField(s, 'course')
                                      : null,
                            ),
                            DataCell(
                              Text(s['yearLevel']!),
                              showEditIcon: !_submitted,
                              onTap:
                                  !_submitted
                                      ? () => _editField(s, 'yearLevel')
                                      : null,
                            ),
                            DataCell(
                              Text(s['sex']!),
                              showEditIcon: !_submitted,
                              onTap:
                                  !_submitted
                                      ? () => _editField(s, 'sex')
                                      : null,
                            ),
                            DataCell(
                              Text(s['block']!),
                              showEditIcon: !_submitted,
                              onTap:
                                  !_submitted
                                      ? () => _editField(s, 'block')
                                      : null,
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _students.remove(s);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _students.isEmpty ? null : _submitAll,
            icon: const Icon(Icons.save),
            label: const Text("Submit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: primaryColor,
            tabs: [
              Tab(icon: Icon(Icons.upload_file), text: "Import Students"),
              Tab(icon: Icon(Icons.list), text: "Student List"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildImportTab(), // your import UI
                const StudentListPage(), // your existing Firestore student list
              ],
            ),
          ),
        ],
      ),
    );
  }
}
