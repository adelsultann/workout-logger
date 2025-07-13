const express = require('express');
const router = express.Router();
const Routine = require('../models/Routine');
const auth = require('../middleware/firebaseAuth');
const Exercise  = require('../models/Exercise');
const WorkoutLog = require('../models/WorkoutLog');   
const mongoose = require('mongoose');

// Create a routine
router.post('/',auth, async (req, res) => {
  try {
    const {  name } = req.body;
    const newRoutine = new Routine({ userId: req.uid, name });
    const saved = await newRoutine.save();
    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create routine' });
  }
});

// Get all routines for a user
router.get('/', async (req, res) => {
  try {
    const routines = await Routine.find({ userId: req.uid }).sort({ createdAt: -1 });
    res.status(200).json(routines);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to load routines' });
  }
});

// DELETE /api/routines/:id
router.delete('/:id', async (req, res) => {
  const session = await mongoose.startSession();
  try {
    await session.withTransaction(async () => {
      /* 1. Delete the routine itself */
      const routine = await Routine.findOneAndDelete(
        { _id: req.params.id, userId: req.uid },   // secure: owner only
        { session }
      );
      if (!routine) throw new Error('Routine not found');
      console.log('Routine deleted:', routine);

      /* 2. Find & delete exercises in that routine */
      const exercises = await Exercise.find({ routineId: routine._id }, '_id', { session });
      const exerciseIds = exercises.map(e => e._id);

      await Exercise.deleteMany({ _id: { $in: exerciseIds } }).session(session);

      /* 3. Delete logs that belong to those exercises */
      await WorkoutLog.deleteMany({ exerciseId: { $in: exerciseIds } }).session(session);
    });

    res.status(200).json({ message: 'Routine + children removed' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete routine and children' });
  } finally {
    await session.endSession();
  }
});

   

module.exports = router;
