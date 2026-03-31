import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:world_capitals_explorer/core/repositories/countries_repository.dart';
import 'package:world_capitals_explorer/core/repositories/countries_repository_impl.dart';

import '../cubit/map_cubit.dart';
import '../graphql/graphql_client.dart';

final getIt = GetIt.instance;

void setUpDependencies() {
  getIt.registerLazySingleton<GraphQLClient>(
    () => GraphQLClientProvider.client,
  );
  getIt.registerLazySingleton<CountriesRepository>(
    () => CountriesRepositoryImpl(client: getIt<GraphQLClient>()),
  );
  getIt.registerFactory<MapCubit>(
    () => MapCubit(repository: getIt<CountriesRepository>()),
  );
}
