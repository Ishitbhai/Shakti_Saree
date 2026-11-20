import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../../admin/data/firestore/firestore_schema.dart';
import '../../admin/data/providers/backend_providers.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

class HelpAndSupportScreen extends ConsumerStatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  ConsumerState<HelpAndSupportScreen> createState() =>
      _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends ConsumerState<HelpAndSupportScreen> {
  int? _expandedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(firestoreProvider);

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

            // ================= FAQ REAL-TIME LIST =================
            Expanded(
              child: db == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: db.collection('support').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                'Failed to load support FAQs: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No FAQs available currently.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          itemCount: docs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>?;

                            final String question = Fs.stringOf(
                              data?['question'] ?? data?['subject'],
                            );
                            final String answer = Fs.stringOf(
                              data?['answer'] ?? data?['message'],
                            );

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
                                            question.isNotEmpty
                                                ? question
                                                : 'General Query',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
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
                                        answer.isNotEmpty
                                            ? answer
                                            : 'No response available.',
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
