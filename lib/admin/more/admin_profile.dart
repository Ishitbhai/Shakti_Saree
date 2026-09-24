/// Which of the three the profile form has selected.
///
/// Three buttons rather than a free-text field, because that is all the form
/// offers — and an enum means a screen can never be handed a gender the
/// selector cannot show.
enum Gender {
  male('Male'),
  female('Female'),
  other('Other');

  const Gender(this.label);

  /// What the button says.
  final String label;
}

/// Who is signed in, as the More tab shows them and the profile form edits
/// them.
///
/// There is no sign-in yet, so the seed is one fixed record rather than a
/// session. It lives as a model anyway: the screens read a profile, and
/// swapping the mock for a real one later is a change to where it comes from,
/// not to what reads it.
///
/// Value equality is the point of this class, not a nicety: the profile form
/// enables its save button by comparing what has been typed against what is
/// stored, so two profiles holding the same values have to compare equal.
class AdminProfile {
  const AdminProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.mobile,
    required this.dateOfBirth,
    required this.gender,
  });

  final String name;
  final String email;

  /// What they are allowed to do, as a label. Not enforced anywhere yet, and
  /// not editable — the profile form carries it through untouched.
  final String role;

  /// As typed, spacing and country code included. Stored the way it was
  /// entered rather than normalised, because it is only ever displayed.
  final String mobile;

  /// Date only — the form's picker has no time to give it.
  final DateTime dateOfBirth;

  final Gender gender;

  /// The single letter on the More tab's avatar.
  String get initial =>
      name.trim().isEmpty ? '-' : name.trim()[0].toUpperCase();

  /// The two letters on the brand monogram: the first of the first word and
  /// the first of the last.
  ///
  /// Split on spaces and the punctuation that separates names, so
  /// 'Admin - Shakti Saree' reads as three words rather than four.
  String get initials {
    final words = [
      for (final word in name.split(RegExp(r'[\s\-_.,]+')))
        if (word.isNotEmpty) word,
    ];
    if (words.isEmpty) return '-';
    final last = words.length == 1 ? '' : words.last[0];
    return (words.first[0] + last).toUpperCase();
  }

  AdminProfile copyWith({
    String? name,
    String? email,
    String? role,
    String? mobile,
    DateTime? dateOfBirth,
    Gender? gender,
  }) => AdminProfile(
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    mobile: mobile ?? this.mobile,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
  );

  @override
  bool operator ==(Object other) =>
      other is AdminProfile &&
      other.name == name &&
      other.email == email &&
      other.role == role &&
      other.mobile == mobile &&
      other.dateOfBirth == dateOfBirth &&
      other.gender == gender;

  @override
  int get hashCode =>
      Object.hash(name, email, role, mobile, dateOfBirth, gender);
}
