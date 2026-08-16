const { query } = require("../config/db");
const { redisClient } = require("../config/redis");

async function getMyProfile(req, res, next) {
  try {
    const cacheKey = `user_profile:${req.user.user_id}`;
    const cachedProfile = await redisClient.get(cacheKey);

    if (cachedProfile) {
      return res.json({
        success: true,
        source: "cache",
        data: JSON.parse(cachedProfile)
      });
    }

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

    const profile = result.rows[0];

    await redisClient.set(cacheKey, JSON.stringify(profile), {
      EX: Number(process.env.CACHE_TTL_SECONDS || 60)
    });

    res.json({
      success: true,
      source: "database",
      data: profile
    });
  } catch (error) {
    next(error);
  }
}

async function updateMyProfile(req, res, next) {
  try {
    const {
      first_name,
      last_name,
      phone,
      city_id
    } = req.body;

    const result = await query(
      `
      UPDATE users
      SET
        first_name = COALESCE($1, first_name),
        last_name = COALESCE($2, last_name),
        phone = COALESCE($3, phone),
        city_id = COALESCE($4, city_id)
      WHERE user_id = $5
      RETURNING
        user_id,
        first_name,
        last_name,
        email,
        phone,
        role,
        city_id;
      `,
      [first_name, last_name, phone, city_id, req.user.user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    await redisClient.del(`user_profile:${req.user.user_id}`);

    res.json({
      success: true,
      message: "Profile updated successfully",
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getMyProfile,
  updateMyProfile
};