import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/teaching_material.dart';
import '../../models/teacher_profile.dart';
import '../../services/material_service.dart';

class MaterialDetailScreen extends StatelessWidget {
  final TeachingMaterial material;

  const MaterialDetailScreen({Key? key, required this.material})
      : super(key: key);

  Future<void> _downloadMaterial(BuildContext context) async {
    if (material.fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No file available'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // Increment download count
      final MaterialService materialService = MaterialService();
      await materialService.incrementDownloadCount(material.id);

      // Open URL
      final Uri url = Uri.parse(material.fileUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not open file'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getCategoryLabel(MaterialCategory cat) {
    switch (cat) {
      case MaterialCategory.lessonPlan:
        return 'Lesson Plan';
      case MaterialCategory.flashcard:
        return 'Flashcards';
      case MaterialCategory.icebreaker:
        return 'Icebreaker';
      case MaterialCategory.worksheet:
        return 'Worksheet';
      case MaterialCategory.digitalTool:
        return 'Digital Tool';
      case MaterialCategory.other:
        return 'Other';
    }
  }

  Color _getCategoryColor(MaterialCategory cat) {
    switch (cat) {
      case MaterialCategory.lessonPlan:
        return Colors.blue;
      case MaterialCategory.flashcard:
        return Colors.green;
      case MaterialCategory.icebreaker:
        return Colors.orange;
      case MaterialCategory.worksheet:
        return Colors.purple;
      case MaterialCategory.digitalTool:
        return Colors.teal;
      case MaterialCategory.other:
        return Colors.grey;
    }
  }

  bool _isImageFile() {
    if (material.fileUrl == null) return false;
    String url = material.fileUrl!.toLowerCase();

    // Debug
    print('Checking if image: $url');
    bool isImage = url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('.gif') ||
        url.contains('.webp');
    print('Is image: $isImage');

    return isImage;
  }

  @override
  Widget build(BuildContext context) {
    print('Material fileUrl: ${material.fileUrl}');
    print('Is image file: ${_isImageFile()}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con preview de imagen si es imagen
            if (_isImageFile() && material.fileUrl != null)
              // Preview de imagen
              Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: Stack(
                  children: [
                    Image.network(
                      material.fileUrl!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: 300,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Loading image...',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Image load error: $error');
                        print('Stack trace: $stackTrace');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Could not load image',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  error.toString(),
                                  style: TextStyle(
                                      color: Colors.red.shade400, fontSize: 10),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Overlay para mostrar que es una imagen
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Image Preview',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Header con gradiente (para PDFs y otros archivos)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCategoryColor(material.category),
                      _getCategoryColor(material.category).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getCategoryLabel(material.category),
                        style: TextStyle(
                          color: _getCategoryColor(material.category),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      material.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          material.uploaderName,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mostrar título también cuando hay imagen preview
                  if (_isImageFile()) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(material.category)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getCategoryLabel(material.category),
                        style: TextStyle(
                          color: _getCategoryColor(material.category),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      material.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          material.uploaderName,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    material.description,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 20),

                  if (material.suitableFor.isNotEmpty) ...[
                    const Text(
                      'Suitable for',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: material.suitableFor.map((level) {
                        return Chip(
                          label: Text(level.toString().split('.').last),
                          backgroundColor: Colors.blue.shade50,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (material.tags.isNotEmpty) ...[
                    const Text(
                      'Tags',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: material.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Row(
                    children: [
                      Icon(Icons.download,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${material.downloadCount} downloads',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(material.uploadedAt),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _downloadMaterial(context),
            icon: const Icon(Icons.download),
            label: const Text('Download Material'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
