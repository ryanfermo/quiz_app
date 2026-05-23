import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color primaryColor = Color(0xFF003366);
const Color accentColor = Color(0xFFFFA500);

class CMSPage extends StatefulWidget {
  const CMSPage({super.key});

  @override
  State<CMSPage> createState() => _CMSPageState();
}

class _CMSPageState extends State<CMSPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;
  final List<String> questionTypes = [
    "Multiple Choice",
    "Fill in the Blank",
    "Identification",
    "Matching",
    "Essay",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: questionTypes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double tabWidth =
        MediaQuery.of(context).size.width / questionTypes.length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(
          elevation: 4,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003366), Color(0xFF0055AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text(
            'Question Bank',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: accentColor,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
            tabs:
                questionTypes.map((t) {
                  return SizedBox(
                    width: tabWidth,
                    child: Center(child: Tab(text: t)),
                  );
                }).toList(),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            questionTypes
                .map(
                  (type) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: QuestionForm(questionType: type),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class QuestionForm extends StatefulWidget {
  final String questionType;
  const QuestionForm({super.key, required this.questionType});

  @override
  State<QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<QuestionForm> {
  final TextEditingController _questionCtrl = TextEditingController();
  final List<TextEditingController> _options = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<Map<String, TextEditingController>> _matchingPairs = [];
  final List<TextEditingController> _blanks = [];
  final TextEditingController _answerCtrl = TextEditingController();

  final TextEditingController _totalPointsCtrl = TextEditingController();

  final List<Map<String, TextEditingController>> _rubrics = [];

  bool _isSaving = false;
  int _selectedOptionIndex = 0;

  @override
  void dispose() {
    _totalPointsCtrl.dispose();

    for (var r in _rubrics) {
      r["criteria"]!.dispose();
      r["points"]!.dispose();
    }
    _questionCtrl.dispose();
    for (var c in _options) {
      c.dispose();
    }
    for (var pair in _matchingPairs) {
      pair['left']!.dispose();
      pair['right']!.dispose();
    }
    for (var b in _blanks) {
      b.dispose();
    }
    _answerCtrl.dispose();
    super.dispose();
  }

  void _clearInputs() {
    _questionCtrl.clear();
    for (var c in _options) {
      c.clear();
    }
    _answerCtrl.clear();
    _blanks.clear();
    _matchingPairs.clear();
    _selectedOptionIndex = 0;

    _totalPointsCtrl.clear();

    for (var r in _rubrics) {
      r["criteria"]!.clear();
      r["points"]!.clear();
    }
    _rubrics.clear();
  }

  Future<void> _saveQuestion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_questionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Question cannot be empty")));
      return;
    }

    setState(() => _isSaving = true);

    Map<String, dynamic> data = {
      "question": _questionCtrl.text.trim(),
      "type": widget.questionType,
      "teacherId": user.uid,
      "createdAt": Timestamp.now(),
    };

    switch (widget.questionType) {
      case "Multiple Choice":
        data["options"] = _options.map((c) => c.text.trim()).toList();
        data["answer"] = _options[_selectedOptionIndex].text.trim();
        break;
      case "Essay":
        data["totalPoints"] = int.tryParse(_totalPointsCtrl.text.trim()) ?? 0;

        data["rubrics"] =
            _rubrics
                .map(
                  (r) => {
                    "criteria": r["criteria"]!.text.trim(),
                    "points": int.tryParse(r["points"]!.text.trim()) ?? 0,
                  },
                )
                .toList();

        data["answer"] = _answerCtrl.text.trim(); // optional
        break;
      case "Identification":
        data["answer"] = _answerCtrl.text.trim();
        break;
      case "Fill in the Blank":
        data["blanks"] = _blanks.map((c) => c.text.trim()).toList();
        break;
      case "Matching":
        data["pairs"] =
            _matchingPairs
                .map(
                  (p) => {
                    "left": p["left"]!.text.trim(),
                    "right": p["right"]!.text.trim(),
                  },
                )
                .toList();
        break;
    }

    await FirebaseFirestore.instance.collection("questions").add(data);
    _clearInputs();
    setState(() => _isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Question saved successfully")),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _questionCtrl,
            decoration: _inputDecoration("Question"),
          ),
          const SizedBox(height: 12),
          if (widget.questionType == "Multiple Choice")
            Column(
              children: [
                ..._options.asMap().entries.map((e) {
                  int idx = e.key;
                  TextEditingController c = e.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: c,
                            decoration: _inputDecoration("Option ${idx + 1}"),
                          ),
                        ),
                        Radio<int>(
                          value: idx,
                          groupValue: _selectedOptionIndex,
                          onChanged:
                              (v) => setState(() => _selectedOptionIndex = v!),
                        ),
                        const Text("Answer"),
                      ],
                    ),
                  );
                }),
              ],
            ),
          if (widget.questionType == "Essay")
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Total Points
                TextField(
                  controller: _totalPointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Total Points (e.g. 10)"),
                ),

                const SizedBox(height: 12),
                const Text(
                  "Rubrics",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                ..._rubrics.asMap().entries.map((e) {
                  int idx = e.key;
                  var rubric = e.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rubric["criteria"],
                            decoration: _inputDecoration(
                              "Criteria (e.g. Grammar)",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: rubric["points"],
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration("Pts"),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed:
                              () => setState(() => _rubrics.removeAt(idx)),
                        ),
                      ],
                    ),
                  );
                }),

                TextButton.icon(
                  onPressed:
                      () => setState(() {
                        _rubrics.add({
                          "criteria": TextEditingController(),
                          "points": TextEditingController(),
                        });
                      }),
                  icon: const Icon(Icons.add),
                  label: const Text("Add Rubric"),
                ),
              ],
            ),
          if (widget.questionType == "Fill in the Blank")
            Column(
              children: [
                ..._blanks.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextField(
                      controller: e.value,
                      decoration: _inputDecoration("Blank ${e.key + 1}"),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      () =>
                          setState(() => _blanks.add(TextEditingController())),
                  icon: const Icon(Icons.add),
                  label: const Text("Add Blank"),
                ),
              ],
            ),
          if (widget.questionType == "Matching")
            Column(
              children: [
                ..._matchingPairs.asMap().entries.map((e) {
                  int idx = e.key;
                  var pair = e.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pair["left"],
                            decoration: _inputDecoration("Left ${idx + 1}"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text("→"),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: pair["right"],
                            decoration: _inputDecoration("Right ${idx + 1}"),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed:
                              () =>
                                  setState(() => _matchingPairs.removeAt(idx)),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed:
                      () => setState(
                        () => _matchingPairs.add({
                          "left": TextEditingController(),
                          "right": TextEditingController(),
                        }),
                      ),
                  icon: const Icon(Icons.add),
                  label: const Text("Add Pair"),
                ),
              ],
            ),
          if (widget.questionType == "Identification")
  Column(
    children: [
      TextField(
        controller: _answerCtrl,
        decoration: _inputDecoration("Correct Answer"),
      ),
    ],
  ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveQuestion,
              icon: const Icon(Icons.save),
              label:
                  _isSaving
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text("Save Question"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
