import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:mime_type/mime_type.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

class MessageTile extends StatefulWidget {
  final String message;
  final String sender;
  final bool sentByMe;
  final String? fileURL;

  const MessageTile({
    Key? key,
    required this.message,
    required this.sender,
    required this.sentByMe,
    this.fileURL,
  }) : super(key: key);

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: widget.sentByMe ? 0 : 24,
          right: widget.sentByMe ? 24 : 0),
      alignment: widget.sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: widget.sentByMe
            ? const EdgeInsets.only(left: 30)
            : const EdgeInsets.only(right: 30),
        padding:
            const EdgeInsets.only(top: 17, bottom: 17, left: 20, right: 20),
        decoration: BoxDecoration(
            borderRadius: widget.sentByMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
            color: widget.sentByMe
                ? Theme.of(context).primaryColor
                : Colors.grey[700]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sender.toUpperCase(),
              textAlign: TextAlign.start,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5),
            ),
            const SizedBox(
              height: 8,
            ),
            filePreviewerWidget(
              fileURL: widget.fileURL,
            ),
            Text(widget.message,
                textAlign: TextAlign.start,
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget filePreviewerWidget({String? fileURL}) {
    if (fileURL == null) {
      return Container();
    }

    final uri = Uri.parse(fileURL);
    final serverFilePath = uri.path;
    // Get the file extension
    String? mimeType = mime(serverFilePath.split('/').last);

    if (mimeType == null) {
      return Container();
    }

    // Display different widgets based on the file type
    if (mimeType.startsWith('image/')) {
      return Image.network(fileURL);
    } else if (mimeType.startsWith('video/')) {
      return FutureBuilder<VideoPlayerController>(
        future: Future.value(
            VideoPlayerController.networkUrl(Uri.parse(fileURL))..initialize()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: snapshot.data!.value.aspectRatio,
              child: VideoPlayer(snapshot.data!),
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      );
    } else if (mimeType == 'application/pdf') {
      return FutureBuilder(
        future: _downloadFile(fileURL),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Container(
              height: 300,
              child: LayoutBuilder(builder: (context, constraints) {
                return GestureDetector(
                  onTap: () async {
                    if (await canLaunchUrl(Uri.parse(snapshot.data!))) {
                      await launchUrl(Uri.parse(snapshot.data!));
                    } else {
                      throw 'Could not launch $snapshot.data';
                    }
                  },
                  child: PDFView(
                    filePath: snapshot.data,
                    autoSpacing: true,
                    pageSnap: true,
                    swipeHorizontal: true,
                  ),
                );
              }),
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      );
    } else {
      return Container();
    }
  }

  Future<String> _downloadFile(String url) async {
    var request = await http.Client().get(Uri.parse(url));
    var bytes = request.bodyBytes;

    String dir = (await getApplicationDocumentsDirectory()).path;
    String filename = path.basename(url);
    File file = File('$dir/$filename');

    await file.writeAsBytes(bytes);

    return file.path;
  }
}
