import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'package:smart_water/model/turbidty_reading.dart';
import 'package:smart_water/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TurbidityController extends GetxController {
  final String broker = dotenv.env['BROKER']!;
  final int port = 1883;
  final String username = dotenv.env['USERNAME']!;
  final String password = dotenv.env['PASSWORD']!;
  final String topicTurbidity = 'emqx/esp8266/turbidity';
  final String topicDrainPump = 'emqx/esp8266/pump';
  final String topicAutomaticDrainPump = 'emqx/esp8266/automatic-drain-pump';

  late MqttServerClient client;
  SharedPreferences? _prefs;

  var connectionError = ''.obs;
  var turbidityValue = "0".obs;
  var isConnected = false.obs;

  var drainPumpState = false.obs;
  var isDrainPumpBusy = false.obs;

  var supplyPumpState = false.obs;
  var isSupplyPumpBusy = false.obs;

  var automaticDrainPumpEnabled = false.obs;
  var automaticDrainPumpThreshold = ''.obs;

  // Add a debounce mechanism
  Timer? _savePreferencesTimer;

  // List to store recent Turbidity Sensor readings
  final RxList<TurbidityReading> recentReadings = <TurbidityReading>[].obs;

  @override
  void onInit() async {
    _prefs = await SharedPreferences.getInstance();
    // Check if this is the first time the app is run
    bool isFirstRun = _prefs?.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      // Set default initial values
      await _prefs?.setBool('drainPumpState', false);
      await _prefs?.setBool('supplyPumpState', false);
      await _prefs?.setBool('automaticDrainPumpEnabled', false);
      await _prefs?.setString('automaticDrainPumpThreshold', '');

      // Mark that first run is complete
      await _prefs?.setBool('isFirstRun', false);
    }

    // Now load the values
    drainPumpState.value = _prefs?.getBool('drainPumpState') ?? false;
    supplyPumpState.value = _prefs?.getBool('supplyPumpState') ?? false;
    automaticDrainPumpEnabled.value =
        _prefs?.getBool('automaticDrainPumpEnabled') ?? false;
    automaticDrainPumpThreshold.value =
        _prefs?.getString('automaticDrainPumpThreshold') ?? '';

    super.onInit();
    connectToMQTT();
  }

  void _debounceSavePreferences() {
    _savePreferencesTimer?.cancel();
    _savePreferencesTimer = Timer(const Duration(milliseconds: 500), () {
      _savePumpState();
      // Data is now saved automatically by the Python API via MQTT
    });
  }

  void _savePumpState() {
    _prefs?.setBool('drainPumpState', drainPumpState.value);
    _prefs?.setBool('supplyPumpState', supplyPumpState.value);
    _prefs?.setBool(
        'automaticDrainPumpEnabled', automaticDrainPumpEnabled.value);
    _prefs?.setString(
        'automaticDrainPumpThreshold', automaticDrainPumpThreshold.value);
  }

  Future<void> connectToMQTT() async {
    try {
      // Add more detailed logging
      print('Attempting to connect to broker: $broker on port $port');

      client = MqttServerClient(
          broker, 'flutter_${DateTime.now().millisecondsSinceEpoch}');
      client.port = port;
      client.secure = false;
      // client.logging(on: true);
      // client.setProtocolV311();
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

    // Data is now automatically saved by the Python API via MQTT
    // No need to save locally anymore
  }

  // Updated method to get readings from API instead of local storage
  Future<List<TurbidityReading>> getAllReadingsFromApi({int days = 1}) async {
    try {
      return await ApiService.getRecentData(days: days);
    } catch (e) {
      print('Error fetching data from API: $e');
      return [];
    }
  }

  // Keep the old method name for backward compatibility, but use API
  Future<List<TurbidityReading>> getAllReadingsFromSharedPreferences() async {
    return getAllReadingsFromApi(days: 1);
  }

  void toggleDrainPump(String command) {
    // Check connection first
    if (!isConnected.value) {
      Get.snackbar('Error', 'Not connected to MQTT broker');
      return;
    }

    if (command == "on" || command == "off") {
      // setAutomaticDrainPump(false);
      automaticDrainPumpThreshold.value = '0';
      automaticDrainPumpEnabled.value = false;
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

    // Reset busy state after a delay
    Timer(const Duration(seconds: 2), () {
      isPumpBusy.value = false;
    });

    // Update state based on the command
    pumpState.value = command.contains("on");

    // Save the updated state
    _savePumpState();
    _debounceSavePreferences();
  }

  void setAutomaticDrainPump(bool enable, {String threshold = ''}) {
    if (!isConnected.value) {
      Get.snackbar('Error', 'Not connected to MQTT broker');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    if (enable) {
      if (threshold.isEmpty) {
        Get.snackbar('Error', 'Please provide a threshold');
        return;
      }
      builder.addString('{"mode": "on", "threshold": $threshold}');
      automaticDrainPumpThreshold.value = threshold;
    } else {
      threshold = '0';
      builder.addString('{"mode": "off", "threshold": $threshold}');
      automaticDrainPumpThreshold.value = '0';
    }

    try {
      client.publishMessage(
          topicAutomaticDrainPump, MqttQos.atLeastOnce, builder.payload!);

      // Update and save automatic drain pump state
      automaticDrainPumpEnabled.value = enable;
      drainPumpState.value = false;
      _savePumpState();
    } catch (e) {
      print('Error publishing MQTT message: $e');
      Get.snackbar('Error', 'Failed to send MQTT message');
    }

    _debounceSavePreferences();
  }

  @override
  void onClose() {
    disconnectMQTT();
    super.onClose();
  }
}
