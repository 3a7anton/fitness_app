import 'package:flutter/material.dart';
import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/core/service/gamification_service.dart';
import 'package:fitness_flutter/data/gamification_data.dart';
import 'package:fitness_flutter/screens/gamification/widget/league_display.dart';
import 'package:fitness_flutter/screens/gamification/widget/points_display.dart';
import 'package:fitness_flutter/screens/gamification/widget/badges_section.dart';
import 'package:fitness_flutter/screens/gamification/widget/challenges_section.dart';
import 'package:fitness_flutter/screens/gamification/widget/avatar_section.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({Key? key}) : super(key: key);

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  GamificationData? _gamificationData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadGamificationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGamificationData() async {
    await GamificationService.initialize();
    setState(() {
      _gamificationData = GamificationService.currentData;
      _isLoading = false;
    });
  }

  Future<void> _claimDailyBonus() async {
    if (GamificationService.canClaimDailyBonus()) {
      final bonusPoints = await GamificationService.claimDailyBonus();
      if (bonusPoints > 0) {
        setState(() {
          _gamificationData = GamificationService.currentData;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily bonus claimed! +$bonusPoints points'),
            backgroundColor: ColorConstants.primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: ColorConstants.white,
      appBar: AppBar(
        title: const Text(
          'Gamification',
          style: TextStyle(
            color: ColorConstants.textBlack,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorConstants.white,
        elevation: 0,
        actions: [
          if (GamificationService.canClaimDailyBonus())
            IconButton(
              onPressed: _claimDailyBonus,
              icon: const Icon(
                Icons.card_giftcard,
                color: ColorConstants.primaryColor,
              ),
              tooltip: 'Claim Daily Bonus',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorConstants.primaryColor,
          unselectedLabelColor: ColorConstants.grey,
          indicatorColor: ColorConstants.primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Badges'),
            Tab(text: 'Challenges'),
            Tab(text: 'Avatar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildBadgesTab(),
          _buildChallengesTab(),
          _buildAvatarTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points and Level Section
          PointsDisplay(
            totalPoints: _gamificationData!.totalPoints,
            level: _gamificationData!.level,
            onRefresh: _loadGamificationData,
          ),
          
          const SizedBox(height: 20),
          
          // League Section
          LeagueDisplay(
            currentLeague: _gamificationData!.currentLeague,
            totalPoints: _gamificationData!.totalPoints,
          ),
          
          const SizedBox(height: 20),
          
          // Quick Stats
          _buildQuickStats(),
          
          const SizedBox(height: 20),
          
          // Recent Badges
          _buildRecentBadges(),
          
          const SizedBox(height: 20),
          
          // Active Challenges Preview
          _buildActiveChallengesPreview(),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    return BadgesSection(
      earnedBadges: _gamificationData!.earnedBadges,
      allBadges: GamificationService.getAllBadges(),
      onRefresh: _loadGamificationData,
    );
  }

  Widget _buildChallengesTab() {
    return ChallengesSection(
      activeChallenges: _gamificationData!.activeChallenges,
      completedChallenges: _gamificationData!.completedChallenges,
      onRefresh: _loadGamificationData,
    );
  }

  Widget _buildAvatarTab() {
    return AvatarSection(
      selectedAvatar: _gamificationData!.selectedAvatar,
      allAvatars: GamificationService.getAllAvatars(),
      totalPoints: _gamificationData!.totalPoints,
      onRefresh: _loadGamificationData,
    );
  }

  Widget _buildQuickStats() {
    final stats = GamificationService.getGamificationStats();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.textBlack.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorConstants.textBlack,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Badges',
                  '${stats['earnedBadges']}/${stats['totalBadges']}',
                  Icons.emoji_events,
                  ColorConstants.primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Challenges',
                  '${stats['completedChallenges']}',
                  Icons.flag,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: ColorConstants.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBadges() {
    final earnedBadges = _gamificationData!.earnedBadges;
    final recentBadges = earnedBadges.take(3).toList();
    
    if (recentBadges.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.textBlack.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Badges',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorConstants.textBlack,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentBadges.length,
              itemBuilder: (context, index) {
                final badge = recentBadges[index];
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 15),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: ColorConstants.primaryColor,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        badge.name,
                        style: const TextStyle(
                          fontSize: 10,
                          color: ColorConstants.textBlack,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChallengesPreview() {
    final activeChallenges = _gamificationData!.activeChallenges.take(2).toList();
    
    if (activeChallenges.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.textBlack.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Challenges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textBlack,
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...activeChallenges.map((challenge) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.textBlack,
                        ),
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: challenge.progressPercentage,
                        backgroundColor: ColorConstants.grey.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(ColorConstants.primaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(challenge.progressPercentage * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorConstants.grey,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
