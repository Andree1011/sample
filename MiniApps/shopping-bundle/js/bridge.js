/**
 * MiniApp Bridge - JavaScript SDK for communicating with the native host app.
 * This script is injected by the iOS SDK (MiniAppBridge.swift) and enables
 * web-based mini apps to call native iOS functions.
 */

window.MiniAppBridge = window.MiniAppBridge || {
  _callbacks: {},
  _eventListeners: {},

  /**
   * Call a native method via the iOS WKWebView message handler.
   * @param {string} method - The native method name
   * @param {object} params - Parameters to pass
   * @returns {Promise}
   */
  callNative: function(method, params) {
    return new Promise((resolve, reject) => {
      const messageId = 'msg_' + Math.random().toString(36).substr(2, 9);
      
      this._callbacks[messageId] = { resolve, reject };

      const message = JSON.stringify({
        messageId,
        type: 'request',
        method,
        payload: params || {}
      });

      // Send to iOS native bridge
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.miniAppBridge) {
        window.webkit.messageHandlers.miniAppBridge.postMessage(message);
      } else {
        // Development fallback - simulate native responses
        setTimeout(() => this._simulateNativeResponse(messageId, method, params), 300);
      }

      // Timeout after 30 seconds
      setTimeout(() => {
        if (this._callbacks[messageId]) {
          delete this._callbacks[messageId];
          reject(new Error('Native call timeout: ' + method));
        }
      }, 30000);
    });
  },

  /**
   * Handle response from native code.
   * Called by the iOS SDK after processing a request.
   */
  handleResponse: function(jsonString) {
    try {
      const data = JSON.parse(jsonString);
      const callback = this._callbacks[data.correlationId];
      if (callback) {
        delete this._callbacks[data.correlationId];
        if (data.error) {
          callback.reject(new Error(data.error.message || 'Native error'));
        } else {
          callback.resolve(data.payload || {});
        }
      }
    } catch (e) {
      console.error('Bridge response parse error:', e);
    }
  },

  /**
   * Listen for events emitted by the native host app.
   */
  onEvent: function(event, callback) {
    if (!this._eventListeners[event]) {
      this._eventListeners[event] = [];
    }
    this._eventListeners[event].push(callback);
  },

  /**
   * Dispatch an event (called by native code).
   */
  dispatchEvent: function(event, data) {
    const listeners = this._eventListeners[event] || [];
    listeners.forEach(fn => fn(data));
  },

  /**
   * Development fallback - simulates native responses for browser testing.
   */
  _simulateNativeResponse: function(messageId, method, params) {
    const responses = {
      'auth.getUserInfo': { userId: 'user_001', name: 'Alex Johnson', email: 'alex@example.com' },
      'payment.startPayment': { transactionId: 'txn_' + Date.now(), status: 'success' },
      'notification.showNotification': { success: true },
      'permission.requestPermission': { granted: true },
      'device.getLocation': { latitude: 37.7749, longitude: -122.4194 },
      'security.requestBiometricAuth': { authenticated: true },
      'iot.getDeviceList': { devices: [{ id: 'dev_001', name: 'Fitbit Sense', type: 'fitness_tracker' }] },
      'iot.connectDevice': { connected: true },
      'iot.readDeviceData': { steps: 8234, heartRate: 72, calories: 412 },
      'storage.saveHealthMetrics': { saved: true },
      'storage.saveMessages': { saved: true },
      'network.getStatus': { connected: true, type: 'wifi' }
    };

    const callback = this._callbacks[messageId];
    if (callback) {
      delete this._callbacks[messageId];
      const response = responses[method] || { success: true };
      callback.resolve(response);
    }
  }
};

/**
 * High-level MiniApp API namespaces
 */
window.MiniApp = {
  auth: {
    getUserInfo: () => MiniAppBridge.callNative('auth.getUserInfo')
  },
  payment: {
    startPayment: (params) => MiniAppBridge.callNative('payment.startPayment', params)
  },
  notification: {
    showNotification: (params) => MiniAppBridge.callNative('notification.showNotification', params),
    onPushReceived: (callback) => MiniAppBridge.onEvent('pushNotification', callback)
  },
  device: {
    getLocation: () => MiniAppBridge.callNative('device.getLocation'),
    playSound: (sound) => MiniAppBridge.callNative('device.playSound', { sound })
  },
  security: {
    requestBiometricAuth: () => MiniAppBridge.callNative('security.requestBiometricAuth')
  },
  permission: {
    requestPermission: (type) => MiniAppBridge.callNative('permission.requestPermission', { type })
  },
  iot: {
    getDeviceList: () => MiniAppBridge.callNative('iot.getDeviceList'),
    connectDevice: (deviceId) => MiniAppBridge.callNative('iot.connectDevice', { deviceId }),
    readDeviceData: (deviceId) => MiniAppBridge.callNative('iot.readDeviceData', { deviceId })
  },
  storage: {
    saveHealthMetrics: (data) => MiniAppBridge.callNative('storage.saveHealthMetrics', data),
    saveMessages: (data) => MiniAppBridge.callNative('storage.saveMessages', data)
  },
  network: {
    getStatus: () => MiniAppBridge.callNative('network.getStatus')
  }
};
