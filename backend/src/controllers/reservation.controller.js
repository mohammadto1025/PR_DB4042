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

function calculateCancellationPenalty(matchDateTime, totalAmount) {
  const now = new Date();
  const matchTime = new Date(matchDateTime);
  const hoursUntilMatch = (matchTime - now) / (1000 * 60 * 60);

  let penaltyPercentage = 0;

  if (hoursUntilMatch >= 48) {
    penaltyPercentage = 0;
  } else if (hoursUntilMatch >= 24) {
    penaltyPercentage = 20;
  } else {
    penaltyPercentage = 50;
  }

  const penaltyAmount = (Number(totalAmount) * penaltyPercentage) / 100;
  const refundAmount = Number(totalAmount) - penaltyAmount;

  return {
    hours_until_match: Number(hoursUntilMatch.toFixed(2)),
    penalty_percentage: penaltyPercentage,
    penalty_amount: penaltyAmount,
    refund_amount: refundAmount
  };
}

async function createReservation(req, res, next) {
  const client = await pool.connect();

  try {
    const ticketId = Number(req.body.ticket_id);
    const quantity = Number(req.body.quantity || 1);

    if (!ticketId || quantity <= 0) {
      return res.status(400).json({
        success: false,
        message: "Valid ticket_id and quantity are required"
      });
    }

    await client.query("BEGIN");

    const ticketResult = await client.query(
      `
      SELECT ticket_id, price, capacity_remaining, is_active
      FROM tickets
      WHERE ticket_id = $1
      FOR UPDATE;
      `,
      [ticketId]
    );

    if (ticketResult.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ success: false, message: "Ticket not found" });
    }

    const ticket = ticketResult.rows[0];

    if (!ticket.is_active) {
      await client.query("ROLLBACK");
      return res.status(400).json({ success: false, message: "Ticket is not active" });
    }

    if (Number(ticket.capacity_remaining) < quantity) {
      await client.query("ROLLBACK");
      return res.status(400).json({ success: false, message: "Not enough ticket capacity" });
    }

    const reservationTtl = Number(process.env.RESERVATION_TTL_MINUTES || 10);

    const reservationResult = await client.query(
      `
      INSERT INTO reservations (
        user_id,
        ticket_id,
        quantity,
        reservation_time,
        expiry_time,
        status
      )
      VALUES (
        $1,
        $2,
        $3,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + ($4 || ' minutes')::INTERVAL,
        'reserved'
      )
      RETURNING *;
      `,
      [req.user.user_id, ticketId, quantity, reservationTtl]
    );

    await client.query(
      `
      UPDATE tickets
      SET capacity_remaining = capacity_remaining - $1
      WHERE ticket_id = $2;
      `,
      [quantity, ticketId]
    );

    await client.query(
      `
      INSERT INTO reservation_actions (
        reservation_id,
        action_type,
        old_status,
        new_status,
        action_by_user_id,
        action_time,
        note
      )
      VALUES (
        $1,
        'created',
        NULL,
        'reserved',
        $2,
        CURRENT_TIMESTAMP,
        'Reservation created by user'
      );
      `,
      [reservationResult.rows[0].reservation_id, req.user.user_id]
    );

    await client.query("COMMIT");
    await clearTicketCache();

    res.status(201).json({
      success: true,
      message: "Reservation created successfully",
      data: {
        reservation: reservationResult.rows[0],
        total_amount: Number(ticket.price) * quantity
      }
    });
  } catch (error) {
    await client.query("ROLLBACK");
    next(error);
  } finally {
    client.release();
  }
}

