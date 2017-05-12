CREATE TEMPORARY VIEW audit_patient_stage
AS
(SELECT 
action.username,
action_code.code,
action_code.description,
parsed_json.acf_json::json->'identifier' as acf_identifier,
parsed_json.acf_json::json->'name' as acf_name,
parsed_json.decrypted_json::json->>'fullName' as staged_patient_full_name,
parsed_json.decrypted_json::json->>'friendlyName' as staged_patient_friendly_name,
parsed_json.decrypted_json::json->>'dateOfBirth' as staged_patient_dob,
parsed_json.decrypted_json::json->>'gender' as staged_patient_gender,
parsed_json.decrypted_json::json->>'phoneNumber' as staged_patient_phone_number,
parsed_json.decrypted_json::json->>'ssn' as staged_patient_ssn,
action.action_tstamp
FROM pulse.pulse_event_action action
JOIN (SELECT 
	action.id,
	pgp_pub_decrypt(action.action_json_enc, dearmor((SELECT * from private_key()))) as decrypted_json,
	pgp_pub_decrypt(action.action_json_enc, dearmor((SELECT * from private_key())))::json->'acf' as acf_json
	FROM pulse.pulse_event_action action) as parsed_json ON action.id = parsed_json.id
LEFT OUTER JOIN pulse.pulse_event_action_code action_code ON action.pulse_event_action_code_id = action_code.id
WHERE code = 'PC'
AND action.creation_date >= to_timestamp(:'startDate'||' 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
AND action.creation_date <= to_timestamp(:'endDate'||' 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
ORDER BY action.creation_date asc);

\copy (SELECT * FROM audit_patient_stage) TO 'patient_stage.csv' DELIMITER ',' CSV HEADER;
