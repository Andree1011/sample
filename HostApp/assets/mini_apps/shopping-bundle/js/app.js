/**
 * Shopping Mini App - Main Application Logic
 */

const ShoppingApp = {
  cart: [],
  products: [],
  currentCategory: 'All',
  searchQuery: '',

  init: async function() {
    await this.loadUserInfo();
    await this.loadProducts();
    this.setupEventListeners();
  },

  loadUserInfo: async function() {
    try {
      const userInfo = await MiniApp.auth.getUserInfo();
      console.log('User:', userInfo.name);
    } catch (e) {
      console.warn('Could not load user info:', e.message);
    }
  },

  loadProducts: async function() {
    this.products = await ShoppingAPI.getProducts(
      this.currentCategory === 'All' ? null : this.currentCategory,
      this.searchQuery
    );
    this.renderProducts();
  },

  renderProducts: function() {
    const grid = document.getElementById('products-grid');
    if (!grid) return;

    if (this.products.length === 0) {
      grid.innerHTML = '<div style="grid-column:1/-1;text-align:center;padding:40px;color:#888">No products found</div>';
      return;
    }

    grid.innerHTML = this.products.map(p => `
      <div class="product-card" onclick="ShoppingApp.viewProduct(${p.id})">
        <div class="product-image">${p.emoji}</div>
        <div class="product-info">
          <div class="product-name">${p.name}</div>
          <div class="product-rating">⭐ ${p.rating} (${p.reviews.toLocaleString()})</div>
          <div class="product-price">$${p.price.toFixed(2)}</div>
          <button class="add-btn" onclick="event.stopPropagation(); ShoppingApp.addToCart(${p.id})">
            Add to Cart
          </button>
        </div>
      </div>
    `).join('');
  },

  viewProduct: function(id) {
    const product = this.products.find(p => p.id === id);
    if (!product) return;

    // Show product detail modal
    const modal = document.getElementById('product-modal');
    if (modal) {
      modal.querySelector('.modal-emoji').textContent = product.emoji;
      modal.querySelector('.modal-name').textContent = product.name;
      modal.querySelector('.modal-price').textContent = `$${product.price.toFixed(2)}`;
      modal.querySelector('.modal-rating').textContent = `⭐ ${product.rating} · ${product.reviews.toLocaleString()} reviews`;
      modal.querySelector('.modal-add-btn').onclick = () => {
        this.addToCart(id);
        modal.style.display = 'none';
      };
      modal.style.display = 'flex';
      modal.dataset.productId = id;
    }
  },

  addToCart: function(id) {
    const product = this.products.find(p => p.id === id);
    if (!product) return;

    const existing = this.cart.find(item => item.id === id);
    if (existing) {
      existing.qty++;
    } else {
      this.cart.push({ ...product, qty: 1 });
    }

    this.updateCartBadge();
    this.showToast(`${product.emoji} ${product.name} added to cart!`);

    // Notify host app
    MiniApp.notification.showNotification({
      title: 'Added to Cart',
      body: `${product.name} - $${product.price.toFixed(2)}`
    }).catch(() => {});
  },

  removeFromCart: function(id) {
    this.cart = this.cart.filter(item => item.id !== id);
    this.updateCartBadge();
    this.renderCart();
  },

  updateCartBadge: function() {
    const badge = document.getElementById('cart-badge');
    const total = this.cart.reduce((sum, item) => sum + item.qty, 0);
    if (badge) {
      badge.textContent = total;
      badge.style.display = total > 0 ? 'flex' : 'none';
    }
  },

  openCart: function() {
    this.renderCart();
    document.getElementById('cart-panel').classList.add('open');
  },

  closeCart: function() {
    document.getElementById('cart-panel').classList.remove('open');
  },

  renderCart: function() {
    const container = document.getElementById('cart-items');
    if (!container) return;

    if (this.cart.length === 0) {
      container.innerHTML = '<div class="empty-cart"><div class="emoji">🛒</div><div>Your cart is empty</div></div>';
      document.getElementById('cart-total-amount').textContent = '$0.00';
      return;
    }

    container.innerHTML = this.cart.map(item => `
      <div class="cart-item">
        <span class="cart-item-emoji">${item.emoji}</span>
        <div class="cart-item-info">
          <div class="cart-item-name">${item.name}</div>
          <div class="cart-item-price">$${(item.price * item.qty).toFixed(2)} ${item.qty > 1 ? `(×${item.qty})` : ''}</div>
        </div>
        <button class="cart-remove" onclick="ShoppingApp.removeFromCart(${item.id})">✕</button>
      </div>
    `).join('');

    const total = this.cart.reduce((sum, item) => sum + item.price * item.qty, 0);
    document.getElementById('cart-total-amount').textContent = `$${total.toFixed(2)}`;
  },

  checkout: async function() {
    if (this.cart.length === 0) return;

    const total = this.cart.reduce((sum, item) => sum + item.price * item.qty, 0);

    this.closeCart();

    try {
      // Call native payment service via bridge
      const result = await MiniApp.payment.startPayment({
        amount: total,
        currency: 'USD',
        description: `Shopping order (${this.cart.length} items)`,
        items: this.cart.map(item => ({
          name: item.name,
          price: item.price,
          qty: item.qty
        }))
      });

      if (result.status === 'success') {
        this.cart = [];
        this.updateCartBadge();
        this.showOrderConfirmation(result.transactionId, total);
      }
    } catch (e) {
      this.showToast('Payment failed: ' + e.message);
    }
  },

  showOrderConfirmation: function(txnId, amount) {
    const modal = document.getElementById('order-modal');
    if (modal) {
      modal.querySelector('.order-txn').textContent = `Order #${txnId}`;
      modal.querySelector('.order-amount').textContent = `$${amount.toFixed(2)}`;
      modal.style.display = 'flex';
    }
  },

  setupEventListeners: function() {
    // Search
    const searchInput = document.getElementById('search-input');
    if (searchInput) {
      let debounceTimer;
      searchInput.addEventListener('input', (e) => {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(async () => {
          this.searchQuery = e.target.value;
          await this.loadProducts();
        }, 300);
      });
    }

    // Category pills
    document.querySelectorAll('.category-pill').forEach(pill => {
      pill.addEventListener('click', async () => {
        document.querySelectorAll('.category-pill').forEach(p => p.classList.remove('active'));
        pill.classList.add('active');
        this.currentCategory = pill.dataset.category;
        await this.loadProducts();
      });
    });

    // Cart overlay close
    const overlay = document.getElementById('cart-overlay');
    if (overlay) {
      overlay.addEventListener('click', () => this.closeCart());
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

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  ShoppingApp.init();
});
