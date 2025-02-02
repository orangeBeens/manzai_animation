import 'package:flutter/material.dart';

class CharacterSelect extends StatefulWidget {
  final String characterType;
  final Function(String) onImageSelected;
  final String? initialImage;

  const CharacterSelect({
    required this.characterType,
    required this.onImageSelected,
    this.initialImage,
    super.key,
  });

  @override
  State<CharacterSelect> createState() => _CharacterSelectState();
}

class _CharacterSelectState extends State<CharacterSelect> {
  String? selectedImage;
  // アセットとして利用可能な画像のリスト
  final List<String> characterImages = [
    'assets/images/character/kuruma.png',
    'assets/images/character/tichi.png',
    'assets/images/character/kemuri.png',
    'assets/images/character/takashi.png',
    'assets/images/character/homeless.png',
    'assets/images/character/manzaishi.png',
    'assets/images/character/kojo.png',
    'assets/images/character/loveo.png',
    'assets/images/character/machida.png',
    'assets/images/character/machida_gachi.png',
    'assets/images/character/sasaki.png',
    'assets/images/character/mojiko.png',
    'assets/images/character/udeita.png',
    'assets/images/character/mathnee.png',
    'assets/images/character/Ronaldo.png',
    'assets/images/character/mike.png',
    'assets/images/character/ojii.png',
    'assets/images/character/musu.png',
    'assets/images/character/punch_hamasaki.png',
    'assets/images/character/sogekingu.png',
    'assets/images/character/nami.png',
    'assets/images/character/suits.png',
    'assets/images/character/okappa.png',
    'assets/images/character/chiyoko.png',
    'assets/images/character/genzou.png',
    'assets/images/character/yasuke.png',
  ];
  
  @override
  void initState() {
    super.initState();
    // 初期値が設定されている場合は反映
    if (widget.initialImage != null) {
      selectedImage = widget.initialImage;
    }
  }

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