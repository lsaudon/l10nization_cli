import 'package:example/l10n/l10n.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) => const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _HomePage(),
      );
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context).helloWorld),
            Text(AppLocalizations.of(context).helloWorld),
            Text(l10n.helloMoon),
            Text(context.l10n.seeingTheWorldAgain),
            Text(Stuff().seeingTheWorldAgain),
          ],
        ),
      ),
    );
  }
}

class Stuff {
  String get seeingTheWorldAgain => 'Seeing the world again';
}
