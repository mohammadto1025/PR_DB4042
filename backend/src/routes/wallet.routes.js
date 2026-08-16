const express = require("express");
const {
  getMyWallet,
  depositWallet,
  getWalletTransactions
} = require("../controllers/wallet.controller");
const { authenticate } = require("../middleware/auth");

const router = express.Router();

router.get("/me", authenticate, getMyWallet);
router.post("/deposit", authenticate, depositWallet);
router.get("/transactions", authenticate, getWalletTransactions);

module.exports = router;
