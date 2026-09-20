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
  final int totalPages = 10;
  int currentPage = 0;

  void _nextPage() {
    if (currentPage < totalPages - 1) {
      setState(() {
        currentPage++;
      });
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
    }
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          // X軸の速度を直接判定（左方向のスワイプ＝負の値）
          if (details.primaryVelocity! < 0) {
            // 左スワイプ（←）: 次のページへ進む（マンガ仕様）
            _nextPage();
          } else if (details.primaryVelocity! > 0) {
            // 右スワイプ（→）: 前のページへ戻る
            _previousPage();
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey<int>(currentPage),
            margin: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Center(
              child: Text(
                '${currentPage + 1} ページ目',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
