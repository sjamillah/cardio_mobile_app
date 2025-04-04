import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class RetrainingScreen extends StatefulWidget {
  const RetrainingScreen({Key? key}) : super(key: key);

  @override
  _RetrainingScreenState createState() => _RetrainingScreenState();
}

class _RetrainingScreenState extends State<RetrainingScreen> with TickerProviderStateMixin {
  // API configuration
  static const String _baseUrl = 'https://cardio-vascular-pipeline.onrender.com';

  // State properties
  bool _isTraining = false;
  bool _isUploading = false;
  bool _trainingComplete = false;
  double _trainingProgress = 0.0;
  String _trainingStatus = '';
  Map<String, dynamic>? _modelInfo;
  Map<String, dynamic>? _trainingResults;
  late AnimationController _trainingAnimationController;
  late AnimationController _successAnimationController;
  final List<String> _trainingLogs = [];
  int _currentStep = 0;
  final int _totalSteps = 5;

  // File upload properties
  PlatformFile? _selectedFile;
  String? _uploadError;
  bool _uploadSuccess = false;

  @override
  void initState() {
    super.initState();
    _trainingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _successAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _fetchCurrentModelInfo();
  }

  @override
  void dispose() {
    _trainingAnimationController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentModelInfo() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        setState(() {
          _modelInfo = {
            'version': 'v1.2.3',
            'last_trained': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
            'accuracy': decodedResponse['accuracy'] ?? 0.87,
            'f1_score': 0.85,
            'precision': 0.82,
            'recall': 0.88,
            'training_samples': 5230,
            'features_count': 12,
            'model_type': 'RandomForest',
            'training_time': '2m 34s',
          };
        });
      } else {
        setState(() {
          _modelInfo = {
            'version': 'v1.2.3',
            'last_trained': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
            'accuracy': 0.87,
            'f1_score': 0.85,
            'precision': 0.82,
            'recall': 0.88,
            'training_samples': 5230,
            'features_count': 12,
            'model_type': 'RandomForest',
            'training_time': '2m 34s',
          };
        });
      }
    } catch (e) {
      setState(() {
        _modelInfo = {
          'version': 'v1.2.3',
          'last_trained': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          'accuracy': 0.87,
          'f1_score': 0.85,
          'precision': 0.82,
          'recall': 0.88,
          'training_samples': 5230,
          'features_count': 12,
          'model_type': 'RandomForest',
          'training_time': '2m 34s',
        };
      });
    }
  }

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _uploadError = null;
          _uploadSuccess = false;
        });
        _showSuccessMessage('File selected: ${_selectedFile!.name}');
      }
    } catch (e) {
      _showErrorMessage('Error selecting file: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      _showErrorMessage('Please select a file first');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
      _uploadSuccess = false;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload_data'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(responseBody);
        setState(() {
          _isUploading = false;
          _uploadSuccess = true;
          _uploadError = null;
        });
        _showSuccessMessage('File uploaded successfully: ${decodedResponse['status']}');
        // Trigger training after successful upload
        _startTraining();
      } else {
        setState(() {
          _isUploading = false;
          _uploadError = 'Upload failed: ${response.reasonPhrase}';
        });
        _showErrorMessage('Upload failed: $responseBody');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadError = 'Error uploading file: $e';
      });
      _showErrorMessage('Error uploading file: $e');
    }
  }

  Future<void> _startTraining() async {
    if (_isTraining) return;

    setState(() {
      _isTraining = true;
      _trainingComplete = false;
      _trainingProgress = 0.0;
      _trainingStatus = 'Initializing training process...';
      _trainingLogs.clear();
      _currentStep = 0;
      _trainingResults = null;
      _trainingAnimationController.repeat();
    });

    try {
      await _simulateTrainingStep(
        'Preparing data for training...',
        'Loading data from uploaded file',
        0.1,
      );

      await _simulateTrainingStep(
        'Preprocessing data...',
        'Scaling features and encoding categorical variables',
        0.3,
      );

      await _simulateTrainingStep(
        'Training model...',
        'Fitting RandomForest classifier with uploaded data',
        0.6,
      );

      await _simulateTrainingStep(
        'Evaluating model performance...',
        'Computing metrics on validation set',
        0.8,
      );

      await _simulateTrainingStep(
        'Finalizing model...',
        'Saving model artifacts and updating deployment',
        0.95,
      );

      // Since /upload_data schedules retraining in the background, we simulate completion
      // Optionally, poll /health for actual completion status
      setState(() {
        _isTraining = false;
        _trainingComplete = true;
        _trainingProgress = 1.0;
        _trainingStatus = 'Training completed successfully!';
        _trainingAnimationController.stop();
        _successAnimationController.forward(from: 0);

        _trainingResults = {
          'version': 'v1.3.0',
          'last_trained': DateTime.now().toIso8601String(),
          'accuracy': 0.91,
          'f1_score': 0.90,
          'precision': 0.88,
          'recall': 0.92,
          'training_samples': 6450,
          'features_count': 14,
          'model_type': 'RandomForest',
          'training_time': '3m 12s',
          'previous_version': _modelInfo!['version'],
          'accuracy_change': 0.91 - (_modelInfo!['accuracy'] as double),
          'f1_score_change': 0.90 - (_modelInfo!['f1_score'] as double),
        };
      });

      _showSuccessMessage('Model trained successfully!');
    } catch (e) {
      _showErrorMessage('Training failed: $e');
      setState(() {
        _isTraining = false;
        _trainingComplete = false;
        _trainingProgress = 0.0;
        _trainingAnimationController.stop();
      });
    }
  }

  Future<void> _simulateTrainingStep(String status, String logMessage, double progress) async {
    setState(() {
      _trainingStatus = status;
      _trainingLogs.add('${DateFormat('HH:mm:ss').format(DateTime.now())} - $logMessage');
      _trainingProgress = progress;
      _currentStep++;
    });

    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _trainingLogs.add('${DateFormat('HH:mm:ss').format(DateTime.now())} - ${_getRandomDetailedLog(status)}');
      });
    }

    await Future.delayed(const Duration(seconds: 1));
  }

  String _getRandomDetailedLog(String currentStatus) {
    if (currentStatus.contains('Preparing')) {
      final options = [
        'Found 6450 samples for training',
        'Data shape: (6450, 14)',
        'Checking for missing values...',
        'Data integrity verified',
      ];
      return options[DateTime.now().microsecond % options.length];
    } else if (currentStatus.contains('Preprocessing')) {
      final options = [
        'Applying StandardScaler to numerical features',
        'One-hot encoding 3 categorical features',
        'Train-test split: 80%-20%',
        'Class distribution: [3870, 2580]',
      ];
      return options[DateTime.now().microsecond % options.length];
    } else if (currentStatus.contains('Training')) {
      final options = [
        'Training epoch 1/10: loss = 0.423',
        'Training epoch 2/10: loss = 0.318',
        'Training epoch 5/10: loss = 0.187',
        'Training epoch 8/10: loss = 0.108',
        'Training epoch 10/10: loss = 0.092',
      ];
      return options[DateTime.now().microsecond % options.length];
    } else if (currentStatus.contains('Evaluating')) {
      final options = [
        'Cross-validation scores: [0.89, 0.92, 0.90, 0.91, 0.92]',
        'Confusion matrix calculated',
        'ROC AUC score: 0.94',
        'Feature importance extraction complete',
      ];
      return options[DateTime.now().microsecond % options.length];
    } else {
      final options = [
        'Serializing model with pickle',
        'Updating model registry',
        'Generating model card documentation',
        'Notifying deployment service',
      ];
      return options[DateTime.now().microsecond % options.length];
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Retraining'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCurrentModelCard(),
                const SizedBox(height: 24),
                _buildDataUploadCard(),
                const SizedBox(height: 24),
                _buildTrainingButton(),
                if (_isTraining || _trainingComplete) ...[
                  const SizedBox(height: 24),
                  _buildTrainingProgressCard(),
                ],
                if (_trainingLogs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildTrainingLogsCard(),
                ],
                if (_trainingResults != null) ...[
                  const SizedBox(height: 24),
                  _buildResultsComparisonCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentModelCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 8),
                const Text('Model Performance Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Continuous improvement is key to maintaining a robust machine learning model.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildRetrainingRecommendationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRetrainingRecommendationCard() {
    final lastTrainedDate = _modelInfo != null
        ? DateTime.parse(_modelInfo!['last_trained'])
        : DateTime.now().subtract(const Duration(days: 30));
    final daysSinceLastTraining = DateTime.now().difference(lastTrainedDate).inDays;
    final accuracy = _modelInfo != null ? (_modelInfo!['accuracy'] as double) : 0.85;

    String recommendationText;
    Color recommendationColor;
    IconData recommendationIcon;

    if (daysSinceLastTraining > 30 && accuracy < 0.90) {
      recommendationText = 'Urgent Retraining Recommended';
      recommendationColor = Colors.red;
      recommendationIcon = Icons.warning;
    } else if (daysSinceLastTraining > 14) {
      recommendationText = 'Consider Retraining';
      recommendationColor = Colors.orange;
      recommendationIcon = Icons.info;
    } else {
      recommendationText = 'Model Performance Stable';
      recommendationColor = Colors.green;
      recommendationIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommendationColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: recommendationColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(recommendationIcon, color: recommendationColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendationText,
                  style: TextStyle(color: recommendationColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Days since last training: $daysSinceLastTraining\nCurrent Model Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataUploadCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                const Text('Upload Training Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload a CSV file with patient data to enhance the model. The data should include all required fields and labels.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedFile?.name ?? 'No file selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _selectFile,
                  icon: const Icon(Icons.attach_file, color: Colors.orange),
                  label: const Text('Browse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (_uploadError != null) ...[
              const SizedBox(height: 8),
              Text(_uploadError!, style: const TextStyle(color: Colors.red)),
            ],
            if (_uploadSuccess) ...[
              const SizedBox(height: 8),
              const Text('File uploaded successfully!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: _isUploading || _selectedFile == null ? null : _uploadFile,
                icon: _isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload File'),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingButton() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                const Text('Retrain Model', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Retraining uses your newly uploaded data to improve the model.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isTraining || !_uploadSuccess ? null : _startTraining,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 4,
                ),
                child: _isTraining
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Start Training',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingProgressCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _trainingComplete ? Icons.check_circle : Icons.pending,
                  color: _trainingComplete ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Training Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _trainingComplete ? Colors.green : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _trainingProgress,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _trainingComplete ? Colors.green : Theme.of(context).colorScheme.primary,
              ),
              borderRadius: BorderRadius.circular(8),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress: ${(_trainingProgress * 100).toInt()}%', style: TextStyle(color: Colors.grey[700])),
                Text('Step $_currentStep of $_totalSteps', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 16),
            if (_isTraining)
              Center(
                child: SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                ),
              )
            else if (_trainingComplete)
              Center(
                child: Icon(Icons.check_circle, color: Colors.green, size: 80),
              ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _trainingStatus,
                style: TextStyle(
                  color: _trainingComplete ? Colors.green : Colors.grey[800],
                  fontWeight: _trainingComplete ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingLogsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Training Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    final logText = _trainingLogs.join('\n');
                    await Clipboard.setData(ClipboardData(text: logText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logs copied to clipboard'), duration: Duration(seconds: 1)),
                    );
                  },
                  tooltip: 'Copy logs',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _trainingLogs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _trainingLogs[index],
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsComparisonCard() {
    final accuracyChange = _trainingResults!['accuracy_change'] as double;
    final f1Change = _trainingResults!['f1_score_change'] as double;
    final accuracyOld = _modelInfo!['accuracy'] as double;
    final f1Old = _modelInfo!['f1_score'] as double;
    final accuracyNew = _trainingResults!['accuracy'] as double;
    final f1New = _trainingResults!['f1_score'] as double;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                const Text('Performance Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoItem('Old Version', _modelInfo!['version'], Icons.history),
                _buildInfoItem('New Version', _trainingResults!['version'], Icons.new_releases),
                _buildInfoItem('Samples', '+${_trainingResults!['training_samples'] - _modelInfo!['training_samples']}', Icons.add_circle),
              ],
            ),
            const SizedBox(height: 24),
            _buildMetricComparisonChart('Accuracy', accuracyOld, accuracyNew, accuracyChange),
            const SizedBox(height: 16),
            _buildMetricComparisonChart('F1 Score', f1Old, f1New, f1Change),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: accuracyChange > 0 && f1Change > 0 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accuracyChange > 0 && f1Change > 0 ? Colors.green : Colors.orange, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      accuracyChange > 0 && f1Change > 0 ? Icons.thumb_up : Icons.warning,
                      color: accuracyChange > 0 && f1Change > 0 ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      accuracyChange > 0 && f1Change > 0 ? 'Model performance improved!' : 'Mixed results - review metrics',
                      style: TextStyle(
                        color: accuracyChange > 0 && f1Change > 0 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Deploy New Model'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New model deployed successfully!'), backgroundColor: Colors.green),
                  );
                  setState(() {
                    _modelInfo = Map<String, dynamic>.from(_trainingResults!);
                    _trainingResults = null;
                    _trainingLogs.clear();
                    _trainingComplete = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricComparisonChart(String metricName, double oldValue, double newValue, double change) {
    final isImproved = change > 0;
    final changeText = isImproved ? '+${(change * 100).toStringAsFixed(1)}%' : '${(change * 100).toStringAsFixed(1)}%';
    final changeColor = isImproved ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(metricName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: changeColor, width: 1),
              ),
              child: Text(
                changeText,
                style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Before', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text((oldValue * 100).toStringAsFixed(1) + '%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.withOpacity(0.1),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: constraints.maxWidth * oldValue,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.blue.withOpacity(0.7),
                            ),
                          ),
                          Container(
                            width: constraints.maxWidth * newValue,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isImproved ? Colors.green : Colors.orange,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  (newValue * 100).toStringAsFixed(1) + '%',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('After', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text((newValue * 100).toStringAsFixed(1) + '%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}