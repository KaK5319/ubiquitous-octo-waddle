import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:page_flip/page_flip.dart';

void main() {
  // 起動時のプラグイン初期化エラー（クラッシュ）を防止
  WidgetsBinding platformBinding = WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SideBooks Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const BookshelfScreen(),
    );
  }
}

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  final List<File> _pdfFiles = [];

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _pdfFiles.add(File(result.files.single.path!));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ファイル選択エラー: $e')),
        );
      }
    }
  }

  void _openPdf(File file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(pdfFile: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本棚'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _pickPDF,
            tooltip: 'PDFを追加',
          ),
        ],
      ),
      body: _pdfFiles.isEmpty
          ? const Center(
              child: Text(
                '右上の「+」ボタンから\nPDFファイルを追加してください',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: _pdfFiles.length,
              itemBuilder: (context, index) {
                final file = _pdfFiles[index];
                final fileName = file.path.split('/').last;

                return GestureDetector(
                  onTap: () => _openPdf(file),
                  child: Card(
                    elevation: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final File pdfFile;

  const PdfViewerScreen({super.key, required this.pdfFile});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<PageFlipWidgetState> _controller = GlobalKey<PageFlipWidgetState>();
  PdfDocument? _pdfDocument;
  int _pageCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final doc = await PdfDocument.openFile(widget.pdfFile.path);
      setState(() {
        _pdfDocument = doc;
        _pageCount = doc.pagesCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'PDFの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfDocument?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        foregroundColor: Colors.white,
        title: Text(
          widget.pdfFile.path.split('/').last,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    PageFlipWidget(
                      key: _controller,
                      backgroundColor: Colors.black,
                      initialIndex: 0,
                      duration: const Duration(milliseconds: 300),
                      children: List.generate(
                        _pageCount,
                        (index) => SinglePdfPageWidget(
                          document: _pdfDocument!,
                          pageNumber: index + 1,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class SinglePdfPageWidget extends StatefulWidget {
  final PdfDocument document;
  final int pageNumber;

  const SinglePdfPageWidget({
    super.key,
    required this.document,
    required this.pageNumber,
  });

  @override
  State<SinglePdfPageWidget> createState() => _SinglePdfPageWidgetState();
}

class _SinglePdfPageWidgetState extends State<SinglePdfPageWidget> {
  PdfPageImage? _pageImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _renderPage();
  }

  Future<void> _renderPage() async {
    try {
      final page = await widget.document.getPage(widget.pageNumber);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
      );
      await page.close();

      if (mounted) {
        setState(() {
          _pageImage = pageImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_pageImage == null) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.white54, size: 48),
      );
    }

    return Center(
      child: Image.memory(
        _pageImage!.bytes,
        fit: BoxFit.contain,
      ),
    );
  }
}
