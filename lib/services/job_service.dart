import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/job_posting.dart';
import '../models/job_application.dart';
import '../models/teacher_profile.dart';
import 'firestore_wrapper.dart';
import 'notification_service.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Create a new job posting
  Future<String> createJobPosting(JobPosting job) async {
    try {
      DocumentReference docRef = await _firestore.collection('jobs').add(job.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating job posting: $e');
      rethrow;
    }
  }

  // Get all active job postings
  Stream<List<JobPosting>> getActiveJobs() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'active')
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => JobPosting.fromFirestore(doc))
        .toList());
  }

  // Get jobs posted by a specific institution
  Stream<List<JobPosting>> getJobsByInstitution(String uid) {
    return _firestore
        .collection('jobs')
        .where('postedBy', isEqualTo: uid)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => JobPosting.fromFirestore(doc))
        .toList());
  }

  // Search jobs with filters
  Stream<List<JobPosting>> searchJobs({
    String? location,
    List<AvailabilityShift>? shifts,
    List<TeachingLevel>? levels,
  }) {
    Query query = _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'active');

    if (location != null && location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }

    return query
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<JobPosting> jobs = snapshot.docs
          .map((doc) => JobPosting.fromFirestore(doc))
          .toList();

      // Filter by shifts and levels in-memory
      if (shifts != null && shifts.isNotEmpty) {
        jobs = jobs.where((job) =>
            job.shifts.any((shift) => shifts.contains(shift))
        ).toList();
      }

      if (levels != null && levels.isNotEmpty) {
        jobs = jobs.where((job) =>
            job.levels.any((level) => levels.contains(level))
        ).toList();
      }

      return jobs;
    });
  }

  Future<JobPosting?> getJobById(String jobId) async {
    final doc = await _firestore.collection('jobs').doc(jobId).get();
    if (!doc.exists) return null;
    return JobPosting.fromFirestore(doc);
  }

  // Apply to a job
  Future<void> applyToJob({
    required String jobId,
    required String jobTitle,
    required String institutionName,
    required String institutionId,
    required String teacherId,
    required String teacherName,
    String? teacherEmail,
    String? teacherPhotoUrl,
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
        teacherPhotoUrl: teacherPhotoUrl,
        cvUrl: cvUrl,
        coverLetter: coverLetter,
        appliedAt: DateTime.now(),
      );
      await FirestoreWrapper.addDocument('applications', application.toMap());
      await FirestoreWrapper.updateDocument('jobs', jobId, {
        'applicationsCount': FieldValue.increment(1),
      });
      NotificationService().createNotification(
        userId: institutionId,
        title: 'New application received',
        body: '$teacherName applied for "$jobTitle"',
        type: 'new_application',
        data: {'jobId': jobId, 'jobTitle': jobTitle, 'teacherName': teacherName},
      );
    } catch (e, stackTrace) {
      print('Error applying to job: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get applications for a specific job
  Stream<List<JobApplication>> getApplicationsForJob(String jobId) {
    return _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => JobApplication.fromFirestore(doc))
        .toList());
  }

  // Get applications submitted by a teacher
  Stream<List<JobApplication>> getApplicationsByTeacher(String teacherId) {
    return _firestore
        .collection('applications')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => JobApplication.fromFirestore(doc))
        .toList());
  }

  // Update application status
  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? notes,
    String? teacherId,
    String? jobTitle,
    String? institutionName,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'status': status.toString().split('.').last,
      };
      if (notes != null) updates['institutionNotes'] = notes;

      await _firestore.collection('applications').doc(applicationId).update(updates);

      if (teacherId != null && jobTitle != null) {
        final statusLabel = status.toString().split('.').last;
        final emoji = status == ApplicationStatus.accepted
            ? '🎉'
            : status == ApplicationStatus.rejected
                ? '😔'
                : 'ℹ️';
        NotificationService().createNotification(
          userId: teacherId,
          title: '$emoji Application $statusLabel',
          body: 'Your application for "$jobTitle"${institutionName != null ? ' at $institutionName' : ''} was marked as $statusLabel.',
          type: 'status_update',
          data: {
            'applicationId': applicationId,
            'jobTitle': jobTitle,
            'institutionName': institutionName,
            'status': statusLabel,
          },
        );
      }
    } catch (e) {
      print('Error updating application status: $e');
      rethrow;
    }
  }

  // Update job status
  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      print('Error updating job status: $e');
      rethrow;
    }
  }

  Future<void> incrementJobViews(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (_) {
      // Non-critical metric — silently ignore permission or network errors
    }
  }

  // Delete job posting
  Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();

      // Optionally delete associated applications
      QuerySnapshot applications = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .get();

      for (var doc in applications.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting job: $e');
      rethrow;
    }
  }
}