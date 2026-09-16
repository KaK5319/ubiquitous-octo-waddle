import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:page_flip_builder/page_flip_builder.dart';

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
      if (!mounted) return;
      final path = result.files.single.path!;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(filePath: path),
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
  PdfDocument? _pdfDocument;
  bool _isLoading = true;
  int _pageCount = 0;
  int _currentPageIndex = 0;
  
  final Map<int, ImageProvider> _imageCache = {};
  bool _isRendering = false;
  final pageFlipKey = GlobalKey<PageFlipBuilderState>();

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    try {
      final doc = await PdfDocument.openFile(widget.filePath);
      _pdfDocument = doc;
      _pageCount = doc.pagesCount;

      await _loadSinglePage(1);
      if (_pageCount >= 2) await _loadSinglePage(2);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<ImageProvider?> _loadSinglePage(int pageNumber) async {
    if (_imageCache.containsKey(pageNumber)) {
      return _imageCache[pageNumber];
    }

    while (_isRendering) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    if (_imageCache.containsKey(pageNumber)) {
      return _imageCache[pageNumber];
    }

    final doc = _pdfDocument;
    if (doc == null) return null;

    _isRendering = true;

    try {
      final page = await doc.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width * 1.0,
        height: page.height * 1.0,
        format: PdfPageImageFormat.jpeg,
      );
      await page.close();

      if (pageImage != null) {
        final provider = MemoryImage(pageImage.bytes);
        _imageCache[pageNumber] = provider;
        _isRendering = false;
        return provider;
      }
    } catch (_) {}

    _isRendering = false;
    return null;
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
        title: Text(_pageCount > 0 ? '全 $_pageCount ページ (${_currentPageIndex + 1})' : '読み込み中...'),
      ),
      body: _isLoading || _pdfDocument == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : PageFlipBuilder(
              key: pageFlipKey,
              isRightToLeft: true, // 右開き（漫画のめくり方向）
              onPageFlip: (pageIndex) {
                setState(() {
                  _currentPageIndex = pageIndex;
                });
                // 先回り読み込み
                final pageNum = pageIndex + 1;
                if (pageNum + 1 <= _pageCount) _loadSinglePage(pageNum + 1);
                if (pageNum - 1 >= 1) _loadSinglePage(pageNum - 1);
              },
              frontBuilder: (context) => PdfPageWidget(
                pageNumber: _currentPageIndex + 1,
                imageCache: _imageCache,
                loadPage: () => _loadSinglePage(_currentPageIndex + 1),
              ),
              backBuilder: (context) => PdfPageWidget(
                pageNumber: (_currentPageIndex + 2).clamp(1, _pageCount),
                imageCache: _imageCache,
                loadPage: () => _loadSinglePage((_currentPageIndex + 2).clamp(1, _pageCount)),
              ),
            ),
    );
  }
}

class PdfPageWidget extends StatefulWidget {
  final int pageNumber;
  final Map<int, ImageProvider> imageCache;
  final Future<ImageProvider?> Function() loadPage;

  const PdfPageWidget({
    super.key,
    required this.pageNumber,
    required this.imageCache,
    required this.loadPage,
  });

  @override
  State<PdfPageWidget> createState() => _PdfPageWidgetState();
}

class _PdfPageWidgetState extends State<PdfPageWidget> {
  ImageProvider? _image;

  @override
  void initState() {
    super.initState();
    _fetchPage();
  }

  @override
  void didUpdateWidget(covariant PdfPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _fetchPage();
    }
  }

  Future<void> _fetchPage() async {
    if (widget.imageCache.containsKey(widget.pageNumber)) {
      if (mounted) {
        setState(() {
          _image = widget.imageCache[widget.pageNumber];
        });
      }
      return;
    }

    final img = await widget.loadPage();
    if (mounted && img != null) {
      setState(() {
        _image = img;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _image ?? widget.imageCache[widget.pageNumber];

    if (img == null) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.grey),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Image(
        image: img,
        fit: BoxFit.contain,
      ),
    );
  }
}
