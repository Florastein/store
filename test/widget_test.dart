import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store/pages/customer/dashboard.dart';
import 'package:store/main.dart';

void main() {
  testWidgets('renders the customer dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.byType(CustomerDashboard), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);
  });
}
