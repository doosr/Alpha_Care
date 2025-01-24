import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class MaintenancePage extends StatefulWidget {
  @override
  _MaintenancePageState createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  bool isLoading = false;
  String statusMessage = "En attente de diagnostic...";
  String batteryLevel = "N/A";
  String connectionStatus = "Déconnecté";

  final String raspberryPiUrl = 'http://<raspberry-pi-ip>:<port>/diagnostic';

  Future<void> _fetchDiagnosticData() async {
    setState(() {
      isLoading = true;
      statusMessage = "Récupération des données...";
    });

    try {
      final response = await http.get(Uri.parse(raspberryPiUrl));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          batteryLevel = data['battery'] ?? "Inconnu";
          connectionStatus = data['connection_status'] ?? "Inconnu";
          statusMessage = "Diagnostic complet";
        });
      } else {
        setState(() {
          statusMessage = "Erreur de connexion au Raspberry Pi";
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "Erreur de communication : $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _performTest() async {
    setState(() {
      isLoading = true;
      statusMessage = "Test en cours...";
    });

    try {
      final response = await http.post(Uri.parse(raspberryPiUrl),
          body: json.encode({'action': 'test'}));

      if (response.statusCode == 200) {
        setState(() {
          statusMessage = "Test réussi";
        });
      } else {
        setState(() {
          statusMessage = "Erreur lors du test";
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "Erreur de communication lors du test : $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDiagnosticData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Page de Maintenance"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "État actuel du bracelet bébé",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  connectionStatus == "Déconnecté" ? Icons.signal_wifi_off : Icons.signal_wifi_4_bar,
                  color: connectionStatus == "Déconnecté" ? Colors.red : Colors.green,
                ),
                SizedBox(width: 10),
                Text("Statut de la connexion : $connectionStatus"),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  batteryLevel == "N/A" || int.parse(batteryLevel) < 20 ? Icons.battery_alert : Icons.battery_full,
                  color: int.parse(batteryLevel) < 20 ? Colors.red : Colors.green,
                ),
                SizedBox(width: 10),
                Text("Niveau de la batterie : $batteryLevel%"),
              ],
            ),
            SizedBox(height: 20),
            if (isLoading)
              CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _performTest,
                    child: Text("Effectuer un Test"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchDiagnosticData,
                    child: Text("Récupérer les données de diagnostic"),
                  ),
                ],
              ),
            SizedBox(height: 20),
            Text(statusMessage),
          ],
        ),
      ),
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// class MaintenancePage extends StatefulWidget {
//   @override
//   _MaintenancePageState createState() => _MaintenancePageState();
// }
//
// class _MaintenancePageState extends State<MaintenancePage> {
//   bool isLoading = false;
//   String statusMessage = "En attente de diagnostic...";
//   String batteryLevel = "N/A";
//   String connectionStatus = "Déconnecté";
//
//   // URL du Raspberry Pi (à adapter selon votre configuration)
//   final String raspberryPiUrl = 'http://<raspberry-pi-ip>:<port>/diagnostic';
//
//   // Méthode pour récupérer les données de diagnostic du Raspberry Pi
//   Future<void> _fetchDiagnosticData() async {
//     setState(() {
//       isLoading = true;
//       statusMessage = "Récupération des données...";
//     });
//
//     try {
//       final response = await http.get(Uri.parse(raspberryPiUrl));
//
//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         setState(() {
//           batteryLevel = data['battery'] ?? "Inconnu";
//           connectionStatus = data['connection_status'] ?? "Inconnu";
//           statusMessage = "Diagnostic complet";
//         });
//       } else {
//         setState(() {
//           statusMessage = "Erreur de connexion au Raspberry Pi";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         statusMessage = "Erreur de communication : $e";
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   // Méthode pour redémarrer le bracelet ou effectuer un test
//   Future<void> _performTest() async {
//     setState(() {
//       isLoading = true;
//       statusMessage = "Test en cours...";
//     });
//
//     try {
//       // Vous pouvez envoyer un signal de test au Raspberry Pi via HTTP
//       final response = await http.post(Uri.parse(raspberryPiUrl),
//           body: json.encode({'action': 'test'}));
//
//       if (response.statusCode == 200) {
//         setState(() {
//           statusMessage = "Test réussi";
//         });
//       } else {
//         setState(() {
//           statusMessage = "Erreur lors du test";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         statusMessage = "Erreur de communication lors du test : $e";
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchDiagnosticData();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Page de Maintenance"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "État actuel du bracelet bébé",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 20),
//             Text("Statut de la connexion : $connectionStatus"),
//             SizedBox(height: 10),
//             Text("Niveau de la batterie : $batteryLevel"),
//             SizedBox(height: 20),
//             if (isLoading)
//               CircularProgressIndicator()
//             else
//               Column(
//                 children: [
//                   ElevatedButton(
//                     onPressed: _performTest,
//                     child: Text("Effectuer un Test"),
//                   ),
//                   SizedBox(height: 10),
//                   ElevatedButton(
//                     onPressed: _fetchDiagnosticData,
//                     child: Text("Récupérer les données de diagnostic"),
//                   ),
//                 ],
//               ),
//             SizedBox(height: 20),
//             Text(statusMessage),
//           ],
//         ),
//       ),
//     );
//   }
// }
