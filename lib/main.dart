import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SideBooksApp());
}

class SideBooksApp extends StatelessWidget {
  const SideBooksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SideBooks Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFF4EFEA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5D4037),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const MainShelfScreen(),
    );
  }
}

class BookItem {
  final String id;
  final String title;
  final String? path;
  final Color coverColor;
  bool isFavorite;

  BookItem({
    required this.id,
    required this.title,
    this.path,
    required this.coverColor,
    this.isFavorite = false,
  });
}

class MainShelfScreen extends StatefulWidget {
  const MainShelfScreen({super.key});

  @override
  State<MainShelfScreen> createState() => _MainShelfScreenState();
}

class _MainShelfScreenState extends State<MainShelfScreen> {
  final List<BookItem> _books = [];

  // 端末からPDFを選択して追加する関数
  Future<void> _pickPDFFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      PlatformFile file = result.files.single;
      setState(() {
        _books.add(
          BookItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: file.name,
            path: file.path,
            coverColor: Colors.brown.shade700,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SideBooks 本棚'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.sort), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF8D6E63),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'すべての本 (${_books.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.grid_view, color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: _books.isEmpty
                ? const Center(
                    child: Text(
                      '右下の「+」ボタンから\nPDFファイルを追加してください',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      final book = _books[index];
                      return GestureDetector(
                        onTap: () {
                          if (book.path != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PDFViewerScreen(book: book),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: book.coverColor,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 8,
                                child: Container(color: Colors.black12),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Spacer(),
                                    Text(
                                      book.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickPDFFile,
        backgroundColor: const Color(0xFF5D4037),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// PDF表示画面
class PDFViewerScreen extends StatefulWidget {
  final BookItem book;

  const PDFViewerScreen({super.key, required this.book});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.book.path,
            enableSwipe: true,
            swipeHorizontal: true, // 横めくり設定
            autoSpacing: false,
            pageFling: true,
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0;
              });
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page ?? 0;
              });
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPage + 1} / $_totalPages ページ',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
