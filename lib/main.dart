import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

void main() {
  runApp(const SideBooksCloneApp());
}

class SideBooksCloneApp extends StatelessWidget {
  const SideBooksCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SideBooks Clone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const BookshelfPage(),
    );
  }
}

class BookItem {
  final String title;
  final String path;
  final bool isZip;

  BookItem({required this.title, required this.path, required this.isZip});
}

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  List<BookItem> _books = [];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'zip'],
    );

    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      String fileName = p.basename(path);
      bool isZip = fileName.toLowerCase().endsWith('.zip');

      setState(() {
        _books.add(BookItem(title: fileName, path: path, isZip: isZip));
      });
    }
  }

  void _openBook(BookItem book) {
    if (book.isZip) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ZipViewerPage(zipPath: book.path, title: book.title),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(pdfPath: book.path, title: book.title),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本棚 (SideBooks Clone)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _books.isEmpty
          ? const Center(child: Text('右下の「+」からPDFまたはZIPを追加してください'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                return GestureDetector(
                  onTap: () => _openBook(book),
                  child: Card(
                    elevation: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          book.isZip ? Icons.folder_zip : Icons.picture_as_pdf,
                          size: 48,
                          color: book.isZip ? Colors.orange : Colors.red,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFile,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PdfViewerPage extends StatelessWidget {
  final String pdfPath;
  final String title;

  const PdfViewerPage({super.key, required this.pdfPath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PDFView(
        filePath: pdfPath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
      ),
    );
  }
}

class ZipViewerPage extends StatefulWidget {
  final String zipPath;
  final String title;

  const ZipViewerPage({super.key, required this.zipPath, required this.title});

  @override
  State<ZipViewerPage> createState() => _ZipViewerPageState();
}

class _ZipViewerPageState extends State<ZipViewerPage> {
  List<File> _images = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _extractZip();
  }

  Future<void> _extractZip() async {
    final bytes = File(widget.zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    final tempDir = await getTemporaryDirectory();
    List<File> extractedFiles = [];

    for (final file in archive) {
      if (file.isFile &&
          (file.name.endsWith('.jpg') ||
              file.name.endsWith('.png') ||
              file.name.endsWith('.jpeg'))) {
        final data = file.content as List<int>;
        final outFile = File('${tempDir.path}/${p.basename(file.name)}');
        await outFile.writeAsBytes(data);
        extractedFiles.add(outFile);
      }
    }

    extractedFiles.sort((a, b) => a.path.compareTo(b.path));

    setState(() {
      _images = extractedFiles;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? const Center(child: Text('画像が見つかりませんでした'))
              : PageView.builder(
                  reverse: true,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Image.file(_images[index], fit: BoxFit.contain);
                  },
                ),
    );
  }
}
