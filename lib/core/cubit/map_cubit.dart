import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/countries_repository.dart';
import 'map_state.dart';


class MapCubit extends Cubit<MapState> {
  final CountriesRepository _repository;

  MapCubit({required CountriesRepository repository}) : _repository = repository, super(MapInitial());

  Future<void> loadCountries() async {
    emit(MapLoading());
    try {
      final countries = await _repository.getCountries();
      emit(MapLoaded(countries: countries));
    } catch (e) {
      emit(MapError(message: e.toString()));
    }
  }
}