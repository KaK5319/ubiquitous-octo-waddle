import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:page_flip/page_flip.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SideBooks Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BookshelfScreen(),
    );
  }
}

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(filePath: result.files.single.path!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本棚')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _pickPDF,
          icon: const Icon(Icons.folder_open),
          label: const Text('PDFファイルを開く'),
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfDocument _pdfDocument;
  final GlobalKey<PageFlipWidgetState> _controller = GlobalKey<PageFlipWidgetState>();
  bool _isLoading = true;
  int _pageCount = 0;
  final Map<int, ImageProvider> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    _pdfDocument = await PdfDocument.openFile(widget.filePath);
    _pageCount = _pdfDocument.pagesCount;

    // 最初の数ページを事前にレンダリングして準備完了にする
    for (int i = 1; i <= (_pageCount < 3 ? _pageCount : 3); i++) {
      await _renderPage(i);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<ImageProvider> _renderPage(int pageNumber) async {
    if (_imageCache.containsKey(pageNumber)) {
      return _imageCache[pageNumber]!;
    }
    final page = await _pdfDocument.getPage(pageNumber);
    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.jpeg,
    );
    await page.close();
    final imageProvider = MemoryImage(pageImage!.bytes);
    _imageCache[pageNumber] = imageProvider;
    return imageProvider;
  }

  @override
  void dispose() {
    _pdfDocument.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.filePath.split('/').last),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageFlipWidget(
              key: _controller,
              backgroundColor: Colors.black,
              isRightSwipe: true, // 右開き（和書・漫画用）
              children: List.generate(_pageCount, (index) {
                final pageNumber = index + 1;
                return PdfPageWidget(
                  pageNumber: pageNumber,
                  onLoad: () => _renderPage(pageNumber),
                );
              }),
            ),
    );
  }
}

class PdfPageWidget extends StatefulWidget {
  final int pageNumber;
  final Future<ImageProvider> Function() onLoad;

  const PdfPageWidget({
    super.key,
    required this.pageNumber,
    required this.onLoad,
  });

  @override
  State<PdfPageWidget> createState() => _PdfPageWidgetState();
}

class _PdfPageWidgetState extends State<PdfPageWidget> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final img = await widget.onLoad();
    if (mounted) {
      setState(() {
        _imageProvider = img;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageProvider == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: Image(
        image: _imageProvider!,
        fit: BoxFit.contain,
      ),
    );
  }
}
