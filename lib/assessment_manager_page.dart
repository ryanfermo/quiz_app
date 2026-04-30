import 'package:flutter/material.dart';
import 'package:quiz_cite_admin/quiz_builder_page.dart';
import 'package:quiz_cite_admin/assessments_page.dart';

const Color primaryColor = Color(0xFF003366);

class AssessmentManagerPage extends StatefulWidget {
  const AssessmentManagerPage({super.key});

  @override
  State<AssessmentManagerPage> createState() => _AssessmentManagerPageState();
}

class _AssessmentManagerPageState extends State<AssessmentManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> tabs = ["Created Questions", "Assessments"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
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
            'Assessments',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false, // <-- makes tabs stretch evenly
            indicatorColor: Colors.orangeAccent,
            indicatorWeight: 4,
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
            tabs: tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Padding(padding: EdgeInsets.all(16), child: QuizBuilderPage()),
          Padding(padding: EdgeInsets.all(16), child: AssessmentsPage()),
        ],
      ),
    );
  }
}
