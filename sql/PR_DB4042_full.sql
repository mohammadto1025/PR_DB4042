--
-- PostgreSQL database dump
--

\restrict azqKDrW1TzdyLanMYX2jZ8q3sVcuQRCeSRftbtxgH7Z5OPkT0L6gadrMLUKq7v3

-- Dumped from database version 17.10
-- Dumped by pg_dump version 17.10

-- Started on 2026-07-08 00:27:29 +0330

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 17014)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 4148 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 945 (class 1247 OID 16494)
-- Name: account_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.account_status AS ENUM (
    'active',
    'inactive'
);


ALTER TYPE public.account_status OWNER TO postgres;

--
-- TOC entry 954 (class 1247 OID 16537)
-- Name: match_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.match_status AS ENUM (
    'scheduled',
    'ongoing',
    'finished',
    'cancelled'
);


ALTER TYPE public.match_status OWNER TO postgres;

--
-- TOC entry 1023 (class 1247 OID 16934)
-- Name: notification_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.notification_status AS ENUM (
    'pending',
    'sent',
    'failed',
    'read'
);


ALTER TYPE public.notification_status OWNER TO postgres;

--
-- TOC entry 1020 (class 1247 OID 16921)
-- Name: notification_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.notification_type AS ENUM (
    'reservation_created',
    'payment_success',
    'reservation_cancelled',
    'refund_processed',
    'reminder',
    'support_message'
);


ALTER TYPE public.notification_type OWNER TO postgres;

--
-- TOC entry 1029 (class 1247 OID 16971)
-- Name: otp_purpose; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.otp_purpose AS ENUM (
    'register',
    'login',
    'password_reset',
    'payment_verification'
);


ALTER TYPE public.otp_purpose OWNER TO postgres;

--
-- TOC entry 1032 (class 1247 OID 16980)
-- Name: otp_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.otp_status AS ENUM (
    'sent',
    'verified',
    'expired',
    'failed'
);


ALTER TYPE public.otp_status OWNER TO postgres;

--
-- TOC entry 993 (class 1247 OID 16766)
-- Name: payment_method_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_method_type AS ENUM (
    'card',
    'wallet',
    'bank_gateway'
);


ALTER TYPE public.payment_method_type OWNER TO postgres;

--
-- TOC entry 990 (class 1247 OID 16756)
-- Name: payment_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_status AS ENUM (
    'pending',
    'successful',
    'failed',
    'refunded'
);


ALTER TYPE public.payment_status OWNER TO postgres;

--
-- TOC entry 999 (class 1247 OID 16797)
-- Name: refund_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.refund_status AS ENUM (
    'requested',
    'approved',
    'rejected',
    'completed'
);


ALTER TYPE public.refund_status OWNER TO postgres;

--
-- TOC entry 1014 (class 1247 OID 16878)
-- Name: report_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.report_status AS ENUM (
    'open',
    'in_progress',
    'resolved',
    'rejected'
);


ALTER TYPE public.report_status OWNER TO postgres;

--
-- TOC entry 1011 (class 1247 OID 16866)
-- Name: report_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.report_type AS ENUM (
    'ticket_issue',
    'payment_issue',
    'reservation_issue',
    'refund_issue',
    'other'
);


ALTER TYPE public.report_type OWNER TO postgres;

--
-- TOC entry 984 (class 1247 OID 16724)
-- Name: reservation_action_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.reservation_action_type AS ENUM (
    'created',
    'paid',
    'cancelled_by_user',
    'cancelled_by_support',
    'expired',
    'updated'
);


ALTER TYPE public.reservation_action_type OWNER TO postgres;

--
-- TOC entry 978 (class 1247 OID 16660)
-- Name: reservation_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.reservation_status AS ENUM (
    'reserved',
    'paid',
    'cancelled',
    'expired'
);


ALTER TYPE public.reservation_status OWNER TO postgres;

--
-- TOC entry 963 (class 1247 OID 16593)
-- Name: ticket_detail_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ticket_detail_type AS ENUM (
    'normal',
    'special',
    'vip'
);


ALTER TYPE public.ticket_detail_type OWNER TO postgres;

--
-- TOC entry 942 (class 1247 OID 16489)
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'spectator',
    'support'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- TOC entry 1005 (class 1247 OID 16828)
-- Name: wallet_transaction_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.wallet_transaction_type AS ENUM (
    'deposit',
    'payment',
    'refund',
    'adjustment'
);


ALTER TYPE public.wallet_transaction_type OWNER TO postgres;

