const mongoose = require('mongoose');

const ContentItemSchema = new mongoose.Schema({
  type: {
    type: String,
    required: true,
    index: true // 'hotel', 'bike', 'van', 'board', 'boat', 'food'
  }
}, { strict: false, timestamps: true });

module.exports = mongoose.model('ContentItem', ContentItemSchema);
