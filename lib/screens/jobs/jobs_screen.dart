import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_user.dart';
import '../../models/job_posting.dart';
import '../../models/teacher_profile.dart';
import '../../services/job_service.dart';
import 'job_detail_screen.dart';
import 'create_job_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final JobService _jobService = JobService();
  final _searchController = TextEditingController();

  String _searchText = '';
  String? _locationFilter;
  List<AvailabilityShift>? _shiftFilters;
  List<TeachingLevel>? _levelFilters;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => _FiltersDialog(
        initialLocation: _locationFilter,
        initialShifts: _shiftFilters ?? [],
        initialLevels: _levelFilters ?? [],
        onApply: (location, shifts, levels) {
          setState(() {
            _locationFilter = location;
            _shiftFilters = shifts.isEmpty ? null : shifts;
            _levelFilters = levels.isEmpty ? null : levels;
          });
        },
      ),
    );
  }

  List<JobPosting> _filterJobs(List<JobPosting> jobs) {
    if (_searchText.isEmpty) return jobs;

    String search = _searchText.toLowerCase();
    return jobs.where((job) {
      return job.jobTitle.toLowerCase().contains(search) ||
          job.institutionName.toLowerCase().contains(search) ||
          job.description.toLowerCase().contains(search) ||
          job.location.toLowerCase().contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Board'),
        actions: [
          if (user?.userType == UserType.institution)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateJobScreen()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search jobs...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchText = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() => _searchText = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFiltersDialog,
                    ),
                    if (_locationFilter != null ||
                        _shiftFilters != null ||
                        _levelFilters != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Jobs list
          Expanded(
            child: StreamBuilder<List<JobPosting>>(
              stream: user?.userType == UserType.institution
                  ? _jobService.getJobsByInstitution(user!.uid)
                  : _jobService.searchJobs(
                      location: _locationFilter,
                      shifts: _shiftFilters,
                      levels: _levelFilters,
                    ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                List<JobPosting> jobs = snapshot.data ?? [];
                jobs = _filterJobs(jobs);

                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_off,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchText.isNotEmpty || _locationFilter != null
                              ? 'No jobs found'
                              : user?.userType == UserType.institution
                                  ? 'No jobs posted yet'
                                  : 'No jobs available',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey.shade600),
                        ),
                        if (user?.userType == UserType.institution) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateJobScreen(),
                                ),
                              );
                            },
                            child: const Text('Post your first job'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return JobCard(
                      job: job,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailScreen(job: job),
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
}

class JobCard extends StatelessWidget {
  final JobPosting job;
  final VoidCallback onTap;

  const JobCard({super.key, required this.job, required this.onTap});

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
                    child: Text(
                      job.jobTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (job.status == JobStatus.active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job.institutionName,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Flexible(
                    // ← AGREGADO: Flexible para location
                    child: Text(
                      job.location,
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Flexible(
                    // ← AGREGADO: Flexible para shifts
                    child: Text(
                      job.shifts
                          .map((s) => s.toString().split('.').last)
                          .join(', '),
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: job.levels.map((level) {
                  return Chip(
                    label: Text(
                      level.toString().split('.').last,
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              if (job.applicationsCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${job.applicationsCount} application${job.applicationsCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltersDialog extends StatefulWidget {
  final String? initialLocation;
  final List<AvailabilityShift> initialShifts;
  final List<TeachingLevel> initialLevels;
  final Function(String?, List<AvailabilityShift>, List<TeachingLevel>) onApply;

  const _FiltersDialog({
    required this.initialLocation,
    required this.initialShifts,
    required this.initialLevels,
    required this.onApply,
  });

  @override
  State<_FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<_FiltersDialog> {
  late TextEditingController _locationController;
  late List<AvailabilityShift> _selectedShifts;
  late List<TeachingLevel> _selectedLevels;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initialLocation);
    _selectedShifts = List.from(widget.initialShifts);
    _selectedLevels = List.from(widget.initialLevels);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filters'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Montevideo',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Shifts:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...AvailabilityShift.values.map((shift) {
              return CheckboxListTile(
                title: Text(shift.toString().split('.').last),
                value: _selectedShifts.contains(shift),
                onChanged: (checked) {
                  setState(() {
                    if (checked!) {
                      _selectedShifts.add(shift);
                    } else {
                      _selectedShifts.remove(shift);
                    }
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 8),
            const Text('Levels:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...TeachingLevel.values.map((level) {
              return CheckboxListTile(
                title: Text(level.toString().split('.').last),
                value: _selectedLevels.contains(level),
                onChanged: (checked) {
                  setState(() {
                    if (checked!) {
                      _selectedLevels.add(level);
                    } else {
                      _selectedLevels.remove(level);
                    }
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _locationController.clear();
              _selectedShifts.clear();
              _selectedLevels.clear();
            });
          },
          child: const Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(
              _locationController.text.trim().isEmpty
                  ? null
                  : _locationController.text.trim(),
              _selectedShifts,
              _selectedLevels,
            );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
