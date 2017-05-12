CREATE TEMPORARY VIEW audit_document_view
AS 
(SELECT 
action.username,
action_code.code,
action_code.description,
parsed_json.doc_json::json->'homeCommunityId' as document_home_community_id,
parsed_json.doc_json::json->'repositoryUniqueId' as document_repository_unique_id,
parsed_json.doc_json::json->>'documentUniqueId' as document_unique_id,
parsed_json.decrypted_json::json->>'name' as document_name,
parsed_json.decrypted_json::json->>'format' as document_format,
parsed_json.decrypted_json::json->>'confidentiality' as document_confidentiality,
parsed_json.decrypted_json::json->>'description' as document_description,
parsed_json.decrypted_json::json->>'size' as document_size,
action.action_tstamp
FROM pulse.pulse_event_action action
JOIN (SELECT 
	action.id,
	pgp_pub_decrypt(action.action_json_enc, dearmor((SELECT * from private_key()))) as decrypted_json,
	pgp_pub_decrypt(action.action_json_enc, dearmor((SELECT * from private_key())))::json->'documentIdentifier' as doc_json
	FROM pulse.pulse_event_action action) as parsed_json ON action.id = parsed_json.id
LEFT OUTER JOIN pulse.pulse_event_action_code action_code ON action.pulse_event_action_code_id = action_code.id
WHERE code = 'DV'
AND action.creation_date >= to_timestamp(:'startDate'||' 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
AND action.creation_date <= to_timestamp(:'endDate'||' 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
ORDER BY action.creation_date asc);

\copy (SELECT * from audit_document_view) TO 'document_view.csv' DELIMITER ',' CSV HEADER;
