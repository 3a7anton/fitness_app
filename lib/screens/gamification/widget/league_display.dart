import 'package:flutter/material.dart';
import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/data/gamification_data.dart';

class LeagueDisplay extends StatelessWidget {
  final League currentLeague;
  final int totalPoints;

  const LeagueDisplay({
    Key? key,
    required this.currentLeague,
    required this.totalPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nextLeague = _getNextLeague();
    final progress = currentLeague.getProgressToNextLeague(totalPoints);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getLeagueColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: _getLeagueColors().first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current League',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        currentLeague.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        currentLeague.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Points',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$totalPoints',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (nextLeague != null) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress to ${nextLeague.name}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
                const SizedBox(height: 5),
                Text(
                  '${currentLeague.maxPoints.toInt() - totalPoints} points to next league',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  League? _getNextLeague() {
    final leagues = League.values;
    final currentIndex = leagues.indexOf(currentLeague);
    
    if (currentIndex < leagues.length - 1) {
      return leagues[currentIndex + 1];
    }
    
    return null; // Already at highest league
  }

  List<Color> _getLeagueColors() {
    if (currentLeague == League.bronze) {
      return [const Color(0xFFCD7F32), const Color(0xFFA0522D)];
    } else if (currentLeague == League.silver) {
      return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
    } else if (currentLeague == League.gold) {
      return [const Color(0xFFFFD700), const Color(0xFFDAA520)];
    } else if (currentLeague == League.diamond) {
      return [const Color(0xFF00BFFF), const Color(0xFF1E90FF)];
    }
    
    // Default case (bronze)
    return [const Color(0xFFCD7F32), const Color(0xFFA0522D)];
  }
}
