import 'package:world_capitals_explorer/models/country.dart';

abstract class CountriesRepository {
  Future<List<Country>> getCountries();
}