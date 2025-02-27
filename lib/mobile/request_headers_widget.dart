import 'package:flutter/material.dart';

class RequestHeadersWidget extends StatefulWidget {
  final Map<String, String> headers;
  const RequestHeadersWidget({super.key, this.headers = const {}});

  @override
  State<StatefulWidget> createState() => RequestHeadersWidgetState();
}

class RequestHeadersWidgetState extends State<RequestHeadersWidget>
    with AutomaticKeepAliveClientMixin {
  late final entries =
      widget.headers.entries.map((e) => HeaderEntry(e.key, e.value)).toList();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lastEntry = entries.lastOrNull;
    if (lastEntry?.headerName != "") {
      entries.add(HeaderEntry("", ""));
    }
    final children = entries.map((entry) {
      final e = entry;
      return TableRow(key: ValueKey(e), children: [
        Container(
          color: Colors.red,
          child: Center(
            child: Checkbox.adaptive(
                value: entry.enabled,
                onChanged: (value) =>
                    setState(() => entry.enabled = value ?? entry.enabled)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: EditableTextField(
            hintText: "Header Name",
            initialValue: entry.headerName,
            onChange: (val) => setState(() => entry.headerName = val),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: EditableTextField(
            hintText: "Header Value",
            initialValue: entry.headerValue,
            onChange: (val) => setState(() => entry.headerValue = val),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            entries.remove(e);
            setState(() {
              debugPrint("removed header $e");
            });
          },
        ),
      ]);
    }).toList();
    return Table(
      children: children,
      border: TableBorder.all(),
      columnWidths: const {
        0: FixedColumnWidth(50),
        3: FixedColumnWidth(50),
      },
    );
  }

  Map<String, String> get headerMap {
    final map = <String, String>{};
    for (var entry in entries) {
      if (entry.enabled) {
        map[entry.headerName] = entry.headerValue;
      }
    }
    return map;
  }

  @override
  bool get wantKeepAlive => true;
}

class HeaderEntry {
  String headerName;
  String headerValue;
  bool enabled;

  HeaderEntry(this.headerName, this.headerValue, [this.enabled = true]);

  @override
  String toString() {
    return [headerName, headerValue, enabled].toString();
  }
}

class EditableTextField extends StatefulWidget {
  final String initialValue;
  final String hintText;
  final Function(String)? onChange;

  const EditableTextField(
      {super.key, this.initialValue = "", this.onChange, this.hintText = ""});

  @override
  State<StatefulWidget> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  late final _tc = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    super.dispose();
    _tc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _tc,
      onChanged: widget.onChange,
      decoration: InputDecoration(hintText: widget.hintText),
    );
  }
}
