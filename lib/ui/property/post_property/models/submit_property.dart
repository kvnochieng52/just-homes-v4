import 'package:just_apartment_live/ui/property/post_step2_page.dart';
import 'package:just_apartment_live/models/configuration.dart';

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class PropertySubmissionService {
  Future<void> submitProperty({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required List<File> images,
    required String userTown,
    required String userRegion,
    required TextEditingController titleController,
    required String propertyID,
  }) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    formKey.currentState!.save();

    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo first'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostStep2Page(
            propertyID: propertyID.toString(),
          ),
        ),
      );
      // Loading().loader(context, "Processing...Please wait");

      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = json.decode(localStorage.getString('user') ?? '{}');

      final uri = Uri.parse("${Configuration.API_URL}property/post");
      final request = http.MultipartRequest('POST', uri);

      for (var imagePath in images) {
        final file =
            await http.MultipartFile.fromPath('images[]', imagePath.path);
        request.files.add(file);
      }

      request.fields['town'] = userTown;
      request.fields['region'] = userRegion;
      request.fields['title'] = titleController.text;
      request.fields['user_id'] = user['id'].toString();
      request.fields['step'] = '4';
      request.fields['propertyID'] = propertyID;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Handle successful response
      } else {
        Navigator.pop(context);
        print('Failed to upload images');
      }
    }
  }
}
