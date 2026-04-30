// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AssessmentsPage extends StatelessWidget {
  const AssessmentsPage({super.key});

  Future<Uint8List> _generateAssessmentPdf(
    String quizTitle,
    List<QueryDocumentSnapshot> questions,
  ) async {
    final PdfDocument document = PdfDocument();
    final page = document.pages.add();
    double y = 0;

    final double pageWidth = page.getClientSize().width;

    // --- HEADER: logo left + logo right + centered text ---
    final ByteData leftLogoData = await rootBundle.load('assets/ucu.png');
    final Uint8List leftLogoBytes = leftLogoData.buffer.asUint8List();
    final PdfBitmap leftLogo = PdfBitmap(leftLogoBytes);

    final ByteData rightLogoData = await rootBundle.load('assets/cite.png');
    final Uint8List rightLogoBytes = rightLogoData.buffer.asUint8List();
    final PdfBitmap rightLogo = PdfBitmap(rightLogoBytes);

    const double logoWidth = 50;
    const double logoHeight = 50;

    // Draw left logo
    page.graphics.drawImage(
      leftLogo,
      Rect.fromLTWH(0, 0, logoWidth, logoHeight),
    );

    // Draw right logo
    page.graphics.drawImage(
      rightLogo,
      Rect.fromLTWH(pageWidth - logoWidth, 0, logoWidth, logoHeight),
    );

    // Draw centered text between logos
    page.graphics.drawString(
      'URDANETA CITY UNIVERSITY\nCollege of Information and Technology Education',
      PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(
        logoWidth + 10, // left margin after logo
        0,
        pageWidth - (2 * logoWidth + 20), // space between left & right logos
        logoHeight,
      ),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
        wordWrap: PdfWordWrapType.word,
      ),
    );

    y += logoHeight + 15; // spacing after header

    // --- QUIZ TITLE ---
    page.graphics.drawString(
      quizTitle,
      PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, y, pageWidth, 25),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.top,
      ),
    );
    y += 40;

    // --- QUESTIONS ---
    const letters = ['A', 'B', 'C', 'D'];

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i].data() as Map<String, dynamic>;

      // Question
      page.graphics.drawString(
        "Q${i + 1}: ${q['question'] ?? ''}",
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(0, y, pageWidth, 20),
      );
      y += 20;

      // Options
      if (q['options'] != null && q['options'] is List) {
        for (var j = 0; j < q['options'].length; j++) {
          final optionLetter = j < letters.length ? letters[j] : '${j + 1}';
          page.graphics.drawString(
            "$optionLetter. ${q['options'][j]}",
            PdfStandardFont(
              PdfFontFamily.helvetica,
              12,
              style: PdfFontStyle.regular,
            ),
            bounds: Rect.fromLTWH(20, y, pageWidth, 18),
          );
          y += 18;
        }
      }

      y += 12;
    }

    final List<int> bytes = await document.save();
    document.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Preview PDF in-app (mobile/desktop) or open in new tab (Web)
  void _previewPdf(BuildContext context, Uint8List pdfBytes) {
    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      // Do not revoke immediately; browser tab needs it
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: const Text("PDF Preview")),
                body: SfPdfViewer.memory(pdfBytes),
              ),
        ),
      );
    }
  }

  /// Delete assessment + questions
  Future<void> _deleteAssessment(BuildContext context, String quizId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Assessment"),
            content: const Text(
              "Are you sure you want to delete this assessment?",
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

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('quizzes').doc(quizId).delete();

    final qs =
        await FirebaseFirestore.instance
            .collection('questions')
            .where('quizId', isEqualTo: quizId)
            .get();

    for (var q in qs.docs) {
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(q.id)
          .delete();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Assessment deleted")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text("You must be logged in to view assessments."),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('quizzes')
              .where('teacherId', isEqualTo: user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No assessments created yet"));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  data['title'] ?? "Untitled Assessment",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Type: ${data['type'] ?? 'Quiz'}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.green,
                      ),
                      onPressed: () async {
                        final qs =
                            await FirebaseFirestore.instance
                                .collection('questions')
                                .where('quizId', isEqualTo: doc.id)
                                .orderBy('createdAt')
                                .get();

                        final pdfBytes = await _generateAssessmentPdf(
                          data['title'] ?? "Assessment",
                          qs.docs,
                        );

                        // ignore: use_build_context_synchronously
                        _previewPdf(context, pdfBytes);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteAssessment(context, doc.id),
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
}
