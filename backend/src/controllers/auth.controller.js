const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const { query } = require("../config/db");
const { redisClient } = require("../config/redis");

function generateOtp() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

function createJwtForUser(user) {
    return jwt.sign(
        {
            user_id: user.user_id,
            email: user.email,
            role: user.role
        },
        process.env.JWT_SECRET,
        {
            expiresIn: process.env.JWT_EXPIRES_IN || "1d"
        }
    );
}

function removePasswordHash(userWithPassword) {
    return {
        user_id: userWithPassword.user_id,
        first_name: userWithPassword.first_name,
        last_name: userWithPassword.last_name,
        email: userWithPassword.email,
        phone: userWithPassword.phone,
        role: userWithPassword.role,
        city_id: userWithPassword.city_id,
        registration_date: userWithPassword.registration_date
    };
}

async function findUserByIdentifier(identifier) {
    const result = await query(
        `
    SELECT
      user_id,
      first_name,
      last_name,
      email,
      phone,
      password_hash,
      role,
      city_id,
      registration_date
    FROM users
    WHERE email = $1 OR phone = $1;
    `,
        [identifier]
    );

    return result.rows[0] || null;
}

async function validatePassword(userWithPassword, password) {
    if (!userWithPassword || !userWithPassword.password_hash) {
        return false;
    }

    try {
        const bcryptValid = await bcrypt.compare(password, userWithPassword.password_hash);

        if (bcryptValid) {
            return true;
        }
    } catch (error) {
        // If the stored value is not a bcrypt hash, fall back to plain comparison for old demo seed data.
    }

    return password === userWithPassword.password_hash;
}

async function saveOtpLog(userId, identifier, purpose, ttlSeconds, codeHashText) {
    await query(
        `
    INSERT INTO otp_logs (
      user_id,
      identifier,
      purpose,
      code_hash,
      status,
      expires_at,
      created_at
    )
    VALUES (
      $1,
      $2,
      $3,
      $4,
      'sent',
      CURRENT_TIMESTAMP + ($5 || ' seconds')::INTERVAL,
      CURRENT_TIMESTAMP
    );
    `,
        [userId, identifier, purpose, codeHashText, ttlSeconds]
    );
}

async function markLatestOtpVerified(identifier, purpose) {
    await query(
        `
    UPDATE otp_logs
    SET status = 'verified',
        verified_at = CURRENT_TIMESTAMP
    WHERE otp_id = (
      SELECT otp_id
      FROM otp_logs
      WHERE identifier = $1
        AND purpose = $2
        AND status = 'sent'
        AND expires_at >= CURRENT_TIMESTAMP
      ORDER BY created_at DESC
      LIMIT 1
    );
    `,
        [identifier, purpose]
    );
}

async function sendOtp(req, res, next) {
    try {
        const identifier = req.body.identifier;
        const purpose = req.body.purpose || "login";

        if (!identifier) {
            return res.status(400).json({
                success: false,
                message: "identifier is required"
            });
        }

        const otp = generateOtp();
        const ttlSeconds = Number(process.env.OTP_TTL_SECONDS || 300);
        const redisKey = "otp:" + purpose + ":" + identifier;

        await redisClient.set(redisKey, otp, {
            EX: ttlSeconds
        });

        await saveOtpLog(null, identifier, purpose, ttlSeconds, "stored_in_redis_for_demo");

        res.json({
            success: true,
            message: "OTP generated successfully",
            data: {
                identifier: identifier,
                purpose: purpose,
                expires_in_seconds: ttlSeconds,
                demo_otp: otp
            }
        });
    } catch (error) {
        next(error);
    }
}

async function verifyOtp(req, res, next) {
    try {
        const identifier = req.body.identifier;
        const purpose = req.body.purpose || "login";
        const otp = req.body.otp;

        if (!identifier || !otp) {
            return res.status(400).json({
                success: false,
                message: "identifier and otp are required"
            });
        }

        const redisKey = "otp:" + purpose + ":" + identifier;
        const savedOtp = await redisClient.get(redisKey);

        if (!savedOtp || savedOtp !== otp) {
            return res.status(400).json({
                success: false,
                message: "Invalid or expired OTP"
            });
        }

        const userWithPassword = await findUserByIdentifier(identifier);

        if (!userWithPassword) {
            return res.status(404).json({
                success: false,
                message: "User not found"
            });
        }

        const user = removePasswordHash(userWithPassword);

        await markLatestOtpVerified(identifier, purpose);
        await redisClient.del(redisKey);

        const token = createJwtForUser(user);

        res.json({
            success: true,
            message: "OTP verified successfully",
            data: {
                user: user,
                token: token
            }
        });
    } catch (error) {
        next(error);
    }
}

