import 'package:ceniflix/features/auth/presentation/pages/signup_screen.dart';
import 'package:ceniflix/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../helpers/fake_auth_view_model.dart';

void main() {
  Widget wrapWithApp(Widget child) {
    return ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => FakeAuthViewModel()),
      ],
      child: MaterialApp(home: child),
    );
  }

  Future<void> tapSignUpButton(WidgetTester tester) async {
    final signUpButton = find.widgetWithText(ElevatedButton, 'SIGN UP');
    await tester.ensureVisible(signUpButton);
    await tester.pumpAndSettle();
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();
  }

  testWidgets('Signup: shows snackbar when fields are empty', (tester) async {
    await tester.pumpWidget(wrapWithApp(const SignupScreen()));

    await tapSignUpButton(tester);

    expect(find.text('Please fill all fields'), findsOneWidget);
  });

  testWidgets('Signup: non-gmail email shows snackbar', (tester) async {
    await tester.pumpWidget(wrapWithApp(const SignupScreen()));

    await tester.enterText(find.byType(TextField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextField).at(1), 'john@yahoo.com');
    await tester.enterText(find.byType(TextField).at(2), '1234567');
    await tester.enterText(find.byType(TextField).at(3), '1234567');

    await tapSignUpButton(tester);

    expect(find.text('Only Gmail addresses are allowed'), findsOneWidget);
  });
}
