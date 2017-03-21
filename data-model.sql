
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

CREATE TABLE pulse_event_action_code (
	id bigserial NOT NULL,
	code varchar(2),
	description varchar(128),
	CONSTRAINT pulse_event_action_code_pk PRIMARY KEY (id)
);
ALTER TABLE pulse_event_action_code OWNER to pulse;

CREATE TABLE pulse_event_action (
	id bigserial NOT NULL,
	username varchar(32),
	action_tstamp timestamp with time zone DEFAULT now() NOT NULL,
	action_json text,
	pulse_event_action_code_id bigint,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT pulse_event_action_pk PRIMARY KEY (id),
	CONSTRAINT pulse_event_action_code_fk FOREIGN KEY (pulse_event_action_code_id) REFERENCES pulse_event_action_code (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE pulse_event_action OWNER to pulse;

--
-- TOC entry 175 (class 1259 OID 35923)
-- Name: audit; Type: TABLE; Schema: pulse; Owner: pulse; Tablespace: 
--

-- ATNA Audit Tables
-- based on p277 of this document
-- http://www.ihe.net/uploadedFiles/Documents/ITI/IHE_ITI_TF_Vol2b.pdf

CREATE TABLE event_action_code (
	id bigserial NOT NULL,
	code varchar(2),
	description varchar(20),
	CONSTRAINT event_action_code_pk PRIMARY KEY (id)
);
ALTER TABLE event_action_code OWNER to pulse;

CREATE TABLE network_access_point_type_code (
	id bigserial NOT NULL,
	code varchar(2),
	description varchar(20),
	CONSTRAINT network_access_point_type_code_pk PRIMARY KEY (id)
);
ALTER TABLE network_access_point_type_code OWNER TO pulse;

CREATE TABLE participant_object_type_code (
	id bigserial NOT NULL,
	code varchar(2),
	description varchar(20),
	CONSTRAINT participant_object_type_code_pk PRIMARY KEY (id)
);
ALTER TABLE participant_object_type_code OWNER TO pulse;

CREATE TABLE participant_object_type_code_role (
	id bigserial NOT NULL,
	code varchar(2),
	description varchar(20),
	CONSTRAINT participant_object_type_code_role_pk PRIMARY KEY (id)
);
ALTER TABLE participant_object_type_code_role OWNER TO pulse;

CREATE TABLE audit_request_source (
	id bigserial NOT NULL,
	user_id varchar(50),
	alternative_user_id varchar(100), --the process ID as used within the local operating system in the local system logs
	user_name varchar(100),
	user_is_requestor boolean default true,
	role_id_code varchar(100), -- EV(110153, DCM, "Source")
	network_access_point_type_code_id bigint, --"1" for machine (DNS) name, "2" for IP address
	network_access_point_id varchar(255), --the machine name or IP address.
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT audit_request_source_pk PRIMARY KEY (id),
	CONSTRAINT network_access_point_type_code_fk FOREIGN KEY (network_access_point_type_code_id) REFERENCES network_access_point_type_code (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE audit_request_source OWNER TO pulse;

CREATE TABLE audit_human_requestor (
	id bigserial NOT NULL,
	audit_event_id bigint NOT NULL,
	user_id varchar(50),
	alternative_user_id varchar(100),
	user_name varchar(100),
	user_is_requestor boolean default true,
	role_id_code varchar(100),
	network_access_point_type_code_id bigint, --"1" for machine (DNS) name, "2" for IP address
	network_access_point_id varchar(255), --the machine name or IP address.
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT audit_human_requestor_pk PRIMARY KEY (id),
	CONSTRAINT network_access_point_type_code_fk FOREIGN KEY (network_access_point_type_code_id) REFERENCES network_access_point_type_code (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE audit_human_requestor OWNER TO pulse;

CREATE TABLE audit_request_destination (
	id bigserial NOT NULL,
	user_id varchar(50), --SOAP endpoint URI
	alternative_user_id varchar(100),
	user_name varchar(100),
	user_is_requestor boolean default false,
	role_id_code varchar(100), -- EV(110152, DCM, "Destination")
	network_access_point_type_code_id bigint, --"1" for machine (DNS) name, "2" for IP address
	network_access_point_id varchar(255), --the machine name or IP address.
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT audit_request_destination_pk PRIMARY KEY (id),
	CONSTRAINT network_access_point_type_code_fk FOREIGN KEY (network_access_point_type_code_id) REFERENCES network_access_point_type_code (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE audit_request_destination OWNER TO pulse;

CREATE TABLE audit_source (
	id bigserial not null,
	audit_source_id varchar(100),
	audit_enterprise_site_id varchar(100),
	audit_source_type_code varchar(100),
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT audit_source_id PRIMARY KEY (id)
);
ALTER TABLE audit_source OWNER TO pulse;

CREATE TABLE audit_patient (
	id bigserial not null,
	participant_object_type_code_id bigint NOT NULL, -- "1" (Person)
	participant_object_type_code_role_id bigint NOT NULL, -- "1" (Patient)
	participant_object_data_lifecycle varchar(100),
	participant_object_id_type_code varchar(100),
	participant_object_sensitivity varchar(100),
	participant_object_id varchar(100), -- The patient ID in HL7 CX format (see ITI TF-2x: appendix E).
	participant_object_name varchar(250),
	participant_object_query varchar(250),
	participant_object_detail varchar(500),
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT audit_patient_pk PRIMARY KEY (id),
	CONSTRAINT participant_object_type_code_fk FOREIGN KEY (participant_object_type_code_id) REFERENCES participant_object_type_code (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT participant_object_type_code_role_fk FOREIGN KEY (participant_object_type_code_role_id) REFERENCES participant_object_type_code_role (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE audit_patient OWNER TO pulse;

CREATE TABLE audit_document (
	id bigserial not null,
	audit_event_id bigint,
	participant_object_type_code_id bigint NOT NULL, -- "2" (System)
	participant_object_type_code_role_id bigint NOT NULL, -- "3" (Report)
	participant_object_data_lifecycle varchar(100),
	participant_object_id_type_code varchar(100),
	participant_object_sensitivity varchar(100),
	participant_object_id varchar(100), -- The value of <ihe:DocumentUniqueId/>
	participant_object_name varchar(250),
	participant_object_query varchar(250),
	participant_object_detail varchar(500), -- The ParticipantObjectDetail element may occur more than once.
											-- In one element, the value of <ihe:RepositoryUniqueId/> in value
											-- attribute, “Repository Unique Id” in type attribute
											-- In another element, the value of “ihe:homeCommunityID” as the value
											-- of the attribute type and the value of the homeCommunityID as the
											-- value of the attribute value
	participant_object_detail_two varchar(500),
	CONSTRAINT audit_document_pk PRIMARY KEY (id),
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT participant_object_type_code_fk FOREIGN KEY (participant_object_type_code_id) REFERENCES participant_object_type_code (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT participant_object_type_code_role_fk FOREIGN KEY (participant_object_type_code_role_id) REFERENCES participant_object_type_code_role (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE audit_document OWNER TO pulse;

CREATE TABLE audit_query_parameters (
	id bigserial not null,
	participant_object_type_code_id bigint NOT NULL, -- "2" (system object)
	participant_object_type_code_role_id bigint NOT NULL, -- "24" (query)
	participant_object_data_lifecycle varchar(100),
	participant_object_id_type_code varchar(100), --  EV("ITI-47", "IHE Transactions", "Patient Demographics Query")
	participant_object_sensitivity varchar(100),
	participant_object_id varchar(100), 
	participant_object_name varchar(250),
	participant_object_query text, -- the QueryByParameter segment of the query, base64 encoded
	participant_object_detail varchar(500),
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT audit_query_parameters_pk PRIMARY KEY (id),
	CONSTRAINT participant_object_type_code_fk FOREIGN KEY (participant_object_type_code_id) REFERENCES participant_object_type_code (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT participant_object_type_code_role_fk FOREIGN KEY (participant_object_type_code_role_id) REFERENCES participant_object_type_code_role (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE audit_query_parameters OWNER TO pulse;

CREATE TABLE audit_event (
	id bigserial NOT NULL,
	event_id varchar(100),
	event_action_code_id bigint,
	event_date_time varchar(100),
	event_outcome_indicator varchar(25),
	event_type_code varchar(100),
	audit_request_source_id bigint,
	audit_request_destination_id bigint,
	audit_source_id bigint,
	audit_query_parameters_id bigint, 
	audit_patient_id bigint,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT audit_event_pk PRIMARY KEY (id),
	CONSTRAINT audit_request_source_fk FOREIGN KEY (audit_request_source_id) REFERENCES audit_request_source (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT audit_request_destination_fk FOREIGN KEY (audit_request_destination_id) REFERENCES audit_request_destination (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT audit_source_fk FOREIGN KEY (audit_source_id) REFERENCES audit_source (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT audit_query_parameters_fk FOREIGN KEY (audit_query_parameters_id) REFERENCES audit_query_parameters (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT audit_patient_fk FOREIGN KEY (audit_patient_id) REFERENCES audit_patient (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE audit_event OWNER TO pulse;

CREATE TABLE audit_event_human_requestor_map ( -- can have 0 to many per audit event
	id bigserial NOT NULL,
	audit_event_id bigint NOT NULL,
	audit_human_requestor_id bigint NOT NULL,
	CONSTRAINT audit_event_human_requestor_map_pk UNIQUE (audit_event_id, audit_human_requestor_id),
	CONSTRAINT audit_event_fk FOREIGN KEY (audit_event_id) REFERENCES audit_event (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT audit_human_requestor_fk FOREIGN KEY (audit_human_requestor_id) REFERENCES audit_human_requestor (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE audit_event_human_requestor_map OWNER TO pulse;


CREATE TABLE audit_event_patient_map ( -- can have 0 to many per audit event
	id bigserial NOT NULL,
	audit_event_id bigint NOT NULL,
	audit_patient_id bigint NOT NULL,
	CONSTRAINT audit_event_patient_map_pk UNIQUE (audit_event_id, audit_patient_id),
	CONSTRAINT audit_event_fk FOREIGN KEY (audit_event_id) REFERENCES audit_event (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT audit_patient_fk FOREIGN KEY (audit_patient_id) REFERENCES audit_patient (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE audit_event_patient_map OWNER TO pulse;

--
-- END Audit Tables
--

CREATE TABLE location_status (
	id bigserial NOT NULL,
	name varchar(50) NOT NULL,
	last_modified_date timestamp without time zone NOT NULL DEFAULT now(),
	creation_date timestamp without time zone NOT NULL DEFAULT now(),
	CONSTRAINT location_status_pk PRIMARY KEY (id),
	CONSTRAINT location_status_name_key UNIQUE (name)
);
ALTER TABLE location_status OWNER TO pulse;

CREATE TABLE endpoint_status (
	id bigserial NOT NULL,
	name varchar(50) NOT NULL,
	last_modified_date timestamp without time zone NOT NULL DEFAULT now(),
	creation_date timestamp without time zone NOT NULL DEFAULT now(),
	CONSTRAINT endpoint_status_pk PRIMARY KEY (id),
	CONSTRAINT endpoint_status_name_key UNIQUE (name)
);
ALTER TABLE location_status OWNER TO pulse;

CREATE TABLE endpoint_type (
	id bigserial NOT NULL,
	name varchar(100) NOT NULL,
	code varchar(25) NOT NULL,
	last_modified_date timestamp without time zone NOT NULL DEFAULT now(),
	creation_date timestamp without time zone NOT NULL DEFAULT now(),
	CONSTRAINT endpoint_type_pk PRIMARY KEY (id),
	CONSTRAINT endpoint_name_key UNIQUE (name)
);
ALTER TABLE endpoint_type OWNER TO pulse;

CREATE TABLE location (
	id bigserial NOT NULL,
	external_id varchar(16) NOT NULL, -- the id we get from CTEN
	location_status_id bigint NOT NULL,
	parent_organization_name varchar(255) NOT NULL,
  	name varchar(128) NOT NULL,
	description varchar(500),
	location_type varchar(50), --Hospital or whatever
	city character varying(250),
	state character varying(100),
	zipcode character varying(100),
	location_last_updated timestamp without time zone, -- lastupdated field
  	last_modified_date timestamp without time zone NOT NULL DEFAULT now(),
  	creation_date timestamp without time zone NOT NULL DEFAULT now(),
  	CONSTRAINT location_pk PRIMARY KEY (id),
	CONSTRAINT location_status_fk FOREIGN KEY (location_status_id)
		REFERENCES location_status (id)
		MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE
);
ALTER TABLE location OWNER TO pulse;

CREATE TABLE location_address_line (
	id bigserial not null,
	location_id bigint not null,
	line varchar(128) not null,
	line_order int not null default 1,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT location_address_line_pk PRIMARY KEY (id),
	CONSTRAINT location_address_line_key UNIQUE (location_id, line),
	CONSTRAINT location_fk FOREIGN KEY (location_id) 
		REFERENCES location (id) 
		MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE		
);
ALTER TABLE location_address_line OWNER TO pulse;

CREATE TABLE endpoint (
	id bigserial NOT NULL,
	external_id varchar(16) NOT NULL, -- the id we get from CTEN
	endpoint_type_id bigint NOT NULL,
	endpoint_status_id bigint NOT NULL,
  	adapter character varying(128) NOT NULL, -- always eHealth?
	payload_type varchar(512), -- HL7 CCDA Document
	payload_mime_type varchar(128), -- application/xml
  	public_key character varying(2048), -- publicKey
  	endpoint_url character varying(256), -- url (address field)
	endpoint_last_updated timestamp without time zone, -- lastupdated field
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT endpoint_pk PRIMARY KEY (id),
	CONSTRAINT endpoint_type_fk FOREIGN KEY (endpoint_type_id) 
		REFERENCES endpoint_type (id) 
		MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT endpoint_status_fk FOREIGN KEY (endpoint_status_id)
		REFERENCES endpoint_status (id)
		MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE
);
ALTER TABLE endpoint OWNER TO pulse;

CREATE TABLE endpoint_mime_type (
	id bigserial NOT NULL,
	endpoint_id bigint NOT NULL,
	payload_mime_type varchar(128), -- application/xml
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT endpoint_mime_type_pk PRIMARY KEY (id),
	CONSTRAINT endpoint_fk FOREIGN KEY (endpoint_id)
		REFERENCES endpoint(id)
		MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE endpoint_mime_type OWNER TO pulse;

CREATE TABLE location_endpoint_map (
	id bigserial NOT NULL,
	endpoint_id bigint NOT NULL,
	location_id bigint NOT NULL,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT location_endpoint_map_pk PRIMARY KEY (id),
	CONSTRAINT endpoint_fk FOREIGN KEY (endpoint_id)
		REFERENCES endpoint (id)
		MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT location_fk FOREIGN KEY (location_id)
		REFERENCES location (id)
		MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE location_endpoint_map OWNER TO pulse;

CREATE TABLE alternate_care_facility (
	id bigserial not null,
	identifier varchar(500) not null,
	name varchar(500),
	phone_number varchar(50),
	city character varying(250),
	state character varying(100),
	zipcode character varying(100),
	last_read_date timestamp without time zone default now() not null,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT alternate_care_facility_pk PRIMARY KEY (id),
	CONSTRAINT identifier_key UNIQUE (identifier)
);

CREATE TABLE alternate_care_facility_address_line (
	id bigserial not null,
	alternate_care_facility_id bigint not null,
	line varchar(128) not null,
	line_order int not null default 1,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT alternate_care_facility_address_line_pk PRIMARY KEY (id),
	CONSTRAINT acf_line_key UNIQUE (alternate_care_facility_id, line),
	CONSTRAINT alternate_care_facility_fk FOREIGN KEY (alternate_care_facility_id) 
		REFERENCES alternate_care_facility (id) 
		MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE		
);

CREATE TABLE query_status (
	id bigserial not null,
	status varchar(30) not null,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT query_status_pk PRIMARY KEY (id)
);
ALTER TABLE query_status OWNER to pulse;
	
CREATE TABLE query_endpoint_status (
	id bigserial not null,
	status varchar(30) not null,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT query_endpoint_status_pk PRIMARY KEY (id)
);
ALTER TABLE query_endpoint_status OWNER to pulse;
		
CREATE TABLE name_type (
	id bigserial not null,
	code varchar(1),
	description varchar(100),
	CONSTRAINT name_type_pk PRIMARY KEY (id)
);
ALTER TABLE name_type OWNER TO pulse;

CREATE TABLE name_representation (
	id bigserial not null,
	code varchar(1),
	description varchar(100),
	CONSTRAINT name_representation_pk PRIMARY KEY (id)
);
ALTER TABLE name_representation OWNER TO pulse;

CREATE TABLE name_assembly (
	id bigserial not null,
	code varchar(1),
	description varchar(100),
	CONSTRAINT name_assembly_pk PRIMARY KEY (id)
);
ALTER TABLE name_assembly OWNER TO pulse;

CREATE TABLE patient (
	id bigserial not null,
	full_name varchar(255) not null,
	friendly_name varchar(128),
	dob varchar(100),
	ssn varchar(15),
	gender varchar(10),
	alternate_care_facility_id bigint,
	last_read_date timestamp without time zone default now() not null,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT patient_pk PRIMARY KEY (id),
	CONSTRAINT acf_fk FOREIGN KEY (alternate_care_facility_id) REFERENCES alternate_care_facility (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE

);
ALTER TABLE patient OWNER TO pulse;

CREATE TABLE patient_gender (
	id bigserial not null,
	code varchar(2) not null,
	description varchar(100),
	CONSTRAINT patient_gender_pk PRIMARY KEY (id)
);
ALTER TABLE patient_gender OWNER to pulse;

-- 'query' in the database only refers to patient discovery queries 
-- in the future, would like to refactor this to include all the queries with a 'type' column to indicate
-- patient discovery, document discovery, document retrieval
CREATE TABLE query (
	id bigserial not null,
	user_id varchar(1024) not null,
	query_status_id bigint not null,
	terms text,
	last_read_date timestamp without time zone default now() not null,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT query_pk PRIMARY KEY (id),
	CONSTRAINT query_status_fk FOREIGN KEY (query_status_id) REFERENCES	
		query_status (id) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE
);
ALTER TABLE query OWNER to pulse;

CREATE TABLE query_endpoint_map (
	id bigserial not null,
	query_id bigint not null,
	endpoint_id bigint not null,
	query_endpoint_status_id bigint not null,
	start_date timestamp without time zone default now() not null,
	end_date timestamp without time zone,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT query_endpoint_map_pk PRIMARY KEY (id),
	CONSTRAINT query_fk FOREIGN KEY (query_id) REFERENCES query (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT endpoint_fk FOREIGN KEY (endpoint_id) REFERENCES endpoint (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT query_endpoint_status_fk FOREIGN KEY (query_endpoint_status_id) REFERENCES	
		query_endpoint_status (id) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE
);
ALTER TABLE query_endpoint_map OWNER to pulse;

CREATE TABLE patient_record (
	id bigserial not null,
	dob varchar(100),
	ssn varchar(15),
	patient_gender_id bigint not null,
	endpoint_patient_record_id varchar(1024),
	phone_number varchar(100),
	query_endpoint_map_id bigint,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT patient_record_pk PRIMARY KEY (id),
	CONSTRAINT patient_gender_fk FOREIGN KEY (patient_gender_id) REFERENCES patient_gender (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT query_endpoint_map_fk FOREIGN KEY (query_endpoint_map_id) REFERENCES query_endpoint_map (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE patient_record OWNER TO pulse;

CREATE TABLE patient_record_address(
  id bigserial NOT NULL,
  patient_record_id bigint not null,
  city character varying(250),
  state character varying(100),
  zipcode character varying(100),
  creation_date timestamp without time zone NOT NULL DEFAULT now(),
  last_modified_date timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT patient_record_id_fk FOREIGN KEY (patient_record_id) REFERENCES patient_record (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT patient_record_address_pk PRIMARY KEY (id)
);
ALTER TABLE patient_record_address OWNER TO pulse;

CREATE TABLE patient_record_address_line (
	id bigserial not null,
	patient_record_address_id bigint not null,
	line varchar(128) not null,
	line_order int not null default 1,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT patient_record_address_line_pk PRIMARY KEY (id),
	CONSTRAINT patient_record_address_line_key UNIQUE (patient_record_address_id, line),
	CONSTRAINT patient_record_address_fk FOREIGN KEY (patient_record_address_id) 
		REFERENCES patient_record_address (id) 
		MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE		
);
ALTER TABLE patient_record_address_line OWNER TO pulse;


CREATE TABLE patient_endpoint_map (
    id bigserial not null,
    patient_id bigint not null,
    endpoint_id bigint not null,
    endpoint_patient_record_id varchar(1024) not null,
    documents_query_status_id bigint not null, 
    documents_query_start timestamp without time zone default now() not null,
    documents_query_end timestamp without time zone,
    last_modified_date timestamp without time zone default now() not null,
    creation_date timestamp without time zone default now() not null,
    CONSTRAINT patient_location_map_pk PRIMARY KEY (id),
    CONSTRAINT patient_fk FOREIGN KEY (patient_id) REFERENCES patient (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT endpoint_fk FOREIGN KEY (endpoint_id) REFERENCES endpoint (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT documents_query_status_fk FOREIGN KEY (documents_query_status_id) REFERENCES    
        query_endpoint_status (id) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE document (
	id bigserial not null,
	patient_endpoint_map_id bigint not null,
	status_id bigint, -- can be null if no one has tried to retrieve it yet
	name varchar(500) not null,
	format varchar(100),
	contents bytea,
	class_name varchar(150),
	confidentiality varchar(150),
	description varchar(500),
	size varchar(10),
	doc_creation_time varchar(100),
	home_community_id varchar(100),
	repository_unique_id varchar(100),
	document_unique_id varchar(100),
	last_read_date timestamp without time zone default now() not null,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT document_pk PRIMARY KEY (id),
	CONSTRAINT patient_endpoint_map_fk FOREIGN KEY (patient_endpoint_map_id) REFERENCES patient_endpoint_map (id) MATCH FULL 
		ON DELETE CASCADE ON UPDATE CASCADE,
	 CONSTRAINT status_fk FOREIGN KEY (status_id) REFERENCES    
        query_endpoint_status (id) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE
);
ALTER TABLE document OWNER TO pulse;

CREATE TABLE patient_record_name (
	id bigserial not null,
	patient_record_id bigint not null,
	name_type_id bigint not null,
	family_name varchar(200) not null,
	name_representation_id bigint,
	name_assembly_id bigint,
	suffix varchar(30),
	prefix varchar(30),
	prof_suffix varchar(30),
	effective_date date,
	expiration_date date,
	last_read_date timestamp without time zone default now() not null,
	last_modified_date timestamp without time zone default now() not null,
	creation_date timestamp without time zone default now() not null,
	CONSTRAINT patient_record_name_pk PRIMARY KEY (id),
	CONSTRAINT patient_record_id_fk FOREIGN KEY (patient_record_id) REFERENCES patient_record (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT name_type_fk FOREIGN KEY (name_type_id) REFERENCES name_type (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT name_representation_fk FOREIGN KEY (name_representation_id) REFERENCES name_representation (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT name_assembly_fk FOREIGN KEY (name_assembly_id) REFERENCES name_assembly (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE patient_record_name OWNER TO pulse;

CREATE TABLE given_name (
	id bigserial not null,
	name varchar(100),
	patient_record_name_id bigint not null,
	CONSTRAINT given_record_name_pk PRIMARY KEY (id),
	CONSTRAINT patient_record_name_fk FOREIGN KEY (patient_record_name_id) REFERENCES patient_record_name (id) MATCH FULL ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE given_name OWNER TO pulse;

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

CREATE TRIGGER pulse_event_action_audit AFTER INSERT OR DELETE OR UPDATE ON pulse_event_action FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER pulse_event_action_timestamp BEFORE UPDATE ON pulse_event_action FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER patient_record_address_audit AFTER INSERT OR DELETE OR UPDATE ON patient_record_address FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER patient_record_address_timestamp BEFORE UPDATE ON patient_record_address FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER patient_record_address_line_audit AFTER INSERT OR DELETE OR UPDATE ON patient_record_address_line FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER patient_record_address_line_timestamp BEFORE UPDATE ON patient_record_address_line FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER patient_gender_audit AFTER INSERT OR DELETE OR UPDATE ON patient_gender FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER patient_gender_timestamp BEFORE UPDATE ON patient_gender FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER patient_record_name_audit AFTER INSERT OR DELETE OR UPDATE ON patient_record_name FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER patient_record_name_timestamp BEFORE UPDATE ON patient_record_name FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER name_assembly_audit AFTER INSERT OR DELETE OR UPDATE ON name_assembly FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER name_assembly_timestamp BEFORE UPDATE ON name_assembly FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER name_representation_audit AFTER INSERT OR DELETE OR UPDATE ON name_representation FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER name_representation_timestamp BEFORE UPDATE ON name_representation FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER name_type_audit AFTER INSERT OR DELETE OR UPDATE ON name_type FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER name_type_timestamp BEFORE UPDATE ON name_type FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER given_name_audit AFTER INSERT OR DELETE OR UPDATE ON given_name FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER given_name_timestamp BEFORE UPDATE ON given_name FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER audit_event_audit AFTER INSERT OR DELETE OR UPDATE ON audit_event FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_event_timestamp AFTER INSERT OR DELETE OR UPDATE ON audit_event FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_source_audit AFTER INSERT OR DELETE OR UPDATE ON audit_source FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_source_timestamp AFTER INSERT OR DELETE OR UPDATE ON audit_source FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_request_source_audit AFTER INSERT OR DELETE OR UPDATE ON audit_request_source FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_request_source_timestamp AFTER INSERT OR DELETE OR UPDATE ON audit_request_source FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_request_destination_audit AFTER INSERT OR DELETE OR UPDATE ON audit_request_destination FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_request_destination_timestamp AFTER INSERT OR DELETE OR UPDATE ON audit_request_destination FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_query_parameters_audit AFTER INSERT OR DELETE OR UPDATE ON audit_query_parameters FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_query_parameters_timestamp AFTER INSERT OR DELETE OR UPDATE ON audit_query_parameters FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_patient_audit AFTER INSERT OR DELETE OR UPDATE ON audit_patient FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_patient_timestamp AFTER INSERT OR DELETE OR UPDATE ON audit_patient FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_human_requestor_audit AFTER INSERT OR DELETE OR UPDATE ON audit_human_requestor FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_human_requestor_timestamp AFTER INSERT OR DELETE OR UPDATE ON audit_human_requestor FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_document_audit AFTER INSERT OR DELETE OR UPDATE ON audit_document FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER audit_document_timestamp AFTER INSERT OR DELETE OR UPDATE ON audit_document FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER location_audit AFTER INSERT OR DELETE OR UPDATE ON location FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER location_timestamp BEFORE UPDATE ON location FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER location_address_line_audit AFTER INSERT OR DELETE OR UPDATE ON location_address_line FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER location_address_line_timestamp BEFORE UPDATE ON location_address_line FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER endpoint_audit AFTER INSERT OR DELETE OR UPDATE ON endpoint FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER endpoint_timestamp BEFORE UPDATE ON endpoint FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER endpoint_mime_type_audit AFTER INSERT OR DELETE OR UPDATE ON endpoint_mime_type FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER endpoint_mime_type_timestamp BEFORE UPDATE ON endpoint_mime_type FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER location_endpoint_map_audit AFTER INSERT OR DELETE OR UPDATE ON location_endpoint_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER location_endpoint_map_timestamp BEFORE UPDATE ON location_endpoint_map FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER patient_audit AFTER INSERT OR DELETE OR UPDATE ON patient FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER patient_timestamp BEFORE UPDATE ON patient FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER patient_endpoint_map_audit AFTER INSERT OR DELETE OR UPDATE ON patient_endpoint_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER patient_endpoint_map_timestamp BEFORE UPDATE ON patient_endpoint_map FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER document_audit AFTER INSERT OR DELETE OR UPDATE ON document FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER document_timestamp BEFORE UPDATE ON document FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER query_audit AFTER INSERT OR DELETE OR UPDATE ON query FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER query_timestamp BEFORE UPDATE ON query FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER query_status_audit AFTER INSERT OR DELETE OR UPDATE ON query_status FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER query_status_timestamp BEFORE UPDATE ON query_status FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER query_endpoint_map_audit AFTER INSERT OR DELETE OR UPDATE ON query_endpoint_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER query_endpoint_map_timestamp BEFORE UPDATE ON query_endpoint_map FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER query_endpoint_status_audit AFTER INSERT OR DELETE OR UPDATE ON query_endpoint_status FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER query_endpoint_status_timestamp BEFORE UPDATE ON query_endpoint_status FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER patient_record_audit AFTER INSERT OR DELETE OR UPDATE ON patient_record FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER patient_record_timestamp BEFORE UPDATE ON patient_record FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER alternate_care_facility_audit AFTER INSERT OR DELETE OR UPDATE ON alternate_care_facility FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER alternate_care_facility_timestamp BEFORE UPDATE ON alternate_care_facility FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();
CREATE TRIGGER alternate_care_facility_address_line_audit AFTER INSERT OR DELETE OR UPDATE ON alternate_care_facility_address_line FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
CREATE TRIGGER alternate_care_facility_address_line_timestamp BEFORE UPDATE ON alternate_care_facility_address_line FOR EACH ROW EXECUTE PROCEDURE update_last_modified_date_column();

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