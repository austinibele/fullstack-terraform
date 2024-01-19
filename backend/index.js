const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 5252;

const pool = new Pool({
  user: process.env.DB_USER || 'dbuser',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'mydb',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

const corsOptions = {
  origin: `http://${process.env.CORS_ORIGIN}` || 'http://localhost:3000',
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));

app.get('/api/message', async (req, res) => {
  try {
    // Replace the query below with your actual query to fetch mock data
    const result = await pool.query('SELECT * FROM mock_table');
    const mockData = result.rows;
    res.json({ message: 'Hello from the backend!', data: mockData });
  } catch (error) {
    console.error('Database query error', error);
    // Send the error message in the response
    res.status(500).json({ message: `Error fetching data from the database: ${error.message}` });
  }
});

app.get('/', (req, res) => {
  res.json({ message: 'Healthy' });
});

app.listen(port, () => {
  console.log(`Backend listening at http://localhost:${port}`);
});