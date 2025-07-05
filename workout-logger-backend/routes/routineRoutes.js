const express = require('express');
const router = express.Router();
const Routine = require('../models/Routine');
const auth = require('../middleware/firebaseAuth');


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
