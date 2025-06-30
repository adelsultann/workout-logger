const mongoose = require('mongoose');

const WorkoutLogSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  exerciseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exercise', required: true },
  weight: { type: Number, required: true },
  reps: { type: Number, required: true },
  totalSets: { type: Number }, // ✅ New field
  date: { type: Date, default: Date.now },
  notes: { type: String },
});


module.exports = mongoose.model('WorkoutLog', WorkoutLogSchema);
