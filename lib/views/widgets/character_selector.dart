import 'package:flutter/material.dart';

class CharacterSelect extends StatefulWidget {
  final String characterType;
  final Function(String) onImageSelected;

  const CharacterSelect({
    required this.characterType,
    required this.onImageSelected,
    super.key,
  });

  @override
  State<CharacterSelect> createState() => _CharacterSelectState();
}

class _CharacterSelectState extends State<CharacterSelect> {
  String? selectedImage;
  // アセットとして利用可能な画像のリスト
  final List<String> characterImages = [
    'assets/images/character/kojo.png',
    'assets/images/character/loveo.png',
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImagePicker(context),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image(
                  image: AssetImage(selectedImage!),
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.person, size: 50),
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'キャラクター画像を選択',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: characterImages.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedImage = characterImages[index];
                        widget.onImageSelected(selectedImage!);
                      });
                      Navigator.pop(context);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: AssetImage(characterImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
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