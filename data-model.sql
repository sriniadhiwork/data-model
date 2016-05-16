--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.5
-- Dumped by pg_dump version 9.4.5
-- Started on 2016-05-04 16:55:32

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 2051 (class 1262 OID 12135)
-- Dependencies: 2050
-- Name: postgres; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- TOC entry 6 (class 2615 OID 35911)
-- Name: audit; Type: SCHEMA; Schema: -; Owner: pulse
--

CREATE SCHEMA audit;


ALTER SCHEMA audit OWNER TO pulse;

--
-- TOC entry 7 (class 2615 OID 35912)
-- Name: pulse; Type: SCHEMA; Schema: -; Owner: pulse
--

CREATE SCHEMA pulse;


ALTER SCHEMA pulse OWNER TO pulse;

--
-- TOC entry 182 (class 3079 OID 11855)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2054 (class 0 OID 0)
-- Dependencies: 182
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 181 (class 3079 OID 16384)
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- TOC entry 2055 (class 0 OID 0)
-- Dependencies: 181
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


SET search_path = audit, pg_catalog;

--
-- TOC entry 195 (class 1255 OID 35913)
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
-- TOC entry 196 (class 1255 OID 35914)
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
-- TOC entry 174 (class 1259 OID 35915)
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
-- TOC entry 175 (class 1259 OID 35923)
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
-- TOC entry 176 (class 1259 OID 35931)
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
-- TOC entry 2059 (class 0 OID 0)
-- Dependencies: 176
-- Name: audit_id_seq; Type: SEQUENCE OWNED BY; Schema: pulse; Owner: pulse
--

ALTER SEQUENCE audit_id_seq OWNED BY audit.id;


--
-- TOC entry 177 (class 1259 OID 35933)
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
-- TOC entry 178 (class 1259 OID 35938)
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
-- TOC entry 2060 (class 0 OID 0)
-- Dependencies: 178
-- Name: directory_id_seq; Type: SEQUENCE OWNED BY; Schema: pulse; Owner: pulse
--

ALTER SEQUENCE directory_id_seq OWNED BY directory.id;


--
-- TOC entry 180 (class 1259 OID 35965)
-- Name: organization_id_seq; Type: SEQUENCE; Schema: pulse; Owner: pulse
--

CREATE SEQUENCE organization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE organization_id_seq OWNER TO pulse;

--
-- TOC entry 179 (class 1259 OID 35960)
-- Name: organization; Type: TABLE; Schema: pulse; Owner: pulse; Tablespace: 
--

CREATE TABLE organization (
    name character varying(128) NOT NULL,
    last_modifed_date timestamp without time zone DEFAULT now() NOT NULL,
    creation_date timestamp without time zone DEFAULT now() NOT NULL,
    id bigint DEFAULT nextval('organization_id_seq'::regclass) NOT NULL
);


ALTER TABLE organization OWNER TO pulse;

CREATE TABLE address
(
  id bigserial NOT NULL,
  street_line_1 character varying(250) NOT NULL,
  street_line_2 character varying(250),
  city character varying(250) NOT NULL,
  state character varying(100) NOT NULL,
  zipcode character varying(100) NOT NULL,
  country character varying(250) NOT NULL,
  creation_date timestamp without time zone NOT NULL DEFAULT now(),
  last_modified_date timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT address_pk PRIMARY KEY (id)
);
ALTER TABLE address OWNER TO pulse;

CREATE TABLE patient (
	id bigserial not null,
	patient_id varchar(100) not null,
	first_name varchar(100) not null,
	last_name varchar(100) not null,
	dob date without timezone,
	ssn varchar(9),
	gender varchar(10),
	phone_number varchar(20),
	address_id bigint,
	last_modified_date timestamp without timezone default now() not null,
	creation_date timestamp without timezone default now() not null,
	CONSTRAINT patient_pk PRIMARY KEY (id),
	CONSTRAINT address_fk FOREIGN KEY (address_id) REFERENCES address (id) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE
);
ALTER TABLE patient OWNER TO pulse;

--
-- TOC entry 1908 (class 2604 OID 35954)
-- Name: id; Type: DEFAULT; Schema: pulse; Owner: pulse
--

ALTER TABLE ONLY audit ALTER COLUMN id SET DEFAULT nextval('audit_id_seq'::regclass);


