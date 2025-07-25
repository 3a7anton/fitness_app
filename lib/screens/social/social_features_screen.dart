import 'package:flutter/material.dart';
import 'package:fitness_flutter/core/service/social_service.dart';
import 'package:fitness_flutter/core/service/fitness_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialFeaturesScreen extends StatefulWidget {
  const SocialFeaturesScreen({Key? key}) : super(key: key);

  @override
  State<SocialFeaturesScreen> createState() => _SocialFeaturesScreenState();
}

class _SocialFeaturesScreenState extends State<SocialFeaturesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _myGroups = [];
  List<Map<String, dynamic>> _activeChallenges = [];
  List<Map<String, dynamic>> _leaderboard = [];
  List<Map<String, dynamic>> _communityFeed = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadSocialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSocialData() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      await SocialService.initialize();

      final groups = await SocialService.getUserStepGroups();
      final challenges = await SocialService.getActiveChallenges();
      final leaderboard = <Map<String, dynamic>>[]; // Placeholder - no global leaderboard method
      final feed = await SocialService.getCommunityFeed(limit: 20);

      setState(() {
        _myGroups = groups;
        _activeChallenges = challenges;
        _leaderboard = leaderboard;
        _communityFeed = feed;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading social data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Social Fitness'),
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.group), text: 'Groups'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Challenges'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
            Tab(icon: Icon(Icons.feed), text: 'Community'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSocialData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupsTab(),
                _buildChallengesTab(),
                _buildLeaderboardTab(),
                _buildCommunityTab(),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateDialog(),
      backgroundColor: Colors.purple.shade400,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Create', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildGroupsTab() {
    return RefreshIndicator(
      onRefresh: _loadSocialData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMyGroupsSection(),
            const SizedBox(height: 20),
            _buildDiscoverGroupsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.group, color: Colors.purple),
            const SizedBox(width: 8),
            const Text(
              'My Step Groups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showCreateGroupDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_myGroups.isEmpty)
          _buildEmptyState(
            'No groups yet',
            'Join or create a step group to compete with friends!',
            Icons.group_add,
          )
        else
          Column(
            children: _myGroups.map((group) => _buildGroupCard(group)).toList(),
          ),
      ],
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Text(
                  group['name'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${group['memberCount']} members',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _viewGroupDetails(group),
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildGroupStat('Goal', '${group['dailyStepGoal']} steps'),
              const SizedBox(width: 16),
              _buildGroupStat('Streak', '${group['groupStreak']} days'),
              const SizedBox(width: 16),
              _buildGroupStat('Total', '${group['totalSteps']} steps'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discover Groups',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.search, color: Colors.blue.shade600, size: 32),
              const SizedBox(height: 8),
              Text(
                'Find Groups',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Search for public step groups in your area',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _showSearchGroupsDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Search Groups'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChallengesTab() {
    return RefreshIndicator(
      onRefresh: _loadSocialData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActiveChallengesSection(),
            const SizedBox(height: 20),
            _buildChallengeHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChallengesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'Active Challenges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showChallengeFriendsDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Challenge'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_activeChallenges.isEmpty)
          _buildEmptyState(
            'No active challenges',
            'Challenge your friends to step competitions!',
            Icons.sports_score,
          )
        else
          Column(
            children: _activeChallenges.map((challenge) => _buildChallengeCard(challenge)).toList(),
          ),
      ],
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final endDate = challenge['endDate'] as DateTime;
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    final isWinning = challenge['currentUserSteps'] > challenge['challengedUserSteps'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinning ? Colors.green.shade300 : Colors.orange.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isWinning ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isWinning ? Icons.trending_up : Icons.timer,
                  color: isWinning ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs ${challenge['challengedUserName']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$daysLeft days left • ${challenge['stepGoal']} steps goal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isWinning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'WINNING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildChallengeProgress(
                  'You',
                  challenge['currentUserSteps'],
                  challenge['stepGoal'],
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChallengeProgress(
                  challenge['challengedUserName'],
                  challenge['challengedUserSteps'],
                  challenge['stepGoal'],
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendEncouragement(challenge['challengeId']),
                  icon: const Icon(Icons.favorite, size: 16),
                  label: const Text('Encourage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade100,
                    foregroundColor: Colors.pink.shade700,
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _viewChallengeDetails(challenge),
                child: const Text('Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade700,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeProgress(String name, int steps, int goal, Color color) {
    final progress = (steps / goal).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '$steps / $goal',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildChallengeHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Challenge History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.history, color: Colors.grey.shade600, size: 32),
              const SizedBox(height: 8),
              Text(
                'View Past Challenges',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'See your wins, losses, and achievements',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _viewChallengeHistory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View History'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: _loadSocialData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeaderboardHeader(),
            const SizedBox(height: 20),
            _buildLeaderboardList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade300, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.leaderboard,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Global Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'See how you rank among all users',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList() {
    if (_leaderboard.isEmpty) {
      return _buildEmptyState(
        'No leaderboard data',
        'Start tracking steps to see rankings!',
        Icons.leaderboard,
      );
    }

    return Column(
      children: _leaderboard.asMap().entries.map((entry) {
        final index = entry.key;
        final user = entry.value;
        final isCurrentUser = user['userId'] == _currentUserId;
        
        return _buildLeaderboardItem(index + 1, user, isCurrentUser);
      }).toList(),
    );
  }

  Widget _buildLeaderboardItem(int rank, Map<String, dynamic> user, bool isCurrentUser) {
    final rankColors = {
      1: Colors.amber,
      2: Colors.grey,
      3: Colors.orange.shade700,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? Colors.blue.shade300 : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColors[rank] ?? Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: isCurrentUser ? Colors.blue.shade200 : Colors.grey.shade200,
            child: Text(
              user['displayName'][0].toUpperCase(),
              style: TextStyle(
                color: isCurrentUser ? Colors.blue.shade700 : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user['displayName'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser ? Colors.blue.shade700 : Colors.black87,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${user['totalSteps']} steps this week',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user['weeklySteps']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'steps',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return RefreshIndicator(
      onRefresh: _loadSocialData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShareProgressSection(),
            const SizedBox(height: 20),
            _buildCommunityFeedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildShareProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.share, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Share Your Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Motivate others by sharing your fitness achievements!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _shareProgress(),
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('Share Achievement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Feed',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_communityFeed.isEmpty)
          _buildEmptyState(
            'No posts yet',
            'Be the first to share your fitness journey!',
            Icons.article,
          )
        else
          Column(
            children: _communityFeed.map((post) => _buildFeedPost(post)).toList(),
          ),
      ],
    );
  }

  Widget _buildFeedPost(Map<String, dynamic> post) {
    final timestamp = post['timestamp'] as DateTime;
    final timeAgo = _getTimeAgo(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.purple.shade200,
                child: Text(
                  (post['user']['displayName'] ?? 'A')[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['user']['displayName'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPostTypeIcon(post['achievement']?['type'] ?? 'general'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post['content'],
            style: const TextStyle(fontSize: 14),
          ),
          if (post['achievement']?['stepCount'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_walk, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '${post['achievement']['stepCount']} steps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _likePost(post['id']),
                icon: Icon(
                  false ? Icons.favorite : Icons.favorite_border, // No isLiked field available
                  size: 16,
                  color: false ? Colors.red : Colors.grey,
                ),
                label: Text('${post['likes'] ?? 0}'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => _showComments(post),
                icon: const Icon(Icons.comment_outlined, size: 16),
                label: Text('${post['comments'] ?? 0}'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostTypeIcon(String type) {
    final icons = {
      'achievement': Icons.emoji_events,
      'milestone': Icons.flag,
      'workout': Icons.fitness_center,
      'general': Icons.message,
    };

    final colors = {
      'achievement': Colors.orange,
      'milestone': Colors.green,
      'workout': Colors.blue,
      'general': Colors.purple,
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors[type]?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icons[type] ?? Icons.message,
        size: 16,
        color: colors[type] ?? Colors.grey,
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Dialog and action methods
  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Create Step Group'),
              onTap: () {
                Navigator.pop(context);
                _showCreateGroupDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_score),
              title: const Text('Challenge Friend'),
              onTap: () {
                Navigator.pop(context);
                _showChallengeFriendsDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Progress'),
              onTap: () {
                Navigator.pop(context);
                _shareProgress();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    // Implementation for creating a group
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Group feature coming soon!')),
    );
  }

  void _showChallengeFriendsDialog() {
    // Implementation for challenging friends
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Challenge Friends feature coming soon!')),
    );
  }

  void _showSearchGroupsDialog() {
    // Implementation for searching groups
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search Groups feature coming soon!')),
    );
  }

  void _viewGroupDetails(Map<String, dynamic> group) {
    // Implementation for viewing group details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${group['name']} details')),
    );
  }

  void _sendEncouragement(String challengeId) async {
    try {
      await SocialService.sendEncouragement(_currentUserId!, 'Keep it up! 💪');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encouragement sent! 💪')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send encouragement')),
      );
    }
  }

  void _viewChallengeDetails(Map<String, dynamic> challenge) {
    // Implementation for viewing challenge details
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Challenge details coming soon!')),
    );
  }

  void _viewChallengeHistory() {
    // Implementation for viewing challenge history
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Challenge history coming soon!')),
    );
  }

  void _shareProgress() async {
    try {
      final todaysSteps = await FitnessService.getTodaySteps();
      await SocialService.postToCommunityFeed(
        content: 'Just completed $todaysSteps steps today! 🚶‍♀️💪',
        achievement: {
          'type': 'achievement',
          'stepCount': todaysSteps,
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress shared to community! 🎉')),
      );
      
      _loadSocialData(); // Refresh feed
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share progress')),
      );
    }
  }

  void _likePost(String postId) {
    // Implementation for liking posts
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❤️ Liked!')),
    );
  }

  void _showComments(Map<String, dynamic> post) {
    // Implementation for showing comments
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comments feature coming soon!')),
    );
  }
}
