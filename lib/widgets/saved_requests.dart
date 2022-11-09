import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mime/mime.dart';

class RequestsExplorer extends StatefulWidget {
  const RequestsExplorer({super.key});

  @override
  State<RequestsExplorer> createState() => _RequestsExplorerState();
}

class _RequestsExplorerState extends State<RequestsExplorer> {
  @override
  Widget build(BuildContext context) {
    return const ResizableWindow();
  }
}

class ResizableWindow extends StatefulWidget {
  final double width;
  const ResizableWindow({super.key, this.width = 300});

  @override
  State<ResizableWindow> createState() => _ResizableWindowState();
}

class _ResizableWindowState extends State<ResizableWindow> {
  late var _width = widget.width;

  var _grabbedGood = false;

  void dragStart(DragStartDetails details) {
    const draggableGap = 10;
    final diff = _width - details.localPosition.dx;
    if (diff < draggableGap && diff > 0) {
      _grabbedGood = true;
    }
  }

  void dragEnd(DragEndDetails details) {
    _grabbedGood = false;
  }

  void dragUpdate(DragUpdateDetails details) {
    if (_grabbedGood) {
      var newWidth = _width + details.delta.dx;
      if (newWidth > 100 &&
          newWidth < MediaQuery.of(context).size.width * 0.9) {
        setState(() {
          _width = newWidth;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: dragStart,
      onHorizontalDragEnd: dragEnd,
      onHorizontalDragUpdate: dragUpdate,
      onHorizontalDragCancel: () => _grabbedGood = false,
      child: Container(
        height: double.infinity,
        width: _width,
        color: Colors.green,
        child: Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Container(
            height: double.infinity,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}

class RequestWidget extends StatelessWidget {
  const RequestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class RequestingPanel extends StatefulWidget {
  const RequestingPanel({super.key});

  @override
  State<RequestingPanel> createState() => _RequestingPanelState();
}

class _RequestingPanelState extends State<RequestingPanel> {
  @override
  void initState() {
    Changes.onChange(onChange);
    super.initState();
  }

  @override
  void dispose() {
    Changes.removeCallback(onChange);
    super.dispose();
  }

  void onChange() {
    setState(() {
      method = Changes.method;
    });
  }

  var method = Changes.method;

  BodyType? bodyType;

  Widget? requestBody;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.yellow,
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              MethodDropDown(),
              Expanded(
                child: TextField(
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(0),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (method == RequestMethod.post || method == RequestMethod.put)
          Row(
            children: [
              TextButton(onPressed: pickFile, child: const Text("File")),
              TextButton(
                  onPressed: pickFiles, child: const Text("Files/Multipart")),
              TextButton(onPressed: pickJson, child: const Text("JSON")),
            ],
          ),
        if (bodyType != null)
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            color: Colors.cyan,
            child: bodyType == BodyType.multipart
                ? ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) => FileWidget(
                      file: files[index],
                      onDelete: () =>
                          setState(() => files.remove(files[index])),
                    ),
                  )
                : requestBody,
          ),
      ],
    );
  }

  void pickJson() {
    setState(() {
      bodyType = BodyType.json;
      requestBody = const TextField(
        maxLines: 10,
      );
    });
  }

  void pickFile() {
    FilePicker.platform.pickFiles(allowMultiple: false).then((value) {
      if (value?.paths.first != null) {
        final mimeType =
            lookupMimeType(value!.paths.first!) ?? "application/octet-stream";
        bodyType = BodyType.file;

        setState(() {
          requestBody = FileWidget(file: value.files.first);
        });
      }
    });
  }

  final files = <PlatformFile>[];

  void pickFiles() {
    FilePicker.platform.pickFiles(allowMultiple: true).then((value) {
      if (value?.paths.isNotEmpty ?? false) {
        setState(() {
          files.clear();
          files.addAll(value!.files);
          bodyType = BodyType.multipart;
        });
      }
    });
  }
}

String formattedString(int n, String unit, [int fractionalDigits = 2]) {
  if (n < 1000) {
    return "$n$unit";
  }
  const map = {
    1000000000000: 'T',
    1000000000: 'G',
    1000000: 'M',
    1000: 'K',
  };
  final entry = map.entries.firstWhere((e) => e.key < n);
  final _ = n / entry.key;
  return _.toStringAsFixed(fractionalDigits) + entry.value + unit;
}

enum BodyType { file, multipart, json }

enum RequestMethod {
  get,
  options,
  post,
  put,
  delete,
}

enum ProtocalType { rest, websocket, grpc }

class MethodDropDown extends StatefulWidget {
  final RequestMethod value;
  const MethodDropDown({super.key, this.value = RequestMethod.get});

  @override
  State<MethodDropDown> createState() => _MethodDropDownState();
}

class _MethodDropDownState extends State<MethodDropDown> {
  late var value = widget.value;

  @override
  void initState() {
    Changes.method = value;
    super.initState();
  }

  static const items = <DropdownMenuItem<RequestMethod>>[
    DropdownMenuItem(
      value: RequestMethod.get,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("GET"),
      ),
    ),
    DropdownMenuItem(
      value: RequestMethod.options,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("OPTIONS"),
      ),
    ),
    DropdownMenuItem(
      value: RequestMethod.post,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("POST"),
      ),
    ),
    DropdownMenuItem(
      value: RequestMethod.put,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("PUT"),
      ),
    ),
    DropdownMenuItem(
      value: RequestMethod.delete,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("DELETE"),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<RequestMethod>(
      value: value,
      items: items,
      onChanged: (_) => _ != null
          ? setState(() {
              value = _;
              Changes.method = _;
              Changes.notifiyListeners();
            })
          : null,
    );
  }
}

class Changes {
  static var method = RequestMethod.get;
  static var type = ProtocalType.rest;
  static var url = "";

  static final callbacks = <VoidCallback>[];
  static void onChange(VoidCallback callback) {
    callbacks.add(callback);
  }

  static void removeCallback(VoidCallback callback) {
    callbacks.remove(callback);
  }

  static void notifiyListeners() {
    for (var e in callbacks) {
      e();
    }
  }
}

class ProtocalPicker extends StatefulWidget {
  const ProtocalPicker({super.key});

  @override
  State<ProtocalPicker> createState() => _ProtocalPickerState();
}

class _ProtocalPickerState extends State<ProtocalPicker> {
  var selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Protocal"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "REST"),
              Tab(text: "WebSocket"),
              Tab(text: "gRPC"),
            ],
          ),
        ),
        body: TabBarView(children: [
          const RequestingPanel(),
          Container(),
          Container(),
        ]),
      ),
    );
  }
}

class FileWidget extends StatelessWidget {
  final PlatformFile file;
  final VoidCallback? onDelete;
  const FileWidget({super.key, required this.file, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(file.name),
      subtitle: Text(formattedString(file.size, 'B')),
      leading: getLeading(),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }

  Widget? getLeading() {
    final mimeType = lookupMimeType(file.path!);
    if (mimeType != null && mimeType.startsWith("image")) {
      if (mimeType.contains("svg+xml")) {
        return SvgPicture.file(
          File(file.path!),
          width: 100,
          height: 100,
        );
      }
      return Image.file(
        File(file.path!),
        width: 100,
        height: 100,
      );
    }
    return null;
  }
}
