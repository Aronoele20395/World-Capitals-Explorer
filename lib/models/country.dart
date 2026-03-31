class Country {
  final String code;
  final String name;
  final String capital;
  final String emoji;
  final String continentName;
  final List<String> languages;
  final String? currencyName;
  final double? latitude;
  final double? longitude;

  const Country({
    required this.code,
    required this.name,
    required this.capital,
    required this.emoji,
    required this.continentName,
    required this.languages,
    this.currencyName,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}