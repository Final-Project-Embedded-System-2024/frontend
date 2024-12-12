import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LDR Monitor and LED Control',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LDRMonitorScreen(),
    );
  }
}

class LDRReading {
  final DateTime timestamp;
  final String value;

  LDRReading({required this.timestamp, required this.value});
}

class LDRController extends GetxController {
  final String broker = 's7ca81ae.ala.asia-southeast1.emqxsl.com';
  final int port = 8883;
  final String username = 'eliz';
  final String password = 'zilepassword';
  final String topicLDR = 'emqx/esp8266/ldr';
  final String topicLED = 'emqx/esp8266/led';

  late MqttServerClient client;
  var ldrValue = "0".obs;
  var isConnected = false.obs;

  // Observables to track LED states and button interaction
  var led1State = false.obs;
  var led2State = false.obs;
  var isLed1Busy = false.obs;
  var isLed2Busy = false.obs;

  // List to store recent LDR readings
  final RxList<LDRReading> recentReadings = <LDRReading>[].obs;

  @override
  void onInit() {
    super.onInit();
    connectToMQTT();
  }

  Future<void> connectToMQTT() async {
    client = MqttServerClient(broker, 'flutter_client');
    client.port = port;
    client.secure = true;
    client.logging(on: false);
    client.setProtocolV311();
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .authenticateAs(username, password)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Connection failed: $e');
      disconnectMQTT();
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      isConnected.value = true;
      client.subscribe(topicLDR, MqttQos.atLeastOnce);
      client.updates?.listen(onMessage);
    } else {
      disconnectMQTT();
    }
  }

  void disconnectMQTT() {
    client.disconnect();
    isConnected.value = false;
  }

  void onDisconnected() {
    isConnected.value = false;
    print('Disconnected from MQTT broker');
  }

  void onMessage(List<MqttReceivedMessage<MqttMessage>>? messages) {
    final MqttPublishMessage message =
        messages![0].payload as MqttPublishMessage;
    final payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);

    // Update LDR value
    ldrValue.value = payload;

    // Add to recent readings
    recentReadings.insert(
        0, LDRReading(timestamp: DateTime.now(), value: payload));

    // Keep only the last 10 readings
    if (recentReadings.length > 10) {
      recentReadings.removeRange(10, recentReadings.length);
    }
  }

  void toggleLED(String ledType) {
    // Prevent spam and ensure connection
    if (!isConnected.value) {
      Get.snackbar('Error', 'Not connected to MQTT broker');
      return;
    }

    // Determine which LED and its current state
    var isBusy = ledType.contains('2') ? isLed2Busy : isLed1Busy;
    var currentState = ledType.contains('2') ? led2State : led1State;

    // If already processing a request, ignore
    if (isBusy.value) {
      Get.snackbar('Wait', 'Previous command is being processed');
      return;
    }

    // Set busy state
    isBusy.value = true;

    // Prepare MQTT message
    final builder = MqttClientPayloadBuilder();
    builder.addString(ledType);
    client.publishMessage(topicLED, MqttQos.atLeastOnce, builder.payload!);

    // Reset busy state after a delay to prevent rapid consecutive commands
    Timer(const Duration(seconds: 2), () {
      isBusy.value = false;
    });

    // Toggle state (this would ideally be confirmed by a response from the device)
    if (ledType.contains('2')) {
      led2State.value = ledType.contains('on');
    } else {
      led1State.value = ledType.contains('on');
    }
  }
}

class LDRMonitorScreen extends StatelessWidget {
  const LDRMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LDRController controller = Get.put(LDRController());

