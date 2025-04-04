# Cardio Health App

A professional-grade Flutter application for cardiovascular health monitoring and risk assessment, featuring machine learning-powered predictions and comprehensive data visualization.

## Overview

The Cardio Health App is designed to help healthcare professionals monitor patient cardiovascular health, assess risk factors, and make data-driven decisions. The application utilizes machine learning models to analyze patient data and predict cardiovascular risk levels.

## Features

### Dashboard
- At-a-glance system health monitoring
- Key performance metrics including prediction counts and model accuracy
- Interactive charts displaying weekly prediction trends
- Notification system for important updates and activities

### Prediction
- Comprehensive patient data input form
- Real-time cardiovascular risk assessment
- Detailed results with risk probability and recommendations
- Ability to save predictions to patient records

### Data Visualization
- Feature distribution analysis
- Correlation visualization between different health metrics
- Target distribution charts
- Interactive data exploration capabilities

### Model Management
- CSV data upload functionality
- Model retraining with new data
- Detailed training progress tracking
- Performance comparison between model versions
- One-click deployment of improved models

## Technical Details

### Backend Integration
The app connects to a Python FastAPI backend with endpoints for:
- `/predict` - Generating cardiovascular risk predictions
- `/visualize/{feature}` - Creating feature distribution visualizations
- `/visualize/feature_importance` - Analyzing model feature importance
- `/upload_data` - Uploading CSV training data
- `/retrain` - Retraining the machine learning model
- `/health` - Checking system status

### Machine Learning
- Random Forest classifier for prediction
- Feature importance analysis for model interpretability
- Comprehensive performance metrics (accuracy, F1 score, precision, recall)

## Getting Started

### Prerequisites
- Flutter SDK
- Dart
- Access to the cardiovascular prediction API

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/sjamillah/cardio_health_app.git
   cd cardio_health_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

### Building for Production

Generate a release build:
```bash
flutter build apk --release
```

Or for iOS:
```bash
flutter build ios --release
```

## CSV Data Format

For uploading training data, use the following CSV format:

```
age,height,weight,gender,ap_hi,ap_lo,cholesterol,gluc,cultural_belief_score,treatment_adherence,distance_to_healthcare,risk_level
12000,165.0,70.0,1,120,80,1,1,"Occasionally","High","Near",0
14600,172.5,85.2,1,135,88,2,1,"Frequently","Medium","Moderate",1
```

Field descriptions:
- `age`: Age in days
- `height`: Height in cm
- `weight`: Weight in kg
- `gender`: 0 = female, 1 = male
- `ap_hi`: Systolic blood pressure
- `ap_lo`: Diastolic blood pressure
- `cholesterol`: 1 = normal, 2 = above normal, 3 = well above normal
- `gluc`: Glucose level (1-3 scale)
- `cultural_belief_score`: "Never", "Occasionally", or "Frequently"
- `treatment_adherence`: "Low", "Medium", or "High"
- `distance_to_healthcare`: "Near", "Moderate", or "Far"
- `risk_level`: 0 = low risk, 1 = medium risk, 2 = high risk

## License

[Your license information here]

## Acknowledgements

- FastAPI for backend services
- Flutter for the frontend framework
- Scikit-learn for machine learning functionality
