DROP DATABASE IF EXISTS pulse;

CREATE DATABASE pulse
  WITH OWNER = pulse
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       CONNECTION LIMIT = -1;

DROP DATABASE IF EXISTS pulse_test;

CREATE DATABASE pulse_test
  WITH OWNER = pulse
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       CONNECTION LIMIT = -1;
