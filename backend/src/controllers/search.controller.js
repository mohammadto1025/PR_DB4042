const { query } = require("../config/db");
const { esClient } = require("../config/elasticsearch");

const TICKET_INDEX = "tickets";

async function indexTickets(req, res, next) {
    try {
        const result = await query(
            `
      SELECT
        t.ticket_id,
        t.price,
        t.capacity_remaining,
        t.is_active,
        sc.name AS seat_category,
        s.name AS sport_name,
        m.match_id,
        m.home_team,
        m.away_team,
        m.match_date,
        m.match_time,
        m.status AS match_status,
        v.name AS venue_name,
        v.address AS venue_address,
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
      WHERE t.is_active = true;
      `
        );

        const exists = await esClient.indices.exists({
            index: TICKET_INDEX
        });

        if (!exists) {
            await esClient.indices.create({
                index: TICKET_INDEX,
                mappings: {
                    properties: {
                        ticket_id: { type: "long" },
                        price: { type: "double" },
                        capacity_remaining: { type: "integer" },
                        is_active: { type: "boolean" },
                        seat_category: { type: "text" },
                        sport_name: { type: "text" },
                        home_team: { type: "text" },
                        away_team: { type: "text" },
                        venue_name: { type: "text" },
                        city_name: { type: "text" },
                        province: { type: "text" },
                        league_or_tournament: { type: "text" },
                        facilities: { type: "text" }
                    }
                }
            });
        }

        for (const ticket of result.rows) {
            await esClient.index({
                index: TICKET_INDEX,
                id: String(ticket.ticket_id),
                document: ticket
            });
        }

        await esClient.indices.refresh({
            index: TICKET_INDEX
        });

        res.json({
            success: true,
            message: "Tickets indexed successfully",
            indexed_count: result.rows.length
        });
    } catch (error) {
        next(error);
    }
}

async function searchTicketsElastic(req, res, next) {
    try {
        const searchText = req.query.q;

        if (!searchText) {
            return res.status(400).json({
                success: false,
                message: "Search query q is required"
            });
        }

        const result = await esClient.search({
            index: TICKET_INDEX,
            query: {
                multi_match: {
                    query: searchText,
                    fields: [
                        "home_team^3",
                        "away_team^3",
                        "sport_name^2",
                        "venue_name^2",
                        "city_name",
                        "province",
                        "league_or_tournament",
                        "facilities",
                        "seat_category"
                    ]
                }
            }
        });

        const tickets = result.hits.hits.map(function (hit) {
            return {
                score: hit._score,
                ticket_id: hit._source.ticket_id,
                price: hit._source.price,
                capacity_remaining: hit._source.capacity_remaining,
                is_active: hit._source.is_active,
                seat_category: hit._source.seat_category,
                sport_name: hit._source.sport_name,
                match_id: hit._source.match_id,
                home_team: hit._source.home_team,
                away_team: hit._source.away_team,
                match_date: hit._source.match_date,
                match_time: hit._source.match_time,
                match_status: hit._source.match_status,
                venue_name: hit._source.venue_name,

                venue_address: hit._source.venue_address,

                city_name: hit._source.city_name,

                province: hit._source.province,

                league_or_tournament: hit._source.league_or_tournament,

                facilities: hit._source.facilities

            };

        });

        res.json({

            success: true,

            query: searchText,

            count: tickets.length,

            data: tickets

        });

    } catch (error) {

        next(error);

    }

}

module.exports = {

    indexTickets,

    searchTicketsElastic

};