--
-- TOC entry 309 (class 1255 OID 17012)
-- Name: fn_cancelled_tickets_by_sport(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_cancelled_tickets_by_sport(p_sport_name text) RETURNS TABLE(reservation_id integer, ticket_id integer, user_name text, sport_name text, home_team character varying, away_team character varying, reservation_time timestamp without time zone, cancelled_at timestamp without time zone, cancellation_reason character varying)
    LANGUAGE sql
    AS $$
    SELECT
        r.reservation_id,
        t.ticket_id,
        CONCAT(u.first_name, ' ', u.last_name),
        s.name,
        m.home_team,
        m.away_team,
        r.reservation_time,
        r.cancelled_at,
        r.cancellation_reason
    FROM reservations r
    JOIN users u ON u.user_id = r.user_id
    JOIN tickets t ON t.ticket_id = r.ticket_id
    JOIN matches m ON m.match_id = t.match_id
    JOIN sports s ON s.sport_id = m.sport_id
    WHERE r.status = 'cancelled'
      AND LOWER(s.name) = LOWER(p_sport_name)
    ORDER BY COALESCE(r.cancelled_at, r.reservation_time) DESC;
$$;


ALTER FUNCTION public.fn_cancelled_tickets_by_sport(p_sport_name text) OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 17007)
-- Name: fn_cancelled_users_by_support(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_cancelled_users_by_support(p_support_identifier text) RETURNS TABLE(user_id integer, full_name text, email character varying, phone character varying, cancelled_count bigint)
    LANGUAGE sql
    AS $$
    SELECT
        u.user_id,
        CONCAT(u.first_name, ' ', u.last_name),
        u.email,
        u.phone,
        COUNT(*) AS cancelled_count
    FROM users su
    JOIN reservation_actions ra ON ra.action_by_user_id = su.user_id
    JOIN reservations r ON r.reservation_id = ra.reservation_id
    JOIN users u ON u.user_id = r.user_id
    WHERE (su.email = p_support_identifier OR su.phone = p_support_identifier)
      AND su.role = 'support'
      AND ra.action_type = 'cancelled_by_support'
    GROUP BY u.user_id, u.first_name, u.last_name, u.email, u.phone
    ORDER BY cancelled_count DESC;
$$;


ALTER FUNCTION public.fn_cancelled_users_by_support(p_support_identifier text) OWNER TO postgres;

--
-- TOC entry 305 (class 1255 OID 17008)
-- Name: fn_purchased_tickets_by_city(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_purchased_tickets_by_city(p_city_name text) RETURNS TABLE(ticket_id integer, purchase_time timestamp without time zone, buyer_name text, sport_name text, home_team character varying, away_team character varying, venue_name character varying, city_name character varying, seat_category character varying, quantity integer, amount numeric)
    LANGUAGE sql
    AS $$
    SELECT
        t.ticket_id,
        p.payment_date,
        CONCAT(u.first_name, ' ', u.last_name),
        s.name,
        m.home_team,
        m.away_team,
        v.name,
        c.name,
        sc.name,
        r.quantity,
        p.amount
    FROM payments p
    JOIN reservations r ON r.reservation_id = p.reservation_id
    JOIN users u ON u.user_id = p.user_id
    JOIN tickets t ON t.ticket_id = r.ticket_id
    JOIN matches m ON m.match_id = t.match_id
    JOIN sports s ON s.sport_id = m.sport_id
    JOIN venues v ON v.venue_id = m.venue_id
    JOIN cities c ON c.city_id = v.city_id
    JOIN seat_categories sc ON sc.seat_category_id = t.seat_category_id
    WHERE p.status = 'successful'
      AND LOWER(c.name) = LOWER(p_city_name)
    ORDER BY p.payment_date DESC;
$$;


ALTER FUNCTION public.fn_purchased_tickets_by_city(p_city_name text) OWNER TO postgres;

--
-- TOC entry 306 (class 1255 OID 17009)
-- Name: fn_search_tickets(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_search_tickets(p_search_text text) RETURNS TABLE(ticket_id integer, spectator_name text, sport_name text, home_team character varying, away_team character varying, venue_name character varying, seat_category character varying, price numeric, capacity_remaining integer, facilities text)
    LANGUAGE sql
    AS $$
    SELECT DISTINCT
        t.ticket_id,
        CONCAT(u.first_name, ' ', u.last_name),
        s.name,
        m.home_team,
        m.away_team,
        v.name,
        sc.name,
        t.price,
        t.capacity_remaining,
        COALESCE(fd.facilities, vd.facilities, bd.facilities)
    FROM tickets t
    JOIN matches m ON m.match_id = t.match_id
    JOIN sports s ON s.sport_id = m.sport_id
    JOIN venues v ON v.venue_id = m.venue_id
    JOIN seat_categories sc ON sc.seat_category_id = t.seat_category_id
    LEFT JOIN football_details fd ON fd.football_detail_id = t.football_detail_id
    LEFT JOIN volleyball_details vd ON vd.volleyball_detail_id = t.volleyball_detail_id
    LEFT JOIN basketball_details bd ON bd.basketball_detail_id = t.basketball_detail_id
    LEFT JOIN reservations r ON r.ticket_id = t.ticket_id
    LEFT JOIN users u ON u.user_id = r.user_id
    WHERE LOWER(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) LIKE '%' || LOWER(p_search_text) || '%'
       OR LOWER(m.home_team) LIKE '%' || LOWER(p_search_text) || '%'
       OR LOWER(m.away_team) LIKE '%' || LOWER(p_search_text) || '%'
       OR LOWER(v.name) LIKE '%' || LOWER(p_search_text) || '%'
       OR LOWER(sc.name) LIKE '%' || LOWER(p_search_text) || '%'
    ORDER BY t.ticket_id;
$$;


ALTER FUNCTION public.fn_search_tickets(p_search_text text) OWNER TO postgres;

--
-- TOC entry 308 (class 1255 OID 17011)
-- Name: fn_top_buyers_since(timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_top_buyers_since(p_start_date timestamp without time zone, p_n integer) RETURNS TABLE(user_id integer, full_name text, email character varying, phone character varying, total_tickets bigint, total_amount numeric)
    LANGUAGE sql
    AS $$
    SELECT
        u.user_id,
        CONCAT(u.first_name, ' ', u.last_name),
        u.email,
        u.phone,
        SUM(r.quantity) AS total_tickets,
        SUM(p.amount) AS total_amount
    FROM users u
    JOIN reservations r ON r.user_id = u.user_id
    JOIN payments p ON p.reservation_id = r.reservation_id
    WHERE p.status = 'successful'
      AND p.payment_date >= p_start_date
    GROUP BY u.user_id, u.first_name, u.last_name, u.email, u.phone
    ORDER BY total_tickets DESC, total_amount DESC
    LIMIT p_n;
$$;


ALTER FUNCTION public.fn_top_buyers_since(p_start_date timestamp without time zone, p_n integer) OWNER TO postgres;

--
-- TOC entry 261 (class 1255 OID 17006)
-- Name: fn_user_purchased_tickets(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_user_purchased_tickets(p_identifier text) RETURNS TABLE(ticket_id integer, purchase_time timestamp without time zone, spectator_name text, sport_name text, home_team character varying, away_team character varying, venue_name character varying, seat_category character varying, price numeric, quantity integer, amount numeric)
    LANGUAGE sql
    AS $$
    SELECT
        t.ticket_id,
        p.payment_date,
        CONCAT(u.first_name, ' ', u.last_name),
        s.name,
        m.home_team,
        m.away_team,
        v.name,
        sc.name,
        t.price,
        r.quantity,
        p.amount
    FROM users u
    JOIN reservations r ON r.user_id = u.user_id
    JOIN payments p ON p.reservation_id = r.reservation_id
    JOIN tickets t ON t.ticket_id = r.ticket_id
    JOIN matches m ON m.match_id = t.match_id
    JOIN sports s ON s.sport_id = m.sport_id
    JOIN venues v ON v.venue_id = m.venue_id
    JOIN seat_categories sc ON sc.seat_category_id = t.seat_category_id
    WHERE (u.email = p_identifier OR u.phone = p_identifier)
      AND p.status = 'successful'
    ORDER BY p.payment_date DESC;
$$;


ALTER FUNCTION public.fn_user_purchased_tickets(p_identifier text) OWNER TO postgres;

--
-- TOC entry 260 (class 1255 OID 17013)
-- Name: fn_users_by_report_subject(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_users_by_report_subject(p_report_subject text) RETURNS TABLE(user_id integer, full_name text, email character varying, phone character varying, report_subject text, report_count bigint)
    LANGUAGE sql
    AS $$
    SELECT
        u.user_id,
        CONCAT(u.first_name, ' ', u.last_name),
        u.email,
        u.phone,
        r.report_type::TEXT,
        COUNT(*) AS report_count
    FROM reports r
    JOIN users u ON u.user_id = r.user_id
    WHERE LOWER(r.report_type::TEXT) LIKE '%' || LOWER(p_report_subject) || '%'
    GROUP BY u.user_id, u.first_name, u.last_name, u.email, u.phone, r.report_type
    ORDER BY report_count DESC;
$$;


ALTER FUNCTION public.fn_users_by_report_subject(p_report_subject text) OWNER TO postgres;

--
-- TOC entry 307 (class 1255 OID 17010)
-- Name: fn_users_same_city(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_users_same_city(p_identifier text) RETURNS TABLE(user_id integer, first_name character varying, last_name character varying, email character varying, phone character varying, city_name character varying, province character varying)
    LANGUAGE sql
    AS $$
    SELECT
        other_u.user_id,
        other_u.first_name,
        other_u.last_name,
        other_u.email,
        other_u.phone,
        c.name,
        c.province
    FROM users target_u
    JOIN users other_u ON other_u.city_id = target_u.city_id
    JOIN cities c ON c.city_id = other_u.city_id
    WHERE (target_u.email = p_identifier OR target_u.phone = p_identifier)
      AND other_u.user_id <> target_u.user_id
    ORDER BY other_u.last_name, other_u.first_name;
$$;


ALTER FUNCTION public.fn_users_same_city(p_identifier text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 241 (class 1259 OID 16616)
-- Name: basketball_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.basketball_details (
    basketball_detail_id integer NOT NULL,
    league_or_tournament character varying(100) NOT NULL,
    hall_name character varying(100) NOT NULL,
    section_number character varying(20),
    row_number character varying(20),
    seat_number character varying(20),
    ticket_category public.ticket_detail_type NOT NULL,
    facilities character varying(255)
);


ALTER TABLE public.basketball_details OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 16615)
-- Name: basketball_details_basketball_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.basketball_details ALTER COLUMN basketball_detail_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.basketball_details_basketball_detail_id_seq
    START WITH 14000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 235 (class 1259 OID 16570)
-- Name: cancellation_policies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cancellation_policies (
    policy_id integer NOT NULL,
    match_id integer,
    organizer_id integer,
    deadline_hours integer NOT NULL,
    penalty_percentage numeric(5,2) NOT NULL,
    description character varying(255),
    CONSTRAINT chk_cancellation_policy_owner CHECK ((((match_id IS NOT NULL) AND (organizer_id IS NULL)) OR ((match_id IS NULL) AND (organizer_id IS NOT NULL)))),
    CONSTRAINT chk_deadline_hours CHECK ((deadline_hours >= 0)),
    CONSTRAINT chk_penalty_percentage CHECK (((penalty_percentage >= (0)::numeric) AND (penalty_percentage <= (100)::numeric)))
);


ALTER TABLE public.cancellation_policies OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16569)
-- Name: cancellation_policies_policy_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cancellation_policies ALTER COLUMN policy_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.cancellation_policies_policy_id_seq
    START WITH 90000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 219 (class 1259 OID 16395)
-- Name: cities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cities (
    city_id integer NOT NULL,
    name character varying(50) NOT NULL,
    province character varying(50) NOT NULL
);


ALTER TABLE public.cities OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16394)
-- Name: cities_city_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cities ALTER COLUMN city_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.cities_city_id_seq
    START WITH 10000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 237 (class 1259 OID 16600)
-- Name: football_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.football_details (
    football_detail_id integer NOT NULL,
    league_or_tournament character varying(100) NOT NULL,
    stadium_name character varying(100) NOT NULL,
    section_number character varying(20),
    row_number character varying(20),
    seat_number character varying(20),
    ticket_type public.ticket_detail_type NOT NULL,
    facilities character varying(255)
);


ALTER TABLE public.football_details OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16599)
-- Name: football_details_football_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.football_details ALTER COLUMN football_detail_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.football_details_football_detail_id_seq
    START WITH 12000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 233 (class 1259 OID 16546)
-- Name: matches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.matches (
    match_id integer NOT NULL,
    sport_id integer NOT NULL,
    home_team character varying(100) NOT NULL,
    away_team character varying(100) NOT NULL,
    match_date date NOT NULL,
    match_time time without time zone NOT NULL,
    venue_id integer NOT NULL,
    organizer_id integer NOT NULL,
    status public.match_status DEFAULT 'scheduled'::public.match_status NOT NULL,
    CONSTRAINT chk_teams_not_same CHECK (((home_team)::text <> (away_team)::text))
);


ALTER TABLE public.matches OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16545)
-- Name: matches_match_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.matches ALTER COLUMN match_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.matches_match_id_seq
    START WITH 80000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 257 (class 1259 OID 16944)
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    notification_id integer NOT NULL,
    user_id integer NOT NULL,
    reservation_id integer,
    ticket_id integer,
    notification_type public.notification_type NOT NULL,
    title character varying(100),
    message character varying(500) NOT NULL,
    status public.notification_status DEFAULT 'pending'::public.notification_status NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    sent_at timestamp without time zone,
    read_at timestamp without time zone,
    CONSTRAINT chk_notification_read_time CHECK (((status <> 'read'::public.notification_status) OR (read_at IS NOT NULL))),
    CONSTRAINT chk_notification_sent_time CHECK (((status <> 'sent'::public.notification_status) OR (sent_at IS NOT NULL)))
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 16943)
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.notifications ALTER COLUMN notification_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.notifications_notification_id_seq
    START WITH 21000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 223 (class 1259 OID 16423)
-- Name: organizers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.organizers (
    organizer_id integer NOT NULL,
    name character varying(100) NOT NULL,
    contact_email character varying(100),
    contact_phone character varying(15),
    address character varying(255),
    CONSTRAINT chk_organizer_contact CHECK (((contact_email IS NOT NULL) OR (contact_phone IS NOT NULL)))
);


ALTER TABLE public.organizers OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16422)
-- Name: organizers_organizer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.organizers ALTER COLUMN organizer_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.organizers_organizer_id_seq
    START WITH 30000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 259 (class 1259 OID 16990)
-- Name: otp_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.otp_logs (
    otp_id integer NOT NULL,
    user_id integer,
    identifier character varying(100) NOT NULL,
    code_hash character varying(255),
    purpose public.otp_purpose NOT NULL,
    status public.otp_status DEFAULT 'sent'::public.otp_status NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    verified_at timestamp without time zone,
    attempt_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT chk_otp_attempt_count CHECK ((attempt_count >= 0)),
    CONSTRAINT chk_otp_expiry CHECK ((expires_at > created_at)),
    CONSTRAINT chk_otp_verified_time CHECK (((status <> 'verified'::public.otp_status) OR (verified_at IS NOT NULL)))
);


ALTER TABLE public.otp_logs OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 16989)
-- Name: otp_logs_otp_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.otp_logs ALTER COLUMN otp_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.otp_logs_otp_id_seq
    START WITH 22000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 249 (class 1259 OID 16774)
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    payment_id integer NOT NULL,
    reservation_id integer NOT NULL,
    user_id integer NOT NULL,
    amount numeric(12,2) NOT NULL,
    payment_method public.payment_method_type NOT NULL,
    status public.payment_status DEFAULT 'pending'::public.payment_status NOT NULL,
    transaction_id character varying(100),
    payment_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_payment_amount CHECK ((amount > (0)::numeric))
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 16773)
-- Name: payments_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.payments ALTER COLUMN payment_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.payments_payment_id_seq
    START WITH 17000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 251 (class 1259 OID 16806)
