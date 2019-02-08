import 'package:flutter/material.dart';
import 'authentication.dart';
import 'root_page.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Grocery List',
        debugShowCheckedModeBanner: false,
        theme: new ThemeData(
          primarySwatch: Colors.indigo,
        ),
        home: new RootPage(auth: new Auth()));
  }
}