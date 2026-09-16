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
  bool _isRightSwipe = false; // めくり方向の切替用（デフォルト：左→右）
  
  // キャッシュ制御
  final Map<int, ImageProvider> _imageCache = {};
  bool _isRendering = false;

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

      // 最初の2ページだけ超高速で読み込み
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

  // ページの単一レンダリング（割り込み優先制御付き）
  Future<ImageProvider?> _loadSinglePage(int pageNumber) async {
    if (_imageCache.containsKey(pageNumber)) {
      return _imageCache[pageNumber];
    }

    // 他のレンダリングが終わるまで少し待機（キュー詰まり防止）
    while (_isRendering) {
      await Future.delayed(const Duration(milliseconds: 20));
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
        width: page.width * 1.0, // 低負荷で爆速レンダリング
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
        title: Text(_pageCount > 0 ? '全 $_pageCount ページ' : '読み込み中...'),
        actions: [
          // めくり方向の切り替えボタン
          IconButton(
            icon: Icon(_isRightSwipe ? Icons.format_line_spacing : Icons.swap_horiz),
            tooltip: 'めくり方向切り替え',
            onPressed: () {
              setState(() {
                _isRightSwipe = !_isRightSwipe;
              });
            },
          ),
        ],
      ),
      body: _isLoading || _pdfDocument == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : PageFlipWidget(
              key: _controller,
              isRightSwipe: _isRightSwipe,
              children: List.generate(_pageCount, (index) {
                final pageNum = index + 1;

                return PdfPageWidget(
                  pageNumber: pageNum,
                  imageCache: _imageCache,
                  loadPage: () => _loadSinglePage(pageNum),
                  preloadNeighbors: () {
                    // 現在ページの「前後1ページ」だけを最優先で直前確保
                    if (pageNum + 1 <= _pageCount) _loadSinglePage(pageNum + 1);
                    if (pageNum - 1 >= 1) _loadSinglePage(pageNum - 1);
                  },
                );
              }),
            ),
    );
  }
}

class PdfPageWidget extends StatefulWidget {
  final int pageNumber;
  final Map<int, ImageProvider> imageCache;
  final Future<ImageProvider?> Function() loadPage;
  final VoidCallback preloadNeighbors;

  const PdfPageWidget({
    super.key,
    required this.pageNumber,
    required this.imageCache,
    required this.loadPage,
    required this.preloadNeighbors,
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

  Future<void> _fetchPage() async {
    if (widget.imageCache.containsKey(widget.pageNumber)) {
      if (mounted) {
        setState(() {
          _image = widget.imageCache[widget.pageNumber];
        });
        widget.preloadNeighbors();
      }
      return;
    }

    final img = await widget.loadPage();
    if (mounted && img != null) {
      setState(() {
        _image = img;
      });
      widget.preloadNeighbors();
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
