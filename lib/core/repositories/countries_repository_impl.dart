import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:world_capitals_explorer/core/graphql/queries/countries_query.dart';
import 'package:world_capitals_explorer/core/services/capitals_service.dart';
import '../../models/country.dart';
import 'countries_repository.dart';

class CountriesRepositoryImpl implements CountriesRepository {
  final GraphQLClient _client;
  //used for testing
  final CapitalsService _capitalsService;

  CountriesRepositoryImpl({required GraphQLClient client, CapitalsService? capitalsService}) : _client = client, _capitalsService = capitalsService ?? CapitalsService();

  @override
  Future<List<Country>> getCountries() async {
    final coordinates = await _capitalsService.loadCoordinates();

    final result = await _client.query(
      QueryOptions(
        document: gql(countriesQuery),
        fetchPolicy: FetchPolicy.cacheFirst,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final List<dynamic> raw = result.data?['countries'] ?? [];

    return raw.map((item) {
      final capitalName = (item['capital'] as String? ?? '').toLowerCase();
      final coords = coordinates[capitalName];
      return Country(
        code: item['code'] as String,
        name: item['name'] as String,
        capital: item['capital'] as String? ?? 'N/A',
        emoji: item['emoji'] as String,
        continentName: item['continent']['name'] as String,
        languages: (item['languages'] as List<dynamic>)
            .map((l) => l['name'] as String)
            .toList(),
        currencyName: item['currency'] as String?,
        latitude: coords?.$1,
        longitude: coords?.$2,
      );
    }).toList();
  }
}
