const express = require('express');
const cors = require('cors');
const { Pool } = require('pg'); // Import the Pool class from the pg module

const app = express();
const port = 5252;

// Configure the database connection using Pool
const pool = new Pool({
  user: 'dbuser', // Replace with your database username
  host: 'http://node-app-prod-db.ckefgvbvfe0n.us-east-1.rds.amazonaws.com', // Replace with your RDS endpoint
  database: 'mydb', // Replace with your database name
  password: 'postgres',
  port: 5432,
});

const corsOptions = {
  origin: 'http://web-dev-frontendlb-894222867.us-east-1.elb.amazonaws.com',
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));

app.get('/api/message', async (req, res) => {
  try {
    // Replace the query below with your actual query to fetch mock data
    const result = await pool.query('SELECT * FROM mock');
    const mockData = result.rows;
    res.json({ message: 'Hello from the backend!', data: mockData });
  } catch (error) {
    console.error('Database query error', error);
    // Send the error message in the response
    res.status(500).json({ message: 'Error fetching data from the database', error: error.message });
  }
});

app.get('/', (req, res) => {
  res.json({ message: 'Healthy' });
});

app.listen(port, () => {
  console.log(`Backend listening at http://localhost:${port}`);
});