import 'package:flutter/material.dart';
// import 'package:rester/homepage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mobile/homepage.dart';
import 'package:rester/themes.dart';

void main() async {
  await Hive.initFlutter("hive");

  runApp(const MyApp());

  // doWhenWindowReady(() {
  //   final win = appWindow;
  //   const initialSize = Size(600, 450);
  //   win.minSize = initialSize;
  //   win.size = initialSize;
  //   win.alignment = Alignment.center;
  //   win.title = "Custom window with Flutter";
  //   win.show();
  // });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rester',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
      home: const HomePage(),
    );
  }
}
