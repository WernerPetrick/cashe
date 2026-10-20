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
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: ledger_entries_append_only(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ledger_entries_append_only() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'ledger_entries is append-only: % is not allowed', TG_OP;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ledger_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ledger_entries (
    id bigint NOT NULL,
    wallet_id bigint NOT NULL,
    amount_cents bigint NOT NULL,
    kind character varying NOT NULL,
    idempotency_key character varying NOT NULL,
    unlock_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT ledger_entries_kind CHECK (((kind)::text = ANY ((ARRAY['deposit'::character varying, 'spend'::character varying, 'refund'::character varying])::text[]))),
    CONSTRAINT ledger_entries_sign_matches_kind CHECK (((((kind)::text = 'deposit'::text) AND (amount_cents > 0)) OR (((kind)::text = ANY ((ARRAY['spend'::character varying, 'refund'::character varying])::text[])) AND (amount_cents < 0)))),
    CONSTRAINT ledger_entries_spend_has_unlock CHECK ((((kind)::text <> 'spend'::text) OR (unlock_id IS NOT NULL)))
);


--
-- Name: ledger_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ledger_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ledger_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ledger_entries_id_seq OWNED BY public.ledger_entries.id;


--
-- Name: places; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.places (
    id bigint NOT NULL,
    name character varying(120) NOT NULL,
    location public.geography(Point,4326) NOT NULL,
    radius_m integer NOT NULL,
    dwell_seconds integer NOT NULL,
    created_by_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT places_dwell_range CHECK (((dwell_seconds >= 10) AND (dwell_seconds <= 3600))),
    CONSTRAINT places_radius_range CHECK (((radius_m >= 10) AND (radius_m <= 1000)))
);


--
-- Name: places_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.places_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: places_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.places_id_seq OWNED BY public.places.id;


--
-- Name: presence_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.presence_sessions (
    id bigint NOT NULL,
    wallet_id bigint NOT NULL,
    user_id bigint NOT NULL,
    entered_at timestamp(6) without time zone NOT NULL,
    last_ping_at timestamp(6) without time zone NOT NULL,
    unlocked_at timestamp(6) without time zone,
    ended_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT presence_sessions_end_order CHECK (((ended_at IS NULL) OR (ended_at >= entered_at))),
    CONSTRAINT presence_sessions_ping_order CHECK ((last_ping_at >= entered_at))
);


--
-- Name: presence_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.presence_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: presence_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.presence_sessions_id_seq OWNED BY public.presence_sessions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: time_windows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.time_windows (
    id bigint NOT NULL,
    wallet_id bigint NOT NULL,
    days_of_week integer[] NOT NULL,
    starts_at time without time zone NOT NULL,
    ends_at time without time zone NOT NULL,
    time_zone character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT time_windows_days_valid CHECK ((((cardinality(days_of_week) >= 1) AND (cardinality(days_of_week) <= 7)) AND (days_of_week <@ ARRAY[0, 1, 2, 3, 4, 5, 6]))),
    CONSTRAINT time_windows_ordered CHECK ((starts_at < ends_at))
);


--
-- Name: time_windows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.time_windows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: time_windows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.time_windows_id_seq OWNED BY public.time_windows.id;


--
-- Name: unlocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unlocks (
    id bigint NOT NULL,
    wallet_id bigint NOT NULL,
    presence_session_id bigint NOT NULL,
    unlocked_until timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: unlocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.unlocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: unlocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.unlocks_id_seq OWNED BY public.unlocks.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    appwrite_user_id character varying NOT NULL,
    display_name character varying(100) NOT NULL,
    role character varying DEFAULT 'adult'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['adult'::character varying, 'child'::character varying])::text[])))
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wallets (
    id bigint NOT NULL,
    kind character varying NOT NULL,
    owner_id bigint,
    funder_id bigint NOT NULL,
    place_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    currency character varying(3) NOT NULL,
    status character varying NOT NULL,
    target_cents bigint,
    expires_at timestamp(6) without time zone,
    claim_token_digest character varying,
    claim_expires_at timestamp(6) without time zone,
    claimed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT wallets_currency_format CHECK (((currency)::text ~ '^[A-Z]{3}$'::text)),
    CONSTRAINT wallets_gift_claimed CHECK ((((kind)::text <> 'gift'::text) OR (((owner_id IS NULL) = (claimed_at IS NULL)) AND (owner_id IS DISTINCT FROM funder_id)))),
    CONSTRAINT wallets_goal_owned CHECK ((((kind)::text <> 'goal'::text) OR ((owner_id = funder_id) AND ((status)::text <> 'pending'::text) AND (claim_token_digest IS NULL)))),
    CONSTRAINT wallets_kind CHECK (((kind)::text = ANY ((ARRAY['goal'::character varying, 'gift'::character varying])::text[]))),
    CONSTRAINT wallets_pending_unclaimed CHECK ((((status)::text <> 'pending'::text) OR ((owner_id IS NULL) AND (claim_token_digest IS NOT NULL) AND (claim_expires_at IS NOT NULL)))),
    CONSTRAINT wallets_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'active'::character varying, 'cancelled'::character varying, 'expired'::character varying])::text[]))),
    CONSTRAINT wallets_target_positive CHECK (((target_cents IS NULL) OR (target_cents > 0)))
);


--
-- Name: wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wallets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wallets_id_seq OWNED BY public.wallets.id;


--
-- Name: ledger_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries ALTER COLUMN id SET DEFAULT nextval('public.ledger_entries_id_seq'::regclass);


--
-- Name: places id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places ALTER COLUMN id SET DEFAULT nextval('public.places_id_seq'::regclass);


