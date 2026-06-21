const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  address: {
    type: String,
    default: 'Google User'
  },
  mobile: {
    type: String,
    default: ''
  },
  hotelName: {
    type: String,
    default: ''
  },
  roomNumber: {
    type: String,
    default: ''
  },
  pin: {
    type: String,
    default: ''
  },
  email: {
    type: String,
    required: true,
    unique: true
  },
  googleId: {
    type: String,
    default: ''
  },
  role: {
    type: String,
    enum: ['user', 'manager'],
    default: 'user'
  },
  managedHotelId: {
    type: String,
    default: ''
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('User', UserSchema);
