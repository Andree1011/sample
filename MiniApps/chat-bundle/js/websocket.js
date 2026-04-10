/**
 * Chat Mini App - WebSocket Manager
 * Handles real-time messaging (simulated for demo)
 */

const WebSocketManager = {
  _connected: false,
  _messageHandlers: [],
  _typingHandlers: [],

  connect: function(userId) {
    // In production, connect to a real WebSocket server
    // wss://chat.superapp-demo.com/ws?userId=userId

    console.log('WebSocket connecting for user:', userId);

    // Simulate connection
    setTimeout(() => {
      this._connected = true;
      console.log('WebSocket connected (simulated)');
    }, 500);

    return this;
  },

  onMessage: function(handler) {
    this._messageHandlers.push(handler);
    return this;
  },

  onTyping: function(handler) {
    this._typingHandlers.push(handler);
    return this;
  },

  sendMessage: function(conversationId, text) {
    if (!this._connected) {
      console.warn('WebSocket not connected');
      return;
    }

    // Simulate sending a message and getting a response
    setTimeout(() => {
      // Show typing indicator
      this._typingHandlers.forEach(h => h(true));

      // Send mock response after delay
      setTimeout(() => {
        this._typingHandlers.forEach(h => h(false));

        const responses = [
          "Got it! Thanks for letting me know 😊",
          "Sure, I'll take a look!",
          "That sounds great! 👍",
          "Let me check and get back to you",
          "Awesome! Talk soon 🙏",
          "Haha, that's hilarious! 😂"
        ];

        const response = responses[Math.floor(Math.random() * responses.length)];
        this._messageHandlers.forEach(h => h({
          id: 'msg_' + Date.now(),
          text: response,
          sender: 'other',
          timestamp: new Date()
        }));
      }, 1500 + Math.random() * 1000);
    }, 500);
  },

  disconnect: function() {
    this._connected = false;
  }
};
