// middleware/firebaseAuth.js
const admin = require('firebase-admin');

//local 

// const serviceAccount = require('../serviceAccount.json')

//Render deployment 
 const serviceAccount = require('/etc/secrets/serviceAccount.json');


admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

module.exports = async function (req, res, next) {
  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Bearer ')) return res.status(401).json({ error: 'No token' });

  try {
    const idToken = auth.split('Bearer ')[1];
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.uid = decoded.uid;
             // 🟢 you now know the user
    next();
  } catch (err) {
    console.error(err);
    res.status(401).json({ error: 'Invalid token' });
  }
};
