const { pool } = require("../config/db");
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

async function expireUnpaidReservations() {
    const client = await pool.connect();

    try {
        await client.query("BEGIN");

        const expiredResult = await client.query(
            `
      UPDATE reservations
      SET
        status = 'expired',
        updated_at = CURRENT_TIMESTAMP
      WHERE status = 'reserved'
        AND expiry_time < CURRENT_TIMESTAMP
      RETURNING reservation_id, ticket_id, quantity;
      `
        );

        const expiredReservations = expiredResult.rows;

        for (const reservation of expiredReservations) {
            await client.query(
                `
        UPDATE tickets
        SET capacity_remaining = capacity_remaining + $1
        WHERE ticket_id = $2;
        `,
                [reservation.quantity, reservation.ticket_id]
            );
        }

        await client.query("COMMIT");

        if (expiredReservations.length > 0) {
            await clearTicketCache();
        }

        return expiredReservations;
    } catch (error) {
        await client.query("ROLLBACK");
        throw error;
    } finally {
        client.release();
    }
}

function startReservationExpiryJob() {
    const checkSeconds = Number(process.env.RESERVATION_EXPIRY_CHECK_SECONDS || 60);
    const intervalMs = checkSeconds * 1000;

    setInterval(async function () {
        try {
            const expiredReservations = await expireUnpaidReservations();

            if (expiredReservations.length > 0) {
                console.log(
                    "Expired unpaid reservations:",
                    expiredReservations.map(function (item) {
                        return item.reservation_id;
                    })
                );
            }
        } catch (error) {
            console.error("Reservation expiry job error:", error.message);
        }
    }, intervalMs);

    console.log("Reservation expiry job started");
}

module.exports = {
    expireUnpaidReservations,
    startReservationExpiryJob
};