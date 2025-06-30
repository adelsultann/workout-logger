const express = require('express');
const router = express.Router();
const Exercise = require('../models/Exercise');

// Add an exercise to a routine
router.post('/', async (req, res) => {
  try {
    const { routineId, name, totalSets } = req.body;
    const exercise = new Exercise({ routineId, name,totalSets });
    const saved = await exercise.save();
    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ error: 'Failed to add exercise' });
  }
});

// Get all exercises under a routine
router.get('/:routineId', async (req, res) => {
  try {
    const { routineId } = req.params;
    const exercises = await Exercise.find({ routineId });
    res.status(200).json(exercises);
  } catch (err) {
    res.status(500).json({ error: 'Failed to get exercises' });
  }
});

// Delete an exercise by ID
router.delete('/:id', async (req, res) => {
     try {
       const deleted = await Exercise.findByIdAndDelete(req.params.id);
       if (!deleted) {
         return res.status(404).json({ error: 'Exercise not found' });
       }
       res.status(200).json({ message: 'Exercise deleted successfully' });
     } catch (err) {
       res.status(500).json({ error: 'Failed to delete exercise' });
     }
   });
   

module.exports = router;