-- Name: refunds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.refunds (
    refund_id integer NOT NULL,
    payment_id integer NOT NULL,
    amount numeric(12,2) NOT NULL,
    refund_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reason character varying(255),
    status public.refund_status DEFAULT 'requested'::public.refund_status NOT NULL,
    approved_by_support_id integer,
    CONSTRAINT chk_refund_amount CHECK ((amount > (0)::numeric)),
    CONSTRAINT chk_refund_approval_user_required CHECK (((status <> ALL (ARRAY['approved'::public.refund_status, 'completed'::public.refund_status])) OR (approved_by_support_id IS NOT NULL)))
);


ALTER TABLE public.refunds OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 16805)
-- Name: refunds_refund_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.refunds ALTER COLUMN refund_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.refunds_refund_id_seq
    START WITH 18000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 255 (class 1259 OID 16888)
-- Name: reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reports (
    report_id integer NOT NULL,
    user_id integer NOT NULL,
    ticket_id integer,
    reservation_id integer,
    report_type public.report_type NOT NULL,
    description character varying(500) NOT NULL,
    status public.report_status DEFAULT 'open'::public.report_status NOT NULL,
    handled_by_support_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    resolved_at timestamp without time zone,
    CONSTRAINT chk_report_has_target CHECK (((ticket_id IS NOT NULL) OR (reservation_id IS NOT NULL))),
    CONSTRAINT chk_report_resolved_handler CHECK (((status <> ALL (ARRAY['resolved'::public.report_status, 'rejected'::public.report_status])) OR (handled_by_support_id IS NOT NULL)))
);


ALTER TABLE public.reports OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 16887)
-- Name: reports_report_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.reports ALTER COLUMN report_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.reports_report_id_seq
    START WITH 20000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 247 (class 1259 OID 16738)
-- Name: reservation_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservation_actions (
    action_id integer NOT NULL,
    reservation_id integer NOT NULL,
    action_type public.reservation_action_type NOT NULL,
    old_status public.reservation_status,
    new_status public.reservation_status NOT NULL,
    action_by_user_id integer,
    action_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    note character varying(255),
    CONSTRAINT chk_reservation_action_status_change CHECK (((old_status IS NULL) OR (old_status <> new_status)))
);


ALTER TABLE public.reservation_actions OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 16737)
-- Name: reservation_actions_action_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.reservation_actions ALTER COLUMN action_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.reservation_actions_action_id_seq
    START WITH 16000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 245 (class 1259 OID 16670)
-- Name: reservations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservations (
    reservation_id integer NOT NULL,
    user_id integer NOT NULL,
    ticket_id integer NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    reservation_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expiry_time timestamp without time zone DEFAULT (CURRENT_TIMESTAMP + '00:15:00'::interval) NOT NULL,
    status public.reservation_status DEFAULT 'reserved'::public.reservation_status NOT NULL,
    cancelled_at timestamp without time zone,
    cancellation_reason character varying(255),
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_reservation_expiry CHECK ((expiry_time > reservation_time)),
    CONSTRAINT chk_reservation_quantity CHECK ((quantity > 0))
);


ALTER TABLE public.reservations OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 16669)
-- Name: reservations_reservation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.reservations ALTER COLUMN reservation_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.reservations_reservation_id_seq
    START WITH 15000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 225 (class 1259 OID 16434)
-- Name: seat_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.seat_categories (
    seat_category_id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(255),
    price_multiplier numeric(4,2) DEFAULT 1.00 NOT NULL,
    CONSTRAINT chk_price_multiplier CHECK ((price_multiplier > (0)::numeric))
);


ALTER TABLE public.seat_categories OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16433)
-- Name: seat_categories_seat_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.seat_categories ALTER COLUMN seat_category_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.seat_categories_seat_category_id_seq
    START WITH 40000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 221 (class 1259 OID 16404)
-- Name: sports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sports (
    sport_id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.sports OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16403)
-- Name: sports_sport_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.sports ALTER COLUMN sport_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.sports_sport_id_seq
    START WITH 20000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 243 (class 1259 OID 16624)
-- Name: tickets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tickets (
    ticket_id integer NOT NULL,
    match_id integer NOT NULL,
    seat_category_id integer NOT NULL,
    football_detail_id integer,
    volleyball_detail_id integer,
    basketball_detail_id integer,
    price numeric(12,2) NOT NULL,
    capacity_remaining integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_only_one_sport_detail CHECK ((num_nonnulls(football_detail_id, volleyball_detail_id, basketball_detail_id) <= 1)),
    CONSTRAINT chk_ticket_capacity_remaining CHECK ((capacity_remaining >= 0)),
    CONSTRAINT chk_ticket_price CHECK ((price >= (0)::numeric))
);


ALTER TABLE public.tickets OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 16623)
-- Name: tickets_ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tickets ALTER COLUMN ticket_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tickets_ticket_id_seq
    START WITH 11000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 229 (class 1259 OID 16500)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    email character varying(100),
    phone character varying(15),
    password_hash character varying(255) NOT NULL,
    role public.user_role DEFAULT 'spectator'::public.user_role NOT NULL,
    city_id integer NOT NULL,
    birth_date date,
    profile_picture character varying(255),
    registration_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_login timestamp without time zone,
    status public.account_status DEFAULT 'active'::public.account_status NOT NULL,
    CONSTRAINT chk_user_contact CHECK (((email IS NOT NULL) OR (phone IS NOT NULL)))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16499)
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.users ALTER COLUMN user_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.users_user_id_seq
    START WITH 60000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 227 (class 1259 OID 16444)
-- Name: venues; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.venues (
    venue_id integer NOT NULL,
    name character varying(100) NOT NULL,
    city_id integer NOT NULL,
    address character varying(255),
    capacity integer NOT NULL,
    contact_info character varying(100),
    CONSTRAINT chk_venue_capacity CHECK ((capacity > 0))
);


ALTER TABLE public.venues OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16443)
-- Name: venues_venue_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.venues ALTER COLUMN venue_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.venues_venue_id_seq
    START WITH 50000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 239 (class 1259 OID 16608)
-- Name: volleyball_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.volleyball_details (
    volleyball_detail_id integer NOT NULL,
    league_or_tournament character varying(100) NOT NULL,
    hall_name character varying(100) NOT NULL,
    section_number character varying(20),
    row_number character varying(20),
    seat_number character varying(20),
    ticket_category public.ticket_detail_type NOT NULL,
    facilities character varying(255)
);


ALTER TABLE public.volleyball_details OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 16607)
-- Name: volleyball_details_volleyball_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.volleyball_details ALTER COLUMN volleyball_detail_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.volleyball_details_volleyball_detail_id_seq
    START WITH 13000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 253 (class 1259 OID 16838)
-- Name: wallet_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wallet_transactions (
    wallet_transaction_id integer NOT NULL,
    wallet_id integer NOT NULL,
    payment_id integer,
    refund_id integer,
    transaction_type public.wallet_transaction_type NOT NULL,
    amount numeric(12,2) NOT NULL,
    transaction_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    description character varying(255),
    CONSTRAINT chk_wallet_transaction_amount CHECK ((amount > (0)::numeric)),
    CONSTRAINT chk_wallet_transaction_reference CHECK ((((transaction_type = 'payment'::public.wallet_transaction_type) AND (payment_id IS NOT NULL) AND (refund_id IS NULL)) OR ((transaction_type = 'refund'::public.wallet_transaction_type) AND (refund_id IS NOT NULL) AND (payment_id IS NULL)) OR ((transaction_type = ANY (ARRAY['deposit'::public.wallet_transaction_type, 'adjustment'::public.wallet_transaction_type])) AND (payment_id IS NULL) AND (refund_id IS NULL))))
);


ALTER TABLE public.wallet_transactions OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 16837)
-- Name: wallet_transactions_wallet_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.wallet_transactions ALTER COLUMN wallet_transaction_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.wallet_transactions_wallet_transaction_id_seq
    START WITH 19000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 231 (class 1259 OID 16521)
-- Name: wallets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wallets (
    wallet_id integer NOT NULL,
    user_id integer NOT NULL,
    balance numeric(12,2) DEFAULT 0.00 NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_wallet_balance CHECK ((balance >= (0)::numeric))
);


ALTER TABLE public.wallets OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16520)
-- Name: wallets_wallet_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.wallets ALTER COLUMN wallet_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.wallets_wallet_id_seq
    START WITH 70000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 4124 (class 0 OID 16616)
-- Dependencies: 241
-- Data for Name: basketball_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.basketball_details (basketball_detail_id, league_or_tournament, hall_name, section_number, row_number, seat_number, ticket_category, facilities) FROM stdin;
14000000	Iran Basketball Super League	Enghelab Sport Complex	B1	1	1	vip	VIP lounge, snack
14000001	Iran Basketball Super League	Enghelab Sport Complex	B1	1	2	special	Close court view
14000002	Friendly Basketball Match	Karaj Sports Hall	B7	1	7	vip	VIP service
14000003	Basketball Cup	Qom Arena	B3	3	12	vip	VIP entrance
14000004	Friendly Basketball Match	Karaj Sports Hall	B8	6	28	normal	Standard seat
14000005	National Basketball League	Hafezieh Stadium	B6	5	21	normal	Standard seat
14000006	National Basketball League	Hafezieh Stadium	B5	2	9	special	Better view
14000007	Basketball Cup	Qom Arena	B4	4	18	normal	Standard seat
14000008	National Basketball League	Enghelab Sport Complex	B9	7	35	special	Family access
14000009	Iran Basketball Super League	Enghelab Sport Complex	B2	2	10	normal	Standard seat
\.


--
-- TOC entry 4118 (class 0 OID 16570)
-- Dependencies: 235
-- Data for Name: cancellation_policies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cancellation_policies (policy_id, match_id, organizer_id, deadline_hours, penalty_percentage, description) FROM stdin;
90000010	80000010	\N	24	10.00	Cancellation allowed up to 24 hours before match with 10 percent penalty
90000011	80000011	\N	48	5.00	Cancellation allowed up to 48 hours before match with 5 percent penalty
90000012	80000012	\N	12	20.00	Cancellation allowed up to 12 hours before match with 20 percent penalty
90000013	80000013	\N	24	15.00	Cancellation allowed up to 24 hours before match with 15 percent penalty
90000014	80000014	\N	6	25.00	Volleyball ticket cancellation allowed up to 6 hours before match
90000015	80000015	\N	8	20.00	Volleyball ticket cancellation allowed up to 8 hours before match
90000016	80000016	\N	10	18.00	Volleyball ticket cancellation allowed up to 10 hours before match
90000017	80000017	\N	24	12.00	Basketball ticket cancellation allowed up to 24 hours before match
90000018	80000018	\N	12	22.00	Basketball ticket cancellation allowed up to 12 hours before match
90000019	80000019	\N	18	17.00	Basketball ticket cancellation allowed up to 18 hours before match
\.


