class TurbidityReading {
  final DateTime timestamp;
  final String value;

  TurbidityReading({required this.timestamp, required this.value});

  // Add JSON serialization methods
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'value': value,
      };

  factory TurbidityReading.fromJson(Map<String, dynamic> json) =>
      TurbidityReading(
        timestamp: DateTime.parse(json['timestamp']),
        value: json['value'],
      );
}
