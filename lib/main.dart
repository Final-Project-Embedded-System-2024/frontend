import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_water/screen/turbidity_monitoring_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Turbidity Monitoring System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TurbidityMonitorScreen(),
    );
  }
}
