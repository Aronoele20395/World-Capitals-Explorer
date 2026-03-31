const String countriesQuery = r'''
  query GetCountries {
    countries {
      code
      name
      capital
      emoji
      continent {
        name
      }
      languages {
        name
      }
      currency
    }
  }
''';