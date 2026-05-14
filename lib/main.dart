import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'provider/sheet_provider.dart';
import 'screens/chat_capture_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SheetProvider(),
      child: const CopiousReimburseApp(),
    ),
  );
}

class CopiousReimburseApp extends StatelessWidget {
  const CopiousReimburseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Copious ReimburseAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ChatCaptureScreen(),
    );
  }
}
