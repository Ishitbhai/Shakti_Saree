import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which admin tab the shell is showing.
///
/// Held out here rather than inside the shell so that anything within a tab
/// can move between them. The header's back arrow is why: at the root of a
/// tab there is no route to pop, and it has to go somewhere.
class AdminTab extends Notifier<int> {
  /// The tab the app opens on, and the leftmost in the bar.
  static const int home = 0;

  @override
  int build() => home;

  void select(int index) => state = index;

  /// Steps one tab to the left, which is what back means inside the bar:
  /// Orders goes to Products, Products to the Dashboard.
  ///
  /// Positional rather than a history of where the admin has been, so the
  /// arrow always leads to the same place from a given tab. On the first tab
  /// there is nothing further left and it stays put.
  void back() {
    if (state > home) state = state - 1;
  }
}

final adminTabProvider = NotifierProvider<AdminTab, int>(AdminTab.new);
