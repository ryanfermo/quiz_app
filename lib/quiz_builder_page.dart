import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color primaryColor = Color(0xFF003366);

class QuizBuilderPage extends StatefulWidget {
  const QuizBuilderPage({super.key});

  @override
  State<QuizBuilderPage> createState() => _QuizBuilderPageState();
}

class _QuizBuilderPageState extends State<QuizBuilderPage> {
  final TextEditingController _titleCtrl = TextEditingController();
  String quizType = "Quiz";
  List<Map<String, dynamic>> selectedQuestions = [];
  bool _isSaving = false;

  Future<void> _saveQuiz() async {
    if (_titleCtrl.text.trim().isEmpty || selectedQuestions.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final quizRef = await FirebaseFirestore.instance.collection('quizzes').add({
      "title": _titleCtrl.text.trim(),
      "type": quizType,
      "teacherId": user.uid,
      "createdAt": Timestamp.now(),
    });

    for (var q in selectedQuestions) {
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(q['questionId'])
          .update({"quizId": quizRef.id});
    }

    setState(() {
      selectedQuestions.clear();
      _titleCtrl.clear();
      _isSaving = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Assessment created successfully!")),
    );
  }

  Future<void> _deleteQuestion(String questionId) async {
    final confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Question"),
            content: const Text(
              "Are you sure you want to delete this question?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(questionId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Question deleted")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text("You must be logged in to create quizzes."),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: "Title",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: quizType,
            items: const [
              DropdownMenuItem(value: "Quiz", child: Text("Quiz")),
              DropdownMenuItem(value: "Exam", child: Text("Exam")),
              DropdownMenuItem(value: "Activity", child: Text("Activity")),
            ],
            onChanged: (value) => setState(() => quizType = value!),
            decoration: InputDecoration(
              labelText: "Type",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Select Questions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('questions')
                      .where('teacherId', isEqualTo: user.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No questions found."));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final q = docs[index];
                    final isSelected = selectedQuestions.any(
                      (e) => e['questionId'] == q.id,
                    );

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text(q['question'] ?? 'No question text'),
                            subtitle: Text("Type: ${q['type'] ?? 'Unknown'}"),
                            value: isSelected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  selectedQuestions.add({
                                    ...q.data() as Map<String, dynamic>,
                                    'questionId': q.id,
                                  });
                                } else {
                                  selectedQuestions.removeWhere(
                                    (e) => e['questionId'] == q.id,
                                  );
                                }
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  final doc = docs[index];
                                  final data =
                                      doc.data()! as Map<String, dynamic>;

                                  final questionCtrl = TextEditingController(
                                    text: data['question'] ?? '',
                                  );
                                  String typeCtrl =
                                      data['type'] ?? 'Multiple Choice';
                                  final answerCtrl = TextEditingController(
                                    text: data['answer'] ?? '',
                                  );

                                  List<TextEditingController> options = [];
                                  if (data['options'] != null) {
                                    options = List.generate(
                                      (data['options'] as List).length,
                                      (i) => TextEditingController(
                                        text: data['options'][i],
                                      ),
                                    );
                                  } else {
                                    options = List.generate(
                                      4,
                                      (_) => TextEditingController(),
                                    );
                                  }

                                  List<TextEditingController> blanks = [];
                                  if (data['blanks'] != null) {
                                    blanks = List.generate(
                                      (data['blanks'] as List).length,
                                      (i) => TextEditingController(
                                        text: data['blanks'][i],
                                      ),
                                    );
                                  }

                                  List<Map<String, TextEditingController>>
                                  matchingPairs = [];
                                  if (data['pairs'] != null) {
                                    matchingPairs = List.generate(
                                      (data['pairs'] as List).length,
                                      (i) => {
                                        'left': TextEditingController(
                                          text: data['pairs'][i]['left'],
                                        ),
                                        'right': TextEditingController(
                                          text: data['pairs'][i]['right'],
                                        ),
                                      },
                                    );
                                  }

                                  await showDialog(
                                    context: context,
                                    builder:
                                        (context) => StatefulBuilder(
                                          builder: (context, setStateDialog) {
                                            Widget dynamicFields() {
                                              switch (typeCtrl) {
                                                case 'Multiple Choice':
                                                  return Column(
                                                    children:
                                                        options.asMap().entries.map((
                                                          e,
                                                        ) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 4,
                                                                ),
                                                            child: TextField(
                                                              controller:
                                                                  e.value,
                                                              decoration:
                                                                  InputDecoration(
                                                                    labelText:
                                                                        "Option ${e.key + 1}",
                                                                  ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                  );
                                                case 'Essay':
                                                case 'Identification':
                                                  return TextField(
                                                    controller: answerCtrl,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: "Answer",
                                                        ),
                                                  );
                                                case 'Fill in the Blank':
                                                  return Column(
                                                    children: [
                                                      ...blanks.asMap().entries.map(
                                                        (e) => Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 4,
                                                              ),
                                                          child: TextField(
                                                            controller: e.value,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      "Blank ${e.key + 1}",
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      TextButton.icon(
                                                        icon: const Icon(
                                                          Icons.add,
                                                        ),
                                                        label: const Text(
                                                          "Add Blank",
                                                        ),
                                                        onPressed:
                                                            () => setStateDialog(
                                                              () => blanks.add(
                                                                TextEditingController(),
                                                              ),
                                                            ),
                                                      ),
                                                    ],
                                                  );
                                                case 'Matching':
                                                  return Column(
                                                    children: [
                                                      ...matchingPairs.asMap().entries.map((
                                                        e,
                                                      ) {
                                                        final pair = e.value;
                                                        return Row(
                                                          children: [
                                                            Expanded(
                                                              child: TextField(
                                                                controller:
                                                                    pair['left'],
                                                                decoration:
                                                                    InputDecoration(
                                                                      labelText:
                                                                          "Left ${e.key + 1}",
                                                                    ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            const Text("→"),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Expanded(
                                                              child: TextField(
                                                                controller:
                                                                    pair['right'],
                                                                decoration:
                                                                    InputDecoration(
                                                                      labelText:
                                                                          "Right ${e.key + 1}",
                                                                    ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons.delete,
                                                              ),
                                                              onPressed:
                                                                  () => setStateDialog(
                                                                    () => matchingPairs
                                                                        .removeAt(
                                                                          e.key,
                                                                        ),
                                                                  ),
                                                            ),
                                                          ],
                                                        );
                                                      }),
                                                      TextButton.icon(
                                                        icon: const Icon(
                                                          Icons.add,
                                                        ),
                                                        label: const Text(
                                                          "Add Pair",
                                                        ),
                                                        onPressed:
                                                            () => setStateDialog(
                                                              () => matchingPairs.add({
                                                                'left':
                                                                    TextEditingController(),
                                                                'right':
                                                                    TextEditingController(),
                                                              }),
                                                            ),
                                                      ),
                                                    ],
                                                  );
                                                default:
                                                  return const SizedBox();
                                              }
                                            }

                                            return AlertDialog(
                                              scrollable: true,
                                              title: const Text(
                                                "Edit Question",
                                              ),
                                              content: Column(
                                                children: [
                                                  TextField(
                                                    controller: questionCtrl,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: "Question",
                                                        ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    value: typeCtrl,
                                                    items: const [
                                                      DropdownMenuItem(
                                                        value:
                                                            'Multiple Choice',
                                                        child: Text(
                                                          'Multiple Choice',
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'Essay',
                                                        child: Text('Essay'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'Identification',
                                                        child: Text(
                                                          'Identification',
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value:
                                                            'Fill in the Blank',
                                                        child: Text(
                                                          'Fill in the Blank',
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'Matching',
                                                        child: Text('Matching'),
                                                      ),
                                                    ],
                                                    onChanged:
                                                        (val) => setStateDialog(
                                                          () => typeCtrl = val!,
                                                        ),
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: "Type",
                                                        ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  dynamicFields(),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Map<String, dynamic>
                                                    updated = {
                                                      "question":
                                                          questionCtrl.text
                                                              .trim(),
                                                      "type": typeCtrl,
                                                    };
                                                    if (typeCtrl ==
                                                        "Multiple Choice") {
                                                      updated["options"] =
                                                          options
                                                              .map(
                                                                (c) =>
                                                                    c.text
                                                                        .trim(),
                                                              )
                                                              .toList();
                                                    }
                                                    if (typeCtrl == "Essay" ||
                                                        typeCtrl ==
                                                            "Identification") {
                                                      updated["answer"] =
                                                          answerCtrl.text
                                                              .trim();
                                                    }
                                                    if (typeCtrl ==
                                                        "Fill in the Blank") {
                                                      updated["blanks"] =
                                                          blanks
                                                              .map(
                                                                (c) =>
                                                                    c.text
                                                                        .trim(),
                                                              )
                                                              .toList();
                                                    }
                                                    if (typeCtrl ==
                                                        "Matching") {
                                                      updated["pairs"] =
                                                          matchingPairs
                                                              .map(
                                                                (p) => {
                                                                  "left":
                                                                      p['left']!
                                                                          .text
                                                                          .trim(),
                                                                  "right":
                                                                      p['right']!
                                                                          .text
                                                                          .trim(),
                                                                },
                                                              )
                                                              .toList();
                                                    }

                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('questions')
                                                        .doc(doc.id)
                                                        .update(updated);
                                                    if (!mounted) return;
                                                    // ignore: use_build_context_synchronously
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(
                                                      // ignore: use_build_context_synchronously
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "Question updated",
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text("Save"),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteQuestion(q.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                      : const Text("Create Assessment"),
            ),
          ),
        ],
      ),
    );
  }
}
