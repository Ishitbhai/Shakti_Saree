import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../mock/profile_store.dart';
import '../shared/widgets/labelled_field.dart';
import 'admin_profile.dart';
import 'widgets/gender_selector.dart';

/// Form for editing who is signed in.
///
/// The same draft arrangement as the inventory screen: everything typed here
/// edits a local copy, and the stored profile only moves when Save Changes is
/// pressed. Save is enabled by comparing the draft against what is stored, so
/// a field edited back to the value it started with leaves nothing to save.
///
/// Only what [AdminProfile] holds is editable. The role is carried through
/// untouched — it is not the admin's to change.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  /// The earliest birth date the picker offers.
  static final DateTime earliestBirthDate = DateTime(1900);

  /// How large a picked photo is kept.
  ///
  /// An avatar is never shown bigger than a coin, and the bytes live in
  /// memory for as long as the app does — a 12-megapixel original would be
  /// megabytes of it for no visible gain.
  static const double maxPhotoSize = 512;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  /// A name that is not an address, an address without an @, and so on: the
  /// point is to catch a typo, not to be the last word on RFC 5322.
  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  /// Ten digits starting 6-9, optionally behind a country code or a trunk
  /// zero — which is what an Indian mobile number looks like.
  static final RegExp _mobilePattern = RegExp(r'^(?:\+?91|0)?[6-9]\d{9}$');

  late final AdminProfile _opened = ref.read(profileStoreProvider);

  late final _name = TextEditingController(text: _opened.name);
  late final _email = TextEditingController(text: _opened.email);
  late final _mobile = TextEditingController(text: _opened.mobile);

  late DateTime _dateOfBirth = _opened.dateOfBirth;
  late Gender _gender = _opened.gender;
  late Uint8List? _photo = _opened.photo;

  final _picker = ImagePicker();

  /// Set once Save has been pressed, so the form does not open already
  /// complaining about fields nobody has touched.
  bool _submitted = false;

  List<TextEditingController> get _fields => [_name, _email, _mobile];

  @override
  void initState() {
    super.initState();
    // The save button's enablement, the error text and the discard guard all
    // depend on what has been typed, so every keystroke has to reach build.
    for (final field in _fields) {
      field.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final field in _fields) {
      field
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------- the draft
  /// The profile as stored right now.
  ///
  /// Read rather than remembered from when the screen opened, so what Save
  /// compares against is the real thing — including straight after a save,
  /// which is what disables the button again.
  AdminProfile get _stored => ref.read(profileStoreProvider);

  /// The profile as currently typed.
  ///
  /// Trimmed, so trailing whitespace is neither saved nor mistaken for an
  /// edit. Spelled out with the constructor rather than [AdminProfile.copyWith]
  /// so that a removed photo is a removed photo, and not a value copyWith
  /// reads as "leave it alone". The role is the one thing carried over.
  AdminProfile get _draft => AdminProfile(
    name: _name.text.trim(),
    email: _email.text.trim(),
    role: _stored.role,
    mobile: _mobile.text.trim(),
    dateOfBirth: _dateOfBirth,
    gender: _gender,
    photo: _photo,
  );

  bool get _isDirty => _draft != _stored;

  // ------------------------------------------------------------ validation
  String? get _nameError => _draft.name.isEmpty ? 'A name is required.' : null;

  String? get _emailError {
    final email = _draft.email;
    if (email.isEmpty) return 'An email address is required.';
    return _emailPattern.hasMatch(email)
        ? null
        : 'That does not look like an email address.';
  }

  /// A blank mobile is allowed — not every admin has one on file — but a
  /// number that is there has to be one somebody could ring.
  String? get _mobileError {
    final digits = _draft.mobile.replaceAll(RegExp(r'[\s()-]'), '');
    if (digits.isEmpty) return null;
    return _mobilePattern.hasMatch(digits)
        ? null
        : 'Enter a 10-digit Indian mobile number.';
  }

  /// The picker cannot offer a future date, but a stored profile can still
  /// be carrying one, and saving over it should not launder it.
  String? get _dateOfBirthError => _dateOfBirth.isBefore(DateTime.now())
      ? null
      : 'Date of birth has to be in the past.';

  bool get _isValid =>
      _nameError == null &&
      _emailError == null &&
      _mobileError == null &&
      _dateOfBirthError == null;

  /// Shown only once Save has been pressed, so typing is not nagged at.
  String? _shown(String? error) => _submitted ? error : null;

  // --------------------------------------------------------------- actions
  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth.isAfter(now) ? now : _dateOfBirth,
      firstDate: EditProfileScreen.earliestBirthDate,
      lastDate: now,
      helpText: 'Date of Birth',
    );
    if (picked == null || !mounted) return;
    setState(() => _dateOfBirth = picked);
  }

  void _save() {
    setState(() => _submitted = true);
    if (!_isValid || !_isDirty) return;

    // Taken before the pop, because the messenger is found by walking up from
    // this context and this screen is about to leave the tree.
    final messenger = ScaffoldMessenger.of(context);
    ref.read(profileStoreProvider.notifier).save(_draft);
    // Saved, so there is nothing left to warn about — and an outright pop
    // goes through the guard rather than around it.
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  /// Opens the gallery and takes the picture that comes back into the draft.
  ///
  /// Bytes are read here rather than a path kept, so the thumbnail renders
  /// the same way on mobile and on web — where a file path is a blob URL
  /// rather than something on disk — and so the picture survives the system
  /// clearing up the temporary file the picker handed over.
  ///
  /// Nothing is stored until Save, like every other field on this form.
  Future<void> _pickPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: EditProfileScreen.maxPhotoSize,
        maxHeight: EditProfileScreen.maxPhotoSize,
      );
      // Null means the gallery was closed without choosing anything, which
      // is not a failure and should leave the draft exactly as it was.
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = bytes);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not open the gallery: $error')),
        );
    }
  }

  /// Takes the picture off the draft, putting the initials back.
  void _removePhoto() => setState(() => _photo = null);

  // -------------------------------------------------------- unsaved changes
  /// Asks before throwing away edits. Answers true if it is fine to leave.
  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: Text(
          'This profile has changes that have not been saved. Leaving now '
          'loses them.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  /// The one way out of this screen, whichever gesture asked for it.
  Future<void> _leave(bool didPop) async {
    if (didPop) return;
    final mayLeave = !_isDirty || await _confirmDiscard();
    if (mayLeave && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Watched as well as read: a logout resets the store underneath this
    // screen, and the draft is compared against whatever is there now.
    ref.watch(profileStoreProvider);

    return PopScope<void>(
      // Always intercepted, so the answer is worked out at the moment of the
      // gesture rather than at whenever the last rebuild happened to be.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _leave(didPop),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(
              initials: _draft.initials,
              photo: _photo,
              onBack: () => Navigator.maybePop(context),
              onChangePhoto: _pickPhoto,
              onRemovePhoto: _photo == null ? null : _removePhoto,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x5,
                AppSpacing.x5,
                AppSpacing.x8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FieldCard(
                    children: [
                      LabelledField(
                        label: 'Full Name',
                        child: TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            prefixIcon: const _FieldIcon(Icons.person_outline),
                            hintText: 'Priyanshu Kateshiya',
                            errorText: _shown(_nameError),
                          ),
                        ),
                      ),
                      LabelledField(
                        label: 'Email Address',
                        child: TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            prefixIcon: const _FieldIcon(Icons.mail_outline),
                            hintText: 'k@example.com',
                            errorText: _shown(_emailError),
                          ),
                        ),
                      ),
                      LabelledField(
                        label: 'Mobile Number',
                        child: TextField(
                          controller: _mobile,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            prefixIcon: const _FieldIcon(Icons.call_outlined),
                            hintText: '+91 98765 43210',
                            errorText: _shown(_mobileError),
                          ),
                        ),
                      ),
                      LabelledField(
                        label: 'Date of Birth',
                        child: _DateField(
                          date: _dateOfBirth,
                          errorText: _shown(_dateOfBirthError),
                          onTap: _pickDateOfBirth,
                        ),
                      ),
                      LabelledField(
                        label: 'Gender',
                        child: GenderSelector(
                          selected: _gender,
                          onSelect: (gender) =>
                              setState(() => _gender = gender),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  FilledButton(
                    // Nothing to save until something differs from what is
                    // stored, and saying so beats a button that quietly does
                    // nothing.
                    onPressed: _isDirty ? _save : null,
                    child: const Text('Save Changes'),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  TextButton(
                    onPressed: () => _leave(false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Curved maroon block, the avatar straddling its bottom edge, and the photo
/// action beneath.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.onBack,
    required this.onChangePhoto,
    this.photo,
    this.onRemovePhoto,
  });

  final String initials;

  /// The picture as the draft has it, or null while there is none.
  final Uint8List? photo;

  final VoidCallback onBack;
  final VoidCallback onChangePhoto;

  /// Null where there is no picture to take off, which is also when the
  /// action has no business being on screen.
  final VoidCallback? onRemovePhoto;

  /// Straight from the design; not on the base-4 scale.
  static const double _avatar = 72;
  static const double _backSquare = 36;
  static const double _badge = 24;

  @override
  Widget build(BuildContext context) {
    // Status bar height varies with the notch; read it rather than assuming.
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        Stack(
          // The avatar hangs past the maroon block; nothing may be trimmed.
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadii.sheet),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.x5,
                topInset + AppSpacing.x4,
                AppSpacing.x5,
                AppSpacing.x10,
              ),
              child: Row(
                children: [
                  Semantics(
                    label: 'Back',
                    button: true,
                    // A node of its own: without this the annotation folds
                    // into the list item along with the title, and the way
                    // back reads as part of a sentence.
                    container: true,
                    child: InkWell(
                      onTap: onBack,
                      customBorder: const CircleBorder(),
                      child: const SizedBox.square(
                        dimension: _backSquare,
                        child: Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Admin Edit Profile',
                      textAlign: TextAlign.center,
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                  // Balances the back square so the title stays centred.
                  const SizedBox.square(dimension: _backSquare),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: -_avatar / 2,
              child: Center(
                child: _Avatar(initials: initials, photo: photo),
              ),
            ),
          ],
        ),
        // The half of the avatar hanging below the block, and the gap under
        // it.
        const SizedBox(height: _avatar / 2 + AppSpacing.x2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: onChangePhoto,
              child: Text(photo == null ? 'Change Photo' : 'Replace Photo'),
            ),
            // Only where there is something to remove — the design has one
            // action, and a dead second one would be worse than none.
            if (onRemovePhoto != null)
              TextButton(
                onPressed: onRemovePhoto,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textGrey,
                ),
                child: const Text('Remove Photo'),
              ),
          ],
        ),
      ],
    );
  }
}

