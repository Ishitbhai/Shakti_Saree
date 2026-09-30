import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
// import '../styles/app_text_styles.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 4, // Opens on Profile tab initially
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: AppColors.white,

        // ================= TAB BAR VIEW (SWIPEABLE PAGES) =================
        body: const TabBarView(
          // Uses standard scroll physics so swiping left/right works like WhatsApp
          physics: BouncingScrollPhysics(),
          children: [
            Center(child: Text('Home (Vivek Scope)')),
            Center(child: Text('Category (Vivek Scope)')),
            Center(child: Text('Cart (Vivek Scope)')),
            MyOrdersScreen(), // Your Tab 3
            ProfileScreen(), // Your Tab 4
          ],
        ),

        // ================= BOTTOM TAB BAR =================
        bottomNavigationBar: Material(
          color: AppColors.white,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.muted.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: const SafeArea(
              top: false,
              child: TabBar(
                indicatorColor:
                    Colors.transparent, // Keeps icons clean without underline
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.muted,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(icon: Icon(Icons.home_outlined), text: 'Home'),
                  Tab(icon: Icon(Icons.grid_view_outlined), text: 'Category'),
                  Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Cart'),
                  Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Orders'),
                  Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
