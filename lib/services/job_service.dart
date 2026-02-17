import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/job_posting.dart';
import '../models/job_application.dart';
import '../models/teacher_profile.dart';
import 'firestore_wrapper.dart';

class JobService {
  final _uuid = const Uuid();

  // Create a new job posting
  Future<String> createJobPosting(JobPosting job) async {
    try {
      DocumentReference docRef =
          await FirestoreWrapper.addDocument('jobs', job.toMap());
      return docRef.id;
    } catch (e, stackTrace) {
      print('Error creating job posting: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get all active job postings
  Stream<List<JobPosting>> getActiveJobs() {
    Query query = FirestoreWrapper.query('jobs')
        .where('status', isEqualTo: 'active')
        .orderBy('postedAt', descending: true);

    return FirestoreWrapper.getCollectionStream(query, 'Active jobs').map(
        (snapshot) =>
            snapshot.docs.map((doc) => JobPosting.fromFirestore(doc)).toList());
  }

  // Get jobs posted by a specific institution
  Stream<List<JobPosting>> getJobsByInstitution(String uid) {
    Query query = FirestoreWrapper.query('jobs')
        .where('postedBy', isEqualTo: uid)
        .orderBy('postedAt', descending: true);

    return FirestoreWrapper.getCollectionStream(
            query, 'Jobs by institution $uid')
        .map((snapshot) =>
            snapshot.docs.map((doc) => JobPosting.fromFirestore(doc)).toList());
  }

  // Search jobs with filters
  Stream<List<JobPosting>> searchJobs({
    String? location,
    List<AvailabilityShift>? shifts,
    List<TeachingLevel>? levels,
  }) {
    Query query =
        FirestoreWrapper.query('jobs').where('status', isEqualTo: 'active');

    if (location != null && location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }

    return query
        .orderBy('postedAt', descending: true)
        .snapshots()
        .handleError((error, stackTrace) {
      print('Error searching jobs: $error');
      print('Stack trace: $stackTrace');
    }).map((snapshot) {
      List<JobPosting> jobs =
          snapshot.docs.map((doc) => JobPosting.fromFirestore(doc)).toList();

      // Filter by shifts and levels in-memory
      if (shifts != null && shifts.isNotEmpty) {
        jobs = jobs
            .where((job) => job.shifts.any((shift) => shifts.contains(shift)))
            .toList();
      }

      if (levels != null && levels.isNotEmpty) {
        jobs = jobs
            .where((job) => job.levels.any((level) => levels.contains(level)))
            .toList();
      }

      return jobs;
    });
  }

  // Apply to a job
  Future<void> applyToJob({
    required String jobId,
    required String teacherId,
    required String teacherName,
    String? teacherEmail,
    String? cvUrl,
    String? coverLetter,
  }) async {
    try {
      // Check if already applied
      QuerySnapshot existing = await FirestoreWrapper.query('applications')
          .where('jobId', isEqualTo: jobId)
          .where('teacherId', isEqualTo: teacherId)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Already applied to this job');
      }

      // Create application
      JobApplication application = JobApplication(
        id: _uuid.v4(),
        jobId: jobId,
        teacherId: teacherId,
        teacherName: teacherName,
        teacherEmail: teacherEmail,
        cvUrl: cvUrl,
        coverLetter: coverLetter,
        appliedAt: DateTime.now(),
      );

      // Add application to Firestore
      await FirestoreWrapper.addDocument('applications', application.toMap());

      // Increment application count on job
      await FirestoreWrapper.updateDocument('jobs', jobId, {
        'applicationsCount': FieldValue.increment(1),
      });
    } catch (e, stackTrace) {
      print('Error applying to job: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get applications for a specific job
  Stream<List<JobApplication>> getApplicationsForJob(String jobId) {
    Query query = FirestoreWrapper.query('applications')
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedAt', descending: true);

    return FirestoreWrapper.getCollectionStream(
            query, 'Applications for job $jobId')
        .map((snapshot) => snapshot.docs
            .map((doc) => JobApplication.fromFirestore(doc))
            .toList());
  }

  // Get applications submitted by a teacher
  Stream<List<JobApplication>> getApplicationsByTeacher(String teacherId) {
    Query query = FirestoreWrapper.query('applications')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('appliedAt', descending: true);

    return FirestoreWrapper.getCollectionStream(
            query, 'Applications by teacher $teacherId')
        .map((snapshot) => snapshot.docs
            .map((doc) => JobApplication.fromFirestore(doc))
            .toList());
  }

  // Update application status
  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? notes,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'status': status.toString().split('.').last,
      };

      if (notes != null) {
        updates['institutionNotes'] = notes;
      }

      await FirestoreWrapper.updateDocument(
          'applications', applicationId, updates);
    } catch (e, stackTrace) {
      print('Error updating application status: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Update job status
  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    try {
      await FirestoreWrapper.updateDocument('jobs', jobId, {
        'status': status.toString().split('.').last,
      });
    } catch (e, stackTrace) {
      print('Error updating job status: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Delete job posting
  Future<void> deleteJob(String jobId) async {
    try {
      await FirestoreWrapper.deleteDocument('jobs', jobId);

      // Optionally delete associated applications
      QuerySnapshot applications = await FirestoreWrapper.query('applications')
          .where('jobId', isEqualTo: jobId)
          .get();

      for (var doc in applications.docs) {
        await FirestoreWrapper.deleteDocument('applications', doc.id);
      }
    } catch (e, stackTrace) {
      print('Error deleting job: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
