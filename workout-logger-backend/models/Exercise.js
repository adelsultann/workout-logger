const mongoose = require('mongoose');

const ExerciseSchema = new mongoose.Schema({
  routineId: { type: mongoose.Schema.Types.ObjectId, ref: 'Routine', required: true },
  name: { type: String, required: true },
    userId:    { type: String, required: true }, 
  totalSets:{ type: Number, required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Exercise', ExerciseSchema);
