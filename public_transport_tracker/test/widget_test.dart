import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:public_transport_tracker/main.dart';
import 'package:public_transport_tracker/services/api_service.dart';

void main() {
  test('default backend targets the Android emulator host', () {
    expect(ApiConfig.baseUrl, 'http://10.0.2.2:5000/api');
    expect(ApiConfig.wsUrl, 'http://10.0.2.2:5000');
  });

  testWidgets('signed-out user can open login without native Firebase', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TransitLiveApp());
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign In'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
