import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_address_repository.dart';
import 'package:wallet_test/features/address/address_repository.dart';
import 'package:wallet_test/features/address/address_tile.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';

class MockAddressRepository extends Mock implements IAddressRepository {}

void main() {
  late InMemoryAddressRepository repository;
  late AddressTileBloc bloc;

  setUp(() {
    repository = InMemoryAddressRepository();
    bloc = AddressTileBloc(repository: repository);
    
    if (!GetIt.instance.isRegistered<IAddressRepository>()) {
      GetIt.instance.registerLazySingleton<IAddressRepository>(() => repository);
    }
    if (!GetIt.instance.isRegistered<AddressTileBloc>()) {
      GetIt.instance.registerFactory<AddressTileBloc>(() => bloc);
    }
  });

  tearDown(() {
    GetIt.instance.unregister<AddressTileBloc>();
    GetIt.instance.unregister<IAddressRepository>();
  });

  testWidgets('widget renders correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AddressTile(
            address: '0x1234567890abcdef1234567890abcdef12345678',
            network: 'Ethereum',
          ),
        ),
      ),
    );

    expect(find.text('Ethereum'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });

  testWidgets('no overflow at textScaleFactor 2.0', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(2.0),
          ),
          child: Scaffold(
            body: AddressTile(
              address: '0x1234567890abcdef1234567890abcdef12345678',
              network: 'Ethereum',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping copy button calls repository.copyAddress', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AddressTile(
            address: '0x1234567890abcdef1234567890abcdef12345678',
            network: 'Ethereum',
          ),
        ),
      ),
    );

    expect(repository.copyCalls, 0);
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();
    expect(repository.copyCalls, 1);
    expect(repository.lastAddress, '0x1234567890abcdef1234567890abcdef12345678');
  });

  testWidgets('shows copied state on success', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AddressTile(
            address: '0x1234567890abcdef1234567890abcdef12345678',
            network: 'Ethereum',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();
    
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('shows error state on failure', (tester) async {
    repository.shouldFail = true;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AddressTile(
            address: '0x1234567890abcdef1234567890abcdef12345678',
            network: 'Ethereum',
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();
    
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('state resets after 1500ms', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AddressTile(
            address: '0x1234567890abcdef1234567890abcdef12345678',
            network: 'Ethereum',
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();
    
    expect(find.byIcon(Icons.check), findsOneWidget);
    
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    
    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('BLoC is closed after dispose', (tester) async {
    final blocSpy = AddressTileBloc(repository: repository);
    GetIt.instance.unregister<AddressTileBloc>();
    GetIt.instance.registerFactory<AddressTileBloc>(() => blocSpy);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AddressTile(
            address: '0x1234567890abcdef1234567890abcdef12345678',
            network: 'Ethereum',
          ),
        ),
      ),
    );

    expect(blocSpy.isClosed, isFalse);
    
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    
    expect(blocSpy.isClosed, isTrue);
  });
}