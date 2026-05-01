import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/institution_staff.dart';
import '../../models/teaching_material.dart';
import '../../models/app_user.dart';
import '../../services/material_service.dart';
import '../../services/staff_service.dart';
import '../../providers/auth_provider.dart';
import 'upload_material_screen.dart';
import 'material_detail_screen.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final MaterialService _materialService = MaterialService();
  MaterialCategory? _selectedCategory;
  List<String> _institutionIds = [];
  StreamSubscription<List<InstitutionStaff>>? _staffSub;

  @override
  void initState() {
    super.initState();
    final user =
        Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null && user.userType == UserType.teacher) {
      _staffSub = StaffService()
          .getInstitutionsForTeacher(user.uid)
          .listen(
        (list) {
          final ids = list
              .where((s) => s.status == StaffStatus.accepted)
              .map((s) => s.institutionId)
              .toList();
          if (mounted) setState(() => _institutionIds = ids);
        },
        onError: (e) => print('🔥 Staff sub error: $e'),
      );
    }
  }

  @override
  void dispose() {
    _staffSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final canUpload = user?.userType == UserType.teacher ||
        user?.userType == UserType.institution;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher's Toolbox"),
        actions: [
          if (canUpload)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final institutionId = user?.userType == UserType.institution
                    ? user?.uid
                    : null;
                final institutionName =
                    user?.userType == UserType.institution
                        ? user?.displayName
                        : null;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadMaterialScreen(
                      institutionId: institutionId,
                      institutionName: institutionName,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All', null),
                ...MaterialCategory.values.map((category) {
                  return _buildCategoryChip(
                    _getCategoryLabel(category),
                    category,
                  );
                }),
              ],
            ),
          ),

          // Materials grid
          Expanded(
            child: StreamBuilder<List<TeachingMaterial>>(
              stream: _materialService.getMaterialsForUser(_institutionIds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final all = snapshot.data ?? [];
                final materials = _selectedCategory == null
                    ? all
                    : all.where((m) => m.category == _selectedCategory).toList();

                if (materials.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No materials available',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey.shade600),
                        ),
                        if (canUpload) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UploadMaterialScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.upload),
                            label: const Text('Upload First Material'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return MaterialCard(
                      material: material,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MaterialDetailScreen(material: material),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, MaterialCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
      ),
    );
  }

  String _getCategoryLabel(MaterialCategory category) {
    switch (category) {
      case MaterialCategory.lessonPlan:
        return 'Lesson Plans';
      case MaterialCategory.flashcard:
        return 'Flashcards';
      case MaterialCategory.icebreaker:
        return 'Icebreakers';
      case MaterialCategory.worksheet:
        return 'Worksheets';
      case MaterialCategory.digitalTool:
        return 'Digital Tools';
      case MaterialCategory.other:
        return 'Other';
    }
  }
}

class MaterialCard extends StatelessWidget {
  final TeachingMaterial material;
  final VoidCallback onTap;

  const MaterialCard({super.key, required this.material, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail or placeholder
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getCategoryColors(material.category),
                ),
              ),
              child: Icon(
                _getCategoryIcon(material.category),
                size: 48,
                color: Colors.white,
              ),
            ),

            // Material info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${material.uploaderName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    if (material.institutionName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Chip(
                          label: Text(
                            material.institutionName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: Colors.teal.shade50,
                          side: BorderSide(color: Colors.teal.shade200),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.download,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${material.downloadCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getCategoryColors(MaterialCategory category) {
    switch (category) {
      case MaterialCategory.lessonPlan:
        return [Colors.blue.shade400, Colors.blue.shade600];
      case MaterialCategory.flashcard:
        return [Colors.green.shade400, Colors.green.shade600];
      case MaterialCategory.icebreaker:
        return [Colors.orange.shade400, Colors.orange.shade600];
      case MaterialCategory.worksheet:
        return [Colors.purple.shade400, Colors.purple.shade600];
      case MaterialCategory.digitalTool:
        return [Colors.teal.shade400, Colors.teal.shade600];
      case MaterialCategory.other:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  IconData _getCategoryIcon(MaterialCategory category) {
    switch (category) {
      case MaterialCategory.lessonPlan:
        return Icons.article;
      case MaterialCategory.flashcard:
        return Icons.style;
      case MaterialCategory.icebreaker:
        return Icons.celebration;
      case MaterialCategory.worksheet:
        return Icons.assignment;
      case MaterialCategory.digitalTool:
        return Icons.computer;
      case MaterialCategory.other:
        return Icons.folder;
    }
  }
}
