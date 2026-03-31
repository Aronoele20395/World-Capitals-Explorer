import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLClientProvider {
  static const String _endpoint = "https://countries.trevorblades.com/";

  static GraphQLClient get client {
    final httpLink = HttpLink(_endpoint);

    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }
}
