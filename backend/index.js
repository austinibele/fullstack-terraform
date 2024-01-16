const express = require('express');
const cors = require('cors'); // Make sure to install the cors package
const app = express();
const port = 5252;

const corsOptions = {
  origin: 'http://web-dev-lb-1198769921.us-east-1.elb.amazonaws.com', // Replace with your frontend's domain
  optionsSuccessStatus: 200 // some legacy browsers (IE11, various SmartTVs) choke on 204
};

app.use(cors(corsOptions));

app.get('/message', (req, res) => {
  res.json({ message: 'Hello from the backend!' });
});

app.listen(port, () => {
  console.log(`Backend listening at http://localhost:${port}`);
});