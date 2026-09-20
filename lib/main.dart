import 'dart:io';
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
  late PageController _pageController;
  PdfDocument? _pdfDocument;
  List<PdfPageImage?> _pageImages = [];
  bool _isLoading = true;
  int _totalPages = 0;
  int _currentPage = 0; // 0ベース

  bool _isRightSwipe = false; // true: 右開き（マンガ）, false: 左開き（書籍）

  final String _samplePdfUrl =
      'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
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

  /// ページ移動処理（アニメーション付き）
  void _goToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < _totalPages) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 次のページへ
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  /// 前のページへ
  void _previousPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  /// ページ指定入力ダイアログ
  void _showPageJumpDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ページ指定移動'),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '1 ～ $_totalPages の数字を入力',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final pageNum = int.tryParse(textController.text);
                if (pageNum != null && pageNum >= 1 && pageNum <= _totalPages) {
                  _goToPage(pageNum - 1);
                  Navigator.pop(context);
                }
              },
              child: const Text('移動'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        title: GestureDetector(
          onTap: _totalPages > 0 ? _showPageJumpDialog : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _totalPages > 0
                    ? '${_currentPage + 1} / $_totalPages ページ'
                    : '読み込み中...',
                style: const TextStyle(fontSize: 16),
              ),
              if (_totalPages > 0)
                const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isRightSwipe = !_isRightSwipe;
              });
            },
            icon: Icon(
              _isRightSwipe ? Icons.arrow_back : Icons.arrow_forward,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              _isRightSwipe ? '右開き(マンガ)' : '左開き(書籍)',
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
                  Text('PDFを読み込み中...'),
                ],
              ),
            )
          : _pageImages.isEmpty
              ? const Center(child: Text('PDFの読み込みに失敗しました。'))
              : Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapUp: (details) {
                          final touchPositionX = details.globalPosition.dx;
                          if (_isRightSwipe) {
                            if (touchPositionX < screenWidth / 2) {
                              _nextPage();
                            } else {
                              _previousPage();
                            }
                          } else {
                            if (touchPositionX > screenWidth / 2) {
                              _nextPage();
                            } else {
                              _previousPage();
                            }
                          }
                        },
                        child: PageView.builder(
                          controller: _pageController,
                          reverse: _isRightSwipe, // 右開き・左開きの切り替え
                          itemCount: _totalPages,
                          onPageChanged: (index) {
                            // ページが変わるたびに上のテキストとスライダーを確実に更新
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
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
                          },
                        ),
                      ),
                    ),
                    // 画面下部のシークバー
                    if (_totalPages > 1)
                      Container(
                        color: Colors.black.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            children: [
                              const Text(
                                '1',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _currentPage.toDouble(),
                                  min: 0,
                                  max: (_totalPages - 1).toDouble(),
                                  divisions:
                                      _totalPages > 1 ? _totalPages - 1 : 1,
                                  activeColor: Colors.blueAccent,
                                  inactiveColor: Colors.white24,
                                  onChanged: (double value) {
                                    _goToPage(value.round());
                                  },
                                ),
                              ),
                              Text(
                                '$_totalPages',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
