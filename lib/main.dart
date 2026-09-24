import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:turnable_page/turnable_page.dart';

void main() {
  runApp(const SideBooksApp());
}

class SideBooksApp extends StatelessWidget {
  const SideBooksApp({super.key});

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
  const PageCurlReaderScreen({super.key});

  @override
  State<PageCurlReaderScreen> createState() => _PageCurlReaderScreenState();
}

class _PageCurlReaderScreenState extends State<PageCurlReaderScreen> {
  late TurnablePageController _turnableController;
  PdfDocument? _pdfDocument;
  List<PdfPageImage?> _pageImages = [];
  bool _isLoading = true;
  int _totalPages = 0;
  int _currentPage = 0;

  bool _isRightSwipe = true;
  bool _showUI = true;

  final String _samplePdfUrl =
      'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf';

  @override
  void initState() {
    super.initState();
    _turnableController = TurnablePageController();
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

  void _goToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < _totalPages) {
      _turnableController.flipToPage(pageIndex);
      setState(() {
        _currentPage = pageIndex;
      });
    }
  }

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
    _turnableController.dispose();
    _pdfDocument?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF151515),
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
              : Stack(
                  children: [
                    // 高精細なカールアニメーションを提供する TurnablePage
                    TurnablePage(
                      controller: _turnableController,
                      pageCount: _totalPages,
                      pageViewMode: PageViewMode.single,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      builder: (context, index, constraints) {
                        final image = _pageImages[index];
                        if (image == null) return const SizedBox.shrink();

                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) {
                            final touchX = details.globalPosition.dx;
                            final leftZone = screenWidth * 0.3;
                            final rightZone = screenWidth * 0.7;

                            // 中央領域タップでUI表示切替
                            if (touchX >= leftZone && touchX <= rightZone) {
                              setState(() {
                                _showUI = !_showUI;
                              });
                              return;
                            }

                            // タップめくり処理
                            if (_isRightSwipe) {
                              if (touchX < leftZone) {
                                _turnableController.flipNext();
                              } else if (touchX > rightZone) {
                                _turnableController.flipPrev();
                              }
                            } else {
                              if (touchX > rightZone) {
                                _turnableController.flipNext();
                              } else if (touchX < leftZone) {
                                _turnableController.flipPrev();
                              }
                            }
                          },
                          child: Container(
                            color: Colors.white,
                            child: Center(
                              child: Image.memory(
                                image.bytes,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // 上部ツールバー
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      top: _showUI ? 0 : -100,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top,
                        ),
                        color: Colors.black.withOpacity(0.85),
                        child: SizedBox(
                          height: kToolbarHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 80),
                              GestureDetector(
                                onTap: _totalPages > 0
                                    ? _showPageJumpDialog
                                    : null,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _totalPages > 0
                                          ? '${_currentPage + 1} / $_totalPages ページ'
                                          : '読み込み中...',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_totalPages > 0)
                                      const Icon(Icons.arrow_drop_down,
                                          color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isRightSwipe = !_isRightSwipe;
                                  });
                                },
                                child: Text(
                                  _isRightSwipe ? '→ 右開き' : '← 左開き',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 下部シークバー
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      bottom: _showUI ? 0 : -100,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black.withOpacity(0.85),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: SafeArea(
                          top: false,
                          child: Slider(
                            value: _currentPage.toDouble(),
                            min: 0,
                            max: (_totalPages - 1).toDouble().clamp(0.0, double.infinity),
                            divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                            activeColor: Colors.blueAccent,
                            inactiveColor: Colors.white24,
                            onChanged: (double value) {
                              _goToPage(value.round());
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
