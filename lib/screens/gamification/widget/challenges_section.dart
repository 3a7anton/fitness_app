import 'package:flutter/material.dart';
import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/data/gamification_data.dart';
import 'package:fitness_flutter/core/service/gamification_service.dart';

class ChallengesSection extends StatelessWidget {
  final List<Challenge> activeChallenges;
  final List<Challenge> completedChallenges;
  final VoidCallback onRefresh;

  const ChallengesSection({
    Key? key,
    required this.activeChallenges,
    required this.completedChallenges,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildActiveChallenges(),
                _buildCompletedChallenges(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChallenges() {
    if (activeChallenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.flag_outlined,
              size: 64,
              color: ColorConstants.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No active challenges',
              style: TextStyle(
                fontSize: 18,
                color: ColorConstants.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'New challenges will appear daily!',
              style: TextStyle(
                fontSize: 14,
                color: ColorConstants.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await GamificationService.addWeeklyChallenge();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Add Weekly Challenge',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: activeChallenges.length,
      itemBuilder: (context, index) {
        return _buildChallengeCard(activeChallenges[index], isActive: true);
      },
    );
  }

  Widget _buildCompletedChallenges() {
    if (completedChallenges.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: ColorConstants.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No completed challenges yet',
              style: TextStyle(
                fontSize: 18,
                color: ColorConstants.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete active challenges to see them here!',
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

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: completedChallenges.length,
      itemBuilder: (context, index) {
        return _buildChallengeCard(completedChallenges[index], isActive: false);
      },
    );
  }

  Widget _buildChallengeCard(Challenge challenge, {required bool isActive}) {
    final isExpired = challenge.isExpired && isActive;
    final timeRemaining = challenge.timeRemaining;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isActive && !isExpired
              ? ColorConstants.primaryColor.withOpacity(0.3)
              : ColorConstants.grey.withOpacity(0.3),
          width: 2,
        ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getChallengeTypeColor(challenge.type).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            challenge.type.displayName.split(' ')[0], // Just first word
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getChallengeTypeColor(challenge.type),
                            ),
                          ),
                        ),
                        if (challenge.isDaily) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Daily',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.textBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: ColorConstants.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive && !challenge.isCompleted
                          ? ColorConstants.primaryColor
                          : Colors.green,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '+${challenge.pointsReward}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isActive && !challenge.isCompleted && !isExpired) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatTimeRemaining(timeRemaining),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorConstants.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Progress section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isExpired ? ColorConstants.grey : ColorConstants.textBlack,
                    ),
                  ),
                  Text(
                    '${challenge.currentProgress}/${challenge.target}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isExpired ? ColorConstants.grey : ColorConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: challenge.progressPercentage,
                backgroundColor: ColorConstants.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExpired ? ColorConstants.grey : 
                  challenge.isCompleted ? Colors.green : ColorConstants.primaryColor,
                ),
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(challenge.progressPercentage * 100).toInt()}% complete',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? ColorConstants.grey : ColorConstants.grey,
                    ),
                  ),
                  if (challenge.isCompleted)
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else if (isExpired)
                    const Row(
                      children: [
                        Icon(
                          Icons.cancel,
                          color: ColorConstants.grey,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Expired',
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorConstants.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getChallengeTypeColor(ChallengeType type) {
    if (type == ChallengeType.steps) {
      return ColorConstants.primaryColor;
    } else if (type == ChallengeType.calories) {
      return Colors.orange;
    } else if (type == ChallengeType.distance) {
      return Colors.blue;
    } else if (type == ChallengeType.streak) {
      return Colors.purple;
    }
    
    // Default case
    return ColorConstants.primaryColor;
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.isNegative) return 'Expired';
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h left';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m left';
    } else {
      return '${duration.inMinutes}m left';
    }
  }
}
