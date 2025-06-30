const express = require('express');
const router = express.Router();
const Routine = require('../models/Routine');

// Create a routine
router.post('/', async (req, res) => {
  try {
    const { userId, name } = req.body;
    const newRoutine = new Routine({ userId, name });
    const saved = await newRoutine.save();
    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create routine' });
  }
});

// Get all routines for a user
router.get('/', async (req, res) => {
  try {
    const { userId } = req.query;
    const routines = await Routine.find({ userId });
    res.status(200).json(routines);
  } catch (err) {
    res.status(500).json({ error: 'Failed to get routines' });
  }
});

// Delete a routine by ID
router.delete('/:id', async (req, res) => {
     try {
       const deleted = await Routine.findByIdAndDelete(req.params.id);
       if (!deleted) {
         return res.status(404).json({ error: 'Routine not found' });
       }
       res.status(200).json({ message: 'Routine deleted successfully' });
     } catch (err) {
       res.status(500).json({ error: 'Failed to delete routine' });
     }
   });
   

module.exports = router;
