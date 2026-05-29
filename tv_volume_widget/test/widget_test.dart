import 'package:flutter_test/flutter_test.dart';
import 'package:tv_volume_widget/app.dart';

void main() {
  testWidgets('App should build without error', (WidgetTester tester) async {
    await tester.pumpWidget(const TvVolumeWidgetApp());
  });
}
