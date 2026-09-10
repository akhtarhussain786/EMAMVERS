import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors ApiService._processResponse's unwrapping rule.
///
/// The bug this guards against: the old implementation only unwrapped `data`
/// when it was a Map, so list endpoints (bookmarks, solutions, purchases)
/// returned the whole envelope and every caller's `is List` check failed.
dynamic unwrap(String body) {
  final json = jsonDecode(body);
  if (json is Map<String, dynamic> && json.containsKey('data') && json.containsKey('status')) {
    return json['data'];
  }
  return json;
}

void main() {
  group('API envelope unwrapping', () {
    test('unwraps a Map payload', () {
      final r = unwrap('{"status":"success","message":"ok","data":{"a":1},"errors":[]}');
      expect(r, isA<Map>());
      expect(r['a'], 1);
    });

    test('unwraps a List payload — the case that used to break', () {
      final r = unwrap('{"status":"success","message":"ok","data":[{"id":1},{"id":2}],"errors":[]}');
      expect(r, isA<List>());
      expect(r.length, 2);
    });

    test('unwraps an empty list to an empty list, not the envelope', () {
      final r = unwrap('{"status":"success","message":"ok","data":[],"errors":[]}');
      expect(r, isA<List>());
      expect(r, isEmpty);
    });

    test('passes through a null payload', () {
      expect(unwrap('{"status":"success","message":"ok","data":null,"errors":[]}'), isNull);
    });

    test('leaves a non-envelope response untouched', () {
      final r = unwrap('{"some":"payload"}');
      expect(r['some'], 'payload');
    });
  });
}
