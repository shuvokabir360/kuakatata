const mongoose = require('mongoose');

const ComplaintSchema = new mongoose.Schema({
  userName: {
    type: String,
    required: true
  },
  userMobile: {
    type: String,
    required: true
  },
  subject: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  image: {
    type: String,
    default: ''
  },
  status: {
    type: String,
    enum: ['Pending', 'Under Investigation', 'Resolved'],
    default: 'Pending'
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

module.exports = mongoose.model('Complaint', ComplaintSchema);
