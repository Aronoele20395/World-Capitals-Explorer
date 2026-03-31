import '../../models/country.dart';

abstract class MapState {}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final List<Country> countries;

  MapLoaded({required this.countries});
}

class MapError extends MapState {
  final String message;

  MapError({required this.message});
}
