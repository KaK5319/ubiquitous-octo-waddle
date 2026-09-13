import 'dart:math';
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
  late PageController _pageController;
  bool _isLoading = true;
  int _pageCount = 0;
  final Map<int, ImageProvider> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    _pdfDocument = await PdfDocument.openFile(widget.filePath);
    setState(() {
      _pageCount = _pdfDocument.pagesCount;
      _isLoading = false;
    });
  }

  Future<ImageProvider> _getOrRenderPage(int pageNumber) async {
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
    _pageController.dispose();
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
          : PageView.builder(
              controller: _pageController,
              itemCount: _pageCount,
              itemBuilder: (context, index) {
                final pageNumber = index + 1;

                return FutureBuilder<ImageProvider>(
                  future: _getOrRenderPage(pageNumber),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final pageImageProvider = snapshot.data!;
                    final pageWidget = Image(
                      image: pageImageProvider,
                      fit: BoxFit.contain,
                    );

                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double pageOffset = 0;
                        if (_pageController.position.haveDimensions) {
                          pageOffset = (_pageController.page ?? 0) - index;
                        }

                        if (pageOffset.abs() < 0.001) {
                          return pageWidget;
                        }

                        // ページを10分割して曲面構成
                        const int slices = 10;
                        final isFlippingForward = pageOffset > 0;
                        final progress = pageOffset.abs().clamp(0.0, 1.0);

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final sliceWidth = constraints.maxWidth / slices;

                            return Stack(
                              children: List.generate(slices, (i) {
                                final ratio = isFlippingForward
                                    ? (slices - 1 - i) / (slices - 1)
                                    : i / (slices - 1);

                                final bendAmount = pow(ratio, 1.5) * progress;
                                final angle = bendAmount * (pi / 2.5);
                                final shadowOpacity = sin(bendAmount * pi) * 0.5;

                                final transform = Matrix4.identity()
                                  ..setEntry(3, 2, 0.002)
                                  ..rotateY(isFlippingForward ? -angle : angle);

                                return Positioned(
                                  left: i * sliceWidth,
                                  top: 0,
                                  width: sliceWidth,
                                  height: constraints.maxHeight,
                                  child: Transform(
                                    transform: transform,
                                    alignment: isFlippingForward
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: Stack(
                                      children: [
                                        OverflowBox(
                                          alignment: Alignment(
                                            -1.0 + (i / (slices - 1)) * 2.0,
                                            0.0,
                                          ),
                                          minWidth: constraints.maxWidth,
                                          maxWidth: constraints.maxWidth,
                                          minHeight: constraints.maxHeight,
                                          maxHeight: constraints.maxHeight,
                                          child: pageWidget,
                                        ),
                                        Container(
                                          color: Colors.black.withOpacity(shadowOpacity),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
