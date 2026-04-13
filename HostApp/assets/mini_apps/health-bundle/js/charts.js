/**
 * Health Mini App - Activity Charts
 * Simple canvas-based bar charts for health data visualization
 */

const HealthCharts = {
  /**
   * Render a weekly steps bar chart into the given container.
   */
  renderWeeklySteps: function(containerId, data) {
    const container = document.getElementById(containerId);
    if (!container) return;

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const max = Math.max(...data);

    container.innerHTML = '';

    const chart = document.createElement('div');
    chart.className = 'bar-chart';

    days.forEach((day, i) => {
      const pct = max > 0 ? (data[i] / max) * 100 : 0;
      const isToday = i === 6;

      const wrap = document.createElement('div');
      wrap.className = 'bar-wrap';
      wrap.style.height = '100%';

      const spacer = document.createElement('div');
      spacer.style.flex = '1';

      const bar = document.createElement('div');
      bar.className = 'bar-fill' + (isToday ? ' today' : '');
      bar.style.width = '100%';
      bar.style.height = '0%';
      bar.title = `${day}: ${data[i].toLocaleString()} steps`;

      const label = document.createElement('div');
      label.className = 'bar-label';
      label.textContent = day;

      wrap.appendChild(spacer);
      wrap.appendChild(bar);
      wrap.appendChild(label);
      chart.appendChild(wrap);

      // Animate bar
      setTimeout(() => {
        bar.style.height = pct + '%';
      }, 50 + i * 80);
    });

    container.appendChild(chart);
  }
};
