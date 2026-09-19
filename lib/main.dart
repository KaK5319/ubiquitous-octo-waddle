import 'package:flutter/material.dart';

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
      home: const MangaReaderScreen(),
    );
  }
}

class MangaReaderScreen extends StatefulWidget {
  const MangaReaderScreen({Key? key}) : super(key: key);

  @override
  State<MangaReaderScreen> createState() => _MangaReaderScreenState();
}

class _MangaReaderScreenState extends State<MangaReaderScreen> {
  late PageController _pageController;
  final int totalPages = 10;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    // 初期ページを末尾インデックスに指定（1ページ目を画面に表示）
    _pageController = PageController(initialPage: totalPages - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: Text(
          '${currentPage + 1} / $totalPages',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: totalPages,
        onPageChanged: (int index) {
          setState(() {
            // インデックス反転（右開き制御）
            currentPage = (totalPages - 1) - index;
          });
        },
        itemBuilder: (context, index) {
          // ページ内容の反転設定
          final displayPageIndex = (totalPages - 1) - index;
          return Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              color: Colors.grey[900],
              child: Center(
                child: Text(
                  '${displayPageIndex + 1} ページ目',
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
