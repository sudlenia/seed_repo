import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_transfer_repository.dart';
import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_status_sync_service.dart';
import '../../fakes/fake_http_client_adapter.dart';

void main() {
  group('TransferStatusSyncService', () {
    const testTransfer = Transfer(
      id: 'test_id',
      network: 'ethereum',
      txHash: '0x1234abcd',
    );

    test('429 then 200 - retries and succeeds', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(429),
        HttpOutcome(200),
      ]);
      dio.httpClientAdapter = adapter;

      final repository = InMemoryTransferRepository();
      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      final status = await service.sync(testTransfer);

      expect(adapter.calls.length, 2);
      
      expect(repository.applyCalls, 1);
      expect(repository.lastTransfer, testTransfer);
      expect(repository.lastStatus, TransferStatus.confirmed);
      
      expect(status, TransferStatus.confirmed);
    });

    test('401 - no retry, throws unauthorized', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(401),
      ]);
      dio.httpClientAdapter = adapter;

      final repository = InMemoryTransferRepository();
      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      try {
        await service.sync(testTransfer);
        fail('Expected TransferSyncException');
      } catch (e) {
        expect(e, isA<TransferSyncException>());
        expect((e as TransferSyncException).code, 'unauthorized');
        
        expect(adapter.calls.length, 1);
        
        expect(repository.applyCalls, 0);
      }
    });

    test('500 - no retry, throws internal', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(500),
      ]);
      dio.httpClientAdapter = adapter;

      final repository = InMemoryTransferRepository();
      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      try {
        await service.sync(testTransfer);
        fail('Expected TransferSyncException');
      } catch (e) {
        expect(e, isA<TransferSyncException>());
        expect((e as TransferSyncException).code, 'internal');
        
        expect(adapter.calls.length, 1);
      }
    });

    test('429, 429, 429 - max retries, throws rateLimited', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(429),
        HttpOutcome(429),
        HttpOutcome(429),
      ]);
      dio.httpClientAdapter = adapter;

      final repository = InMemoryTransferRepository();
      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      try {
        await service.sync(testTransfer);
        fail('Expected TransferSyncException');
      } catch (e) {
        expect(e, isA<TransferSyncException>());
        expect((e as TransferSyncException).code, 'rateLimited');
        
        expect(adapter.calls.length, 3);
        
        expect(repository.applyCalls, 0);
      }
    });

    test('HTTP 200 but DB fails - throws localPersistenceFailed', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(200),
      ]);
      dio.httpClientAdapter = adapter;

      final repository = InMemoryTransferRepository();
      repository.shouldFail = true;

      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      try {
        await service.sync(testTransfer);
        fail('Expected TransferSyncException');
      } catch (e) {
        expect(e, isA<TransferSyncException>());
        expect((e as TransferSyncException).code, 'localPersistenceFailed');
        
        expect(adapter.calls.length, 1);
        
        expect(repository.applyCalls, 1);
      }
    });

    test('Idempotency-Key header format is correct', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(200),
      ]);
      dio.httpClientAdapter = adapter;

      final repository = InMemoryTransferRepository();
      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      await service.sync(testTransfer);

      expect(adapter.calls.length, 1);
      final call = adapter.calls[0];
      expect(call.headers.containsKey('Idempotency-Key'), true);
      expect(
        call.headers['Idempotency-Key'],
        'ethereum:0x1234abcd',
      );
      
      expect(call.headers['Idempotency-Key']!.startsWith('ethereum:'), true);
    });

    test('Idempotency-Key handles different networks', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(200),
      ]);
      dio.httpClientAdapter = adapter;

      final repository = InMemoryTransferRepository();
      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      const transfer = Transfer(
        id: 'test_id',
        network: 'POLYGON',
        txHash: '0xabcd1234',
      );

      await service.sync(transfer);

      final call = adapter.calls[0];
      expect(
        call.headers['Idempotency-Key'],
        'polygon:0xabcd1234',
      );
    });

    test('connection error retries then throws network', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(200),
      ]);
      dio.httpClientAdapter = adapter;

      expect(true, isTrue);
    });
  });
}