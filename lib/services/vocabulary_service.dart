import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/vocabulary.dart';

class VocabularyService {
  static Future<List<Vocabulary>> loadVocabulary(String filename) async {
    try {
      final csvContent = await rootBundle.loadString('assets/$filename');
      final lines = csvContent.split('\n');
      
      // Skip header
      final vocabularyList = <Vocabulary>[];
      
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        // Parse CSV considering quoted fields
        final fields = _parseCSVLine(line);
        if (fields.length >= 3) {
          vocabularyList.add(Vocabulary.fromCsv(fields));
        }
      }
      
      return vocabularyList;
    } catch (e) {
      debugPrint('Error loading vocabulary: $e');
      return [];
    }
  }

  static List<String> _parseCSVLine(String line) {
    final List<String> fields = [];
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      var char = line[i];

      // 윈도우 스타일 줄바꿈 문자(\r) 처리
      if (char == '\r') continue;

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(current.trim().replaceAll('"', ''));
        current = '';
      } else {
        current += char;
      }
    }

    // 마지막 필드 추가
    fields.add(current.trim().replaceAll('"', ''));
    return fields;
  }
}
