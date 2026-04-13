/**
 * Chat Mini App - Main Application Logic
 */

const ChatApp = {
  currentConversation: null,
  messages: {},

  conversations: [
    {
      id: 'conv_sarah',
      name: 'Sarah',
      lastMessage: "Hey, are you available? 👋",
      time: '2m ago',
      unread: 3,
      online: true,
      color: '#6C63FF'
    },
    {
      id: 'conv_mike',
      name: 'Mike',
      lastMessage: "Can you review the PR?",
      time: '15m ago',
      unread: 1,
      online: false,
      color: '#FF6B6B'
    },
    {
      id: 'conv_team',
      name: 'Team Chat',
      lastMessage: "Meeting at 3PM today",
      time: '1h ago',
      unread: 5,
      online: true,
      color: '#FF9800'
    },
    {
      id: 'conv_anna',
      name: 'Anna',
      lastMessage: "Thanks for your help! 🙏",
      time: '3h ago',
      unread: 0,
      online: true,
      color: '#4CAF50'
    },
    {
      id: 'conv_support',
      name: 'Support',
      lastMessage: "Your issue has been resolved",
      time: '1d ago',
      unread: 0,
      online: false,
      color: '#2196F3'
    },
  ],

  init: async function() {
    // Request notification permission
    try {
      await MiniApp.permission.requestPermission('notification');
    } catch (e) {
      console.warn('Could not request notification permission:', e.message);
    }

    // Listen for push notifications
    MiniApp.notification.onPushReceived((data) => {
      console.log('Push received:', data);
    });

    // Check network status
    try {
      const network = await MiniApp.network.getStatus();
      console.log('Network:', network.type, network.connected ? 'connected' : 'disconnected');
    } catch (e) {
      console.warn('Could not check network:', e.message);
    }

    // Initialize mock messages
    this.initMockMessages();

    // Connect WebSocket
    WebSocketManager.connect('user_001')
      .onMessage((msg) => {
        if (this.currentConversation) {
          this.appendMessage(msg.text, 'other');
        }
      })
      .onTyping((isTyping) => {
        const indicator = document.getElementById('typing-indicator');
        if (indicator) {
          indicator.style.display = isTyping ? 'block' : 'none';
        }
      });

    this.renderConversationList();
    this.setupSearch();
  },

  initMockMessages: function() {
    this.messages['conv_sarah'] = [
      { id: 'm1', text: "Hey! Are you available?", sender: 'other', time: '2:30 PM' },
      { id: 'm2', text: "Yes, what's up?", sender: 'mine', time: '2:31 PM' },
      { id: 'm3', text: "Can you help me with the project?", sender: 'other', time: '2:31 PM' },
      { id: 'm4', text: "Sure! Let me check the files first.", sender: 'mine', time: '2:32 PM' },
      { id: 'm5', text: "Great, thanks! 🙏", sender: 'other', time: '2:32 PM' },
    ];
    this.messages['conv_mike'] = [
      { id: 'm1', text: "Can you review the PR?", sender: 'other', time: '2:15 PM' },
      { id: 'm2', text: "I'll take a look now", sender: 'mine', time: '2:16 PM' },
    ];
    this.messages['conv_team'] = [
      { id: 'm1', text: "Meeting at 3PM today", sender: 'other', time: '1:00 PM' },
      { id: 'm2', text: "Got it! 👍", sender: 'mine', time: '1:05 PM' },
      { id: 'm3', text: "Don't forget to bring your laptops", sender: 'other', time: '1:30 PM' },
    ];
  },

  renderConversationList: function() {
    const container = document.getElementById('conversation-list');
    if (!container) return;

    container.innerHTML = this.conversations.map(conv => `
      <div class="conversation-item" onclick="ChatApp.openConversation('${conv.id}')">
        <div class="avatar" style="background:${conv.color}">
          ${conv.name[0]}
          ${conv.online ? '<div class="online-dot"></div>' : ''}
        </div>
        <div class="conversation-info">
          <div class="conversation-name">${conv.name}</div>
          <div class="conversation-preview">${conv.lastMessage}</div>
        </div>
        <div class="conversation-meta">
          <div class="conversation-time">${conv.time}</div>
          ${conv.unread > 0
            ? `<div class="unread-badge">${conv.unread}</div>`
            : ''
          }
        </div>
      </div>
    `).join('');
  },

  openConversation: function(convId) {
    this.currentConversation = convId;
    const conv = this.conversations.find(c => c.id === convId);
    if (!conv) return;

    // Update header
    document.getElementById('chat-name').textContent = conv.name;
    document.getElementById('chat-status').textContent =
      conv.online ? '🟢 Online' : '⚪ Offline';

    // Clear unread
    conv.unread = 0;
    this.renderConversationList();

    // Switch views
    document.getElementById('chat-list-view').style.display = 'none';
    document.getElementById('chat-detail-view').style.display = 'flex';

    // Render messages
    this.renderMessages(convId);

    // Focus input
    setTimeout(() => {
      const input = document.getElementById('message-input');
      if (input) input.focus();
    }, 100);
  },

  backToList: function() {
    this.currentConversation = null;
    document.getElementById('chat-detail-view').style.display = 'none';
    document.getElementById('chat-list-view').style.display = 'flex';
    document.getElementById('chat-list-view').style.flexDirection = 'column';
  },

  renderMessages: function(convId) {
    const container = document.getElementById('messages-container');
    if (!container) return;

    const msgs = this.messages[convId] || [];

    container.innerHTML = '<div class="date-separator">Today</div>';

    msgs.forEach(msg => {
      container.appendChild(this.createMessageEl(msg.text, msg.sender, msg.time));
    });

    // Scroll to bottom
    container.scrollTop = container.scrollHeight;
  },

  createMessageEl: function(text, sender, time) {
    const div = document.createElement('div');
    div.className = `message ${sender}`;

    const bubble = document.createElement('div');
    bubble.className = 'message-bubble';
    bubble.textContent = text;

    const timeEl = document.createElement('div');
    timeEl.className = 'message-time';
    timeEl.textContent = time || this.formatTime(new Date());

    div.appendChild(bubble);
    div.appendChild(timeEl);
    return div;
  },

  appendMessage: function(text, sender) {
    const container = document.getElementById('messages-container');
    if (!container) return;

    const el = this.createMessageEl(text, sender);
    container.appendChild(el);
    container.scrollTop = container.scrollHeight;

    // Save messages
    if (this.currentConversation) {
      if (!this.messages[this.currentConversation]) {
        this.messages[this.currentConversation] = [];
      }
      this.messages[this.currentConversation].push({
        id: 'msg_' + Date.now(),
        text,
        sender,
        time: this.formatTime(new Date())
      });

      // Persist via bridge
      MiniApp.storage.saveMessages({
        conversationId: this.currentConversation,
        messages: this.messages[this.currentConversation]
      }).catch(() => {});
    }
  },

  sendMessage: function() {
    const input = document.getElementById('message-input');
    if (!input) return;

    const text = input.value.trim();
    if (!text) return;

    input.value = '';
    input.style.height = 'auto';

    // Add to UI
    this.appendMessage(text, 'mine');

    // Update conversation preview
    if (this.currentConversation) {
      const conv = this.conversations.find(c => c.id === this.currentConversation);
      if (conv) {
        conv.lastMessage = text;
        conv.time = 'now';
      }
    }

    // Send via WebSocket (will trigger typing + auto-response)
    WebSocketManager.sendMessage(this.currentConversation, text);

    // Play notification sound
    MiniApp.device.playSound('notification').catch(() => {});
  },

  setupSearch: function() {
    const searchInput = document.getElementById('search-input');
    if (!searchInput) return;

    searchInput.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase();
      const filtered = this.conversations.filter(c =>
        c.name.toLowerCase().includes(query) ||
        c.lastMessage.toLowerCase().includes(query)
      );

      const container = document.getElementById('conversation-list');
      if (!container) return;

      container.innerHTML = filtered.map(conv => `
        <div class="conversation-item" onclick="ChatApp.openConversation('${conv.id}')">
          <div class="avatar" style="background:${conv.color}">
            ${conv.name[0]}
            ${conv.online ? '<div class="online-dot"></div>' : ''}
          </div>
          <div class="conversation-info">
            <div class="conversation-name">${conv.name}</div>
            <div class="conversation-preview">${conv.lastMessage}</div>
          </div>
          <div class="conversation-meta">
            <div class="conversation-time">${conv.time}</div>
            ${conv.unread > 0 ? `<div class="unread-badge">${conv.unread}</div>` : ''}
          </div>
        </div>
      `).join('');
    });
  },

  formatTime: function(date) {
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    });
  }
};

document.addEventListener('DOMContentLoaded', () => {
  ChatApp.init();
});
