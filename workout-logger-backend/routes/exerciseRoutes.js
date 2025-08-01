const express = require('express');
const router = express.Router();
const Exercise = require('../models/Exercise');
const auth = require('../middleware/firebaseAuth');
const mongoose = require('mongoose');
const WorkoutLog = require('../models/WorkoutLog');   

// Add an exercise to a routine
router.post('/', async (req, res) => {
  try {
    const { routineId, name, totalSets } = req.body;
    const exercise = new Exercise({ userId: req.uid, routineId, name,totalSets });
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
    const exercises = await Exercise.find({ routineId }).sort({ order_position: 1 });
    res.status(200).json(exercises);
  } catch (err) {
    res.status(500).json({ error: 'Failed to get exercises' });
  }
});



router.delete('/:id', async (req, res) => {
  const session = await mongoose.startSession();

  try {
    await session.withTransaction(async () => {
      /* 1️⃣ delete the exercise (owner-checked) */
      const exercise = await Exercise.findOneAndDelete(
        { _id: req.params.id, userId: req.uid },
        { session }
      );
      if (!exercise) throw new Error('Exercise not found');

      /* 2️⃣ delete all logs tied to that exercise */
      await WorkoutLog.deleteMany({ exerciseId: exercise._id }).session(session);
    });

    res.status(200).json({ message: 'Exercise and its logs deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete exercise & logs' });
  } finally {
    await session.endSession();
  }
});

router.put('/:routineId/reorder', async (req, res) => {
  try {
    const { routineId } = req.params;
    const { exercises } = req.body;

    if (!Array.isArray(exercises)) {
      return res.status(400).json({ error: 'Exercises must be an array' });
    }

    for (const exercise of exercises) {
      await Exercise.updateOne(
        { _id: exercise.exerciseId, routineId: routineId },
        { $set: { order_position: exercise.order } }
      );
    }

    res.status(200).json({ message: 'Exercise order updated successfully' });
  } catch (error) {
    console.error(error); // log actual error for debugging
    res.status(500).json({ error: 'Failed to update exercise order' });
  }
});

// // Delete an exercise by ID
// router.delete('/:id', async (req, res) => {
//      try {
//        const deleted = await Exercise.findByIdAndDelete(req.params.id);
//        if (!deleted) {
//          return res.status(404).json({ error: 'Exercise not found' });
//        }
//        res.status(200).json({ message: 'Exercise deleted successfully' });
//      } catch (err) {
//        res.status(500).json({ error: 'Failed to delete exercise' });
//      }
//    });
   

module.exports = router;
