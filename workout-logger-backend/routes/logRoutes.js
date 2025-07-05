const express = require('express');
const router = express.Router();
const WorkoutLog = require('../models/WorkoutLog');
const Exercise = require('../models/Exercise');
const auth = require('../middleware/firebaseAuth');

// Log a new workout set
router.post('/',auth, async (req, res) => {
     try {
       const {  exerciseId, weight, reps, date, notes } = req.body;
   
       // Fetch the exercise to get totalSets
       const exercise = await Exercise.findById(exerciseId);
       if (!exercise) return res.status(404).json({ error: 'Exercise not found' });
   
       const log = new WorkoutLog({
        // this is the authenticated user from firebase,
         userId: req.uid,
         exerciseId,
         weight,
         reps,
         totalSets: exercise.totalSets, // ✅ include it here
         date,
         notes,
       });
   
       const saved = await log.save();
       res.status(201).json(saved);
     } catch (err) {
       console.error(err);
       res.status(500).json({ error: 'Failed to add workout log' });
     }
   });



// Get all workout logs
router.get('/', auth ,async (req, res) => {
     try {
       const logs = await WorkoutLog.find().sort({ date: 1 }); // ascending by date
       res.status(200).json(logs);
     } catch (err) {
       res.status(500).json({ error: 'Failed to fetch logs' });
     }
   });
   

// Get all logs for a specific exercise
router.get('/:exerciseId' , auth , async (req, res) => {
  try {
    const { exerciseId } = req.params;
    const logs = await WorkoutLog.find({ exerciseId }).sort({ date: 1 });
    res.status(200).json(logs);
  } catch (err) {
    res.status(500).json({ error: 'Failed to get logs' });
  }
});

// Get progress summary for an exercise
router.get('/progress/:exerciseId',auth, async (req, res) => {
  try {
    const { exerciseId } = req.params;
    const logs = await WorkoutLog.find({ exerciseId }).sort({ date: 1 });

    const progress = logs.map(log => ({
      date: log.date,
      weight: log.weight,
      reps: log.reps
    }));

    res.status(200).json(progress);
  } catch (err) {
    res.status(500).json({ error: 'Failed to get progress' });
  }
});

// Delete a log by ID
router.delete('/:id', async (req, res) => {
     try {
       const deleted = await WorkoutLog.findByIdAndDelete(req.params.id);
       if (!deleted) {
         return res.status(404).json({ error: 'Log not found' });
       }
       res.status(200).json({ message: 'Log deleted successfully' });
     } catch (err) {
       console.error(err);
       res.status(500).json({ error: 'Failed to delete log' });
     }
   });
   
module.exports = router;