    return Scaffold(
      appBar: AppBar(
        title: Text('LDR Monitor and LED Control',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Radial Gauge
            Obx(() => SfRadialGauge(
                  enableLoadingAnimation: true,
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 1001,
                      startAngle: 180,
                      endAngle: 360,
                      showLabels: true,
                      axisLineStyle: AxisLineStyle(
                        thickness: 20, // Reduce axis line thickness
                        color: Colors.transparent, // Make axis line invisible
                      ),
                      showAxisLine:
                          false, // Remove the axis line to reduce extra space
                      canScaleToFit: true, // Helps in fitting the gauge
                      radiusFactor: 1.0, // Use full available space
                      ranges: <GaugeRange>[
                        GaugeRange(
                          startValue: 0,
                          endValue: 333,
                          color: Colors.red,
                          startWidth: 20,
                          endWidth: 20,
                        ),
                        GaugeRange(
                          startValue: 333,
                          endValue: 666,
                          color: Colors.orange,
                          startWidth: 20,
                          endWidth: 20,
                        ),
                        GaugeRange(
                          startValue: 666,
                          endValue: 1000,
                          color: Colors.green,
                          startWidth: 20,
                          endWidth: 20,
                        ),
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(
                          value:
                              double.tryParse(controller.ldrValue.value) ?? 0,
                          enableAnimation: true,
                          needleLength: 0.7, // Adjust needle length
                          needleColor: Colors.black,
                        )
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: Text(
                            controller.ldrValue.value,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          angle: 90,
                          positionFactor: 0.3,
                        )
                      ],
                    )
                  ],
                )),

            const SizedBox(height: 20),

            // Linear Gauge
            Obx(() => SfLinearGauge(
                  minimum: 0,
                  maximum: 1000,
                  orientation: LinearGaugeOrientation.horizontal,
                  ranges: <LinearGaugeRange>[
                    LinearGaugeRange(
                        startValue: 0, endValue: 333, color: Colors.red),
                    LinearGaugeRange(
                        startValue: 333, endValue: 666, color: Colors.orange),
                    LinearGaugeRange(
                        startValue: 666, endValue: 1000, color: Colors.green),
                  ],
                  markerPointers: [
                    LinearShapePointer(
                      value: double.tryParse(controller.ldrValue.value) ?? 0,
                      color: Colors.black,
                    )
                  ],
                )),

            const SizedBox(height: 20),

            // Recent Readings List
            Text(
              'Recent Readings',
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
                        title: Text('Value: ${reading.value}'),
                        subtitle: Text(
                            'Time: ${reading.timestamp.toString().substring(0, 19)}'),
                      );
                    },
                  )),
            ),

            // LED Control Buttons in 2x2 Grid
            const SizedBox(height: 20),
            Obx(() => GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 3, // Makes buttons wider
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    // LED 1 ON Button
                    ElevatedButton(
                      onPressed: controller.isLed1Busy.value ||
                              !controller.isConnected.value
                          ? null
                          : () => controller.toggleLED("on"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            controller.led1State.value ? Colors.green : null,
                      ),
                      child: Text(
                        controller.led1State.value
                            ? 'LED 1 ON'
                            : 'Turn ON LED 1',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                    // LED 1 OFF Button
                    ElevatedButton(
                      onPressed: controller.isLed1Busy.value ||
                              !controller.isConnected.value
                          ? null
                          : () => controller.toggleLED("off"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !controller.led1State.value ? Colors.red : null,
                      ),
                      child: Text(
                        !controller.led1State.value
                            ? 'LED 1 OFF'
                            : 'Turn OFF LED 1',
                        style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                    // LED 2 ON Button
                    ElevatedButton(
                      onPressed: controller.isLed2Busy.value ||
                              !controller.isConnected.value
                          ? null
                          : () => controller.toggleLED("on2"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            controller.led2State.value ? Colors.green : null,
                      ),
                      child: Text(
                        controller.led2State.value
                            ? 'LED 2 ON'
                            : 'Turn ON LED 2',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                    // LED 2 OFF Button
                    ElevatedButton(
                      onPressed: controller.isLed2Busy.value ||
                              !controller.isConnected.value
                          ? null
                          : () => controller.toggleLED("off2"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !controller.led2State.value ? Colors.red : null,
                      ),
                      child: Text(
                        !controller.led2State.value
                            ? 'LED 2 OFF'
                            : 'Turn OFF LED 2',
                        style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
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
