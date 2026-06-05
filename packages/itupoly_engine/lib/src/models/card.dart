import 'package:itupoly_engine/src/models/enums.dart';

/// Bir kartın oyuncu üzerindeki etkisi.
sealed class CardAction {
  const CardAction();
}

/// Bankadan para al (pozitif tutar).
final class GainMoney extends CardAction {
  const GainMoney(this.amount);
  final int amount;
}

/// Bankaya para öde.
final class PayMoney extends CardAction {
  const PayMoney(this.amount);
  final int amount;
}

/// Belirli bir kareye ilerle. [collectIfPass] true ise BAŞLA'dan geçerken burs
/// alınır.
final class MoveTo extends CardAction {
  const MoveTo(this.tileIndex, {this.collectIfPass = true});
  final int tileIndex;
  final bool collectIfPass;
}

/// Geriye doğru [steps] kare git (BAŞLA'dan geçiş sayılmaz).
final class MoveBack extends CardAction {
  const MoveBack(this.steps);
  final int steps;
}

/// Doğrudan Disiplin Kurulu'na (hapse) gönderilir.
final class GoToDisiplin extends CardAction {
  const GoToDisiplin();
}

/// Af Kartı (hapisten çıkış) kazanılır; kullanılana dek oyuncuda kalır.
final class GetAfKarti extends CardAction {
  const GetAfKarti();
}

/// Her rakipten [amount] kredi toplanır.
final class CollectFromEach extends CardAction {
  const CollectFromEach(this.amount);
  final int amount;
}

/// Her rakibe [amount] kredi ödenir.
final class PayEach extends CardAction {
  const PayEach(this.amount);
  final int amount;
}

/// Bir deste kartı.
final class GameCard {
  const GameCard({
    required this.id,
    required this.deck,
    required this.text,
    required this.action,
  });

  /// Deste içinde benzersiz kimlik (cards_tr indeksiyle eşleşir).
  final int id;

  /// Hangi desteye ait.
  final DeckType deck;

  /// Karttaki özgün Türkçe metin.
  final String text;

  /// Etki.
  final CardAction action;
}
