import 'package:flutter/material.dart';
import 'package:fitness_flutter/core/const/color_constants.dart';
import 'package:fitness_flutter/data/gamification_data.dart';
import 'package:fitness_flutter/core/service/gamification_service.dart';

class AvatarSection extends StatefulWidget {
  final Avatar selectedAvatar;
  final List<Avatar> allAvatars;
  final int totalPoints;
  final VoidCallback onRefresh;

  const AvatarSection({
    Key? key,
    required this.selectedAvatar,
    required this.allAvatars,
    required this.totalPoints,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<AvatarSection> createState() => _AvatarSectionState();
}

class _AvatarSectionState extends State<AvatarSection> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Avatar Display
          _buildCurrentAvatarDisplay(),
          
          const SizedBox(height: 30),
          
          // Avatar Skins Section
          _buildAvatarSkinsSection(),
          
          const SizedBox(height: 30),
          
          // All Avatars Grid
          _buildAvatarsGrid(),
        ],
      ),
    );
  }

  Widget _buildCurrentAvatarDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstants.primaryColor.withOpacity(0.8),
            ColorConstants.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Avatar Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Avatar',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.selectedAvatar.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.selectedAvatar.skin.name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Points Display
          Column(
            children: [
              const Icon(
                Icons.stars,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 5),
              Text(
                '${widget.totalPoints}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'points',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSkinsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avatar Skins',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorConstants.textBlack,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AvatarSkin.values.length,
            itemBuilder: (context, index) {
              final skin = AvatarSkin.values[index];
              final isSelected = widget.selectedAvatar.skin == skin;
              final canAfford = widget.totalPoints >= skin.unlockCost;
              final isUnlocked = skin == AvatarSkin.classic || canAfford;
              
              return GestureDetector(
                onTap: isUnlocked ? () => _selectSkin(skin) : null,
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? ColorConstants.primaryColor 
                        : isUnlocked 
                            ? ColorConstants.white 
                            : ColorConstants.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected 
                          ? ColorConstants.primaryColor 
                          : ColorConstants.grey.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: ColorConstants.primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        size: 30,
                        color: isSelected 
                            ? Colors.white 
                            : isUnlocked 
                                ? ColorConstants.primaryColor 
                                : ColorConstants.grey,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        skin.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected 
                              ? Colors.white 
                              : isUnlocked 
                                  ? ColorConstants.textBlack 
                                  : ColorConstants.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (skin.unlockCost > 0 && !isUnlocked)
                        Text(
                          '${skin.unlockCost}pts',
                          style: const TextStyle(
                            fontSize: 8,
                            color: ColorConstants.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Avatars',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorConstants.textBlack,
          ),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemCount: widget.allAvatars.length,
          itemBuilder: (context, index) {
            return _buildAvatarCard(widget.allAvatars[index]);
          },
        ),
      ],
    );
  }

  Widget _buildAvatarCard(Avatar avatar) {
    final isSelected = widget.selectedAvatar.id == avatar.id;
    final canAfford = widget.totalPoints >= avatar.unlockCost;
    final isUnlocked = avatar.isUnlocked || canAfford;
    
    return GestureDetector(
      onTap: () => _handleAvatarTap(avatar),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? ColorConstants.primaryColor.withOpacity(0.1)
              : ColorConstants.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected 
                ? ColorConstants.primaryColor 
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected 
                    ? ColorConstants.primaryColor 
                    : isUnlocked 
                        ? ColorConstants.primaryColor.withOpacity(0.2)
                        : ColorConstants.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.person,
                size: 30,
                color: isSelected 
                    ? Colors.white 
                    : isUnlocked 
                        ? ColorConstants.primaryColor 
                        : ColorConstants.grey,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              avatar.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? ColorConstants.textBlack : ColorConstants.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            if (avatar.unlockCost > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? (isSelected ? ColorConstants.primaryColor : Colors.green)
                      : ColorConstants.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isUnlocked 
                      ? (isSelected ? 'Selected' : 'Unlocked')
                      : '${avatar.unlockCost} pts',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : ColorConstants.grey,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? ColorConstants.primaryColor : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSelected ? 'Selected' : 'Free',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectSkin(AvatarSkin skin) async {
    final updatedAvatar = widget.selectedAvatar.copyWith(skin: skin);
    await GamificationService.selectAvatar(updatedAvatar);
    widget.onRefresh();
  }

  void _handleAvatarTap(Avatar avatar) async {
    if (avatar.isUnlocked || widget.totalPoints >= avatar.unlockCost) {
      if (!avatar.isUnlocked && avatar.unlockCost > 0) {
        // Show unlock confirmation dialog
        final shouldUnlock = await _showUnlockDialog(avatar);
        if (shouldUnlock) {
          final success = await GamificationService.unlockAvatar(avatar.id);
          if (success) {
            await GamificationService.selectAvatar(avatar);
            widget.onRefresh();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${avatar.name} unlocked and selected!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // Just select the avatar
        await GamificationService.selectAvatar(avatar);
        widget.onRefresh();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${avatar.name} selected!'),
            backgroundColor: ColorConstants.primaryColor,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough points to unlock ${avatar.name}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showUnlockDialog(Avatar avatar) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlock ${avatar.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This will cost ${avatar.unlockCost} points.'),
            const SizedBox(height: 10),
            Text('You have ${widget.totalPoints} points.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
            ),
            child: const Text(
              'Unlock',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}
