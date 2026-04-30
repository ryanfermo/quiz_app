import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'admin_homepage.dart';
import 'teacher_homepage.dart';

const Color primaryColor = Color(0xFF003366);
const Color accentColor = Color(0xFFFFCC00);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          );

      final uid = userCredential.user!.uid;
      final doc =
          await FirebaseFirestore.instance
              .collection('teachers')
              .doc(uid)
              .get();

      String role = 'admin';
      if (doc.exists && doc.data() != null) {
        role = doc.data()!['role'] ?? 'teacher';
      }

      Fluttertoast.showToast(msg: "Login Successful!");
      _emailCtrl.clear();
      _passwordCtrl.clear();

      if (!mounted) return;

      if (role == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherHomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "Login failed");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.isEmpty) {
      Fluttertoast.showToast(msg: "Enter your email first");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );
      Fluttertoast.showToast(msg: "Password reset email sent!");
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "Error");
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return Scaffold(
      body:
          isMobile
              ? SingleChildScrollView(
                child: Column(
                  children: [
                    _buildImageSection(width),
                    _buildLoginSection(width),
                  ],
                ),
              )
              : Row(
                children: [
                  Expanded(child: _buildImageSection(width)),
                  Expanded(child: _buildLoginSection(width)),
                ],
              ),
    );
  }

  Widget _buildImageSection(double width) {
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: double.infinity),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withValues(alpha: 0.8), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/ucu.png', height: 100, fit: BoxFit.contain),
                const SizedBox(height: 24),
                Text(
                  "Welcome to UCU\nYour Future Starts Here!",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginSection(double width) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: width > 600 ? 400 : width * 0.9,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/ucu.png', height: 80),
              const SizedBox(height: 24),
              TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: primaryColor,
                tabs: const [Tab(text: "Login"), Tab(text: "About CITE")],
              ),
              SizedBox(
                height: 350,
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildLoginForm(), _buildAboutTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.isEmpty ? "Please enter your email" : null,
            decoration: InputDecoration(
              labelText: "Email",
              prefixIcon: Icon(Icons.email, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Password Field
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            validator: (v) => v!.isEmpty ? "Please enter your password" : null,
            decoration: InputDecoration(
              labelText: "Password",
              prefixIcon: Icon(Icons.lock, color: primaryColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Login Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                      : const Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "The College of Information and Technology Education (CITE) at "
              "Urdaneta City University (UCU) prepares students for careers in the digital age "
              "with strong foundations in computing, technology, and innovation. "
              "CITE focuses on outcomes-based learning, industry-relevant skills, "
              "and research engagement to ensure graduates are globally competitive.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "📌 College Leadership",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("• Dean: Danilo B. Dorado, DIT"),
                Text("• Program Head (IT): Anthony G. Marquez, MIT"),
                Text(
                  "• Program Head (BLIS): Jovelyn S. Rivera - De Leon, RL, MLIS",
                ),
                Text("• Kind Instructor: Ryan Jay A. Fermo, BSIT"),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              "📚 Academic Programs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("• Bachelor of Science in Information Technology (BSIT)"),
                Text("• Bachelor of Library and Information Science  (BLIS)"),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              "CITE also participates in community and extension activities "
              "to enhance practical learning opportunities for students.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
