const { query } = require("../config/db");

async function searchTickets(req, res, next) {
    try {
        const cityId = req.query.city_id;
        const sportId = req.query.sport_id;
        const seatCategoryId = req.query.seat_category_id;
        const minPrice = req.query.min_price;
        const maxPrice = req.query.max_price;
        const matchDate = req.query.match_date;
        const minCapacity = req.query.min_capacity;

        const conditions = ["t.is_active = true"];
        const params = [];

        if (cityId) {
            params.push(Number(cityId));
            conditions.push(`c.city_id = $${params.length}`);
        }

        if (sportId) {
            params.push(Number(sportId));
            conditions.push(`s.sport_id = $${params.length}`);
        }

        if (seatCategoryId) {
            params.push(Number(seatCategoryId));
            conditions.push(`sc.seat_category_id = $${params.length}`);
        }

        if (minPrice) {
            params.push(Number(minPrice));
            conditions.push(`t.price >= $${params.length}`);
        }

        if (maxPrice) {
            params.push(Number(maxPrice));
            conditions.push(`t.price <= $${params.length}`);
        }

        if (matchDate) {
            params.push(matchDate);
            conditions.push(`m.match_date::date = $${params.length}::date`);
        }

        if (minCapacity) {
            params.push(Number(minCapacity));
            conditions.push(`t.capacity_remaining >= $${params.length}`);
        }

        const result = await query(
            `
      SELECT
        t.ticket_id,
        t.price,
        t.capacity_remaining,
        t.is_active,

        sc.seat_category_id,
        sc.name AS seat_category,

        s.sport_id,
        s.name AS sport_name,

        m.match_id,
        m.home_team,
        m.away_team,
        m.match_date,
        m.match_time,
        m.status AS match_status,

        v.venue_id,
        v.name AS venue_name,
        v.address AS venue_address,

        c.city_id,
        c.name AS city_name,
        c.province,

        COALESCE(
          fd.league_or_tournament,
          vd.league_or_tournament,
          bd.league_or_tournament
        ) AS league_or_tournament,

        COALESCE(
          fd.facilities,
          vd.facilities,
          bd.facilities
        ) AS facilities

      FROM tickets t
      JOIN matches m ON m.match_id = t.match_id
      JOIN sports s ON s.sport_id = m.sport_id
      JOIN venues v ON v.venue_id = m.venue_id
      JOIN cities c ON c.city_id = v.city_id
      JOIN seat_categories sc ON sc.seat_category_id = t.seat_category_id

      LEFT JOIN football_details fd ON fd.football_detail_id = t.football_detail_id
      LEFT JOIN volleyball_details vd ON vd.volleyball_detail_id = t.volleyball_detail_id
      LEFT JOIN basketball_details bd ON bd.basketball_detail_id = t.basketball_detail_id

      WHERE ${conditions.join(" AND ")}

      ORDER BY m.match_date, m.match_time, t.price;
      `,
            params
        );

        res.json({
            success: true,
            count: result.rows.length,
            filters: {
                city_id: cityId || null,
                sport_id: sportId || null,
                seat_category_id: seatCategoryId || null,
                min_price: minPrice || null,
                max_price: maxPrice || null,
                match_date: matchDate || null,
                min_capacity: minCapacity || null
            },
            data: result.rows
        });
    } catch (error) {
        next(error);
    }
}

async function getTicketById(req, res, next) {
    try {
        const ticketId = Number(req.params.id);

        if (!ticketId) {
            return res.status(400).json({
                success: false,
                message: "Valid ticket id is required"
            });
        }

        const result = await query(
            `
      SELECT
        t.ticket_id,
        t.price,
        t.capacity_remaining,
        t.is_active,

        sc.seat_category_id,
        sc.name AS seat_category,

        s.sport_id,
        s.name AS sport_name,

        m.match_id,
        m.home_team,
        m.away_team,
        m.match_date,
        m.match_time,
        m.status AS match_status,

        v.venue_id,
        v.name AS venue_name,
        v.address AS venue_address,

        c.city_id,
        c.name AS city_name,
        c.province,

        COALESCE(
          fd.league_or_tournament,
          vd.league_or_tournament,
          bd.league_or_tournament
        ) AS league_or_tournament,

        COALESCE(
          fd.stadium_name,
          vd.hall_name,
          bd.hall_name
        ) AS place_name,

        COALESCE(
          fd.section_number,
          vd.section_number,
          bd.section_number
        ) AS section_number,

        COALESCE(
          fd.row_number,
          vd.row_number,
          bd.row_number
        ) AS row_number,

        COALESCE(
          fd.seat_number,
          vd.seat_number,
          bd.seat_number
        ) AS seat_number,

        COALESCE(
          fd.ticket_type::text,
          vd.ticket_category::text,
          bd.ticket_category::text
        ) AS ticket_detail_type,

        COALESCE(
          fd.facilities,
          vd.facilities,
          bd.facilities
        ) AS facilities

      FROM tickets t
      JOIN matches m ON m.match_id = t.match_id
      JOIN sports s ON s.sport_id = m.sport_id
      JOIN venues v ON v.venue_id = m.venue_id
      JOIN cities c ON c.city_id = v.city_id
      JOIN seat_categories sc ON sc.seat_category_id = t.seat_category_id

      LEFT JOIN football_details fd ON fd.football_detail_id = t.football_detail_id
      LEFT JOIN volleyball_details vd ON vd.volleyball_detail_id = t.volleyball_detail_id
      LEFT JOIN basketball_details bd ON bd.basketball_detail_id = t.basketball_detail_id

      WHERE t.ticket_id = $1;
      `,
            [ticketId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Ticket not found"
            });
        }

        res.json({
            success: true,
            source: "database",
            data: result.rows[0]
        });
    } catch (error) {
        next(error);
    }
}

module.exports = {
    searchTickets,
    getTicketById
};