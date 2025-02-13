import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './script_editor_view.dart';
import '../viewmodels/title_viewmodel.dart';

class TitleView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TitleViewModel()..loadScripts(),
      child: Scaffold(
        body: Consumer<TitleViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      '漫才動画生成アプリ',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildMainContent(context, viewModel),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ScriptEditorView()),
                      );
                    },
                    child: Text('新規作成'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, TitleViewModel viewModel) {
    if (viewModel.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(viewModel.error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.loadScripts,
              child: Text('再試行'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: viewModel.scripts.length,
      itemBuilder: (context, index) {
        final script = viewModel.scripts[index];
        return Card(
          child: ListTile(
            title: Text(script.title),
            subtitle: Text('コンビ名: ${script.combiName}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScriptEditorView(
                          scriptData: script.rawData,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
