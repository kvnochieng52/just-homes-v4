import 'package:flutter/material.dart';

//import 'package:searchable_dropdown/searchable_dropdown.dart';

class EditPage extends StatefulWidget {
  var propertyID;
  EditPage({super.key, required this.propertyID});

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const Text("Edit Page");
  }
}
