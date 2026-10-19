/// Firebase only deletes an account for a sign-in that is recent. Within this
/// window the app does not ask the user to confirm who they are again; after
/// it, it must (Google, Apple or password), because Firebase would refuse.
///
/// Measured against Firebase's server: a delete 30 s, 2.5, 3.3 and 4 minutes
/// after sign-in was accepted; after 5 and 7 minutes it was refused
/// (CREDENTIAL_TOO_OLD_LOGIN_AGAIN). 3 minutes keeps a margin under that.
const recentSignInWindow = Duration(minutes: 3);

/// Whether a sign-in made at [signedInAt] is still recent at [now].
/// An unknown sign-in time is never recent.
bool signInIsRecent(DateTime? signedInAt, DateTime now) {
  if (signedInAt == null) return false;
  return now.difference(signedInAt) < recentSignInWindow;
}
