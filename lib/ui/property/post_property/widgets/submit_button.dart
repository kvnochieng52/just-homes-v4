import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_apartment_live/ui/property/post_property/models/submit_property.dart';

class NextButtonWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<File> images;
  final String userTown;
  final String userRegion;
  final TextEditingController titleController;
  final String propertyID;
  final PropertySubmissionService _propertySubmissionService;

  const NextButtonWidget({
    super.key,
    required this.formKey,
    required this.images,
    required this.userTown,
    required this.userRegion,
    required this.titleController,
    required this.propertyID,
    required PropertySubmissionService propertySubmissionService,
  }) : _propertySubmissionService = propertySubmissionService;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: SizedBox(
        width: double.infinity, // Full width of the parent
        child: ElevatedButton(
          onPressed: () => _propertySubmissionService.submitProperty(
            context: context,
            formKey: formKey,
            images: images,
            userTown: userTown,
            userRegion: userRegion,
            titleController: titleController,
            propertyID: propertyID,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple, // Purple background color
            foregroundColor: Colors.white, // White font color
            minimumSize:
                const Size(double.infinity, 50), // Set a minimum height
          ),
          child: const Text("Next"),
        ),
      ),
    );
  }
}
