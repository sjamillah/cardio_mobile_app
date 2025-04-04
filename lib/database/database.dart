import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class MongoService {
  static const String _baseUrl = 'https://cardio-vascular-pipeline.onrender.com';
  static const String _dbName = "cardio_database";
  static const String _collectionName = "cardio_info";
  static const String _batchCollection = "upload_batches";

  // Initialize the service (equivalent to ensure_db_exists)
  Future<bool> ensureDbExists() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/ensure_db'));
      if (response.statusCode == 200) {
        print('Connected to MongoDB and initialized database');
        return true;
      } else {
        print('Failed to initialize database: ${response.reasonPhrase}');
        return false;
      }
    } catch (e) {
      print('Error in ensureDbExists: $e');
      print('Warning: Running with limited database functionality');
      return false;
    }
  }

  // Import CSV to database
  Future<int> importCsvToDb(String csvPath) async {
    try {
      final file = File(csvPath);
      final bytes = await file.readAsBytes();
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/import_csv'))
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: csvPath.split('/').last,
        ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = jsonDecode(responseBody);
        print('Imported ${result['num_records']} records from CSV');
        return result['num_records'] ?? 0;
      } else {
        print('Error importing CSV: ${response.reasonPhrase}');
        return 0;
      }
    } catch (e) {
      print('Error importing CSV: $e');
      return 0;
    }
  }

  // Get training data
  Future<Map<String, dynamic>?> getTrainingData({int? limit, bool onlyNew = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl/get_training_data').replace(queryParameters: {
        'limit': limit?.toString(),
        'only_new': onlyNew.toString(),
      });
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['X'] == null || data['Y'] == null) return null;

        final X = List<Map<String, dynamic>>.from(data['X']);
        final Y = List<String>.from(data['Y']);
        return {'X': X, 'Y': Y};
      } else {
        print('Error fetching training data: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error fetching training data: $e');
      return null;
    }
  }

  // Get record count
  Future<int> getRecordCount() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/record_count'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else {
        print('Error getting record count: ${response.reasonPhrase}');
        return 0;
      }
    } catch (e) {
      print('Error getting record count: $e');
      return 0;
    }
  }

  // Get training stats
  Future<Map<String, dynamic>> getTrainingStats() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/training_stats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'total_records': data['total_records'] ?? 0,
          'used_for_training': data['used_for_training'] ?? 0,
          'unused_for_training': data['unused_for_training'] ?? 0,
          'risk_level_counts': Map<String, int>.from(data['risk_level_counts'] ?? {}),
          'recent_batches': List<Map<String, dynamic>>.from(data['recent_batches'] ?? []),
        };
      } else {
        print('Error getting training stats: ${response.reasonPhrase}');
        return {};
      }
    } catch (e) {
      print('Error getting training stats: $e');
      return {};
    }
  }

  // Export to CSV
  Future<int> exportToCsv(String outputPath, {int? limit}) async {
    try {
      final uri = Uri.parse('$_baseUrl/export_to_csv').replace(queryParameters: {
        'limit': limit?.toString(),
      });
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final csvContent = data['csv_content'] as String;
        final file = File(outputPath);
        await file.writeAsString(csvContent);
        print('Exported ${data['num_records']} records to $outputPath');
        return data['num_records'] ?? 0;
      } else {
        print('Error exporting to CSV: ${response.reasonPhrase}');
        return 0;
      }
    } catch (e) {
      print('Error exporting to CSV: $e');
      return 0;
    }
  }

  // Add single record
  Future<String?> addSingleRecord(Map<String, dynamic> recordData) async {
    try {
      final processedData = _preprocessSingleDatapoint(recordData);
      processedData['upload_date'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      processedData['used_for_training'] = false;

      final response = await http.post(
        Uri.parse('$_baseUrl/add_record'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(processedData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Added record with ID: ${data['inserted_id']}');
        return data['inserted_id'];
      } else {
        print('Error adding record: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error adding record: $e');
      return null;
    }
  }

  // Placeholder for preprocessing single datapoint (client-side simulation)
  Map<String, dynamic> _preprocessSingleDatapoint(Map<String, dynamic> data) {
    // Simulate preprocessing (actual logic should be on backend)
    final processed = Map<String, dynamic>.from(data);
    if (!processed.containsKey('risk_level')) {
      // Dummy risk level assignment (replace with actual logic)
      processed['risk_level'] = processed['age'] != null && processed['age'] > 50 ? 1 : 0;
    }
    return processed;
  }
}

// Example usage in a Flutter widget
class MongoExample extends StatefulWidget {
  const MongoExample({Key? key}) : super(key: key);

  @override
  _MongoExampleState createState() => _MongoExampleState();
}

class _MongoExampleState extends State<MongoExample> {
  final MongoService _mongoService = MongoService();
  String _status = '';

  @override
  void initState() {
    super.initState();
    _mongoService.ensureDbExists().then((success) {
      setState(() => _status = success ? 'Database initialized' : 'Database init failed');
    });
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null) {
      final count = await _mongoService.importCsvToDb(result.files.single.path!);
      setState(() => _status = 'Imported $count records');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MongoDB Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            ElevatedButton(
              onPressed: _importCsv,
              child: const Text('Import CSV'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = await _mongoService.getTrainingData(limit: 10);
                setState(() => _status = 'Fetched ${data?['X'].length ?? 0} records');
              },
              child: const Text('Get Training Data'),
            ),
          ],
        ),
      ),
    );
  }
}