import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 32;
  runApp(const SideBooksApp());
}

class SideBooksApp extends StatelessWidget {
  const SideBooksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SideBooks Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFF4EFEA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5D4037),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const MainShelfScreen(),
    );
  }
}

class BookItem {
  final String id;
  final String title;
  final String? path;
  final Color coverColor;
  Uint8List? thumbnail;

  BookItem({
    required this.id,
    required this.title,
    this.path,
    required this.coverColor,
    this.thumbnail,
  });
}

class MainShelfScreen extends StatefulWidget {
  const MainShelfScreen({super.key});

  @override
  State<MainShelfScreen> createState() => _MainShelfScreenState();
}

class _MainShelfScreenState extends State<MainShelfScreen> {
  final List<BookItem> _books = [];

  Future<Uint8List?> _generateThumbnail(String filePath) async {
    pdfx.PdfDocument? document;
    try {
      document = await pdfx.PdfDocument.openFile(filePath);
      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: page.width / 4,
        height: page.height / 4,
        format: pdfx.PdfPageImageFormat.jpeg,
      );
      return pageImage?.bytes;
    } catch (e) {
      return null;
    } finally {
      await document?.close();
    }
  }

  Future<void> _pickPDFFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      PlatformFile file = result.files.single;
      final thumbnailBytes = await _generateThumbnail(file.path!);

      setState(() {
        _books.add(
          BookItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: file.name,
            path: file.path,
            coverColor: Colors.brown.shade700,
            thumbnail: thumbnailBytes,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SideBooks 本棚'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.sort), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF8D6E63),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'すべての本 (${_books.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.grid_view, color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: _books.isEmpty
                ? const Center(
                    child: Text(
                      '右下の「+」ボタンから\nPDFファイルを追加してください',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      final book = _books[index];
                      return GestureDetector(
                        onTap: () {
                          if (book.path != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RealCurlPDFViewerScreen(book: book),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: book.coverColor,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              children: [
                                if (book.thumbnail != null)
                                  Positioned.fill(
                                    child: Image.memory(
                                      book.thumbnail!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Spacer(),
                                        Text(
                                          book.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: 6,
                                  child: Container(color: Colors.black26),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickPDFFile,
        backgroundColor: const Color(0xFF5D4037),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// リアル3Dカール・シャドウアニメーション表示画面
class RealCurlPDFViewerScreen extends StatefulWidget {
  final BookItem book;

  const RealCurlPDFViewerScreen({super.key, required this.book});

  @override
  State<RealCurlPDFViewerScreen> createState() => _RealCurlPDFViewerScreenState();
}

class _RealCurlPDFViewerScreenState extends State<RealCurlPDFViewerScreen> {
  pdfx.PdfDocument? _pdfDocument;
  int _pageCount = 0;
  int _currentPageIndex = 0;
  bool _isLoading = true;

  double _dragProgress = 0.0; // 0.0 ~ 1.0 めくり進行度
  bool _isDragging = false;
  bool _isNextPage = true; // 右開き方向

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    if (widget.book.path != null) {
      try {
        final doc = await pdfx.PdfDocument.openFile(widget.book.path!);
        if (mounted) {
          setState(() {
            _pdfDocument = doc;
            _pageCount = doc.pagesCount;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _pdfDocument?.close();
    PaintingBinding.instance.imageCache.clear();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double screenWidth) {
    setState(() {
      _isDragging = true;
      // 右から左へ（次のページ）
      _dragProgress -= details.delta.dx / screenWidth;
      _dragProgress = _dragProgress.clamp(-1.0, 1.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      if (_dragProgress > 0.3 && _currentPageIndex < _pageCount - 1) {
        _currentPageIndex++;
      } else if (_dragProgress < -0.3 && _currentPageIndex > 0) {
        _currentPageIndex--;
      }
      _dragProgress = 0.0;
      PaintingBinding.instance.imageCache.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : GestureDetector(
              onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, screenWidth),
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Stack(
                children: [
                  // ベース（現在のページ）
                  SinglePdfPageWidget(
                    key: ValueKey('page_${_currentPageIndex}'),
                    document: _pdfDocument!,
                    pageNumber: _currentPageIndex + 1,
                  ),

                  // めくられている最中のページと3Dカール影
                  if (_isDragging && _dragProgress != 0.0) ...[
                    // 背面の影（捲れた下のページに落ちる影）
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity((_dragProgress.abs() * 0.4).clamp(0.0, 0.4)),
                      ),
                    ),

                    // カールする紙（3D変形と湾曲シャドウ）
                    Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // 遠近感
                        ..rotateY(_dragProgress * math.pi * 0.45), // しなり回転
                      alignment: _dragProgress > 0 ? Alignment.centerLeft : Alignment.centerRight,
                      child: Stack(
                        children: [
                          SinglePdfPageWidget(
                            key: ValueKey('curl_page_${_currentPageIndex}'),
                            document: _pdfDocument!,
                            pageNumber: (_dragProgress > 0
                                    ? (_currentPageIndex + 1).clamp(0, _pageCount - 1)
                                    : (_currentPageIndex - 1).clamp(0, _pageCount - 1)) +
                                1,
                          ),
                          // 本物の紙の立体感（画像の中央の黒い折り目グラデーション）
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black.withOpacity(0.5),
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.2),
                                    Colors.black.withOpacity(0.4),
                                  ],
                                  stops: const [0.0, 0.15, 0.85, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ページ数インジケーター
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentPageIndex + 1} / $_pageCount ページ',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class SinglePdfPageWidget extends StatefulWidget {
  final pdfx.PdfDocument document;
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
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _renderPage();
  }

  @override
  void dispose() {
    _imageBytes = null;
    super.dispose();
  }

  Future<void> _renderPage() async {
    try {
      final page = await widget.document.getPage(widget.pageNumber);
      final pageImage = await page.render(
        width: page.width,
        height: page.height,
        format: pdfx.PdfPageImageFormat.jpeg,
      );

      if (mounted) {
        setState(() {
          _imageBytes = pageImage?.bytes;
        });
      }
    } catch (e) {
      // エラーハンドリング
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageBytes == null) {
      return Container(
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator(color: Colors.brown)),
      );
    }
    return Container(
      color: Colors.white,
      child: Center(
        child: Image.memory(
          _imageBytes!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