async function requestLoginOtpAfterPassword(req, res, next) {
    try {
        const identifier = req.body.identifier;
        const password = req.body.password;

        if (!identifier || !password) {
            return res.status(400).json({
                success: false,
                message: "identifier and password are required"
            });
        }

        const userWithPassword = await findUserByIdentifier(identifier);

        if (!userWithPassword) {
            return res.status(401).json({
                success: false,
                message: "Invalid login credentials"
            });
        }

        const isPasswordValid = await validatePassword(userWithPassword, password);

        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: "Invalid login credentials"
            });
        }

        const otp = generateOtp();
        const ttlSeconds = Number(process.env.OTP_TTL_SECONDS || 300);
        const redisKey = "otp:password_login:" + identifier;

        await redisClient.set(redisKey, otp, {
            EX: ttlSeconds
        });

        await saveOtpLog(
            userWithPassword.user_id,
            identifier,
            "login",
            ttlSeconds,
            "password_verified_stored_in_redis_for_demo"
        );

        res.json({
            success: true,
            message: "Password verified. OTP generated successfully",
            data: {
                identifier: identifier,
                purpose: "password_login",
                expires_in_seconds: ttlSeconds,
                demo_otp: otp
            }
        });
    } catch (error) {
        next(error);
    }
}

async function verifyLoginOtpAfterPassword(req, res, next) {
    try {
        const identifier = req.body.identifier;
        const otp = req.body.otp;

        if (!identifier || !otp) {
            return res.status(400).json({
                success: false,
                message: "identifier and otp are required"
            });
        }

        const redisKey = "otp:password_login:" + identifier;
        const savedOtp = await redisClient.get(redisKey);

        if (!savedOtp || savedOtp !== otp) {
            return res.status(400).json({
                success: false,
                message: "Invalid or expired OTP"
            });
        }

        const userWithPassword = await findUserByIdentifier(identifier);

        if (!userWithPassword) {
            return res.status(404).json({
                success: false,
                message: "User not found"
            });
        }

        const user = removePasswordHash(userWithPassword);

        await markLatestOtpVerified(identifier, "login");
        await redisClient.del(redisKey);

        const token = createJwtForUser(user);

        res.json({
            success: true,
            message: "Password and OTP verified successfully",
            data: {
                user: user,
                token: token
            }
        });
    } catch (error) {
        next(error);
    }
}

async function signup(req, res, next) {
    try {
        const firstName = req.body.first_name;
        const lastName = req.body.last_name;
        const email = req.body.email;
        const phone = req.body.phone;
        const password = req.body.password;
        const cityId = req.body.city_id;

        if (!firstName || !lastName || !email || !phone || !password || !cityId) {
            return res.status(400).json({
                success: false,
                message: "first_name, last_name, email, phone, password, and city_id are required"
            });
        }

        const existingUser = await query(
            `
      SELECT user_id
      FROM users
      WHERE email = $1 OR phone = $2;
      `,
            [email, phone]
        );

        if (existingUser.rows.length > 0) {
            return res.status(400).json({
                success: false,
                message: "User with this email or phone already exists"
            });
        }

        const passwordHash = await bcrypt.hash(password, 10);

        const result = await query(
            `
      INSERT INTO users (
        first_name,
        last_name,
        email,
        phone,
        password_hash,
        role,
        city_id,
        registration_date
      )
      VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        'spectator',
        $6,
        CURRENT_TIMESTAMP
      )
      RETURNING
        user_id,
        first_name,
        last_name,
        email,
        phone,
        role,
        city_id,
        registration_date;
      `,
            [firstName, lastName, email, phone, passwordHash, cityId]
        );

        const user = result.rows[0];
        const token = createJwtForUser(user);

        res.status(201).json({
            success: true,
            message: "User registered successfully",
            data: {
                user: user,
                token: token
            }
        });
    } catch (error) {
        next(error);
    }
}

async function getMe(req, res, next) {
    try {
        const result = await query(
            `
      SELECT
        u.user_id,
        u.first_name,
        u.last_name,
        u.email,
        u.phone,
        u.role,
        u.city_id,
        c.name AS city_name,
        c.province,
        u.registration_date
      FROM users u
      LEFT JOIN cities c ON c.city_id = u.city_id
      WHERE u.user_id = $1;
      `,
            [req.user.user_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "User not found"
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        next(error);
    }
}

module.exports = {
    sendOtp,
    verifyOtp,
    requestLoginOtpAfterPassword,
    verifyLoginOtpAfterPassword,
    signup,
    getMe
};