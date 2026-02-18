import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/job_posting.dart';
import '../models/job_application.dart';
import '../models/teacher_profile.dart';
import 'firestore_wrapper.dart';

class JobService {
  final _uuid = const Uuid();

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

  Stream<List<JobPosting>> getActiveJobs() {
    Query query = FirestoreWrapper.query('jobs')
        .where('status', isEqualTo: 'active')
        .orderBy('postedAt', descending: true);
    return FirestoreWrapper.getCollectionStream(query, 'Active jobs').map(
        (snapshot) =>
            snapshot.docs.map((doc) => JobPosting.fromFirestore(doc)).toList());
  }

  Stream<List<JobPosting>> getJobsByInstitution(String uid) {
    Query query = FirestoreWrapper.query('jobs')
        .where('postedBy', isEqualTo: uid)
        .orderBy('postedAt', descending: true);
    return FirestoreWrapper.getCollectionStream(
            query, 'Jobs by institution $uid')
        .map((snapshot) =>
            snapshot.docs.map((doc) => JobPosting.fromFirestore(doc)).toList());
  }

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

  // Apply to a job — ahora recibe jobTitle e institutionName
  Future<void> applyToJob({
    required String jobId,
    required String jobTitle,
    required String institutionName,
    required String teacherId,
    required String teacherName,
    String? teacherEmail,
    String? cvUrl,
    String? coverLetter,
  }) async {
    try {
      QuerySnapshot existing = await FirestoreWrapper.query('applications')
          .where('jobId', isEqualTo: jobId)
          .where('teacherId', isEqualTo: teacherId)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('Already applied to this job');
      }
      JobApplication application = JobApplication(
        id: _uuid.v4(),
        jobId: jobId,
        jobTitle: jobTitle,
        institutionName: institutionName,
        teacherId: teacherId,
        teacherName: teacherName,
        teacherEmail: teacherEmail,
        cvUrl: cvUrl,
        coverLetter: coverLetter,
        appliedAt: DateTime.now(),
      );
      await FirestoreWrapper.addDocument('applications', application.toMap());
      await FirestoreWrapper.updateDocument('jobs', jobId, {
        'applicationsCount': FieldValue.increment(1),
      });
    } catch (e, stackTrace) {
      print('Error applying to job: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

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

  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? notes,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'status': status.toString().split('.').last,
      };
      if (notes != null) updates['institutionNotes'] = notes;
      await FirestoreWrapper.updateDocument(
          'applications', applicationId, updates);
    } catch (e, stackTrace) {
      print('Error updating application status: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

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

  Future<void> deleteJob(String jobId) async {
    try {
      await FirestoreWrapper.deleteDocument('jobs', jobId);
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
