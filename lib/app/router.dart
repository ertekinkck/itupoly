import 'package:go_router/go_router.dart';
import 'package:itupoly/features/end/end_screen.dart';
import 'package:itupoly/features/game/game_screen.dart';
import 'package:itupoly/features/home/home_screen.dart';
import 'package:itupoly/features/home/how_to_screen.dart';
import 'package:itupoly/features/online/online_room_screen.dart';
import 'package:itupoly/features/setup/setup_screen.dart';

/// URL tabanlı navigasyon (#'siz adresler).
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/kurulum', builder: (_, __) => const SetupScreen()),
    GoRoute(path: '/oyun', builder: (_, __) => const GameScreen()),
    GoRoute(path: '/sonuc', builder: (_, __) => const EndScreen()),
    GoRoute(
      path: '/nasil-oynanir',
      builder: (_, __) => const HowToScreen(),
    ),
    // Online derin bağlantısı (Faz 5 iskeleti): /oda/KOD
    GoRoute(
      path: '/oda/:kod',
      builder: (_, state) =>
          OnlineRoomScreen(code: state.pathParameters['kod'] ?? '—'),
    ),
  ],
);
