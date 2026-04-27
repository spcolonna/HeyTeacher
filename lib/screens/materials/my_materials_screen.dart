import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/teaching_material.dart';
import '../../models/teacher_profile.dart';
import '../../services/material_service.dart';
import '../materials/upload_material_screen.dart';
import '../materials/material_detail_screen.dart';

class MyMaterialsScreen extends StatelessWidget {
  const MyMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final MaterialService materialService = MaterialService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Materials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UploadMaterialScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TeachingMaterial>>(
        stream: materialService.getMaterialsByUser(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final materials = snapshot.data ?? [];

          if (materials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No materials uploaded yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UploadMaterialScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Your First Material'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              return _MyMaterialCard(
                material: material,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MaterialDetailScreen(material: material),
                    ),
                  );
                },
                onDelete: () async {
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Material'),
                      content: Text(
                          'Are you sure you want to delete "${material.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await materialService.deleteMaterial(material.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Material deleted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MyMaterialCard extends StatelessWidget {
  final TeachingMaterial material;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MyMaterialCard({
    required this.material,
    required this.onTap,
    required this.onDelete,
  });

  String _getCategoryLabel(MaterialCategory cat) {
    switch (cat) {
      case MaterialCategory.lessonPlan:
        return 'Lesson Plan';
      case MaterialCategory.flashcard:
        return 'Flashcard';
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(material.category)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getCategoryLabel(material.category),
                            style: TextStyle(
                              color: _getCategoryColor(material.category),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                material.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.download, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '${material.downloadCount} downloads',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(material.uploadedAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
