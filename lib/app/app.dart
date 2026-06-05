import 'package:flutter/material.dart';
import 'package:itupoly/app/router.dart';
import 'package:itupoly/app/theme/theme.dart';

/// İTÜpoly kök widget'ı.
class ItupolyApp extends StatelessWidget {
  const ItupolyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'İTÜpoly',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
