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
  final PageController _pageController = PageController();
  bool _isLoading = true;
  int _pageCount = 0;
  bool _isRightToLeft = true; // デフォルト：右開き
  
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_pageCount > 0 ? '全 $_pageCount ページ' : '読み込み中...'),
        actions: [
          IconButton(
            icon: Icon(_isRightToLeft ? Icons.swap_horiz : Icons.format_line_spacing),
            tooltip: 'めくり方向切り替え',
            onPressed: () {
              setState(() {
                _isRightToLeft = !_isRightToLeft;
              });
            },
          ),
        ],
      ),
      body: _isLoading || _pdfDocument == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : PageView.builder(
              controller: _pageController,
              reverse: _isRightToLeft,
              itemCount: _pageCount,
              itemBuilder: (context, index) {
                final pageNum = index + 1;

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double position = 0.0;
                    if (_pageController.position.haveDimensions) {
                      position = (_pageController.page ?? 0.0) - index;
                    }
                    
                    // 90度（半開き）を超えたら背面（裏側）を描画しない保護
                    final isBackFace = position.abs() > 0.5;
                    
                    // カール計算と回転角度
                    final angle = position * (pi / 2.5);
                    final matrix = Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(angle);

                    // ページ接合部のリアルな影（グラデーション）
                    final shadowOpacity = (position.abs()).clamp(0.0, 0.6);

                    return Transform(
                      transform: matrix,
                      alignment: position > 0 ? Alignment.centerLeft : Alignment.centerRight,
                      child: Stack(
                        children: [
                          // 90度以上回った時は白地（紙の裏面）で隠す
                          if (isBackFace)
                            Container(color: Colors.white)
                          else
                            child!,
                          // めくり部分の陰影
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(shadowOpacity),
                                    Colors.transparent,
                                  ],
                                  begin: position > 0 ? Alignment.centerLeft : Alignment.centerRight,
                                  end: position > 0 ? Alignment.centerRight : Alignment.centerLeft,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: PdfPageWidget(
                    pageNumber: pageNum,
                    imageCache: _imageCache,
                    loadPage: () => _loadSinglePage(pageNum),
                    preloadNeighbors: () {
                      if (pageNum + 1 <= _pageCount) _loadSinglePage(pageNum + 1);
                      if (pageNum - 1 >= 1) _loadSinglePage(pageNum - 1);
                    },
                  ),
                );
              },
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
