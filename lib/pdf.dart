import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MyHomePage extends StatefulWidget {
  final String file;
  MyHomePage({Key? key, required this.title, required this.file})
      : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerStateKey = GlobalKey();

  @override
  void initState() {
    _pdfViewerController = PdfViewerController();
    super.initState();
  }

  Future<void> _downloadFile() async {
    firebase_storage.Reference ref =
        firebase_storage.FirebaseStorage.instance.ref(widget.file);

    try {
      final Directory appDirectory = await getApplicationDocumentsDirectory();
      final String filePath = '${appDirectory.path}/${widget.file}';
      File file = File(filePath);

      await ref.writeToFile(file);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File downloaded successfully'),
        ),
      );
    } catch (e) {
      print('Error downloading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SfPdfViewer.network(widget.file,
            controller: _pdfViewerController, key: _pdfViewerStateKey),
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              onPressed: () {
                _pdfViewerStateKey.currentState!.openBookmarkView();
              },
              icon: Icon(
                Icons.bookmark,
                color: Colors.blue,
              ),
            ),
            IconButton(
              onPressed: () {
                _pdfViewerController.jumpToPage(5);
              },
              icon: Icon(
                Icons.arrow_drop_down_circle,
                color: Colors.blue,
              ),
            ),
            IconButton(
              onPressed: () {
                _pdfViewerController.zoomLevel = 1.25;
              },
              icon: Icon(
                Icons.zoom_in,
                color: Colors.blue,
              ),
            ),
            IconButton(
              onPressed: _downloadFile,
              icon: Icon(
                Icons.download,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
