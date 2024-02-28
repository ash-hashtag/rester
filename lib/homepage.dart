import 'package:flutter/material.dart';
import 'package:rester/widgets/saved_requests.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rester")),
      body: const Row(
        children: [
          RequestsExplorer(),
          // RequestingPanel(),
          Expanded(child: ProtocalPicker())
        ],
      ),
    );
  }
}
