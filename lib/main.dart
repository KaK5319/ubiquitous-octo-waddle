import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_flip/page_flip.dart';
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
      home: const PageCurlReaderScreen(),
    );
  }
}

class PageCurlReaderScreen extends StatefulWidget {
  const PageCurlReaderScreen({Key? key}) : super(key: key);

  @override
  State<PageCurlReaderScreen> createState() => _PageCurlReaderScreenState();
}

class _PageCurlReaderScreenState extends State<PageCurlReaderScreen> {
  final _controller = GlobalKey<PageFlipWidgetState>();
  PdfDocument? _pdfDocument;
  List<PdfPageImage?> _pageImages = [];
  bool _isLoading = true;
  int _totalPages = 0;

  // 設定用フラグ
  bool _isRightSwipe = false; // true: 右開き（マンガ）, false: 左開き（書籍）[span_0](start_span)[span_0](end_span)[span_1](start_span)[span_1](end_span)[span_2](start_span)[span_2](end_span)[span_3](start_span)[span_3](end_span)

  final String _samplePdfUrl =
      'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf';

  @override
  void initState() {
    super.initState();
    _loadAndRenderPdf();
  }

  Future<void> _loadAndRenderPdf() async {
    try {
      final response = await http.get(Uri.parse(_samplePdfUrl));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/curl_sample.pdf');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      final doc = await PdfDocument.openFile(file.path);
      final count = doc.pagesCount;
      List<PdfPageImage?> images = [];

      for (int i = 1; i <= count; i++) {
        final page = await doc.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
        );
        await page.close();
        images.add(pageImage);
      }

      if (mounted) {
        setState(() {
          _pdfDocument = doc;
          _totalPages = count;
          _pageImages = images;
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

  /// 次のページに進む
  void _nextPage() {
    _controller.currentState?.nextPage();
  }

  /// 前のページに戻る
  void _previousPage() {
    _controller.currentState?.previousPage();
  }

  @override
  void dispose() {
    _pdfDocument?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF222222),
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: Text(
          _totalPages > 0 ? '全 $_totalPages ページ' : '読み込み中...',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isRightSwipe = !_isRightSwipe; //[span_4](start_span)[span_4](end_span)
              });
            },
            icon: Icon(
              _isRightSwipe ? Icons.arrow_back : Icons.arrow_forward, //[span_5](start_span)[span_5](end_span)
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              _isRightSwipe ? '右開き(マンガ)' : '左開き(書籍)', //[span_6](start_span)[span_6](end_span)
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('PDFをページめくり用に変換中...'),
                ],
              ),
            )
          : _pageImages.isEmpty
              ? const Center(child: Text('PDFの読み込みに失敗しました。'))
              : GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) {
                    final touchPositionX = details.globalPosition.dx;

                    if (_isRightSwipe) {
                      // 右開き（マンガ）の場合: 左側タップで進む、右側タップで戻る[span_7](start_span)[span_7](end_span)
                      if (touchPositionX < screenWidth / 2) {
                        _nextPage();
                      } else {
                        _previousPage();
                      }
                    } else {
                      // 左開き（書籍）の場合: 右側タップで進む、左側タップで戻る[span_8](start_span)[span_8](end_span)
                      if (touchPositionX > screenWidth / 2) {
                        _nextPage();
                      } else {
                        _previousPage();
                      }
                    }
                  },
                  child: PageFlipWidget(
                    key: _controller,
                    backgroundColor: const Color(0xFF1A1A1A), //[span_9](start_span)[span_9](end_span)
                    isRightSwipe: _isRightSwipe, //[span_10](start_span)[span_10](end_span)
                    children: List.generate(_totalPages, (index) {
                      final image = _pageImages[index];
                      if (image == null) return const SizedBox.shrink();

                      return Container(
                        color: Colors.white,
                        child: Center(
                          child: Image.memory(
                            image.bytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
    );
  }
}
