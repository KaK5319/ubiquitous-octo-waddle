import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

  @override
  void initState() {
    super.initState();
    _generateAndLoadPdf();
  }

  /// 古いファイルを削除し、新しい3ページのPDFをローカル生成する
  Future<void> _generateAndLoadPdf() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/generated_sample.pdf');

      // 古いファイルが存在する場合は削除してキャッシュをクリア
      if (await file.exists()) {
        await file.delete();
      }

      // PDFドキュメントの作成（3ページ分）
      final pdf = pw.Document();
      for (int i = 1; i <= 3; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Text(
                  '$i Page',
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        );
      }

      // ファイル保存
      await file.writeAsBytes(await pdf.save(), flush: true);

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
                    'PDF生成に失敗しました。',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) {
                    // 画面右側タップで「次へ」、左側タップで「前へ」
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
