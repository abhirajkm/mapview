import 'package:flutter/material.dart';
import 'package:mapviewapp/map_screen.dart';
import 'package:mapviewapp/mapnavigation.dart';
import 'package:mapviewapp/providers/index.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: ProviderTree.get(context),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home:    MapViewScreen(),
      ),
    );
  }
}

