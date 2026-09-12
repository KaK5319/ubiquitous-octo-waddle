import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(filePath: result.files.single.path!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本棚')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _pickPDF,
          icon: const Icon(Icons.folder_open),
          label: const Text('PDFファイルを開く'),
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfDocument _pdfDocument;
  late PageController _pageController;
  bool _isLoading = true;
  int _pageCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    _pdfDocument = await PdfDocument.openFile(widget.filePath);
    setState(() {
      _pageCount = _pdfDocument.pagesCount;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pdfDocument.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.filePath.split('/').last),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              itemCount: _pageCount,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double pageOffset = 0;
                    if (_pageController.position.haveDimensions) {
                      pageOffset = (_pageController.page ?? 0) - index;
                    }

                    // ページめくりの3D湾曲＋影効果
                    final angle = pageOffset * pi / 3.5;
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(-angle);

                    return Transform(
                      transform: transform,
                      alignment: pageOffset > 0 ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: pageOffset.abs() > 0.01
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: PdfPageImageWidget(
                    pdfDocument: _pdfDocument,
                    pageNumber: index + 1,
                  ),
                );
              },
            ),
    );
  }
}

class PdfPageImageWidget extends StatelessWidget {
  final PdfDocument pdfDocument;
  final int pageNumber;

  const PdfPageImageWidget({
    super.key,
    required this.pdfDocument,
    required this.pageNumber,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PdfPageImage?>(
      future: _renderPage(pageNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image.memory(
            snapshot.data!.bytes,
            fit: BoxFit.contain,
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<PdfPageImage?> _renderPage(int pageNum) async {
    final page = await pdfDocument.getPage(pageNum);
    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.jpeg,
    );
    await page.close();
    return pageImage;
  }
}
