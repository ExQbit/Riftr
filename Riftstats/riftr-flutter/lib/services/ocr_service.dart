import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/card_model.dart';
import '../models/card_fingerprint.dart';
import 'card_lookup_service.dart';

/// Result of a scan with confidence level.
enum ScanConfidence { high, medium, low }

class OcrMatch {
  final ScanResult? scanResult;
  final RiftCard card;
  final List<RiftCard> alternatives;
  final ScanConfidence confidence;
  final int score;
  final Map<String, int> breakdown;

  const OcrMatch({
    this.scanResult,
    required this.card,
    this.alternatives = const [],
    required this.confidence,
    this.score = 0,
    this.breakdown = const {},
  });
}

/// OCR scanner with multi-point fingerprint scoring.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isProcessing = false;
  bool debugMode = false;

  // ── Regex patterns ──

  /// CN with optional /max: "SFD 097/221", "S0-143", "0GN 022298", "SO-84m"
  /// Requires 2+ digits for CN (1-digit like "OGN 1" is too ambiguous)
  /// Exception: 1 digit OK if followed by / (e.g. "SFD 1/221")
  static final _patternCN = RegExp(
    r'(OGN|SFD|OGS|UNL|SFO|OGM|OG5|OGH|SFE|SF0|0GN|0GS|0G5|O6S|06S|065|O65|D6S|DGS|0N|GN|S0|SO|SD|DGN)\s*[A-Z>]?\s*[·.•:\- ]{0,3}\s*(\d{2,3})([a*b])?',
    caseSensitive: false,
  );

  /// Single-digit CN only if followed by / (e.g. "SFD 1/221")
  static final _patternCNSingleDigit = RegExp(
    r'(OGN|SFD|OGS|UNL|SFO|OGM|OG5|OGH|SFE|SF0|0GN|0GS|0G5|O6S|06S|065|O65|D6S|DGS|0N|GN|S0|SO|SD|DGN)\s*[A-Z>]?\s*[·.•:\- ]{0,3}\s*(\d)([a*b])?\s*/',
    caseSensitive: false,
  );

  /// "FND-249/298" (Project K)
  static final _patternFnd = RegExp(
    r'(FND)\s*[-–\s]?\s*(\d{1,3})([a*b])?\s*/\s*(\d{1,3})',
    caseSensitive: false,
  );

  /// Token CN: "SFD T03", "OGN T01" etc.
  static final _patternTokenCN = RegExp(
    r'(OGN|SFD|OGS|UNL|SFO|OGM|OG5|OGH|SFE|SF0|0GN|0GS|0G5|O6S|06S|065|O65|D6S|DGS|DGN)\s*[·.•:\- ]?\s*T\s*0?(\d{1,2})',
    caseSensitive: false,
  );

  /// Detect set code standalone in text.
  static final _setInText = RegExp(
    r'\b(OGN|SFD|OGS|UNL|FND|SFO|OGM|OGH|SFE)\b',
    caseSensitive: false,
  );

  /// Extract data points from a camera frame without scoring.
  /// Set [tryRotate90] to also try 90° CW for landscape battlefields.
  /// Debug counter for saving OCR input images
  int _ocrDebugFrameCount = 0;

  Future<OcrExtraction?> extractFrame(CameraImage image, CameraDescription camera, {bool tryRotate90 = false}) async {
    if (_isProcessing) return null;
    _isProcessing = true;
    try {
      // Primary: grayscale — ML Kit reads stylized card names better without color
      final grayInput = _convertCameraImage(image, camera, grayscaleOnly: true);
      if (grayInput == null) return null;
      final recognized = await _textRecognizer.processImage(grayInput);

      OcrExtraction? result;
      if (recognized.blocks.isNotEmpty) {
        final allText = recognized.blocks.map((b) => b.text).join(' | ');
        if (debugMode) debugPrint('OCR raw: $allText');
        final allTextLower = allText.toLowerCase();
        final allLines = <String>[];
        final blocks = recognized.blocks.toList()
          ..sort((a, b) => b.boundingBox.top.compareTo(a.boundingBox.top));
        for (final block in blocks) {
          for (final line in block.lines) {
            allLines.add(line.text);
          }
        }
        result = _extract(allLines, allTextLower, recognized);
      }

      // Fallback: color pass if grayscale found no names
      if (result != null && result!.namesFound.isEmpty) {
        final colorInput = _convertCameraImage(image, camera);
        if (colorInput != null) {
          final colorRecognized = await _textRecognizer.processImage(colorInput);
          if (colorRecognized.blocks.isNotEmpty) {
            final colorText = colorRecognized.blocks.map((b) => b.text).join(' | ');
            if (debugMode) debugPrint('OCR color fallback: $colorText');
            final colorLower = colorText.toLowerCase();
            final colorLines = <String>[];
            for (final block in colorRecognized.blocks) {
              for (final line in block.lines) {
                colorLines.add(line.text);
              }
            }
            final colorExtraction = _extract(colorLines, colorLower, colorRecognized);
            if (colorExtraction.namesFound.isNotEmpty) {
              // Merge color names into grayscale result
              result = OcrExtraction(
                setCode: result!.setCode ?? colorExtraction.setCode,
                collectorNumber: result!.collectorNumber ?? colorExtraction.collectorNumber,
                cnSuffix: result!.cnSuffix ?? colorExtraction.cnSuffix,
                cnRaw: result!.cnRaw ?? colorExtraction.cnRaw,
                cnHasSetPrefix: result!.cnHasSetPrefix || colorExtraction.cnHasSetPrefix,
                namesFound: {...result!.namesFound, ...colorExtraction.namesFound},
                keywordsFound: {...result!.keywordsFound, ...colorExtraction.keywordsFound},
                typesFound: {...result!.typesFound, ...colorExtraction.typesFound},
                regionsFound: {...result!.regionsFound, ...colorExtraction.regionsFound},
                manaCost: result!.manaCost ?? colorExtraction.manaCost,
                rawTextLower: '${result!.rawTextLower} ${colorExtraction.rawTextLower}',
                fuzzyTextLower: '${result!.fuzzyTextLower} ${colorExtraction.fuzzyTextLower}',
                softSetHint: result!.softSetHint ?? colorExtraction.softSetHint,
                manaBox: result!.manaBox ?? colorExtraction.manaBox,
                typeBox: result!.typeBox ?? colorExtraction.typeBox,
                nameBox: result!.nameBox ?? colorExtraction.nameBox,
                cnBox: result!.cnBox ?? colorExtraction.cnBox,
                promoDetected: result!.promoDetected || colorExtraction.promoDetected,
              );
            }
          }
        }
      }

      // Try 90° CW for landscape battlefields
      if (tryRotate90) {
        final rot90 = _convertRotated90CW(image, camera);
        if (rot90 != null) {
          final rot90Recognized = await _textRecognizer.processImage(rot90);
          if (rot90Recognized.blocks.isNotEmpty) {
            final rotText = rot90Recognized.blocks.map((b) => b.text).join(' | ');
            if (debugMode) debugPrint('OCR rot90: $rotText');
            final rotLower = rotText.toLowerCase();
            final rotLines = <String>[];
            for (final block in rot90Recognized.blocks) {
              for (final line in block.lines) {
                rotLines.add(line.text);
              }
            }
            final rotExtraction = _extract(rotLines, rotLower, rot90Recognized);
            if (result == null) {
              result = rotExtraction;
            } else {
              // Merge rot90 data INTO existing result
              result = OcrExtraction(
                setCode: result!.setCode ?? rotExtraction.setCode,
                collectorNumber: result!.collectorNumber ?? rotExtraction.collectorNumber,
                cnSuffix: result!.cnSuffix ?? rotExtraction.cnSuffix,
                cnRaw: result!.cnRaw ?? rotExtraction.cnRaw,
                cnHasSetPrefix: result!.cnHasSetPrefix || rotExtraction.cnHasSetPrefix,
                namesFound: {...result!.namesFound, ...rotExtraction.namesFound},
                keywordsFound: {...result!.keywordsFound, ...rotExtraction.keywordsFound},
                typesFound: {...result!.typesFound, ...rotExtraction.typesFound},
                regionsFound: {...result!.regionsFound, ...rotExtraction.regionsFound},
                manaCost: result!.manaCost ?? rotExtraction.manaCost,
                rawTextLower: '${result!.rawTextLower} ${rotExtraction.rawTextLower}',
                fuzzyTextLower: '${result!.fuzzyTextLower} ${rotExtraction.fuzzyTextLower}',
                softSetHint: result!.softSetHint ?? rotExtraction.softSetHint,
              );
            }
          }
        }
      }

      return result;
    } catch (e) {
      debugPrint('OcrService: Error: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a camera image. Returns best OcrMatch or null.
  /// Set [tryFlip] to attempt 180° rotation on failure (slower, use sparingly).
  Future<OcrMatch?> processImage(CameraImage image, CameraDescription camera, {bool tryFlip = false}) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      // Primary: grayscale — ML Kit reads stylized card names better without color
      final grayInput = _convertCameraImage(image, camera, grayscaleOnly: true);
      if (grayInput != null) {
        final grayRecognized = await _textRecognizer.processImage(grayInput);
        final grayMatch = await _analyze(grayRecognized, minScore: 35);
        if (grayMatch != null) return grayMatch;
      }

      // Fallback: color (native YUV) — in case grayscale misses something
      final inputImage = _convertCameraImage(image, camera);
      if (inputImage != null) {
        final recognized = await _textRecognizer.processImage(inputImage);
        final match = await _analyze(recognized, minScore: 35);
        if (match != null) return match;
      }

      if (!tryFlip) return null;

      // Try 180° flip (upside-down cards)
      final flipped = _convertCameraImageFlipped(image, camera);
      if (flipped != null) {
        final flippedRecognized = await _textRecognizer.processImage(flipped);
        final flipMatch = await _analyze(flippedRecognized, minScore: 35);
        if (flipMatch != null) return flipMatch;
      }

      // Try 90° CW (landscape battlefields) — physical pixel rotation
      final rot90 = _convertRotated90CW(image, camera);
      if (rot90 != null) {
        final rot90Recognized = await _textRecognizer.processImage(rot90);
        final rot90Match = await _analyze(rot90Recognized, minScore: 25);
        if (rot90Match != null) return rot90Match;
      }

      return null;
    } catch (e) {
      debugPrint('OcrService: Error: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Multi-point analysis using fingerprint scoring.
  Future<OcrMatch?> _analyze(RecognizedText text, {int minScore = 25}) async {
    if (text.blocks.isEmpty) return null;

    // Collect all text
    final allText = text.blocks.map((b) => b.text).join(' | ');
    if (debugMode) debugPrint('OCR raw: $allText');
    final allTextLower = allText.toLowerCase();

    // Collect lines bottom-first
    final allLines = <String>[];
    final blocks = text.blocks.toList()
      ..sort((a, b) => b.boundingBox.top.compareTo(a.boundingBox.top));
    for (final block in blocks) {
      for (final line in block.lines) {
        allLines.add(line.text);
      }
    }

    // ── Extract all data points ──
    final extraction = _extract(allLines, allTextLower, text);

    // ── Score all candidates (in isolate) ──
    final lookup = CardLookupService.instance;
    final matches = await lookup.findBestMatches(extraction, minScore: minScore);

    if (matches.isEmpty) return null;

    final best = matches.first;
    final card = best.fingerprint.card;

    // Determine confidence
    final confidence = best.score >= 60
        ? ScanConfidence.high
        : best.score >= 40
            ? ScanConfidence.medium
            : ScanConfidence.low;

    debugPrint('OCR MATCH: ${card.name} (${card.setId} #${card.collectorNumber}) '
        'score=${best.score} ${best.breakdown}');

    // Get alternatives (same name, different sets)
    final altFps = lookup.nameIndex[best.fingerprint.nameLower] ?? [];
    final alternatives = altFps
        .where((fp) => fp.cardId != card.id)
        .map((fp) => fp.card)
        .toList();

    return OcrMatch(
      card: card,
      alternatives: alternatives,
      confidence: confidence,
      score: best.score,
      breakdown: best.breakdown,
    );
  }

  /// Extract all recognizable data points from OCR text.
  OcrExtraction _extract(List<String> lines, String allTextLower, RecognizedText recognized) {
    // Remove pipe separators so multi-block names like "production | surge" match
    allTextLower = allTextLower.replaceAll(' | ', ' ');
    final lookup = CardLookupService.instance;

    // 1. CN extraction
    String? setCode;
    String? softSetHint;
    int? collectorNumber;
    String? cnSuffix;
    String? cnRaw;
    bool cnHasSetPrefix = false;

    // OCR misreads 1↔L/l in CN digits: "20L"→"201", "L36"→"136"
    // Only fix L/l AFTER the set code to protect UNL etc.
    final _setCodePattern = RegExp(
      r'(OGN|SFD|OGS|UNL|SFO|OGM|OG5|OGH|SFE|SF0|0GN|0GS|0G5|O6S|06S|065|O65|D6S|DGS|0N|GN|S0|SO|SD|DGN|FND)',
      caseSensitive: false,
    );
    final _fixL = RegExp(r'(?<=\d)[Ll]');
    final _fixLBefore = RegExp(r'[Ll](?=\d)');

    String _fixLineL(String line) {
      final setMatch = _setCodePattern.firstMatch(line);
      if (setMatch != null) {
        // Only fix L/l in the part AFTER the set code
        final prefix = line.substring(0, setMatch.end);
        final rest = line.substring(setMatch.end);
        return prefix + rest.replaceAll(_fixL, '1').replaceAll(_fixLBefore, '1');
      }
      // No set code found — fix entire line (fallback CN path)
      return line.replaceAll(_fixL, '1').replaceAll(_fixLBefore, '1');
    }

    for (final line in lines) {
      final fixedLine = _fixLineL(line);
      if (debugMode) debugPrint('CN scan line: "$fixedLine"${fixedLine != line ? ' (was: "$line")' : ''}');
      // 1a. Standard CN (2+ digits): "SFD 097/221", "S0-143", "0GN 022"
      final m1 = _patternCN.firstMatch(fixedLine);
      if (m1 != null) {
        setCode = CardLookupService.fixSetCode(m1.group(1)!);
        cnRaw = m1.group(2)!;
        collectorNumber = int.tryParse(cnRaw!.replaceFirst(RegExp(r'^0+'), ''));
        cnSuffix = m1.group(3);
        cnHasSetPrefix = true;
        if (debugMode) debugPrint('CN match: set=$setCode cn=$collectorNumber raw="$cnRaw" suffix=$cnSuffix');
        break;
      }
      // 1b. Single-digit CN only if followed by / (e.g. "SFD 1/221")
      final m1b = _patternCNSingleDigit.firstMatch(fixedLine);
      if (m1b != null) {
        setCode = CardLookupService.fixSetCode(m1b.group(1)!);
        cnRaw = m1b.group(2)!;
        collectorNumber = int.tryParse(cnRaw!);
        cnSuffix = m1b.group(3);
        cnHasSetPrefix = true;
        if (debugMode) debugPrint('CN match (1dig): set=$setCode cn=$collectorNumber');
        break;
      }
      // 2. FND: "FND-249/298"
      final m2 = _patternFnd.firstMatch(fixedLine);
      if (m2 != null) {
        setCode = 'FND';
        cnRaw = m2.group(2)!;
        collectorNumber = int.tryParse(cnRaw!.replaceFirst(RegExp(r'^0+'), ''));
        cnSuffix = m2.group(3);
        if (debugMode) debugPrint('CN match (FND): cn=$collectorNumber');
        break;
      }
      // 3. Token CN: "SFD T03"
      final m3 = _patternTokenCN.firstMatch(fixedLine);
      if (m3 != null) {
        setCode = CardLookupService.fixSetCode(m3.group(1)!);
        cnRaw = 'T${m3.group(2)!}';
        collectorNumber = null;
        if (debugMode) debugPrint('CN match (token): set=$setCode raw=$cnRaw');
        break;
      }
    }

    // 1c. Rune CN: "SFD R01", "SFO RI3", "SFD RDL"
    // Rune digits are 01-06: OCR misreads 0→I/O/D, 1→L
    if (collectorNumber == null) {
      final runeCN = RegExp(
        r'(OGN|SFD|OGS|UNL|SFO|OGM|OG5|OGH|SFE|SF0|0GN|0GS|0G5|O6S|06S|065|O65|D6S|DGS|0N|GN|S0|SO|SD|DGN)\s*[-·.•:\s]{0,3}R\s*([0-9IODLl]{1,2})([a-z*])?',
        caseSensitive: false,
      );
      for (final line in lines) {
        final m = runeCN.firstMatch(line);
        if (m != null) {
          setCode = CardLookupService.fixSetCode(m.group(1)!);
          var runeDigits = m.group(2)!.toUpperCase();
          runeDigits = runeDigits
              .replaceAll('I', '0').replaceAll('O', '0')
              .replaceAll('D', '0').replaceAll('L', '1');
          final runeNum = int.tryParse(runeDigits);
          if (runeNum == null || runeNum < 1 || runeNum > 6) continue; // R01-R06 only
          cnRaw = 'R${runeDigits.padLeft(2, '0')}';
          collectorNumber = runeNum;
          cnSuffix = m.group(3);
          cnHasSetPrefix = true;
          if (debugMode) debugPrint('CN match (rune): set=$setCode cn=$collectorNumber raw=$cnRaw digits="${m.group(2)}"→$runeDigits');
          break;
        }
      }
    }

    // 1d. Soft-alias: 3-letter/digit prefix not in strict list, Levenshtein 1 to known set
    if (collectorNumber == null) {
      final softCN = RegExp(r'([A-Z0-9]{3})\s*[·.•:\- ]{0,3}\s*(\d{2,3})([a*b])?');
      for (final line in lines) {
        final fixedLine = _fixLineL(line);
        final m = softCN.firstMatch(fixedLine);
        if (m != null) {
          final rawPrefix = m.group(1)!.toUpperCase();
          final resolved = CardLookupService.softAliasResolve(rawPrefix);
          if (resolved != null) {
            softSetHint = resolved;
            cnRaw = m.group(2)!;
            collectorNumber = int.tryParse(cnRaw!.replaceFirst(RegExp(r'^0+'), ''));
            cnSuffix = m.group(3);
            cnHasSetPrefix = true;
            if (debugMode) debugPrint('CN soft-alias: "$rawPrefix"→$resolved cn=$collectorNumber');
            break;
          }
        }
      }
    }

    // 4. Fallback: CN without set prefix: "-076/221", "076/221", "180a/221"
    // Only on longer text (>50 chars) to avoid false matches on garbled flip-frames
    if (collectorNumber == null && allTextLower.length > 50) {
      final noSetCN = RegExp(r'[-–]?\s*(\d{2,3})([a*b])?\s*/\s*(\d{2,3})');
      for (final line in lines) {
        // No set code in fallback → fix L/l on entire line
        final fixedLine = line.replaceAll(_fixL, '1').replaceAll(_fixLBefore, '1');
        final m = noSetCN.firstMatch(fixedLine);
        if (m != null) {
          cnRaw = m.group(1)!;
          collectorNumber = int.tryParse(cnRaw!.replaceFirst(RegExp(r'^0+'), ''));
          cnSuffix ??= m.group(2);
          if (debugMode) debugPrint('CN fallback (no set): cn=$collectorNumber raw="$cnRaw" suffix=$cnSuffix');
          break;
        }
      }
    }

    if (debugMode && collectorNumber == null) debugPrint('CN: no match found');

    // Standalone set code detection — also catches OCR misreads like "O6N", "S0"
    if (setCode == null) {
      final setMatch = _setInText.firstMatch(allTextLower);
      if (setMatch != null) {
        setCode = CardLookupService.fixSetCode(setMatch.group(1)!);
      }
    }
    // Extended fuzzy set detection in raw text
    if (setCode == null) {
      if (allTextLower.contains('o6n') || allTextLower.contains('0gn') || allTextLower.contains('ogh')) {
        setCode = 'OGN';
      } else if (allTextLower.contains('sfo') || allTextLower.contains('sf0') || allTextLower.contains('sfe')) {
        setCode = 'SFD';
      } else if (allTextLower.contains('og5') || allTextLower.contains('0gs')) {
        setCode = 'OGS';
      }
    }

    // 2. Find known card names in text (exact match, min 4 chars)
    // No blocklist — score system resolves conflicts automatically
    // Use pipe-free text for name search: ML Kit may split "Eye of the | Herald"
    // into separate blocks, breaking contains() for multi-word names.
    final searchableNameText = allTextLower
        .replaceAll('|', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final namesFound = <String>{};
    for (final name in lookup.nameIndex.keys) {
      if (name.length >= 4 && searchableNameText.contains(name)) {
        namesFound.add(name);
      }
    }

    // 3. Find known keywords in text (exact only — fuzzy moved to _scoreCandidate)
    final keywordsFound = <String>{};
    for (final kw in lookup.allKeywords) {
      if (kw.length >= 4 && allTextLower.contains(kw)) {
        keywordsFound.add(kw);
      }
    }

    // 4. Find card types — ONLY match UPPERCASE standalone type headers
    // "SPELL", "CHAMPION UNIT", "UNIT", "GEAR", "RUNE", "BATTLEFIELD"
    // NOT "unit" in "unit token" or "gear token" (lowercase in card text)
    final typesFound = <String>{};
    final allTextOriginal = recognized.blocks.map((b) => b.text).join(' | ');
    for (final t in CardLookupService.cardTypes) {
      final upper = t.toUpperCase();
      if (allTextOriginal.contains(upper)) {
        typesFound.add(t);
      } else {
        for (final v in CardLookupService.typeVariants(t)) {
          if (allTextOriginal.contains(v.toUpperCase())) {
            typesFound.add(t);
            break;
          }
        }
      }
    }

    // Equipment signal: "attach this to a unit" appears on every Equipment card
    if (!typesFound.contains('gear') && allTextLower.contains('attach')) {
      typesFound.add('gear');
    }
    // EQUIP partial match for garbled EQUIPMENT: "EOUIP", "EQUIP", "EPO"
    if (!typesFound.contains('gear')) {
      if (allTextOriginal.contains('EQUIP') || allTextOriginal.contains('EOUIP')) {
        typesFound.add('gear');
      }
    }

    // 4b. Find bounding box for the type line
    List<double>? typeBox;
    if (typesFound.isNotEmpty) {
      for (final block in recognized.blocks) {
        final blockUpper = block.text.toUpperCase();
        for (final t in typesFound) {
          if (blockUpper.contains(t.toUpperCase())) {
            final r = block.boundingBox;
            typeBox = [r.left, r.top, r.right, r.bottom];
            break;
          }
        }
        if (typeBox != null) break;
      }
    }

    // 5. Find regions/factions (exact only — fuzzy too expensive per-frame)
    final regionsFound = <String>{};
    for (final r in CardLookupService.regionNames) {
      if (allTextLower.contains(r)) {
        regionsFound.add(r);
      }
    }

    // 5b. Promo badge detection — search for "PROMO" text on card
    // The promo badge has curved "PROMO" text above the rarity gem.
    // Also catch common OCR misreads: "PROM0", "PR0MO", "PROMD"
    bool promoDetected = false;
    final promoPatterns = ['promo', 'prom0', 'pr0mo', 'promd', 'promq'];
    for (final p in promoPatterns) {
      if (allTextLower.contains(p)) {
        promoDetected = true;
        break;
      }
    }
    // Also check individual blocks for short "PROMO"-like text
    if (!promoDetected) {
      for (final block in recognized.blocks) {
        final t = block.text.trim().toLowerCase();
        if (t.length >= 4 && t.length <= 7) {
          for (final p in promoPatterns) {
            if (t.contains(p)) {
              promoDetected = true;
              break;
            }
          }
          if (promoDetected) break;
        }
      }
    }
    if (debugMode && promoDetected) debugPrint('OCR: PROMO badge detected in text!');

    // 6. Mana cost — look for single digit at start of a block (often top-left of card)
    int? manaCost;
    List<double>? manaBox;
    if (recognized.blocks.isNotEmpty) {
      final topBlocks = recognized.blocks.toList()
        ..sort((a, b) {
          final dy = a.boundingBox.top.compareTo(b.boundingBox.top);
          return dy != 0 ? dy : a.boundingBox.left.compareTo(b.boundingBox.left);
        });
      for (final block in topBlocks.take(3)) {
        final trimmed = block.text.trim();
        if (trimmed.length <= 2 && RegExp(r'^\d{1,2}$').hasMatch(trimmed)) {
          manaCost = int.tryParse(trimmed);
          final r = block.boundingBox;
          manaBox = [r.left, r.top, r.right, r.bottom];
          break;
        }
      }
    }

    // 7. OCR-Anchor bounding boxes for pHash card rect calculation
    // Find the bounding box of the recognized card name and CN in the camera frame
    List<double>? nameBox;
    List<double>? cnBox;

    // Find name: search blocks for the first word(s) of the longest matching name
    if (namesFound.isNotEmpty) {
      final bestName = namesFound.reduce((a, b) => a.length > b.length ? a : b);
      // Use first two words for stricter match ("eye of" not just "eye")
      final words = bestName.toLowerCase().split(' ').where((w) => w.length >= 2).toList();
      final searchPrefix = words.take(2).join(' ');

      if (searchPrefix.isNotEmpty) {
        for (final block in recognized.blocks) {
          final blockText = block.text.toLowerCase().replaceAll('\n', ' ');
          if (blockText.contains(searchPrefix)) {
            final r = block.boundingBox;
            nameBox = [r.left, r.top, r.right, r.bottom];
            break;
          }
        }
      }
    }

    // Find CN: search blocks for CN text that is BELOW the name anchor
    // On a card, the CN is always below the name. Pick the closest one.
    if (cnRaw != null) {
      final nameBottomY = nameBox != null ? nameBox[3] : 0.0;
      double bestDist = double.infinity;
      for (final block in recognized.blocks) {
        if (block.text.contains(cnRaw!)) {
          final r = block.boundingBox;
          final blockCenterY = (r.top + r.bottom) / 2;
          // CN must be below name (or at least not above it)
          if (nameBox != null && blockCenterY < nameBottomY - 20) continue;
          // Pick the closest CN below the name
          final dist = (blockCenterY - nameBottomY).abs();
          if (dist < bestDist) {
            bestDist = dist;
            cnBox = [r.left, r.top, r.right, r.bottom];
          }
        }
      }
    }

    return OcrExtraction(
      setCode: setCode,
      collectorNumber: collectorNumber,
      cnSuffix: cnSuffix,
      cnRaw: cnRaw,
      cnHasSetPrefix: cnHasSetPrefix,
      namesFound: namesFound,
      keywordsFound: keywordsFound,
      typesFound: typesFound,
      regionsFound: regionsFound,
      manaCost: manaCost,
      rawTextLower: allTextLower,
      fuzzyTextLower: allTextLower, // single frame = same as raw
      softSetHint: softSetHint,
      manaBox: manaBox,
      typeBox: typeBox,
      nameBox: nameBox,
      cnBox: cnBox,
      promoDetected: promoDetected,
    );
  }

  // ══════════════════════════════════════════════
  // ── OCR Debug: save input image with block boxes ──
  // ══════════════════════════════════════════════

  /// Save the camera Y-plane as grayscale PNG with all OCR block bounding boxes drawn.
  void _saveOcrDebugImage(CameraImage image, RecognizedText recognized) async {
    try {
      final width = image.width;
      final height = image.height;
      final yPlane = image.planes.first.bytes;
      final stride = image.planes.first.bytesPerRow;

      // Build RGBA from Y-plane
      final rgba = Uint8List(width * height * 4);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final v = yPlane[y * stride + x];
          final idx = (y * width + x) * 4;
          rgba[idx] = v; rgba[idx + 1] = v; rgba[idx + 2] = v; rgba[idx + 3] = 255;
        }
      }

      // Draw each block's bounding box in different colors
      final colors = [
        [255, 0, 0], [0, 255, 0], [0, 0, 255], [255, 255, 0],
        [255, 0, 255], [0, 255, 255], [255, 128, 0], [128, 0, 255],
      ];

      for (int bi = 0; bi < recognized.blocks.length; bi++) {
        final block = recognized.blocks[bi];
        final r = block.boundingBox;
        final color = colors[bi % colors.length];
        final bx = r.left.round().clamp(0, width - 1);
        final by = r.top.round().clamp(0, height - 1);
        final bw = r.width.round().clamp(1, width - bx);
        final bh = r.height.round().clamp(1, height - by);

        // Draw border (2px)
        for (int t = 0; t < 2; t++) {
          for (int x = bx; x < bx + bw && x < width; x++) {
            for (final yy in [by + t, by + bh - 1 - t]) {
              if (yy >= 0 && yy < height) {
                final idx = (yy * width + x) * 4;
                rgba[idx] = color[0]; rgba[idx + 1] = color[1]; rgba[idx + 2] = color[2];
              }
            }
          }
          for (int y = by; y < by + bh && y < height; y++) {
            for (final xx in [bx + t, bx + bw - 1 - t]) {
              if (xx >= 0 && xx < width) {
                final idx = (y * width + xx) * 4;
                rgba[idx] = color[0]; rgba[idx + 1] = color[1]; rgba[idx + 2] = color[2];
              }
            }
          }
        }

        debugPrint('OCR BLOCK[$bi]: "${block.text}" at (${bx},${by}) ${bw}x${bh}');
      }

      // Save as PNG
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, completer.complete);
      final img = await completer.future;
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final docsDir = await getApplicationDocumentsDirectory();
        final dir = Directory('${docsDir.path}/phash_debug');
        if (!dir.existsSync()) dir.createSync(recursive: true);
        final ts = DateTime.now().millisecondsSinceEpoch;
        final path = '${dir.path}/ocr_debug_${ts}.png';
        await File(path).writeAsBytes(byteData.buffer.asUint8List());
        debugPrint('OCR DEBUG IMAGE saved: $path (${recognized.blocks.length} blocks)');
      }
      img.dispose();
    } catch (e) {
      debugPrint('OCR debug image save failed: $e');
    }
  }

  // ══════════════════════════════════════════════
  // ── Camera image conversion ──
  // ══════════════════════════════════════════════

  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera, {bool grayscaleOnly = false}) {
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;
    if (image.planes.isEmpty) return null;

    if (grayscaleOnly) {
      // Convert Y-plane to BGRA grayscale — ML Kit needs a valid image format.
      // Y-only as NV21 crashes because ML Kit expects UV data after Y.
      final yBytes = image.planes.first.bytes;
      final stride = image.planes.first.bytesPerRow;
      final width = image.width;
      final height = image.height;
      final bgra = Uint8List(width * height * 4);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final v = yBytes[y * stride + x];
          final idx = (y * width + x) * 4;
          bgra[idx] = v;     // B
          bgra[idx + 1] = v; // G
          bgra[idx + 2] = v; // R
          bgra[idx + 3] = 255; // A
        }
      }
      return InputImage.fromBytes(
        bytes: bgra,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final Uint8List bytes;
    if (image.planes.length > 1) {
      final allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
    } else {
      bytes = image.planes.first.bytes;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Physically rotate Y-plane 90° CW for landscape battlefield detection.
  /// Transposes rows↔cols: pixel at (x,y) moves to (height-1-y, x).
  InputImage? _convertRotated90CW(CameraImage image, CameraDescription camera) {
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;
    if (image.planes.isEmpty) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final width = image.width;
    final height = image.height;
    final yPlane = image.planes.first;
    final yBytes = yPlane.bytes;
    final bytesPerRow = yPlane.bytesPerRow;

    // After 90° CW: new dimensions are height × width
    final newWidth = height;
    final newHeight = width;
    final rotated = Uint8List(newWidth * newHeight);

    for (int y = 0; y < height; y++) {
      final srcRow = y * bytesPerRow;
      for (int x = 0; x < width; x++) {
        // 90° CW: (x, y) → (height-1-y, x) in new image
        // new image: row = x, col = height-1-y
        final dstIdx = x * newWidth + (height - 1 - y);
        if (srcRow + x < yBytes.length && dstIdx < rotated.length) {
          rotated[dstIdx] = yBytes[srcRow + x];
        }
      }
    }

    // For multi-plane YUV: only Y is rotated, UV planes passed as-is
    // ML Kit primarily uses Y for text recognition
    final Uint8List allBytes;
    if (image.planes.length > 1) {
      final buffer = WriteBuffer();
      buffer.putUint8List(rotated);
      for (int i = 1; i < image.planes.length; i++) {
        buffer.putUint8List(image.planes[i].bytes);
      }
      allBytes = buffer.done().buffer.asUint8List();
    } else {
      allBytes = rotated;
    }

    return InputImage.fromBytes(
      bytes: allBytes,
      metadata: InputImageMetadata(
        size: Size(newWidth.toDouble(), newHeight.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: newWidth,
      ),
    );
  }

  /// Pixel-level 180° flip for upside-down cards.
  InputImage? _convertCameraImageFlipped(CameraImage image, CameraDescription camera) {
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;
    if (image.planes.isEmpty) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final width = image.width;
    final height = image.height;
    final yPlane = image.planes.first;
    final yBytes = yPlane.bytes;
    final bytesPerRow = yPlane.bytesPerRow;

    final flipped = Uint8List(yBytes.length);
    for (int y = 0; y < height; y++) {
      final srcRow = y * bytesPerRow;
      final dstRow = (height - 1 - y) * bytesPerRow;
      for (int x = 0; x < bytesPerRow; x++) {
        flipped[dstRow + (bytesPerRow - 1 - x)] = yBytes[srcRow + x];
      }
    }

    final Uint8List allBytes;
    if (image.planes.length > 1) {
      final buffer = WriteBuffer();
      buffer.putUint8List(flipped);
      for (int i = 1; i < image.planes.length; i++) {
        buffer.putUint8List(image.planes[i].bytes);
      }
      allBytes = buffer.done().buffer.asUint8List();
    } else {
      allBytes = flipped;
    }

    return InputImage.fromBytes(
      bytes: allBytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      ),
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
