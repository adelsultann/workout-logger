// server.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();



const app = express();
app.use(cors());
app.use(express.json());

// MongoDB connection
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("✅ MongoDB Connected"))
  .catch((err) => console.error("❌ Mongo Error:", err));

// Routes
app.get('/', (req, res) => {
     res.send('Workout Logger API is running');
   });

   // Routine Routes
const routineRoutes = require('./routes/routineRoutes');
app.use('/api/routines', routineRoutes);

// Exercise Routes
const exerciseRoutes = require('./routes/exerciseRoutes');
app.use('/api/exercises', exerciseRoutes);

//log routes
const logRoutes = require('./routes/logRoutes');
app.use('/api/logs', logRoutes);


const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
