import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Chinese and English have identical nonempty resource keys', () {
    final zh =
        jsonDecode(File('lib/l10n/app_zh.arb').readAsStringSync())
            as Map<String, dynamic>;
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    final keys = zh.keys.where((k) => !k.startsWith('@')).toSet();
    expect(en.keys.where((k) => !k.startsWith('@')).toSet(), keys);
    for (final k in keys) {
      expect(zh[k], isNotEmpty);
      expect(en[k], isNotEmpty);
    }
  });
}
