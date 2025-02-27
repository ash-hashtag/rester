import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

// ignore: constant_identifier_names
const MAX_ALLOWED_TEXT_FILE_LENGTH = 1024 * 1024; // 1 MB

class RequestBodyWidget extends StatefulWidget {
  const RequestBodyWidget({super.key});

  @override
  State<StatefulWidget> createState() => RequestBodyWidgetState();
}

enum BodyType {
  empty,
  file,
  text,
  json,
  form,
}

class RequestBodyWidgetState extends State<RequestBodyWidget> {
  var bodyType = BodyType.empty;

  final _tc = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _tc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [_bodyTypePicker(), _getBody()]);
  }

  Widget _bodyTypePicker() {
    return DropdownButton<BodyType>(
      value: BodyType.empty,
      items: const [
        DropdownMenuItem(
          value: BodyType.empty,
          child: Text("Empty"),
        ),
        DropdownMenuItem(
          value: BodyType.file,
          child: Text("File"),
        ),
        DropdownMenuItem(
          value: BodyType.form,
          child: Text("Form"),
        ),
        DropdownMenuItem(
          value: BodyType.text,
          child: Text("Text"),
        ),
      ],
      onChanged: (value) {
        setState(() {
          bodyType = value ?? bodyType;
        });
      },
    );
  }

  Widget _getBody() {
    switch (bodyType) {
      case BodyType.empty:
        return const SizedBox();
      case BodyType.file:
        return Column(
          children: [
            TextButton(
              onPressed: _pickFile,
              child: const Row(
                children: [Icon(Icons.attach_file), Text("Pick a File")],
              ),
            ),
            FutureBuilder(
              future: _pickedFileWidget(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return snapshot.data!;
                }

                return const CircularProgressIndicator.adaptive();
              },
            ),
          ],
        );

      case BodyType.json:
      case BodyType.text:
        return TextField(
          controller: _tc,
          maxLines: 20,
        );

      case BodyType.form:
        return const Text("Form not supported yet");
    }
  }

  PickedFile? _pickedFile;

  Future<Widget> _pickedFileWidget() async {
    if (_pickedFile == null) {
      return const SizedBox();
    }

    final mimeType = _pickedFile!.contentType;
    final path = _pickedFile!.file.path;
    final file = _pickedFile!.file;

    if (mimeType.startsWith("image")) {
      return Column(
        children: [
          Text("File picked at $path"),
          Image.file(file),
        ],
      );
    }

    if (mimeType.startsWith("text")) {
      return Column(
        children: [
          Text("File picked at $path"),
          Text(await file.readAsString()),
        ],
      );
    }

    final length = await file.length();
    if (length < MAX_ALLOWED_TEXT_FILE_LENGTH) {
      try {
        final value = await file.readAsString();
        return Column(
          children: [
            Text("File picked at $path"),
            Text(value),
          ],
        );
      } catch (err) {
        debugPrint(err.toString());
      }
    }

    return Text("File picked at $path");
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) {
      return;
    }
    if (result.files.length == 1) {
      final file = result.files[0];
      if (file.path != null) {
        final f = File(file.path!);
        final mimeType =
            lookupMimeType(f.path, headerBytes: await getMagicBytesFromFile(f));
        final length = await f.length();
        setState(() {
          _pickedFile =
              PickedFile(f, mimeType ?? "application/octet-stream", length);
        });
      }
    }
  }
}

Future<List<int>> getMagicBytesFromFile(File file) async {
  final content = <int>[];
  await for (final chunk in file.openRead(0, 50)) {
    content.addAll(chunk);
    for (final c in content) {
      if (c == 0) {
        break;
      }
    }
  }
  return content;
}

class PickedFile {
  File file;
  String contentType;
  int length;

  PickedFile(this.file, this.contentType, this.length);
}
