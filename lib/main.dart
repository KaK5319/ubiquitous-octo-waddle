import 'package:flutter/material.dart';

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

// 本のデータモデル
class BookItem {
  final String id;
  final String title;
  final String author;
  final Color coverColor;
  bool isFavorite;

  BookItem({
    required this.id,
    required this.title,
    required this.author,
    required this.coverColor,
    this.isFavorite = false,
  });
}

// メイン本棚画面
class MainShelfScreen extends StatefulWidget {
  const MainShelfScreen({super.key});

  @override
  State<MainShelfScreen> createState() => _MainShelfScreenState();
}

class _MainShelfScreenState extends State<MainShelfScreen> {
  final List<BookItem> _books = [
    BookItem(id: '1', title: 'サンプル文書 1', author: '著者 A', coverColor: Colors.teal),
    BookItem(id: '2', title: 'マニュアル PDF', author: '公式ガイド', coverColor: Colors.indigo),
    BookItem(id: '3', title: 'プロジェクト資料', author: 'チーム B', coverColor: Colors.deepOrange),
    BookItem(id: '4', title: 'デザイン設計書', author: 'デザイナー C', coverColor: Colors.brown),
  ];

  void _addNewBook() {
    setState(() {
      final newId = (_books.length + 1).toString();
      _books.add(
        BookItem(
          id: newId,
          title: '新規ドキュメント $newId',
          author: 'マイフォルダ',
          coverColor: Colors.blueGrey,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SideBooks 本棚'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 棚の装飾ヘッダー
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
          // 本棚グリッド
          Expanded(
            child: GridView.builder(
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookViewerScreen(book: book),
                      ),
                    );
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
                        // 背表紙風デザイン
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 8,
                          child: Container(
                            color: Colors.black12,
                          ),
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.author,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                book.isFavorite = !book.isFavorite;
                              });
                            },
                            child: Icon(
                              book.isFavorite ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            ),
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
        onPressed: _addNewBook,
        backgroundColor: const Color(0xFF5D4037),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ドキュメント閲覧画面 (Viewer)
class BookViewerScreen extends StatefulWidget {
  final BookItem book;

  const BookViewerScreen({super.key, required this.book});

  @override
  State<BookViewerScreen> createState() => _BookViewerScreenState();
}

class _BookViewerScreenState extends State<BookViewerScreen> {
  int _currentPage = 1;
  final int _totalPages = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {},
          ),
        ],
      ),
      body: PageView.builder(
        itemCount: _totalPages,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index + 1;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.book.title}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ページ ${index + 1} / $_totalPages',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.description,
                    size: 100,
                    color: Colors.black38,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '左右にスワイプしてページをめくれます。',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_currentPage / $_totalPages ページ',
              style: const TextStyle(color: Colors.white),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_in, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