--
-- TOC entry 4102 (class 0 OID 16395)
-- Dependencies: 219
-- Data for Name: cities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cities (city_id, name, province) FROM stdin;
10000000	Tehran	Tehran
10000001	Mashhad	Khorasan Razavi
10000002	Isfahan	Isfahan
10000003	Shiraz	Fars
10000004	Tabriz	East Azerbaijan
10000005	Karaj	Alborz
10000006	Qom	Qom
10000007	Ahvaz	Khuzestan
10000008	Rasht	Gilan
10000009	Kerman	Kerman
\.


--
-- TOC entry 4120 (class 0 OID 16600)
-- Dependencies: 237
-- Data for Name: football_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.football_details (football_detail_id, league_or_tournament, stadium_name, section_number, row_number, seat_number, ticket_type, facilities) FROM stdin;
12000000	Friendly Match	Hafezieh Stadium	D2	6	25	normal	Standard seat
12000001	National League	Azadi Stadium	F1	9	40	special	Family access
12000002	Persian Gulf Pro League	Azadi Stadium	A1	1	2	special	Better view, snack
12000003	Persian Gulf Pro League	Azadi Stadium	A1	1	1	vip	VIP lounge, parking, snack
12000004	Persian Gulf Pro League	Azadi Stadium	B2	3	10	normal	Standard seat
12000005	National League	Yadegar-e Emam Stadium	E2	7	30	normal	Standard seat
12000006	National League	Yadegar-e Emam Stadium	E1	2	8	vip	VIP service
12000007	Friendly Match	Hafezieh Stadium	D1	5	20	special	Close view
12000008	Hazfi Cup	Naghsh-e Jahan Stadium	C1	2	5	vip	VIP entrance, parking
12000009	Hazfi Cup	Naghsh-e Jahan Stadium	C2	4	15	normal	Standard seat
\.


--
-- TOC entry 4116 (class 0 OID 16546)
-- Dependencies: 233
-- Data for Name: matches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.matches (match_id, sport_id, home_team, away_team, match_date, match_time, venue_id, organizer_id, status) FROM stdin;
80000010	20000000	Esteghlal	Persepolis	2026-08-10	20:00:00	50000000	30000000	scheduled
80000011	20000000	Sepahan	Tractor	2026-08-12	18:30:00	50000003	30000000	scheduled
80000012	20000000	Shiraz FC	Ahvaz FC	2026-08-14	19:00:00	50000004	30000006	scheduled
80000013	20000000	Tabriz Stars	Karaj United	2026-08-16	17:30:00	50000005	30000007	scheduled
80000014	20000001	Tehran VC	Mashhad VC	2026-08-18	16:00:00	50000001	30000001	scheduled
80000015	20000001	Karaj Spikers	Qom Setters	2026-08-20	15:30:00	50000006	30000008	scheduled
80000016	20000001	Rasht Waves	Tabriz Netters	2026-08-22	17:00:00	50000009	30000009	scheduled
80000017	20000002	Tehran Hoopers	Isfahan Giants	2026-08-24	19:30:00	50000001	30000002	scheduled
80000018	20000002	Qom Stars	Ahvaz Dunkers	2026-08-26	18:00:00	50000007	30000002	scheduled
80000019	20000002	Shiraz Kings	Karaj Ballers	2026-08-28	20:30:00	50000004	30000002	scheduled
\.


--
-- TOC entry 4140 (class 0 OID 16944)
-- Dependencies: 257
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (notification_id, user_id, reservation_id, ticket_id, notification_type, title, message, status, created_at, sent_at, read_at) FROM stdin;
21000000	60000003	15000003	11000003	payment_success	Notification 4	This is a sample notification message for reservation 15000003	sent	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026	\N
21000001	60000002	15000002	11000002	reservation_created	Notification 3	This is a sample notification message for reservation 15000002	sent	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026	\N
21000002	60000006	15000006	11000006	reservation_cancelled	Notification 7	This is a sample notification message for reservation 15000006	read	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026
21000003	60000007	15000007	11000007	refund_processed	Notification 8	This is a sample notification message for reservation 15000007	pending	2026-07-07 16:27:25.894026	\N	\N
21000004	60000000	15000000	11000000	reservation_created	Notification 1	This is a sample notification message for reservation 15000000	sent	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026	\N
21000005	60000008	15000008	11000008	reminder	Notification 9	This is a sample notification message for reservation 15000008	pending	2026-07-07 16:27:25.894026	\N	\N
21000006	60000001	15000001	11000001	reservation_created	Notification 2	This is a sample notification message for reservation 15000001	sent	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026	\N
21000007	60000009	15000009	11000009	support_message	Notification 10	This is a sample notification message for reservation 15000009	pending	2026-07-07 16:27:25.894026	\N	\N
21000009	60000004	15000004	11000004	payment_success	Notification 5	This is a sample notification message for reservation 15000004	read	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026
21000010	60000005	15000010	11000000	reservation_cancelled	Restored Cancellation Notification	This notification was restored after query testing.	sent	2026-07-07 18:22:37.671203	2026-07-07 18:22:37.671203	\N
\.


--
-- TOC entry 4106 (class 0 OID 16423)
-- Dependencies: 223
-- Data for Name: organizers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.organizers (organizer_id, name, contact_email, contact_phone, address) FROM stdin;
30000000	Iran Football Federation	football@organizer.com	09120000001	\N
30000001	Iran Volleyball Federation	volleyball@organizer.com	09120000002	\N
30000002	Iran Basketball Federation	basketball@organizer.com	09120000003	\N
30000003	Tehran Sports Organization	tehran.sport@organizer.com	09120000004	\N
30000004	Mashhad Sports Club	mashhad.club@organizer.com	09120000005	\N
30000005	Isfahan Event Group	isfahan.event@organizer.com	09120000006	\N
30000006	Shiraz Sport Events	shiraz.event@organizer.com	09120000007	\N
30000007	Tabriz Arena Management	tabriz.arena@organizer.com	09120000008	\N
30000008	Karaj Sports Center	karaj.center@organizer.com	09120000009	\N
30000009	National Sports Events	national.events@organizer.com	09120000010	\N
\.


--
-- TOC entry 4142 (class 0 OID 16990)
-- Dependencies: 259
-- Data for Name: otp_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.otp_logs (otp_id, user_id, identifier, code_hash, purpose, status, created_at, expires_at, verified_at, attempt_count) FROM stdin;
22000000	60000003	neda.hosseini@example.com	hashed_otp_code_4	login	sent	2026-07-07 16:27:25.894026	2026-07-07 16:32:25.894026	\N	0
22000001	60000004	amir.rahimi@example.com	hashed_otp_code_5	login	verified	2026-07-07 16:27:25.894026	2026-07-07 16:32:25.894026	2026-07-07 16:27:25.894026	1
22000002	60000002	reza.karimi@example.com	hashed_otp_code_3	register	sent	2026-07-07 16:27:25.894026	2026-07-07 16:32:25.894026	\N	0
22000003	60000001	sara.mohammadi@example.com	hashed_otp_code_2	register	sent	2026-07-07 16:27:25.894026	2026-07-07 16:32:25.894026	\N	0
22000004	60000005	mina.ebrahimi@example.com	hashed_otp_code_6	login	verified	2026-07-07 16:27:25.894026	2026-07-07 16:32:25.894026	2026-07-07 16:27:25.894026	1
22000005	60000008	support1@example.com	hashed_otp_code_9	payment_verification	expired	2026-07-07 16:27:25.894026	2026-07-07 16:32:25.894026	\N	3
22000006	60000000	ali.ahmadi@example.com	hashed_otp_code_1	register	sent	2026-07-07 16:27:25.894026	2026-07-07 16:32:25.894026	\N	0
22000007	60000006	pouya.moradi@example.com	hashed_otp_code_7	password_reset	verified	2026-07-07 16:27:25.894026	2026-07-07 16:32:25.894026	2026-07-07 16:27:25.894026	1
22000008	60000007	elham.jafari@example.com	hashed_otp_code_8	password_reset	expired	2026-07-07 16:27:25.894026	2026-07-07 16:32:25.894026	\N	3
22000009	60000009	support2@example.com	hashed_otp_code_10	payment_verification	failed	2026-07-07 16:27:25.894026	2026-07-07 16:32:25.894026	\N	3
\.


--
-- TOC entry 4132 (class 0 OID 16774)
-- Dependencies: 249
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (payment_id, reservation_id, user_id, amount, payment_method, status, transaction_id, payment_date) FROM stdin;
17000000	15000008	60000008	900000.00	bank_gateway	successful	TXN-15000008	2026-07-07 16:27:25.894026
17000002	15000006	60000006	1000000.00	card	refunded	TXN-15000006	2026-07-07 16:27:25.894026
17000003	15000007	60000007	1800000.00	wallet	successful	TXN-15000007	2026-07-07 16:27:25.894026
17000004	15000003	60000003	2100000.00	card	successful	TXN-15000003	2026-07-07 16:27:25.894026
17000005	15000002	60000002	3600000.00	bank_gateway	successful	TXN-15000002	2026-07-07 16:27:25.894026
17000006	15000001	60000001	800000.00	wallet	successful	TXN-15000001	2026-07-07 16:27:25.894026
17000007	15000009	60000009	1300000.00	card	successful	TXN-15000009	2026-07-07 16:27:25.894026
17000008	15000004	60000004	1400000.00	wallet	successful	TXN-15000004	2026-07-07 16:27:25.894026
17000009	15000000	60000000	5000000.00	card	successful	TXN-15000000	2026-07-07 16:27:25.894026
17000010	15000010	60000005	2500000.00	card	refunded	TXN-RESTORE-CANCELLED-001	2026-07-07 17:32:37.671203
\.


