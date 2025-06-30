class TurbidityReading {
  final DateTime timestamp;
  final String value;
  final String? drainPump;
  final bool? automaticMode;

  TurbidityReading({
    required this.timestamp,
    required this.value,
    this.drainPump,
    this.automaticMode,
  });

  // Add JSON serialization methods for local storage
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'value': value,
        'drainPump': drainPump,
        'automaticMode': automaticMode,
      };

  factory TurbidityReading.fromJson(Map<String, dynamic> json) =>
      TurbidityReading(
        timestamp: DateTime.parse(json['timestamp']),
        value: json['value'],
        drainPump: json['drainPump'],
        automaticMode: json['automaticMode'],
      );

  // Add JSON serialization methods for API data
  factory TurbidityReading.fromApiJson(Map<String, dynamic> json) =>
      TurbidityReading(
        timestamp: DateTime.parse(json['timestamp']),
        value: json['turbidity'].toString(),
        drainPump: json['drain_pump'],
        automaticMode: json['automatic_mode'],
      );

  Map<String, dynamic> toApiJson() => {
        'timestamp': timestamp.toIso8601String(),
        'turbidity': int.tryParse(value) ?? 0,
        'drain_pump': drainPump ?? 'off',
        'automatic_mode': automaticMode ?? false,
      };
}
