import 'dart:async';

import 'package:dio/dio.dart';

import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_repository.dart';

class TransferStatusSyncService {
  TransferStatusSyncService({
    required ApiClient api,
    required ITransferRepository repository,
  })  : _api = api,
        _repository = repository;

  final ApiClient _api;
  final ITransferRepository _repository;

  Future<TransferStatus> sync(
    Transfer transfer, {
    CancelToken? cancelToken,
  }) async {
    int attempt = 0;
    const maxAttempts = 3;
    final delays = [0, 200, 500];

    while (attempt < maxAttempts) {
      attempt++;

      try {
        if (cancelToken?.isCancelled == true) {
          throw const CancelException();
        }

        final response = await _api.dio.get(
          '/v1/transfers/${transfer.txHash}/status',
          options: Options(
            headers: {
              'Idempotency-Key': '${transfer.network.toLowerCase()}:${transfer.txHash}',
            },
          ),
          cancelToken: cancelToken,
        );

        if (cancelToken?.isCancelled == true) {
          throw const CancelException();
        }

        final statusName = response.data['status'] as String? ?? 'unknown';
        final status = TransferStatus.fromName(statusName);

        try {
          await _repository.applyStatus(
            transfer,
            status,
            DateTime.now(),
          );
        } catch (e) {
          throw TransferSyncException(
            code: 'localPersistenceFailed',
            message: e.toString(),
          );
        }

        return status;

      } on CancelException {
        rethrow;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel || cancelToken?.isCancelled == true) {
          throw const CancelException();
        }

        if (!_shouldRetry(e)) {
          throw _mapError(e);
        }

        if (attempt >= maxAttempts) {
          throw _mapError(e);
        }

        await Future.delayed(Duration(milliseconds: delays[attempt - 1]));
        continue;
      } catch (e) {
        if (e is CancelException) {
          rethrow;
        }
        throw TransferSyncException(
          code: 'unknown',
          message: e.toString(),
        );
      }
    }

    throw const TransferSyncException(
      code: 'unknown',
      message: 'Max retry attempts exhausted',
    );
  }

  bool _shouldRetry(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return false;
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return true;
    }

    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      if (statusCode != null) {
        if (statusCode == 408 || statusCode == 429 || statusCode == 503) {
          return true;
        }

        if ([400, 401, 402, 403, 404, 409, 422, 500].contains(statusCode)) {
          return false;
        }

        if (statusCode >= 500 && statusCode < 600) {
          return true;
        }

        return false;
      }
    }

    return false;
  }

  TransferSyncException _mapError(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return const TransferSyncException(code: 'cancelled');
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const TransferSyncException(code: 'network');
    }

    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      switch (statusCode) {
        case 401:
          return const TransferSyncException(code: 'unauthorized');
        case 404:
          return const TransferSyncException(code: 'notFound');
        case 409:
          return const TransferSyncException(code: 'conflict');
        case 408:
        case 429:
          return const TransferSyncException(code: 'rateLimited');
        case 503:
          return const TransferSyncException(code: 'serverUnavailable');
        case 500:
          return const TransferSyncException(code: 'internal');
        default:
          if (statusCode != null && statusCode >= 500 && statusCode < 600) {
            return const TransferSyncException(code: 'internal');
          }
          return TransferSyncException(
            code: 'httpError',
            message: 'HTTP $statusCode',
          );
      }
    }

    return const TransferSyncException(code: 'unknown');
  }
}