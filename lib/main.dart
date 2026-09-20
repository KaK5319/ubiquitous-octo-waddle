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
      home: const ReaderScreen(),
    );
  }
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({Key? key}) : super(key: key);

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
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
    final screenWidth = MediaQuery.of(context).size.width;

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
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) {
          // 画面右半分タップで「次へ」、左半分タップで「前へ」
          if (details.globalPosition.dx > screenWidth / 2) {
            _nextPage();
          } else {
            _previousPage();
          }
        },
        onHorizontalDragEnd: (details) {
          // 右スワイプ（→）で「次へ」、左スワイプ（←）で「前へ」
          if (details.primaryVelocity! > 100) {
            _nextPage();
          } else if (details.primaryVelocity! < -100) {
            _previousPage();
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[900],
          margin: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              '${currentPage + 1} ページ目',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
