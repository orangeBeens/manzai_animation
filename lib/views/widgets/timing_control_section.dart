import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';

class TimingControlSection extends StatelessWidget {
  const TimingControlSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ScriptEditorViewModel>(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('間（秒）:', style: TextStyle(fontSize: 12)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: viewModel.selectedTiming,
                      min: -1.0,
                      max: 5.0,
                      divisions: 60,
                      label: viewModel.selectedTiming.toStringAsFixed(1),
                      onChanged: viewModel.setSelectedTiming,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${viewModel.selectedTiming.toStringAsFixed(1)}秒',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<double>(
            value: viewModel.selectedSpeed,
            decoration: const InputDecoration(
              labelText: 'スピード',
              border: OutlineInputBorder(),
            ),
            items: [2.0, 1.75, 1.5, 1.25, 1.0, 0.75, 0.5, 0.25].map((speed) {
              return DropdownMenuItem(
                value: speed,
                child: Text('${speed}x'),
              );
            }).toList(),
            onChanged: (double? value) {
              if (value != null) {
                viewModel.setSelectedSpeed(value);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<double>(
            value: viewModel.selectedVolume,
            decoration: const InputDecoration(
              labelText: '声量',
              border: OutlineInputBorder(),
            ),
            items:
                [10.0, 7.0, 5.0, 3.0, 2.0, 1.5, 1.0, 0.75, 0.5].map((volume) {
              return DropdownMenuItem(
                value: volume,
                child: Text('${volume}倍'),
              );
            }).toList(),
            onChanged: (double? value) {
              if (value != null) {
                viewModel.setSelectedVolume(value);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<double>(
            value: viewModel.selectedPitch,
            decoration: const InputDecoration(
              labelText: '声の高さ',
              border: OutlineInputBorder(),
            ),
            items: [0.15, 1.0, 0.5, 0.0, -0.5, -1.0, -1.5].map((pitch) {
              return DropdownMenuItem(
                value: pitch,
                child: Text('${pitch}倍'),
              );
            }).toList(),
            onChanged: (double? value) {
              if (value != null) {
                print("Selected pitch value: $value"); // デバッグプリントを追加
                viewModel.setSelectedPitch(value);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('抑揚:', style: TextStyle(fontSize: 12)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: viewModel.selectedIntonation,
                      min: 0.0,
                      max: 3.0,
                      divisions: 30,
                      label: viewModel.selectedIntonation.toStringAsFixed(1),
                      onChanged: viewModel.setSelectedIntonation,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${viewModel.selectedIntonation.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
