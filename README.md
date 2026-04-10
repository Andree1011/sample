# SuperApp Demo Architecture

A complete demonstration of a **SuperApp system** — a container application that hosts multiple web-based mini apps through a native iOS SDK middleware layer.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  Host App (Flutter)                  │
│  Login · Dashboard · Marketplace · Profile · Settings│
└────────────────────────┬────────────────────────────┘
                         │ Method Channels / Platform Bridge
┌────────────────────────▼────────────────────────────┐
│             Mini App SDK (iOS Native - Swift)         │
│  MiniAppManager · BundleLoader · CacheManager         │
│  AuthService · BiometricService · PermissionManager   │
│  NetworkService · NotificationService · PaymentService│
│  IoTService · MiniAppBridge (JS ↔ Native)            │
└────────────────────────┬────────────────────────────┘
                         │ WKWebView + JavaScript Bridge
┌─────────────────────────────────────────────────────┐
│          Web-based Mini Apps (HTML/CSS/JS)            │
│  shopping-bundle  ·  health-bundle  ·  chat-bundle   │
└─────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
sample/
├── README.md                    # This file
├── MiniAppSDK/                  # iOS Native SDK (Swift)
│   ├── Package.swift
│   ├── Sources/
│   │   ├── Core/                # MiniAppManager, Config, Error
│   │   ├── Loader/              # Bundle loading & app lifecycle
│   │   ├── Cache/               # LRU caching & storage
│   │   ├── Auth/                # JWT tokens & Keychain
│   │   ├── Security/            # Biometric (Face/Touch ID) & permissions
│   │   ├── Network/             # URLSession HTTP client with interceptors
│   │   ├── Notification/        # Local & push notifications
│   │   ├── Payment/             # Transaction processing
│   │   ├── IoT/                 # Bluetooth device integration
│   │   └── Bridge/              # WKWebView JavaScript ↔ Native bridge
│   └── Tests/                   # Unit tests for all components
│
├── HostApp/                     # Flutter Host Application
│   ├── lib/
│   │   ├── main.dart            # App entry point
│   │   ├── screens/             # Login, Home, Marketplace, Profile, Settings
│   │   ├── models/              # User, MiniApp, Payment
│   │   ├── services/            # Auth, MiniApp, Payment, Notification
│   │   ├── widgets/             # MiniAppGrid, MiniAppCard, BottomNavBar
│   │   └── utils/               # Constants, MockData
│   └── pubspec.yaml
│
└── MiniApps/                    # Web-based Mini App Bundles
    ├── shopping-bundle/         # 🛍️ E-commerce mini app
    │   ├── index.html
    │   ├── css/style.css
    │   ├── js/
    │   │   ├── bridge.js        # Native bridge SDK
    │   │   ├── api.js           # Mock product API
    │   │   └── app.js           # App logic
    │   └── manifest.json
    ├── health-bundle/           # ❤️ Health & fitness mini app
    │   ├── index.html
    │   ├── css/style.css
    │   ├── js/
    │   │   ├── bridge.js        # Native bridge SDK
    │   │   ├── charts.js        # Activity chart renderer
    │   │   └── app.js           # App logic
    │   └── manifest.json
    └── chat-bundle/             # 💬 Real-time messaging mini app
        ├── index.html
        ├── css/style.css
        ├── js/
        │   ├── bridge.js        # Native bridge SDK
        │   ├── websocket.js     # WebSocket manager
        │   └── app.js           # App logic
        └── manifest.json
```

---

## 1. Mini App SDK (iOS Native - Swift)

The middleware layer between the Flutter host app and web-based mini apps.

### Key Components

| Component | File | Purpose |
|-----------|------|---------|
| `MiniAppManager` | Core/MiniAppManager.swift | Central orchestrator, singleton entry point |
| `MiniAppBridge` | Bridge/MiniAppBridge.swift | JavaScript ↔ Native communication via WKWebView |
| `MiniAppLoader` | Loader/MiniAppLoader.swift | Download & manage web bundles |
| `CacheManager` | Cache/CacheManager.swift | LRU cache for bundles & resources |
| `AuthenticationService` | Auth/AuthenticationService.swift | JWT token management |
| `BiometricService` | Security/BiometricService.swift | Face ID / Touch ID |
| `PermissionManager` | Security/PermissionManager.swift | iOS permission management |
| `NetworkService` | Network/NetworkService.swift | HTTP client with interceptors |
| `NotificationService` | Notification/NotificationService.swift | Push & local notifications |
| `PaymentService` | Payment/PaymentService.swift | Transaction processing |
| `IoTService` | IoT/IoTService.swift | Bluetooth device communication |

### Quick Start

```swift
import MiniAppSDK

// Initialize SDK
let config = MiniAppConfig(
    baseURL: URL(string: "https://api.superapp.com")!,
    appId: "host-app-id",
    apiKey: "your-api-key"
)
try MiniAppManager.shared.initialize(with: config)

