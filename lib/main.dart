import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'router/app_router.dart';

void main() {
  // Enable URL strategy
  usePathUrlStrategy();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Poputka',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
