import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:searchlab/app/lab_home.dart';
import 'package:searchlab/features/search/data/fake_catalog_api.dart';
import 'package:searchlab/features/search/presentation/cubit/search_cubit.dart';

Future<SearchCubit> mount(WidgetTester tester) async {
  final cubit = SearchCubit(FakeCatalogApi()..delayMs = 0);
  await tester.pumpWidget(BlocProvider.value(
      value: cubit, child: const MaterialApp(home: LabHome())));
  await tester.pumpAndSettle();
  addTearDown(cubit.close);
  return cubit;
}

void main() {
  testWidgets('search, empty results, and Clear synchronize visible input',
      (tester) async {
    final cubit = await mount(tester);
    await tester.enterText(find.byType(TextField), 'no matching book xyz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('No results · try different filters'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(cubit.state.items, isNotEmpty);
  });
  testWidgets('all labs remain reachable and sessions isolate favorites',
      (tester) async {
    await mount(tester);
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pump();
    await tester.tap(find.text('Session'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites for User A: 1'), findsOneWidget);
    await tester.tap(find.text('User B'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites for User B: 0'), findsOneWidget);
    await tester.tap(find.text('Network'));
    await tester.pumpAndSettle();
    expect(find.text('Network Playground'), findsOneWidget);
    await tester.tap(find.text('Cache'));
    await tester.pumpAndSettle();
    expect(find.text('Cache & Offline Lab'), findsOneWidget);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });
  testWidgets('offline errors render and retry recovers', (tester) async {
    final cubit = await mount(tester);
    cubit.api.offline = true;
    await cubit.refresh();
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsOneWidget);
    cubit.api.offline = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);
  });
  testWidgets('filter changes preserve selected values and filter results',
      (tester) async {
    final cubit = await mount(tester);
    await tester.tap(find.byType(DropdownButton<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category: Technology').last);
    await tester.pumpAndSettle();
    expect(cubit.state.query.category, 'Technology');
    expect(cubit.state.items.every((book) => book.category == 'Technology'),
        isTrue);
  });
  testWidgets(
      'loading indicator remains visible until fake transport completes',
      (tester) async {
    final cubit = SearchCubit(FakeCatalogApi());
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider.value(
        value: cubit, child: const MaterialApp(home: LabHome())));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // The transport checks cancellation every 25 ms; advance each virtual tick.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 25));
    }
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
  testWidgets('scrolling loads the next page', (tester) async {
    final cubit = await mount(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(cubit.state.page, greaterThan(1));
  });
}
