This project is a 5G Network Speed Test & Analysis App that measures and analyzes mobile network performance using Flutter for the frontend, Flask for backend services, Firebase for data storage, and an ML model (developed by a collaborator) to estimate performance metrics.


Flutter Frontend -
Intuitive UI/UX designed for seamless navigation.
Bottom Navigation Bar Google Nav Bar to switch between:
Home Page
Map Page
Preset Page
Settings Page

UI/UX developed by me, ensuring smooth interaction and modern aesthetics.

Flask Backend -
Hosts a Flask server (deployed on PythonAnywhere https://ritamsen1512.pythonanywhere.com/speedtest) that:
Runs real-time speed tests (Download, Upload, Ping).
Stores network details in Firebase Realtime Database.
Fetches ML-based estimations from Firestore.
Uses flask_cors for Cross-Origin Requests from Flutter.
Utilizes speedtest API to measure:
Download Speed (Mbps)
Upload Speed (Mbps)
Ping (ms)
Saves test results in Firebase with a unique ID for tracking.

Network Signal Data - 
Fetches signal parameters via SignalHandler.kt in Kotlin:
RSRP (Reference Signal Received Power)
RSRQ (Reference Signal Received Quality)
TAC, CID, EARFCN, SS, MCC, MNC, Bandwidth, PCI
Merges signal strength data with speed test results.

ML Model Integration -
The ML model (developed by a collaborator https://github.com/ojasraverkar/spectrai_random_forest_ojasML) estimates:
Future download/upload speeds for various 4G & 5G bands.
Network performance based on signal strength.
Fetches ML-calculated results from Firestore.

Firebase Integration -
Stores network test results in Realtime Database.
Fetches ML estimations from Firestore.
Supports real-time updates & synchronization.


**Upcoming Features
Interactive Map:
Display real-time network performance on a Google Map widget.
Advanced Network Analytics:
Graphs & insights based on historical speed test data.
CSV Export:
Allow users to export test results for further analysis.
Background Testing:
Run speed tests in the background at scheduled intervals.
5G Band Recommendations:
Suggest the best frequency bands based on location & signal strength.
**

Credits -
UI/UX & Flutter Development: Ritam Sen |||
ML Model & Predictions: Ojas Raverkar |||
Backend & API Integrations: Ritam Sen

