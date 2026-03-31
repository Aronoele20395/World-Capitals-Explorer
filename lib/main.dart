import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:world_capitals_explorer/screens/map_screen.dart';
import 'core/cubit/map_cubit.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const mapboxToken = String.fromEnvironment('MAPBOX_PUBLIC_TOKEN');
  MapboxOptions.setAccessToken(
    mapboxToken.isNotEmpty ? mapboxToken : '',
  );
  setUpDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World capitals explorer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: BlocProvider(
        create: (_) => getIt<MapCubit>(),
        child: const MapScreen(),
      ),
    );
  }
}