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
                      min: 0.0,
                      max: 5.0,
                      divisions: 50,
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
            items: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
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
      ],
    );
  }
}