--
-- TOC entry 1911 (class 2604 OID 35955)
-- Name: id; Type: DEFAULT; Schema: pulse; Owner: pulse
--

ALTER TABLE ONLY directory ALTER COLUMN id SET DEFAULT nextval('directory_id_seq'::regclass);


SET search_path = audit, pg_catalog;

--
-- TOC entry 2039 (class 0 OID 35915)
-- Dependencies: 174
-- Data for Name: logged_actions; Type: TABLE DATA; Schema: audit; Owner: pulse
--

COPY logged_actions (schema_name, table_name, user_name, action_tstamp, action, original_data, new_data, query) FROM stdin;
pulse	organization	postgres	2016-05-04 16:22:50.731-04	I	\N	{"name":"OrganizationOne","last_modifed_date":"2016-05-04T16:22:50.731","creation_date":"2016-05-04T16:22:50.731","id":1}	INSERT into organization (name) VALUES ('OrganizationOne')
pulse	organization	postgres	2016-05-04 16:22:50.834-04	I	\N	{"name":"OrganizationTwo","last_modifed_date":"2016-05-04T16:22:50.834","creation_date":"2016-05-04T16:22:50.834","id":2}	INSERT into organization (name) VALUES ('OrganizationTwo')
pulse	organization	postgres	2016-05-04 16:22:50.834-04	I	\N	{"name":"OrganizationThree","last_modifed_date":"2016-05-04T16:22:50.834","creation_date":"2016-05-04T16:22:50.834","id":3}	INSERT into organization (name) VALUES ('OrganizationThree')
\.


SET search_path = pulse, pg_catalog;

--
-- TOC entry 2040 (class 0 OID 35923)
-- Dependencies: 175
-- Data for Name: audit; Type: TABLE DATA; Schema: pulse; Owner: pulse
--

COPY audit (id, query, creation_date, querent, last_modified_date) FROM stdin;
\.


--
-- TOC entry 2061 (class 0 OID 0)
-- Dependencies: 176
-- Name: audit_id_seq; Type: SEQUENCE SET; Schema: pulse; Owner: pulse
--

SELECT pg_catalog.setval('audit_id_seq', 1, false);


--
-- TOC entry 2042 (class 0 OID 35933)
-- Dependencies: 177
-- Data for Name: directory; Type: TABLE DATA; Schema: pulse; Owner: pulse
--

COPY directory (organization, id, last_modified_date, creation_date) FROM stdin;
\.


--
-- TOC entry 2062 (class 0 OID 0)
-- Dependencies: 178
-- Name: directory_id_seq; Type: SEQUENCE SET; Schema: pulse; Owner: pulse
--

SELECT pg_catalog.setval('directory_id_seq', 1, false);


--
-- TOC entry 2044 (class 0 OID 35960)
-- Dependencies: 179
-- Data for Name: organization; Type: TABLE DATA; Schema: pulse; Owner: pulse
--

COPY organization (name, last_modifed_date, creation_date, id) FROM stdin;
OrganizationOne	2016-05-04 16:22:50.731	2016-05-04 16:22:50.731	1
OrganizationTwo	2016-05-04 16:22:50.834	2016-05-04 16:22:50.834	2
OrganizationThree	2016-05-04 16:22:50.834	2016-05-04 16:22:50.834	3
\.


--
-- TOC entry 2063 (class 0 OID 0)
-- Dependencies: 180
-- Name: organization_id_seq; Type: SEQUENCE SET; Schema: pulse; Owner: pulse
--

SELECT pg_catalog.setval('organization_id_seq', 3, true);


--
-- TOC entry 1919 (class 2606 OID 35943)
-- Name: audit_pk; Type: CONSTRAINT; Schema: pulse; Owner: pulse; Tablespace: 
--

ALTER TABLE ONLY audit
    ADD CONSTRAINT audit_pk PRIMARY KEY (id);


--
-- TOC entry 1921 (class 2606 OID 35945)
-- Name: directory_pk; Type: CONSTRAINT; Schema: pulse; Owner: pulse; Tablespace: 
--

ALTER TABLE ONLY directory
    ADD CONSTRAINT directory_pk PRIMARY KEY (id);


--
-- TOC entry 1923 (class 2606 OID 35968)
-- Name: organization_pk; Type: CONSTRAINT; Schema: pulse; Owner: pulse; Tablespace: 
--

ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_pk PRIMARY KEY (id);


