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
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(filePath: result.files.single.path!),
        ),
      );
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

    await _manageCache(_currentIndex);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _manageCache(int index) async {
    final neededPages = {index + 1, index + 2, index + 3};

    final keysToRemove = _imageMap.keys.where((k) => !neededPages.contains(k)).toList();
    for (var k in keysToRemove) {
      _imageMap[k]?.dispose();
      _imageMap.remove(k);
    }

    for (var p in neededPages) {
      if (p >= 1 && p <= _pageCount && !_imageMap.containsKey(p)) {
        final img = await _renderPageUi(p);
        _imageMap[p] = img;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<ui.Image> _renderPageUi(int pageNumber) async {
    final page = await _pdfDocument.getPage(pageNumber);
    final pageImage = await page.render(
      width: page.width * 1.2,
      height: page.height * 1.2,
      format: PdfPageImageFormat.jpeg,
    );
    await page.close();

    final codec = await ui.instantiateImageCodec(pageImage!.bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double screenWidth) {
    setState(() {
      _dragProgress -= details.primaryDelta! / screenWidth;
      _dragProgress = _dragProgress.clamp(0.0, 1.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragProgress > 0.3 && _currentIndex + 1 < _pageCount) {
      setState(() {
        _currentIndex++;
        _dragProgress = 0.0;
      });
      _manageCache(_currentIndex);
    } else {
      setState(() {
        _dragProgress = 0.0;
      });
    }
  }

  @override
  void dispose() {
    for (var img in _imageMap.values) {
      img.dispose();
    }
    _pdfDocument.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentImg = _imageMap[_currentIndex + 1];
    final nextImg = _imageMap[_currentIndex + 2] ?? currentImg;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / $_pageCount'),
      ),
      body: _isLoading || _shader == null || currentImg == null
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
                  currentImage: currentImg,
                  nextImage: nextImg,
                  progress: _dragProgress,
                ),
              ),
            ),
    );
  }
}

class PageCurlPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image currentImage;
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
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, progress);
    shader.setImageSampler(0, currentImage);
    shader.setImageSampler(1, nextImage ?? currentImage);

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
