import 'package:flutter/material.dart';
import '../../theme/app_components.dart';

/// Verkäufer-Status-Badge für Discogs-Modell + Verbraucherwiderrufsrecht
/// (2026-05-01).
///
/// Zeigt „Privater Verkäufer" oder „Gewerblich" an. Treibt zwei rechtliche
/// Mechanismen:
///
/// 1. **Verbraucher-Aufklärung vor Bestellung:** Käufer muss vor Vertrags-
///    schluss erkennen können, ob der Verkäufer gewerblich (§ 14 BGB) ist —
///    nur dann besteht das gesetzliche Widerrufsrecht (§ 312g BGB) und die
///    14-Tage-Belehrung gilt (Riftr_AGB_Anhang_1_Widerrufsbelehrung.md
///    Abschnitt A).
///
/// 2. **Reklamations-Hinweis-Dialog:** Bei den Reason-Codes `wrong_card`
///    und `not_arrived` MUSS die App den Käufer aktiv fragen, ob er
///    stattdessen das Widerrufsrecht ausüben möchte — aber nur wenn der
///    Verkäufer gewerblich ist (§ X Refund-Policy Abs. 2 lit. c) +
///    Anhang 1 Abschnitt C).
///
/// Datenquelle: `MarketOrder.sellerIsCommercial` oder direkt aus
/// `SellerProfile.isCommercialSeller`. Snapshot zur Order-Zeit.
class SellerStatusBadge extends StatelessWidget {
  final bool isCommercial;

  /// Kompaktere Variante für eng platzierte Kontexte (Listing-Tile).
  /// Default false = volles Label; true = nur „Commercial" / „Private".
  final bool compact;

  const SellerStatusBadge({
    super.key,
    required this.isCommercial,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = compact
        ? (isCommercial ? 'Commercial' : 'Private')
        : (isCommercial ? 'Commercial seller' : 'Private seller');
    return RiftrBadge(
      label: label,
      type: isCommercial ? RiftrBadgeType.gold : RiftrBadgeType.neutral,
    );
  }
}