--
-- TOC entry 4134 (class 0 OID 16806)
-- Dependencies: 251
-- Data for Name: refunds; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refunds (refund_id, payment_id, amount, refund_date, reason, status, approved_by_support_id) FROM stdin;
18000000	17000000	720000.00	2026-07-07 16:27:25.894026	User requested refund	requested	\N
18000002	17000002	800000.00	2026-07-07 16:27:25.894026	User requested refund	requested	\N
18000003	17000003	1440000.00	2026-07-07 16:27:25.894026	Match schedule changed	approved	60000008
18000004	17000004	1680000.00	2026-07-07 16:27:25.894026	Match schedule changed	approved	60000008
18000005	17000005	2880000.00	2026-07-07 16:27:25.894026	Match schedule changed	approved	60000008
18000006	17000006	640000.00	2026-07-07 16:27:25.894026	Reservation cancelled	completed	60000008
18000007	17000007	1040000.00	2026-07-07 16:27:25.894026	Reservation cancelled	completed	60000008
18000008	17000008	1120000.00	2026-07-07 16:27:25.894026	Payment issue	rejected	\N
18000009	17000009	4000000.00	2026-07-07 16:27:25.894026	Payment issue	rejected	\N
18000010	17000010	2500000.00	2026-07-07 18:02:37.671203	Refund for restored cancelled reservation	completed	60000008
\.


--
-- TOC entry 4138 (class 0 OID 16888)
-- Dependencies: 255
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reports (report_id, user_id, ticket_id, reservation_id, report_type, description, status, handled_by_support_id, created_at, resolved_at) FROM stdin;
20000000	60000003	11000003	15000003	payment_issue	Sample report number 4	in_progress	\N	2026-07-07 16:27:25.894026	\N
20000001	60000009	11000009	15000009	other	Sample report number 10	rejected	60000008	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026
20000002	60000007	11000007	15000007	refund_issue	Sample report number 8	resolved	60000008	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026
20000003	60000006	11000006	15000006	refund_issue	Sample report number 7	resolved	60000008	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026
20000005	60000000	11000000	15000000	ticket_issue	Sample report number 1	open	\N	2026-07-07 16:27:25.894026	\N
20000006	60000002	11000002	15000002	payment_issue	Sample report number 3	open	\N	2026-07-07 16:27:25.894026	\N
20000007	60000001	11000001	15000001	ticket_issue	Sample report number 2	open	\N	2026-07-07 16:27:25.894026	\N
20000008	60000008	11000008	15000008	other	Sample report number 9	rejected	60000008	2026-07-07 16:27:25.894026	2026-07-07 16:27:25.894026
20000009	60000004	11000004	15000004	reservation_issue	Sample report number 5	in_progress	\N	2026-07-07 16:27:25.894026	\N
20000010	60000005	11000000	15000010	refund_issue	Restored sample report after query testing	open	\N	2026-07-07 18:22:37.671203	\N
\.


--
-- TOC entry 4130 (class 0 OID 16738)
-- Dependencies: 247
-- Data for Name: reservation_actions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reservation_actions (action_id, reservation_id, action_type, old_status, new_status, action_by_user_id, action_time, note) FROM stdin;
16000000	15000000	created	\N	reserved	60000000	2026-07-07 16:27:25.894026	Reservation was created
16000001	15000001	created	\N	reserved	60000001	2026-07-07 16:27:25.894026	Reservation was created
16000002	15000002	created	\N	reserved	60000002	2026-07-07 16:27:25.894026	Reservation was created
16000003	15000003	created	\N	reserved	60000003	2026-07-07 16:27:25.894026	Reservation was created
16000004	15000004	created	\N	reserved	60000004	2026-07-07 16:27:25.894026	Reservation was created
16000006	15000006	created	\N	reserved	60000006	2026-07-07 16:27:25.894026	Reservation was created
16000007	15000007	created	\N	reserved	60000007	2026-07-07 16:27:25.894026	Reservation was created
16000008	15000008	created	\N	reserved	60000008	2026-07-07 16:27:25.894026	Reservation was created
16000009	15000009	created	\N	reserved	60000009	2026-07-07 16:27:25.894026	Reservation was created
16000010	15000010	cancelled_by_user	reserved	cancelled	60000005	2026-07-07 17:52:37.671203	Restored sample reservation cancelled by user
16000011	15000010	created	\N	reserved	60000005	2026-07-07 17:22:37.671203	Restored sample reservation created
\.


--
-- TOC entry 4128 (class 0 OID 16670)
-- Dependencies: 245
-- Data for Name: reservations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reservations (reservation_id, user_id, ticket_id, quantity, reservation_time, expiry_time, status, cancelled_at, cancellation_reason, updated_at) FROM stdin;
15000000	60000000	11000000	2	2026-07-01 10:00:00	2026-07-01 10:15:00	paid	\N	\N	2026-07-07 16:27:25.894026
15000001	60000001	11000001	1	2026-07-01 10:10:00	2026-07-01 10:25:00	paid	\N	\N	2026-07-07 16:27:25.894026
15000002	60000002	11000002	3	2026-07-01 10:20:00	2026-07-01 10:35:00	paid	\N	\N	2026-07-07 16:27:25.894026
15000003	60000003	11000003	1	2026-07-01 10:30:00	2026-07-01 10:45:00	reserved	\N	\N	2026-07-07 16:27:25.894026
15000004	60000004	11000004	2	2026-07-01 10:40:00	2026-07-01 10:55:00	paid	\N	\N	2026-07-07 16:27:25.894026
15000006	60000006	11000006	2	2026-07-01 11:00:00	2026-07-01 11:15:00	expired	\N	Reservation expired	2026-07-07 16:27:25.894026
15000007	60000007	11000007	1	2026-07-01 11:10:00	2026-07-01 11:25:00	paid	\N	\N	2026-07-07 16:27:25.894026
15000008	60000008	11000008	1	2026-07-01 11:20:00	2026-07-01 11:35:00	reserved	\N	\N	2026-07-07 16:27:25.894026
15000009	60000009	11000009	2	2026-07-01 11:30:00	2026-07-01 11:45:00	paid	\N	\N	2026-07-07 16:27:25.894026
15000010	60000005	11000000	1	2026-07-07 17:22:37.671203	2026-07-07 17:37:37.671203	cancelled	2026-07-07 17:52:37.671203	Restored cancelled sample after query testing	2026-07-07 18:22:37.671203
\.


--
-- TOC entry 4108 (class 0 OID 16434)
-- Dependencies: 225
-- Data for Name: seat_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.seat_categories (seat_category_id, name, description, price_multiplier) FROM stdin;
40000000	Economy	Basic seats with standard view	1.00
40000001	Standard	Regular seats with good view	1.20
40000002	Premium	Better seats with closer view	1.50
40000003	VIP	VIP seats with best view and extra services	2.50
40000004	Family	Family-friendly seating area	1.10
40000005	Student	Discounted student seating area	0.80
40000006	Front Row	Seats closest to the field or court	2.00
40000007	Balcony	Upper-level seating area	0.90
40000008	Accessible	Seats designed for accessibility needs	1.00
40000009	Sponsor	Reserved seats for sponsors and partners	3.00
\.


--
-- TOC entry 4104 (class 0 OID 16404)
-- Dependencies: 221
-- Data for Name: sports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sports (sport_id, name) FROM stdin;
20000000	Football
20000001	Volleyball
20000002	Basketball
20000003	Tennis
20000004	Swimming
20000005	Wrestling
20000006	Futsal
20000007	Handball
20000008	Boxing
20000009	Athletics
\.


--
-- TOC entry 4126 (class 0 OID 16624)
-- Dependencies: 243
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tickets (ticket_id, match_id, seat_category_id, football_detail_id, volleyball_detail_id, basketball_detail_id, price, capacity_remaining, is_active, created_at) FROM stdin;
11000000	80000010	40000003	12000003	\N	\N	2500000.00	50	t	2026-07-07 16:22:21.860479
11000001	80000011	40000001	12000009	\N	\N	800000.00	300	t	2026-07-07 16:22:21.860479
11000002	80000012	40000002	12000007	\N	\N	1200000.00	120	t	2026-07-07 16:22:21.860479
11000003	80000013	40000003	12000006	\N	\N	2100000.00	35	t	2026-07-07 16:22:21.860479
11000004	80000010	40000000	12000004	\N	\N	700000.00	500	t	2026-07-07 16:22:21.860479
11000005	80000011	40000003	12000008	\N	\N	2200000.00	40	t	2026-07-07 16:22:21.860479
11000006	80000012	40000000	12000000	\N	\N	500000.00	400	t	2026-07-07 16:22:21.860479
11000007	80000010	40000002	12000002	\N	\N	1800000.00	80	t	2026-07-07 16:22:21.860479
11000008	80000010	40000004	12000001	\N	\N	900000.00	150	t	2026-07-07 16:22:21.860479
11000009	80000013	40000001	12000005	\N	\N	650000.00	350	t	2026-07-07 16:22:21.860479
11000010	80000016	40000000	\N	13000006	\N	220000.00	250	t	2026-07-07 16:22:21.860479
11000011	80000015	40000001	\N	13000004	\N	300000.00	200	t	2026-07-07 16:22:21.860479
11000012	80000014	40000004	\N	13000007	\N	350000.00	150	t	2026-07-07 16:22:21.860479
11000013	80000014	40000003	\N	13000001	\N	900000.00	30	t	2026-07-07 16:22:21.860479
11000014	80000016	40000002	\N	13000009	\N	500000.00	100	t	2026-07-07 16:22:21.860479
11000015	80000015	40000003	\N	13000002	\N	780000.00	20	t	2026-07-07 16:22:21.860479
11000016	80000014	40000002	\N	13000003	\N	650000.00	70	t	2026-07-07 16:22:21.860479
11000017	80000015	40000003	\N	13000000	\N	850000.00	25	t	2026-07-07 16:22:21.860479
11000018	80000015	40000001	\N	13000005	\N	240000.00	180	t	2026-07-07 16:22:21.860479
11000019	80000014	40000000	\N	13000008	\N	250000.00	300	t	2026-07-07 16:22:21.860479
11000020	80000018	40000003	\N	\N	14000003	950000.00	30	t	2026-07-07 16:22:21.860479
11000021	80000017	40000000	\N	\N	14000009	300000.00	250	t	2026-07-07 16:22:21.860479
11000022	80000019	40000002	\N	\N	14000006	600000.00	90	t	2026-07-07 16:22:21.860479
11000023	80000017	40000004	\N	\N	14000008	420000.00	140	t	2026-07-07 16:22:21.860479
11000024	80000017	40000002	\N	\N	14000001	700000.00	80	t	2026-07-07 16:22:21.860479
11000025	80000019	40000000	\N	\N	14000005	280000.00	220	t	2026-07-07 16:22:21.860479
11000026	80000017	40000003	\N	\N	14000000	1000000.00	35	t	2026-07-07 16:22:21.860479
11000027	80000018	40000001	\N	\N	14000007	350000.00	180	t	2026-07-07 16:22:21.860479
11000028	80000019	40000003	\N	\N	14000002	900000.00	25	t	2026-07-07 16:22:21.860479
11000029	80000019	40000001	\N	\N	14000004	320000.00	160	t	2026-07-07 16:22:21.860479
\.


