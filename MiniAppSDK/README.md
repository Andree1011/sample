# MiniApp SDK for iOS

A comprehensive iOS native SDK for the SuperApp architecture, providing all necessary middleware components for building and managing mini apps.

## Overview

The MiniApp SDK provides a complete set of middleware components that enable a host iOS application to load, manage, and communicate with mini apps. It follows the SuperApp architecture pattern, allowing multiple lightweight mini applications to run within a single host app.

## Requirements

- iOS 12.0+
- Swift 5.5+
- Xcode 13+

## Platform Compatibility

The package targets **iOS 12.0+**. Some Apple frameworks used by the SDK have their own API availability windows, so iOS 10+ APIs are guarded internally.

| Component | Framework | API Availability |
|-----------|-----------|------------------|
| `NotificationManager` | UserNotifications | iOS 10.0+ |
| `BiometricService` | LocalAuthentication | Base auth APIs: iOS 8.0+; biometric type detection (`biometryType`): iOS 11.0+ |
| `IoTService` / `DeviceManager` | CoreBluetooth | iOS 5.0+ |
| `NetworkService` | URLSession | iOS 7.0+ |
| `CacheManager` | FileManager | iOS 2.0+ |
| `PaymentService` | Foundation-based flow | iOS 12.0+ target compatible |

Availability guard example:

```swift
if #available(iOS 10.0, *) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
        DispatchQueue.main.async {
            print("Notifications granted: \(granted)")
        }
    }
}
```

> Note: The SDK implementation additionally serializes notification-center operations on a dedicated dispatch queue (`NotificationManager`) before returning callbacks on the main thread.

## Required Skills for Mini App SDK Development

- Swift fundamentals: protocols, error handling, async patterns, generics
- iOS framework integration: Foundation, WebKit, UserNotifications, LocalAuthentication, CoreBluetooth
- Concurrency: `DispatchQueue`, thread-safe state access, callback synchronization
- SDK/API design: backward compatibility, clear public APIs, semantic versioning
- Testing: XCTest, async tests, service-level isolation

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/MiniAppSDK.git", from: "1.0.0")
]
```

Or add it via Xcode: **File > Add Packages** and enter the repository URL.

## Architecture

```
MiniAppSDK/
├── Sources/
│   ├── Core/           - Central manager, configuration, error types
│   ├── Loader/         - Mini app loading and lifecycle management
│   ├── Cache/          - Bundle and resource caching (LRU)
│   ├── Auth/           - Authentication, token, and keychain management
│   ├── Security/       - Biometric auth and permission management
│   ├── Network/        - HTTP client with interceptors and retry logic
│   ├── Notification/   - Local and push notification handling
│   ├── Payment/        - Payment processing and transaction management
│   ├── IoT/            - Bluetooth device integration
│   └── Bridge/         - Host ↔ Mini App communication bridge
└── Tests/              - Unit tests for all components
```

## Quick Start

### 1. Initialize the SDK

```swift
import MiniAppSDK

// In your AppDelegate or SceneDelegate
let config = MiniAppConfig(
    baseURL: URL(string: "https://your-miniapp-server.com")!,
    appId: "your-host-app-id",
    apiKey: "your-api-key",
    environment: .production
)

do {
    try MiniAppManager.shared.initialize(with: config)
} catch {
    print("SDK initialization failed: \(error)")
}
```

### 2. Load a Mini App

```swift
let loader = MiniAppManager.shared.loader

loader.loadApp(appId: "my-mini-app") { result in
    switch result {
    case .success(let manifest):
        print("Loaded: \(manifest.name)")
        // Mount the app to display it
        loader.mountApp(appId: manifest.appId) { _ in }
    case .failure(let error):
        print("Load failed: \(error)")
    }
}
```

### 3. Authenticate Users

```swift
let auth = MiniAppManager.shared.authService

auth.signIn(username: "user@example.com", password: "password") { result in
    switch result {
    case .success(let user):
        print("Signed in: \(user.username)")
    case .failure(let error):
        print("Auth failed: \(error)")
    }
}
```

### 4. Set Up the Bridge

```swift
import WebKit

// In your view controller
let webView = WKWebView()
let bridge = MiniAppBridge()
bridge.initialize(with: webView)

// Register native methods accessible from JavaScript
bridge.register(method: "getUserInfo") { params, completion in
    let userInfo = ["name": "John", "email": "john@example.com"]
    completion(.success(userInfo))
}

