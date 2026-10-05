import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  // 1. Text Controllers
  final TextEditingController _queryController = TextEditingController();

  // 2. Form & UI State Variables
  int? _expandedIndex = 0;

  // 3. Error / Status Strings
  String errQuery = '';
  String successMessage = '';

  final List<Map<String, String>> _faqList = [
    {
      'question': 'How to see status of my orders',
      'answer':
          'Go to Profile > My Orders. There you will find direct live status and tracking link.\nYou can track your order after 24 hours of order.',
    },
    {
      'question': 'Can I apply for any coupen code?',
      'answer':
          'Yes, you can apply available coupon codes at the cart and checkout pages to avail special festive discounts.',
    },
    {
      'question': 'What are return and refund policy?',
      'answer':
          'We offer an easy 7-day return and refund policy from the date of delivery for unused sarees in original packaging.',
    },
    {
      'question': 'How much is delivery charge?',
      'answer':
          'Standard delivery is FREE on all orders across India. Express delivery options may carry nominal charges.',
    },
    {
      'question': 'How long a saree size can be?',
      'answer':
          'Standard sarees are 5.5 meters in length along with an additional 0.8-meter unstitched blouse piece.',
    },
    {
      'question': 'Is Cash On Delivery is available?',
      'answer':
          'Yes, Cash On Delivery (COD) is available on all eligible postal pin codes across India.',
    },
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  // Submit and Validation
  void validateAndSubmitQuery() {
    setState(() {
      final queryText = _queryController.text.trim();

      if (queryText.isEmpty) {
        errQuery = 'Please enter your message';
        successMessage = '';
      } else if (queryText.length < 5) {
        errQuery = 'Query must be at least 5 characters';
        successMessage = '';
      } else {
        errQuery = '';
        successMessage = 'Your query has been submitted successfully!';
        _queryController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Help & Support',
                          style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'We are ready to help you',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ================= SECTION TITLE =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Frequently Asked Questions',
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ================= FAQ LIST =================
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                itemCount: _faqList.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final faq = _faqList[index];
                  final bool isExpanded = _expandedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.black.withOpacity(0.75),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question Header Row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  faq['question']!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.chevron_right,
                                color: AppColors.black,
                                size: 20,
                              ),
                            ],
                          ),

                          // Expanded Answer Body
                          if (isExpanded) ...[
                            const SizedBox(height: 10),
                            Divider(
                              color: AppColors.muted.withOpacity(0.4),
                              height: 1,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              faq['answer']!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.muted,
                                fontSize: 11,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
