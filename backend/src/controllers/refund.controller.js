const { pool } = require("../config/db");

function calculateRefund(matchDateTime, totalAmount) {
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

async function createRefund(req, res, next) {
    const client = await pool.connect();

    try {
        const paymentId = Number(req.body.payment_id);
        const reason = req.body.reason || "Refund requested by user";

        if (!paymentId) {
            return res.status(400).json({
                success: false,
                message: "Valid payment_id is required"
            });
        }

        await client.query("BEGIN");

        const paymentResult = await client.query(
            `
      SELECT
        p.payment_id,
        p.reservation_id,
        p.user_id,
        p.amount,
        p.status AS payment_status,
        r.ticket_id,
        r.quantity,
        r.status AS reservation_status,
        (m.match_date::date + m.match_time) AS match_datetime
      FROM payments p
      JOIN reservations r ON r.reservation_id = p.reservation_id
      JOIN tickets t ON t.ticket_id = r.ticket_id
      JOIN matches m ON m.match_id = t.match_id
      WHERE p.payment_id = $1
        AND p.user_id = $2
      FOR UPDATE OF p, r;
      `,
            [paymentId, req.user.user_id]
        );

        if (paymentResult.rows.length === 0) {
            await client.query("ROLLBACK");
            return res.status(404).json({
                success: false,
                message: "Payment not found"
            });
        }

        const payment = paymentResult.rows[0];

        if (payment.payment_status !== "successful") {
            await client.query("ROLLBACK");
            return res.status(400).json({
                success: false,
                message: "Only successful payments can be refunded"
            });
        }

        const existingRefund = await client.query(
            `
      SELECT refund_id
      FROM refunds
      WHERE payment_id = $1;
      `,
            [paymentId]
        );

        if (existingRefund.rows.length > 0) {
            await client.query("ROLLBACK");
            return res.status(400).json({
                success: false,
                message: "Refund already exists for this payment"
            });
        }

        const refundCalculation = calculateRefund(
            payment.match_datetime,
            payment.amount
        );

        const supportResult = await client.query(
            `
            SELECT user_id
            FROM users
            WHERE role = 'support'
            ORDER BY user_id
            LIMIT 1;
            `
          );

        if (supportResult.rows.length === 0) {
            await client.query("ROLLBACK");
            return res.status(400).json({
                success: false,
                message: "No support or admin user found to approve refund"
            });
        }

        const approvedBySupportId = supportResult.rows[0].user_id;

        const refundResult = await client.query(
            `
        INSERT INTO refunds (
          payment_id,
          amount,
          refund_date,
          reason,
          status,
          approved_by_support_id
        )
        VALUES (
          $1,
          $2,
          CURRENT_TIMESTAMP,
          $3,
          'completed',
          $4
        )
        RETURNING *;
        `,
            [
                payment.payment_id,
                refundCalculation.refund_amount,
                reason,
                approvedBySupportId
            ]
        );

        await client.query(
            `
      UPDATE payments
      SET status = 'refunded'
      WHERE payment_id = $1;
      `,
            [payment.payment_id]
        );

        await client.query(
            `
      UPDATE reservations
      SET
        status = 'cancelled',
        cancelled_at = CURRENT_TIMESTAMP,
        cancellation_reason = $1,
        updated_at = CURRENT_TIMESTAMP
      WHERE reservation_id = $2;
      `,
            [reason, payment.reservation_id]
        );

        await client.query(
            `
      UPDATE tickets
      SET capacity_remaining = capacity_remaining + $1
      WHERE ticket_id = $2;
      `,
            [payment.quantity, payment.ticket_id]
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
      )VALUES (
        $1,
        'cancelled_by_user',
        $2,
        'cancelled',
        $3,
        CURRENT_TIMESTAMP,
        $4
      );
      `,
            [
                payment.reservation_id,
                payment.reservation_status,
                req.user.user_id,
                reason
            ]
        );

        await client.query("COMMIT");

        res.status(201).json({
            success: true,
            message: "Refund completed successfully",
            data: {
                refund: refundResult.rows[0],
                payment_status: "refunded",
                reservation_status: "cancelled",
                calculation: refundCalculation
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
    createRefund
};