// lib/widgets/character_avatar.dart
import 'package:flutter/material.dart';

class CharacterAvatar extends StatelessWidget {
  final String name;
  final String imagePath;
  final String role;

  const CharacterAvatar({
    super.key,
    required this.name,
    required this.imagePath,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage(imagePath),
        ),
        const SizedBox(height: 8),
        Text(name),
        Text(
          role,
          style: TextStyle(
            color: role == 'ボケ' ? Colors.blue : Colors.red,
          ),
        ),
      ],
    );
  }
}