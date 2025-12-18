import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isdateendance/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Just verify the app structure builds without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    // It will likely be in loading state (CircularProgressIndicator)
    // because the DB future might not resolve instantly in this environment
    // or requires the loop to pump.
  });
}
