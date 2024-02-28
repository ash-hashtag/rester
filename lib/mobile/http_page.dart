import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:rester/mobile/response_widget.dart';

const methods = ["GET", "PUT", "POST", "DELETE", "OPTIONS"];

class HttpPage extends StatefulWidget {
  const HttpPage({super.key});

  @override
  State<StatefulWidget> createState() => _HttpPageState();
}

class _HttpPageState extends State<HttpPage> {
  final _urlTc = TextEditingController();
  final _client = http.Client();

  Widget? _responseWidget = null;

  @override
  void dispose() {
    super.dispose();
    _urlTc.dispose();
    _client.close();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildMethodsMenu(),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _urlTc,
                  onSubmitted: (_) => _makeRequest(),
                ),
              )),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _makeRequest,
              ),
            ],
          ),
          if (_responseWidget != null) Expanded(child: _responseWidget!),
        ],
      ),
    );
  }

  DropdownMenu<String> _buildMethodsMenu() {
    final dropdownMenuEntries = methods
        .map((e) => DropdownMenuEntry(
              value: e,
              label: e,
            ))
        .toList();
    return DropdownMenu<String>(
      dropdownMenuEntries: dropdownMenuEntries,
      initialSelection: _selectedMethod,
      onSelected: (value) =>
          setState(() => _selectedMethod = value ?? _selectedMethod),
    );
  }

  var _selectedMethod = methods.first;

  Future<void> _makeRequest() async {
    var url = Uri.parse(_urlTc.text);
    debugPrint("Making Request $_selectedMethod: $url");

    final request = http.Request(_selectedMethod, url);
    final response = await _client.send(request);

    setState(() =>
        _responseWidget = ResponseWidget(response: response, key: UniqueKey()));
  }
}
