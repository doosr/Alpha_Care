import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_project/screens/onboding/api_constants.dart';
import 'package:my_project/socket.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:my_project/notification_service.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';
import '../../screens/entryPoint/components/baby_measurement_chart.dart';

class BabyHealthMonitorPage extends StatefulWidget {
  final String babyId;

  const BabyHealthMonitorPage({super.key, required this.babyId});
  @override
  _BabyHealthMonitorPageState createState() => _BabyHealthMonitorPageState();
}

class _BabyHealthMonitorPageState extends State<BabyHealthMonitorPage> {

  double _babyTemperature = 0.0;
  double _ambientTemperature = 0.0;
  int _babyHeartRate = 0;
  int _babySpo2 = 0;
  double _opacity = 0.0; // Initial opacity
  // Locale _locale = Locale('fr', ''); // Définissez la langue par défaut ici

  late IO.Socket _socket;
  int _temperatureInterval = 1800; // 30 minutes
  int _heartbeatInterval = 900; // 15 minutes
  final NotificationService notificationService = NotificationService();
  Timer? _timer;
  @override
  void initState() {
    super.initState();

    notificationService.initialize();
    _startTokenExpirationTimer();
    _connectToSocket();

    _getBabyId().then((babyId) {
      // Utilisez babyId ici si nécessaire
      print('Baby ID: $babyId');
    });    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0; // Update opacity after 500 milliseconds
      });
    });
  }
  void _stopNotifications() {
    notificationService.cancelAllNotifications();
    print('Notifications stopped');
  }
  void _startTokenExpirationTimer() {
    _timer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _checkTokenExpiration();
    });
  }
  Future<void> _checkTokenExpiration() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final expiryDateStr = await storage.read(key: 'expiryDate');

    if (token == null || expiryDateStr == null) {
      _showTokenExpiredDialog();
      return;
    }

    final expiryDate = DateTime.parse(expiryDateStr);
    if (DateTime.now().isAfter(expiryDate)) {
      _showTokenExpiredDialog();
    }
  }
  void _showTokenExpiredDialog() {
    SocketService.disconnect();
    _stopNotifications();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Session expirée"),
        content: const Text("Votre session a expiré. Veuillez vous reconnecter."),
        actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MyApp()),
                    (Route<dynamic> route) => false,
              );
            },
            child: const Text("Se connecter"),
          ),
        ],
      ),
    );
  }
  Future<void> fetchBabyData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/baby/${widget.babyId}/data'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _babyTemperature = data['temperature'];
          _ambientTemperature = data['ambientTemperature'];
          _babyHeartRate = data['heartRate'];
          _babySpo2 = data['spo2'];
        });
      } else {
        throw Exception('Failed to fetch baby data');
      }
    } catch (error) {
      print('Error fetching baby data: $error');
    }
  }
  Future<String?> _getBabyId() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'baby_id');
  }

  void _connectToSocket() {
    _socket = IO.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
    });

    _socket.on('connect', (_) {
      print('Connected to server');
    });

    _socket.on('updateTemperatureSuccess', (data) {
      setState(() {
        _babyTemperature = double.parse(data['data']['bebe_temperature'].toString());
        _ambientTemperature = double.parse(data['data']['ambient_temperature'].toString());
      });

    });


    _socket.on('updateHeartbeatSuccess', (data) {
      setState(() {
        _babyHeartRate = data['data']['last_bpm'];
        _babySpo2 = int.tryParse(data['data']['last_spo2'].toString()) ?? 0;
        if (_babySpo2 <= 0) {
          _babySpo2 = 0;
        }
      });

    });
    _socket.on('updateIntervals', (data) {
      setState(() {
        _temperatureInterval = data['temperature_interval'];
        _heartbeatInterval = data['heartbeat_interval'];
      });
    });

  }
  // void _changeLanguage(String languageCode) {
  //   setState(() {
  //     _locale = Locale(languageCode, '');
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(left: 50.0),
          child: Text('Home'),
        ),
        automaticallyImplyLeading: false, // Cette ligne supprime le bouton de retour

        actions: [
          IconButton(
            icon: const Icon(Icons.history), // Utilisez l'icône d'historique
            onPressed: () {
              _showHistoryBottomSheet(context); // Afficher l'historique sous forme de BottomSheet
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showIntervalSettingsDialog(context);
            },
          ),
          //   DropdownButton<String>(
          //     value: _locale.languageCode,
          //     onChanged: (String? newValue) {
          //       if (newValue != null) {
          //         _changeLanguage(newValue);
          //       }
          //     },
          //     items: [
          //       DropdownMenuItem<String>(
          //         value: 'fr',
          //         child: const Text('Français'),
          //       ),
          //       DropdownMenuItem<String>(
          //         value: 'en',
          //         child: const Text('English'),
          //       ),
          //       DropdownMenuItem<String>(
          //         value: 'ar',
          //         child: const Text('العربية'),
          //       ),
          //     ],
          //   ),
          //
        ],
        flexibleSpace: AnimatedBuilder(
          animation: ModalRoute.of(context)!.animation!,
          builder: (context, child) {
            return Center(
              child: Opacity(
                opacity: _opacity,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                  height: 70,
                  width: 70,
                ),
              ),
            );
          },
        ),
      ),

      body: Center(
          child: SingleChildScrollView(

              child: Column(

                children: [

                  const SizedBox(height: 15),
                  Container(
                    height: 160,
                    width: 370,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        CircularPercentIndicator(
                          radius: 60.0,
                          lineWidth: 10.0,
                          percent: _ambientTemperature / 50,
                          center: Text(
                            "${_ambientTemperature.toStringAsFixed(2)}°C",
                            style: const TextStyle(fontSize: 19,fontFamily: "Poppins"),
                          ),
                          progressColor: Colors.blue,
                        ),
                        const SizedBox(width: 18),

                        const Column(

                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [

                            Text('Température ambiante', style: TextStyle(fontSize: 15,fontFamily: "Poppins")),
                            SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),
                  Container(
                    height: 160,
                    width: 370,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,

                      children: [

                        CircularPercentIndicator(
                          radius: 60.0,
                          lineWidth: 10.0,
                          percent: _babyTemperature / 45, // <-- Cette ligne
                          center: Text(
                            "${_babyTemperature.toStringAsFixed(2)}°C",
                            style: const TextStyle(fontSize: 19, fontFamily: "Poppins"),
                          ),
                          progressColor: Colors.red,
                        ),
                        const SizedBox(width: 25),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [

                            const Text('Température du bébé', style: TextStyle(fontSize: 15,fontFamily: "Poppins")),
                            const SizedBox(height: 8),
                            if (_babyTemperature > 37.5)
                              Column(
                                children: [
                                  const Text(
                                    'Température Elevée',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: "Poppins",
                                      color: Colors.red,
                                    ),
                                  ),
                                  FutureBuilder<void>(
                                    future: notificationService.showNotification(
                                      'Température Elevée',
                                      'La température de votre bébé est supérieure à 37.5°C',
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.done) {
                                        return const SizedBox(); // Vous pouvez remplacer par un widget approprié si nécessaire
                                      } else {
                                        return const CircularProgressIndicator(); // Afficher un indicateur de chargement pendant l'attente
                                      }
                                    },
                                  ),
                                ],
                              )
                            else if (_babyTemperature >= 36.5 && _babyTemperature <= 37.5)
                              const Text(
                                'Température Normale',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: "Poppins",
                                  color: Colors.green,
                                ),
                              )
                            else
                              Column(
                                children: [
                                  const Text(
                                    'Température faible',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: "Poppins",
                                      color: Colors.red,
                                    ),
                                  ),
                                  FutureBuilder<void>(
                                    future: notificationService.showNotification(
                                      'Température faible',
                                      'La température de votre bébé est supérieure à 37.5°C',
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.done) {
                                        return const SizedBox(); // Vous pouvez remplacer par un widget approprié si nécessaire
                                      } else {
                                        return const CircularProgressIndicator(); // Afficher un indicateur de chargement pendant l'attente
                                      }
                                    },
                                  ),
                                ],
                              )

                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  Container(
                    height: 160,
                    width: 370,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,

                      children: [
                        CircularPercentIndicator(

                          radius: 60.0,
                          lineWidth: 10.0,
                          percent: (_babyHeartRate / 280).clamp(0.0, 1.0), // Limiter la valeur entre 0.0 et 1.0
                          center: Text(
                            "$_babyHeartRate bpm",
                            style: const TextStyle(fontSize: 17, fontFamily: "Poppins"),
                          ),
                          progressColor: Colors.green,

                        ),

                        const SizedBox(width: 25),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [

                            const Text('Rythme cardiaque \n du bébé', style: TextStyle(fontSize:  15,fontFamily: "Poppins")),
                            const SizedBox(height: 8),
                            if (  _babyHeartRate <= 140 && _babyHeartRate>=120)
                              const Text(' bpm Normal', style: TextStyle(fontSize: 15, fontFamily: "Poppins", color: Colors.green))
                            else
                              Column(
                                children: [
                                  const Text(
                                    'bpm Faible',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: "Poppins",
                                      color: Colors.red,
                                    ),
                                  ),
                                  FutureBuilder<void>(
                                    future: notificationService.showNotification(
                                      'bpm Faible',
                                      'La rythme cardiaque de votre bébé est faible',
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.done) {
                                        return const SizedBox(); // Vous pouvez remplacer par un widget approprié si nécessaire
                                      } else {
                                        return const CircularProgressIndicator(); // Afficher un indicateur de chargement pendant l'attente
                                      }
                                    },
                                  ),
                                ],
                              )




                            // Jusqu'à 2 ans : 120 a 140 bpm,
                            // Entre 8 et 17 ans : 80 a 100 bpm,
                            // Adulte sédentaire : 70 a 80 bpm,
                            // Adulte praticant de sport e personnes âgées : 50 a 60 bpm.
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),
                  Container(
                    height: 160,
                    width: 370,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,

                      children: [
                        CircularPercentIndicator(
                          radius: 60.0,
                          lineWidth: 10.0,
                          percent: _babySpo2 / 100,
                          center: Text(
                            "$_babySpo2%",
                            style: const TextStyle(fontSize: 20,fontFamily: "Poppins"),
                          ),
                          progressColor: Colors.orange,
                        ),
                        const SizedBox(width: 25),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            const Text('Saturation en oxygène', style: TextStyle(fontSize: 15,fontFamily: "Poppins")),
                            const SizedBox(height: 8),
                            if (_babySpo2 >= 95)
                              const Text(' Taux de O₂ Normal', style: TextStyle(fontSize: 15, fontFamily: "Poppins", color: Colors.orange)),



                            if  (_babySpo2 < 95)
                              Column(
                                children: [
                                  const Text(' Taux de O₂ Faible', style: TextStyle(fontSize: 15, fontFamily: "Poppins", color: Colors.red)),

                                  FutureBuilder<void>(
                                    future: notificationService.showNotification(
                                      'Taux de O₂ Faible',
                                      'La Taux de O₂  de votre bébé est faible',
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.done) {
                                        return const SizedBox(); // Vous pouvez remplacer par un widget approprié si nécessaire
                                      } else {
                                        return const CircularProgressIndicator(); // Afficher un indicateur de chargement pendant l'attente
                                      }
                                    },
                                  ),
                                ],
                              )


                          ],
                        ),
                      ],
                    ),
                  ),


                ],
              )
          )
      ),

    );

  }


  Future<void> _showHistoryBottomSheet(BuildContext context) async {
    final babyId = await _getBabyId();
    print('$babyId');


    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: BabyMeasurementPage(baby_id:  babyId ?? '',), // Use your TemperatureChart widget here to display history
        );
      },
    );
  }
  Future<void> _showIntervalSettingsDialog(BuildContext context) async {
    final temperatureIntervalController = TextEditingController(text: _temperatureInterval.toString());
    final heartbeatIntervalController = TextEditingController(text: _heartbeatInterval.toString());

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Réglages des intervalles de lecture'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: temperatureIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Intervalle de lecture de la température (secondes)',
                  ),
                ),
                TextField(
                  controller: heartbeatIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Intervalle de lecture du BPM/SpO2 (secondes)',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Enregistrer'),
              onPressed: () {
                final temperatureInterval = int.parse(temperatureIntervalController.text);
                final heartbeatInterval = int.parse(heartbeatIntervalController.text);
                _socket.emit('updateIntervals', {
                  'temperature_interval': temperatureInterval,
                  'heartbeat_interval': heartbeatInterval,
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _stopNotifications();
    _timer?.cancel();
    super.dispose();
  }
}
