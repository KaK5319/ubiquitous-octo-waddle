import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';

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
  ui.FragmentShader? _shader;
  bool _isLoading = true;
  int _pageCount = 0;
  int _currentIndex = 0;
  double _dragProgress = 0.0;
  
  final Map<int, ui.Image> _imageMap = {};

  @override
  void initState() {
    super.initState();
    _initShaderAndPdf();
  }

  Future<void> _initShaderAndPdf() async {
    final program = await ui.FragmentProgram.fromAsset('shaders/page_curl.frag');
    _shader = program.fragmentShader();

    _pdfDocument = await PdfDocument.openFile(widget.filePath);
    _pageCount = _pdfDocument.pagesCount;

    // 最初の2ページだけ読み込んで高速起動
    await _preloadPages(_currentIndex);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _preloadPages(int index) async {
    // 現在のページとその前後のみ準備
    final pagesToLoad = [index + 1, index + 2, index + 3];
    for (var p in pagesToLoad) {
      if (p >= 1 && p <= _pageCount && !_imageMap.containsKey(p)) {
        await _renderPageUi(p);
      }
    }
  }

  Future<ui.Image> _renderPageUi(int pageNumber) async {
    if (_imageMap.containsKey(pageNumber)) {
      return _imageMap[pageNumber]!;
    }
    final page = await _pdfDocument.getPage(pageNumber);
    final pageImage = await page.render(
      width: page.width * 1.5,
      height: page.height * 1.5,
      format: PdfPageImageFormat.jpeg,
    );
    await page.close();

    final codec = await ui.instantiateImageCodec(pageImage!.bytes);
    final frame = await codec.getNextFrame();
    _imageMap[pageNumber] = frame.image;
    return frame.image;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double screenWidth) {
    setState(() {
      _dragProgress -= details.primaryDelta! / screenWidth;
      _dragProgress = _dragProgress.clamp(0.0, 1.0);
    });

    // めくっている最中に裏で次ページを準備
    _preloadPages(_currentIndex + 1);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragProgress > 0.3 && _currentIndex + 1 < _pageCount) {
      setState(() {
        _currentIndex++;
        _dragProgress = 0.0;
      });
      _preloadPages(_currentIndex);
    } else {
      setState(() {
        _dragProgress = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _pdfDocument.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / $_pageCount'),
      ),
      body: _isLoading || _shader == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : GestureDetector(
              onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, size.width),
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: CustomPaint(
                size: size,
                painter: PageCurlPainter(
                  shader: _shader!,
                  currentImage: _imageMap[_currentIndex + 1],
                  nextImage: _imageMap[_currentIndex + 2] ?? _imageMap[_currentIndex + 1],
                  progress: _dragProgress,
                ),
              ),
            ),
    );
  }
}

class PageCurlPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image? currentImage;
  final ui.Image? nextImage;
  final double progress;

  PageCurlPainter({
    required this.shader,
    required this.currentImage,
    required this.nextImage,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentImage == null) return;

    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, progress);
    shader.setImageSampler(0, currentImage!);
    shader.setImageSampler(1, nextImage ?? currentImage!);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant PageCurlPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.currentImage != currentImage ||
        oldDelegate.nextImage != nextImage;
  }
}
