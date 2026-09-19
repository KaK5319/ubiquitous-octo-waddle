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
  final PageController _pageController = PageController();
  final int totalPages = 10;
  int currentPage = 0;

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
            // インデックスを反転させてページ番号を計算（右開き仕様）
            currentPage = (totalPages - 1) - index;
          });
        },
        itemBuilder: (context, index) {
          // 表示するページ番号も反転させる
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
