import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:itupoly/app/app.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: ItupolyApp()));
}
