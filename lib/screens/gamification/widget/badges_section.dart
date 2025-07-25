import 'package:flutter/material.dart';
import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/data/gamification_data.dart' hide Badge;
import 'package:fitness_flutter/data/gamification_data.dart' as GamificationData show Badge;

class BadgesSection extends StatelessWidget {
  final List<GamificationData.Badge> earnedBadges;
  final List<GamificationData.Badge> allBadges;
  final VoidCallback onRefresh;

  const BadgesSection({
    Key? key,
    required this.earnedBadges,
    required this.allBadges,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final earnedIds = earnedBadges.map((b) => b.id).toSet();
    final unlockedBadges = allBadges.where((b) => earnedIds.contains(b.id)).toList();
    final lockedBadges = allBadges.where((b) => !earnedIds.contains(b.id)).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: ColorConstants.white,
            child: const TabBar(
              labelColor: ColorConstants.primaryColor,
              unselectedLabelColor: ColorConstants.grey,
              indicatorColor: ColorConstants.primaryColor,
              tabs: [
                Tab(text: 'Earned'),
                Tab(text: 'Available'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildEarnedBadges(unlockedBadges),
                _buildAvailableBadges(lockedBadges),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnedBadges(List<GamificationData.Badge> badges) {
    if (badges.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: ColorConstants.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No badges earned yet',
              style: TextStyle(
                fontSize: 18,
                color: ColorConstants.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete challenges and reach milestones to earn badges!',
              style: TextStyle(
                fontSize: 14,
                color: ColorConstants.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.85,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          return _buildBadgeCard(badges[index], isEarned: true);
        },
      ),
    );
  }

  Widget _buildAvailableBadges(List<GamificationData.Badge> badges) {
    if (badges.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: ColorConstants.primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'All badges earned!',
              style: TextStyle(
                fontSize: 18,
                color: ColorConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Congratulations! You\'ve earned all available badges.',
              style: TextStyle(
                fontSize: 14,
                color: ColorConstants.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.85,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          return _buildBadgeCard(badges[index], isEarned: false);
        },
      ),
    );
  }

  Widget _buildBadgeCard(GamificationData.Badge badge, {required bool isEarned}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEarned ? ColorConstants.white : ColorConstants.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isEarned ? ColorConstants.primaryColor.withOpacity(0.3) : ColorConstants.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: isEarned ? [
          BoxShadow(
            color: ColorConstants.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isEarned 
                  ? ColorConstants.primaryColor.withOpacity(0.2)
                  : ColorConstants.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.emoji_events,
              size: 30,
              color: isEarned ? ColorConstants.primaryColor : ColorConstants.grey,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isEarned ? ColorConstants.textBlack : ColorConstants.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 12,
              color: isEarned ? ColorConstants.grey : ColorConstants.grey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isEarned ? ColorConstants.primaryColor : ColorConstants.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isEarned ? '+${badge.pointsReward} pts' : '${badge.pointsReward} pts',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isEarned ? Colors.white : ColorConstants.grey,
              ),
            ),
          ),
          
          if (isEarned && badge.earnedDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Earned ${_formatDate(badge.earnedDate!)}',
              style: const TextStyle(
                fontSize: 10,
                color: ColorConstants.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
