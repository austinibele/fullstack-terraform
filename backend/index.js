const express = require('express');
const cors = require('cors'); // Make sure to install the cors package
const app = express();
const port = 5252;

app.use(cors()); // Enable CORS for all routes

app.get('/message', (req, res) => {
  res.json({ message: 'Hello from the backend!' });
});

app.listen(port, () => {
  console.log(`Backend listening at http://localhost:${port}`);
});