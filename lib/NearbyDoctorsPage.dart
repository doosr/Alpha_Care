import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MedecinLocalisationPage extends StatefulWidget {
  @override
  _MedecinLocalisationPageState createState() => _MedecinLocalisationPageState();
}

class _MedecinLocalisationPageState extends State<MedecinLocalisationPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<Marker> _medecinsMarkers = [];

  @override
  void initState() {
    super.initState();
    _obtenirPositionActuelle();
  }

  Future<void> _obtenirPositionActuelle() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      _chargerMedecinsProches();
    } catch (e) {
      print('Erreur de géolocalisation: $e');
    }
  }

  Future<void> _chargerMedecinsProches() async {
    if (_currentPosition == null) return;

    try {
      final response = await http.post(
          Uri.parse('https://votre-api.com/medecins/proximite'),
          body: jsonEncode({
            'latitude': _currentPosition!.latitude,
            'longitude': _currentPosition!.longitude,
            'rayonKm': 10
          }),
          headers: {'Content-Type': 'application/json'}
      );

      if (response.statusCode == 200) {
        final medecins = jsonDecode(response.body)['medecins'];

        setState(() {
          _medecinsMarkers = medecins.map<Marker>((medecin) =>
              Marker(
                  markerId: MarkerId(medecin['id'].toString()),
                  position: LatLng(
                      medecin['latitude'],
                      medecin['longitude']
                  ),
                  infoWindow: InfoWindow(
                      title: medecin['nom'],
                      snippet: medecin['specialite']
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
              )
          ).toList();
        });
      }
    } catch (e) {
      print('Erreur de chargement des médecins: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Médecins à Proximité'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _chargerMedecinsProches,
          )
        ],
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
            target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude
            ),
            zoom: 12
        ),
        markers: Set.from(_medecinsMarkers),
        myLocationEnabled: true,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _obtenirPositionActuelle,
        child: Icon(Icons.my_location),
      ),
    );
  }
}