SET search_path = audit, pg_catalog;

--
-- TOC entry 1915 (class 1259 OID 35946)
-- Name: logged_actions_action_idx; Type: INDEX; Schema: audit; Owner: pulse; Tablespace: 
--

CREATE INDEX logged_actions_action_idx ON logged_actions USING btree (action);


--
-- TOC entry 1916 (class 1259 OID 35947)
-- Name: logged_actions_action_tstamp_idx; Type: INDEX; Schema: audit; Owner: pulse; Tablespace: 
--

CREATE INDEX logged_actions_action_tstamp_idx ON logged_actions USING btree (action_tstamp);


--
-- TOC entry 1917 (class 1259 OID 35948)
-- Name: logged_actions_schema_table_idx; Type: INDEX; Schema: audit; Owner: pulse; Tablespace: 
--

CREATE INDEX logged_actions_schema_table_idx ON logged_actions USING btree ((((schema_name || '.'::text) || table_name)));


SET search_path = pulse, pg_catalog;

--
-- TOC entry 1924 (class 2620 OID 35949)
-- Name: audit_audit; Type: TRIGGER; Schema: pulse; Owner: pulse
--

CREATE TRIGGER audit_audit AFTER INSERT OR DELETE OR UPDATE ON audit FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();


--
-- TOC entry 1925 (class 2620 OID 35950)
-- Name: audit_timestamp; Type: TRIGGER; Schema: pulse; Owner: pulse
--

CREATE TRIGGER audit_timestamp BEFORE UPDATE ON audit FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();


--
-- TOC entry 1926 (class 2620 OID 35951)
-- Name: directory_audit; Type: TRIGGER; Schema: pulse; Owner: pulse
--

CREATE TRIGGER directory_audit AFTER INSERT OR DELETE OR UPDATE ON directory FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();


--
-- TOC entry 1927 (class 2620 OID 35952)
-- Name: directory_timestamp; Type: TRIGGER; Schema: pulse; Owner: pulse
--

CREATE TRIGGER directory_timestamp BEFORE UPDATE ON directory FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();


--
-- TOC entry 1928 (class 2620 OID 35969)
-- Name: organization_audit; Type: TRIGGER; Schema: pulse; Owner: pulse
--

CREATE TRIGGER organization_audit AFTER INSERT OR DELETE OR UPDATE ON organization FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();


--
-- TOC entry 1929 (class 2620 OID 35970)
-- Name: organization_timestamp; Type: TRIGGER; Schema: pulse; Owner: pulse
--

CREATE TRIGGER organization_timestamp BEFORE UPDATE ON organization FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();


--
-- TOC entry 2053 (class 0 OID 0)
-- Dependencies: 8
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


SET search_path = audit, pg_catalog;

--
-- TOC entry 2056 (class 0 OID 0)
-- Dependencies: 195
-- Name: if_modified_func(); Type: ACL; Schema: audit; Owner: pulse
--

REVOKE ALL ON FUNCTION if_modified_func() FROM PUBLIC;
REVOKE ALL ON FUNCTION if_modified_func() FROM pulse;
GRANT ALL ON FUNCTION if_modified_func() TO pulse;
GRANT ALL ON FUNCTION if_modified_func() TO PUBLIC;


SET search_path = pulse, pg_catalog;

--
-- TOC entry 2057 (class 0 OID 0)
-- Dependencies: 196
-- Name: update_last_modified_date_column(); Type: ACL; Schema: pulse; Owner: pulse
--

REVOKE ALL ON FUNCTION update_last_modified_date_column() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_last_modified_date_column() FROM pulse;
GRANT ALL ON FUNCTION update_last_modified_date_column() TO pulse;
GRANT ALL ON FUNCTION update_last_modified_date_column() TO PUBLIC;


SET search_path = audit, pg_catalog;

--
-- TOC entry 2058 (class 0 OID 0)
-- Dependencies: 174
-- Name: logged_actions; Type: ACL; Schema: audit; Owner: pulse
--

REVOKE ALL ON TABLE logged_actions FROM PUBLIC;
REVOKE ALL ON TABLE logged_actions FROM pulse;
GRANT ALL ON TABLE logged_actions TO pulse;


-- Completed on 2016-05-04 16:55:33

--
-- PostgreSQL database dump complete
--
