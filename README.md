## L10nization_cli

[![Pub Version][pub_version_badge]][pub_package_link]
[![Pub Points][pub_points_badge]][pub_points_link]
[![License: MIT][license_badge]][license_link]

A Command-Line Interface to find unused l10n translations from an arb file.

---

## Getting Started 🚀

If the CLI application is available on [pub](https://pub.dev), activate globally via:

```sh
dart pub global activate l10nization_cli
```

## Usage

```sh
# Check unused translations
l10nization check-unused <folder-of-app>
```

### Cases considered

```dart
return Text(context.l10n.hello);
```

```dart
final l10n = AppLocalizations.of(context);
return Text(l10n.a);
```

```dart
final l10n = context.l10n;
return Text(l10n.a);
```

```dart
return Text(AppLocalizations.of(context).a);
```

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({
    required this.l10n,
    super.key,
  });

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Text(l10n.helloMoon);
  }
}
```

```dart
abstract class MySuperWidget extends StatelessWidget {
  const MySuperWidget({
    required this.l10n,
    super.key,
  });

  final AppLocalizations l10n;
}

class MyWidget extends MySuperWidget {
  const MyWidget({
    required super.l10n,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(l10n.helloMoon);
  }
}
```

```dart
extension AppLocalizationsExtension on AppLocalizations {
  String byKey(final String value) {
    switch (value) {
      case 'helloMars':
        return helloMars;
      default:
        throw Exception();
    }
  }
}
```

```dart
String function(AppLocalizations l10n) {
  return l10n.helloMoon;
}
```

```dart
String function(AppLocalizations l10n) => l10n.helloMoon;
```

```dart
final l10n = context.l10n;
return Text(l10n.a(b));
```

```dart
return Text(context.l10n.a(b));
```

## Running locally

```sh
dart pub global activate --source=path . && l10nization check-unused example
```

## Running Tests with coverage 🧪

To run all unit tests use the following command:

```sh
dart pub global activate coverage
dart test --coverage=coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
open coverage/index.html
```

## Build version

```sh
dart run build_runner build -d
```

---

Generated by the [Very Good CLI][very_good_cli_link] 🤖

[license_badge]: https://img.shields.io/github/license/lsaudon/l10nization_cli
[license_link]: https://img.shields.io/github/license/lsaudon/l10nization_cli
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli
[pub_points_badge]: https://img.shields.io/pub/points/l10nization_cli
[pub_version_badge]: https://img.shields.io/pub/v/l10nization_cli
[pub_package_link]: https://pub.dev/packages/l10nization_cli
[pub_points_link]: https://pub.dev/packages/l10nization_cli/score
