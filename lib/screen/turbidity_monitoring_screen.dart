import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_water/turbidity_controller.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:smart_water/screen/offline_screen.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:smart_water/model/turbidty_reading.dart';

class TurbidityMonitorScreen extends StatefulWidget {
  const TurbidityMonitorScreen({super.key});

  @override
  _TurbidityMonitorScreenState createState() => _TurbidityMonitorScreenState();
}

class _TurbidityMonitorScreenState extends State<TurbidityMonitorScreen> {
  int _currentIndex = 0;
  final TextEditingController _thresholdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final TurbidityController controller = Get.put(TurbidityController());

    return Obx(() {
      if (!controller.isConnected.value) {
        return const OfflineScreen();
      }

      return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
              backgroundColor: Colors.blue,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
              backgroundColor: Colors.blue,
            ),
          ],
        ),
        appBar: AppBar(
          title: Text(
              _currentIndex == 0
                  ? 'Water Turbidity Monitoring System'
                  : 'Automatic Drain Pump Settings',
              style: GoogleFonts.poppins(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blue,
        ),
        body: _currentIndex == 0
            ? _buildHomeScreen(controller)
            : _buildSettingsScreen(controller),
      );
    });
  }

  Widget _buildHomeScreen(TurbidityController controller) {
    // Your existing home screen implementation
    return SingleChildScrollView(
      child: Container(
        height: 750,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Radial Gauge
              Obx(() => ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 0.8,
                      child: SfRadialGauge(
                        enableLoadingAnimation: true,
                        axes: <RadialAxis>[
                          RadialAxis(
                            minimum: 0,
                            maximum: 900,
                            showLastLabel: true,
                            maximumLabels: 5,
                            startAngle: 180,
                            endAngle: 360,
                            showLabels: true,
                            axisLineStyle: const AxisLineStyle(
                              thickness: 20,
                              color: Colors.transparent,
                            ),
                            showAxisLine: false,
                            canScaleToFit: true,
                            radiusFactor: 1.0,
                            ranges: <GaugeRange>[
                              GaugeRange(
                                startValue: 0,
                                endValue: 180,
                                color: Colors.brown,
                                startWidth: 20,
                                endWidth: 20,
                              ),
                              GaugeRange(
                                startValue: 180,
                                endValue: 360,
                                color: Colors.brown[300],
                                startWidth: 20,
                                endWidth: 20,
                              ),
                              GaugeRange(
                                startValue: 360,
                                endValue: 540,
                                color: Colors.brown[100],
                                startWidth: 20,
                                endWidth: 20,
                              ),
                              GaugeRange(
                                startValue: 540,
                                endValue: 720,
                                color: Colors.brown[50],
                                startWidth: 20,
                                endWidth: 20,
                              ),
                              GaugeRange(
                                startValue: 720,
                                endValue: 900,
                                color: Colors.blue,
                                startWidth: 20,
                                endWidth: 20,
                              ),
                            ],
                            pointers: <GaugePointer>[
                              NeedlePointer(
                                value: double.tryParse(
                                        controller.turbidityValue.value) ??
                                    0,
                                enableAnimation: true,
                                needleLength: 0.7,
                                needleColor: Colors.black,
                              )
                            ],
                            annotations: <GaugeAnnotation>[
                              GaugeAnnotation(
                                widget: Obx(() {
                                  final value = double.tryParse(
                                          controller.turbidityValue.value) ??
                                      0;
                                  String text;
                                  Color? color;

                                  if (value >= 750) {
                                    text =
                                        '${controller.turbidityValue.value} - Jernih';
                                    color = Colors.blue;
                                  } else if (value > 500) {
                                    text =
                                        '${controller.turbidityValue.value} - Keruh';
                                    color = Colors.brown[200];
                                  } else {
                                    text =
                                        '${controller.turbidityValue.value} - Sangat Kotor';
                                    color = Colors.brown;
                                  }

                                  return Text(
                                    text,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  );
                                }),
                                angle: 90,
                                positionFactor: 0.3,
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: 20),

              // Linear Gauge
              Obx(() => SfLinearGauge(
                    minimum: 0,
                    maximum: 900,
                    orientation: LinearGaugeOrientation.horizontal,
                    axisLabelStyle: const TextStyle(color: Colors.black),
                    ranges: <LinearGaugeRange>[
                      const LinearGaugeRange(
                          midWidth: 20,
                          endWidth: 20,
                          startValue: 0,
                          endValue: 180,
                          color: Colors.brown),
                      LinearGaugeRange(
                          midWidth: 20,
                          endWidth: 20,
                          startValue: 180,
                          endValue: 360,
                          color: Colors.brown[300]),
                      LinearGaugeRange(
                          midWidth: 20,
                          endWidth: 20,
                          startValue: 360,
                          endValue: 540,
                          color: Colors.brown[100]),
                      LinearGaugeRange(
                          midWidth: 20,
                          endWidth: 20,
                          startValue: 540,
                          endValue: 720,
                          color: Colors.brown[50]),
                      const LinearGaugeRange(
                          midWidth: 20,
                          endWidth: 20,
                          startValue: 720,
                          endValue: 900,
                          color: Colors.blue),
                    ],
                    markerPointers: [
                      LinearShapePointer(
                        value:
                            double.tryParse(controller.turbidityValue.value) ??
                                0,
                        color: Colors.black,
                      )
                    ],
                  )),

              const SizedBox(height: 20),

              // Recent Readings List
              Text(
                'Riwayat Bacaan Sensor',
                style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Expanded(
                flex: 2,
                child: Obx(() => ListView.builder(
                      itemCount: controller.recentReadings.length,
                      itemBuilder: (context, index) {
                        final reading = controller.recentReadings[index];
                        return ListTile(
                          title: Text(
                            'Nilai: ${reading.value}',
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              'Waktu: ${reading.timestamp.hour}:${reading.timestamp.minute}:${reading.timestamp.second} - ${reading.timestamp.day} ${DateFormat.MMMM().format(reading.timestamp)} ${reading.timestamp.year}'),
                        );
                      },
                    )),
              ),

              // Drain Pump Control Buttons
              const SizedBox(height: 20),
              Obx(() => GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    childAspectRatio: 3, // Makes buttons wider
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      // ON 2
                      // ON Button
                      ElevatedButton(
                        onPressed: controller.isSupplyPumpBusy.value ||
                                !controller.isConnected.value
                            ? null
                            : () => controller.toggleDrainPump("on_supply"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.supplyPumpState.value
                              ? Colors.green
                              : null,
                        ),
                        child: Text(
                          textAlign: TextAlign.center,
                          controller.supplyPumpState.value
                              ? 'Supply Pump ON'
                              : 'Turn ON Supply Pump',
                          style: GoogleFonts.poppins(
                              color: !controller.supplyPumpState.value
                                  ? Colors.grey
                                  : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                      // OFF Button
                      ElevatedButton(
                        onPressed: controller.isSupplyPumpBusy.value ||
                                !controller.isConnected.value
                            ? null
                            : () => controller.toggleDrainPump("off_supply"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !controller.supplyPumpState.value
                              ? Colors.red
                              : null,
                        ),
                        child: Text(
                          textAlign: TextAlign.center,
                          !controller.supplyPumpState.value
                              ? 'Supply Pump OFF'
                              : 'Turn OFF Supply Pump',
                          style: GoogleFonts.poppins(
                              color: !controller.supplyPumpState.value
                                  ? Colors.white
                                  : Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                      // ON Button
                      ElevatedButton(
                        onPressed: controller.isDrainPumpBusy.value ||
                                !controller.isConnected.value
                            ? null
                            : () => controller.toggleDrainPump("on"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.drainPumpState.value
                              ? Colors.green
                              : null,
                        ),
                        child: Text(
                          textAlign: TextAlign.center,
                          controller.drainPumpState.value
                              ? 'Drain Pump ON'
                              : 'Turn ON Drain Pump',
                          style: GoogleFonts.poppins(
                              color: !controller.drainPumpState.value
                                  ? Colors.grey
                                  : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                      // OFF Button
                      ElevatedButton(
                        onPressed: controller.isDrainPumpBusy.value ||
                                !controller.isConnected.value
                            ? null
                            : () => controller.toggleDrainPump("off"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !controller.drainPumpState.value
                              ? Colors.red
                              : null,
                        ),
                        child: Text(
                          textAlign: TextAlign.center,
                          !controller.drainPumpState.value
                              ? 'Drain Pump OFF'
                              : 'Turn OFF Drain Pump',
                          style: GoogleFonts.poppins(
                              color: !controller.drainPumpState.value
                                  ? Colors.white
                                  : Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsScreen(TurbidityController controller) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live Chart for Last 12 Hours Readings
            Text(
              'Turbidity Readings (Last 12 Hours)',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 300,
              child: Obx(() {
                // Filter readings from last 12 hours
                final now = DateTime.now();
                final lastTwelveHours = controller.recentReadings
                    .where((reading) =>
                        now.difference(reading.timestamp).inHours < 12)
                    .toList();

                return SfCartesianChart(
                  primaryXAxis: DateTimeAxis(
                    intervalType: DateTimeIntervalType.hours,
                    dateFormat: DateFormat('HH:mm'),
                  ),
                  primaryYAxis: NumericAxis(
                    title: AxisTitle(text: 'Turbidity'),
                  ),
                  series: <LineSeries<TurbidityReading, DateTime>>[
                    LineSeries<TurbidityReading, DateTime>(
                      dataSource: lastTwelveHours,
                      xValueMapper: (reading, _) => reading.timestamp,
                      yValueMapper: (reading, _) =>
                          double.tryParse(reading.value) ?? 0,
                      color: Colors.blue,
                      markerSettings: const MarkerSettings(
                        isVisible: true,
                      ),
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 20),

            // Automatic Drain Pump Configuration
            Text(
              'Automatic Drain Pump Settings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // Threshold Input
            TextField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Turbidity Threshold',
                hintText: 'Enter turbidity threshold for auto drain',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Automatic Drain Pump Control Buttons
            Obx(() => GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    // ON Button
                    ElevatedButton(
                      onPressed: !controller.isConnected.value
                          ? null
                          : () {
                              final threshold = _thresholdController.text;
                              if (threshold.isNotEmpty) {
                                // Prepare payload as JSON or string
                                final payload =
                                    '{"mode": "on", "threshold": $threshold}';

                                // Use a new topic for automatic drain pump
                                controller.client.publishMessage(
                                    'emqx/esp8266/automatic-drain-pump',
                                    MqttQos.atLeastOnce,
                                    MqttClientPayloadBuilder()
                                        .addString(payload)
                                        .payload!);
                                Get.snackbar(
                                  'Automatic Drain Pump',
                                  'Enabled with threshold $threshold',
                                );
                              } else {
                                Get.snackbar(
                                    'Error', 'Please enter a threshold value');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        'Enable Auto Drain',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // OFF Button
                    ElevatedButton(
                      onPressed: !controller.isConnected.value
                          ? null
                          : () {
                              final payload = '{"mode": "off"}';

                              controller.client.publishMessage(
                                  'emqx/esp8266/automatic-drain-pump',
                                  MqttQos.atLeastOnce,
                                  MqttClientPayloadBuilder()
                                      .addString(payload)
                                      .payload!);
                              Get.snackbar(
                                'Automatic Drain Pump',
                                'Disabled',
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        'Disable Auto Drain',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

// class TurbidityMonitorScreen extends StatelessWidget {
//   const TurbidityMonitorScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final TurbidityController controller = Get.put(TurbidityController());

//     return Obx(() {
//       if (!controller.isConnected.value) {
//         return const OfflineScreen();
//       }

//       return Scaffold(
//         bottomNavigationBar: BottomNavigationBar(
//           items: [
//             const BottomNavigationBarItem(
//                 icon: Icon(Icons.home),
//                 label: 'Home',
//                 backgroundColor: Colors.blue),
//             const BottomNavigationBarItem(
//                 icon: Icon(Icons.settings),
//                 label: 'Settings',
//                 backgroundColor: Colors.blue),
//           ],
//         ),
//         appBar: AppBar(
//           title: Text('Water Turbidity Monitoring System',
//               style: GoogleFonts.poppins(
//                   fontSize: 17,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold)),
//           backgroundColor: Colors.blue,
//           actions: [
//             IconButton(
//                 icon: const Icon(
//                   Icons.info_outline,
//                   color: Colors.white,
//                 ),
//                 onPressed: () {
//                   Get.defaultDialog(
//                     titlePadding: const EdgeInsets.all(25),
//                     title: 'Water Turbidity Monitoring Information',
//                     titleStyle: GoogleFonts.poppins(
//                         fontWeight: FontWeight.bold, fontSize: 20),
//                     content: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text('750 ke atas: Jernih',
//                             style: GoogleFonts.poppins(
//                                 color: Colors.blue,
//                                 fontWeight: FontWeight.bold)),
//                         Text('500 - 749: Keruh',
//                             style: GoogleFonts.poppins(
//                                 color: Colors.brown[200],
//                                 fontWeight: FontWeight.bold)),
//                         Text('Di Bawah 500: Sangat Kotor',
//                             style: GoogleFonts.poppins(
//                                 color: Colors.brown,
//                                 fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//                     confirm: TextButton(
//                       onPressed: () {
//                         Get.back();
//                       },
//                       child: Text('Tutup',
//                           style:
//                               GoogleFonts.poppins(fontWeight: FontWeight.bold)),
//                     ),
//                   );
//                 }),
//           ],
//         ),
//         body: SingleChildScrollView(
//           child: Container(
//             height: 750,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // Radial Gauge
//                   Obx(() => ClipRect(
//                         child: Align(
//                           alignment: Alignment.bottomCenter,
//                           heightFactor: 0.8,
//                           child: SfRadialGauge(
//                             enableLoadingAnimation: true,
//                             axes: <RadialAxis>[
//                               RadialAxis(
//                                 minimum: 0,
//                                 maximum: 900,
//                                 showLastLabel: true,
//                                 maximumLabels: 5,
//                                 startAngle: 180,
//                                 endAngle: 360,
//                                 showLabels: true,
//                                 axisLineStyle: const AxisLineStyle(
//                                   thickness: 20,
//                                   color: Colors.transparent,
//                                 ),
//                                 showAxisLine: false,
//                                 canScaleToFit: true,
//                                 radiusFactor: 1.0,
//                                 ranges: <GaugeRange>[
//                                   GaugeRange(
//                                     startValue: 0,
//                                     endValue: 180,
//                                     color: Colors.brown,
//                                     startWidth: 20,
//                                     endWidth: 20,
//                                   ),
//                                   GaugeRange(
//                                     startValue: 180,
//                                     endValue: 360,
//                                     color: Colors.brown[300],
//                                     startWidth: 20,
//                                     endWidth: 20,
//                                   ),
//                                   GaugeRange(
//                                     startValue: 360,
//                                     endValue: 540,
//                                     color: Colors.brown[100],
//                                     startWidth: 20,
//                                     endWidth: 20,
//                                   ),
//                                   GaugeRange(
//                                     startValue: 540,
//                                     endValue: 720,
//                                     color: Colors.brown[50],
//                                     startWidth: 20,
//                                     endWidth: 20,
//                                   ),
//                                   GaugeRange(
//                                     startValue: 720,
//                                     endValue: 900,
//                                     color: Colors.blue,
//                                     startWidth: 20,
//                                     endWidth: 20,
//                                   ),
//                                 ],
//                                 pointers: <GaugePointer>[
//                                   NeedlePointer(
//                                     value: double.tryParse(
//                                             controller.turbidityValue.value) ??
//                                         0,
//                                     enableAnimation: true,
//                                     needleLength: 0.7,
//                                     needleColor: Colors.black,
//                                   )
//                                 ],
//                                 annotations: <GaugeAnnotation>[
//                                   GaugeAnnotation(
//                                     widget: Obx(() {
//                                       final value = double.tryParse(controller
//                                               .turbidityValue.value) ??
//                                           0;
//                                       String text;
//                                       Color? color;

//                                       if (value >= 750) {
//                                         text =
//                                             '${controller.turbidityValue.value} - Jernih';
//                                         color = Colors.blue;
//                                       } else if (value > 500) {
//                                         text =
//                                             '${controller.turbidityValue.value} - Keruh';
//                                         color = Colors.brown[200];
//                                       } else {
//                                         text =
//                                             '${controller.turbidityValue.value} - Sangat Kotor';
//                                         color = Colors.brown;
//                                       }

//                                       return Text(
//                                         text,
//                                         style: GoogleFonts.poppins(
//                                           fontSize: 20,
//                                           fontWeight: FontWeight.bold,
//                                           color: color,
//                                         ),
//                                       );
//                                     }),
//                                     angle: 90,
//                                     positionFactor: 0.3,
//                                   )
//                                 ],
//                               )
//                             ],
//                           ),
//                         ),
//                       )),

//                   const SizedBox(height: 20),

//                   // Linear Gauge
//                   Obx(() => SfLinearGauge(
//                         minimum: 0,
//                         maximum: 900,
//                         orientation: LinearGaugeOrientation.horizontal,
//                         axisLabelStyle: const TextStyle(color: Colors.black),
//                         ranges: <LinearGaugeRange>[
//                           const LinearGaugeRange(
//                               midWidth: 20,
//                               endWidth: 20,
//                               startValue: 0,
//                               endValue: 180,
//                               color: Colors.brown),
//                           LinearGaugeRange(
//                               midWidth: 20,
//                               endWidth: 20,
//                               startValue: 180,
//                               endValue: 360,
//                               color: Colors.brown[300]),
//                           LinearGaugeRange(
//                               midWidth: 20,
//                               endWidth: 20,
//                               startValue: 360,
//                               endValue: 540,
//                               color: Colors.brown[100]),
//                           LinearGaugeRange(
//                               midWidth: 20,
//                               endWidth: 20,
//                               startValue: 540,
//                               endValue: 720,
//                               color: Colors.brown[50]),
//                           const LinearGaugeRange(
//                               midWidth: 20,
//                               endWidth: 20,
//                               startValue: 720,
//                               endValue: 900,
//                               color: Colors.blue),
//                         ],
//                         markerPointers: [
//                           LinearShapePointer(
//                             value: double.tryParse(
//                                     controller.turbidityValue.value) ??
//                                 0,
//                             color: Colors.black,
//                           )
//                         ],
//                       )),

//                   const SizedBox(height: 20),

//                   // Recent Readings List
//                   Text(
//                     'Riwayat Bacaan Sensor',
//                     style: GoogleFonts.poppins(
//                         color: Colors.black,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold),
//                     textAlign: TextAlign.center,
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Obx(() => ListView.builder(
//                           itemCount: controller.recentReadings.length,
//                           itemBuilder: (context, index) {
//                             final reading = controller.recentReadings[index];
//                             return ListTile(
//                               title: Text(
//                                 'Nilai: ${reading.value}',
//                                 style: GoogleFonts.poppins(
//                                     color: Colors.black,
//                                     fontSize: 15,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                               subtitle: Text(
//                                   'Waktu: ${reading.timestamp.hour}:${reading.timestamp.minute}:${reading.timestamp.second} - ${reading.timestamp.day} ${DateFormat.MMMM().format(reading.timestamp)} ${reading.timestamp.year}'),
//                             );
//                           },
//                         )),
//                   ),

//                   // Drain Pump Control Buttons
//                   const SizedBox(height: 20),
//                   Obx(() => GridView.count(
//                         shrinkWrap: true,
//                         crossAxisCount: 2,
//                         childAspectRatio: 3, // Makes buttons wider
//                         mainAxisSpacing: 10,
//                         crossAxisSpacing: 10,
//                         children: [
//                           // ON 2
//                           // ON Button
//                           ElevatedButton(
//                             onPressed: controller.isSupplyPumpBusy.value ||
//                                     !controller.isConnected.value
//                                 ? null
//                                 : () => controller.toggleDrainPump("on_supply"),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: controller.supplyPumpState.value
//                                   ? Colors.green
//                                   : null,
//                             ),
//                             child: Text(
//                               textAlign: TextAlign.center,
//                               controller.supplyPumpState.value
//                                   ? 'Supply Pump ON'
//                                   : 'Turn ON Supply Pump',
//                               style: GoogleFonts.poppins(
//                                   color: !controller.supplyPumpState.value
//                                       ? Colors.grey
//                                       : Colors.white,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ),

//                           // OFF Button
//                           ElevatedButton(
//                             onPressed: controller.isSupplyPumpBusy.value ||
//                                     !controller.isConnected.value
//                                 ? null
//                                 : () =>
//                                     controller.toggleDrainPump("off_supply"),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: !controller.supplyPumpState.value
//                                   ? Colors.red
//                                   : null,
//                             ),
//                             child: Text(
//                               textAlign: TextAlign.center,
//                               !controller.supplyPumpState.value
//                                   ? 'Supply Pump OFF'
//                                   : 'Turn OFF Supply Pump',
//                               style: GoogleFonts.poppins(
//                                   color: !controller.supplyPumpState.value
//                                       ? Colors.white
//                                       : Colors.grey,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ),

//                           // ON Button
//                           ElevatedButton(
//                             onPressed: controller.isDrainPumpBusy.value ||
//                                     !controller.isConnected.value
//                                 ? null
//                                 : () => controller.toggleDrainPump("on"),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: controller.drainPumpState.value
//                                   ? Colors.green
//                                   : null,
//                             ),
//                             child: Text(
//                               textAlign: TextAlign.center,
//                               controller.drainPumpState.value
//                                   ? 'Drain Pump ON'
//                                   : 'Turn ON Drain Pump',
//                               style: GoogleFonts.poppins(
//                                   color: !controller.drainPumpState.value
//                                       ? Colors.grey
//                                       : Colors.white,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ),

//                           // OFF Button
//                           ElevatedButton(
//                             onPressed: controller.isDrainPumpBusy.value ||
//                                     !controller.isConnected.value
//                                 ? null
//                                 : () => controller.toggleDrainPump("off"),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: !controller.drainPumpState.value
//                                   ? Colors.red
//                                   : null,
//                             ),
//                             child: Text(
//                               textAlign: TextAlign.center,
//                               !controller.drainPumpState.value
//                                   ? 'Drain Pump OFF'
//                                   : 'Turn OFF Drain Pump',
//                               style: GoogleFonts.poppins(
//                                   color: !controller.drainPumpState.value
//                                       ? Colors.white
//                                       : Colors.grey,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                         ],
//                       )),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }
// }
