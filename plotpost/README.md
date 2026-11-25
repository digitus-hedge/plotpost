# plotpost

PlotPost is a Flutter property-listing app.

## Running with the backend

The app's default API URL targets the host machine from a web build or emulator:

- Android emulator: `http://10.0.2.2:5000/api`
- iOS simulator: `http://localhost:5000/api`
- Web: `http://localhost:5000/api`

On a physical phone, `localhost` refers to the phone itself. Use the development
computer's LAN IP instead, and make sure the backend accepts connections from
the LAN and the computer's firewall allows port 5000. For example:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.25:5000/api
```

Replace `192.168.1.25` with the development computer's LAN IP. Android debug
builds and iOS local-network connections allow the app to use this local HTTP
backend. Use an HTTPS URL for deployed or production backends.

The API URL is set at build/run time; restart the app after changing it.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