--
-- Name: presence_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presence_sessions ALTER COLUMN id SET DEFAULT nextval('public.presence_sessions_id_seq'::regclass);


--
-- Name: time_windows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.time_windows ALTER COLUMN id SET DEFAULT nextval('public.time_windows_id_seq'::regclass);


--
-- Name: unlocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unlocks ALTER COLUMN id SET DEFAULT nextval('public.unlocks_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: wallets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets ALTER COLUMN id SET DEFAULT nextval('public.wallets_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: ledger_entries ledger_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT ledger_entries_pkey PRIMARY KEY (id);


--
-- Name: places places_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places
    ADD CONSTRAINT places_pkey PRIMARY KEY (id);


--
-- Name: presence_sessions presence_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presence_sessions
    ADD CONSTRAINT presence_sessions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: time_windows time_windows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.time_windows
    ADD CONSTRAINT time_windows_pkey PRIMARY KEY (id);


--
-- Name: unlocks unlocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unlocks
    ADD CONSTRAINT unlocks_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (id);


--
-- Name: index_ledger_entries_on_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ledger_entries_on_idempotency_key ON public.ledger_entries USING btree (idempotency_key);


--
-- Name: index_ledger_entries_on_unlock_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_entries_on_unlock_id ON public.ledger_entries USING btree (unlock_id);


--
-- Name: index_ledger_entries_on_wallet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_entries_on_wallet_id ON public.ledger_entries USING btree (wallet_id);


--
-- Name: index_places_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_places_on_created_by_id ON public.places USING btree (created_by_id);


--
-- Name: index_places_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_places_on_location ON public.places USING gist (location);


--
-- Name: index_presence_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_presence_sessions_on_user_id ON public.presence_sessions USING btree (user_id);


--
-- Name: index_presence_sessions_on_wallet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_presence_sessions_on_wallet_id ON public.presence_sessions USING btree (wallet_id);


--
-- Name: index_presence_sessions_one_open_per_wallet_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_presence_sessions_one_open_per_wallet_user ON public.presence_sessions USING btree (wallet_id, user_id) WHERE (ended_at IS NULL);


--
-- Name: index_time_windows_on_wallet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_time_windows_on_wallet_id ON public.time_windows USING btree (wallet_id);


--
-- Name: index_unlocks_on_presence_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_unlocks_on_presence_session_id ON public.unlocks USING btree (presence_session_id);


--
-- Name: index_unlocks_on_wallet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_unlocks_on_wallet_id ON public.unlocks USING btree (wallet_id);


--
-- Name: index_unlocks_on_wallet_id_and_unlocked_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_unlocks_on_wallet_id_and_unlocked_until ON public.unlocks USING btree (wallet_id, unlocked_until);


--
-- Name: index_users_on_appwrite_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_appwrite_user_id ON public.users USING btree (appwrite_user_id);


--
-- Name: index_wallets_on_claim_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_wallets_on_claim_token_digest ON public.wallets USING btree (claim_token_digest);


--
-- Name: index_wallets_on_funder_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wallets_on_funder_id ON public.wallets USING btree (funder_id);


--
-- Name: index_wallets_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wallets_on_owner_id ON public.wallets USING btree (owner_id);


--
-- Name: index_wallets_on_place_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wallets_on_place_id ON public.wallets USING btree (place_id);


--
-- Name: ledger_entries ledger_entries_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ledger_entries_append_only BEFORE DELETE OR UPDATE ON public.ledger_entries FOR EACH ROW EXECUTE FUNCTION public.ledger_entries_append_only();


--
-- Name: unlocks fk_rails_101cb713c8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unlocks
    ADD CONSTRAINT fk_rails_101cb713c8 FOREIGN KEY (wallet_id) REFERENCES public.wallets(id);


--
-- Name: wallets fk_rails_1efc111466; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT fk_rails_1efc111466 FOREIGN KEY (place_id) REFERENCES public.places(id);


--
-- Name: places fk_rails_31ce07b761; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places
    ADD CONSTRAINT fk_rails_31ce07b761 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: time_windows fk_rails_461c356606; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.time_windows
    ADD CONSTRAINT fk_rails_461c356606 FOREIGN KEY (wallet_id) REFERENCES public.wallets(id);


--
-- Name: wallets fk_rails_5aeec89b41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT fk_rails_5aeec89b41 FOREIGN KEY (funder_id) REFERENCES public.users(id);


--
-- Name: ledger_entries fk_rails_617b3bc35c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT fk_rails_617b3bc35c FOREIGN KEY (unlock_id) REFERENCES public.unlocks(id);


--
-- Name: wallets fk_rails_6698238c25; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT fk_rails_6698238c25 FOREIGN KEY (owner_id) REFERENCES public.users(id);


--
-- Name: presence_sessions fk_rails_7f17780758; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presence_sessions
    ADD CONSTRAINT fk_rails_7f17780758 FOREIGN KEY (wallet_id) REFERENCES public.wallets(id);


--
-- Name: ledger_entries fk_rails_98acf6cd6c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT fk_rails_98acf6cd6c FOREIGN KEY (wallet_id) REFERENCES public.wallets(id);


--
-- Name: unlocks fk_rails_d7f862430c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unlocks
    ADD CONSTRAINT fk_rails_d7f862430c FOREIGN KEY (presence_session_id) REFERENCES public.presence_sessions(id);


--
-- Name: presence_sessions fk_rails_ead4a26204; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presence_sessions
    ADD CONSTRAINT fk_rails_ead4a26204 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261020115002'),
('20261020115000'),
('20261020114958'),
('20261020114957'),
('20261020114955'),
('20261020114953'),
('20261020074700'),
('20261020072612');

