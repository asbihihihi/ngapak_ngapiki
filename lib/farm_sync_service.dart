import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class FarmSyncService {
  FarmSyncService._();

  static const _boxNames = [
    'dombaBox',
    'penjualanBox',
    'bobotDombaBox',
    'aktivitasDombaBox',
    'batchBox',
    'barangBox',
    'pergerakanGudangBox',
    'keuanganBox',
    'posProductBox',
    'posSaleBox',
    'dailyReportBox',
    'healthRecordBox',
  ];
  static const _mediaFields = ['foto', 'buktiPembayaran'];
  static const _bucket = 'farm-media';
  static const _pageSize = 200;

  static final _subscriptions = <StreamSubscription<BoxEvent>>[];
  static String? _farmId;
  static Timer? _debounce;
  static Timer? _poll;
  static bool _syncing = false;
  static bool _syncAgain = false;
  static final _suppressedEvents = <String>{};
  static final _recordIdCreations = <String, Future<String>>{};
  static Future<void> _localEventQueue = Future<void>.value();
  static final status = ValueNotifier<String>('Belum disinkronkan');

  static Box get _metadata => Hive.box('syncMetaBox');
  static String get codeSuffix {
    if (!SupabaseConfig.isConfigured) return '';
    final id = _metadata.get('installationId');
    return id is String && id.length >= 8
        ? id.replaceAll('-', '').substring(0, 6).toUpperCase()
        : '';
  }

  static Future<void> initialize() async {
    if (!_metadata.containsKey('installationId')) {
      await _metadata.put('installationId', _newUuid());
    }
  }

  static Future<void> start({required String farmId}) async {
    if (!SupabaseConfig.isConfigured) return;
    if (farmId.isEmpty) throw ArgumentError.value(farmId, 'farmId');
    if (_farmId == farmId && _subscriptions.isNotEmpty) return;
    await stop();
    _farmId = farmId;
    status.value = 'Menyinkronkan data...';

    for (final name in _boxNames) {
      _subscriptions.add(
        Hive.box(name).watch().listen(
          (event) => _onBoxEvent(name, event),
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Hive sync listener failed for $name: $error');
          },
        ),
      );
    }

    await _synchronize();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      _scheduleSync();
    });
  }

  static Future<void> stop() async {
    _debounce?.cancel();
    _poll?.cancel();
    _debounce = null;
    _poll = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _farmId = null;
  }

  static void _onBoxEvent(String boxName, BoxEvent event) {
    final eventToken = _eventToken(boxName, event.key);
    if (_suppressedEvents.remove(eventToken)) return;
    _localEventQueue = _localEventQueue.then(
      (_) => _recordLocalChange(boxName, event),
    );
  }

  static Future<void> _recordLocalChange(String boxName, BoxEvent event) async {
    try {
      final recordId = await _recordIdFor(boxName, event.key);
      final now = DateTime.now().toUtc().toIso8601String();
      final deleted = event.deleted;
      await _metadata.put(_versionKey(boxName, recordId), now);
      await _metadata.put(
        _actorKey(boxName, recordId),
        Supabase.instance.client.auth.currentUser?.id ?? '',
      );
      await _metadata.put(_pendingKey(boxName, recordId), {
        'updatedAt': now,
        'deleted': deleted,
      });
      _scheduleSync();
    } catch (error) {
      debugPrint('Could not queue local $boxName change: $error');
    }
  }

  static void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(_synchronize());
    });
  }

  static Future<void> _synchronize() async {
    if (_farmId == null) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      await _queueUnmappedLocalRecords();
      await _pushPendingRecords();
      await _pullRemoteRecords();
      status.value = 'Data tersinkron';
    } catch (error, stackTrace) {
      debugPrint('Farm data sync failed: $error\n$stackTrace');
      status.value = 'Sinkronisasi tertunda: $error';
    } finally {
      _syncing = false;
      if (_syncAgain) {
        _syncAgain = false;
        _scheduleSync();
      }
    }
  }

  static Future<void> _queueUnmappedLocalRecords() async {
    for (final boxName in _boxNames) {
      final box = Hive.box(boxName);
      for (final key in box.keys) {
        final recordId = await _recordIdFor(boxName, key);
        final pendingKey = _pendingKey(boxName, recordId);
        if (_metadata.containsKey(pendingKey)) continue;
        final version =
            _metadata.get(_versionKey(boxName, recordId)) as String?;
        final synced = _metadata.get(_syncedKey(boxName, recordId)) as String?;
        if (version != null && synced == version) continue;
        final updatedAt = version ?? DateTime.now().toUtc().toIso8601String();
        await _metadata.put(_versionKey(boxName, recordId), updatedAt);
        await _metadata.put(
          _actorKey(boxName, recordId),
          Supabase.instance.client.auth.currentUser?.id ?? '',
        );
        await _metadata.put(pendingKey, {
          'updatedAt': updatedAt,
          'deleted': false,
        });
      }
    }
  }

  static Future<void> _pushPendingRecords() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    final farmId = _farmId;
    if (userId == null || farmId == null) return;

    final pendingEntries = _metadata
        .toMap()
        .entries
        .where((entry) => '${entry.key}'.startsWith('pending|'))
        .toList();
    for (final entry in pendingEntries) {
      final parts = '${entry.key}'.split('|');
      if (parts.length != 3 || !_boxNames.contains(parts[1])) continue;
      final boxName = parts[1];
      final recordId = parts[2];
      final pending = Map<String, dynamic>.from(entry.value as Map);
      final updatedAt = '${pending['updatedAt']}';
      final deleted = pending['deleted'] == true;
      final localKey = _metadata.get(_remoteKey(boxName, recordId));
      final box = Hive.box(boxName);

      Map<String, dynamic>? payload;
      if (!deleted && localKey != null && box.containsKey(localKey)) {
        final raw = box.get(localKey);
        if (raw is! Map) {
          throw StateError('Expected map record in $boxName at key $localKey.');
        }
        payload = Map<String, dynamic>.from(raw);
        await _uploadMedia(boxName, recordId, payload, farmId, updatedAt);
      } else if (!deleted && localKey == null) {
        continue;
      } else if (!deleted && localKey != null && !box.containsKey(localKey)) {
        pending['deleted'] = true;
        pending['updatedAt'] = DateTime.now().toUtc().toIso8601String();
        await _metadata.put(entry.key, pending);
        continue;
      }

      await client.rpc(
        'sync_farm_record',
        params: {
          'p_farm_id': farmId,
          'p_box_name': boxName,
          'p_record_id': recordId,
          'p_payload': payload,
          'p_updated_at': updatedAt,
          'p_deleted_at': deleted ? updatedAt : null,
        },
      );
      await _metadata.put(_syncedKey(boxName, recordId), updatedAt);

      final latestPending = _metadata.get(entry.key);
      if (latestPending is Map &&
          latestPending['updatedAt'] == pending['updatedAt'] &&
          latestPending['deleted'] == pending['deleted']) {
        await _metadata.delete(entry.key);
      }
    }
  }

  static Future<void> _pullRemoteRecords() async {
    final client = Supabase.instance.client;
    final farmId = _farmId;
    if (farmId == null) return;
    final cursorKey = 'cursor|$farmId';
    final cursorText = _metadata.get(cursorKey) as String?;
    final cursor = cursorText == null ? null : DateTime.tryParse(cursorText);
    var offset = 0;
    var newest = cursor;

    while (true) {
      var query = client
          .from('farm_sync_records')
          .select(
            'box_name, record_id, payload, client_updated_at, updated_at, '
            'deleted_at, updated_by',
          )
          .eq('farm_id', farmId);
      if (cursor != null) {
        query = query.gte(
          'updated_at',
          cursor.subtract(const Duration(seconds: 2)).toUtc().toIso8601String(),
        );
      }
      final rows = await query
          .order('updated_at')
          .range(offset, offset + _pageSize - 1);
      if (rows.isEmpty) break;

      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final boxName = '${row['box_name']}';
        final recordId = '${row['record_id']}';
        if (!_boxNames.contains(boxName)) continue;
        final serverUpdatedAt = DateTime.parse('${row['updated_at']}').toUtc();
        final clientUpdatedAt = DateTime.parse(
          '${row['client_updated_at']}',
        ).toUtc();
        if (newest == null || serverUpdatedAt.isAfter(newest)) {
          newest = serverUpdatedAt;
        }
        final previousText = _metadata.get(_versionKey(boxName, recordId));
        final previous = previousText is String
            ? DateTime.tryParse(previousText)?.toUtc()
            : null;
        final remoteActor = '${row['updated_by']}';
        final localActor =
            '${_metadata.get(_actorKey(boxName, recordId)) ?? ''}';
        if (previous != null &&
            (clientUpdatedAt.isBefore(previous) ||
                (clientUpdatedAt.isAtSameMomentAs(previous) &&
                    remoteActor.compareTo(localActor) <= 0))) {
          continue;
        }
        await _applyRemoteRecord(row, farmId);
      }

      if (rows.length < _pageSize) break;
      offset += _pageSize;
    }

    if (newest != null) {
      await _metadata.put(cursorKey, newest.toIso8601String());
    }
  }

  static Future<void> _applyRemoteRecord(
    Map<String, dynamic> row,
    String farmId,
  ) async {
    final boxName = '${row['box_name']}';
    final recordId = '${row['record_id']}';
    final box = Hive.box(boxName);
    final localKeyToken = _remoteKey(boxName, recordId);
    var localKey = _metadata.get(localKeyToken);
    final deleted = row['deleted_at'] != null;

    if (deleted) {
      if (localKey != null && box.containsKey(localKey)) {
        _suppressedEvents.add(_eventToken(boxName, localKey));
        await box.delete(localKey);
      }
      await _metadata.delete(_pendingKey(boxName, recordId));
    } else {
      final rawPayload = row['payload'];
      if (rawPayload is! Map) {
        throw StateError(
          'Invalid synchronized payload for $boxName/$recordId.',
        );
      }
      final payload = Map<String, dynamic>.from(rawPayload);
      await _downloadMedia(boxName, recordId, payload, farmId);
      if (localKey == null) {
        localKey = 'cloud-$recordId';
        await _metadata.put(localKeyToken, localKey);
      }
      await _metadata.put(_localKey(boxName, localKey), recordId);
      _suppressedEvents.add(_eventToken(boxName, localKey));
      await box.put(localKey, payload);
      await _metadata.delete(_pendingKey(boxName, recordId));
    }

    await _metadata.put(
      _versionKey(boxName, recordId),
      DateTime.parse('${row['client_updated_at']}').toUtc().toIso8601String(),
    );
    await _metadata.put(
      _syncedKey(boxName, recordId),
      DateTime.parse('${row['client_updated_at']}').toUtc().toIso8601String(),
    );
    await _metadata.put(_actorKey(boxName, recordId), '${row['updated_by']}');
  }

  static Future<void> _uploadMedia(
    String boxName,
    String recordId,
    Map<String, dynamic> payload,
    String farmId,
    String updatedAt,
  ) async {
    final storage = Supabase.instance.client.storage.from(_bucket);
    for (final field in _mediaFields) {
      final path = payload[field];
      if (path is! String || path.isEmpty || path.startsWith('storage://')) {
        continue;
      }
      final file = File(path);
      if (!await file.exists()) {
        throw FileSystemException('Local media file does not exist.', path);
      }
      final extension = _extension(path);
      final version = updatedAt.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
      final uploadId = _newUuid();
      final objectPath =
          '$farmId/$boxName/$recordId/'
          '${field}_${version}_$uploadId.$extension';
      await storage.uploadBinary(
        objectPath,
        await file.readAsBytes(),
        fileOptions: FileOptions(
          upsert: true,
          contentType: _contentType(extension),
        ),
      );
      payload[field] = 'storage://$_bucket/$objectPath';
    }
  }

  static Future<void> _downloadMedia(
    String boxName,
    String recordId,
    Map<String, dynamic> payload,
    String farmId,
  ) async {
    final storage = Supabase.instance.client.storage.from(_bucket);
    for (final field in _mediaFields) {
      final path = payload[field];
      if (path is! String || !path.startsWith('storage://$_bucket/')) continue;
      final objectPath = path.substring('storage://$_bucket/'.length);
      final bytes = await storage.download(objectPath);
      final extension = _extension(objectPath);
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}'
        '${farmId}_${boxName}_${recordId}_$field.$extension',
      );
      await file.writeAsBytes(bytes, flush: true);
      payload[field] = file.path;
    }
  }

  static Future<String> _recordIdFor(String boxName, dynamic localKey) async {
    final key = _localKey(boxName, localKey);
    final existing = _metadata.get(key);
    if (existing is String) return existing;
    final creating = _recordIdCreations[key];
    if (creating != null) return creating;
    final future = _createRecordId(boxName, localKey, key);
    _recordIdCreations[key] = future;
    try {
      return await future;
    } finally {
      _recordIdCreations.remove(key);
    }
  }

  static Future<String> _createRecordId(
    String boxName,
    dynamic localKey,
    String localToken,
  ) async {
    final recordId = _newUuid();
    await _metadata.put(localToken, recordId);
    await _metadata.put(_remoteKey(boxName, recordId), localKey);
    return recordId;
  }

  static String _localKey(String boxName, dynamic key) =>
      'local|$boxName|${key.runtimeType}|$key';

  static String _remoteKey(String boxName, String recordId) =>
      'remote|$boxName|$recordId';

  static String _versionKey(String boxName, String recordId) =>
      'version|$boxName|$recordId';

  static String _actorKey(String boxName, String recordId) =>
      'actor|$boxName|$recordId';

  static String _syncedKey(String boxName, String recordId) =>
      'synced|$boxName|$recordId';

  static String _pendingKey(String boxName, String recordId) =>
      'pending|$boxName|$recordId';

  static String _eventToken(String boxName, dynamic key) =>
      '$boxName|${key.runtimeType}|$key';

  static String _extension(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    final value = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    return RegExp(r'^[a-z0-9]{1,8}$').hasMatch(value) ? value : 'bin';
  }

  static String _contentType(String extension) => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'application/octet-stream',
  };

  static String _newUuid() {
    final random = List<int>.generate(16, (_) => 0);
    final source = Random.secure();
    for (var index = 0; index < random.length; index++) {
      random[index] = source.nextInt(256);
    }
    random[6] = (random[6] & 0x0f) | 0x40;
    random[8] = (random[8] & 0x3f) | 0x80;
    final hex = random
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
