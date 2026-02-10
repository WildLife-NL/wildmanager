import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:wildlifenl_map_logic_components/wildlifenl_map_logic_components.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        body: WildLifeNLMap(
          userAgentPackageName: 'wildmanager',
          mapController: _mapController,
          options: MapOptions(
            initialCenter: MapStateInterface.defaultCenter,
            initialZoom: 10,
          ),
          extraLayers: [
            MarkerLayer(
              markers: [
                Marker(
                  point: MapStateInterface.defaultCenter,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.place,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
