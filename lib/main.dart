import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:page_flip/page_flip.dart';

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
  final GlobalKey<PageFlipWidgetState> _controller = GlobalKey<PageFlipWidgetState>();
  bool _isLoading = true;
  int _pageCount = 0;
  final Map<int, ImageProvider> _imageCache = {};

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

      final initialLoadCount = _pageCount < 8 ? _pageCount : 8;
      for (int i = 1; i <= initialLoadCount; i++) {
        await _preloadPage(i);
      }

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

  Future<ImageProvider?> _preloadPage(int pageNumber) async {
    if (_imageCache.containsKey(pageNumber)) {
      return _imageCache[pageNumber];
    }
    final doc = _pdfDocument;
    if (doc == null) return null;

    try {
      final page = await doc.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width * 1.2,
        height: page.height * 1.2,
        format: PdfPageImageFormat.jpeg,
      );
      await page.close();

      if (pageImage != null) {
        final provider = MemoryImage(pageImage.bytes);
        _imageCache[pageNumber] = provider;
        return provider;
      }
    } catch (_) {}
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
        title: Text(_pageCount > 0 ? '全 $_pageCount ページ' : '読み込み中...'),
      ),
      body: _isLoading || _pdfDocument == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : PageFlipWidget(
              key: _controller,
              backgroundColor: Colors.black,
              isRightSwipe: false,
              cutoff: 0.1,
              duration: const Duration(milliseconds: 150),
              children: List.generate(_pageCount, (index) {
                final pageNum = index + 1;
                
                for (int i = 1; i <= 3; i++) {
                  if (pageNum + i <= _pageCount) _preloadPage(pageNum + i);
                  if (pageNum - i >= 1) _preloadPage(pageNum - i);
                }

                return PdfPageCachedWidget(
                  pageNumber: pageNum,
                  imageCache: _imageCache,
                  loadTask: () => _preloadPage(pageNum),
                );
              }),
            ),
    );
  }
}

class PdfPageCachedWidget extends StatefulWidget {
  final int pageNumber;
  final Map<int, ImageProvider> imageCache;
  final Future<ImageProvider?> Function() loadTask;

  const PdfPageCachedWidget({
    super.key,
    required this.pageNumber,
    required this.imageCache,
    required this.loadTask,
  });

  @override
  State<PdfPageCachedWidget> createState() => _PdfPageCachedWidgetState();
}

class _PdfPageCachedWidgetState extends State<PdfPageCachedWidget> {
  ImageProvider? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.imageCache.containsKey(widget.pageNumber)) {
      if (mounted) {
        setState(() {
          _image = widget.imageCache[widget.pageNumber];
        });
      }
    } else {
      final img = await widget.loadTask();
      if (mounted) {
        setState(() {
          _image = img;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
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
