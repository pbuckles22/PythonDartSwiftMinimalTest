import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:python_flutter_embed_demo/main.dart';
import 'package:python_flutter_embed_demo/presentation/providers/game_provider.dart';
import 'package:python_flutter_embed_demo/presentation/providers/settings_provider.dart';
import 'package:python_flutter_embed_demo/presentation/pages/game_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Minesweeper Test App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: GamePage(),
      ),
    );
  }
} 