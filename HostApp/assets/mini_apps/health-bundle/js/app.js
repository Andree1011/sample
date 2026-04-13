/**
 * Health Mini App - Main Application Logic
 */

const HealthApp = {
  currentTab: 'dashboard',
  healthData: {
    steps: { value: 8234, goal: 10000, unit: 'steps' },
    calories: { value: 412, goal: 600, unit: 'kcal' },
    heartRate: { value: 72, unit: 'bpm' },
    sleep: { value: '7h 20m', score: 88, unit: '' },
    water: { value: 6, goal: 8, unit: 'glasses' },
    weight: { value: 72.5, unit: 'kg' }
  },
  weeklySteps: [7200, 9100, 6800, 10500, 8300, 5900, 8234],

  init: async function() {
    this.renderDashboard();
    this.setupTabs();

    // Try to get user info
    try {
      const userInfo = await MiniApp.auth.getUserInfo();
      const greeting = document.getElementById('header-greeting');
      if (greeting) greeting.textContent = `Hello, ${userInfo.name}! 👋`;
    } catch (e) {
      console.warn('Could not load user info:', e.message);
    }
  },

  setupTabs: function() {
    document.querySelectorAll('.nav-tab').forEach(tab => {
      tab.addEventListener('click', () => {
        document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

        tab.classList.add('active');
        this.currentTab = tab.dataset.tab;
        document.getElementById(`tab-${this.currentTab}`).classList.add('active');

        if (this.currentTab === 'activity') this.renderActivityChart();
        if (this.currentTab === 'integration') this.loadDevices();
      });
    });
  },

  renderDashboard: function() {
    const d = this.healthData;

    this.updateMetricCard('steps', '👣', d.steps.value.toLocaleString(), 'Steps Today',
      Math.round((d.steps.value / d.steps.goal) * 100));
    this.updateMetricCard('calories', '🔥', d.calories.value, 'Calories Burned',
      Math.round((d.calories.value / d.calories.goal) * 100));
    this.updateMetricCard('heart', '❤️', d.heartRate.value + ' bpm', 'Heart Rate', null);
    this.updateMetricCard('sleep', '😴', d.sleep.value, 'Sleep', d.sleep.score);
    this.updateMetricCard('water', '💧', `${d.water.value}/${d.water.goal}`, 'Water Intake',
      Math.round((d.water.value / d.water.goal) * 100));
    this.updateMetricCard('weight', '⚖️', d.weight.value + ' kg', 'Weight', null);

    // Chart preview on dashboard
    HealthCharts.renderWeeklySteps('dashboard-chart', this.weeklySteps);
  },

  updateMetricCard: function(id, icon, value, label, pct) {
    const card = document.getElementById(`metric-${id}`);
    if (!card) return;
    card.querySelector('.metric-icon').textContent = icon;
    card.querySelector('.metric-value').textContent = value;
    card.querySelector('.metric-label').textContent = label;

    const progressWrap = card.querySelector('.metric-progress');
    if (pct !== null && progressWrap) {
      progressWrap.style.display = 'block';
      card.querySelector('.metric-progress-bar').style.width = pct + '%';
      card.querySelector('.metric-pct').textContent = `${pct}% of daily goal`;
    } else if (progressWrap) {
      progressWrap.style.display = 'none';
      const pctEl = card.querySelector('.metric-pct');
      if (pctEl) pctEl.textContent = '';
    }
  },

  renderActivityChart: function() {
    HealthCharts.renderWeeklySteps('activity-chart', this.weeklySteps);
  },

  loadDevices: async function() {
    try {
      const result = await MiniApp.iot.getDeviceList();
      this.renderDevices(result.devices || []);
    } catch (e) {
      // Use mock data if bridge unavailable
      this.renderDevices([
        { id: 'dev_001', name: 'Fitbit Sense 2', type: 'fitness_tracker', connected: false },
        { id: 'dev_002', name: 'Apple Watch', type: 'smartwatch', connected: true },
      ]);
    }
  },

  renderDevices: function(devices) {
    const container = document.getElementById('device-list');
    if (!container) return;

    if (devices.length === 0) {
      container.innerHTML = '<p style="color:#888;text-align:center;padding:20px">No devices found</p>';
      return;
    }

    container.innerHTML = devices.map(device => `
      <div class="device-item">
        <span class="device-icon">${device.type === 'smartwatch' ? '⌚' : '📱'}</span>
        <div class="device-info">
          <div class="device-name">${device.name}</div>
          <div class="device-status">${device.connected ? '🟢 Connected' : '⚪ Not connected'}</div>
        </div>
        <button class="device-connect-btn" onclick="HealthApp.connectDevice('${device.id}', '${device.name}')">
          ${device.connected ? 'Sync' : 'Connect'}
        </button>
      </div>
    `).join('');
  },

  connectDevice: async function(deviceId, deviceName) {
    this.showToast(`Connecting to ${deviceName}...`);
    try {
      await MiniApp.iot.connectDevice(deviceId);
      const data = await MiniApp.iot.readDeviceData(deviceId);

      // Update local data with device data
      if (data.steps) this.healthData.steps.value = data.steps;
      if (data.heartRate) this.healthData.heartRate.value = data.heartRate;
      if (data.calories) this.healthData.calories.value = data.calories;

      this.renderDashboard();
      this.showToast(`✅ ${deviceName} synced successfully!`);

      // Save to storage
      await MiniApp.storage.saveHealthMetrics({
        timestamp: new Date().toISOString(),
        deviceId,
        ...data
      });
    } catch (e) {
      this.showToast('Connection failed: ' + e.message);
    }
  },

  requestBiometricAuth: async function() {
    try {
      this.showToast('🔐 Requesting biometric authentication...');
      const result = await MiniApp.security.requestBiometricAuth();
      if (result.authenticated) {
        this.showToast('✅ Biometric auth successful!');
      }
    } catch (e) {
      this.showToast('Biometric auth failed');
    }
  },

  showToast: function(message) {
    const toast = document.getElementById('toast');
    if (!toast) return;
    toast.textContent = message;
    toast.classList.add('show');
    setTimeout(() => toast.classList.remove('show'), 2500);
  }
};

document.addEventListener('DOMContentLoaded', () => {
  HealthApp.init();
});
