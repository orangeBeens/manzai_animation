import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/character_avatar.dart';
import '../utils/character_utils.dart'; // character_utils.dartをインポート

class CreationScreen extends StatefulWidget {
  const CreationScreen({super.key});

  @override
  _CreationScreenState createState() => _CreationScreenState();
}

class DialogueEntry {
  String character = 'ツッコミ';
  String expression = '真顔';
  String dialogue = '';
  String timingStyle = '普通';
  double seconds = 0.0;
  final TextEditingController dialogueController = TextEditingController();
}

class _CreationScreenState extends State<CreationScreen> {
  final List<DialogueEntry> dialogues = [DialogueEntry()];
  final TextEditingController combiNameController = TextEditingController();
  String _selectedBokeImage = '';
  String _selectedTsukkomiImage = '';
  String _selectedBokeCharacter = '';      // 追加
  String _selectedBokeExpression = '';     // 追加
  String _selectedTsukkomiCharacter = ''; // 追加
  String _selectedTsukkomiExpression = '';
  final TextEditingController bokeNameController = TextEditingController();
  final TextEditingController tsukkomiNameController = TextEditingController();
  late FlutterTts flutterTts;
  bool isPlaying = false;
  bool isInitialized = false;

  final List<String> _characterImages = [
    'taro.png',
    'boke2.png',
    'tsukkomi1.png',
    'tsukkomi2.png',
  ];

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    flutterTts = FlutterTts();
    try {
      await flutterTts.setLanguage('ja-JP');
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      
      // TTSの完了イベントを監視
      flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            isPlaying = false;
          });
        }
      });

      // エラーハンドリングを追加
      flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            isPlaying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('音声再生エラー: $msg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      setState(() {
        isInitialized = true;
      });
    } catch (e) {
      print('TTS初期化エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('音声機能の初期化に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playDialogue() async {
    if (!isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('音声機能の準備中です。しばらくお待ちください。'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (isPlaying) {
      await flutterTts.stop();
      setState(() {
        isPlaying = false;
      });
      return;
    }

    if (dialogues.isEmpty || dialogues.every((d) => d.dialogue.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('セリフを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isPlaying = true;
    });

    try {
      for (var i = 0; i < dialogues.length; i++) {
        if (!isPlaying) break;
        
        final entry = dialogues[i];
        
        // キャラクターに応じて声の特性を設定
        if (entry.character == 'ボケ') {
          await flutterTts.setPitch(1.5);
          await flutterTts.setSpeechRate(0.6);
        } else {
          await flutterTts.setPitch(0.8);
          await flutterTts.setSpeechRate(0.4);
        }

        // タイミングスタイルの適用
        double speedMultiplier = entry.timingStyle == '早め' ? 2.0 :
                               entry.timingStyle == '遅め' ? 0.5 : 1.0;
        await flutterTts.setSpeechRate(0.5 * speedMultiplier);

        // セリフの再生
        if (entry.dialogue.isNotEmpty) {
          await flutterTts.speak(entry.dialogue);
          
          // 次のセリフまでの待機時間
          if (entry.seconds > 0 && i < dialogues.length - 1) {
            await Future.delayed(Duration(milliseconds: (entry.seconds * 1000).round()));
          }
        }
      }
    } catch (e) {
      print('再生エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('音声再生中にエラーが発生しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    }
  }

  // キャラクター選択時の画像取得を修正
void _showImagePicker(BuildContext context, bool isBoke) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isBoke ? "ボケ" : "ツッコミ"}の画像を選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: CharacterAssets.expressions.keys.length,
            itemBuilder: (context, index) {
              final characterName = CharacterAssets.expressions.keys.elementAt(index);
              final imagePath = CharacterAssets.getCharacterImagePath(characterName, 'normal');
              return ListTile(
                leading: Image.asset(
                  imagePath,
                  width: 50,
                  height: 50,
                ),
                title: Text(characterName),
                onTap: () {
                  setState(() {
                    if (isBoke) {
                      _selectedBokeCharacter = characterName;
                      _selectedBokeExpression = 'normal';
                      _selectedBokeImage = imagePath.split('/').last; // assets/images/character/を除いたファイル名を保存
                    } else {
                      _selectedTsukkomiCharacter = characterName;
                      _selectedTsukkomiExpression = 'normal';
                      _selectedTsukkomiImage = imagePath.split('/').last;
                    }
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('キャラクター設定'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // キャラクター設定部分
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'ボケ',
                            style: TextStyle(color: Colors.blue),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: bokeNameController,
                            decoration: InputDecoration(
                              hintText: 'ボケの名前',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                image: _selectedBokeImage.isNotEmpty
                                    ? DecorationImage(
                                        image: AssetImage('assets/images/character/$_selectedBokeImage'),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showImagePicker(context, true),
                                  child: _selectedBokeImage.isEmpty
                                      ? const Center(child: Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey))
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButton<String>(
                            value: '真顔',
                            isExpanded: true,
                            underline: Container(),
                            items: const [
                              DropdownMenuItem(value: '真顔', child: Text('真顔')),
                            ],
                            onChanged: (String? value) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'ツッコミ',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: tsukkomiNameController,
                        decoration: InputDecoration(
                          hintText: 'ツッコミの名前',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                image: _selectedTsukkomiImage.isNotEmpty
                                    ? DecorationImage(
                                        image: AssetImage('assets/images/character/$_selectedTsukkomiImage'),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showImagePicker(context, false),
                                  child: _selectedTsukkomiImage.isEmpty
                                      ? const Center(child: Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey))
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButton<String>(
                            value: '真顔',
                            isExpanded: true,
                            underline: Container(),
                            items: const [
                              DropdownMenuItem(value: '真顔', child: Text('真顔')),
                            ],
                            onChanged: (String? value) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // コンビ名入力
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('コンビ名'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: combiNameController,
                    decoration: InputDecoration(
                      hintText: 'コンビ名を入力してください',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 再生ボタン
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _playDialogue,
                      icon: Icon(
                        isPlaying ? Icons.stop : Icons.play_circle_outline,
                        color: Colors.white
                      ),
                      label: Text(isPlaying ? '停止' : '再生'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPlaying ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 台本セクション
              const Text('台本', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              
              // 台本アイテム
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dialogues.isEmpty ? 1 : dialogues.length,
                itemBuilder: (context, index) {
                  if (dialogues.isEmpty) {
                    return _buildDialogueItem(DialogueEntry());
                  }
                  return _buildDialogueItem(dialogues[index]);
                },
              ),

              // セリフを追加ボタン
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    dialogues.add(DialogueEntry());
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('+ セリフを追加'),
              ),

              const SizedBox(height: 16),

              // 動画生成ボタン
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.movie),
                    SizedBox(width: 8),
                    Text('動画を生成する'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogueItem(DialogueEntry entry) {
    // Create a TextEditingController that's connected to the entry
    final textController = TextEditingController(text: entry.dialogue);
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<String>(
                      value: entry.character,
                      isExpanded: true,
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(value: 'ツッコミ', child: Text('ツッコミ')),
                        DropdownMenuItem(value: 'ボケ', child: Text('ボケ')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            entry.character = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<String>(
                      value: entry.expression,
                      isExpanded: true,
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(value: '真顔', child: Text('真顔')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            entry.expression = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      dialogues.remove(entry);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'どうも～、新年の時間です。',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  entry.dialogue = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // タイミングスタイルのドロップダウン
                SizedBox(
                  width: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<String>(
                      value: entry.timingStyle,
                      isExpanded: true,
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(value: '早め', child: Text('早め')),
                        DropdownMenuItem(value: '普通', child: Text('普通')),
                        DropdownMenuItem(value: '遅め', child: Text('遅め')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            entry.timingStyle = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 秒数入力フィールド
                SizedBox(
                  width: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                      ],
                      controller: TextEditingController(text: entry.seconds.toString()),
                      onChanged: (value) {
                        final newValue = double.tryParse(value) ?? 0.0;
                        setState(() {
                          entry.seconds = newValue.clamp(0.0, 30.0);
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('秒'),
                const Spacer(),
              ],  // Row children
            ),   // Row
          ],    // Column children
        ),      // Padding
      ), 
    );    // Card
  }

  Widget _buildExpressionDropdown(String characterName, String currentExpression, Function(String?) onChanged) {
    final expressions = CharacterAssets.getAvailableExpressions(characterName);
      
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButton<String>(
          value: currentExpression,
          isExpanded: true,
          underline: Container(),
          items: expressions.map((expression) =>
            DropdownMenuItem(
              value: expression,
              child: Text(expression),
            ),
          ).toList(),
          onChanged: onChanged,
        ),
      );
    }
    

}