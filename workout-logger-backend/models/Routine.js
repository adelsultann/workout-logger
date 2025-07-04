const mongoose = require('mongoose');

const RoutineSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  name: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Routine', RoutineSchema);
