const { query } = require("../config/db");
const { redisClient } = require("../config/redis");

async function getCachedOrLoad(cacheKey, loader, ttlSeconds) {
    const cached = await redisClient.get(cacheKey);

    if (cached) {
        return {
            source: "cache",
            data: JSON.parse(cached)
        };
    }

    const data = await loader();

    await redisClient.set(cacheKey, JSON.stringify(data), {
        EX: ttlSeconds
    });

    return {
        source: "database",
        data: data
    };
}

async function getCities(req, res, next) {
    try {
        const cacheResult = await getCachedOrLoad(
            "cities:all",
            async function () {
                const result = await query(
                    `
          SELECT city_id, name, province
          FROM cities
          ORDER BY name;
          `
                );
                return result.rows;
            },
            Number(process.env.CACHE_TTL_SECONDS || 60)
        );

        res.json({
            success: true,
            source: cacheResult.source,
            count: cacheResult.data.length,
            data: cacheResult.data
        });
    } catch (error) {
        next(error);
    }
}

async function getVenues(req, res, next) {
    try {
        const cityId = req.query.city_id;
        const params = [];
        const conditions = [];

        if (cityId) {
            params.push(Number(cityId));
            conditions.push(`v.city_id = $${params.length}`);
        }

        const whereClause = conditions.length > 0
            ? "WHERE " + conditions.join(" AND ")
            : "";

        const result = await query(
            `
      SELECT
        v.venue_id,
        v.name,
        v.address,
        v.capacity,
        v.city_id,
        c.name AS city_name,
        c.province
      FROM venues v
      JOIN cities c ON c.city_id = v.city_id
      ${whereClause}
      ORDER BY v.name;
      `,
            params
        );

        res.json({
            success: true,
            source: "database",
            count: result.rows.length,
            data: result.rows
        });
    } catch (error) {
        next(error);
    }
}

async function getSports(req, res, next) {
    try {
        const cacheResult = await getCachedOrLoad(
            "sports:all",
            async function () {
                const result = await query(
                    `
          SELECT sport_id, name
          FROM sports
          ORDER BY name;
          `
                );
                return result.rows;
            },
            Number(process.env.CACHE_TTL_SECONDS || 60)
        );

        res.json({
            success: true,
            source: cacheResult.source,
            count: cacheResult.data.length,
            data: cacheResult.data
        });
    } catch (error) {
        next(error);
    }
}

async function getSeatCategories(req, res, next) {
    try {
        const cacheResult = await getCachedOrLoad(
            "seat_categories:all",
            async function () {
                const result = await query(
                    `
          SELECT seat_category_id, name
          FROM seat_categories
          ORDER BY name;
          `
                );
                return result.rows;
            },
            Number(process.env.CACHE_TTL_SECONDS || 60)
        );

        res.json({
            success: true,
            source: cacheResult.source,
            count: cacheResult.data.length,
            data: cacheResult.data
        });
    } catch (error) {
        next(error);
    }
}

module.exports = {
    getCities,
    getVenues,
    getSports,
    getSeatCategories
};