import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:rester/mobile/request_body_widget.dart';
import 'package:rester/mobile/request_headers_widget.dart';
import 'package:rester/mobile/response_widget.dart';

const methods = ["GET", "HEAD", "PUT", "POST", "DELETE", "OPTIONS"];

class HttpPage extends StatefulWidget {
  const HttpPage({super.key});

  @override
  State<StatefulWidget> createState() => _HttpPageState();
}

class _HttpPageState extends State<HttpPage> {
  final _urlTc = TextEditingController();
  final _client = http.Client();
  final _requestHeadersKey = GlobalKey<RequestHeadersWidgetState>();
  final _requestBodyKey = GlobalKey<RequestBodyWidgetState>();
  var _requiresRequestBody = false;
  var _showResponseBody = false;
  Widget _responseWidget = const Text("Response Body");
  final _tabsLength = 3;
  // 2 + (_requiresRequestBody ? 1 : 0) + (_showResponseBody ? 1 : 0);

  @override
  void dispose() {
    super.dispose();
    _urlTc.dispose();
    _client.close();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabsLength,
      child: Column(children: [
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
        const TabBar(
          tabs: [
            Text("Request Headers"),
            Text("Request Body"),
            Text("Response"),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RequestHeadersWidget(key: _requestHeadersKey),
              ),
              // if (_selectedMethod == "PUT" || _selectedMethod == "POST")
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RequestBodyWidget(key: _requestBodyKey),
              ),
              // HeadersWidget(headers: _responseHeaders),

              _responseWidget,
            ],
          ),
        ),
      ]
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Column(
          //     children: [
          //       Row(
          //         children: [
          //           _buildMethodsMenu(),
          //           Expanded(
          //               child: Padding(
          //             padding: const EdgeInsets.all(8.0),
          //             child: TextField(
          //               controller: _urlTc,
          //               onSubmitted: (_) => _makeRequest(),
          //             ),
          //           )),
          //           IconButton(
          //             icon: const Icon(Icons.send),
          //             onPressed: _makeRequest,
          //           ),
          //         ],
          //       ),
          //       TabBarView(
          //         children: [
          //           HeadersWidget(headers: _requestHeaders),
          //           HeadersWidget(headers: _responseHeaders),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
          ),
    );
  }

  var _responseHeaders = <String, String>{};
  get _requestHeaders => _requestHeadersKey.currentState!.headerMap;

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
      onSelected: (value) => setState(() {
        _selectedMethod = value ?? _selectedMethod;
        switch (_selectedMethod) {
          case "PUT":
          case "POST":
          case "DELETE":
            _requiresRequestBody = true;
            break;
          default:
            _requiresRequestBody = false;
        }
        // _requestHeaders = http.Request(_selectedMethod,
        //         Uri.tryParse(_urlTc.text) ?? Uri.parse("https://example.com"))
        //     .headers;
      }),
    );
  }

  var _selectedMethod = methods.first;

  Future<void> _makeRequest() async {
    if (!_urlTc.text.startsWith("http")) {
      setState(() {
        _urlTc.text = "https://${_urlTc.text}";
      });
    }

    final url = Uri.parse(_urlTc.text);
    final request = http.Request(_selectedMethod, url);
    request.headers.addAll(_requestHeaders);
    final headers = Map.from(request.headers);

    debugPrint("Making Request $_selectedMethod: $url with Headers $headers");
    final response = await _client.send(request);

    setState(() {
      _responseHeaders = response.headers;
    });

    setState(() =>
        _responseWidget = ResponseWidget(response: response, key: UniqueKey()));
  }
}
