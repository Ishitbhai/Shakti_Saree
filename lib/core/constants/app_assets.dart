/// Every asset path the app loads, written down once.
///
/// Paths are typed here and nowhere else, so a renamed file is a single edit
/// and a typo is a compile error rather than a blank frame at runtime.
///
/// All of these are local. Nothing in this app loads a picture over a
/// network, and nothing should: a path here must name a file that ships in
/// `assets/`, declared in `pubspec.yaml`.
///
/// The images are placeholders drawn by `tool/generate_placeholder_art.dart`,
/// standing in until there is photography. Replacing one is a matter of
/// dropping a real picture in at the same path — no code changes, and any
/// format Flutter decodes will do, with the extension updated here.
class AppAssets {
  const AppAssets._();

  // -------------------------------------------------------------- products
  static const String banarasiSilkSaree =
      'assets/images/products/banarasi_silk_saree.png';
  static const String kanjivaramPureSilk =
      'assets/images/products/kanjivaram_pure_silk.png';
  static const String cottonDailySaree =
      'assets/images/products/cotton_daily_saree.png';
  static const String georgettePartyWear =
      'assets/images/products/georgette_party_wear.png';
  static const String paithaniSilkSaree =
      'assets/images/products/paithani_silk_saree.png';

  // ------------------------------------------------------------ categories
  static const String silkSareeCategory =
      'assets/images/categories/silk_saree.png';
  static const String banarasiCategory =
      'assets/images/categories/banarasi.png';
  static const String cottonSareeCategory =
      'assets/images/categories/cotton_saree.png';
  static const String georgetteCategory =
      'assets/images/categories/georgette.png';
  static const String kanjivaramCategory =
      'assets/images/categories/kanjivaram.png';
  static const String bridalWearCategory =
      'assets/images/categories/bridal_wear.png';
  static const String designerCategory =
      'assets/images/categories/designer.png';
  static const String dailyWearCategory =
      'assets/images/categories/daily_wear.png';
  static const String chanderiCategory =
      'assets/images/categories/chanderi.png';
  static const String patolaCategory = 'assets/images/categories/patola.png';
  static const String paithaniCategory =
      'assets/images/categories/paithani.png';
  static const String organzaCategory = 'assets/images/categories/organza.png';

  // --------------------------------------------------------------- licences
  /// The Open Font License text each bundled family ships under.
  static const String interLicence = 'assets/fonts/OFL-Inter.txt';
  static const String playfairLicence = 'assets/fonts/OFL-PlayfairDisplay.txt';

  /// Every image above, for the test that checks each one is on disk and
  /// declared. Keep in sync when adding one.
  static const List<String> images = [
    banarasiSilkSaree,
    kanjivaramPureSilk,
    cottonDailySaree,
    georgettePartyWear,
    paithaniSilkSaree,
    silkSareeCategory,
    banarasiCategory,
    cottonSareeCategory,
    georgetteCategory,
    kanjivaramCategory,
    bridalWearCategory,
    designerCategory,
    dailyWearCategory,
    chanderiCategory,
    patolaCategory,
    paithaniCategory,
    organzaCategory,
  ];
}