--
-- TOC entry 4112 (class 0 OID 16500)
-- Dependencies: 229
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, first_name, last_name, email, phone, password_hash, role, city_id, birth_date, profile_picture, registration_date, last_login, status) FROM stdin;
60000000	Ali	Ahmadi	ali.ahmadi@example.com	09121111111	hashed_password_1	spectator	10000000	1998-04-12	\N	2026-07-06 19:51:21.659116	\N	active
60000001	Sara	Mohammadi	sara.mohammadi@example.com	09122222222	hashed_password_2	spectator	10000001	2000-07-22	\N	2026-07-06 19:51:21.659116	\N	active
60000002	Reza	Karimi	reza.karimi@example.com	09123333333	hashed_password_3	spectator	10000002	1996-02-10	\N	2026-07-06 19:51:21.659116	\N	active
60000003	Neda	Hosseini	neda.hosseini@example.com	09124444444	hashed_password_4	spectator	10000003	2001-11-05	\N	2026-07-06 19:51:21.659116	\N	active
60000004	Amir	Rahimi	amir.rahimi@example.com	09125555555	hashed_password_5	spectator	10000004	1999-09-18	\N	2026-07-06 19:51:21.659116	\N	active
60000006	Pouya	Moradi	pouya.moradi@example.com	09127777777	hashed_password_7	spectator	10000006	1997-06-14	\N	2026-07-06 19:51:21.659116	\N	active
60000007	Elham	Jafari	elham.jafari@example.com	09128888888	hashed_password_8	spectator	10000007	1995-12-03	\N	2026-07-06 19:51:21.659116	\N	active
60000008	Support	UserOne	support1@example.com	09129999991	hashed_password_9	support	10000000	1994-03-20	\N	2026-07-06 19:51:21.659116	\N	active
60000009	Support	UserTwo	support2@example.com	09129999992	hashed_password_10	support	10000002	1993-08-09	\N	2026-07-06 19:51:21.659116	\N	active
60000005	Mina	Ebrahimi	mina.ebrahimi@example.com	09126666666	hashed_password_6	spectator	10000005	2002-01-30	\N	2026-07-06 19:51:21.659116	\N	active
\.


--
-- TOC entry 4110 (class 0 OID 16444)
-- Dependencies: 227
-- Data for Name: venues; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venues (venue_id, name, city_id, address, capacity, contact_info) FROM stdin;
50000000	Azadi Stadium	10000000	West Tehran, Azadi Sport Complex	78000	02144000001
50000001	Enghelab Sport Complex	10000000	Vanak, Tehran	12000	02144000002
50000002	Imam Reza Stadium	10000001	Imam Reza Blvd, Mashhad	27000	05138000001
50000003	Naghsh-e Jahan Stadium	10000002	Sepahan Shahr, Isfahan	75000	03136000001
50000004	Hafezieh Stadium	10000003	Hafezieh Area, Shiraz	20000	07132000001
50000005	Yadegar-e Emam Stadium	10000004	East Tabriz	66000	04134000001
50000006	Karaj Sports Hall	10000005	Azimieh, Karaj	8000	02634000001
50000007	Qom Arena	10000006	Central Qom	7000	02532000001
50000008	Takhti Stadium Ahvaz	10000007	Takhti Street, Ahvaz	30000	06133000001
50000009	Rasht Sports Hall	10000008	Golsar, Rasht	6000	01333000001
\.


--
-- TOC entry 4122 (class 0 OID 16608)
-- Dependencies: 239
-- Data for Name: volleyball_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.volleyball_details (volleyball_detail_id, league_or_tournament, hall_name, section_number, row_number, seat_number, ticket_category, facilities) FROM stdin;
13000000	Volleyball Cup	Karaj Sports Hall	V3	3	12	vip	VIP entrance
13000001	Iran Volleyball Super League	Enghelab Sport Complex	V1	1	1	vip	VIP lounge, snack
13000002	Friendly Volleyball Match	Qom Arena	V7	1	7	vip	VIP service
13000003	Iran Volleyball Super League	Enghelab Sport Complex	V1	1	2	special	Close court view
13000004	Volleyball Cup	Karaj Sports Hall	V4	4	18	normal	Standard seat
13000005	Friendly Volleyball Match	Qom Arena	V8	6	28	normal	Standard seat
13000006	National Volleyball League	Rasht Sports Hall	V6	5	21	normal	Standard seat
13000007	National Volleyball League	Karaj Sports Hall	V9	7	35	special	Family access
13000008	Iran Volleyball Super League	Enghelab Sport Complex	V2	2	10	normal	Standard seat
13000009	National Volleyball League	Rasht Sports Hall	V5	2	9	special	Better view
\.


--
-- TOC entry 4136 (class 0 OID 16838)
-- Dependencies: 253
-- Data for Name: wallet_transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wallet_transactions (wallet_transaction_id, wallet_id, payment_id, refund_id, transaction_type, amount, transaction_date, description) FROM stdin;
19000000	70000000	\N	\N	deposit	1050000.00	2026-07-07 16:27:25.894026	Initial wallet deposit
19000001	70000001	\N	\N	deposit	1100000.00	2026-07-07 16:27:25.894026	Initial wallet deposit
19000002	70000002	\N	\N	deposit	1150000.00	2026-07-07 16:27:25.894026	Initial wallet deposit
19000003	70000003	\N	\N	deposit	1200000.00	2026-07-07 16:27:25.894026	Initial wallet deposit
19000004	70000004	\N	\N	deposit	1250000.00	2026-07-07 16:27:25.894026	Initial wallet deposit
19000005	70000005	\N	\N	deposit	1300000.00	2026-07-07 16:27:25.894026	Initial wallet deposit
19000006	70000006	\N	\N	deposit	1350000.00	2026-07-07 16:27:25.894026	Initial wallet deposit
19000007	70000007	\N	\N	deposit	1400000.00	2026-07-07 16:27:25.894026	Initial wallet deposit
19000008	70000008	\N	\N	deposit	1450000.00	2026-07-07 16:27:25.894026	Initial wallet deposit
19000009	70000009	\N	\N	deposit	1500000.00	2026-07-07 16:27:25.894026	Initial wallet deposit
19000010	70000005	\N	18000010	refund	2500000.00	2026-07-07 18:22:37.671203	Wallet refund for restored cancelled reservation
\.


--
-- TOC entry 4114 (class 0 OID 16521)
-- Dependencies: 231
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wallets (wallet_id, user_id, balance, last_updated) FROM stdin;
70000001	60000001	1000000.00	2026-07-07 16:27:25.894026
70000007	60000007	1000000.00	2026-07-07 16:27:25.894026
70000004	60000004	1000000.00	2026-07-07 16:27:25.894026
70000002	60000002	1000000.00	2026-07-07 16:27:25.894026
70000000	60000000	1000000.00	2026-07-07 16:27:25.894026
70000003	60000003	1000000.00	2026-07-07 16:27:25.894026
70000008	60000008	1000000.00	2026-07-07 16:27:25.894026
70000006	60000006	1000000.00	2026-07-07 16:27:25.894026
70000009	60000009	1000000.00	2026-07-07 16:27:25.894026
70000005	60000005	1000000.00	2026-07-07 16:27:25.894026
\.


--
-- TOC entry 4149 (class 0 OID 0)
-- Dependencies: 240
-- Name: basketball_details_basketball_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.basketball_details_basketball_detail_id_seq', 14000009, true);


--
-- TOC entry 4150 (class 0 OID 0)
-- Dependencies: 234
-- Name: cancellation_policies_policy_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cancellation_policies_policy_id_seq', 90000019, true);


--
-- TOC entry 4151 (class 0 OID 0)
-- Dependencies: 218
-- Name: cities_city_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cities_city_id_seq', 10000009, true);


--
-- TOC entry 4152 (class 0 OID 0)
-- Dependencies: 236
-- Name: football_details_football_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.football_details_football_detail_id_seq', 12000009, true);


--
-- TOC entry 4153 (class 0 OID 0)
-- Dependencies: 232
-- Name: matches_match_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.matches_match_id_seq', 80000019, true);


--
-- TOC entry 4154 (class 0 OID 0)
-- Dependencies: 256
-- Name: notifications_notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_notification_id_seq', 21000010, true);


--
-- TOC entry 4155 (class 0 OID 0)
-- Dependencies: 222
-- Name: organizers_organizer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.organizers_organizer_id_seq', 30000009, true);


--
-- TOC entry 4156 (class 0 OID 0)
-- Dependencies: 258
-- Name: otp_logs_otp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.otp_logs_otp_id_seq', 22000009, true);


--
-- TOC entry 4157 (class 0 OID 0)
-- Dependencies: 248
-- Name: payments_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payments_payment_id_seq', 17000010, true);


--
-- TOC entry 4158 (class 0 OID 0)
-- Dependencies: 250
-- Name: refunds_refund_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.refunds_refund_id_seq', 18000010, true);


--
-- TOC entry 4159 (class 0 OID 0)
-- Dependencies: 254
-- Name: reports_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reports_report_id_seq', 20000010, true);


--
-- TOC entry 4160 (class 0 OID 0)
-- Dependencies: 246
-- Name: reservation_actions_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reservation_actions_action_id_seq', 16000011, true);


--
-- TOC entry 4161 (class 0 OID 0)
-- Dependencies: 244
-- Name: reservations_reservation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reservations_reservation_id_seq', 15000010, true);


--
-- TOC entry 4162 (class 0 OID 0)
-- Dependencies: 224
-- Name: seat_categories_seat_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seat_categories_seat_category_id_seq', 40000009, true);


--
-- TOC entry 4163 (class 0 OID 0)
-- Dependencies: 220
-- Name: sports_sport_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sports_sport_id_seq', 20000009, true);


--
-- TOC entry 4164 (class 0 OID 0)
-- Dependencies: 242
-- Name: tickets_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tickets_ticket_id_seq', 11000029, true);


