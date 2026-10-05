import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../styles/app_colors.dart';
import 'more_screen.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import '../data/admin_tab.dart';
import '../widgets/navigation/admin_bottom_nav.dart';

/// Holds the admin tabs, the bar that switches between them, and the swipe
/// that does the same thing with a thumb.
///
/// A [TabBarView] rather than an IndexedStack, so the pages can be dragged
/// left and right the way the customer side's `MainNavigationScreen` works.
/// The bar is still [AdminBottomNav] — the design marks the active tab with a
/// rule along the top edge, which a Material `TabBar` cannot draw — so it is
/// wired to the [TabController] by hand in [_AdminTabs].
///
/// Which tab is showing still lives in [adminTabProvider] rather than here, so
/// the screens inside a tab can move between them: the header's back arrow,
/// the dashboard's 'View all' and the logout all drive it, and the pages
/// follow. Replaced by go_router once real navigation lands.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  /// The tab bodies, in the order [AdminBottomNav.items] lists them.
  static const List<Widget> tabs = [
    DashboardScreen(),
    ProductsScreen(),
    OrdersScreen(),
    CustomersScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    assert(
      tabs.length == AdminBottomNav.items.length,
      'Every slot in the bar needs a page behind it: '
      '${AdminBottomNav.items.length} slots, ${tabs.length} pages.',
    );

    return DefaultTabController(
      length: tabs.length,
      initialIndex: AdminTab.home,
      child: const _AdminTabs(),
    );
  }
}

/// The pages, the bar, and the two-way tie between them.
///
/// Separate from [AdminShell] because [DefaultTabController.of] only finds a
/// controller from a context below the one that supplies it.
class _AdminTabs extends ConsumerStatefulWidget {
  const _AdminTabs();

  @override
  ConsumerState<_AdminTabs> createState() => _AdminTabsState();
}

class _AdminTabsState extends ConsumerState<_AdminTabs> {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final controller = DefaultTabController.of(context);
    if (identical(controller, _controller)) return;
    _controller?.removeListener(_followPages);
    _controller = controller..addListener(_followPages);
  }

  @override
  void dispose() {
    _controller?.removeListener(_followPages);
    super.dispose();
  }

  /// A tap on the bar or a swipe across the pages moved the view: write it
  /// back so the rest of the app knows which tab is showing.
  ///
  /// The guard is what stops this bouncing against the listener below — it
  /// writes only a value the provider does not already hold, so settling on a
  /// tab the provider asked for ends the exchange rather than restarting it.
  void _followPages() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.index == ref.read(adminTabProvider)) return;
    ref.read(adminTabProvider.notifier).select(controller.index);
  }

  @override
  Widget build(BuildContext context) {
    // The other direction: something that is not the bar moved the tab — the
    // header's back arrow, the dashboard's 'View all', a logout — and the
    // pages have to go there too.
    ref.listen<int>(adminTabProvider, (_, next) {
      final controller = _controller;
      if (controller == null || controller.index == next) return;
      controller.animateTo(next);
    });

    final index = ref.watch(adminTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: TabBarView(
        physics: const BouncingScrollPhysics(),
        children: [
          for (final tab in AdminShell.tabs) _TabPage(child: tab),
        ],
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: index,
        // Animated rather than set, so a tap and a swipe arrive the same way
        // and the listener above sees one kind of movement.
        onSelect: (selected) => _controller?.animateTo(selected),
      ),
    );
  }
}

/// One tab inside the [TabBarView], given back the two things the IndexedStack
/// used to provide for free.
///
/// **It stays mounted.** [TabBarView] builds the pages either side of the
/// current one and throws the rest away, so without the keep-alive the orders
/// filter would snap back to New and whatever was half-typed into the customer
/// search would be gone every time the admin swiped past.
///
/// **Its controls keep their own voices.** A page inside a [TabBarView] has its
/// semantics merged, which collapsed the whole page header into a single node
/// — a screen reader read the back button as "Back Orders 3 new today" instead
/// of "Back". `explicitChildNodes` puts the nodes back the way every other
/// screen has them; the shell test checks the count.
class _TabPage extends StatefulWidget {
  const _TabPage({required this.child});

  final Widget child;

  @override
  State<_TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<_TabPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // The mixin's own build has to run for the keep-alive to be registered.
    super.build(context);
    return Semantics(explicitChildNodes: true, child: widget.child);
  }
}
