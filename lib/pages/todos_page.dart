import 'package:flutter/material.dart';

class TodosPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TodosPage();
}

class _TodosPage extends State<TodosPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Text('TODOS'),
    ));
  }
}
