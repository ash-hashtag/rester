import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResponseWidget extends StatefulWidget {
  final http.StreamedResponse response;

  const ResponseWidget({super.key, required this.response});
  @override
  State<StatefulWidget> createState() => _ResponseWidgetState();
}

class _ResponseWidgetState extends State<ResponseWidget> {
  late final response = widget.response;

  Widget _outputWidget = const SizedBox();

  @override
  void initState() {
    super.initState();

    _listenToStream();
  }

  void _listenToStream() async {
    try {
      await for (var bytes in response.stream) {
        _onBytes(bytes);
      }
    } catch (err) {
      _onError(err);
    }
    _onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _statusWidget(),
        Expanded(
          child: ListView(
            children: [
              HeadersWidget(
                headers: response.headers,
              ),
              _outputWidget,
            ],
          ),
        ),
      ],
    );
  }

  final _receivedBytes = <int>[];
  late final _contentLength = _getContentLength();

  int? _getContentLength() {
    final contentLengthHeaderValue = response.headers["content-length"];
    if (contentLengthHeaderValue != null) {
      return int.tryParse(contentLengthHeaderValue);
    }

    return null;
  }

  void _onBytes(List<int> bytes) {
    setState(() {
      _receivedBytes.addAll(bytes);
    });
  }

  Widget _statusWidget() {
    late final String s;
    if (_contentLength != null) {
      s = "Status: ${response.statusCode} | Content Received: ${_parseByteCount(_receivedBytes.length)} Out of ${_parseByteCount(_contentLength!)}";
    } else {
      s = "Status: ${response.statusCode} | Content Received: ${_parseByteCount(_receivedBytes.length)}";
    }
    return Row(
      children: [
        Text(s),
      ],
    );
  }

  void _onError(err) {
    setState(() {
      _outputWidget =
          Text(err.toString(), style: const TextStyle(color: Colors.red));
    });
  }

  void _onDone() {
    try {
      final totalBytes = _receivedBytes;
      final body = utf8.decode(totalBytes);
      setState(() => _outputWidget = Text(body));
    } catch (err, st) {
      debugPrint("Error $err $st");
    }
  }
}

String _parseByteCount(int bytes) {
  return bytes.toString();
}

class HeadersWidget extends StatelessWidget {
  final Map<String, String> headers;

  const HeadersWidget({super.key, required this.headers});

  TableRow _widgetBuilder(String headerName, String headerValue) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(headerName),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(headerValue),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final children =
        headers.entries.map((e) => _widgetBuilder(e.key, e.value)).toList();
    return Table(
      children: children,
      border: TableBorder.all(),
    );
  }
}
