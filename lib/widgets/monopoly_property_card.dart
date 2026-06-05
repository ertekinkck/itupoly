import 'package:flutter/material.dart';
import 'package:itupoly/app/theme/tokens.dart';
import 'package:itupoly/widgets/group_icon.dart';
import 'package:itupoly_engine/itupoly_engine.dart';

/// Monopoly tarzı şık mülk tapusu ve bilgi kartı.
class MonopolyPropertyCard extends StatelessWidget {
  const MonopolyPropertyCard({
    required this.tile,
    required this.ts,
    required this.state,
    this.compact = false,
    super.key,
  });

  final Tile tile;
  final TileState ts;
  final GameState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Color groupCol = AppColors.accent;
    String subtitle = 'MASA OYUNU';
    IconData icon = Icons.help_outline_rounded;
    
    if (tile is PropertyTile) {
      groupCol = groupColor((tile as PropertyTile).group);
      subtitle = 'KİRA TAPUSU';
      icon = groupIcon((tile as PropertyTile).group);
    } else if (tile is RingTile) {
      groupCol = const Color(0xFF607D8B);
      subtitle = 'RİNG DURAĞI TAPUSU';
      icon = Icons.directions_bus_rounded;
    } else if (tile is UtilityTile) {
      groupCol = const Color(0xFF8D6E63);
      subtitle = 'TESİS TAPUSU';
      icon = Icons.bolt_rounded;
    } else if (tile is TaxTile) {
      groupCol = const Color(0xFFB04A58);
      subtitle = 'ÖDEME YÜKÜMLÜLÜĞÜ';
      icon = Icons.receipt_long_rounded;
    } else if (tile is CardTile) {
      groupCol = const Color(0xFF00796B);
      subtitle = (tile as CardTile).deck == DeckType.sans ? 'ŞANS KARTI' : 'KAMPÜS KARTI';
      icon = (tile as CardTile).deck == DeckType.sans ? Icons.help_outline_rounded : Icons.style_rounded;
    } else if (tile is CornerTile) {
      groupCol = const Color(0xFFC2185B);
      subtitle = 'KAMPÜS BÖLGESİ';
      icon = Icons.flag_rounded;
    }

