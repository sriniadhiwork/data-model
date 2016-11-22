INSERT INTO pulse.location_status (name)
VALUES ('Active'), ('Inactive');

INSERT INTO pulse.endpoint_status (name)
VALUES ('Active'), ('Inactive');

INSERT INTO pulse.endpoint_type (name)
VALUES ('Patient Discovery'), ('Query for Documents'), ('Retrieve Documents');

INSERT INTO pulse.query_location_status (status)
VALUES ('Active'), ('Successful'), ('Cancelled'), ('Failed');

INSERT INTO pulse.name_representation (code, description)
VALUES ('A', 'Alphabetic (i.e. Default or some single-byte)'),
	('I', 'Ideographic (i.e. Kanji)'),
	('P', 'Phonetic (i.e. ASCII, Katakana, Hiragana, etc.)');

INSERT INTO pulse.name_type (code, description)
VALUES ('A', 'Alias Name'), ('B', 'Name at Birth'), ('C', 'Adopted Name'),
	('D', 'Display Name'), ('I', 'Licensing Name'), ('L', 'Legal Name'),
	('M', 'Maiden Name'), ('N', 'Nickname/"Call me" Name/Street Name'),
	('S', 'Coded Pseudo-Name to ensure anonymity'),
	('T', 'Indigenous/Tribal/Community Name'), ('U', 'Unspecified');

INSERT INTO pulse.name_assembly (code, description)
VALUES('F', 'Prefix Family Middle Given Suffix'),
('G', 'Prefix Given Middle Family Suffix');

INSERT INTO pulse.patient_gender (code, description)
VALUES('F', 'Female'),
('M', 'Male'),
('UN', 'Undifferentiated');