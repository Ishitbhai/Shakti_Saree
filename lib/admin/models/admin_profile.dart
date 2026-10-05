import 'dart:typed_data';

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
    this.photo,
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

  /// The profile picture, as encoded image bytes, or null for none.
  ///
  /// Bytes rather than a path, so the same code paints it on mobile, desktop
  /// and web without touching `dart:io` — and because a picked file's path is
  /// a temporary the system is free to delete, while what the profile holds
  /// has to outlive the picker.
  ///
  /// In memory only, like everything else in the store: a restart loses it,
  /// exactly as a restart loses an edited product.
  final Uint8List? photo;

  /// Whether there is a picture to show instead of [initials].
  bool get hasPhoto => photo != null;

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

  /// Carries the photo through untouched.
  ///
  /// Taking one *off* a profile cannot go through here — `photo ?? this.photo`
  /// has no way to say "none" — so removing a picture builds the profile with
  /// the constructor instead, which is what the form does.
  AdminProfile copyWith({
    String? name,
    String? email,
    String? role,
    String? mobile,
    DateTime? dateOfBirth,
    Gender? gender,
    Uint8List? photo,
  }) => AdminProfile(
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    mobile: mobile ?? this.mobile,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
    photo: photo ?? this.photo,
  );

  @override
  bool operator ==(Object other) =>
      other is AdminProfile &&
      other.name == name &&
      other.email == email &&
      other.role == role &&
      other.mobile == mobile &&
      other.dateOfBirth == dateOfBirth &&
      other.gender == gender &&
      _samePhoto(other.photo, photo);

  /// Two pictures are the same picture when they are the same bytes.
  ///
  /// By content rather than by identity, because the picker hands back a new
  /// list every time: choosing the same file again would otherwise leave the
  /// form looking edited when nothing about it had changed. The length check
  /// settles the ordinary case — a different picture — without walking
  /// either list.
  static bool _samePhoto(Uint8List? a, Uint8List? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  /// The photo is left out: equal profiles have to agree on their hash codes,
  /// and two equal pictures are different objects. Its length stands in,
  /// which is cheap and keeps the contract.
  @override
  int get hashCode => Object.hash(
    name,
    email,
    role,
    mobile,
    dateOfBirth,
    gender,
    photo?.length,
  );
}
