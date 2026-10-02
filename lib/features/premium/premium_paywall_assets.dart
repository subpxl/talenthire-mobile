import 'dart:math';

/// Images in [assets/paywall/] (see `pubspec.yaml`).
enum PaywallBackgroundMode { random, sequential }

/// Random = new image each time the paywall opens. Sequential = rotate 1→N.
const paywallBackgroundMode = PaywallBackgroundMode.random;

const paywallBackgrounds = <String>[
  'assets/paywall/paywall_h_01.jpeg',
  'assets/paywall/paywall_h_02.jpeg',
  'assets/paywall/paywall_h_03.jpeg',
  'assets/paywall/paywall_h_04.jpeg',
  'assets/paywall/paywall_h_05.jpeg',
];

int _sequentialPaywallIndex = 0;

/// Call once when [PremiumPage] opens.
String pickPaywallBackgroundAsset({Random? random}) {
  if (paywallBackgrounds.isEmpty) {
    return 'assets/splash.png';
  }
  switch (paywallBackgroundMode) {
    case PaywallBackgroundMode.random:
      final rng = random ?? Random();
      return paywallBackgrounds[rng.nextInt(paywallBackgrounds.length)];
    case PaywallBackgroundMode.sequential:
      final asset =
          paywallBackgrounds[_sequentialPaywallIndex % paywallBackgrounds.length];
      _sequentialPaywallIndex++;
      return asset;
  }
}
