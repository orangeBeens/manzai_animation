import 'package:flutter/material.dart';
import './script_editor_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TitleView extends StatefulWidget {
  @override
  _TitleViewState createState() => _TitleViewState();
}

class _TitleViewState extends State<TitleView> {
  List<Map<String, dynamic>> scripts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/scripts/get_manzai_scripts'),
        headers: {'Accept': 'application/json; charset=utf-8'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          scripts = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      }
      print('response: ${response.body}');
    } catch (e) {
      print('Error loading scripts: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '漫才動画生成アプリ',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: scripts.length,
                    itemBuilder: (context, index) {
                      final script = scripts[index];
                      return Card(
                        child: ListTile(
                          title: Text(script['title'] ?? '無題'),
                          subtitle:
                              Text('コンビ名: ${script['combi_name'] ?? '(未設定)'}'),
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
                                            scriptData: script)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScriptEditorView()),
                );
              },
              child: Text('新規作成'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