async function getActiveReservations(req, res, next) {
  try {
    const result = await query(
      `
      SELECT
        r.reservation_id,
        r.ticket_id,
        r.quantity,
        r.reservation_time,
        r.expiry_time,
        r.status,
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
      JOIN tickets t ON t.ticket_id = r.ticket_id
      JOIN matches m ON m.match_id = t.match_id
      JOIN sports s ON s.sport_id = m.sport_id
      JOIN venues v ON v.venue_id = m.venue_id
      JOIN cities c ON c.city_id = v.city_id
      WHERE r.user_id = $1
        AND r.status = 'reserved'
        AND r.expiry_time >= CURRENT_TIMESTAMP
      ORDER BY r.reservation_time DESC;
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

async function getReservationHistory(req, res, next) {
  try {
    const result = await query(
      `
      SELECT
        r.reservation_id,
        r.ticket_id,
        r.quantity,
        r.reservation_time,
        r.expiry_time,
        r.status::text AS reservation_status,
        r.cancelled_at,
        r.cancellation_reason,
        t.price,
        t.price * r.quantity AS total_amount,
        sc.name AS seat_category,
        s.name AS sport_name,
        m.home_team,
        m.away_team,
        m.match_date,
        m.match_time,
        v.name AS venue_name,
        c.name AS city_name,
        p.payment_id,
        p.amount AS payment_amount,
        p.payment_method,
        CASE
          WHEN p.payment_id IS NULL THEN 'not_paid'
          ELSE p.status::text
        END AS payment_status,
        p.transaction_id,
        p.payment_date,
        rf.refund_id,
        rf.amount AS refund_amount,
        rf.status::text AS refund_status,
        rf.refund_date,
        rf.reason AS refund_reason
      FROM reservations r
      JOIN tickets t ON t.ticket_id = r.ticket_id
      JOIN seat_categories sc ON sc.seat_category_id = t.seat_category_id
      JOIN matches m ON m.match_id = t.match_id
      JOIN sports s ON s.sport_id = m.sport_id
      JOIN venues v ON v.venue_id = m.venue_id
      JOIN cities c ON c.city_id = v.city_id
      LEFT JOIN payments p ON p.reservation_id = r.reservation_id
      LEFT JOIN refunds rf ON rf.payment_id = p.payment_id
      WHERE r.user_id = $1
      ORDER BY r.reservation_time DESC;
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

async function changeReservationTicket(req, res, next) {
  const client = await pool.connect();

  try {
    const reservationId = Number(req.params.id);
    const newTicketId = Number(req.body.new_ticket_id);

    if (!reservationId || !newTicketId) {
      return res.status(400).json({
        success: false,
        message: "Valid reservation id and new_ticket_id are required"
      });
    }

    await client.query("BEGIN");

    const reservationResult = await client.query(
      `
      SELECT
        r.reservation_id,
        r.user_id,
        r.ticket_id AS old_ticket_id,
        r.quantity,
        r.status::text AS reservation_status,
        r.expiry_time,
        old_ticket.match_id AS old_match_id
      FROM reservations r
      JOIN tickets old_ticket ON old_ticket.ticket_id = r.ticket_id
      WHERE r.reservation_id = $1
        AND r.user_id = $2
      FOR UPDATE OF r, old_ticket;
      `,
      [reservationId, req.user.user_id]
    );

    if (reservationResult.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ success: false, message: "Reservation not found" });
    }

    const reservation = reservationResult.rows[0];

    if (reservation.reservation_status !== "reserved") {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: "Only unpaid reserved reservations can be changed"
      });
    }

    if (new Date(reservation.expiry_time) < new Date()) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: "Reservation has expired"
      });
    }

    if (Number(reservation.old_ticket_id) === newTicketId) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: "New ticket must be different from current ticket"
      });
    }

    const newTicketResult = await client.query(
      `
      SELECT
        ticket_id,
        match_id,
        price,
        capacity_remaining,
        is_active
      FROM tickets
      WHERE ticket_id = $1
      FOR UPDATE;
      `,
      [newTicketId]
    );

    if (newTicketResult.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ success: false, message: "New ticket not found" });
    }

    const newTicket = newTicketResult.rows[0];

    if (!newTicket.is_active) {
      await client.query("ROLLBACK");
      return res.status(400).json({ success: false, message: "New ticket is not active" });
    }

    if (Number(newTicket.match_id) !== Number(reservation.old_match_id)) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: "New ticket must belong to the same match"
      });
    }

    if (Number(newTicket.capacity_remaining) < Number(reservation.quantity)) {
      await client.query("ROLLBACK");
      return res.status(400).json({ success: false, message: "Not enough capacity for new ticket" });
    }

    await client.query(
      `
      UPDATE tickets
      SET capacity_remaining = capacity_remaining + $1
      WHERE ticket_id = $2;
      `,
      [reservation.quantity, reservation.old_ticket_id]
    );

    await client.query(
      `
      UPDATE tickets
      SET capacity_remaining = capacity_remaining - $1
      WHERE ticket_id = $2;
      `,
      [reservation.quantity, newTicketId]
    );

    const updatedReservation = await client.query(
      `
      UPDATE reservations
      SET
        ticket_id = $1,
        updated_at = CURRENT_TIMESTAMP
      WHERE reservation_id = $2
      RETURNING *;
      `,
      [newTicketId, reservationId]
    );

    await client.query("COMMIT");
    await clearTicketCache();

    res.json({
      success: true,
      message: "Reservation ticket changed successfully",
      data: {
        old_ticket_id: Number(reservation.old_ticket_id),
        new_ticket_id: newTicketId,
        reservation: updatedReservation.rows[0]
      }
    });
  } catch (error) {
    await client.query("ROLLBACK");
    next(error);
  } finally {
    client.release();
  }
}

