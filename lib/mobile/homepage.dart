import 'package:flutter/material.dart';
import 'package:rester/mobile/http_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // var _currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   appBar: AppBar(
    //     title: const Text("Rester"),
    //   ),
    //   bottomNavigationBar: NavigationBar(
    //     selectedIndex: _currentPageIndex,
    //     destinations: const [
    //       NavigationDestination(
    //         label: "HTTP",
    //         icon: Icon(Icons.send_outlined),
    //         selectedIcon: Icon(Icons.send),
    //       ),
    //       NavigationDestination(
    //         label: "GRPC",
    //         icon: Icon(Icons.message_outlined),
    //         selectedIcon: Icon(Icons.message),
    //       ),
    //     ],
    //     onDestinationSelected: (index) =>
    //         setState(() => _currentPageIndex = index),
    //   ),
    //   body: _buildPages()[_currentPageIndex],
    // );
    return Scaffold(body: _buildPages()[0]);
  }

  List<Widget> _buildPages() {
    const pages = <Widget>[
      HttpPage(),
      Center(child: Text("GRPC")),
    ];

    return pages;
  }
}
