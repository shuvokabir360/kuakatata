const mongoose = require('mongoose');

const ReviewSchema = new mongoose.Schema({
  itemId: {
    type: String,
    required: true
  },
  itemType: {
    type: String,
    required: true,
    enum: ['hotel', 'bike', 'board', 'food', 'room']
  },
  userName: {
    type: String,
    required: true
  },
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  comment: {
    type: String,
    required: true
  },
  adminReply: {
    type: String,
    default: ''
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Review', ReviewSchema);
