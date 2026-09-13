/// Who is signed in, as the More tab shows them.
///
/// There is no sign-in yet, so this is one fixed record rather than a session.
/// It lives as a model anyway: the screen reads a profile, and swapping the
/// mock for a real one later is a change to where it comes from, not to what
/// reads it.
class AdminProfile {
  const AdminProfile({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;

  /// What they are allowed to do, as a label. Not enforced anywhere yet.
  final String role;

  /// The single letter on the avatar.
  String get initial =>
      name.trim().isEmpty ? '-' : name.trim()[0].toUpperCase();
}
