import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Visibility;
import 'package:world_capitals_explorer/core/cubit/map_cubit.dart';
import 'package:world_capitals_explorer/models/country.dart';
import 'package:world_capitals_explorer/screens/error_view.dart';
import 'package:world_capitals_explorer/widgets/continent_legend.dart';
import 'package:world_capitals_explorer/widgets/country_bottom_sheet.dart';

import '../core/cubit/map_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _annotationManager;

  //map annotation markers to a country
  final Map<String, Country> _annotationToCountry = {};

  //to force mapwodget rebuild on retry after connection or other type error
  Key _mapKey = UniqueKey();
  //state to handle MapBox native errors
  String? _mapboxError;

  @override
  void initState() {
    super.initState();

    context.read<MapCubit>().loadCountries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MapCubit, MapState>(
        listener: (context, state) {},
        builder: (context, state) {
          return SafeArea(
            child: Stack(
              children: [
                //Visibility to hide the map widget while loading keeping it into the widget tree. Map widget is expensive to rebuild, so I don't want to rebuild it when the status changes
                Visibility(
                  visible: state is MapLoaded,
                  child: MapWidget(
                    //key to avoid useless rebuilds of the map widget
                    key: _mapKey,
                    styleUri: MapboxStyles.DARK,
                    onMapCreated: (controller) async {
                      _mapboxMap = controller;

                      await controller.scaleBar.updateSettings(
                        ScaleBarSettings(
                          enabled: true,
                          position: OrnamentPosition.BOTTOM_LEFT,
                          marginBottom: 32,
                          marginLeft: 16,
                        ),
                      );

                      _annotationManager = await controller.annotations
                          .createCircleAnnotationManager();

                      //scenario: map data already available so I immediately add markers
                      final currentState = context.read<MapCubit>().state;
                      if (currentState is MapLoaded) {
                        await _addMarkers(currentState.countries);
                      }
                    },
                    onMapLoadErrorListener: (event) {
                    if (mounted) {
                      setState(() => _mapboxError =
                      'Map could not be loaded. Please check your connection.');
                    }
                  },
                    onStyleLoadedListener: (_) {
                      if (_mapboxError != null && mounted) {
                        setState(() => _mapboxError = null);
                      }
                    },
                    cameraOptions: CameraOptions(
                      center: Point(coordinates: Position(12.4964, 41.9028)),
                      zoom: 1.5,
                    ),
                  ),
                ),


                //if there's some errors in building the map, shows an error page
                if (_mapboxError != null)
                  Container(
                    color: const Color(0xFF121212),
                    child: ErrorView(
                      title: 'Map error',
                      message: _mapboxError!,
                      onRetry: () {
                        setState(() {
                          _mapboxError = null;
                          _mapKey = UniqueKey();
                          _annotationToCountry.clear();
                          _annotationManager = null;
                        });
                      },
                    ),
                  ),

                if (state is MapLoading)
                  const Center(child: CircularProgressIndicator()),

                //I use MarkersLoader helper class to handle the scenario in which country data is loaded before map finished initialization
                if (state is MapLoaded)
                  MarkersLoader(
                    countries: state.countries,
                    onLoad: _addMarkers,
                  ),

                //Not the usual AppBar in order to overlay the map widget and not to push it down
                if (state is! MapError && _mapboxError == null)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            "World Capitals Explorer",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),

                          if (state is MapLoaded)
                            Text(
                              '${(state).countries.where((c) => c.hasCoordinates).length} countries',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                if( state is MapLoaded && _mapboxError == null)
                Positioned(right: 16, bottom: 32, child: ContinentLegend()),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addMarkers(List<Country> countries) async {
    if (_annotationManager == null) return;

    //I want to consider only countries that have the correct information about coordinates
    final countriesWithCoord = countries
        .where((c) => c.hasCoordinates)
        .toList();

    //markers list filtered as above
    final annotationOptions = countriesWithCoord.map((country) {
      return CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(country.longitude!, country.latitude!),
        ),
        circleRadius: 6,
        circleColor: _getColorForContinent(country.continentName).value,
        circleStrokeWidth: 1.3,
        circleStrokeColor: Colors.white.value,
      );
    }).toList();

    //all the markers added in one single operation
    final annotations = await _annotationManager!.createMulti(
      annotationOptions,
    );

    for (int i = 0; i < annotations.length; i++) {
      final id = annotations[i]!.id;
      _annotationToCountry[id] = countriesWithCoord[i];
    }

    _annotationManager!.tapEvents(
      onTap: (CircleAnnotation annotation) {
        _onMarkerTapped(annotation);
      },
    );
  }

  void _onMarkerTapped(CircleAnnotation annotation) {
    final country = _annotationToCountry[annotation.id];
    if (country == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Country data not available"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _showCountryBottomSheet(country);
  }

  void _showCountryBottomSheet(Country country) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CountryBottomSheet(country: country),
    );
  }

  Color _getColorForContinent(String continent) {
    return ContinentLegend.continentColors[continent] ??
        const Color(0xFFEEEEEE);
  }
}

//helper class to trigger _addMarkers function once countries and map data are ready to use
class MarkersLoader extends StatefulWidget {
  final List<Country> countries;
  final Future<void> Function(List<Country>) onLoad;
  const MarkersLoader({required this.countries, required this.onLoad});

  @override
  State<MarkersLoader> createState() => _MarkersLoaderState();
}

class _MarkersLoaderState extends State<MarkersLoader> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!_isLoaded) {
      _isLoaded = true;
      widget.onLoad(widget.countries);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
