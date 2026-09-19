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
      body: Directionality(
        textDirection: TextDirection.rtl, // 右開きスワイプ方向（←へめくると進む）
        child: PageView.builder(
          controller: _pageController,
          itemCount: totalPages,
          onPageChanged: (int index) {
            setState(() {
              currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            return Directionality(
              textDirection: TextDirection.ltr, // コンテンツの文字・表示方向は標準（左から右）に復元
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  color: Colors.grey[900],
                  child: Center(
                    child: Text(
                      '${index + 1} ページ目',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
