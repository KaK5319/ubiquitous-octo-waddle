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
    // 右開き用に初期ページを最後のインデックスに設定（インデックスを反転させて制御）
    _pageController = PageController(initialPage: 0);
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
      body: Directionality(
        textDirection: TextDirection.rtl, // 右開き（左スワイプで進む）設定
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
              textDirection: TextDirection.ltr, // コンテンツ（テキスト・画像）の向きを正常に戻す
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
