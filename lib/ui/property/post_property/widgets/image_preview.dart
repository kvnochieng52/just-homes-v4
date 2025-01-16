import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final List<File> images;
  final Function(int) onRemoveImage;

  const ImagePreview({
    super.key,
    required this.images,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return images.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: SizedBox(
              height: 100.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(images[index]),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            width: 20, // Reduced width
                            height: 20, // Reduced height
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12, // Reduced icon size
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