--
-- TOC entry 4165 (class 0 OID 0)
-- Dependencies: 228
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 60000009, true);


--
-- TOC entry 4166 (class 0 OID 0)
-- Dependencies: 226
-- Name: venues_venue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venues_venue_id_seq', 50000009, true);


--
-- TOC entry 4167 (class 0 OID 0)
-- Dependencies: 238
-- Name: volleyball_details_volleyball_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.volleyball_details_volleyball_detail_id_seq', 13000009, true);


--
-- TOC entry 4168 (class 0 OID 0)
-- Dependencies: 252
-- Name: wallet_transactions_wallet_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wallet_transactions_wallet_transaction_id_seq', 19000010, true);


--
-- TOC entry 4169 (class 0 OID 0)
-- Dependencies: 230
-- Name: wallets_wallet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wallets_wallet_id_seq', 70000009, true);


--
-- TOC entry 3869 (class 2606 OID 16622)
-- Name: basketball_details basketball_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.basketball_details
    ADD CONSTRAINT basketball_details_pkey PRIMARY KEY (basketball_detail_id);


--
-- TOC entry 3859 (class 2606 OID 16579)
-- Name: cancellation_policies cancellation_policies_match_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cancellation_policies
    ADD CONSTRAINT cancellation_policies_match_id_key UNIQUE (match_id);


--
-- TOC entry 3861 (class 2606 OID 16581)
-- Name: cancellation_policies cancellation_policies_organizer_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cancellation_policies
    ADD CONSTRAINT cancellation_policies_organizer_id_key UNIQUE (organizer_id);


--
-- TOC entry 3863 (class 2606 OID 16577)
-- Name: cancellation_policies cancellation_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cancellation_policies
    ADD CONSTRAINT cancellation_policies_pkey PRIMARY KEY (policy_id);


--
-- TOC entry 3816 (class 2606 OID 16399)
-- Name: cities cities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cities
    ADD CONSTRAINT cities_pkey PRIMARY KEY (city_id);


--
-- TOC entry 3865 (class 2606 OID 16606)
-- Name: football_details football_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.football_details
    ADD CONSTRAINT football_details_pkey PRIMARY KEY (football_detail_id);


--
-- TOC entry 3857 (class 2606 OID 16552)
-- Name: matches matches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_pkey PRIMARY KEY (match_id);


--
-- TOC entry 3919 (class 2606 OID 16954)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- TOC entry 3825 (class 2606 OID 16430)
-- Name: organizers organizers_contact_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizers
    ADD CONSTRAINT organizers_contact_email_key UNIQUE (contact_email);


--
-- TOC entry 3827 (class 2606 OID 16432)
-- Name: organizers organizers_contact_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizers
    ADD CONSTRAINT organizers_contact_phone_key UNIQUE (contact_phone);


--
-- TOC entry 3829 (class 2606 OID 16428)
-- Name: organizers organizers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizers
    ADD CONSTRAINT organizers_pkey PRIMARY KEY (organizer_id);


--
-- TOC entry 3923 (class 2606 OID 17000)
-- Name: otp_logs otp_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_logs
    ADD CONSTRAINT otp_logs_pkey PRIMARY KEY (otp_id);


--
-- TOC entry 3891 (class 2606 OID 16781)
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (payment_id);


--
-- TOC entry 3893 (class 2606 OID 16783)
-- Name: payments payments_reservation_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_reservation_id_key UNIQUE (reservation_id);


--
-- TOC entry 3895 (class 2606 OID 16785)
-- Name: payments payments_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_transaction_id_key UNIQUE (transaction_id);


--
-- TOC entry 3899 (class 2606 OID 16816)
-- Name: refunds refunds_payment_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_payment_id_key UNIQUE (payment_id);


--
-- TOC entry 3901 (class 2606 OID 16814)
-- Name: refunds refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_pkey PRIMARY KEY (refund_id);


--
-- TOC entry 3915 (class 2606 OID 16898)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (report_id);


--
-- TOC entry 3886 (class 2606 OID 16744)
-- Name: reservation_actions reservation_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_actions
    ADD CONSTRAINT reservation_actions_pkey PRIMARY KEY (action_id);


--
-- TOC entry 3882 (class 2606 OID 16681)
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (reservation_id);


--
-- TOC entry 3831 (class 2606 OID 16440)
-- Name: seat_categories seat_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seat_categories
    ADD CONSTRAINT seat_categories_pkey PRIMARY KEY (seat_category_id);


--
-- TOC entry 3821 (class 2606 OID 16408)
-- Name: sports sports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sports
    ADD CONSTRAINT sports_pkey PRIMARY KEY (sport_id);


--
-- TOC entry 3876 (class 2606 OID 16633)
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (ticket_id);


--
-- TOC entry 3818 (class 2606 OID 16401)
-- Name: cities uq_city_name_province; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cities
    ADD CONSTRAINT uq_city_name_province UNIQUE (name, province);


--
-- TOC entry 3833 (class 2606 OID 16442)
-- Name: seat_categories uq_seat_category_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seat_categories
    ADD CONSTRAINT uq_seat_category_name UNIQUE (name);


--
-- TOC entry 3823 (class 2606 OID 16410)
-- Name: sports uq_sport_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sports
    ADD CONSTRAINT uq_sport_name UNIQUE (name);


--
-- TOC entry 3842 (class 2606 OID 16512)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3844 (class 2606 OID 16514)
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- TOC entry 3846 (class 2606 OID 16510)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3837 (class 2606 OID 16449)
-- Name: venues venues_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venues
    ADD CONSTRAINT venues_pkey PRIMARY KEY (venue_id);


--
-- TOC entry 3867 (class 2606 OID 16614)
-- Name: volleyball_details volleyball_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.volleyball_details
    ADD CONSTRAINT volleyball_details_pkey PRIMARY KEY (volleyball_detail_id);


--
-- TOC entry 3905 (class 2606 OID 16847)
-- Name: wallet_transactions wallet_transactions_payment_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_payment_id_key UNIQUE (payment_id);


--
-- TOC entry 3907 (class 2606 OID 16845)
-- Name: wallet_transactions wallet_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_pkey PRIMARY KEY (wallet_transaction_id);


--
-- TOC entry 3909 (class 2606 OID 16849)
-- Name: wallet_transactions wallet_transactions_refund_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_refund_id_key UNIQUE (refund_id);


--
-- TOC entry 3848 (class 2606 OID 16528)
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (wallet_id);


--
-- TOC entry 3850 (class 2606 OID 16530)
-- Name: wallets wallets_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_key UNIQUE (user_id);


--
-- TOC entry 3851 (class 1259 OID 17105)
-- Name: idx_matches_away_team_trgm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_away_team_trgm ON public.matches USING gin (lower((away_team)::text) public.gin_trgm_ops);


--
-- TOC entry 3852 (class 1259 OID 17104)
-- Name: idx_matches_home_team_trgm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_home_team_trgm ON public.matches USING gin (lower((home_team)::text) public.gin_trgm_ops);


--
-- TOC entry 3853 (class 1259 OID 17101)
-- Name: idx_matches_sport_date_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_sport_date_time ON public.matches USING btree (sport_id, match_date, match_time);


--
-- TOC entry 3854 (class 1259 OID 17103)
-- Name: idx_matches_status_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_status_date ON public.matches USING btree (status, match_date);


--
-- TOC entry 3855 (class 1259 OID 17102)
-- Name: idx_matches_venue_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_matches_venue_date ON public.matches USING btree (venue_id, match_date);


--
-- TOC entry 3916 (class 1259 OID 17127)
-- Name: idx_notifications_pending; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_pending ON public.notifications USING btree (created_at) WHERE (status = 'pending'::public.notification_status);


--
-- TOC entry 3917 (class 1259 OID 17126)
-- Name: idx_notifications_user_status_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user_status_date ON public.notifications USING btree (user_id, status, created_at DESC);


--
-- TOC entry 3920 (class 1259 OID 17128)
-- Name: idx_otp_active_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_otp_active_lookup ON public.otp_logs USING btree (identifier, purpose, expires_at DESC) WHERE (status = 'sent'::public.otp_status);


--
-- TOC entry 3921 (class 1259 OID 17129)
-- Name: idx_otp_user_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_otp_user_created ON public.otp_logs USING btree (user_id, created_at DESC);


--
-- TOC entry 3887 (class 1259 OID 17119)
-- Name: idx_payments_method_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_method_status ON public.payments USING btree (payment_method, status);


--
-- TOC entry 3888 (class 1259 OID 17117)
-- Name: idx_payments_status_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_status_date ON public.payments USING btree (status, payment_date DESC);


--
-- TOC entry 3889 (class 1259 OID 17118)
-- Name: idx_payments_user_status_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_user_status_date ON public.payments USING btree (user_id, status, payment_date DESC);


--
-- TOC entry 3896 (class 1259 OID 17120)
-- Name: idx_refunds_status_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_refunds_status_date ON public.refunds USING btree (status, refund_date DESC);


--
-- TOC entry 3897 (class 1259 OID 17121)
-- Name: idx_refunds_support_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_refunds_support_status ON public.refunds USING btree (approved_by_support_id, status);


--
-- TOC entry 3910 (class 1259 OID 17125)
-- Name: idx_reports_open_queue; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_open_queue ON public.reports USING btree (status, created_at DESC) WHERE (status = ANY (ARRAY['open'::public.report_status, 'in_progress'::public.report_status]));


--
-- TOC entry 3911 (class 1259 OID 17122)
-- Name: idx_reports_ticket_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_ticket_type ON public.reports USING btree (ticket_id, report_type);


--
-- TOC entry 3912 (class 1259 OID 17124)
-- Name: idx_reports_type_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_type_status ON public.reports USING btree (report_type, status);


--
-- TOC entry 3913 (class 1259 OID 17123)
-- Name: idx_reports_user_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_user_status ON public.reports USING btree (user_id, status);


--
-- TOC entry 3883 (class 1259 OID 17116)
-- Name: idx_reservation_actions_reservation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reservation_actions_reservation ON public.reservation_actions USING btree (reservation_id);


--
-- TOC entry 3884 (class 1259 OID 17115)
-- Name: idx_reservation_actions_support_cancel; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reservation_actions_support_cancel ON public.reservation_actions USING btree (action_by_user_id, action_time DESC) WHERE (action_type = 'cancelled_by_support'::public.reservation_action_type);


