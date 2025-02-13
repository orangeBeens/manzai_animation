import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';
import '../../utils/logger_config.dart';

class TimingControlSection extends StatelessWidget {
  static final _logger = LoggerConfig.getLogger('TimingControlSection');

  const TimingControlSection({Key? key}) : super(key: key);

  Future<void> _handleError(BuildContext context, String action, Object error,
      StackTrace? stackTrace) {
    _logger.severe('Error during $action', error, stackTrace);
    return Future.value(ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${action}の設定に失敗しました'))));
  }

  void _executeControlChange(
      BuildContext context, String action, Function() operation) {
    try {
      _logger.info('Changing $action');
      operation();
      _logger.info('Successfully changed $action');
    } catch (e, stackTrace) {
      _handleError(context, action, e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ScriptEditorViewModel>(context);
    _logger.info('Building TimingControlSection');

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
                      onChanged: (value) => _executeControlChange(
                        context,
                        '間の設定',
                        () => viewModel.setSelectedTiming(value),
                      ),
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
            onChanged: (value) {
              if (value != null) {
                _executeControlChange(
                  context,
                  'スピードの設定',
                  () => viewModel.setSelectedSpeed(value),
                );
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
            onChanged: (value) {
              if (value != null) {
                _executeControlChange(
                  context,
                  '声量の設定',
                  () => viewModel.setSelectedVolume(value),
                );
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
            onChanged: (value) {
              if (value != null) {
                _executeControlChange(
                  context,
                  '声の高さの設定',
                  () {
                    _logger.info('Setting pitch to: $value');
                    viewModel.setSelectedPitch(value);
                  },
                );
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
                      onChanged: (value) => _executeControlChange(
                        context,
                        '抑揚の設定',
                        () => viewModel.setSelectedIntonation(value),
                      ),
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
