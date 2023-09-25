import 'dart:io';

import 'package:crdt/map_crdt.dart';
import 'package:crdt_sync/crdt_sync_server.dart';

final colorRegex = RegExp(r'^#(?:[0-9a-fA-F]{3}){1,2}$');
final crdt = MapCrdt(['pixels', 'meta']);

main(List<String> args) async {
  final port = args.isEmpty ? 8080 : int.parse(args.first);

  print('Running server on port $port…');
  while (true) {
    try {
      await listen(
        crdt,
        port,
        onConnecting: (request) =>
            print('Incoming client: ${request.remoteAddress}'),
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onUpgradeError: (error, request) =>
            print('[${request.remoteAddress}] ${request.requestedUri}: $error'),
        validateRecord: validateRecord,
        // onChangesetReceived: (recordCounts, nodeId) =>
        //     print('⇩ $nodeId $recordCounts'),
        // onChangesetSent: (recordCounts, nodeId) => print('⇧ $nodeId $recordCounts'),
        // verbose: true,
      );
    } catch (e, st) {
      print('$e\n$st');
    }
  }
}

void onConnect(CrdtSync crdtSync, Object? customData) {
  final count = crdt.get('meta', 'user_count') ?? 0;
  crdt.put('meta', 'user_count', count + 1);
  print('Client joined: ${crdtSync.peerId}');
}

void onDisconnect(String peerId, int? code, String? reason) {
  final count = crdt.get('meta', 'user_count');
  crdt.put('meta', 'user_count', count - 1);
  print('Client left: $peerId');
}

bool validateRecord(String table, Map<String, dynamic> record) {
  try {
    // Clients can only write to the pixels table
    if (table != 'pixels') throw 'Client tried writing to $table\n$record';

    // Ensure keys are properly formatted
    final key = record['key'] as String;
    final i = key.indexOf(' ');
    final x = int.parse(key.substring(0, i));
    final y = int.parse(key.substring(i + 1));

    // Ensure coordinates are valid
    if (x < 0 || x > 99 || y < 0 || y > 99) throw 'Bad coordinate: $x:$y';

    // Ensure color is valid
    final color = record['value'] as String;
    if (!colorRegex.hasMatch(color)) throw 'Bad color string: $color';
  } catch (e) {
    print(e);
    return false;
  }
  return true;
}

extension on HttpRequest {
  // Convenience getter to resolve forwarded connections e.g. nginx or Caddy
  String? get remoteAddress =>
      headers['X-Forwarded-For']?.first ??
      connectionInfo?.remoteAddress.address;
}
