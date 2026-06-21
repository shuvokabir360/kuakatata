const mongoose = require('mongoose');

const BookingSchema = new mongoose.Schema({
  serviceType: {
    type: String,
    required: true,
    enum: ['hotel', 'bike', 'van', 'board', 'boat', 'ship']
  },
  customerName: {
    type: String,
    required: true
  },
  customerPhone: {
    type: String,
    required: true
  },
  bookingDate: {
    type: String,
    required: true
  },
  bookingTime: {
    type: String,
    required: true
  },
  duration: {
    type: Number,
    default: 1
  },
  quantity: {
    type: Number,
    default: 1
  },
  category: {
    type: String,
    default: 'Standard'
  },
  notes: {
    type: String,
    default: ''
  },
  status: {
    type: String,
    enum: ['Pending', 'Confirmed', 'Cancelled'],
    default: 'Pending'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Booking', BookingSchema);
