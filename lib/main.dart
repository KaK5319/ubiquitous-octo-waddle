import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

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
      home: const CustomCurlReaderScreen(),
    );
  }
}

class CustomCurlReaderScreen extends StatefulWidget {
  const CustomCurlReaderScreen({Key? key}) : super(key: key);

  @override
  State<CustomCurlReaderScreen> createState() => _CustomCurlReaderScreenState();
}

class _CustomCurlReaderScreenState extends State<CustomCurlReaderScreen>
    with SingleTickerProviderStateMixin {
  PdfDocument? _pdfDocument;
  List<ui.Image> _decodedImages = [];
  bool _isLoading = true;
  int _totalPages = 0;
  int _currentPage = 0;

  late AnimationController _animController;
  double _dragProgress = 0.0;
  bool _isDragging = false;

  final String _samplePdfUrl =
      'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        setState(() {
          _dragProgress = _animController.value;
        });
      });

    _loadAndRenderPdf();
  }

  Future<void> _loadAndRenderPdf() async {
    try {
      final response = await http.get(Uri.parse(_samplePdfUrl));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/curl_sample_v3.pdf');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      final doc = await PdfDocument.openFile(file.path);
      final count = doc.pagesCount;
      List<ui.Image> images = [];

      for (int i = 1; i <= count; i++) {
        final page = await doc.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
        );
        await page.close();

        if (pageImage != null) {
          final codec = await ui.instantiateImageCodec(pageImage.bytes);
          final frame = await codec.getNextFrame();
          images.add(frame.image);
        }
      }

      if (mounted) {
        setState(() {
          _pdfDocument = doc;
          _totalPages = count;
          _decodedImages = images;
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
  void dispose() {
    _animController.dispose();
    _pdfDocument?.close();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double screenWidth) {
    if (_animController.isAnimating) return;
    _isDragging = true;
    
    // 左スワイプ（←）でめくる
    final delta = -details.primaryDelta! / screenWidth;
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _dragProgress = (_dragProgress + delta).clamp(0.0, 1.0);
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    if (_dragProgress > 0.3) {
      _animController.forward(from: _dragProgress).then((_) {
        setState(() {
          if (_currentPage < _totalPages - 1) {
            _currentPage++;
          }
          _dragProgress = 0.0;
          _animController.value = 0.0;
        });
      });
    } else {
      _animController.reverse(from: _dragProgress).then((_) {
        setState(() {
          _dragProgress = 0.0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
        title: Text(
          _totalPages > 0 ? '${_currentPage + 1} / $_totalPages ページ' : '読み込み中...',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('PDFを構築中...'),
                ],
              ),
            )
          : GestureDetector(
              onHorizontalDragUpdate: (details) =>
                  _onHorizontalDragUpdate(details, screenWidth),
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: CustomPaint(
                size: Size.infinite,
                painter: PageCurlPainter(
                  currentPageImage: _currentPage < _decodedImages.length
                      ? _decodedImages[_currentPage]
                      : null,
                  nextPageImage: (_currentPage + 1) < _decodedImages.length
                      ? _decodedImages[_currentPage + 1]
                      : null,
                  progress: _dragProgress,
                ),
              ),
            ),
    );
  }
}

class PageCurlPainter extends CustomPainter {
  final ui.Image? currentPageImage;
  final ui.Image? nextPageImage;
  final double progress;

  PageCurlPainter({
    required this.currentPageImage,
    required this.nextPageImage,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 1. 次のページを描画 (背面)
    if (nextPageImage != null) {
      _drawImageFit(canvas, size, nextPageImage!, paint);
    }

    if (currentPageImage == null) return;

    // めくられていない状態なら通常描画
    if (progress <= 0.0) {
      _drawImageFit(canvas, size, currentPageImage!, paint);
      return;
    }

    // 2. 現在のページ（クリップしてめくり効果を演出）
    final curlX = size.width * (1.0 - progress);

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, curlX, size.height));
    _drawImageFit(canvas, size, currentPageImage!, paint);
    canvas.restore();

    // 3. めくれ目のカール影（立体グラデーション）
    final shadowWidth = 40.0;
    final shadowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(curlX - shadowWidth, 0),
        Offset(curlX + shadowWidth / 2, 0),
        [
          Colors.transparent,
          Colors.black.withOpacity(0.4),
          Colors.black.withOpacity(0.1),
          Colors.transparent,
        ],
        [0.0, 0.6, 0.85, 1.0],
      );

    canvas.drawRect(
      Rect.fromLTRB(curlX - shadowWidth, 0, curlX + shadowWidth / 2, size.height),
      shadowPaint,
    );
  }

  void _drawImageFit(Canvas canvas, Size size, ui.Image image, Paint paint) {
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant PageCurlPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.currentPageImage != currentPageImage ||
        oldDelegate.nextPageImage != nextPageImage;
  }
}
