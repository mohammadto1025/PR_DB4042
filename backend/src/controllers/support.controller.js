const { pool, query } = require("../config/db");
const { redisClient } = require("../config/redis");

async function clearTicketCache() {
  try {
    const searchKeys = await redisClient.keys("tickets:*");
    const detailKeys = await redisClient.keys("ticket:*");
    const keys = [...searchKeys, ...detailKeys];

    if (keys.length > 0) {
      await redisClient.del(keys);
    }
  } catch (error) {
    console.log("Could not clear ticket cache:", error.message);
  }
}

async function getAllReports(req, res, next) {
  try {
    const result = await query(
      `
      SELECT
        r.report_id,
        r.user_id,
        u.first_name,
        u.last_name,
        u.email,
        r.ticket_id,
        r.reservation_id,
        r.report_type,
        r.description,
        r.status,
        r.handled_by_support_id,
        r.created_at,
        r.resolved_at
      FROM reports r
      JOIN users u ON u.user_id = r.user_id
      ORDER BY r.created_at DESC;
      `
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

async function updateReportStatus(req, res, next) {
  try {
    const reportId = Number(req.params.id);
    const status = req.body.status;

    const allowedStatuses = ["open", "in_progress", "resolved", "rejected"];

    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "Valid report id is required"
      });
    }

    if (!status || !allowedStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Valid status is required: open, in_progress, resolved, rejected"
      });
    }

    const resolvedAtValue = status === "resolved" ? "CURRENT_TIMESTAMP" : "resolved_at";

    const result = await query(
      `
      UPDATE reports
      SET
        status = $1,
        handled_by_support_id = $2,
        resolved_at = ${resolvedAtValue}
      WHERE report_id = $3
      RETURNING *;
      `,
      [status, req.user.user_id, reportId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Report not found"
      });
    }

    res.json({
      success: true,
      message: "Report status updated successfully",
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

async function getAllReservations(req, res, next) {
  try {
    const status = req.query.status;
    const allowedStatuses = ["reserved", "paid", "cancelled", "expired"];

    if (status && !allowedStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Valid status is required: reserved, paid, cancelled, expired"
      });
    }

    const params = [];
    const conditions = [];

    if (status) {
      params.push(status);
      conditions.push(`r.status::text = $${params.length}`);
    }

    const whereClause = conditions.length > 0
      ? "WHERE " + conditions.join(" AND ")
      : "";

    const result = await query(
      `
      SELECT
        r.reservation_id,
        r.user_id,
        u.first_name,
        u.last_name,
        u.email,
        r.ticket_id,
        r.quantity,
        r.reservation_time,
        r.expiry_time,
        r.status::text AS reservation_status,
        r.cancelled_at,
        r.cancellation_reason,
        t.price,
        t.price * r.quantity AS total_amount,
        s.name AS sport_name,
        m.home_team,
        m.away_team,
        m.match_date,
        m.match_time,
        v.name AS venue_name,
        c.name AS city_name
      FROM reservations r
      JOIN users u ON u.user_id = r.user_id
      JOIN tickets t ON t.ticket_id = r.ticket_id
      JOIN matches m ON m.match_id = t.match_id
      JOIN sports s ON s.sport_id = m.sport_id
      JOIN venues v ON v.venue_id = m.venue_id
      JOIN cities c ON c.city_id = v.city_id
      ${whereClause}
      ORDER BY r.reservation_time DESC;
      `,
      params
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

async function updateReservationStatus(req, res, next) {
  const client = await pool.connect();

  try {
    const reservationId = Number(req.params.id);
    const status = req.body.status;
    const reason = req.body.reason || "Updated by support";

    const allowedStatuses = ["reserved", "paid", "cancelled", "expired"];

    if (!reservationId) {
      return res.status(400).json({
        success: false,
        message: "Valid reservation id is required"
      });
    }

    if (!status || !allowedStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Valid status is required: reserved, paid, cancelled, expired"
      });
    }

    await client.query("BEGIN");

    const reservationResult = await client.query(
      `
      SELECT
        r.reservation_id,
        r.ticket_id,
        r.quantity,
        r.status::text AS current_status,
        t.capacity_remaining
      FROM reservations r
      JOIN tickets t ON t.ticket_id = r.ticket_id
      WHERE r.reservation_id = $1
      FOR UPDATE OF r, t;
      `,
      [reservationId]
    );

    if (reservationResult.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({
        success: false,
        message: "Reservation not found"
      });
    }

    const reservation = reservationResult.rows[0];

    const oldActive = ["reserved", "paid"].includes(reservation.current_status);
    const newActive = ["reserved", "paid"].includes(status);

    if (!oldActive && newActive) {
      if (Number(reservation.capacity_remaining) < Number(reservation.quantity)) {
        await client.query("ROLLBACK");
        return res.status(400).json({
          success: false,
          message: "Not enough ticket capacity to reactivate this reservation"
        });
      }

      await client.query(
        `
        UPDATE tickets
        SET capacity_remaining = capacity_remaining - $1
        WHERE ticket_id = $2;
        `,
        [reservation.quantity, reservation.ticket_id]
      );
    }

    if (oldActive && !newActive) {
      await client.query(
        `
        UPDATE tickets
        SET capacity_remaining = capacity_remaining + $1
        WHERE ticket_id = $2;
        `,
        [reservation.quantity, reservation.ticket_id]
      );
    }

    let updateResult;

    if (status === "cancelled") {
      updateResult = await client.query(
        `
        UPDATE reservations
        SET
          status = $1,
          cancellation_reason = $2,
          cancelled_at = CURRENT_TIMESTAMP,
          updated_at = CURRENT_TIMESTAMP
        WHERE reservation_id = $3
        RETURNING *;
        `,
        [status, reason, reservationId]
      );
    } else if (status === "expired") {
      updateResult = await client.query(
        `
        UPDATE reservations
        SET
          status = $1,
          cancellation_reason = $2,
          cancelled_at = NULL,
          updated_at = CURRENT_TIMESTAMP
        WHERE reservation_id = $3
        RETURNING *;
        `,
        [status, reason, reservationId]
      );
    } else {
      updateResult = await client.query(
        `
        UPDATE reservations
        SET
          status = $1,
          cancellation_reason = NULL,
          cancelled_at = NULL,
          updated_at = CURRENT_TIMESTAMP
        WHERE reservation_id = $2
        RETURNING *;
        `,
        [status, reservationId]
      );
    }

    await client.query("COMMIT");
    await clearTicketCache();

    res.json({
      success: true,
      message: "Reservation status updated successfully",
      data: {
        old_status: reservation.current_status,
        new_status: status,
        reservation: updateResult.rows[0]
      }
    });
  } catch (error) {
    await client.query("ROLLBACK");
    next(error);
  } finally {
    client.release();
  }
}

module.exports = {
  getAllReports,
  updateReportStatus,
  getAllReservations,
  updateReservationStatus
};
