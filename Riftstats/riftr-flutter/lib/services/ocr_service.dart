import 'dart:typed_data';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
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

  /// Last extraction from processImage — exposed so scanner can grab boxes from WAITING state
  OcrExtraction? lastExtraction;
  /// Best mana box seen across all processImage calls — sticky because ML Kit
  /// only reads the mana digit in early frames before the full card is visible
  List<double>? _bestManaBox;
  int? _bestManaCost;

  /// Identifier for the rotation/conversion strategy that most recently
  /// succeeded. `null` means default (metadata sensorOrientation, no physical
  /// rotation). Other values: "metadata-0deg", "physical-90cw", "physical-180"
  /// — used by extractFrame to skip straight to the strategy that worked in
  /// WAITING (cheaper than re-discovering each SCANNING frame). Reset on MOTION.
  String? _lastWorkingAltStrategy;

  /// Reset sticky state when scanning a new card (sticky mana, last extraction,
  /// and the remembered alt-rotation strategy — battlefield-detected rotation
  /// must not carry over into scanning a portrait card next).
  void resetStickyMana() {
    _bestManaBox = null;
    _bestManaCost = null;
    lastExtraction = null;
    _lastWorkingAltStrategy = null;
  }

  /// Run OCR on a raw BGRA image crop. Returns recognized text blocks.
  Future<RecognizedText?> recognizeCrop(Uint8List bgra, int width, int height) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: bgra,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );
      return await _textRecognizer.processImage(inputImage);
    } catch (e) {
      debugPrint('OCR recognizeCrop error: $e');
      return null;
    }
  }

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
  /// Rotation handling is internal — uses [_lastWorkingRotation] (set by
  /// processImage on WAITING match) and falls back to alt rotations when no
  /// text is recognized (covers landscape battlefields after a portrait scan).

  Future<OcrExtraction?> extractFrame(CameraImage image, CameraDescription camera) async {
    if (_isProcessing) return null;
    _isProcessing = true;
    try {
      // Use the strategy that succeeded most recently (null = default
      // sensorOrientation rotation, no physical work). Auto-discover via
      // alt-rotation fallback if primary returns nothing matchable —
      // covers MOTION→SCANNING path with no preceding WAITING phase
      // (e.g., scanning a battlefield right after a portrait card).
      OcrExtraction? result = await _runExtractionWithStrategy(
          image, camera, _lastWorkingAltStrategy);

      // Trigger alt rotations whenever the primary didn't identify a card.
      // Length-of-rawText is NOT a useful trigger here: an upside-down
      // portrait card may produce 50+ chars of garbled-but-non-empty text
      // that fools the length check (beta-test 2026-05-02 evidence).
      // What matters: did we find a known card name or a CN? If not, try alts.
      final primaryFailed = result == null ||
          (result.namesFound.isEmpty && result.collectorNumber == null);
      if (primaryFailed) {
        const altStrategies = ['metadata-0deg', 'physical-90cw', 'physical-180'];
        for (final strat in altStrategies) {
          if (strat == _lastWorkingAltStrategy) continue;
          final altResult = await _runExtractionWithStrategy(image, camera, strat);
          if (altResult != null &&
              (altResult.namesFound.isNotEmpty ||
               altResult.collectorNumber != null)) {
            _lastWorkingAltStrategy = strat;
            if (debugMode) {
              debugPrint('OCR extract: switched strategy to "$strat" '
                  '(found ${altResult.namesFound.length} names, cn=${altResult.collectorNumber})');
            }
            result = altResult;
            break;
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

  /// Build the InputImage for a given strategy:
  ///   null            → default (metadata sensorOrientation, no physical work)
  ///   "metadata-0deg" → metadata rotation0deg, no physical work
  ///   "physical-90cw" → physical 90° CW Y-plane rotation + metadata 0deg
  ///   "physical-180"  → physical 180° Y-plane rotation + metadata 0deg
  InputImage? _buildInputForStrategy(
    CameraImage image,
    CameraDescription camera,
    String? strategy, {
    bool grayscaleOnly = true,
  }) {
    switch (strategy) {
      case null:
        return _convertCameraImage(image, camera, grayscaleOnly: grayscaleOnly);
      case 'metadata-0deg':
        return _convertCameraImage(image, camera,
            grayscaleOnly: grayscaleOnly,
            rotation: InputImageRotation.rotation0deg);
      case 'physical-90cw':
        return _convertPhysicallyRotated(image, 90);
      case 'physical-180':
        return _convertPhysicallyRotated(image, 180);
    }
    return null;
  }

  /// Run a single grayscale+color extraction pass with the given strategy.
  Future<OcrExtraction?> _runExtractionWithStrategy(
    CameraImage image,
    CameraDescription camera,
    String? strategy,
  ) async {
    final grayInput = _buildInputForStrategy(image, camera, strategy);
    if (grayInput == null) return null;
    final recognized = await _textRecognizer.processImage(grayInput);

    OcrExtraction? result;
    if (recognized.blocks.isNotEmpty) {
      final allText = recognized.blocks.map((b) => b.text).join(' | ');
      if (debugMode) debugPrint('OCR raw [${strategy ?? "default"}]: $allText');
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

    // Color fallback if grayscale found no names — only for the default
    // strategy (alt strategies are already low-confidence; doing color on
    // top would multiply cost). Plus the physical-rotation strategies
    // already produce a BGRA buffer, no native YUV available.
    if (strategy == null && result != null && result.namesFound.isEmpty) {
      final colorInput = _convertCameraImage(image, camera);
      if (colorInput != null) {
        final colorRecognized = await _textRecognizer.processImage(colorInput);
        if (colorRecognized.blocks.isNotEmpty) {
          final colorText = colorRecognized.blocks.map((b) => b.text).join(' | ');
          if (debugMode) debugPrint('OCR color fallback [default]: $colorText');
          final colorLower = colorText.toLowerCase();
          final colorLines = <String>[];
          for (final block in colorRecognized.blocks) {
            for (final line in block.lines) {
              colorLines.add(line.text);
            }
          }
          final colorExtraction = _extract(colorLines, colorLower, colorRecognized);
          if (colorExtraction.namesFound.isNotEmpty) {
            result = OcrExtraction(
              setCode: result.setCode ?? colorExtraction.setCode,
              collectorNumber: result.collectorNumber ?? colorExtraction.collectorNumber,
              cnSuffix: result.cnSuffix ?? colorExtraction.cnSuffix,
              cnRaw: result.cnRaw ?? colorExtraction.cnRaw,
              cnHasSetPrefix: result.cnHasSetPrefix || colorExtraction.cnHasSetPrefix,
              namesFound: {...result.namesFound, ...colorExtraction.namesFound},
              keywordsFound: {...result.keywordsFound, ...colorExtraction.keywordsFound},
              typesFound: {...result.typesFound, ...colorExtraction.typesFound},
              regionsFound: {...result.regionsFound, ...colorExtraction.regionsFound},
              manaCost: result.manaCost ?? colorExtraction.manaCost,
              rawTextLower: '${result.rawTextLower} ${colorExtraction.rawTextLower}',
              fuzzyTextLower: '${result.fuzzyTextLower} ${colorExtraction.fuzzyTextLower}',
              softSetHint: result.softSetHint ?? colorExtraction.softSetHint,
              manaBox: result.manaBox ?? colorExtraction.manaBox,
              typeBox: result.typeBox ?? colorExtraction.typeBox,
              nameBox: result.nameBox ?? colorExtraction.nameBox,
              cnBox: result.cnBox ?? colorExtraction.cnBox,
              promoDetected: result.promoDetected || colorExtraction.promoDetected,
            );
          }
        }
      }
    }

    return result;
  }

  /// Process a camera image. Returns best OcrMatch or null.
  /// Set [tryFlip] to attempt all 3 alternative rotations (180° upside-down +
  /// 0°/270° landscape battlefields). Cheap — only metadata changes, no pixel
  /// manipulation.
  Future<OcrMatch?> processImage(CameraImage image, CameraDescription camera, {bool tryFlip = false}) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      bool grayscaleSawBlocks = false;

      // Primary: grayscale at default rotation (= sensor orientation,
      // works for upright portrait card on portrait phone — empirically
      // confirmed via beta tests). No metadata override here.
      final grayInput = _convertCameraImage(image, camera, grayscaleOnly: true);
      if (grayInput != null) {
        final grayRecognized = await _textRecognizer.processImage(grayInput);
        grayscaleSawBlocks = grayRecognized.blocks.isNotEmpty;
        final grayMatch = await _analyze(grayRecognized, minScore: 35);
        if (grayMatch != null) {
          _lastWorkingAltStrategy = null;
          return grayMatch;
        }
      }

      // Fallback: color (native YUV) — skip when grayscale found NO text
      // blocks at all. Camera at empty space → both fail; running color
      // adds ~3× cost (3-plane YUV vs 1-plane Y) for no gain. Color only
      // helps when grayscale recognized blocks but couldn't score a match
      // (e.g., colored text/glow that grayscale's lower contrast missed).
      if (grayscaleSawBlocks) {
        final inputImage = _convertCameraImage(image, camera);
        if (inputImage != null) {
          final recognized = await _textRecognizer.processImage(inputImage);
          final match = await _analyze(recognized, minScore: 35);
          if (match != null) {
            _lastWorkingAltStrategy = null;
            return match;
          }
        }
      }

      if (!tryFlip) return null;

      // Alt rotations — hybrid metadata + physical fallback because empirical
      // evidence (beta-test 2026-05-02) shows ML Kit's rotation metadata for
      // BGRA8888 may not be honored by the iOS plugin. Order trades cost vs.
      // expected hit-rate:
      //   1. metadata rotation0deg (cheap, works if plugin honors metadata)
      //      — battlefield held with content's natural-top on device's left
      //   2. physical 90° CW + rotation0deg (one Y-plane copy + rotate)
      //      — upside-down portrait card
      //   3. physical 180° + rotation0deg
      //      — battlefield held with content's natural-top on device's right
      // All use grayscale + minScore=25 (lenient since these are low-conf paths).
      final altAttempts = <(InputImage? Function(), String)>[
        (() => _convertCameraImage(image, camera,
            grayscaleOnly: true, rotation: InputImageRotation.rotation0deg), 'metadata-0deg'),
        (() => _convertPhysicallyRotated(image, 90), 'physical-90cw'),
        (() => _convertPhysicallyRotated(image, 180), 'physical-180'),
      ];

      for (final (builder, label) in altAttempts) {
        final altInput = builder();
        if (altInput == null) continue;
        final altRecognized = await _textRecognizer.processImage(altInput);
        final altMatch = await _analyze(altRecognized, minScore: 25);
        if (altMatch != null) {
          // Save which strategy worked so SCANNING extractFrame can reuse.
          _lastWorkingAltStrategy = label;
          if (debugMode) {
            debugPrint('OCR: matched via "$label" (score=${altMatch.score})');
          }
          return altMatch;
        }
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
    // Remember best manaBox across all calls — ML Kit only reads the mana digit
    // in early frames before the full card is visible, then drops it
    if (extraction.manaBox != null) {
      _bestManaBox = extraction.manaBox;
      _bestManaCost = extraction.manaCost;
    }
    // Expose for scanner with sticky manaBox from earlier frames
    if (_bestManaBox != null && extraction.manaBox == null) {
      lastExtraction = OcrExtraction(
        setCode: extraction.setCode,
        collectorNumber: extraction.collectorNumber,
        cnSuffix: extraction.cnSuffix,
        cnRaw: extraction.cnRaw,
        cnHasSetPrefix: extraction.cnHasSetPrefix,
        namesFound: extraction.namesFound,
        keywordsFound: extraction.keywordsFound,
        typesFound: extraction.typesFound,
        regionsFound: extraction.regionsFound,
        manaCost: extraction.manaCost ?? _bestManaCost,
        rawTextLower: extraction.rawTextLower,
        fuzzyTextLower: extraction.fuzzyTextLower,
        softSetHint: extraction.softSetHint,
        manaBox: _bestManaBox,
        typeBox: extraction.typeBox,
        nameBox: extraction.nameBox,
        cnBox: extraction.cnBox,
        promoDetected: extraction.promoDetected,
      );
    } else {
      lastExtraction = extraction;
    }

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

    // 6. Mana cost — look for single digit at start of a block (top-left of card)
    // Must be in the upper quarter of the frame to avoid "+0" stats being read as mana
    int? manaCost;
    List<double>? manaBox;
    if (recognized.blocks.isNotEmpty) {
      final topBlocks = recognized.blocks.toList()
        ..sort((a, b) {
          final dy = a.boundingBox.top.compareTo(b.boundingBox.top);
          return dy != 0 ? dy : a.boundingBox.left.compareTo(b.boundingBox.left);
        });
      // Mana must be in the upper portion of the visible text area.
      // Old approach (highestTextTop - 250px) broke when neighbor card text
      // appeared at the top of the frame, making upperLimit negative.
      // New approach: find the vertical span of all text blocks and require
      // mana to be in the upper 35% of that span.
      double minY = double.infinity, maxY = 0;
      for (final b in recognized.blocks) {
        if (b.boundingBox.top < minY) minY = b.boundingBox.top;
        if (b.boundingBox.bottom > maxY) maxY = b.boundingBox.bottom;
      }
      final textSpan = maxY - minY;
      final upperLimit = textSpan > 100
          ? minY + textSpan * 0.35  // mana must be in upper 35% of text span
          : recognized.blocks.first.boundingBox.top; // fallback if text span too small
      if (debugMode) {
        debugPrint('Mana search: ${topBlocks.length} blocks, upperLimit=${upperLimit.round()}');
        for (int i = 0; i < topBlocks.length && i < 8; i++) {
          final b = topBlocks[i];
          debugPrint('  top[$i]: "${b.text.trim()}" y=${b.boundingBox.top.round()} len=${b.text.trim().length} isDigit=${RegExp(r'^\d{1,2}$').hasMatch(b.text.trim())}');
        }
      }
      for (final block in topBlocks.take(5)) {
        final trimmed = block.text.trim();
        if (trimmed.length <= 2 && RegExp(r'^\d{1,2}$').hasMatch(trimmed)) {
          // Must be ABOVE the main card text — reject stats like "+0" at bottom
          if (block.boundingBox.top >= upperLimit) {
            if (debugMode) debugPrint('Mana: rejected "$trimmed" at y=${block.boundingBox.top.round()} (not above upperLimit=${upperLimit.round()})');
            continue;
          }
          manaCost = int.tryParse(trimmed);
          final r = block.boundingBox;
          manaBox = [r.left, r.top, r.right, r.bottom];
          if (debugMode) debugPrint('Mana: accepted "$trimmed" at y=${block.boundingBox.top.round()}');
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
  // ── Camera image conversion ──
  // ══════════════════════════════════════════════

  /// Convert a CameraImage to an ML Kit InputImage.
  ///
  /// [rotation] overrides the rotation metadata. If null, the camera's sensor
  /// orientation is used (= upright portrait reading on iOS where sensor=90°).
  /// Different rotation values reorient ML Kit's text recognition WITHOUT any
  /// pixel manipulation — used to handle upside-down cards (180°) and
  /// landscape battlefields held in portrait holders (0° / 270°).
  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera, {
    bool grayscaleOnly = false,
    InputImageRotation? rotation,
  }) {
    final rot = rotation ?? InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rot == null) return null;
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
          rotation: rot,
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
        rotation: rot,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Physically rotate the camera Y-plane by [degrees] CW (90 or 180), emit
  /// BGRA grayscale with rotation0deg metadata.
  ///
  /// Why physical rotation: empirical evidence (beta-test logs showing the
  /// exact same OCR output at all 4 rotation metadata values) suggests
  /// google_mlkit_text_recognition on iOS may not honor the rotation
  /// metadata reliably for BGRA8888 input. Physical pixel rotation
  /// guarantees the buffer is upright when ML Kit processes it, regardless
  /// of metadata interpretation.
  ///
  /// Math: sensor mounts the camera 90° CW from device-portrait → buffer
  /// content is rotated by `(90 + cardOrientation) % 360` CW from upright.
  /// We pre-rotate physically so `_runMetadataRotation0` lands at upright:
  ///   - degrees=90 (CW): handles upside-down portrait card
  ///                     (buffer at 270° → +90 = 360 = 0)
  ///   - degrees=180:    handles battlefield held with name on the right
  ///                     (buffer at 180° → +180 = 360 = 0)
  /// The "battlefield with name on the left" case is covered by metadata-
  /// rotation0deg without physical work (buffer already at 0).
  InputImage? _convertPhysicallyRotated(CameraImage image, int degrees) {
    if (image.planes.isEmpty) return null;
    if (degrees != 90 && degrees != 180) return null;

    final yBytes = image.planes.first.bytes;
    final stride = image.planes.first.bytesPerRow;
    final w = image.width, h = image.height;

    // Output dimensions: 90° swaps w↔h, 180° keeps them.
    final ow = degrees == 90 ? h : w;
    final oh = degrees == 90 ? w : h;

    // Rotate + convert to BGRA in one pass.
    final bgra = Uint8List(ow * oh * 4);
    for (int y = 0; y < h; y++) {
      final srcRow = y * stride;
      for (int x = 0; x < w; x++) {
        final v = yBytes[srcRow + x];
        // 90° CW: source (x, y) → destination (h-1-y, x) in new coords.
        // 180°:    source (x, y) → destination (w-1-x, h-1-y).
        final int dstIdx;
        if (degrees == 90) {
          dstIdx = (x * ow + (h - 1 - y)) * 4;
        } else {
          dstIdx = ((h - 1 - y) * ow + (w - 1 - x)) * 4;
        }
        bgra[dstIdx] = v;
        bgra[dstIdx + 1] = v;
        bgra[dstIdx + 2] = v;
        bgra[dstIdx + 3] = 255;
      }
    }

    return InputImage.fromBytes(
      bytes: bgra,
      metadata: InputImageMetadata(
        size: Size(ow.toDouble(), oh.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: ow * 4,
      ),
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