// Send events to the mini app
bridge.sendEvent(eventName: "themeChanged", data: ["theme": "dark"])
```

### 5. Handle Permissions

```swift
let permissionLayer = SDKPermissionLayer()

permissionLayer.grantPermission(.camera, to: "my-mini-app") { result in
    switch result {
    case .success(let status):
        print("Camera permission: \(status)")
    case .failure(let error):
        print("Permission denied: \(error)")
    }
}
```

### 6. Process Payments

```swift
let paymentService = MiniAppManager.shared.paymentService

paymentService.processPayment(
    amount: 2999, // $29.99 in cents
    currency: "USD",
    paymentMethod: .creditCard,
    description: "Premium subscription"
) { result in
    switch result {
    case .success(let transaction):
        print("Payment completed: \(transaction.transactionId)")
    case .failure(let error):
        print("Payment failed: \(error)")
    }
}
```

### 7. Connect IoT Devices

```swift
let iotService = MiniAppManager.shared.iotService

iotService.onDeviceDiscovered = { device in
    print("Found device: \(device.name)")
}

iotService.startScanning { result in
    if case .failure(let error) = result {
        print("Scan failed: \(error)")
    }
}
```

## Components

### Core

| Component | Description |
|-----------|-------------|
| `MiniAppManager` | Central coordinator and dependency injection container |
| `MiniAppConfig` | SDK configuration with validation |
| `MiniAppError` | Comprehensive error types for all SDK operations |

### Loader

| Component | Description |
|-----------|-------------|
| `MiniAppLoader` | Load, initialize, mount, and unmount mini apps |
| `AppLifecycleManager` | Track and respond to mini app lifecycle events |
| `AppManifest` | Mini app metadata and configuration |

### Cache

| Component | Description |
|-----------|-------------|
| `CacheManager` | Thread-safe LRU memory and disk cache |
| `StorageManager` | File system persistence for cached data |
| `CachePolicy` | Configurable caching behavior |

### Auth

| Component | Description |
|-----------|-------------|
| `AuthenticationService` | User sign-in/sign-out and session management |
| `TokenManager` | Access/refresh token lifecycle |
| `KeychainManager` | Secure credential storage using iOS Keychain |
| `User` | User model with authentication state |

### Security

| Component | Description |
|-----------|-------------|
| `BiometricService` | Face ID and Touch ID authentication |
| `PermissionManager` | Device-level permission requests and status |
| `SDKPermissionLayer` | Per-app permission management |
| `Permission` | Permission types and status definitions |

### Network

| Component | Description |
|-----------|-------------|
| `NetworkService` | High-level HTTP service with retry logic |
| `HTTPClient` | URLSession wrapper with interceptor support |
| `RequestInterceptor` | Request/response modification pipeline |
| `NetworkError` | Network-specific error types |

### Notification

| Component | Description |
|-----------|-------------|
| `NotificationService` | Schedule and manage notifications |
| `NotificationManager` | UserNotifications framework integration |
| `LocalNotification` | Local notification model |

### Payment

| Component | Description |
|-----------|-------------|
| `PaymentService` | Payment processing and refund handling |
| `TransactionManager` | Transaction tracking and status management |
| `Transaction` | Payment transaction model |

### IoT

| Component | Description |
|-----------|-------------|
| `IoTService` | Device scanning, connection, and communication |
| `DeviceManager` | CoreBluetooth integration |
| `Device` | IoT device model with connection state |

### Bridge

| Component | Description |
|-----------|-------------|
| `MiniAppBridge` | WebView JavaScript bridge for host-app communication |
| `MethodInvoker` | Native method registration and invocation |
| `BridgeMessage` | Message format for bridge communication |

## Thread Safety

All SDK components are thread-safe. They use `DispatchQueue` with concurrent reads and barrier writes to ensure data consistency without blocking the main thread.

## Error Handling

The SDK uses a unified `MiniAppError` enum for all error conditions. Each error includes a descriptive `errorDescription` that can be displayed to users or logged for debugging.

```swift
do {
    try MiniAppManager.shared.checkInitialized()
} catch MiniAppError.notInitialized {
    // Handle not initialized
} catch MiniAppError.networkFailed(let message) {
    // Handle network error
} catch {
    // Handle other errors
}
```

## Testing

Run the test suite using Swift Package Manager:

```bash
cd MiniAppSDK
swift test
```

Or through Xcode: **Product > Test** (⌘U)

## License

Copyright © 2024. All rights reserved.
