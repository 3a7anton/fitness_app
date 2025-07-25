import 'package:flutter/material.dart';
import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/core/service/gamification_service.dart';

class PointsDisplay extends StatelessWidget {
  final int totalPoints;
  final int level;
  final VoidCallback onRefresh;

  const PointsDisplay({
    Key? key,
    required this.totalPoints,
    required this.level,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pointsForNextLevel = GamificationService.getPointsForNextLevel(level);
    final pointsToNext = pointsForNextLevel - totalPoints;
    final currentLevelPoints = level > 1 ? GamificationService.getPointsForNextLevel(level - 1) : 0;
    final levelProgress = totalPoints >= pointsForNextLevel 
        ? 1.0 
        : (totalPoints - currentLevelPoints) / (pointsForNextLevel - currentLevelPoints);

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Points',
                    style: TextStyle(
                      fontSize: 16,
                      color: ColorConstants.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        color: ColorConstants.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$totalPoints',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.textBlack,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level $level Progress',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.textBlack,
                    ),
                  ),
                  Text(
                    '${(levelProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: levelProgress.clamp(0.0, 1.0),
                backgroundColor: ColorConstants.grey.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(ColorConstants.primaryColor),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              if (pointsToNext > 0)
                Text(
                  '$pointsToNext points to Level ${level + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorConstants.grey,
                  ),
                )
              else
                const Text(
                  'Maximum level reached!',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Points earning info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to earn points:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.textBlack,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions_walk, size: 16, color: ColorConstants.primaryColor),
                    SizedBox(width: 8),
                    Text('1 point per 10,000 steps', style: TextStyle(fontSize: 12, color: ColorConstants.grey)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 16, color: ColorConstants.primaryColor),
                    SizedBox(width: 8),
                    Text('0.1 points per calorie burned', style: TextStyle(fontSize: 12, color: ColorConstants.grey)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.emoji_events, size: 16, color: ColorConstants.primaryColor),
                    SizedBox(width: 8),
                    Text('Bonus points for badges & challenges', style: TextStyle(fontSize: 12, color: ColorConstants.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