--
-- TOC entry 3877 (class 1259 OID 17113)
-- Name: idx_reservations_cancelled; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reservations_cancelled ON public.reservations USING btree (user_id, cancelled_at) WHERE (status = 'cancelled'::public.reservation_status);


--
-- TOC entry 3878 (class 1259 OID 17114)
-- Name: idx_reservations_expiring; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reservations_expiring ON public.reservations USING btree (expiry_time) WHERE (status = 'reserved'::public.reservation_status);


--
-- TOC entry 3879 (class 1259 OID 17112)
-- Name: idx_reservations_ticket_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reservations_ticket_status ON public.reservations USING btree (ticket_id, status);


--
-- TOC entry 3880 (class 1259 OID 17111)
-- Name: idx_reservations_user_status_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reservations_user_status_time ON public.reservations USING btree (user_id, status, reservation_time DESC);


--
-- TOC entry 3819 (class 1259 OID 17100)
-- Name: idx_sports_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sports_name ON public.sports USING btree (name);


--
-- TOC entry 3870 (class 1259 OID 17107)
-- Name: idx_tickets_available_by_match_price; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_available_by_match_price ON public.tickets USING btree (match_id, price) WHERE ((is_active = true) AND (capacity_remaining > 0));


--
-- TOC entry 3871 (class 1259 OID 17110)
-- Name: idx_tickets_basketball_detail; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_basketball_detail ON public.tickets USING btree (basketball_detail_id) WHERE (basketball_detail_id IS NOT NULL);


--
-- TOC entry 3872 (class 1259 OID 17108)
-- Name: idx_tickets_football_detail; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_football_detail ON public.tickets USING btree (football_detail_id) WHERE (football_detail_id IS NOT NULL);


--
-- TOC entry 3873 (class 1259 OID 17106)
-- Name: idx_tickets_match_category_price; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_match_category_price ON public.tickets USING btree (match_id, seat_category_id, price);


--
-- TOC entry 3874 (class 1259 OID 17109)
-- Name: idx_tickets_volleyball_detail; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_volleyball_detail ON public.tickets USING btree (volleyball_detail_id) WHERE (volleyball_detail_id IS NOT NULL);


--
-- TOC entry 3838 (class 1259 OID 17095)
-- Name: idx_users_city_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_city_role ON public.users USING btree (city_id, role);


--
-- TOC entry 3839 (class 1259 OID 17097)
-- Name: idx_users_full_name_trgm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_full_name_trgm ON public.users USING gin (lower((((first_name)::text || ' '::text) || (last_name)::text)) public.gin_trgm_ops);


--
-- TOC entry 3840 (class 1259 OID 17096)
-- Name: idx_users_registration_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_registration_date ON public.users USING btree (registration_date);


--
-- TOC entry 3834 (class 1259 OID 17098)
-- Name: idx_venues_city_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_venues_city_name ON public.venues USING btree (city_id, name);


--
-- TOC entry 3835 (class 1259 OID 17099)
-- Name: idx_venues_name_trgm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_venues_name_trgm ON public.venues USING gin (lower((name)::text) public.gin_trgm_ops);


--
-- TOC entry 3902 (class 1259 OID 17131)
-- Name: idx_wallet_transactions_type_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wallet_transactions_type_date ON public.wallet_transactions USING btree (transaction_type, transaction_date DESC);


--
-- TOC entry 3903 (class 1259 OID 17130)
-- Name: idx_wallet_transactions_wallet_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wallet_transactions_wallet_date ON public.wallet_transactions USING btree (wallet_id, transaction_date DESC);


--
-- TOC entry 3930 (class 2606 OID 16582)
-- Name: cancellation_policies fk_cancellation_policy_match; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cancellation_policies
    ADD CONSTRAINT fk_cancellation_policy_match FOREIGN KEY (match_id) REFERENCES public.matches(match_id);


--
-- TOC entry 3931 (class 2606 OID 16587)
-- Name: cancellation_policies fk_cancellation_policy_organizer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cancellation_policies
    ADD CONSTRAINT fk_cancellation_policy_organizer FOREIGN KEY (organizer_id) REFERENCES public.organizers(organizer_id);


--
-- TOC entry 3927 (class 2606 OID 16563)
-- Name: matches fk_matches_organizer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT fk_matches_organizer FOREIGN KEY (organizer_id) REFERENCES public.organizers(organizer_id);


--
-- TOC entry 3928 (class 2606 OID 16553)
-- Name: matches fk_matches_sport; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT fk_matches_sport FOREIGN KEY (sport_id) REFERENCES public.sports(sport_id);


--
-- TOC entry 3929 (class 2606 OID 16558)
-- Name: matches fk_matches_venue; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT fk_matches_venue FOREIGN KEY (venue_id) REFERENCES public.venues(venue_id);


--
-- TOC entry 3952 (class 2606 OID 16960)
-- Name: notifications fk_notifications_reservation; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_reservation FOREIGN KEY (reservation_id) REFERENCES public.reservations(reservation_id);


--
-- TOC entry 3953 (class 2606 OID 16965)
-- Name: notifications fk_notifications_ticket; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_ticket FOREIGN KEY (ticket_id) REFERENCES public.tickets(ticket_id);


--
-- TOC entry 3954 (class 2606 OID 16955)
-- Name: notifications fk_notifications_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3955 (class 2606 OID 17001)
-- Name: otp_logs fk_otp_logs_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_logs
    ADD CONSTRAINT fk_otp_logs_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3941 (class 2606 OID 16786)
-- Name: payments fk_payments_reservation; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_payments_reservation FOREIGN KEY (reservation_id) REFERENCES public.reservations(reservation_id);


--
-- TOC entry 3942 (class 2606 OID 16791)
-- Name: payments fk_payments_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_payments_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3943 (class 2606 OID 16822)
-- Name: refunds fk_refunds_approved_by_support; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT fk_refunds_approved_by_support FOREIGN KEY (approved_by_support_id) REFERENCES public.users(user_id);


--
-- TOC entry 3944 (class 2606 OID 16817)
-- Name: refunds fk_refunds_payment; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT fk_refunds_payment FOREIGN KEY (payment_id) REFERENCES public.payments(payment_id);


--
-- TOC entry 3948 (class 2606 OID 16914)
-- Name: reports fk_reports_handled_by_support; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_reports_handled_by_support FOREIGN KEY (handled_by_support_id) REFERENCES public.users(user_id);


--
-- TOC entry 3949 (class 2606 OID 16909)
-- Name: reports fk_reports_reservation; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_reports_reservation FOREIGN KEY (reservation_id) REFERENCES public.reservations(reservation_id);


--
-- TOC entry 3950 (class 2606 OID 16904)
-- Name: reports fk_reports_ticket; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_reports_ticket FOREIGN KEY (ticket_id) REFERENCES public.tickets(ticket_id);


--
-- TOC entry 3951 (class 2606 OID 16899)
-- Name: reports fk_reports_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_reports_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3939 (class 2606 OID 16745)
-- Name: reservation_actions fk_reservation_actions_reservation; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_actions
    ADD CONSTRAINT fk_reservation_actions_reservation FOREIGN KEY (reservation_id) REFERENCES public.reservations(reservation_id);


--
-- TOC entry 3940 (class 2606 OID 16750)
-- Name: reservation_actions fk_reservation_actions_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_actions
    ADD CONSTRAINT fk_reservation_actions_user FOREIGN KEY (action_by_user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3937 (class 2606 OID 16687)
-- Name: reservations fk_reservations_ticket; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_reservations_ticket FOREIGN KEY (ticket_id) REFERENCES public.tickets(ticket_id);


--
-- TOC entry 3938 (class 2606 OID 16682)
-- Name: reservations fk_reservations_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_reservations_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3932 (class 2606 OID 16654)
-- Name: tickets fk_tickets_basketball_detail; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_tickets_basketball_detail FOREIGN KEY (basketball_detail_id) REFERENCES public.basketball_details(basketball_detail_id);


--
-- TOC entry 3933 (class 2606 OID 16644)
-- Name: tickets fk_tickets_football_detail; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_tickets_football_detail FOREIGN KEY (football_detail_id) REFERENCES public.football_details(football_detail_id);


--
-- TOC entry 3934 (class 2606 OID 16634)
-- Name: tickets fk_tickets_match; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_tickets_match FOREIGN KEY (match_id) REFERENCES public.matches(match_id);


--
-- TOC entry 3935 (class 2606 OID 16639)
-- Name: tickets fk_tickets_seat_category; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_tickets_seat_category FOREIGN KEY (seat_category_id) REFERENCES public.seat_categories(seat_category_id);


--
-- TOC entry 3936 (class 2606 OID 16649)
-- Name: tickets fk_tickets_volleyball_detail; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_tickets_volleyball_detail FOREIGN KEY (volleyball_detail_id) REFERENCES public.volleyball_details(volleyball_detail_id);


--
-- TOC entry 3925 (class 2606 OID 16515)
-- Name: users fk_users_city; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_city FOREIGN KEY (city_id) REFERENCES public.cities(city_id);


--
-- TOC entry 3924 (class 2606 OID 16450)
-- Name: venues fk_venues_city; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venues
    ADD CONSTRAINT fk_venues_city FOREIGN KEY (city_id) REFERENCES public.cities(city_id);


--
-- TOC entry 3945 (class 2606 OID 16855)
-- Name: wallet_transactions fk_wallet_transactions_payment; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT fk_wallet_transactions_payment FOREIGN KEY (payment_id) REFERENCES public.payments(payment_id);


--
-- TOC entry 3946 (class 2606 OID 16860)
-- Name: wallet_transactions fk_wallet_transactions_refund; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT fk_wallet_transactions_refund FOREIGN KEY (refund_id) REFERENCES public.refunds(refund_id);


--
-- TOC entry 3947 (class 2606 OID 16850)
-- Name: wallet_transactions fk_wallet_transactions_wallet; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT fk_wallet_transactions_wallet FOREIGN KEY (wallet_id) REFERENCES public.wallets(wallet_id);


--
-- TOC entry 3926 (class 2606 OID 16531)
-- Name: wallets fk_wallets_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT fk_wallets_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


-- Completed on 2026-07-08 00:27:29 +0330

--
-- PostgreSQL database dump complete
--

\unrestrict azqKDrW1TzdyLanMYX2jZ8q3sVcuQRCeSRftbtxgH7Z5OPkT0L6gadrMLUKq7v3

