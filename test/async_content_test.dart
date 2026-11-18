import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/data/api_exception.dart';
import 'package:shakti_saree/admin/widgets/common/async_content.dart';

class _Version extends Notifier<int> {
  @override
  int build() => 1;

  void next() => state++;
}

final _version = NotifierProvider<_Version, int>(_Version.new);

Widget _host(FutureProvider<String> read) => ProviderScope(
  child: MaterialApp(
    home: Scaffold(
      body: Consumer(
        builder: (context, ref, _) => AsyncContent<String>(
          state: ref.watch(read),
          onRetry: () {},
          builder: (context, value) => Text(value),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('what is on screen stays while it is read again', (tester) async {
    final second = Completer<String>();
    final list = FutureProvider<String>((ref) async {
      final version = ref.watch(_version);
      return version == 1 ? 'first read' : second.future;
    });

    await tester.pumpWidget(_host(list));
    await tester.pumpAndSettle();
    expect(find.text('first read'), findsOneWidget);

    ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
      listen: false,
    ).read(_version.notifier).next();
    await tester.pump();

    expect(find.text('first read'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    second.complete('second read');
    await tester.pumpAndSettle();
    expect(find.text('second read'), findsOneWidget);
  });

  testWidgets('a failed read says so while it is being retried', (
    tester,
  ) async {
    final refused = FutureProvider<String>(
      (ref) async => throw const NetworkUnavailable(),
    );

    await tester.pumpWidget(_host(refused));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Lets the provider's own retries wind down with the screen gone.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
  });

  testWidgets('the very first read still shows a spinner', (tester) async {
    final waiting = Completer<String>();
    final list = FutureProvider<String>((ref) => waiting.future);

    await tester.pumpWidget(_host(list));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    waiting.complete('loaded');
    await tester.pumpAndSettle();
    expect(find.text('loaded'), findsOneWidget);
  });
}
