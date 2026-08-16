const { query } = require("../config/db");

async function createReport(req, res, next) {
  try {
    const {
      ticket_id,
      reservation_id,
      report_type,
      description
    } = req.body;

    if (!report_type || !description) {
      return res.status(400).json({
        success: false,
        message: "report_type and description are required"
      });
    }

    const result = await query(
      `
      INSERT INTO reports (
        user_id,
        ticket_id,
        reservation_id,
        report_type,
        description,
        status,
        handled_by_support_id,
        created_at,
        resolved_at
      )
      VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        'open',
        NULL,
        CURRENT_TIMESTAMP,
        NULL
      )
      RETURNING *;
      `,
      [
        req.user.user_id,
        ticket_id || null,
        reservation_id || null,
        report_type,
        description
      ]
    );

    res.status(201).json({
      success: true,
      message: "Report created successfully",
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

async function getMyReports(req, res, next) {
  try {
    const result = await query(
      `
      SELECT
        r.report_id,
        r.user_id,
        r.ticket_id,
        r.reservation_id,
        r.report_type,
        r.description,
        r.status,
        r.handled_by_support_id,
        r.created_at,
        r.resolved_at,
        t.price,
        m.home_team,
        m.away_team,
        s.name AS sport_name,
        v.name AS venue_name
      FROM reports r
      LEFT JOIN tickets t ON t.ticket_id = r.ticket_id
      LEFT JOIN matches m ON m.match_id = t.match_id
      LEFT JOIN sports s ON s.sport_id = m.sport_id
      LEFT JOIN venues v ON v.venue_id = m.venue_id
      WHERE r.user_id = $1
      ORDER BY r.created_at DESC;
      `,
      [req.user.user_id]
    );

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createReport,
  getMyReports
};