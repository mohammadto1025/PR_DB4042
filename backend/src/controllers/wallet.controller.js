const { pool } = require("../config/db");

async function getTableColumns(client, tableName) {
  const result = await client.query(
    `SELECT column_name
     FROM information_schema.columns
     WHERE table_schema = 'public'
     AND table_name = $1;`,
    [tableName]
  );

  return new Set(result.rows.map((row) => row.column_name));
}

async function ensureWallet(client, userId) {
  let walletResult = await client.query(
    `SELECT wallet_id, user_id, balance
     FROM wallets
     WHERE user_id = $1
     FOR UPDATE;`,
    [userId]
  );

  if (walletResult.rows.length > 0) {
    return walletResult.rows[0];
  }

  const walletColumns = await getTableColumns(client, "wallets");
  const fields = ["user_id", "balance"];
  const values = ["$1", "$2"];
  const params = [userId, 0];

  if (walletColumns.has("last_updated")) {
    fields.push("last_updated");
    values.push("CURRENT_TIMESTAMP");
  }

  if (walletColumns.has("created_at")) {
    fields.push("created_at");
    values.push("CURRENT_TIMESTAMP");
  }

  if (walletColumns.has("updated_at")) {
    fields.push("updated_at");
    values.push("CURRENT_TIMESTAMP");
  }

  walletResult = await client.query(
    `INSERT INTO wallets (${fields.join(", ")})
     VALUES (${values.join(", ")})
     RETURNING wallet_id, user_id, balance;`,
    params
  );

  return walletResult.rows[0];
}

async function touchWalletTimestamp(client, walletId) {
  const walletColumns = await getTableColumns(client, "wallets");

  if (walletColumns.has("last_updated")) {
    await client.query(
      `UPDATE wallets SET last_updated = CURRENT_TIMESTAMP WHERE wallet_id = $1;`,
      [walletId]
    );
  } else if (walletColumns.has("updated_at")) {
    await client.query(
      `UPDATE wallets SET updated_at = CURRENT_TIMESTAMP WHERE wallet_id = $1;`,
      [walletId]
    );
  }
}

async function insertWalletTransaction(client, walletId, amount, transactionType, referenceId, description) {
  const columns = await getTableColumns(client, "wallet_transactions");

  const fields = ["wallet_id", "amount"];
  const values = ["$1", "$2"];
  const params = [walletId, amount];

  const typeColumn = columns.has("transaction_type")
    ? "transaction_type"
    : columns.has("type")
      ? "type"
      : null;

  if (typeColumn) {
    params.push(transactionType);
    fields.push(typeColumn);
    values.push("$" + params.length);
  }

  if (columns.has("reference_id")) {
    params.push(referenceId);
    fields.push("reference_id");
    values.push("$" + params.length);
  }

  if (columns.has("description")) {
    params.push(description);
    fields.push("description");
    values.push("$" + params.length);
  }

  if (columns.has("created_at")) {
    fields.push("created_at");
    values.push("CURRENT_TIMESTAMP");
  }

  const result = await client.query(
    `INSERT INTO wallet_transactions (${fields.join(", ")})
     VALUES (${values.join(", ")})
     RETURNING *;`,
    params
  );

  return result.rows[0];
}

async function getMyWallet(req, res, next) {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const wallet = await ensureWallet(client, req.user.user_id);

    const transactionsResult = await client.query(
      `SELECT *
       FROM wallet_transactions
       WHERE wallet_id = $1
       ORDER BY wallet_transaction_id DESC
       LIMIT 10;`,
      [wallet.wallet_id]
    );

    await client.query("COMMIT");

    res.json({
      success: true,
      message: "Wallet loaded successfully",
      data: {
        wallet: wallet,
        recent_transactions: transactionsResult.rows
      }
    });
  } catch (error) {
    await client.query("ROLLBACK");
    next(error);
  } finally {
    client.release();
  }
}

async function depositWallet(req, res, next) {
  const amount = Number(req.body.amount);
  const description = req.body.description || "User wallet deposit";

  if (!amount || amount <= 0) {
    return res.status(400).json({
      success: false,
      message: "Valid deposit amount is required"
    });
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const wallet = await ensureWallet(client, req.user.user_id);

    const updatedWalletResult = await client.query(
      `UPDATE wallets
       SET balance = balance + $1
       WHERE wallet_id = $2
       RETURNING wallet_id, user_id, balance;`,
      [amount, wallet.wallet_id]
    );

    await touchWalletTimestamp(client, wallet.wallet_id);

    const walletTransaction = await insertWalletTransaction(
      client,
      wallet.wallet_id,
      amount,
      "deposit",
      null,
      description
    );

    await client.query("COMMIT");

    res.status(201).json({
      success: true,
      message: "Wallet deposit completed successfully",
      data: {
        wallet: updatedWalletResult.rows[0],
        transaction: walletTransaction
      }
    });
  } catch (error) {
    await client.query("ROLLBACK");
    next(error);
  } finally {
    client.release();
  }
}

async function getWalletTransactions(req, res, next) {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const wallet = await ensureWallet(client, req.user.user_id);

    const transactionsResult = await client.query(
      `SELECT *
       FROM wallet_transactions
       WHERE wallet_id = $1
       ORDER BY wallet_transaction_id DESC;`,
      [wallet.wallet_id]
    );

    await client.query("COMMIT");

    res.json({
      success: true,
      count: transactionsResult.rows.length,
      data: transactionsResult.rows
    });
  } catch (error) {
    await client.query("ROLLBACK");
    next(error);
  } finally {
    client.release();
  }
}

module.exports = {
  getMyWallet,
  depositWallet,
  getWalletTransactions,
  ensureWallet,
  insertWalletTransaction,
  touchWalletTimestamp
};
