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

INSERT INTO pulse.alternate_care_facility(name, state)
VALUES('Alameda', 'CA'),
('Alpine', 'CA'),
('Amador', 'CA'),
('Butte', 'CA'),
('Calaveras', 'CA'),
('Colusa', 'CA'),
('Contra Costa', 'CA'),
('Del Norte', 'CA'),
('El Dorado', 'CA'),
('Fresno', 'CA'),
('Glenn', 'CA'),
('Humboldt', 'CA'),
('Imperial', 'CA'),
('Inyo', 'CA'),
('Kern', 'CA'),
('Kings', 'CA'),
('Lake', 'CA'),
('Lassen', 'CA'),
('Los Angeles', 'CA'),
('Madera', 'CA'),
('Marin', 'CA'),
('Mariposa', 'CA'),
('Mendocino', 'CA'),
('Merced', 'CA'),
('Modoc', 'CA'),
('Mono', 'CA'),
('Monterey', 'CA'),
('Napa', 'CA'),
('Nevada', 'CA'),
('Orange', 'CA'),
('Placer', 'CA'),
('Plumas', 'CA'),
('Riverside', 'CA'),
('Sacramento', 'CA'),
('San Benito', 'CA'),
('San Bernardino', 'CA'),
('San Diego', 'CA'),
('San Francisco', 'CA'),
('San Joaquin', 'CA'),
('San Luis Obispo', 'CA'),
('San Mateo', 'CA'),
('Santa Barbara', 'CA'),
('Santa Clara', 'CA'),
('Santa Cruz', 'CA'),
('Shasta', 'CA'),
('Sierra', 'CA'),
('Siskiyou', 'CA'),
('Solano', 'CA'),
('Sonoma', 'CA'),
('Stanislaus', 'CA'),
('Sutter', 'CA'),
('Tehama', 'CA'),
('Trinity', 'CA'),
('Tulare', 'CA'),
('Tuolumne', 'CA'),
('Ventura', 'CA'),
('Yolo', 'CA'),
('Yuba', 'CA');
