import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../model/turbidty_reading.dart';

class DataVisualizationScreen extends StatefulWidget {
  const DataVisualizationScreen({super.key});

  @override
  State<DataVisualizationScreen> createState() =>
      _DataVisualizationScreenState();
}

class _DataVisualizationScreenState extends State<DataVisualizationScreen> {
  List<TurbidityReading> readings = [];
  bool isLoading = false;
  String? error;
  int selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await ApiService.getRecentData(days: selectedDays);
      setState(() {
        readings = data;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Historical Data',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Time range selector
          _buildTimeRangeCard(),

          const SizedBox(height: 16),

          // Chart
          _buildChartCard(),

          // Statistics
          if (readings.isNotEmpty) _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nilai Sensor Over Time',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Range',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTimeRangeButton(1, 'Last 24 Hours')),
                const SizedBox(width: 8),
                Expanded(child: _buildTimeRangeButton(7, 'Last 7 Days')),
                const SizedBox(width: 8),
                Expanded(child: _buildTimeRangeButton(30, 'Last 30 Days')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeButton(int days, String label) {
    final isSelected = selectedDays == days;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedDays = days;
        });
        _loadData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading data...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Text(
          'Error: $error',
          style: GoogleFonts.poppins(
            color: Colors.red,
          ),
        ),
      );
    }

    if (readings.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat:
            selectedDays == 1 ? DateFormat('HH:mm') : DateFormat('MM/dd'),
        intervalType: selectedDays == 1
            ? DateTimeIntervalType.hours
            : DateTimeIntervalType.days,
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(
          text: 'Nilai Sensor',
          textStyle: GoogleFonts.poppins(),
        ),
      ),
      legend: const Legend(isVisible: true),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<TurbidityReading, DateTime>>[
        LineSeries<TurbidityReading, DateTime>(
          name: 'Nilai Sensor',
          dataSource: readings,
          xValueMapper: (TurbidityReading reading, _) => reading.timestamp,
          yValueMapper: (TurbidityReading reading, _) =>
              double.tryParse(reading.value) ?? 0,
          color: Colors.blue,
          width: 2,
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            borderWidth: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final turbidityValues = readings
        .map((r) => double.tryParse(r.value) ?? 0)
        .where((v) => v > 0)
        .toList();

    if (turbidityValues.isEmpty) return const SizedBox();

    final average =
        turbidityValues.reduce((a, b) => a + b) / turbidityValues.length;
    final minimum = turbidityValues.reduce((a, b) => a < b ? a : b);
    final maximum = turbidityValues.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    'Average', average.toStringAsFixed(1), Colors.blue),
                _buildStatItem(
                    'Minimum', minimum.toStringAsFixed(1), Colors.green),
                _buildStatItem(
                    'Maximum', maximum.toStringAsFixed(1), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
