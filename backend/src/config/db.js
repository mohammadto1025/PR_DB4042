const { Pool } = require("pg");

const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD
});

async function query(text, params) {
  try {
    const result = await pool.query(text, params);
    return result;
  } catch (error) {
    console.error("Database query error:", error.message);
    throw error;
  }
}

async function testDatabaseConnection() {
  const result = await query(`
    SELECT 
      current_database() AS database_name,
      current_user AS database_user,
      NOW() AS connected_at;
  `);

  return result.rows[0];
}

module.exports = {
  pool,
  query,
  testDatabaseConnection
};