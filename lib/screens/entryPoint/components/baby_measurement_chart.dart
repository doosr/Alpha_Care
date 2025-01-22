import 'dart:convert';
import 'dart:io';
import 'package:my_project/screens/onboding/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
class BabyMeasurementPage extends StatefulWidget {
  final String baby_id;
  const BabyMeasurementPage({super.key, required this.baby_id});

  @override
  _BabyMeasurementPageState createState() => _BabyMeasurementPageState();
}

class _BabyMeasurementPageState extends State<BabyMeasurementPage> {
  List<BabyMeasurementData> _data = [];
  double previousX = 0.0;
  double spacing = 5.0;
  int _previousDay = 0;

  bool _isDifferentDay(int currentDay) {
    return currentDay != _previousDay;
  }

  void _updatePreviousDay(int currentDay) {
    _previousDay = currentDay;
  }
  Future<void> _generatePdf() async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getExternalStorageDirectory();
      final imagePath = File('${directory!.path}/baby_measurements.png');
      await imagePath.writeAsBytes(image);

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                pw.MemoryImage(image),
              ),
            );
          },
        ),
      );

      final pdfFile = File('${directory.path}/baby_measurements.pdf');
      await pdfFile.writeAsBytes(await pdf.save());

      final snackBar = SnackBar(
        content: Text('PDF enregistré dans ${pdfFile.path}'),
        action: SnackBarAction(
          label: 'Ouvrir',
          onPressed: () => OpenFile.open(pdfFile.path),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }
  final TransformationController _transformationController =
  TransformationController();
  final _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _fetchMeasurements();
  }

  Future<void> _fetchMeasurements() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.measurementsUrl}/${widget.baby_id}'));

      if (mounted) {
        if (response.statusCode == 200) {
          final chartData = jsonDecode(response.body);
          final labels = chartData['labels'] as List<dynamic>;
          final datasets = chartData['datasets'] as List<dynamic>;

          setState(() {
            _data = List.generate(labels.length, (index) {
              final dateFormatter = DateFormat('dd/MM/yyyy hh:mm:ss a');
              final timestamp = dateFormatter.parse(labels[index] as String);

              final temperatureData = datasets[0]['data'] as List<dynamic>;
              final spo2Data = datasets[1]['data'] as List<dynamic>;
              final bpmData = datasets[2]['data'] as List<dynamic>;

              final temperature = index < temperatureData.length
                  ? (temperatureData[index] ?? 0).toDouble()
                  : 0.0;
              final spo2 =
              index < spo2Data.length ? (spo2Data[index] ?? 0).toDouble() : 0.0;
              final bpm =
              index < bpmData.length ? (bpmData[index] ?? 0).toDouble() : 0.0;

              return BabyMeasurementData(
                timestamp: timestamp,
                temperature: temperature,
                spo2: spo2,
                bpm: bpm,
              );
            });
          });
        } else {
          print('Error fetching measurements: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching: $e');
    }
  }

  void _zoomIn() {
    _transformationController.value *= Matrix4.diagonal3Values(1.5, 1.5, 1);
  }

  void _zoomOut() {
    _transformationController.value *= Matrix4.diagonal3Values(0.5, 0.5, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique bébé'),
      ),
      body: _data.isNotEmpty
          ? Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: Colors.red),
              SizedBox(width: 8),
              Text('Température'),
              SizedBox(width: 16),
              Icon(Icons.circle, color: Colors.orange),
              SizedBox(width: 8),
              Text('SpO2'),
              SizedBox(width: 16),
              Icon(Icons.circle, color: Colors.green),
              SizedBox(width: 8),
              Text('BPM'),
            ],
          ),

          const SizedBox(height: 16),
          Expanded(
            child: Screenshot(
              controller: _screenshotController,
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 3.0,
                scaleEnabled: true,
                constrained: true,

                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueAccent,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          final touchedIndexes = <int>{};
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final index = touchedSpot.spotIndex;
                            if (!touchedIndexes.contains(index)) {
                              touchedIndexes.add(index);
                              final item = _data[index];
                              return LineTooltipItem(
                                '${DateFormat('dd/MM/yyyy hh:mm:ss a').format(item.timestamp)}\nTemperature: ${item.temperature}\nSpO2: ${item.spo2}\nBPM: ${item.bpm}',
                                const TextStyle(color: Colors.white),
                              );
                            } else {
                              return null;
                            }
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(

                      show: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(

                      show: true,
                      bottomTitles: SideTitles(

                        showTitles: true,
                        reservedSize: 22,
                        getTextStyles: (value) => const TextStyle(
                          color: Color(0xff68737d),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        getTitles: (value) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          final currentDay = date.day;

                          if (_isDifferentDay(currentDay)) {
                            _updatePreviousDay(currentDay);
                            String dayString =
                            currentDay < 10 ? '0$currentDay' : '$currentDay';
                            return '$dayString day';
                          } else {
                            return '';
                          }
                        },
                        margin: 20,
                      ),

                      leftTitles: SideTitles(
                        showTitles: true,
                        getTextStyles: (value) => const TextStyle(
                          color: Color(0xff67727d),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        getTitles: (value) {
                          switch (value.toInt()) {
                            case 0:
                              return '0';
                            case 20:
                              return '20';
                            case 40:
                              return '40';
                            case 60:
                              return '60';
                            case 80:
                              return '80';
                            case 100:
                              return '100';
                            case 120:
                              return '120';
                            case 140:
                              return '140';
                            case 160:
                              return '160';
                            case 180:
                              return '180';
                            default:
                              return '';
                          }
                        },
                        reservedSize: 28,
                        margin: 12,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: Colors.grey, width: 4),
                        left: BorderSide(color: Colors.grey, width: 4),
                      ),
                    ),
                    lineBarsData: [

                      LineChartBarData(
                        spots: _data
                            .map((item) => FlSpot(
                          item.timestamp.millisecondsSinceEpoch
                              .toDouble(),
                          item.temperature,
                        ))
                            .toList(),
                        isCurved: true,
                        colors: [ Colors.red],
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData:  FlDotData(
                          show: false,
                        ),
                        belowBarData: BarAreaData(
                          show: false,
                        ),
                      ),
                      LineChartBarData(
                        spots: _data
                            .map((item) => FlSpot(
                          item.timestamp.millisecondsSinceEpoch
                              .toDouble(),
                          item.spo2,
                        ))
                            .toList(),
                        isCurved: true,
                        colors: [ Colors.orange],

                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData:  FlDotData(
                          show: false,
                        ),
                        belowBarData: BarAreaData(
                          show: false,
                        ),
                      ),
                      LineChartBarData(
                        spots: _data
                            .map((item) => FlSpot(
                          item.timestamp.millisecondsSinceEpoch
                              .toDouble(),
                          item.bpm,


                        ))
                            .toList(),
                        isCurved: true,
                        colors: [ Colors.green],

                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData:  FlDotData(
                          show: false,
                        ),
                        belowBarData: BarAreaData(
                          show: false,
                        ),

                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: _zoomIn,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: _zoomOut,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () {
                  _generatePdf();
                },
              ),
            ],
          ),
        ],
      )
          : const Center(
        child: Text(
          'Aucun historique',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

      ),
    );
  }
}

class BabyMeasurementData {
  final DateTime timestamp;
  final double temperature;
  final double spo2;
  final double bpm;

  BabyMeasurementData({
    required this.timestamp,
    required this.temperature,
    required this.spo2,
    required this.bpm,
  });
}