// Load & display a mini app
let loader = MiniAppManager.shared.loader
loader.loadApp(appId: "shopping") { result in
    switch result {
    case .success(let manifest):
        // Mount in WKWebView with bridge
        let bridge = MiniAppBridge()
        bridge.initialize(with: webView)
        bridge.register(method: "payment.startPayment") { params, completion in
            // Handle native payment
        }
    case .failure(let error):
        print("Error:", error)
    }
}
```

### JavaScript Bridge API

Mini apps call native features using the bridge:

```javascript
// Payment
const result = await MiniApp.payment.startPayment({
    amount: 49.99,
    currency: 'USD',
    description: 'Order #12345'
});

// Biometric auth
const auth = await MiniApp.security.requestBiometricAuth();

// User info
const user = await MiniApp.auth.getUserInfo();

// Notifications
await MiniApp.notification.showNotification({
    title: 'Order Shipped!',
    body: 'Your order is on the way'
});

// IoT devices
const devices = await MiniApp.iot.getDeviceList();
await MiniApp.iot.connectDevice(devices[0].id);
const data = await MiniApp.iot.readDeviceData(devices[0].id);

// Permissions
const granted = await MiniApp.permission.requestPermission('camera');
```

### Running Tests

```bash
cd MiniAppSDK
swift test
```

---

## 2. Host App (Flutter)

The main container app that users interact with.

### Screens

- **Login Screen** — Email/password + biometric (Face ID / Touch ID)
- **Home Dashboard** — Grid of installed mini apps + quick actions
- **Marketplace** — Browse, search, filter and install mini apps
- **Profile** — User info, stats, biometric settings
- **Settings** — Theme, permissions, payments, cache management
- **Mini App Container** — Loads and runs mini apps with native bridge UI

### Running the Flutter App

```bash
cd HostApp
flutter pub get
flutter run
```

### State Management

Uses **GetX** for reactive state management:
- `AuthService` — User authentication state
- `MiniAppService` — Installed apps & marketplace
- `PaymentService` — Transaction history
- `NotificationService` — Unread notifications

---

## 3. Web-based Mini Apps

Each mini app is a self-contained web bundle (HTML/CSS/JS) that:
1. Gets downloaded as a `.zip` file
2. Is extracted to the app's documents directory by the SDK
3. Loads in a `WKWebView` container
4. Communicates with native features via `MiniAppBridge`

### 🛍️ Shopping Mini App

Features: product browsing, search/filter, cart management, native payment checkout, order confirmation.

Native bridge calls used:
- `MiniApp.auth.getUserInfo()`
- `MiniApp.payment.startPayment({...})`
- `MiniApp.notification.showNotification({...})`

### ❤️ Health Mini App

Features: activity dashboard, weekly charts, health metrics, IoT device connection, biometric verification, goals tracking.

Native bridge calls used:
- `MiniApp.security.requestBiometricAuth()`
- `MiniApp.iot.getDeviceList()`
- `MiniApp.iot.connectDevice(deviceId)`
- `MiniApp.iot.readDeviceData(deviceId)`
- `MiniApp.storage.saveHealthMetrics({...})`
- `MiniApp.permission.requestPermission('camera')`

### 💬 Chat Mini App

Features: conversation list, real-time messaging, typing indicators, online/offline status, search, simulated WebSocket responses.

Native bridge calls used:
- `MiniApp.notification.onPushReceived(callback)`
- `MiniApp.network.getStatus()`
- `MiniApp.storage.saveMessages({...})`
- `MiniApp.device.playSound('notification')`
- `MiniApp.permission.requestPermission('notification')`

---

## 🚀 Demo Workflow

1. **Open Host App** → Login screen appears
2. **Sign In** → Use email/password or tap "Face ID / Touch ID"
3. **Home Dashboard** → See installed mini apps (Shopping, Health, Chat)
4. **Tap Shopping app** → Opens in native container with product grid
5. **Add to cart** → Tap "Add to Cart" on any product
6. **Checkout** → Triggers native payment sheet via JavaScript bridge
7. **Order confirmed** → Native notification sent via bridge
8. **Marketplace** → Browse and install additional mini apps
9. **Settings** → Manage permissions, theme, payment methods

---

## 🔒 Security

- All bridge calls are validated by the SDK before execution
- Permission system requires explicit user grants
- Payment calls require user confirmation dialog
- Biometric authentication integrated for sensitive operations
- Certificate pinning available in NetworkService

## 📦 Bundle Management

Mini apps are distributed as ZIP bundles containing:
- `index.html` — Entry point
- `css/` — Stylesheets
- `js/bridge.js` — Native bridge SDK (injected by host)
- `js/app.js` — Application logic
- `manifest.json` — App metadata (id, version, permissions)

The SDK handles: download → extraction → version check → cache → load in WKWebView.
