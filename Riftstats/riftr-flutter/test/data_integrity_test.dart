import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Map<String, dynamic>> cards;
  late Map<String, dynamic>? metadata;

  setUpAll(() {
    final file = File('assets/cards.json');
    final jsonList = json.decode(file.readAsStringSync()) as List<dynamic>;
    metadata = jsonList
        .whereType<Map<String, dynamic>>()
        .where((item) => item['_type'] == 'metadata')
        .firstOrNull;
    cards = jsonList
        .whereType<Map<String, dynamic>>()
        .where((item) => item['_type'] != 'metadata')
        .toList();
  });

  group('Card Data Integrity', () {
    test('Alle Overnumbered/Alt Art Karten haben Rarity Showcase', () {
      // Regel: overnumbered=true → immer Showcase.
      // alternate_art=true in BASE sets (OGN, OGS, SFD, UNL) → immer Showcase.
      // alternate_art=true in PROMO sets (OGNX, SFDX, OGSX) → Ausnahme erlaubt:
      //   Promo-Karten können alternate_art haben und trotzdem ihre Basis-Rarity behalten
      //   (z.B. Recruit OGNX/271a = Alt Art Common).
      const promoSets = {'OGNX', 'SFDX', 'OGSX'};
      final bad = <String>[];
      for (final c in cards) {
        final meta = c['metadata'] as Map<String, dynamic>? ?? {};
        final rarity = (c['classification'] as Map?)?['rarity'] as String? ?? '';
        final setId = (c['set'] as Map?)?['set_id'] as String? ?? '';
        final isOver = meta['overnumbered'] == true;
        final isAlt = meta['alternate_art'] == true;

        // overnumbered muss Showcase oder Ultimate sein (Baron Nashor = first Ultimate Rare)
        if (isOver && rarity != 'Showcase' && rarity != 'Ultimate') {
          bad.add('${c['name']} ($setId/${c['collector_number']}) overnumbered but rarity=$rarity');
        }
        // alternate_art in Promo-Sets darf Basis-Rarity behalten → kein Check
        if (isAlt && !promoSets.contains(setId) && rarity != 'Showcase') {
          bad.add('${c['name']} ($setId/${c['collector_number']}) alternate_art but rarity=$rarity');
        }
      }
      expect(bad, isEmpty, reason: 'Overnumbered/Alt Art without Showcase:\n${bad.join('\n')}');
    });

    test('Collector Number Suffixe sind korrekt', () {
      final bad = <String>[];
      for (final c in cards) {
        final col = (c['collector_number'] ?? '').toString();
        final meta = c['metadata'] as Map<String, dynamic>? ?? {};
        if (col.isEmpty || col == 'null') continue;

        if (col.endsWith('*') && meta['signature'] != true) {
          bad.add('${c['name']} col=$col has * but signature=${meta['signature']}');
        }
        // 'a' suffix should be alternate_art OR known Arcane variants
        // 'b' suffix is for rune-promos or Arcane where 'a' is taken
        // No unknown suffixes
        final suffix = col.replaceAll(RegExp(r'^[0-9A-Z]+'), '');
        if (suffix.isNotEmpty && !['a', 'b', '*'].contains(suffix)) {
          bad.add('${c['name']} col=$col has unknown suffix "$suffix"');
        }
      }
      expect(bad, isEmpty, reason: 'Suffix issues:\n${bad.join('\n')}');
    });

    test('Keine doppelten UUIDs', () {
      final ids = <String>{};
      final dupes = <String>[];
      for (final c in cards) {
        final id = c['id'] as String? ?? '';
        if (id.isEmpty) continue;
        if (!ids.add(id)) {
          dupes.add('${c['name']} id=$id');
        }
      }
      expect(dupes, isEmpty, reason: 'Duplicate UUIDs:\n${dupes.join('\n')}');
    });

    test('Keine doppelten Set+CollectorNumber+Rarity Kombinationen', () {
      // Metal cards share Col# with standard promos — differentiated by rarity
      final seen = <String>{};
      final dupes = <String>[];
      for (final c in cards) {
        final setId = (c['set'] as Map?)?['set_id'] as String? ?? '';
        final col = (c['collector_number'] ?? '').toString();
        final rarity = (c['classification'] as Map?)?['rarity'] as String? ?? '';
        if (col.isEmpty || col == 'null') continue;
        final key = '$setId|$col|$rarity';
        if (!seen.add(key)) {
          dupes.add('${c['name']} $key');
        }
      }
      expect(dupes, isEmpty, reason: 'Duplicate Set+Col#+Rarity:\n${dupes.join('\n')}');
    });

    test('Jedes Basis-Set hat ein releaseDate in Metadata', () {
      expect(metadata, isNotNull, reason: 'No metadata entry in cards.json');
      final sets = metadata!['sets'] as Map<String, dynamic>? ?? {};

      // Collect all base set IDs from cards
      final baseSets = cards
          .map((c) => (c['set'] as Map?)?['set_id'] as String?)
          .whereType<String>()
          .where((s) => !s.endsWith('X')) // Exclude promo sets
          .toSet();

      for (final setId in baseSets) {
        expect(sets.containsKey(setId), isTrue,
            reason: 'Set $setId missing from metadata.sets');
        final setData = sets[setId] as Map?;
        expect(setData?['releaseDate'], isNotNull,
            reason: 'Set $setId has no releaseDate');
      }
    });

    test('Rarity ist ein bekannter Wert', () {
      const validRarities = {'Common', 'Uncommon', 'Rare', 'Epic', 'Showcase', 'Ultimate', 'Metal', 'Promo', 'Token'};
      final bad = <String>[];
      for (final c in cards) {
        final rarity = (c['classification'] as Map?)?['rarity'] as String? ?? '';
        if (rarity.isNotEmpty && !validRarities.contains(rarity)) {
          bad.add('${c['name']} (${(c['set'] as Map?)?['set_id']}/${c['collector_number']}) rarity=$rarity');
        }
      }
      expect(bad, isEmpty, reason: 'Unknown rarities:\n${bad.join('\n')}');
    });

    test('Alle Karten haben Pflichtfelder (id, name, set_id, rarity)', () {
      final bad = <String>[];
      for (final c in cards) {
        final id = c['id'] as String? ?? '';
        final name = c['name'] as String? ?? '';
        final setId = (c['set'] as Map?)?['set_id'] as String? ?? '';
        final rarity = (c['classification'] as Map?)?['rarity'] as String? ?? '';

        if (id.isEmpty) bad.add('$name: missing id');
        if (name.isEmpty) bad.add('(unnamed card): missing name');
        if (setId.isEmpty) bad.add('$name: missing set_id');
        if (rarity.isEmpty) bad.add('$name ($setId): missing rarity');
      }
      expect(bad, isEmpty, reason: 'Cards missing required fields:\n${bad.join('\n')}');
    });

    test('display_name ist bei allen released Karten vorhanden und nicht leer', () {
      // UNL is pre-release — display_name may not be populated yet.
      const preReleaseSets = {'UNL'};
      final bad = <String>[];
      for (final c in cards) {
        final setId = (c['set'] as Map?)?['set_id'] as String? ?? '';
        if (preReleaseSets.contains(setId)) continue;
        final displayName = c['display_name'] as String? ?? '';
        if (displayName.isEmpty) {
          bad.add('${c['name']} ($setId): missing display_name');
        }
      }
      expect(bad, isEmpty, reason: 'Released cards with missing display_name:\n${bad.join('\n')}');
    });

    test('Orientation ist portrait oder landscape', () {
      const valid = {'portrait', 'landscape'};
      final bad = <String>[];
      for (final c in cards) {
        final orientation = c['orientation'] as String? ?? '';
        if (orientation.isNotEmpty && !valid.contains(orientation)) {
          bad.add('${c['name']}: orientation="$orientation"');
        }
      }
      expect(bad, isEmpty, reason: 'Cards with invalid orientation:\n${bad.join('\n')}');
    });

    test('Set-IDs sind bekannte Werte', () {
      const knownSets = {'OGN', 'OGS', 'SFD', 'UNL', 'OGNX', 'SFDX', 'OGSX'};
      final bad = <String>[];
      for (final c in cards) {
        final setId = (c['set'] as Map?)?['set_id'] as String? ?? '';
        if (setId.isEmpty) continue;
        if (!knownSets.contains(setId)) {
          bad.add('${c['name']}: set_id="$setId"');
        }
      }
      expect(bad, isEmpty, reason: 'Cards with unknown set_id:\n${bad.join('\n')}');
    });

    test('classification.domain ist immer eine Liste', () {
      final bad = <String>[];
      for (final c in cards) {
        final classification = c['classification'] as Map?;
        if (classification == null) continue;
        final domain = classification['domain'];
        if (domain != null && domain is! List) {
          bad.add('${c['name']}: domain is ${domain.runtimeType}');
        }
      }
      expect(bad, isEmpty, reason: 'Cards with non-list domain:\n${bad.join('\n')}');
    });

    test('tags ist immer eine Liste', () {
      final bad = <String>[];
      for (final c in cards) {
        final tags = c['tags'];
        if (tags != null && tags is! List) {
          bad.add('${c['name']}: tags is ${tags.runtimeType}');
        }
      }
      expect(bad, isEmpty, reason: 'Cards with non-list tags:\n${bad.join('\n')}');
    });

    test('Alle Promo-Sets Karten haben korrekte Basis-Rarity', () {
      // Build base rarity lookup
      final baseRarity = <String, String>{};
      for (final c in cards) {
        final setId = (c['set'] as Map?)?['set_id'] as String? ?? '';
        if (!['OGN', 'SFD', 'OGS', 'UNL'].contains(setId)) continue;
        final meta = c['metadata'] as Map<String, dynamic>? ?? {};
        if (meta['alternate_art'] == true || meta['overnumbered'] == true || meta['signature'] == true) continue;
        final name = c['name'] as String? ?? '';
        final rarity = (c['classification'] as Map?)?['rarity'] as String? ?? '';
        baseRarity.putIfAbsent(name, () => rarity);
      }

      // OGS Starter legends have different names
      baseRarity.putIfAbsent('Annie, Dark Child', () => 'Rare');
      baseRarity.putIfAbsent('Master Yi, Wuju Bladesman', () => 'Rare');
      baseRarity.putIfAbsent('Lux, Lady of Luminosity', () => 'Rare');
      baseRarity.putIfAbsent('Garen, Might of Demacia', () => 'Rare');

      final bad = <String>[];
      for (final c in cards) {
        final setId = (c['set'] as Map?)?['set_id'] as String? ?? '';
        if (!['OGNX', 'SFDX', 'OGSX'].contains(setId)) continue;
        final meta = c['metadata'] as Map<String, dynamic>? ?? {};
        if (meta['overnumbered'] == true || meta['alternate_art'] == true || meta['signature'] == true) continue;
        if (meta['metal'] == true) continue; // Metal has its own rarity

        final name = c['name'] as String? ?? '';
        final rarity = (c['classification'] as Map?)?['rarity'] as String? ?? '';
        final expected = baseRarity[name];
        // Showcase on a promo is OK if the card is genuinely Showcase (special promo art)
        // Only flag if Showcase but base card isn't Showcase and it's clearly wrong
        if (expected != null && expected != 'Showcase' && rarity == 'Showcase' && rarity != expected) {
          // Allow known Showcase promos (GG EZ Teemo, Project K, Champion-Variants, etc.)
          final col = (c['collector_number'] ?? '').toString();
          final displayName = (c['display_name'] ?? '').toString();
          // 2026-04-30: "(... Champion)"-Suffix kennzeichnet Champion-Showcase-Variants
          // (z.B. "Edge of Night (SFDX Champion)") — legitime Showcase-Variants,
          // nicht falsche Daten. Vorher schlug der Test hier auf.
          final isKnownShowcasePromo = col == 'FND196' ||
              displayName.contains('GG EZ') ||
              displayName.contains('Champion)');
          if (!isKnownShowcasePromo) {
            bad.add('$name ($setId) rarity=$rarity expected=$expected');
          }
        }
      }
      expect(bad, isEmpty, reason: 'Promo cards with wrong Showcase rarity:\n${bad.join('\n')}');
    });
  });
}
