import 'package:itupoly_engine/itupoly_engine.dart';

/// Online lockstep taşıma katmanı sözleşmesi (Faz 5).
///
/// Determinizm motoru sayesinde ağa **state değil aksiyon** gönderilir; her
/// istemci aynı `GameEngine.submit`'i çalıştırır. `seq` senkronun bel kemiğidir.
/// Supabase Realtime implementasyonu `supabase_online_transport.dart` içine
/// gelir (ONLINE.md'ye bakın). Bu arayüz motoru ağdan tamamen bağımsız tutar.
abstract interface class OnlineTransport {
  /// Host: oda kur, 6 haneli kod + seed üret.
  Future<RoomConfig> createRoom(List<PlayerSetup> setups, int seed);

  /// Misafir: koda katıl.
  Future<RoomConfig> joinRoom(
    String code, {
    required String name,
    required PawnType pawn,
  });

  /// seq sırasına göre gelen uzak aksiyonlar (reconnect'te eksikler backfill).
  Stream<RemoteAction> watchActions();

  /// Yerel aksiyonu yayınla. `unique(room_id, seq)` çakışmayı DB'de reddeder.
  Future<void> sendAction(int seq, PlayerAction action);

  /// Host: oyunu başlat (status → playing).
  Future<void> startGame();

  Future<void> dispose();
}

/// Bir odanın deterministik kurulum bilgisi.
class RoomConfig {
  const RoomConfig({
    required this.code,
    required this.seed,
    required this.setups,
    required this.mySeat,
  });

  final String code;
  final int seed;
  final List<PlayerSetup> setups;

  /// Bu istemcinin oturma sırası = motor oyuncu id'si.
  final int mySeat;
}

/// Ağdan gelen, seq damgalı uzak aksiyon.
class RemoteAction {
  const RemoteAction({
    required this.seq,
    required this.senderSeat,
    required this.action,
  });

  final int seq;
  final int senderSeat;
  final PlayerAction action;
}
