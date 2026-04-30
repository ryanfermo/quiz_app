import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color primaryColor = Color(0xFF003366);
const Color accentColor = Color(0xFFFFCC00);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final user = FirebaseAuth.instance.currentUser;

  int totalStudents = 0;
  int totalQuiz = 0;
  int totalExam = 0;
  int totalActivity = 0;

  Map<String, List<Map<String, dynamic>>> studentsPerBlock = {};
  bool isLoading = true;
  String? selectedBlock;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    if (user == null) return;

    try {
      final studentSnapshot =
          await FirebaseFirestore.instance
              .collection('teachers')
              .doc(user!.uid)
              .collection('students')
              .get();

      totalStudents = studentSnapshot.docs.length;

      Map<String, List<Map<String, dynamic>>> blockMap = {};

      for (var doc in studentSnapshot.docs) {
        final data = doc.data();
        String block = data['block'] ?? 'No Block';

        blockMap.putIfAbsent(block, () => []);
        blockMap[block]!.add(data);
      }

      final resultsSnapshot =
          await FirebaseFirestore.instance
              .collection('results')
              .where('teacherId', isEqualTo: user!.uid)
              .get();

      int quiz = 0, exam = 0, activity = 0;

      for (var doc in resultsSnapshot.docs) {
        final type = (doc['type'] ?? '').toString().toLowerCase();

        if (type == 'quiz') quiz++;
        if (type == 'exam') exam++;
        if (type == 'activity') activity++;
      }

      setState(() {
        totalQuiz = quiz;
        totalExam = exam;
        totalActivity = activity;
        studentsPerBlock = blockMap;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "No date";
    final date = (timestamp as Timestamp).toDate();

    return "${date.month}/${date.day}/${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;

          int columns = 4;
          if (width < 1200) columns = 3;
          if (width < 900) columns = 2;
          if (width < 600) columns = 1;

          double cardWidth = (width - (20 * (columns - 1))) / columns;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard Overview",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildCard(
                        "Students",
                        totalStudents,
                        Icons.people,
                        cardWidth,
                        () => showStudentsPerBlock(),
                      ),
                      _buildCard(
                        "Quizzes",
                        totalQuiz,
                        Icons.quiz,
                        cardWidth,
                        () => showResultsPerBlock("quiz"),
                      ),
                      _buildCard(
                        "Exams",
                        totalExam,
                        Icons.school,
                        cardWidth,
                        () => showResultsPerBlock("exam"),
                      ),
                      _buildCard(
                        "Activities",
                        totalActivity,
                        Icons.assignment,
                        cardWidth,
                        () => showResultsPerBlock("activity"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Students per Block",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if (studentsPerBlock.isEmpty)
                    const Text("No students found.")
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                studentsPerBlock.keys.map((block) {
                                  final isSelected = selectedBlock == block;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text("Block $block"),
                                      selected: isSelected,
                                      selectedColor: primaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          selectedBlock = block;
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),

                        const SizedBox(height: 15),

                        if (selectedBlock == null)
                          const Text(
                            "Tap a block to view students",
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          ...studentsPerBlock[selectedBlock]!.map((student) {
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(
                                  "${student['firstName'] ?? ''} ${student['lastName'] ?? ''}"
                                      .trim(),
                                ),
                                subtitle: Text(
                                  "ID: ${student['id'] ?? ''} | ${student['course'] ?? ''}",
                                ),
                                onTap: () => showStudentRecords(student),
                              ),
                            );
                          }),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
    String title,
    int count,
    IconData icon,
    double width,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: primaryColor),
            const SizedBox(height: 10),
            Text(
              "$count",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }

  Future<void> showStudentRecords(Map<String, dynamic> student) async {
    final studentId = student['id'];

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('results')
                  .where('teacherId', isEqualTo: user!.uid)
                  .where('studentId', isEqualTo: studentId)
                  .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            List<Map<String, dynamic>> quizzes = [];
            List<Map<String, dynamic>> exams = [];
            List<Map<String, dynamic>> activities = [];

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final type = (data['type'] ?? '').toString().toLowerCase();

              if (type == 'quiz') quizzes.add(data);
              if (type == 'exam') exams.add(data);
              if (type == 'activity') activities.add(data);
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxHeight: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${student['firstName']} ${student['lastName']}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildResultSection("Quiz", quizzes),
                            const SizedBox(height: 10),
                            _buildResultSection("Exam", exams),
                            const SizedBox(height: 10),
                            _buildResultSection("Activities", activities),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResultSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title (${items.length})",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        if (items.isEmpty)
          const SizedBox(
            height: 120,
            child: Center(
              child: Text("No records", style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,

                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width < 900 ? 1 : 2,

                  childAspectRatio: 2.6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),

                itemBuilder: (context, index) {
                  final item = items[index];
                  int essayScore = 0;
                  int essayTotal = 0;

                  if (item['essayScores'] != null) {
                    final scoresMap = Map<String, dynamic>.from(
                      item['essayScores'],
                    );

                    essayScore = scoresMap.values.fold(
                      0,
                      (totalValue, val) => totalValue + (val as int),
                    );

                    // OPTIONAL (only if you really want max estimate)
                    essayTotal = scoresMap.length * 10;
                  }
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),

                      border: const Border(
                        left: BorderSide(color: primaryColor, width: 4),
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.08),
                          blurRadius: 6,
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] ?? 'No title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        if (item['essayScores'] != null)
                          Text(
                            "Essay Score: $essayScore${essayTotal > 0 ? " / $essayTotal" : ""}",
                          ),

                        Text(
                          "Score: ${item['score'] ?? 0} / ${item['total'] ?? 0}",
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Created: ${_formatDate(item['createdAt'])}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),

                        Text(
                          "Completed: ${_formatDate(item['completedAt'])}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  void showStudentsPerBlock() {
    showDialog(
      context: context,
      builder: (_) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 700;

        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            width: isMobile ? screenWidth * 0.96 : 650,
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // HEADER
                Row(
                  children: [
                    const Icon(Icons.groups, color: primaryColor, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Students Per Block",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // TABLE HEADER
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Block",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Students",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // DATA
                Expanded(
                  child: ListView.builder(
                    itemCount: studentsPerBlock.length,
                    itemBuilder: (_, index) {
                      final entry = studentsPerBlock.entries.elementAt(index);
                      final count = entry.value.length;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Block ${entry.key}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    "$count",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showResultsPerBlock(String type) async {
    final studentSnapshot =
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user!.uid)
            .collection('students')
            .get();

    Map<String, String> studentBlockMap = {};

    for (var doc in studentSnapshot.docs) {
      final data = doc.data();
      studentBlockMap[data['id']] = data['block'] ?? 'No Block';
    }

    final resultsSnapshot =
        await FirebaseFirestore.instance
            .collection('results')
            .where('teacherId', isEqualTo: user!.uid)
            .get();

    Map<String, Map<String, int>> blockData = {};

    for (var doc in resultsSnapshot.docs) {
      final data = doc.data();

      final docType = (data['type'] ?? '').toString().toLowerCase();
      if (docType != type.toLowerCase()) continue;

      final studentId = data['studentId'];
      final block = studentBlockMap[studentId] ?? 'Unknown Block';
      final title = data['title'] ?? 'Untitled';

      blockData.putIfAbsent(block, () => {});
      blockData[block]![title] = (blockData[block]![title] ?? 0) + 1;
    }

    if (!mounted) return;

    if (blockData.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(content: Text("No data found")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isMobile = screenWidth < 700;

        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            width: isMobile ? screenWidth * 0.96 : 850,
            height: screenHeight * 0.85,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // HEADER
                Row(
                  children: [
                    const Icon(Icons.assessment, color: primaryColor, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${type.toUpperCase()} Results Per Block",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Expanded(
                  child: ListView(
                    children:
                        blockData.entries.map((blockEntry) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                // BLOCK HEADER
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.08),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    "Block ${blockEntry.key}",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children:
                                        blockEntry.value.entries.map((entry) {
                                          final count = entry.value;

                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    entry.key,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: primaryColor
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        "$count ${count == 1 ? 'student' : 'students'}",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
