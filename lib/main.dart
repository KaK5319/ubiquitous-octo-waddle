import 'dartd:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Manga Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MangaReaderScreen(pdfPath: path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本棚')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _pickPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('PDFファイルを開く'),
        ),
      ),
    );
  }
}

class MangaReaderScreen extends StatefulWidget {
  final String pdfPath;
  const MangaReaderScreen({super.key, required this.pdfPath});

  @override
  State<MangaReaderScreen> createState() => _MangaReaderScreenState();
}

class _MangaReaderScreenState extends State<MangaReaderScreen> {
  late PdfDocumentProvider _pdfProvider;
  PdfDocument? _pdfDocument;
  late PageController _pageController;

  int _totalPages = 0;
  int _currentPage = 0;
  final Map<int, PdfPageImage> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initPdf();
  }

  Future<void> _initPdf() async {
    _pdfProvider = PdfDocumentProvider.openFile(widget.pdfPath);
    final doc = await _pdfProvider.openDocument();
    setState(() {
      _pdfDocument = doc;
      _totalPages = doc.pagesCount;
    });
    _preloadImages(0);
  }

  Future<void> _preloadImages(int centerIndex) async {
    if (_pdfDocument == null) return;
    for (int i = centerIndex - 2; i <= centerIndex + 2; i++) {
      if (i >= 0 && i < _totalPages && !_imageCache.containsKey(i)) {
        _renderPage(i);
      }
    }
  }

  Future<void> _renderPage(int pageIndex) async {
    if (_pdfDocument == null || _imageCache.containsKey(pageIndex)) return;
    final page = await _pdfDocument!.getPage(pageIndex + 1);
    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.jpeg,
    );
    await page.close();
    if (pageImage != null && mounted) {
      setState(() {
        _imageCache[pageIndex] = pageImage;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pdfDocument?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('全 $_totalPages ページ'),
        backgroundColor: Colors.black,
      ),
      body: _pdfDocument == null
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              reverse: true, // 右開き（右から左へめくる）
              controller: _pageController,
              itemCount: _totalPages,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                _preloadImages(index);
              },
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 0.0;
                    if (_pageController.position.haveDimensions) {
                      value = (_pageController.page ?? 0) - index;
                    }
                    final angle = value * 0.4;

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: value > 0
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: child,
                    );
                  },
                  child: _buildPageContent(index),
                );
              },
            ),
    );
  }

  Widget _buildPageContent(int index) {
    final cachedImage = _imageCache[index];
    if (cachedImage != null) {
      return Image.memory(cachedImage.bytes, fit: BoxFit.contain);
    }
    _renderPage(index);
    return const Center(child: CircularProgressIndicator());
  }
}