async function getCancellationPenalty(req, res, next) {
  try {
    const reservationId = Number(req.params.id);

    if (!reservationId) {
      return res.status(400).json({
        success: false,
        message: "Valid reservation id is required"
      });
    }

    const result = await query(
      `
      SELECT
        r.reservation_id,
        r.status,
        r.quantity,
        t.price,
        t.price * r.quantity AS total_amount,
        (m.match_date::date + m.match_time) AS match_datetime
      FROM reservations r
      JOIN tickets t ON t.ticket_id = r.ticket_id
      JOIN matches m ON m.match_id = t.match_id
      WHERE r.reservation_id = $1
        AND r.user_id = $2;
      `,
      [reservationId, req.user.user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Reservation not found"
      });
    }

    const reservation = result.rows[0];

    if (reservation.status === "cancelled") {
      return res.status(400).json({
        success: false,
        message: "Reservation is already cancelled"
      });
    }

    const penalty = calculateCancellationPenalty(
      reservation.match_datetime,
      reservation.total_amount
    );

    res.json({
      success: true,
      data: {
        reservation_id: reservation.reservation_id,
        status: reservation.status,
        total_amount: Number(reservation.total_amount),
        ...penalty
      }
    });
  } catch (error) {
    next(error);
  }
}

async function cancelReservation(req, res, next) {
  const client = await pool.connect();

  try {
    const reservationId = Number(req.params.id);
    const reason = req.body.reason || "Cancelled by user";

    if (!reservationId) {
      return res.status(400).json({
        success: false,
        message: "Valid reservation id is required"
      });
    }

    await client.query("BEGIN");

    const reservationResult = await client.query(
      `
      SELECT
        r.reservation_id,
        r.user_id,
        r.ticket_id,
        r.quantity,
        r.status,
        t.price,
        t.price * r.quantity AS total_amount,
        (m.match_date::date + m.match_time) AS match_datetime
      FROM reservations r
      JOIN tickets t ON t.ticket_id = r.ticket_id
      JOIN matches m ON m.match_id = t.match_id
      WHERE r.reservation_id = $1
        AND r.user_id = $2
      FOR UPDATE OF r;
      `,
      [reservationId, req.user.user_id]
    );

    if (reservationResult.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({
        success: false,
        message: "Reservation not found"
      });
    }

    const reservation = reservationResult.rows[0];

    if (reservation.status === "cancelled") {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: "Reservation is already cancelled"
      });
    }

    if (!["reserved", "paid"].includes(reservation.status)) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: "This reservation cannot be cancelled"
      });
    }

    const penalty = calculateCancellationPenalty(
      reservation.match_datetime,
      reservation.total_amount
    );

    const updatedReservation = await client.query(
      `
      UPDATE reservations
      SET
        status = 'cancelled',
        cancelled_at = CURRENT_TIMESTAMP,
        cancellation_reason = $1,
        updated_at = CURRENT_TIMESTAMP
      WHERE reservation_id = $2
      RETURNING *;
      `,
      [reason, reservationId]
    );

    await client.query(
      `
      UPDATE tickets
      SET capacity_remaining = capacity_remaining + $1
      WHERE ticket_id = $2;
      `,
      [reservation.quantity, reservation.ticket_id]
    );

    await client.query(
      `
      INSERT INTO reservation_actions (
        reservation_id,
        action_type,
        old_status,
        new_status,
        action_by_user_id,
        action_time,
        note
      )
      VALUES (
        $1,
        'cancelled_by_user',
        $2,
        'cancelled',
        $3,
        CURRENT_TIMESTAMP,
        $4
      );
      `,
      [reservationId, reservation.status, req.user.user_id, reason]
    );

    await client.query("COMMIT");
    await clearTicketCache();

    res.json({
      success: true,
      message: "Reservation cancelled successfully",
      data: {
        reservation: updatedReservation.rows[0],
        cancellation: penalty
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
  createReservation,
  getActiveReservations,
  getReservationHistory,
  changeReservationTicket,
  getCancellationPenalty,
  cancelReservation
};