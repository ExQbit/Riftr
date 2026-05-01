import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/market/seller_profile.dart';
import '../theme/app_theme.dart';
import '../theme/app_components.dart';
import '../services/firestore_service.dart';
import '../widgets/drag_to_dismiss.dart';
import '../widgets/gold_header.dart';
import '../widgets/market/seller_imprint_card.dart';
import '../widgets/riftr_drag_handle.dart';

class SellerReviewsScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const SellerReviewsScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  // Track which reviews have their full comment expanded.
  final Set<String> _expandedReviews = {};

  @override
  Widget build(BuildContext context) {
    final sellerId = widget.sellerId;
    final sellerName = widget.sellerName;
    // Use two streams: playerProfiles (public mirror — readable cross-user)
    // for header stats + DSA Art. 30 imprint info; orders for review list.
    // sellerProfile path is owner-only; the public mirror is kept in sync
    // by `syncPlayerProfile` Cloud Function on every sellerProfile write.
    final profileStream = FirestoreService.instance
        .globalCollection('playerProfiles')
        .doc(sellerId)
        .snapshots();

    final reviewsStream = FirestoreService.instance
        .globalCollection('users')
        .doc(sellerId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DragToDismiss(
        onDismissed: () => Navigator.pop(context),
        backgroundColor: AppColors.background,
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: profileStream,
            builder: (context, profileSnap) {
              // Read aggregate rating from sellerProfile (updated by submitReview Cloud Function)
              final profileData = profileSnap.data?.data() as Map<String, dynamic>?;
              final profileRating = (profileData?['rating'] as num?)?.toDouble() ?? 0.0;
              final profileCount = (profileData?['reviewCount'] as num?)?.toInt() ?? 0;

              return StreamBuilder<QuerySnapshot>(
                stream: reviewsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint('SellerReviewsScreen query error: ${snapshot.error}');
                  }

                  final isLoading = snapshot.connectionState == ConnectionState.waiting;
                  final docs = snapshot.data?.docs ?? [];

                  // Use sellerProfile as source of truth for header;
                  // fall back to computing from docs if profile not available
                  final double avg;
                  final int count;
                  if (profileCount > 0) {
                    avg = profileRating;
                    count = profileCount;
                  } else if (docs.isNotEmpty) {
                    count = docs.length;
                    avg = docs.fold<int>(0, (sum, d) =>
                        sum + ((d.data() as Map<String, dynamic>)['rating'] as int? ?? 0)) / count;
                  } else {
                    avg = 0.0;
                    count = 0;
                  }

                  return Column(
                    children: [
                      // Drag handle (fullscreen style, matches Cart/Wallet/etc.)
                      const SizedBox(height: AppSpacing.md),
                      const RiftrDragHandle(style: RiftrDragHandleStyle.fullscreen),
                      const SizedBox(height: AppSpacing.md),

                      // Gold-ornament header
                      const GoldOrnamentHeader(title: 'REVIEWS'),

                      // Seller name + rating summary (hero area)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.base,
                        ),
                        child: Column(
                          children: [
                            Text(
                              sellerName,
                              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (i) => Icon(
                                i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 28,
                                color: AppColors.amber400,
                              )),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // titleLarge (22sp) for hero-stat prominence
                            Text(
                              '${avg.toStringAsFixed(1)} out of 5',
                              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '$count ${count == 1 ? 'review' : 'reviews'}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),

                      // DSA Art. 30 / § 5 DDG Pflicht-Imprint — nur fuer
                      // gewerbliche Verkaeufer sichtbar; rendert SizedBox.
                      // shrink bei privaten Verkaeufern. Daten kommen aus
                      // playerProfiles-Mirror (cross-user-readable).
                      if (profileData?['isCommercialSeller'] == true)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
                          ),
                          child: SellerImprintCard(
                            isCommercial: true,
                            legalEntityName:
                                profileData?['sellerLegalEntityName']
                                    as String?,
                            vatId: profileData?['sellerVatId'] as String?,
                            address: profileData?['sellerAddress']
                                    is Map<String, dynamic>
                                ? SellerAddress.fromMap(
                                    profileData!['sellerAddress']
                                        as Map<String, dynamic>)
                                : null,
                            email: profileData?['sellerEmail'] as String?,
                          ),
                        ),

                      // Reviews list
                      if (isLoading)
                        Expanded(
                          child: Center(child: CircularProgressIndicator(color: AppColors.amber500)),
                        )
                      else if (docs.isEmpty)
                        const Expanded(
                          child: RiftrEmptyState(
                            icon: Icons.star_border,
                            title: 'No Reviews Yet',
                            subtitle: 'Reviews from buyers will appear here',
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.base),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final rating = data['rating'] as int? ?? 0;
                              final comment = data['comment'] as String?;
                              final buyerName = data['reviewerName'] as String? ?? 'Buyer';
                              final timestamp = _parseTimestamp(data['createdAt']);
                              final tags = (data['tags'] as List<dynamic>?)?.cast<String>() ?? [];
                              final isExpanded = _expandedReviews.contains(doc.id);

                              return RiftrCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                radius: AppRadius.listItem,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Stars
                                        ...List.generate(5, (i) => Icon(
                                          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                          size: 14,
                                          color: AppColors.amber400,
                                        )),
                                        const Spacer(),
                                        if (timestamp != null)
                                          Text(
                                            _timeAgo(timestamp),
                                            style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      buyerName,
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (tags.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Wrap(
                                        spacing: AppSpacing.xs,
                                        runSpacing: AppSpacing.xs,
                                        children: tags.map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.amber500,
                                            borderRadius: BorderRadius.circular(AppRadius.pill),
                                          ),
                                          child: Text(tag, style: AppTextStyles.tiny.copyWith(color: AppColors.background)),
                                        )).toList(),
                                      ),
                                    ],
                                    if (comment != null && comment.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      // Collapsed: max 5 lines with ellipsis.
                                      // Expanded: full text. Toggle via "Show more/less".
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final textStyle = AppTextStyles.caption.copyWith(
                                              color: AppColors.textPrimary, height: 1.4);
                                          // Measure rendered height at unlimited lines vs. 5 lines
                                          // to decide if the "Show more" toggle is needed at all.
                                          final tp = TextPainter(
                                            text: TextSpan(text: comment, style: textStyle),
                                            maxLines: 5,
                                            textDirection: TextDirection.ltr,
                                          )..layout(maxWidth: constraints.maxWidth);
                                          final overflows = tp.didExceedMaxLines;
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment,
                                                style: textStyle,
                                                maxLines: isExpanded ? null : 5,
                                                overflow: isExpanded
                                                    ? TextOverflow.visible
                                                    : TextOverflow.ellipsis,
                                              ),
                                              if (overflows) ...[
                                                const SizedBox(height: 4),
                                                GestureDetector(
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () => setState(() {
                                                    if (isExpanded) {
                                                      _expandedReviews.remove(doc.id);
                                                    } else {
                                                      _expandedReviews.add(doc.id);
                                                    }
                                                  }),
                                                  child: Text(
                                                    isExpanded ? 'Show less' : 'Show more',
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: AppColors.amber400,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }
}