/// The picture — or the gold circle with the admin's initials where there is
/// none — and the camera badge.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.photo});

  final String initials;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;

    return SizedBox.square(
      dimension: _ProfileHeader._avatar,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative: the name field below says who this is, and the photo
          // actions underneath are the controls.
          ExcludeSemantics(
            child: Container(
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: photo == null
                  ? Text(
                      initials,
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.textOnAccent,
                      ),
                    )
                  : Image.memory(
                      photo,
                      fit: BoxFit.cover,
                      width: _ProfileHeader._avatar,
                      height: _ProfileHeader._avatar,
                      // The bytes are already in hand; fading in from nothing
                      // would only make the avatar flicker on every rebuild.
                      gaplessPlayback: true,
                    ),
            ),
          ),
          const Positioned(
            right: 0,
            bottom: 0,
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.background, width: 2),
                  ),
                ),
                child: SizedBox.square(
                  dimension: _ProfileHeader._badge,
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 13,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The white card the fields sit in.
class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        boxShadow: AppShadows.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0) const SizedBox(height: AppSpacing.x4),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// A date, shown as a field and edited by the platform picker.
///
/// Not a text field: a date typed by hand is a date to be parsed, and the
/// form would then be arguing about formats instead of about birthdays.
class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap, this.errorText});

  final DateTime date;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final formatted = Formatters.date(date);
    // InputDecorator, unlike a TextField, is not given the theme's field
    // styling for free.
    final decoration = InputDecoration(
      prefixIcon: const _FieldIcon(Icons.calendar_today_outlined),
      suffixIcon: const Icon(
        Icons.keyboard_arrow_down,
        size: 20,
        color: AppColors.textGrey,
      ),
      errorText: errorText,
    ).applyDefaults(Theme.of(context).inputDecorationTheme);

    return Semantics(
      label: 'Date of Birth, $formatted',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: InputDecorator(
          decoration: decoration,
          child: Text(formatted, style: AppTypography.bodyMedium),
        ),
      ),
    );
  }
}

/// The leading icon inside a field.
class _FieldIcon extends StatelessWidget {
  const _FieldIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 18, color: AppColors.textGrey);
  }
}
