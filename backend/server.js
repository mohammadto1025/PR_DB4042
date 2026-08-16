require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");

const healthRoutes = require("./src/routes/health.routes");
const authRoutes = require("./src/routes/auth.routes");
const userRoutes = require("./src/routes/user.routes");
const cityVenueRoutes = require("./src/routes/cityVenue.routes");
const ticketRoutes = require("./src/routes/ticket.routes");
const reservationRoutes = require("./src/routes/reservation.routes");
const paymentRoutes = require("./src/routes/payment.routes");
const refundRoutes = require("./src/routes/refund.routes");
const reportRoutes = require("./src/routes/report.routes");
const supportRoutes = require("./src/routes/support.routes");
const searchRoutes = require("./src/routes/search.routes");
const walletRoutes = require("./src/routes/wallet.routes");

const { errorHandler } = require("./src/middleware/errorHandler");
const { connectRedis } = require("./src/config/redis");
const { startReservationExpiryJob } = require("./src/jobs/reservationExpiry.job");

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

app.use("/api/health", healthRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api", cityVenueRoutes);
app.use("/api/tickets", ticketRoutes);
app.use("/api/reservations", reservationRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/refunds", refundRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/support", supportRoutes);
app.use("/api/search", searchRoutes);
app.use("/api/wallet", walletRoutes);

app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: "Route not found"
    });
});

app.use(errorHandler);

const PORT = process.env.PORT || 5000;

async function startServer() {
    try {
        await connectRedis();
        startReservationExpiryJob();

        app.listen(PORT, () => {
            console.log("Server is running on port " + PORT);
        });
    } catch (error) {
        console.error("Failed to start server:", error.message);
        process.exit(1);
    }
}

startServer();