// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:english_bro_v2/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // 앱을 빌드하고 프레임을 렌더링합니다.
    await tester.pumpWidget(const VocabularyApp());
    
    // 초기 화면에 '영단어 삼형제' 타이틀과 레벨 선택 안내 문구가 있는지 확인합니다.
    expect(find.text('영단어 삼형제'), findsOneWidget);
    expect(find.text('학습할 레벨을 선택하세요'), findsOneWidget);
  });
}
