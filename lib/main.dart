import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SideBooksApp());
}

class SideBooksApp extends StatelessWidget {
  const SideBooksApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SideBooks Style Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const PdfReaderScreen(),
    );
  }
}

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({Key? key}) : super(key: key);

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  String? localPath;
  bool isLoading = true;
  int totalPages = 0;
  int currentPage = 0;
  PDFViewController? pdfViewController;
  bool _isPageChanging = false;

  final String samplePdfUrl =
      'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/examples/learning/helloworld.pdf';

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final response = await http.get(Uri.parse(samplePdfUrl));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sample.pdf');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      if (mounted) {
        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _nextPage() {
    if (_isPageChanging) return;
    if (currentPage < totalPages - 1 && pdfViewController != null) {
      _isPageChanging = true;
      pdfViewController!.setPage(currentPage + 1);
    }
  }

  void _previousPage() {
    if (_isPageChanging) return;
    if (currentPage > 0 && pdfViewController != null) {
      _isPageChanging = true;
      pdfViewController!.setPage(currentPage - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: Text(
          totalPages > 0 ? '${currentPage + 1} / $totalPages' : 'PDF Reader',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : localPath == null
              ? const Center(
                  child: Text(
                    'PDFの読み込みに失敗しました。',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) {
                    // 画面右半分タップで「次へ」、左半分タップで「前へ」
                    if (details.globalPosition.dx > screenWidth / 2) {
                      _nextPage();
                    } else {
                      _previousPage();
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    // 右スワイプ（→）で「次へ」、左スワイプ（←）で「前へ」
                    if (details.primaryVelocity! > 100) {
                      _nextPage();
                    } else if (details.primaryVelocity! < -100) {
                      _previousPage();
                    }
                  },
                  child: PDFView(
                    filePath: localPath,
                    enableSwipe: false,
                    swipeHorizontal: true,
                    autoSpacing: false,
                    pageFling: false,
                    pageSnap: true,
                    defaultPage: 0,
                    fitPolicy: FitPolicy.BOTH,
                    onRender: (pages) {
                      setState(() {
                        totalPages = pages ?? 0;
                      });
                    },
                    onViewCreated: (PDFViewController controller) {
                      pdfViewController = controller;
                    },
                    onPageChanged: (int? page, int? total) {
                      if (page != null) {
                        setState(() {
                          currentPage = page;
                          _isPageChanging = false;
                        });
                      }
                    },
                  ),
                ),
    );
  }
}