    // Sahiplik etiketi: yalnızca satın alınabilir kareler için hesaplanır.
    var ownerLabel = '';
    var ownerColor = Colors.grey[700]!;
    if (tile.isOwnable) {
      if (!ts.isOwned) {
        ownerLabel = 'Sahipsiz (Bankada)';
      } else {
        final owner = state.playerById(ts.ownerId!);
        ownerLabel = owner.id == state.currentPlayer.id ? 'Senin (Mülk sahibi)' : owner.name;
        ownerColor = owner.id == state.currentPlayer.id ? Colors.green[700]! : Colors.blue[800]!;
      }
    }

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1A1A1A), width: 2),
      ),
      color: const Color(0xFFFAF9F5), // Classic cream white card background
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored Header Band (exactly like Monopoly)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: AppSpace.md),
              decoration: BoxDecoration(
                color: groupCol,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 1.8),
              ),
              child: Column(
                children: [
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: const Color(0xFF1A1A1A), size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          tile.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),

            // Sahip satırı: yalnızca satın alınabilir kareler için
            if (tile.isOwnable) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_pin_rounded, size: 14, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    ownerLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ownerColor,
                    ),
                  ),
                  if (ts.mortgaged) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'İPOTEKLİ',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    )
                  ]
                ],
              ),
            ],
            if (!compact) ...[
              const Divider(color: Colors.black26, height: AppSpace.sm, thickness: 1.2),

              // Card Body (Detailed Rents / Tariffs)
              if (tile is PropertyTile)
                _buildPropertyBody(tile as PropertyTile)
              else if (tile is RingTile)
                _buildRingBody(tile as RingTile)
              else if (tile is UtilityTile)
                _buildUtilityBody(tile as UtilityTile)
              else if (tile is TaxTile)
                _buildTaxBody(tile as TaxTile)
              else if (tile is CardTile)
                _buildCardBody(tile as CardTile)
              else if (tile is CornerTile)
                _buildCornerBody(tile as CornerTile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyBody(PropertyTile pTile) {
    final monopoly = ts.isOwned && ownsFullGroup(state, pTile.group, ts.ownerId!);
    final activeHouseCount = ts.houses;
    final houseCost = pTile.houseCost;
    final mortVal = pTile.purchasePrice ~/ 2;

    return Column(
      children: [
        _Row(label: 'KİRA (Yalın)', val: '${pTile.rents[0]} ₭', active: activeHouseCount == 0 && !monopoly),
        _Row(label: 'Tekel Grubu Kirası (x2)', val: '${pTile.rents[0] * 2} ₭', active: activeHouseCount == 0 && monopoly),
        _Row(label: '1 Derslik ile', val: '${pTile.rents[1]} ₭', active: activeHouseCount == 1),
        _Row(label: '2 Derslik ile', val: '${pTile.rents[2]} ₭', active: activeHouseCount == 2),
        _Row(label: '3 Derslik ile', val: '${pTile.rents[3]} ₭', active: activeHouseCount == 3),
        _Row(label: '4 Derslik ile', val: '${pTile.rents[4]} ₭', active: activeHouseCount == 4),
        _Row(label: '🏛️ AMFİ İLE', val: '${pTile.rents[5]} ₭', active: activeHouseCount == 5, highlight: true),
        const Divider(color: Colors.black26, thickness: 1.2),
        _InfoRow(label: 'Derslik Maliyeti', val: '$houseCost ₭ / Derslik'),
        _InfoRow(label: 'Amfi Maliyeti', val: '$houseCost ₭ + 4 Derslik'),
        _InfoRow(label: 'İpotek Değeri', val: '$mortVal ₭'),
      ],
    );
  }

  Widget _buildRingBody(RingTile rTile) {
    final owned = ts.isOwned ? ringsOwnedUnmortgaged(state, ts.ownerId!) : 0;
    return Column(
      children: [
        _Row(label: '1 Ring Durağı Sahibi', val: '25 ₭', active: owned == 1),
        _Row(label: '2 Ring Durağı Sahibi', val: '50 ₭', active: owned == 2),
        _Row(label: '3 Ring Durağı Sahibi', val: '100 ₭', active: owned == 3),
        _Row(label: '4 Ring Durağı Sahibi', val: '200 ₭', active: owned == 4),
        const Divider(color: Colors.black26, thickness: 1.2),
        const _InfoRow(label: 'İpotek Değeri', val: '100 ₭'),
      ],
    );
  }

  Widget _buildUtilityBody(UtilityTile uTile) {
    final owned = ts.isOwned ? utilitiesOwnedUnmortgaged(state, ts.ownerId!) : 0;
    return Column(
      children: [
        _Row(label: '1 Tesis sahibi ise', val: 'Zar x 4 ₭', active: owned == 1),
        _Row(label: '2 Tesis sahibi ise', val: 'Zar x 10 ₭', active: owned == 2),
        const Divider(color: Colors.black26, thickness: 1.2),
        const _InfoRow(label: 'İpotek Değeri', val: '75 ₭'),
      ],
    );
  }

  Widget _buildTaxBody(TaxTile tTile) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Text(
          'Bu kareye gelen oyuncu bankaya ${tTile.amount} ₭ vergi ödemekle yükümlüdür.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildCardBody(CardTile cTile) {
    final deckName = cTile.deck == DeckType.sans ? 'ŞANS' : 'KAMPÜS';
    return Column(
      children: [
        const SizedBox(height: 6),
        Text(
          'Bu kareye gelen oyuncu $deckName destesinden bir kart çeker ve karttaki talimatları uygular.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildCornerBody(CornerTile cTile) {
    String desc = '';
    switch (cTile.type) {
      case CornerType.basla:
        desc = 'Başlangıç noktası. Buradan her geçildiğinde bankadan 200 ₭ burs desteği alınır.';
      case CornerType.disiplinZiyaret:
        desc = 'Disiplin Kurulu. Sadece ziyaretçisiniz, herhangi bir ceza veya işlem uygulanmaz.';
      case CornerType.cimAmfi:
        desc = 'Çim Amfi. Dinlenme bölgesi. Herhangi bir işlem yapılmaz.';
      case CornerType.disiplineSevk:
        desc = '🚨 Disipline Sevk! Bu kareye gelen oyuncu doğrudan Disiplin Kurulu\'na gönderilir.';
    }
    return Column(
      children: [
        const SizedBox(height: 6),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.val,
    required this.active,
    this.highlight = false,
  });

  final String label;
  final String val;
  final bool active;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: highlight ? 11 : 10,
      fontWeight: (active || highlight) ? FontWeight.w900 : FontWeight.w600,
      color: active
          ? Colors.green[800]
          : (highlight ? const Color(0xFFC2185B) : Colors.black87),
    );

    return Container(
      color: active ? Colors.green.withValues(alpha: 0.1) : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (active)
                const Icon(Icons.arrow_right_rounded, color: Colors.green, size: 14)
              else
                const SizedBox(width: 14),
              Text(label, style: style),
            ],
          ),
          Text(val, style: style),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.val,
  });

  final String label;
  final String val;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black54),
          ),
          Text(
            val,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
