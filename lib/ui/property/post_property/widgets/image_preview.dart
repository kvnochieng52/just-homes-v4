import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../reelsplayer/reels_page.dart';

class ImagePreview extends StatefulWidget {
  final List<File> images;
  final Function(int) onRemoveImage;
  final VoidCallback onAddImage;
  final Future<void> Function(File image) onUploadImage;

  const ImagePreview({
    super.key,
    required this.images,
    required this.onRemoveImage,
    required this.onAddImage,
    required this.onUploadImage,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  bool _isExpanded = false; // Controls the collapsible state

  void _toggleExpandCollapse() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<String> _uploadImage(File image) async {
    final url = Uri.parse('https://justhomes.co.ke/api/property/upload-property-image');
    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    logger.i('RESPNSE IOMG + ${json.decode(responseData)} + ${response.statusCode}');
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(responseData);
      return data['image_path']; // Adjust based on actual API response format
    } else {
      throw Exception('Failed to upload image');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int visibleImagesCount = _isExpanded
        ? widget.images.length
        : (widget.images.length > 6 ? 6 : widget.images.length);

    // Combine "Add Image" button and images into a single list
    final List<Widget> items = [
      // Add Image Button
      GestureDetector(
        onTap: widget.onAddImage,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.purple),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 40, color: Colors.purple),
          ),
        ),
      ),
      // Image items (if available)
      if (widget.images.isNotEmpty)
        ...List.generate(visibleImagesCount, (index) {
          return Stack(
            children: [
              FutureBuilder<String>(
                future: _uploadImage(widget.images[index]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.black.withOpacity(0.1),
                      child: const Center(
                        child: SizedBox(child: CircularProgressIndicator(color: Colors.purple),height: 10, width: 10),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      color: Colors.red.withOpacity(0.5),
                      child: Center(
                        child: Text(
                          'Error',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        image: DecorationImage(
                          image: FileImage(widget.images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                },
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => widget.onRemoveImage(index),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Please upload at least 1 photo. You can add up to 20 photos.",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // Number of items per row
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 1, // Maintain square items
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        ),
        if (widget.images.length > 6)
          TextButton(
            onPressed: _toggleExpandCollapse,
            child: Text(_isExpanded ? "Show less" : "Show more (${widget.images.length - 6})"),
          ),
        const SizedBox(height: 8),
        const Text(
          "Supported formats are .jpg and .png. Pictures may not exceed 5MB.",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
