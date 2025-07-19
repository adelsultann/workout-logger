const mongoose = require('mongoose');

const RoutineSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  name: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

RoutineSchema.index({ userId: 1, name: 1 });

module.exports = mongoose.model('Routine', RoutineSchema);
