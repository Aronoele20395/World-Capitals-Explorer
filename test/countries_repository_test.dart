import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:world_capitals_explorer/core/repositories/countries_repository_impl.dart';
import 'package:world_capitals_explorer/core/services/capitals_service.dart';

class MockGraphQLClient extends Mock implements GraphQLClient {}
class MockCapitalsService extends Mock implements CapitalsService {}
class FakeQueryOptions extends Fake implements QueryOptions {}

final Map<String, (double, double)> fakeCoordinates = {
  "rome": (41.9, 12.4),
  "tokyo": (35.6, 139.6)
};

void main() {
  setUpAll(() {
    registerFallbackValue(FakeQueryOptions());
  });
  late MockGraphQLClient mockClient;
  late MockCapitalsService mockCapitalsService;
  late CountriesRepositoryImpl repository;

  setUp(() {
    mockClient = MockGraphQLClient();
    mockCapitalsService = MockCapitalsService();

    when(() => mockCapitalsService.loadCoordinates()).thenAnswer((_) async => fakeCoordinates);

    repository = CountriesRepositoryImpl(client: mockClient, capitalsService: mockCapitalsService);
  });

  group("CountriesRepositoryImpl", () {
    test("Return a list of countries on successful GraphQL response", () async {
      final fakeData = {
        'countries': [
          {
            'code': 'IT',
            'name': 'Italy',
            'capital': 'Rome',
            'emoji': '🇮🇹',
            'continent': {'name': 'Europe'},
            'languages': [
              {'name': 'Italian'},
            ],
            'currency': 'EUR',
          },
          {
            'code': 'JP',
            'name': 'Japan',
            'capital': 'Tokyo',
            'emoji': '🇯🇵',
            'continent': {'name': 'Asia'},
            'languages': [
              {'name': 'Japanese'},
            ],
            'currency': 'JPY',
          },
        ],
      };

      when(() => mockClient.query(any())).thenAnswer(
        (_) async => QueryResult(
          options: QueryOptions(document: gql("{countries {code}}")),
          data: fakeData,
          source: QueryResultSource.network,
        ),
      );

      final countries = await repository.getCountries();

      expect(countries.length, 2);
      expect(countries.first.code, "IT");
      expect(countries.first.name, "Italy");
      expect(countries.first.capital, "Rome");
      expect(countries.first.continentName, "Europe");
      expect(countries.first.languages, ["Italian"]);
      expect(countries.first.currencyName, "EUR");
    });

    test("Throws exception when GraphQL response has an error", () async {
      when(() => mockClient.query(any())).thenAnswer(
        (_) async => QueryResult(
          options: QueryOptions(document: gql("{countries {code}}")),
          exception: OperationException(
            graphqlErrors: [const GraphQLError(message: "Network error")],
          ),
          source: QueryResultSource.network,
        ),
      );
      expect(() => repository.getCountries(), throwsException);
    });

    test("country without matching capital coordinates has null lat/lng", () async {
      final fakeData = {
        'countries': [
          {
            'code': 'XX',
            'name': 'Fake Country',
            'capital': 'Nonexistent Capital XYZ',
            'emoji': '🏳️',
            'continent': {'name': 'Europe'},
            'languages': [],
            'currency': null,
          },
        ]
      };

      when(() => mockClient.query(any())).thenAnswer(
            (_) async => QueryResult(
          options: QueryOptions(document: gql("{ countries { code } }")),
          data: fakeData,
          source: QueryResultSource.network,
        ),
      );

      final countries = await repository.getCountries();

      expect(countries.first.hasCoordinates, false);
      expect(countries.first.latitude, null);
      expect(countries.first.longitude, null);
    });
  });
}
