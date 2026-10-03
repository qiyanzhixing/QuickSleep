import 'dart:convert';
import 'package:flutter/services.dart';

class AudioAsset {
  const AudioAsset({
    required this.id,
    required this.path,
    required this.duration,
  });
  final String id, path;
  final Duration duration;
}

class AudioCatalog {
  AudioCatalog(Iterable<AudioAsset> assets)
    : _assets = {for (final a in assets) a.id: a};
  final Map<String, AudioAsset> _assets;
  AudioAsset asset(String id) =>
      _assets[id] ?? (throw StateError('Missing audio asset: $id'));
}

Future<AudioCatalog> loadAudioCatalog(AssetBundle bundle) async {
  final raw =
      jsonDecode(await bundle.loadString('assets/audio/catalog.json'))
          as List<dynamic>;
  final expected = {
    for (final l in ['zh', 'en'])
      for (final m in ['moon', 'mountain', 'forest'])
        for (final r in ['guide', 'preview']) '$l.$m.$r',
    for (final m in ['moon', 'mountain', 'forest'])
      for (final r in ['bed', 'fade']) 'shared.$m.$r',
  };
  final assets = <AudioAsset>[];
  for (final entry in raw) {
    final e = entry as Map<String, dynamic>;
    final id = e['id'] as String;
    final path = e['path'] as String;
    final role = e['role'] as String;
    final durations = {
      'guide': 80000,
      'preview': 8000,
      'bed': 60000,
      'fade': 15000,
    };
    if (!expected.remove(id) ||
        path.contains('..') ||
        path.startsWith('/') ||
        !path.endsWith('.wav') ||
        e['durationMs'] != durations[role] ||
        e['provenance'] == null) {
      throw const FormatException('Invalid audio catalog');
    }
    assets.add(
      AudioAsset(
        id: id,
        path: 'assets/audio/$path',
        duration: Duration(milliseconds: e['durationMs'] as int),
      ),
    );
  }
  if (expected.isNotEmpty) {
    throw const FormatException('Incomplete audio catalog');
  }
  return AudioCatalog(assets);
}
