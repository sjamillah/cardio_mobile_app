import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class VisualizationScreen extends StatefulWidget {
  const VisualizationScreen({Key? key}) : super(key: key);

  @override
  _VisualizationScreenState createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen>
    with SingleTickerProviderStateMixin {
  // API configuration
  static const String _baseUrl = 'https://cardio-vascular-pipeline.onrender.com';

  final List<Color> _gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  late TabController _tabController;
  int _selectedVisualization = 0;
  String _selectedFeature = 'age';
  bool _isLoading = false;
  String? _visualizationImage;
  String? _featureImportanceImage;
  String? _error;

  // List of features that can be visualized
  final List<Map<String, String>> _availableFeatures = [
    {'value': 'age', 'display': 'Age'},
    {'value': 'gender', 'display': 'Gender'},
    {'value': 'height', 'display': 'Height'},
    {'value': 'weight', 'display': 'Weight'},
    {'value': 'ap_hi', 'display': 'Systolic BP'},
    {'value': 'ap_lo', 'display': 'Diastolic BP'},
    {'value': 'cholesterol', 'display': 'Cholesterol'},
    {'value': 'gluc', 'display': 'Glucose'},
    {'value': 'cultural_belief_score', 'display': 'Cultural Belief'},
    {'value': 'treatment_adherence', 'display': 'Treatment Adherence'},
    {'value': 'distance_to_healthcare', 'display': 'Healthcare Distance'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedVisualization = _tabController.index;

        // Fetch the appropriate visualization when tab changes
        if (_selectedVisualization == 0) {
          _fetchFeatureVisualization(_selectedFeature);
        } else {
          _fetchFeatureImportance();
        }
      });
    });

    // Fetch initial visualization
    _fetchFeatureVisualization(_selectedFeature);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFeatureVisualization(String feature) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/visualize/$feature'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _visualizationImage = data['image'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch visualization: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFeatureImportance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/visualize/feature_importance'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _featureImportanceImage = data['image'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch feature importance: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: const Text('Data Visualizations'),
              floating: true,
              pinned: true,
              forceElevated: innerBoxIsScrolled,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              expandedHeight: 120.0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.secondary,
                indicatorWeight: 4,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.bar_chart),
                    text: 'Feature Distribution',
                  ),
                  Tab(
                    icon: Icon(Icons.insights),
                    text: 'Feature Importance',
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildFeatureDistributionTab(),
            _buildFeatureImportanceTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureDistributionTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Feature Distribution',
            content:
            'This visualization shows how each feature is distributed across your dataset. Identifying the distribution patterns can help understand the data characteristics and detect outliers.',
            icon: Icons.bar_chart,
          ),
          const SizedBox(height: 24),
          _buildFeatureSelector(),
          const SizedBox(height: 24),
          _buildVisualizationCard(),
        ],
      ),
    );
  }

  Widget _buildFeatureImportanceTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Feature Importance',
            content:
            'This visualization shows which features have the strongest impact on the model\'s predictions. Understanding feature importance helps identify key risk factors and areas for intervention.',
            icon: Icons.insights,
          ),
          const SizedBox(height: 24),
          _buildFeatureImportanceCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
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
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSelector() {
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
            const Text(
              'Select Feature',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
              value: _selectedFeature,
              items: _availableFeatures.map((feature) {
                return DropdownMenuItem<String>(
                  value: feature['value'],
                  child: Text(feature['display']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFeature = newValue;
                    _fetchFeatureVisualization(_selectedFeature);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribution of ${_getFeatureDisplayName(_selectedFeature)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : _error != null
                ? _buildErrorWidget()
                : _visualizationImage != null
                ? Column(
              children: [
                Image.memory(
                  base64Decode(_visualizationImage!),
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                _buildInsightsForFeature(_selectedFeature),
              ],
            )
                : _buildSampleVisualization(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureImportanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model Feature Importance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : _error != null
                ? _buildErrorWidget()
                : _featureImportanceImage != null
                ? Column(
              children: [
                Image.memory(
                  base64Decode(_featureImportanceImage!),
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                _buildFeatureImportanceInsights(),
              ],
            )
                : _buildSampleFeatureImportance(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Error Loading Visualization',
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_selectedVisualization == 0) {
                _fetchFeatureVisualization(_selectedFeature);
              } else {
                _fetchFeatureImportance();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleVisualization() {
    // Create a sample histogram for demonstration when API fails
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 20,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              barGroups: List.generate(
                10,
                    (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: 5 + math.Random().nextDouble() * 15,
                      color: _gradientColors[0],
                      width: 18,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      gradient: LinearGradient(
                        colors: _gradientColors,
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange,
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Using sample visualization. API data not available.',
                  style: TextStyle(
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSampleFeatureImportance() {
    // Create a sample feature importance visualization for demonstration when API fails
    final features = [
      {'name': 'age', 'importance': 0.28},
      {'name': 'ap_hi', 'importance': 0.22},
      {'name': 'ap_lo', 'importance': 0.18},
      {'name': 'cholesterol', 'importance': 0.15},
      {'name': 'weight', 'importance': 0.10},
      {'name': 'height', 'importance': 0.07},
    ];

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 0.3,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= features.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          features[value.toInt()]['name'] as String,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              barGroups: List.generate(
                features.length,
                    (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: features[index]['importance'] as double,
                      color: Colors.purple,
                      width: 18,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.purpleAccent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange,
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Using sample feature importance. API data not available.',
                  style: TextStyle(
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsForFeature(String feature) {
    String insight;

    switch (feature) {
      case 'age':
        insight = 'Age appears to have a normal distribution centered around middle age. Older age is a well-established risk factor for cardiovascular disease.';
        break;
      case 'gender':
        insight = 'Gender distribution shows differences in cardiovascular risk profiles between males and females. Males typically have higher risks at younger ages.';
        break;
      case 'height':
        insight = 'Height follows a bimodal distribution reflecting general male and female population ranges.';
        break;
      case 'weight':
        insight = 'Weight data shows typical population distribution with a slightly right-skewed pattern indicating some presence of higher-weight individuals.';
        break;
      case 'ap_hi':
        insight = 'Systolic blood pressure shows peaks around normal (120mmHg) and elevated (140mmHg) values, highlighting hypertension prevalence.';
        break;
      case 'ap_lo':
        insight = 'Diastolic blood pressure has highest frequency around 80mmHg with secondary peaks indicating presence of patients with hypertensive readings.';
        break;
      case 'cholesterol':
        insight = 'Cholesterol distribution shows that a substantial portion of the population has elevated or high cholesterol levels, a key cardiovascular risk factor.';
        break;
      case 'gluc':
        insight = 'Glucose data indicates presence of both normal values and elevated levels, reflecting the contribution of diabetes to cardiovascular risk.';
        break;
      case 'cultural_belief_score':
        insight = 'Cultural beliefs show varied impacts on health outcomes, with many individuals reporting occasional influence.';
        break;
      case 'treatment_adherence':
        insight = 'Treatment adherence data suggests good compliance in many patients, though there is a notable portion with lower adherence.';
        break;
      case 'distance_to_healthcare':
        insight = 'Distance to healthcare facilities shows a distribution that highlights access challenges for a segment of the population.';
        break;
      default:
        insight = 'Analysis of this feature reveals patterns that can help understand cardiovascular risk factors and patient populations.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Insights:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(insight),
        ],
      ),
    );
  }

  Widget _buildFeatureImportanceInsights() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Insights:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Age, blood pressure, cholesterol, and glucose levels appear to be the most influential factors in predicting cardiovascular risk. These traditional risk factors continue to demonstrate strong predictive power in the model.',
          ),
          SizedBox(height: 8),
          Text(
            'Social determinants such as treatment adherence and distance to healthcare facilities show moderate importance, highlighting the comprehensive approach of this model in considering both biological and social factors.',
          ),
        ],
      ),
    );
  }

  String _getFeatureDisplayName(String feature) {
    for (var f in _availableFeatures) {
      if (f['value'] == feature) {
        return f['display'] ?? feature;
      }
    }
    return feature;
  }
}