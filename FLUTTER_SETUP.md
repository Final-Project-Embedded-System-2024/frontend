# Smart Water Monitoring System - Flutter App

This Flutter application integrates with a Python API backend to provide real-time water turbidity monitoring with AI-powered daily summaries.

## Features

- **Real-time Monitoring**: Live turbidity readings via MQTT
- **Pump Control**: Manual and automatic drain pump control
- **Data Visualization**: Historical data charts and statistics
- **AI Summaries**: Daily AI-generated summaries of water quality data
- **API Integration**: Seamless integration with Python FastAPI backend

## Setup Instructions

### Prerequisites

1. Flutter SDK (>= 3.5.3)
2. Python API server running (see your Python API script)
3. MQTT broker access

### Installation

1. **Clone and setup the Flutter app:**
   ```bash
   cd smart_water
   flutter pub get
   ```

2. **Configure environment variables:**
   
   Update the `.env` file with your configuration:
   ```properties
   BROKER = "your-mqtt-broker.com"
   USERNAME = "your-mqtt-username"
   PASSWORD = "your-mqtt-password"
   API_BASE_URL = "http://your-api-server.com:8000"
   ```

3. **Setup Python API Server:**
   
   Make sure your Python API server is running with the provided script. The server should handle:
   - Data storage via MQTT
   - API endpoints for data retrieval
   - AI summary generation

4. **Run the app:**
   ```bash
   flutter run
   ```

## Key Changes Made

### 1. API Integration
- Added `http` package for API communication
- Created `ApiService` class to handle all API calls
- Updated `TurbidityReading` model to support API data format

### 2. Data Management
- Removed local SQLite storage (now handled by Python API)
- Updated controller to use API for historical data
- Maintained local state for real-time MQTT data

### 3. New Features
- **AI Summary Screen**: Daily AI-generated summaries
- **Data Visualization Screen**: Historical data charts with statistics
- **Enhanced Navigation**: Added new tabs and navigation options

### 4. Updated UI
- Added AI Summary tab in bottom navigation
- Added chart icon in app bar for data visualization
- Improved error handling and loading states

## Architecture

```
Flutter App (Frontend)
├── MQTT Client (Real-time data)
├── HTTP Client (Historical data & AI summaries)
└── UI Components
    ├── Home (Live monitoring)
    ├── Settings (Pump controls)
    ├── AI Summary (Daily insights)
    └── Data Visualization (Charts)

Python API (Backend)
├── MQTT Handler (Data ingestion)
├── SQLite Database (Data storage)
├── FastAPI Server (API endpoints)
└── OpenAI Integration (AI summaries)
```

## API Endpoints Used

- `POST /data` - Get historical data by date range
- `GET /summary/{date}` - Get AI summary for a specific date

## Dependencies Added

- `http: ^1.1.0` - For API communication

## Configuration Notes

1. **API Base URL**: Update `API_BASE_URL` in `.env` to point to your Python API server
2. **MQTT Topics**: Ensure MQTT topics match between Flutter app and Python API
3. **Network**: Make sure Flutter app can reach the Python API server

## Usage

1. **Home Screen**: View real-time turbidity readings and live chart
2. **Settings Screen**: Configure automatic drain pump settings
3. **AI Summary Screen**: View AI-generated daily summaries
4. **Data Visualization**: Access via chart icon, view historical trends

## Troubleshooting

1. **API Connection Issues**: 
   - Verify API_BASE_URL in .env file
   - Ensure Python API server is running
   - Check network connectivity

2. **MQTT Connection Issues**:
   - Verify MQTT broker credentials
   - Check broker accessibility

3. **No Data in Charts**:
   - Ensure Python API has historical data
   - Check date ranges in API calls
