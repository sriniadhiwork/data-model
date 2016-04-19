--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: audit; Type: SCHEMA; Schema: -; Owner: pulse
--

CREATE SCHEMA audit;


ALTER SCHEMA audit OWNER TO pulse;

--
-- Name: pulse; Type: SCHEMA; Schema: -; Owner: pulse
--

CREATE SCHEMA pulse;


ALTER SCHEMA pulse OWNER TO pulse;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = audit, pg_catalog;

--
-- Name: if_modified_func(); Type: FUNCTION; Schema: audit; Owner: pulse
--

CREATE FUNCTION if_modified_func() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO pg_catalog, audit
    AS $$
DECLARE
    v_old_data json;
    v_new_data json;
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        v_old_data := row_to_json(OLD);
        v_new_data := row_to_json(NEW);
        INSERT INTO audit.logged_actions (schema_name, table_name, user_name, action, original_data, new_data, query)
        VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, substring(TG_OP,1,1), v_old_data, v_new_data, current_query());
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        v_old_data := row_to_json(OLD);
        INSERT INTO audit.logged_actions (schema_name, table_name, user_name, action, original_data, query)
        VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, substring(TG_OP,1,1), v_old_data, current_query());
        RETURN OLD;
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := row_to_json(NEW);
        INSERT INTO audit.logged_actions (schema_name, table_name, user_name, action, new_data, query)
        VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, session_user::TEXT, substring(TG_OP,1,1), v_new_data, current_query());
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - Other action occurred: %, at %',TG_OP,now();
        RETURN NULL;
    END IF;

EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
END;
$$;


ALTER FUNCTION audit.if_modified_func() OWNER TO pulse;

SET search_path = pulse, pg_catalog;

--
-- Name: update_last_modified_date_column(); Type: FUNCTION; Schema: pulse; Owner: pulse
--

CREATE FUNCTION update_last_modified_date_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.last_modified_date = now();
   RETURN NEW;
END;
$$;


ALTER FUNCTION pulse.update_last_modified_date_column() OWNER TO pulse;

SET search_path = audit, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: logged_actions; Type: TABLE; Schema: audit; Owner: pulse; Tablespace: 
--

CREATE TABLE logged_actions (
    schema_name text NOT NULL,
    table_name text NOT NULL,
    user_name text,
    action_tstamp timestamp with time zone DEFAULT now() NOT NULL,
    action text NOT NULL,
    original_data json,
    new_data json,
    query text,
    CONSTRAINT logged_actions_action_check CHECK ((action = ANY (ARRAY['I'::text, 'D'::text, 'U'::text])))
)
WITH (fillfactor=100);


ALTER TABLE logged_actions OWNER TO pulse;

SET search_path = pulse, pg_catalog;

--
-- Name: audit; Type: TABLE; Schema: pulse; Owner: pulse; Tablespace: 
--

