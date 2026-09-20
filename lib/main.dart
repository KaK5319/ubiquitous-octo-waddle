import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_turn/page_turn.dart';
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
  final GlobalKey<PageTurnState> _pageTurnKey = GlobalKey<PageTurnState>();
  PdfDocument? _pdfDocument;
  List<PdfPageImage?> _pageImages = [];
  bool _isLoading = true;
  int _totalPages = 0;
  int _currentPage = 0; // 0ベース

  bool _isRightSwipe = false; // true: 右開き, false: 左開き
  bool _showUI = true; // 上下のバーを表示するかどうかのフラグ

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

  /// ページ指定ダイアログ
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
                  // 特定ページへジャンプ
                  setState(() {
                    _currentPage = pageNum - 1;
                  });
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
    _pdfDocument?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 開き方向によってページ順序を反転
    final displayImages = _isRightSwipe ? _pageImages.reversed.toList() : _pageImages;

    return Scaffold(
      backgroundColor: const Color(0xFF222222),
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
                    // 1. 本のページめくり (PageTurn)
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (details) {
                        final touchX = details.globalPosition.dx;
                        final leftZone = screenWidth * 0.3;
                        final rightZone = screenWidth * 0.7;

                        // 画面中央タップでバー表示/非表示切り替え
                        if (touchX >= leftZone && touchX <= rightZone) {
                          setState(() {
                            _showUI = !_showUI;
                          });
                        }
                      },
                      child: PageTurn(
                        key: _pageTurnKey,
                        backgroundColor: const Color(0xFF1A1A1A),
                        showHourGlass: false,
                        children: List.generate(_totalPages, (index) {
                          final image = displayImages[index];
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

                    // 2. 上部アプリバー
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
                              const SizedBox(width: 70),
                              // ページ番号表示
                              GestureDetector(
                                onTap: _totalPages > 0 ? _showPageJumpDialog : null,
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
                              // 右開き / 左開き 切り替え
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isRightSwipe = !_isRightSwipe;
                                  });
                                },
                                icon: Icon(
                                  _isRightSwipe
                                      ? Icons.arrow_back
                                      : Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                label: Text(
                                  _isRightSwipe ? '右開き' : '左開き',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. 下部シークバー（両端の数字なし）
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
                            max: (_totalPages - 1).toDouble(),
                            divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                            activeColor: Colors.blueAccent,
                            inactiveColor: Colors.white24,
                            onChanged: (double value) {
                              setState(() {
                                _currentPage = value.round();
                              });
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
