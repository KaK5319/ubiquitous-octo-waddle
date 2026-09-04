import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:archive/archive.dart';
import 'package:unrar_flut/unrar_flut.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BookViewerPage(),
    );
  }
}

class BookViewerPage extends StatefulWidget {
  const BookViewerPage({super.key});

  @override
  State<BookViewerPage> createState() => _BookViewerPageState();
}

class _BookViewerPageState extends State<BookViewerPage> {
  String? _filePath;
  List<String> _extractedImages = [];
  bool _isLoading = false;
  String _loadingText = '';

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final extension = p.extension(path).toLowerCase();

        if (extension == '.pdf') {
          setState(() {
            _filePath = path;
            _extractedImages = [];
          });
        } else if (extension == '.zip') {
          await _extractZip(path);
        } else if (extension == '.rar') {
          await _extractRar(path);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF、ZIP、またはRARファイルを選択してください')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ファイル選択エラー: $e')),
        );
      }
    }
  }

  Future<void> _extractZip(String zipPath) async {
    setState(() {
      _isLoading = true;
      _loadingText = 'ZIPファイルを解凍中...';
    });

    try {
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final tempDir = await getTemporaryDirectory();
      final outDir = Directory('${tempDir.path}/extracted_${DateTime.now().millisecondsSinceEpoch}');
      await outDir.create(recursive: true);

      List<String> imagePaths = [];

      for (final file in archive) {
        if (file.isFile) {
          final filename = file.name;
          final ext = p.extension(filename).toLowerCase();
          if (['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
            final data = file.content as List<int>;
            final outFile = File('${outDir.path}/$filename');
            await outFile.writeAsBytes(data);
            imagePaths.add(outFile.path);
          }
        }
      }

      imagePaths.sort();

      setState(() {
        _filePath = null;
        _extractedImages = imagePaths;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ZIPの読み込みに失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _extractRar(String rarPath) async {
    setState(() {
      _isLoading = true;
      _loadingText = 'RARファイルを解凍中...';
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final outDir = Directory('${tempDir.path}/extracted_rar_${DateTime.now().millisecondsSinceEpoch}');
      await outDir.create(recursive: true);

      // UnrarFlutで解凍処理
      await UnrarFlut.extractRar(
        rarPath: rarPath,
        outputPath: outDir.path,
      );

      List<String> imagePaths = [];
      final files = outDir.listSync(recursive: true);

      for (final entity in files) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
            imagePaths.add(entity.path);
          }
        }
      }

      imagePaths.sort();

      setState(() {
        _filePath = null;
        _extractedImages = imagePaths;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('RARの読み込みに失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SideBooks Clone'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _pickFile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_loadingText),
                ],
              ),
            )
          : _filePath != null
              ? PDFView(
                  filePath: _filePath,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: false,
                  pageFling: true,
                )
              : _extractedImages.isNotEmpty
                  ? PageView.builder(
                      reverse: true,
                      itemCount: _extractedImages.length,
                      itemBuilder: (context, index) {
                        return Image.file(
                          File(_extractedImages[index]),
                          fit: BoxFit.contain,
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('PDF、ZIP、またはRARファイルを選択してください'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('ファイルを開く'),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
