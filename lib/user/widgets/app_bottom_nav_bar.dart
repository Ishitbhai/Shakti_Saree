import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:shakti_saree/user/screens/my_orders_screen.dart';
import 'package:shakti_saree/user/screens/profile_screen.dart';
import 'package:shakti_saree/user/screens/home_screen.dart';
import 'package:shakti_saree/user/screens/categories_screen.dart';
import 'package:shakti_saree/user/screens/cart_screen.dart';
=======
>>>>>>> origin/ishit
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNavBar({super.key, required this.selectedIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.muted.withOpacity(0.3), width: 1),
        ),
      ),
<<<<<<< HEAD
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            index: 0,
            label: 'Home',
            icon: Icons.home_outlined,
          ),
          _buildNavItem(
            context: context,
            index: 1,
            label: 'Category',
            icon: Icons.grid_view_outlined,
          ),
          _buildNavItem(
            context: context,
            index: 2,
            label: 'Cart',
            icon: Icons.shopping_bag_outlined,
          ),
          _buildNavItem(
            context: context,
            index: 3,
            label: 'Orders',
            icon: Icons.view_in_ar,
          ),
          _buildNavItem(
            context: context,
            index: 4,
            label: 'Profile',
            icon: Icons.person_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = selectedIndex == index;
    final Color itemColor = isSelected ? AppColors.primary : AppColors.muted;

    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CategoriesScreen()),
          );
        }
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CartScreen()),
          );
        }
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
          );
        }
        if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
=======
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
>>>>>>> origin/ishit
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(
              1,
              Icons.grid_view_outlined,
              Icons.grid_view,
              'Category',
            ),
            _buildNavItem(
              2,
              Icons.shopping_bag_outlined,
              Icons.shopping_bag,
              'Cart',
            ),
            _buildNavItem(
              3,
              Icons.inventory_2_outlined,
              Icons.inventory_2,
              'Orders',
            ),
            _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
  ) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (onTap != null) {
          onTap!(index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? selectedIcon : unselectedIcon,
            color: isSelected ? AppColors.primary : AppColors.muted,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? AppColors.primary : AppColors.muted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
