import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';
import 'character_selector.dart';

class CharacterInputSection extends StatelessWidget {
 const CharacterInputSection({Key? key}) : super(key: key);

 @override
 Widget build(BuildContext context) {
   final viewModel = Provider.of<ScriptEditorViewModel>(context);

   return Column(
     children: [
       // キャラクター設定部分
       Row(
         children: [
           // ボケのキャラクター設定
           Expanded(
             child: Column(
               children: [
                 const Text('ボケ'),
                 CharacterSelect(
                   characterType: 'ボケ',
                   onImageSelected: viewModel.setBokeImage,
                 ),
                 const SizedBox(height: 8),
                 TextField(
                   onChanged: viewModel.setBokeName,
                   decoration: const InputDecoration(
                     labelText: 'ボケの名前',
                     border: OutlineInputBorder(),
                   ),
                 ),
               ],
             ),
           ),
           // ツッコミのキャラクター設定
           Expanded(
             child: Column(
               children: [
                 const Text('ツッコミ'),
                 CharacterSelect(
                   characterType: 'ツッコミ',
                   onImageSelected: viewModel.setTsukkomiImage,
                 ),
                 const SizedBox(height: 8),
                 TextField(
                   onChanged: viewModel.setTsukkomiName,
                   decoration: const InputDecoration(
                     labelText: 'ツッコミの名前',
                     border: OutlineInputBorder(),
                   ),
                 ),
               ],
             ),
           ),
         ],
       ),
       const SizedBox(height: 16),
       
       // コンビ名入力
       TextField(
         onChanged: viewModel.setCombiName,
         decoration: const InputDecoration(
           labelText: 'コンビ名',
           border: OutlineInputBorder(),
         ),
       ),
     ],
   );
 }
}