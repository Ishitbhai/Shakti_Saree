import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/more/admin_profile.dart';
import 'mock_data.dart';

/// The app's one copy of who is signed in, on the same footing as the order,
/// product and category stores.
///
/// A single record rather than a list, because there is no sign-in and so
/// nobody else it could be. Writing replaces it whole, so the More header,
/// the monogram and anything else reading the profile recompute without
/// being told to.
///
/// State lives only as long as the process; a restart — or a logout, which
/// throws the stores away — re-seeds from [MockData].
class ProfileStore extends Notifier<AdminProfile> {
  @override
  AdminProfile build() => MockData.admin();

  /// Who is signed in.
  AdminProfile get profile => state;

  /// Saves an edited profile and answers with what was stored.
  ///
  /// Nothing to reject here: the profile has no identity to collide with, so
  /// whether a given set of values is allowed is the form's business.
  AdminProfile save(AdminProfile updated) {
    state = updated;
    return updated;
  }
}

/// The single profile, alive for as long as the app is.
final profileStoreProvider = NotifierProvider<ProfileStore, AdminProfile>(
  ProfileStore.new,
);
