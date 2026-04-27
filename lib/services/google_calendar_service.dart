import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleCalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      gcal.CalendarApi.calendarEventsScope,
    ],
  );

  static GoogleSignInAccount? _account;

  static GoogleSignInAccount? get currentAccount => _account;
  static bool get isSignedIn => _account != null;

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      _account = await _googleSignIn.signIn();
      return _account;
    } catch (e) {
      return null;
    }
  }

  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      _account = await _googleSignIn.signInSilently();
      return _account;
    } catch (e) {
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
  }

  /// Returns a Firebase OAuthCredential from the current Google Sign-In session.
  /// Triggers sign-in if not already signed in.
  static Future<OAuthCredential?> getFirebaseCredential() async {
    _account ??= await _googleSignIn.signIn();
    if (_account == null) return null;
    final auth = await _account!.authentication;
    return GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
  }

  /// Creates a Google Calendar event with Meet conferencing.
  /// Returns the Meet link or null on failure.
  static Future<MeetResult> createMeeting({
    required String title,
    required DateTime scheduledAt,
    required Duration duration,
    List<String> attendeeEmails = const [],
  }) async {
    try {
      // Ensure signed in
      _account ??= await _googleSignIn.signInSilently();
      _account ??= await _googleSignIn.signIn();
      if (_account == null) {
        return MeetResult.error('Sign-in cancelled');
      }

      // On iOS requestScopes doesn't work on stale sessions — if it fails,
      // force a fresh sign-in so the consent screen includes Calendar scope.
      final hasScope = await _googleSignIn.requestScopes([
        gcal.CalendarApi.calendarEventsScope,
      ]);
      if (!hasScope) {
        await _googleSignIn.signOut();
        _account = await _googleSignIn.signIn();
        if (_account == null) {
          return MeetResult.error('Sign-in cancelled');
        }
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        return MeetResult.error('Could not authenticate with Google');
      }

      final calendarApi = gcal.CalendarApi(authClient);

      final event = gcal.Event(
        summary: title,
        start: gcal.EventDateTime(
          dateTime: scheduledAt,
          timeZone: 'America/Montevideo',
        ),
        end: gcal.EventDateTime(
          dateTime: scheduledAt.add(duration),
          timeZone: 'America/Montevideo',
        ),
        attendees: attendeeEmails
            .map((e) => gcal.EventAttendee(email: e))
            .toList(),
        conferenceData: gcal.ConferenceData(
          createRequest: gcal.CreateConferenceRequest(
            requestId: '${DateTime.now().millisecondsSinceEpoch}',
            conferenceSolutionKey: gcal.ConferenceSolutionKey(
              type: 'hangoutsMeet',
            ),
          ),
        ),
      );

      final created = await calendarApi.events.insert(
        event,
        'primary',
        conferenceDataVersion: 1,
      );

      final link = created.hangoutLink;
      final eventId = created.id;

      if (link == null) {
        return MeetResult.error('Google did not return a Meet link');
      }

      return MeetResult.success(meetLink: link, calendarEventId: eventId);
    } catch (e) {
      return MeetResult.error(e.toString());
    }
  }
}

class MeetResult {
  final bool ok;
  final String? meetLink;
  final String? calendarEventId;
  final String? error;

  const MeetResult._({
    required this.ok,
    this.meetLink,
    this.calendarEventId,
    this.error,
  });

  factory MeetResult.success({
    required String meetLink,
    String? calendarEventId,
  }) =>
      MeetResult._(ok: true, meetLink: meetLink, calendarEventId: calendarEventId);

  factory MeetResult.error(String message) =>
      MeetResult._(ok: false, error: message);
}
