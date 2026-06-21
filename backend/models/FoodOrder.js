const mongoose = require('mongoose');

const FoodOrderItemSchema = new mongoose.Schema({
  itemId: String,
  name: String,
  quantity: Number,
  price: Number
});

const FoodOrderSchema = new mongoose.Schema({
  customerName: {
    type: String,
    required: true
  },
  customerPhone: {
    type: String,
    required: true
  },
  locationDetails: {
    type: String,
    required: true // e.g. Hotel room no or beach umbrella no
  },
  items: [FoodOrderItemSchema],
  totalPrice: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['Ordered', 'Preparing', 'Delivering', 'Completed', 'Cancelled'],
    default: 'Ordered'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('FoodOrder', FoodOrderSchema);
