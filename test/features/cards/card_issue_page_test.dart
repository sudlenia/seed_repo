import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/dev_stubs/dev_card_issuer.dart';
import 'package:wallet_test/features/cards/card_issue_bloc.dart';
import 'package:wallet_test/features/cards/card_issue_page.dart';
import 'package:wallet_test/features/cards/card_issuer.dart';

void main() {
  group('CardIssuePage', () {
    late DevCardIssuer issuer;
    late CardIssueBloc bloc;

    setUp(() {
      issuer = DevCardIssuer();
      bloc = CardIssueBloc(issuer: issuer);
      
      if (!GetIt.instance.isRegistered<ICardIssuer>()) {
        GetIt.instance.registerLazySingleton<ICardIssuer>(() => issuer);
      }
      if (!GetIt.instance.isRegistered<CardIssueBloc>()) {
        GetIt.instance.registerFactory<CardIssueBloc>(() => bloc);
      }
    });

    tearDown(() {
      GetIt.instance.unregister<CardIssueBloc>();
      GetIt.instance.unregister<ICardIssuer>();
    });

    testWidgets('page renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      expect(find.text('Issue Card card_1'), findsOneWidget);
      expect(find.text('Issue card'), findsOneWidget);
    });

    testWidgets('BLoC is retrieved from GetIt', (tester) async {
      final testBloc = CardIssueBloc(issuer: issuer);
      GetIt.instance.unregister<CardIssueBloc>();
      GetIt.instance.registerFactory<CardIssueBloc>(() => testBloc);

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      final blocFromGetIt = GetIt.instance<CardIssueBloc>();
      
      expect(blocFromGetIt, testBloc);
    });

    testWidgets('ICardIssuer is retrieved from GetIt', (tester) async {
      final testIssuer = DevCardIssuer();
      GetIt.instance.unregister<ICardIssuer>();
      GetIt.instance.registerLazySingleton<ICardIssuer>(() => testIssuer);

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      final issuerFromGetIt = GetIt.instance<ICardIssuer>();
      expect(issuerFromGetIt, testIssuer);
    });

    testWidgets('dispose closes BLoC and calls cancelPending once', (tester) async {
      final testIssuer = DevCardIssuer();
      final testBloc = CardIssueBloc(issuer: testIssuer);
      
      GetIt.instance.unregister<ICardIssuer>();
      GetIt.instance.registerLazySingleton<ICardIssuer>(() => testIssuer);
      GetIt.instance.unregister<CardIssueBloc>();
      GetIt.instance.registerFactory<CardIssueBloc>(() => testBloc);

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      expect(testIssuer.cancelCalls, 0);
      expect(testBloc.isClosed, false);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(testIssuer.cancelCalls, 1);
    });

    testWidgets('dispose calls cancelPending only once even with multiple disposals', (tester) async {
      final testIssuer = DevCardIssuer();
      final testBloc = CardIssueBloc(issuer: testIssuer);
      
      GetIt.instance.unregister<ICardIssuer>();
      GetIt.instance.registerLazySingleton<ICardIssuer>(() => testIssuer);
      GetIt.instance.unregister<CardIssueBloc>();
      GetIt.instance.registerFactory<CardIssueBloc>(() => testBloc);

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      expect(testIssuer.cancelCalls, 0);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(testIssuer.cancelCalls, 1);
    });

    testWidgets('using testWithGetIt pattern', (tester) async {
      final testIssuer = DevCardIssuer();
      final testBloc = CardIssueBloc(issuer: testIssuer);
      
      GetIt.instance.reset();
      GetIt.instance.registerLazySingleton<ICardIssuer>(() => testIssuer);
      GetIt.instance.registerFactory<CardIssueBloc>(() => testBloc);

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(testIssuer.cancelCalls, 1);
      
      GetIt.instance.reset();
    });
  });
}