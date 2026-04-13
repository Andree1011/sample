/**
 * Shopping Mini App - Mock API
 * Provides product data and simulates backend calls
 */

const ShoppingAPI = {
  products: [
    { id: 1, name: 'Wireless Headphones Pro', price: 79.99, category: 'Electronics', emoji: '🎧', rating: 4.8, reviews: 1234 },
    { id: 2, name: 'Smart Watch Series 5', price: 199.99, category: 'Electronics', emoji: '⌚', rating: 4.6, reviews: 892 },
    { id: 3, name: 'Running Shoes Elite', price: 89.99, category: 'Sports', emoji: '👟', rating: 4.7, reviews: 567 },
    { id: 4, name: 'Yoga Mat Premium', price: 29.99, category: 'Sports', emoji: '🧘', rating: 4.5, reviews: 340 },
    { id: 5, name: 'Coffee Maker Deluxe', price: 59.99, category: 'Kitchen', emoji: '☕', rating: 4.4, reviews: 789 },
    { id: 6, name: 'Desk Lamp LED', price: 34.99, category: 'Office', emoji: '💡', rating: 4.3, reviews: 421 },
    { id: 7, name: 'Backpack Urban Pro', price: 49.99, category: 'Fashion', emoji: '🎒', rating: 4.6, reviews: 654 },
    { id: 8, name: 'Water Bottle Titanium', price: 24.99, category: 'Sports', emoji: '🍶', rating: 4.9, reviews: 1102 },
  ],

  getProducts: function(category = null, search = '') {
    return new Promise(resolve => {
      setTimeout(() => {
        let filtered = this.products;
        if (category && category !== 'All') {
          filtered = filtered.filter(p => p.category === category);
        }
        if (search) {
          const q = search.toLowerCase();
          filtered = filtered.filter(p => p.name.toLowerCase().includes(q));
        }
        resolve(filtered);
      }, 200);
    });
  },

  getProduct: function(id) {
    return new Promise(resolve => {
      setTimeout(() => {
        resolve(this.products.find(p => p.id === id));
      }, 100);
    });
  }
};
