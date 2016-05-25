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
    id bigserial NOT NULL,
    query character varying(1024) NOT NULL,
    creation_date timestamp without time zone DEFAULT now() NOT NULL,
    querent character varying(128) NOT NULL,
    last_modified_date timestamp without time zone DEFAULT now() NOT NULL,
	CONSTRAINT audit_pk PRIMARY KEY (id)
);
ALTER TABLE audit OWNER TO pulse;


CREATE TABLE organization (
	id bigserial NOT NULL,
	organization_id bigserial NOT NULL,
  	name character varying(128) NOT NULL,
  	last_modified_date timestamp without time zone NOT NULL DEFAULT now(),
  	creation_date timestamp without time zone NOT NULL DEFAULT now(),
  	is_active boolean NOT NULL,
  	adapter character varying(128) NOT NULL,
  	ip_address character varying(32),
  	username character varying(64),
  	password character varying(64),
  	certification_key character varying(128),
  	endpoint_url character varying(256),
  	CONSTRAINT organization_pk PRIMARY KEY (id)
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
	dob date,
	ssn varchar(9),
	gender varchar(10),
	phone_number varchar(20),
	address_id bigint,
	organization_id bigint,
	last_read_date timestamp without time zone default now() not null,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT patient_pk PRIMARY KEY (id),
	CONSTRAINT address_fk FOREIGN KEY (address_id) REFERENCES address (id) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT organization_fk FOREIGN KEY (organization_id) REFERENCES organization (id) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE
);
ALTER TABLE patient OWNER TO pulse;

CREATE TABLE document (
	id bigserial not null,
	name varchar(500) not null,
	format varchar(100),
	patient_id bigint not null,
	last_read_date timestamp without time zone default now() not null,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT document_pk PRIMARY KEY (id),
	CONSTRAINT patient_fk FOREIGN KEY (patient_id) REFERENCES patient (id) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE
);
ALTER TABLE document OWNER TO pulse;

SET search_path = audit, pg_catalog;

--
-- TOC entry 2039 (class 0 OID 35915)
-- Dependencies: 174
-- Data for Name: logged_actions; Type: TABLE DATA; Schema: audit; Owner: pulse
--


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
CREATE TRIGGER audit_timestamp BEFORE UPDATE ON audit FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER organization_audit AFTER INSERT OR DELETE OR UPDATE ON organization FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER organization_timestamp BEFORE UPDATE ON organization FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER address_audit AFTER INSERT OR DELETE OR UPDATE ON address FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER address_timestamp BEFORE UPDATE ON address FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER patient_audit AFTER INSERT OR DELETE OR UPDATE ON patient FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER patient_timestamp BEFORE UPDATE ON patient FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER document_audit AFTER INSERT OR DELETE OR UPDATE ON document FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER document_timestamp BEFORE UPDATE ON document FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();

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