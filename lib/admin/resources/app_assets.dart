/// Every asset path the app loads, written down once.
///
/// Paths are typed here and nowhere else, so a renamed file is a single edit
/// and a typo is a compile error rather than a blank frame at runtime.
///
/// All of these are local. Nothing in this app loads a picture over a
/// network, and nothing should: a path here must name a file that ships in
/// `assets/`, declared in `pubspec.yaml`.
///
/// The file names carry a running number as well as a slug — `01_`, `02_`,
/// and so on, in catalogue order. The number is what ties a file back to the
/// photograph it came from; the slug is what makes the folder readable. The
/// constants below are named for the item, so swapping a photograph is a
/// matter of dropping a new file in at the same path, in any format Flutter
/// decodes, with the extension updated here.
class AppAssets {
  const AppAssets._();

  // -------------------------------------------------------------- products
  // Twenty-five, in catalogue order. Every SKU the sample orders mention has
  // one here, so no order line points at a product that does not exist.
  static const String banarasiSilkSaree =
      'assets/images/products/01_banarasi_silk_saree.jpg';
  static const String kanjivaramPureSilk =
      'assets/images/products/02_kanjivaram_pure_silk.jpg';
  static const String cottonDailySaree =
      'assets/images/products/03_cotton_daily_saree.jpg';
  static const String georgettePartyWear =
      'assets/images/products/04_georgette_party_wear.jpg';
  static const String paithaniMuniyaBorder =
      'assets/images/products/05_paithani_muniya_border.jpg';
  static const String mysoreCrepeSilk =
      'assets/images/products/06_mysore_crepe_silk.jpg';
  static const String bridalKanjivaramRed =
      'assets/images/products/07_bridal_kanjivaram_red.jpg';
  static const String patolaHandloomSaree =
      'assets/images/products/08_patola_handloom_saree.jpg';
  static const String bandhaniGeorgetteSaree =
      'assets/images/products/09_bandhani_georgette_saree.jpg';
  static const String designerNetSaree =
      'assets/images/products/10_designer_net_saree.jpg';
  static const String chanderiCottonSilk =
      'assets/images/products/11_chanderi_cotton_silk.jpg';
  static const String linenDailySaree =
      'assets/images/products/12_linen_daily_saree.jpg';
  static const String paithaniSilkSaree =
      'assets/images/products/13_paithani_silk_saree.jpg';
  static const String tussarSilkSaree =
      'assets/images/products/14_tussar_silk_saree.jpg';
  static const String banarasiKatanSilk =
      'assets/images/products/15_banarasi_katan_silk.jpg';
  static const String organzaEmbroideredSaree =
      'assets/images/products/16_organza_embroidered_saree.jpg';
  static const String ajrakhPrintModalSilk =
      'assets/images/products/17_ajrakh_print_modal_silk.jpg';
  static const String tissueSilkSaree =
      'assets/images/products/18_tissue_silk_saree.jpg';
  static const String gadwalCottonSilk =
      'assets/images/products/19_gadwal_cotton_silk.jpg';
  static const String narayanpetCotton =
      'assets/images/products/20_narayanpet_cotton.jpg';
  static const String maheshwariHandloom =
      'assets/images/products/21_maheshwari_handloom.jpg';
  static const String kotaDoriaCotton =
      'assets/images/products/22_kota_doria_cotton.jpg';
  static const String velvetBridalSaree =
      'assets/images/products/23_velvet_bridal_saree.jpg';
  static const String bhagalpuriSilkSaree =
      'assets/images/products/24_bhagalpuri_silk_saree.jpg';
  static const String chiffonSequinSaree =
      'assets/images/products/25_chiffon_sequin_saree.jpg';

  // ------------------------------------------------------------ categories
  // Twelve, in the order the grouping screen lists them.
  static const String silkSareeCategory =
      'assets/images/categories/01_silk_saree.jpg';
  static const String banarasiCategory =
      'assets/images/categories/02_banarasi.jpg';
  static const String cottonSareeCategory =
      'assets/images/categories/03_cotton_saree.jpg';
  static const String georgetteCategory =
      'assets/images/categories/04_georgette.jpg';
  static const String kanjivaramCategory =
      'assets/images/categories/05_kanjivaram.jpg';
  static const String bridalWearCategory =
      'assets/images/categories/06_bridal_wear.jpg';
  static const String designerCategory =
      'assets/images/categories/07_designer.jpg';
  static const String dailyWearCategory =
      'assets/images/categories/08_daily_wear.jpg';
  static const String chanderiCategory =
      'assets/images/categories/09_chanderi.jpg';
  static const String patolaCategory =
      'assets/images/categories/10_patola.jpg';
  static const String paithaniCategory =
      'assets/images/categories/11_paithani.jpg';
  static const String organzaCategory =
      'assets/images/categories/12_organza.jpg';

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
    paithaniMuniyaBorder,
    mysoreCrepeSilk,
    bridalKanjivaramRed,
    patolaHandloomSaree,
    bandhaniGeorgetteSaree,
    designerNetSaree,
    chanderiCottonSilk,
    linenDailySaree,
    paithaniSilkSaree,
    tussarSilkSaree,
    banarasiKatanSilk,
    organzaEmbroideredSaree,
    ajrakhPrintModalSilk,
    tissueSilkSaree,
    gadwalCottonSilk,
    narayanpetCotton,
    maheshwariHandloom,
    kotaDoriaCotton,
    velvetBridalSaree,
    bhagalpuriSilkSaree,
    chiffonSequinSaree,
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
