// Minimal flutter_driver host over the VM service — the fallback for when the
// Dart MCP (`mcp__dart__*`) is not available in the session.
//
// usage:
//   dart run drive.dart <ws-uri> '<json-command>' ['<json-command>' ...]
//   dart run drive.dart <ws-uri> texts      # every string on screen
//
// <ws-uri> is the "Debug service listening on ws://…/ws" line that
// `flutter run --target test_driver/app.dart` prints. Commands are plain
// flutter_driver commands, e.g.
//   '{"command":"get_health"}'
//   '{"command":"tap","finderType":"ByText","text":"Settings"}'
//   '{"command":"tap","finderType":"ByType","type":"LibraryBackButton"}'
//   '{"command":"waitFor","finderType":"ByType","type":"LibraryScreen","timeout":"5000"}'
//
// A DWDS "timed out - received 0/1 responses" does NOT tell you whether the tap
// happened: take a screenshot before deciding either way.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

late WebSocket _ws;
int _id = 0;
final Map<int, Completer<Map<String, dynamic>>> _waiters = {};

Future<Map<String, dynamic>> _rpc(String method, Map<String, dynamic> params) {
  final id = ++_id;
  final completer = Completer<Map<String, dynamic>>();
  _waiters[id] = completer;
  _ws.add(jsonEncode({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params}));
  return completer.future
      .timeout(const Duration(seconds: 60), onTimeout: () => {'error': 'timeout'});
}

Future<Map<String, dynamic>> _driver(String isolateId, Map<String, dynamic> cmd) {
  // The driver extension takes every argument as a STRING.
  final params = <String, dynamic>{'isolateId': isolateId};
  cmd.forEach((k, v) => params[k] = v is String ? v : jsonEncode(v));
  return _rpc('ext.flutter.driver', params);
}

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln("usage: dart run drive.dart <ws-uri> '<json-command>'... | texts");
    exit(64);
  }
  _ws = await WebSocket.connect(args[0]);
  _ws.listen((data) {
    final message = jsonDecode(data as String) as Map<String, dynamic>;
    final id = message['id'];
    if (id is int) _waiters.remove(id)?.complete(message);
  });

  final vm = await _rpc('getVM', {});
  final isolates = (vm['result']?['isolates'] as List?) ?? const [];
  if (isolates.isEmpty) {
    stderr.writeln('no isolates — is the app running with --target test_driver/app.dart?');
    exit(2);
  }
  final isolateId = isolates.first['id'] as String;

  for (final raw in args.skip(1)) {
    if (raw == 'texts') {
      final res = await _driver(isolateId, {'command': 'get_render_tree'});
      final tree = (res['result']?['response']?['tree'] as String?) ?? '';
      // Long strings wrap across lines behind the tree's box-drawing prefix:
      // strip the prefix from every line and join before matching quotes.
      final flat = tree
          .split('\n')
          .map((line) => line.replaceFirst(RegExp(r'^[\s╎│║┃┆┊└├─═╘╞]*'), ''))
          .join(' ');
      final texts = RegExp(r'"([^"]{2,200})"')
          .allMatches(flat)
          .map((m) => m.group(1)!)
          .toSet()
          .toList()
        ..sort();
      stdout.writeln('### texts (${texts.length})');
      texts.forEach(stdout.writeln);
      continue;
    }
    final cmd = jsonDecode(raw) as Map<String, dynamic>;
    final res = await _driver(isolateId, cmd);
    stdout.writeln('### ${cmd['command']} ${cmd['text'] ?? cmd['type'] ?? ''}');
    stdout.writeln(jsonEncode(res['result'] ?? res['error'] ?? res));
  }
  await _ws.close();
}
