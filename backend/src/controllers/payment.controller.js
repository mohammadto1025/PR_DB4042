const { pool } = require("../config/db");
const {
    ensureWallet,
    insertWalletTransaction,
    touchWalletTimestamp
} = require("./wallet.controller");

async function createPayment(req, res, next) {
    const reservationId = Number(req.body.reservation_id);
    const paymentMethod = String(req.body.payment_method || "card").trim().toLowerCase();
    const userId = req.user.user_id;

    if (!reservationId) {
        return res.status(400).json({
            success: false,
            message: "Reservation ID is required"
        });
    }

    if (!["card", "wallet"].includes(paymentMethod)) {
        return res.status(400).json({
            success: false,
            message: "Valid payment method is required: card or wallet"
        });
    }

    const client = await pool.connect();

    try {
        await client.query("BEGIN");

        const reservationResult = await client.query(
            `SELECT
         r.reservation_id,
         r.user_id,
         r.ticket_id,
         r.quantity,
         r.status::text AS reservation_status,
         r.expiry_time,
         t.price
       FROM reservations r
       JOIN tickets t ON t.ticket_id = r.ticket_id
       WHERE r.reservation_id = $1
       AND r.user_id = $2
       FOR UPDATE OF r;`,
            [reservationId, userId]
        );

        if (reservationResult.rows.length === 0) {
            await client.query("ROLLBACK");
            return res.status(404).json({
                success: false,
                message: "Reservation not found for this user"
            });
        }

        const reservation = reservationResult.rows[0];

        if (reservation.reservation_status !== "reserved") {
            await client.query("ROLLBACK");
            return res.status(400).json({
                success: false,
                message: "Only reserved reservations can be paid"
            });
        }

        const expiryTime = new Date(reservation.expiry_time);
        if (expiryTime < new Date()) {
            await client.query(
                `UPDATE reservations
         SET status = 'expired', updated_at = CURRENT_TIMESTAMP
         WHERE reservation_id = $1;`,
                [reservationId]
            );

            await client.query(
                `UPDATE tickets
         SET capacity_remaining = capacity_remaining + $1
         WHERE ticket_id = $2;`,
                [reservation.quantity, reservation.ticket_id]
            );

            await client.query("COMMIT");

            return res.status(400).json({
                success: false,
                message: "Reservation is expired and cannot be paid"
            });
        }

        const amount = Number(reservation.price) * Number(reservation.quantity);
        const transactionId = "TXN-" + Date.now() + "-" + reservationId;
        let walletAfterPayment = null;
        let walletTransaction = null;

        if (paymentMethod === "wallet") {
            const wallet = await ensureWallet(client, userId);
            const currentBalance = Number(wallet.balance);

            if (currentBalance < amount) {
                await client.query("ROLLBACK");
                return res.status(400).json({
                    success: false,
                    message: "Insufficient wallet balance",
                    data: {
                        wallet_balance: currentBalance,
                        required_amount: amount
                    }
                });
            }

            const updatedWalletResult = await client.query(
                `UPDATE wallets
         SET balance = balance - $1
         WHERE wallet_id = $2
         RETURNING wallet_id, user_id, balance;`,
                [amount, wallet.wallet_id]
            );

            await touchWalletTimestamp(client, wallet.wallet_id);

            walletAfterPayment = updatedWalletResult.rows[0];
        }

        const paymentResult = await client.query(
            `INSERT INTO payments
        (reservation_id, user_id, amount, payment_method, status, transaction_id, payment_date)
       VALUES
        ($1, $2, $3, $4, 'successful', $5, CURRENT_TIMESTAMP)
       RETURNING *;`,
            [reservationId, userId, amount, paymentMethod, transactionId]
        );

        const payment = paymentResult.rows[0];

        if (paymentMethod === "wallet") {
            const wallet = walletAfterPayment;
            walletTransaction = await insertWalletTransaction(
                client,
                wallet.wallet_id,
                -amount,
                "withdrawal",
                payment.payment_id,
                "Payment for reservation " + reservationId
            );
        }

        const updatedReservationResult = await client.query(
            `UPDATE reservations
       SET status = 'paid', updated_at = CURRENT_TIMESTAMP
       WHERE reservation_id = $1
       RETURNING *;`,
            [reservationId]
        );

        await client.query("COMMIT");

        res.status(201).json({
            success: true,
            message: paymentMethod === "wallet"
                ? "Payment completed successfully using wallet"
                : "Payment completed successfully using card",
            data: {
                payment: payment,
                reservation: updatedReservationResult.rows[0],
                wallet: walletAfterPayment,
                wallet_transaction: walletTransaction
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
    createPayment
};