CREATE TABLE audit (
    id bigint NOT NULL,
    query character varying(1024) NOT NULL,
    creation_date timestamp without time zone DEFAULT now() NOT NULL,
    querent character varying(128) NOT NULL,
    last_modified_date timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE audit OWNER TO pulse;

--
-- Name: audit_id_seq; Type: SEQUENCE; Schema: pulse; Owner: pulse
--

CREATE SEQUENCE audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE audit_id_seq OWNER TO pulse;

--
-- Name: audit_id_seq; Type: SEQUENCE OWNED BY; Schema: pulse; Owner: pulse
--

ALTER SEQUENCE audit_id_seq OWNED BY audit.id;


--
-- Name: directory; Type: TABLE; Schema: pulse; Owner: pulse; Tablespace: 
--

CREATE TABLE directory (
    organization character varying(128) NOT NULL,
    id bigint NOT NULL,
    last_modified_date timestamp without time zone DEFAULT now() NOT NULL,
    creation_date timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE directory OWNER TO pulse;

--
-- Name: directory_id_seq; Type: SEQUENCE; Schema: pulse; Owner: pulse
--

CREATE SEQUENCE directory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE directory_id_seq OWNER TO pulse;

--
-- Name: directory_id_seq; Type: SEQUENCE OWNED BY; Schema: pulse; Owner: pulse
--

ALTER SEQUENCE directory_id_seq OWNED BY directory.id;


--
-- Name: id; Type: DEFAULT; Schema: pulse; Owner: pulse
--

ALTER TABLE ONLY audit ALTER COLUMN id SET DEFAULT nextval('audit_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: pulse; Owner: pulse
--

ALTER TABLE ONLY directory ALTER COLUMN id SET DEFAULT nextval('directory_id_seq'::regclass);


SET search_path = audit, pg_catalog;

--
-- Data for Name: logged_actions; Type: TABLE DATA; Schema: audit; Owner: pulse
--

COPY logged_actions (schema_name, table_name, user_name, action_tstamp, action, original_data, new_data, query) FROM stdin;
\.


SET search_path = pulse, pg_catalog;

--
-- Data for Name: audit; Type: TABLE DATA; Schema: pulse; Owner: pulse
--

COPY audit (id, query, creation_date, querent, last_modified_date) FROM stdin;
\.


--
-- Name: audit_id_seq; Type: SEQUENCE SET; Schema: pulse; Owner: pulse
--

SELECT pg_catalog.setval('audit_id_seq', 1, false);


--
-- Data for Name: directory; Type: TABLE DATA; Schema: pulse; Owner: pulse
--

COPY directory (organization, id, last_modified_date, creation_date) FROM stdin;
\.


--
-- Name: directory_id_seq; Type: SEQUENCE SET; Schema: pulse; Owner: pulse
--

SELECT pg_catalog.setval('directory_id_seq', 1, false);


--
-- Name: audit_pk; Type: CONSTRAINT; Schema: pulse; Owner: pulse; Tablespace: 
--

ALTER TABLE ONLY audit
    ADD CONSTRAINT audit_pk PRIMARY KEY (id);


--
-- Name: directory_pk; Type: CONSTRAINT; Schema: pulse; Owner: pulse; Tablespace: 
--

ALTER TABLE ONLY directory
    ADD CONSTRAINT directory_pk PRIMARY KEY (id);


SET search_path = audit, pg_catalog;

--
-- Name: logged_actions_action_idx; Type: INDEX; Schema: audit; Owner: pulse; Tablespace: 
--

CREATE INDEX logged_actions_action_idx ON logged_actions USING btree (action);


--
-- Name: logged_actions_action_tstamp_idx; Type: INDEX; Schema: audit; Owner: pulse; Tablespace: 
--

CREATE INDEX logged_actions_action_tstamp_idx ON logged_actions USING btree (action_tstamp);


--
-- Name: logged_actions_schema_table_idx; Type: INDEX; Schema: audit; Owner: pulse; Tablespace: 
--

CREATE INDEX logged_actions_schema_table_idx ON logged_actions USING btree ((((schema_name || '.'::text) || table_name)));


SET search_path = pulse, pg_catalog;

--
-- Name: audit_audit; Type: TRIGGER; Schema: pulse; Owner: pulse
--

CREATE TRIGGER audit_audit AFTER INSERT OR DELETE OR UPDATE ON audit FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();


--
-- Name: audit_timestamp; Type: TRIGGER; Schema: pulse; Owner: pulse
--

CREATE TRIGGER audit_timestamp BEFORE UPDATE ON audit FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();


--
-- Name: directory_audit; Type: TRIGGER; Schema: pulse; Owner: pulse
--

CREATE TRIGGER directory_audit AFTER INSERT OR DELETE OR UPDATE ON directory FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();


--
-- Name: directory_timestamp; Type: TRIGGER; Schema: pulse; Owner: pulse
--

CREATE TRIGGER directory_timestamp BEFORE UPDATE ON directory FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


SET search_path = audit, pg_catalog;

--
-- Name: if_modified_func(); Type: ACL; Schema: audit; Owner: pulse
--

REVOKE ALL ON FUNCTION if_modified_func() FROM PUBLIC;
REVOKE ALL ON FUNCTION if_modified_func() FROM pulse;
GRANT ALL ON FUNCTION if_modified_func() TO pulse;
GRANT ALL ON FUNCTION if_modified_func() TO PUBLIC;


SET search_path = pulse, pg_catalog;

--
-- Name: update_last_modified_date_column(); Type: ACL; Schema: pulse; Owner: pulse
--

REVOKE ALL ON FUNCTION update_last_modified_date_column() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_last_modified_date_column() FROM pulse;
GRANT ALL ON FUNCTION update_last_modified_date_column() TO pulse;
GRANT ALL ON FUNCTION update_last_modified_date_column() TO PUBLIC;


SET search_path = audit, pg_catalog;

--
-- Name: logged_actions; Type: ACL; Schema: audit; Owner: pulse
--

REVOKE ALL ON TABLE logged_actions FROM PUBLIC;
REVOKE ALL ON TABLE logged_actions FROM pulse;
GRANT ALL ON TABLE logged_actions TO pulse;


--
-- PostgreSQL database dump complete
--

