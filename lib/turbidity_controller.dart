import 'dart:convert';
import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'package:smart_water/model/turbidty_reading.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TurbidityController extends GetxController {
  final String broker = 's7ca81ae.ala.asia-southeast1.emqxsl.com';
  final int port = 8883;
  final String username = 'eliz';
  final String password = 'zilepassword';
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
      // _saveReading();
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

  void _saveReading(TurbidityReading newReading) {
    // Load existing readings from shared preferences
    final existingReadingsJson = _prefs?.getString('turbidityReadings');
    List<TurbidityReading> allReadings = [];

    // Parse existing readings if they exist
    if (existingReadingsJson != null) {
      final List<dynamic> existingReadings = json.decode(existingReadingsJson);
      allReadings = existingReadings
          .map((reading) => TurbidityReading.fromJson(reading))
          .toList();
    }

    // Append the new reading
    allReadings.add(newReading);

    // Optional: Prune readings older than 3 days
    final now = DateTime.now();
    allReadings = allReadings
        .where((reading) =>
            now.difference(reading.timestamp).inDays < 3) // Keep last 3 days
        .toList();

    // Save the updated list to shared preferences
    final allReadingsJson =
        json.encode(allReadings.map((reading) => reading.toJson()).toList());
    _prefs?.setString('turbidityReadings', allReadingsJson);
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

    // Persist readings
    _saveReading(TurbidityReading(timestamp: DateTime.now(), value: payload));
  }

  Future<List<TurbidityReading>> getAllReadingsFromSharedPreferences() async {
    final readingsJson = _prefs?.getString('turbidityReadings');
    if (readingsJson == null) {
      return [];
    }

    // Decode all readings
    final List<dynamic> decodedReadings = json.decode(readingsJson);
    final List<TurbidityReading> allReadings = decodedReadings
        .map((reading) => TurbidityReading.fromJson(reading))
        .toList();

    // Get the current time
    final now = DateTime.now();

    // Filter readings to get the latest 12 hours data
    final List<TurbidityReading> last12HoursReadings = allReadings
        .where((reading) => now.difference(reading.timestamp).inHours < 12)
        .toList();

    // Filter readings to get 6 data points per hour
    final Map<int, List<TurbidityReading>> hourlyReadings = {};
    for (var reading in last12HoursReadings) {
      final hour = reading.timestamp.hour;
      if (!hourlyReadings.containsKey(hour)) {
        hourlyReadings[hour] = [];
      }
      // Add reading if less than 6 readings for this hour
      if (hourlyReadings[hour]!.length < 10) {
        hourlyReadings[hour]!.add(reading);
      }
    }

    // Flatten the map to a list
    return hourlyReadings.values.expand((readings) => readings).toList();
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
