import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ro_photo_viewer/core/database/app_database.dart';
import 'package:ro_photo_viewer/presentation/screens/photo_viewer_screen.dart';

class PhotoGrid extends StatelessWidget {
  final List<Photo> photos;

  const PhotoGrid({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: MasonryGridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PhotoViewerScreen(
                    photos: photos,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Hero(
              tag: photo.id,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: (photo.localThumbnailPath != null && File(photo.localThumbnailPath!).existsSync())
                    ? Image.file(
                        File(photo.localThumbnailPath!),
                        fit: BoxFit.cover,
                      )
                    : AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.photo, color: Colors.white),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
