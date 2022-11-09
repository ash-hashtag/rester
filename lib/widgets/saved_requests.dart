import 'dart:io';

import 'package:dio/dio.dart';
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
  final jsonTc = TextEditingController();
  final urlTc = TextEditingController();

  final uploadProgressKey = GlobalKey<_ProgressIndicatorState>();
  final downloadProgressKey = GlobalKey<_ProgressIndicatorState>();

  final Map<String, String> headers = {};
  @override
  void initState() {
    Changes.onChange(onChange);
    super.initState();
  }

  @override
  void dispose() {
    Changes.removeCallback(onChange);
    jsonTc.dispose();
    urlTc.dispose();
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
            children: [
              const MethodDropDown(),
              const Expanded(
                child: TextField(
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(0),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: sendRequest)
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
                      icon: const Icon(Icons.delete),
                      onIconPressed: () =>
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

  void sendRequest() async {
    final url = urlTc.text;

    final dio = Dio();
    if (method == RequestMethod.post || method == RequestMethod.put) {
      if (bodyType == BodyType.json) {
        if (method == RequestMethod.post) {
          final Response<Stream<int>> response = await dio.post(
            url,
            data: jsonTc.text,
            options: Options(
              responseType: ResponseType.stream,
            ),
            onSendProgress: uploadProgressKey.currentState!.progress,
            onReceiveProgress: downloadProgressKey.currentState!.progress,
          );

          final responseWidget = ResponsePanel(
              statusCode: response.statusCode!,
              headers: response.headers.map
                  .map((key, value) => MapEntry(key, value.join(','))),
              body: await () async {
                final contentLength = response.headers.value("content-length");
                if (contentLength != null &&
                    int.tryParse(contentLength) != null) {
                  final size = int.parse(contentLength);
                  if (size > 1000000) {
                    return const ProgressIndicator();
                  }
                }
                return SelectableText(
                    String.fromCharCodes(await response.data!.toList()));
              }());
        }
      }
    }
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
  final VoidCallback? onIconPressed;
  final Icon? icon;
  const FileWidget(
      {super.key, required this.file, this.onIconPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(file.name),
      subtitle: Text(formattedString(file.size, 'B')),
      leading: getLeading(),
      trailing: icon == null
          ? null
          : IconButton(
              icon: icon!,
              onPressed: onIconPressed,
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

class SwitchWidget extends StatefulWidget {
  final bool value;
  const SwitchWidget({super.key, this.value = false});

  @override
  State<SwitchWidget> createState() => _SwitchWidgetState();
}

class _SwitchWidgetState extends State<SwitchWidget> {
  late var value = widget.value;
  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
        value: value, onChanged: (_) => setState(() => value = _));
  }
}

class ResponsePanel extends StatelessWidget {
  final int statusCode;
  final Map<String, String> headers;
  final Widget body;
  const ResponsePanel(
      {super.key,
      required this.statusCode,
      required this.headers,
      required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectableText("Status: $statusCode"),
        Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: ListView(children: [
            for (var entry in headers.entries)
              SelectableText("${entry.key}: ${entry.value}"),
          ]),
        ),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
            maxWidth: MediaQuery.of(context).size.width * 0.5,
          ),
          child: body,
        )
      ],
    );
  }
}

class ProgressIndicator extends StatefulWidget {
  final bool showText;
  final VoidCallback? onDone;
  const ProgressIndicator({super.key, this.showText = false, this.onDone});

  @override
  State<ProgressIndicator> createState() => _ProgressIndicatorState();
}

class _ProgressIndicatorState extends State<ProgressIndicator> {
  void progress(int count, int total) {
    setState(() => value = count / total);
    if (value == 1.0 && widget.onDone != null) widget.onDone!();
  }

  var value = 0.0;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LinearProgressIndicator(
          value: value,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        if (widget.showText) Text("${value * 100}%")
      ],
    );
  }
}
