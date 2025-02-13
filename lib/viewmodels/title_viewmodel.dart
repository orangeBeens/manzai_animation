import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScriptData {
  final String title;
  final String combiName;
  final Map<String, dynamic> rawData;

  ScriptData({
    required this.title,
    required this.combiName,
    required this.rawData,
  });

  factory ScriptData.fromJson(Map<String, dynamic> json) {
    return ScriptData(
      title: json['title'] ?? '無題',
      combiName: json['combi_name'] ?? '(未設定)',
      rawData: json,
    );
  }
}

class TitleViewModel extends ChangeNotifier {
  List<ScriptData> _scripts = [];
  bool _isLoading = true;
  String? _error;

  List<ScriptData> get scripts => _scripts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadScripts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('http://localhost:8000/scripts/get_manzai_scripts'),
        headers: {'Accept': 'application/json; charset=utf-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _scripts = data.map((json) => ScriptData.fromJson(json)).toList();
      } else {
        _error = 'データの取得に失敗しました';
      }
    } catch (e) {
      _error = 'エラーが発生しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
