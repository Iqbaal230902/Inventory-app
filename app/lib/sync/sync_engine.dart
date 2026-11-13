import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../data/local/database.dart';
import '../data/repositories/master_repo.dart';
import '../data/repositories/trx_repo.dart';

class SyncReport {
  SyncReport({this.pushed = 0, this.rejected = 0, this.pendingApproval = 0, this.error});
  int pushed;
  int rejected;
  int pendingApproval;
  ApiException? error;

  bool get ok => error == null;

  String get summary {
    if (error != null) return error!.isNetwork ? 'Offline — data tersimpan di HP.' : error!.message;
    final parts = <String>[
      if (pushed > 0) '$pushed transaksi terkirim',
      if (rejected > 0) '$rejected ditolak server',
      if (pendingApproval > 0) '$pendingApproval menunggu tinjauan',
    ];
    return parts.isEmpty ? 'Data sudah terbaru.' : parts.join(' · ');
  }
}

/// Mesin sinkronisasi (PRD 10): push antrian → upload foto & catatan cetak → pull delta.
/// Tidak bergantung pada Flutter UI sehingga dapat dijalankan dari WorkManager.
class SyncEngine {
  SyncEngine({required this.db, required this.api, required this.currentUserId})
      : trx = TrxRepo(db),
        master = MasterRepo(db);

  final AppDatabase db;
  final ApiClient api;
  final Future<int?> Function() currentUserId;
  final TrxRepo trx;
  final MasterRepo master;

  Future<SyncReport>? _running;
  final _events = StreamController<bool>.broadcast();

  /// true saat sinkron berjalan.
  Stream<bool> get runningStream => _events.stream;
  bool get isRunning => _running != null;

  Future<SyncReport> sync({bool fullPull = false}) {
    // Single-flight: panggilan bersamaan berbagi proses yang sama.
    return _running ??= _sync(fullPull).whenComplete(() {
      _running = null;
      _events.add(false);
    });
  }

  Future<SyncReport> _sync(bool fullPull) async {
    _events.add(true);
    final report = SyncReport();
    try {
      await _push(report);
      await _uploadPhotos();
      await _reportPrints();
      await pull(full: fullPull);
      await db.setKv('last_sync_ok_at', DateTime.now().toUtc().toIso8601String());
      await db.setKv('last_sync_error', '');
    } catch (e) {
      report.error = ApiException.from(e);
      await db.setKv('last_sync_error', report.error!.isNetwork ? '' : report.error!.message);
    }
    return report;
  }

  Future<void> _push(SyncReport report) async {
    final userId = await currentUserId();
    if (userId == null) return;
    var guard = 0;
    while (guard++ < 100) {
      final batch = await trx.pendingBatch(AppConfig.pushBatchSize, userId: userId);
      if (batch.isEmpty) return;
      final res = await api.post<Map<String, dynamic>>('/sync/push', {
        'transactions': batch.map((r) => jsonDecode(r.payload)).toList(),
      });
      final results = (res['results'] as List).cast<Map>();
      for (final r in results) {
        final uuid = r['client_uuid'] as String?;
        if (uuid == null) continue;
        final status = r['status'];
        if (status == 'ok' || status == 'duplicate') {
          final t = (r['transaction'] as Map).cast<String, dynamic>();
          await trx.markSynced(uuid, t);
          report.pushed++;
          if (t['status'] == 'pending_approval') report.pendingApproval++;
        } else {
          final err = (r['error'] as Map?) ?? {};
          await trx.markRejected(uuid, '${err['code'] ?? 'REJECTED'}', '${err['message'] ?? 'Ditolak server.'}');
          report.rejected++;
        }
      }
      // Item yang tidak dikembalikan server tetap pending (dicoba lagi berikutnya).
      if (results.isEmpty) return;
    }
  }

  Future<void> _uploadPhotos() async {
    final rows = await (db.select(db.localTransactions)
          ..where((t) =>
              t.syncState.equals(SyncState.synced) &
              t.photoPath.isNotNull() &
              t.photoUploaded.equals(false) &
              t.serverId.isNotNull()))
        .get();
    for (final r in rows) {
      final f = File(r.photoPath!);
      if (!await f.exists()) {
        await _setPhotoUploaded(r.clientUuid);
        continue;
      }
      await api.post('/transactions/${r.serverId}/photo',
          FormData.fromMap({'photo': await MultipartFile.fromFile(f.path, filename: 'foto.jpg')}));
      await _setPhotoUploaded(r.clientUuid);
    }
  }

  Future<void> _setPhotoUploaded(String uuid) =>
      (db.update(db.localTransactions)..where((t) => t.clientUuid.equals(uuid)))
          .write(const LocalTransactionsCompanion(photoUploaded: Value(true)));

  /// Cetak surat jalan saat offline dilaporkan ke audit log server setelah online.
  Future<void> _reportPrints() async {
    final rows = await (db.select(db.localTransactions)
          ..where((t) => t.unreportedPrints.isBiggerThanValue(0) & t.serverId.isNotNull()))
        .get();
    for (final r in rows) {
      for (var i = 0; i < r.unreportedPrints; i++) {
        await api.post('/transactions/${r.serverId}/print', {'channel': 'offline'});
      }
      await (db.update(db.localTransactions)..where((t) => t.clientUuid.equals(r.clientUuid)))
          .write(const LocalTransactionsCompanion(unreportedPrints: Value(0)));
    }
  }

  Future<void> pull({bool full = false}) async {
    final since = full ? null : await db.getKv('last_pull_server_time');
    final res = await api.get<Map<String, dynamic>>('/sync/pull', query: {'since': since});
    await master.applyPull(res);
  }
}
