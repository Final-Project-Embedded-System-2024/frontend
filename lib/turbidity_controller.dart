import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'package:smart_water/model/turbidty_reading.dart';

class TurbidityController extends GetxController {
  final String broker = 's7ca81ae.ala.asia-southeast1.emqxsl.com';
  final int port = 8883;
  final String username = 'eliz';
  final String password = 'zilepassword';
  final String topicTurbidity = 'emqx/esp8266/turbidity';
  final String topicDrainPump = 'emqx/esp8266/pump';

  late MqttServerClient client;
  var connectionError = ''.obs;
  var turbidityValue = "0".obs;
  var isConnected = false.obs;

  var drainPumpState = false.obs;
  var isDrainPumpBusy = false.obs;

  var supplyPumpState = false.obs;
  var isSupplyPumpBusy = false.obs;

  // List to store recent Turbidity Sensor readings
  final RxList<TurbidityReading> recentReadings = <TurbidityReading>[].obs;

  @override
  void onInit() {
    super.onInit();
    connectToMQTT();
  }

  Future<void> connectToMQTT() async {
    try {
      // Add more detailed logging
      print('Attempting to connect to broker: $broker on port $port');

      client = MqttServerClient(broker, 'flutter_client');
      client.port = port;
      client.secure = true;
      client.logging(on: true); // Enable logging for more details
      client.setProtocolV311();
      client.keepAlivePeriod = 20;

      // More comprehensive error handling
      client.onConnected = () {
        print('Connected to MQTT broker successfully');
        isConnected.value = true;
      };

      client.onDisconnected = () {
        print('Disconnected from MQTT broker');
        isConnected.value = false;
      };

      final connMessage = MqttConnectMessage()
          .withClientIdentifier('flutter_client')
          .authenticateAs(username, password)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMessage;

      await client.connect().then((_) {
        if (client.connectionStatus?.state == MqttConnectionState.connected) {
          client.subscribe(topicTurbidity, MqttQos.atLeastOnce);
          client.updates?.listen(onMessage);
        } else {
          throw Exception('Connection failed after connect attempt');
        }
      }).catchError((error) {
        print('Connection error: $error');
        connectionError.value = 'Connection failed: $error';
      });
    } catch (e) {
      print('Exception during MQTT connection: $e');
      connectionError.value = 'Connection exception: $e';
    }
  }

  void disconnectMQTT() {
    try {
      client.disconnect();
    } catch (e) {
      // Ignore disconnect errors
    }
    isConnected.value = false;
  }

  void onDisconnected() {
    isConnected.value = false;
    connectionError.value = 'Disconnected from MQTT broker';
  }

  void onMessage(List<MqttReceivedMessage<MqttMessage>>? messages) {
    final MqttPublishMessage message =
        messages![0].payload as MqttPublishMessage;
    final payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);

    // Update Turbidity value
    turbidityValue.value = payload;

    // Add to recent readings
    recentReadings.insert(
        0, TurbidityReading(timestamp: DateTime.now(), value: payload));

    // Keep only the last 10 readings
    if (recentReadings.length > 10) {
      recentReadings.removeRange(10, recentReadings.length);
    }
  }

  void toggleDrainPump(String command) {
    // Prevent spam and ensure connection
    if (!isConnected.value) {
      Get.snackbar('Error', 'Not connected to MQTT broker');
      return;
    }

    // Determine which pump is being controlled
    bool isSupplyPump = command.contains("supply");
    var isPumpBusy = isSupplyPump ? isSupplyPumpBusy : isDrainPumpBusy;
    var pumpState = isSupplyPump ? supplyPumpState : drainPumpState;

    // If already processing a request, ignore
    if (isPumpBusy.value) {
      Get.snackbar('Wait', 'Previous command is being processed');
      return;
    }

    // Set busy state
    isPumpBusy.value = true;

    // Prepare MQTT message
    final builder = MqttClientPayloadBuilder();
    builder.addString(command);
    client.publishMessage(isSupplyPump ? topicDrainPump : topicDrainPump,
        MqttQos.atLeastOnce, builder.payload!);

    // Reset busy state after a delay to prevent rapid consecutive commands
    Timer(const Duration(seconds: 2), () {
      isPumpBusy.value = false;
    });

    // Update state based on the command
    pumpState.value = command.contains("on");
  }
}
