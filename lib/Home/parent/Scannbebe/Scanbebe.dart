
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:my_project/Home/parent/Scannbebe/trouveridbebe.dart';
import 'package:my_project/screens/onboding/api_constants.dart'; // Import flutter_barcode_scanner package

class BabyIdPage extends StatefulWidget {
  const BabyIdPage({super.key});

  @override
  _BabyIdPageState createState() => _BabyIdPageState();
}

class _BabyIdPageState extends State<BabyIdPage> {
  final TextEditingController _controller = TextEditingController();
  String _babyId = '';

  Future<void> _sendBabyId(String babyId) async {
    final response = await http.post(
      Uri.parse(ApiConstants.babyIdUrl),
      body: {'babyId': babyId},
    );
    if (response.statusCode == 200) {
      setState(() {
        _babyId = babyId;
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Success'),
          content: const Text('bébé est ajouté'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Error dajouter un bébé'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

      throw Exception('Failed to send baby ID');
    }
  }

  Future<void> _scanQR() async {
    try {
      String qrResult = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
      if (!mounted) return;
      setState(() {
        _controller.text = qrResult;
      });
    } catch (e) {
      print('Error scanning QR code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Cette ligne supprime le bouton de retour

        title: const Padding(
          padding: EdgeInsets.only(left: 50.0), // Ajoutez un padding à gauche du titre
          child: Text('Baby ID'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter Baby ID or Scan QR Code',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _sendBabyId(_controller.text.trim());
                     Future.delayed(const Duration(seconds: 1), () async {

                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(builder: (context) =>BabyHealthMonitorPage(babyId: '',),
                    //     ));

                     });

                  },
                  child: const Text('Send Baby ID'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _scanQR();
                  },
                  child: const Text('Scan QR Code'),
                ),
              ],
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>const SendBabyIdPage(),
                  ));

                },
                child: const Text('Trouver babyID'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Baby ID: $_babyId',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: BabyIdPage(),
  ));
}
