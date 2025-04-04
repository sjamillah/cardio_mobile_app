import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class PredictingScreen extends StatefulWidget {
  const PredictingScreen({Key? key}) : super(key: key);

  @override
  _PredictingScreenState createState() => _PredictingScreenState();
}

class _PredictingScreenState extends State<PredictingScreen> with SingleTickerProviderStateMixin {
  // API configuration
  static const String _baseUrl = 'https://cardio-vascular-pipeline.onrender.com';

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();

  // Dropdowns
  int _selectedGender = 1;
  int _selectedCholesterol = 1;
  int _selectedGlucose = 1;
  String _selectedCulturalBelief = 'Occasionally';
  String _selectedTreatmentAdherence = 'High';
  String _selectedDistanceToHealthcare = 'Near';

  // Lists for dropdowns
  final List<String> _culturalBeliefOptions = ['Never', 'Occasionally', 'Frequently'];
  final List<String> _treatmentAdherenceOptions = ['Low', 'Medium', 'High'];
  final List<String> _distanceToHealthcareOptions = ['Near', 'Moderate', 'Far'];

  // State variables
  bool _isLoading = false;
  bool _hasPrediction = false;
  Map<String, dynamic>? _predictionResult;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Set default values
    _ageController.text = '12000'; // approximately 33 years in days
    _heightController.text = '170';
    _weightController.text = '70';
    _systolicController.text = '120';
    _diastolicController.text = '80';
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _makePrediction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasPrediction = false;
      _predictionResult = null;
    });

    try {
      // Create request body
      final Map<String, dynamic> requestBody = {
        'age': int.parse(_ageController.text),
        'height': double.parse(_heightController.text),
        'weight': double.parse(_weightController.text),
        'gender': _selectedGender,
        'ap_hi': int.parse(_systolicController.text),
        'ap_lo': int.parse(_diastolicController.text),
        'cholesterol': _selectedCholesterol,
        'gluc': _selectedGlucose,
        'cultural_belief_score': _selectedCulturalBelief,
        'treatment_adherence': _selectedTreatmentAdherence,
        'distance_to_healthcare': _selectedDistanceToHealthcare,
      };

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        setState(() {
          _predictionResult = jsonDecode(response.body);
          _hasPrediction = true;
          _isLoading = false;
        });
      } else {
        _showErrorMessage('Prediction failed: ${response.body}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorMessage('Error: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Prediction'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Information Card
                _buildInfoCard(),

                const SizedBox(height: 16),

                // Input Form
                _buildInputForm(),

                const SizedBox(height: 24),

                // Prediction Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _makePrediction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Make Prediction',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Prediction Results
                if (_hasPrediction && _predictionResult != null)
                  _buildResultCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cardiovascular Risk Prediction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter patient information below to predict cardiovascular risk level. The model analyzes various factors to estimate risk.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Demographics Section
              _buildSectionHeader('Demographics'),
              const SizedBox(height: 12),

              // Age and Gender
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ageController,
                      label: 'Age (days)',
                      hint: 'e.g., 12000',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Gender',
                      value: _selectedGender,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Female')),
                        DropdownMenuItem(value: 1, child: Text('Male')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedGender = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Height and Weight
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: 'Height (cm)',
                      hint: 'e.g., 170',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      hint: 'e.g., 70',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Clinical Measurements
              _buildSectionHeader('Clinical Measurements'),
              const SizedBox(height: 12),

              // Blood Pressure
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _systolicController,
                      label: 'Systolic (mmHg)',
                      hint: 'e.g., 120',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _diastolicController,
                      label: 'Diastolic (mmHg)',
                      hint: 'e.g., 80',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cholesterol and Glucose
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Cholesterol',
                      value: _selectedCholesterol,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Normal')),
                        DropdownMenuItem(value: 2, child: Text('Above Normal')),
                        DropdownMenuItem(value: 3, child: Text('Well Above Normal')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCholesterol = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Glucose',
                      value: _selectedGlucose,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Normal')),
                        DropdownMenuItem(value: 2, child: Text('Above Normal')),
                        DropdownMenuItem(value: 3, child: Text('Well Above Normal')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedGlucose = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Social Factors
              _buildSectionHeader('Social Factors'),
              const SizedBox(height: 12),

              // Cultural Belief
              _buildDropdown(
                label: 'Cultural Belief Impact',
                value: _selectedCulturalBelief,
                items: _culturalBeliefOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCulturalBelief = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Treatment Adherence and Healthcare Distance
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Treatment Adherence',
                      value: _selectedTreatmentAdherence,
                      items: _treatmentAdherenceOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTreatmentAdherence = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Distance to Healthcare',
                      value: _selectedDistanceToHealthcare,
                      items: _distanceToHealthcareOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDistanceToHealthcare = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        labelStyle: TextStyle(fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        isDense: false,
      ),
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      icon: const Icon(Icons.arrow_drop_down, size: 24),
      isExpanded: true,
    );
  }

  Widget _buildResultCard() {
    final riskLevel = _predictionResult!['risk_level'] as int;
    final riskCategory = _predictionResult!['risk_category'] as String;
    final riskProbability = (_predictionResult!['risk_probability'] as double) * 100;
    final interpretation = _predictionResult!['interpretation'] as String;

    Color riskColor;
    if (riskLevel == 0) {
      riskColor = Colors.green;
    } else if (riskLevel == 1) {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.red;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                    Icon(
                      Icons.analytics_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Prediction Results',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing results...'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Risk Level Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    riskCategory.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Risk Probability: ${riskProbability.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Interpretation
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interpretation:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    interpretation,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recommendations
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommendations:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: _buildRecommendationList(riskLevel),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Result saved to patient records',
                          style: TextStyle(color: Colors.white)
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save to Patient Records'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationList(int riskLevel) {
    List<String> recommendations = [];

    // Common recommendations for all risk levels
    recommendations.add('Regular monitoring of blood pressure and cholesterol levels.');
    recommendations.add('Maintain a balanced diet rich in fruits, vegetables, and whole grains.');

    // Risk-specific recommendations
    if (riskLevel == 0) {
      recommendations.add('Continue annual cardiovascular checkups.');
      recommendations.add('Focus on maintaining current lifestyle habits.');
    } else if (riskLevel == 1) {
      recommendations.add('Schedule follow-up appointment within 3 months.');
      recommendations.add('Consider lifestyle modifications to address risk factors.');
      recommendations.add('Review medication adherence if applicable.');
    } else {
      recommendations.add('Immediate consultation with a cardiologist is recommended.');
      recommendations.add('Comprehensive cardiovascular evaluation needed.');
      recommendations.add('Develop a personalized risk reduction plan with healthcare provider.');
      recommendations.add('Close monitoring of all cardiovascular parameters required.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recommendations.map((recommendation) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}