CREATE TEMPORARY VIEW audit_patient_discovery
AS 
(SELECT 
-- audit event fields
event.id, event.event_id, event.event_action_code_id, event.event_date_time,
event.event_outcome_indicator, event.event_type_code,
-- request source fields
request_source.user_id as request_source_src_user_id,
request_source.alternative_user_id as request_source_src_alternative_user_id,
request_source.user_name as request_source_src_user_name,
request_source.user_is_requestor as request_source_src_user_is_requestor,
request_source.role_id_code as request_source_src_role_id_code,
request_source.network_access_point_type_code_id as request_source_src_network_access_point_type_code_id,
request_source.network_access_point_id as request_source_src_network_access_point_id,
--request destination fields
request_dest.user_id as request_dest_src_user_id,
request_dest.alternative_user_id as request_dest_src_alternative_user_id,
request_dest.user_name as request_dest_src_user_name,
request_dest.user_is_requestor as request_dest_src_user_is_requestor,
request_dest.role_id_code as request_dest_src_role_id_code,
request_dest.network_access_point_type_code_id as request_dest_src_network_access_point_type_code_id,
request_dest.network_access_point_id as request_dest_src_network_access_point_id,
-- who made the request
requestor.user_id as requestor_user_id,
requestor.alternative_user_id as requestor_alternative_user_id,
requestor.user_name as requestor_user_name,
requestor.user_is_requestor as requestor_user_is_requestor,
requestor.role_id_code as requestor_role_id_code,
requestor.network_access_point_type_code_id as requestor_network_access_point_type_code_id,
requestor.network_access_point_id as requestor_network_access_point_id, 
-- what was in the request
query_params.participant_object_type_code_id as queryparams_participant_object_type_code_id, 
query_params.participant_object_type_code_role_id as queryparams_participant_object_type_code_role_id,
query_params.participant_object_data_lifecycle as queryparams_participant_object_data_lifecycle, 
query_params.participant_object_id_type_code as queryparams_participant_object_id_type_code,
query_params.participant_object_sensitivity as queryparams_participant_object_sensitivity, 
query_params.participant_object_id as queryparams_participant_object_id,
pgp_pub_decrypt(query_params.participant_object_name_enc, dearmor((SELECT * from private_key()))) as queryparams_participant_object_name,
CONVERT_FROM(
	DECODE(pgp_pub_decrypt(query_params.participant_object_query_enc, dearmor((SELECT * from private_key()))), 'BASE64'), 
	'UTF-8') as queryparams_participant_object_query, --decrypts value into base64 then decode into UTF-8 so it's readable
pgp_pub_decrypt(query_params.participant_object_detail_enc, dearmor((SELECT * from private_key()))) as queryparams_participant_object_detail,
--info about the patient
patient.participant_object_type_code_id as patient_participant_object_type_code_id, 
patient.participant_object_type_code_role_id as patient_participant_object_type_code_role_id,
patient.participant_object_data_lifecycle as patient_participant_object_data_lifecycle, 
patient.participant_object_id_type_code as patient_participant_object_id_type_code,
patient.participant_object_sensitivity as patient_participant_object_sensitivity, 
patient.participant_object_id as patient_participant_object_id,
pgp_pub_decrypt(patient.participant_object_name_enc, dearmor((SELECT * from private_key()))) as patient_participant_object_name,
CONVERT_FROM(
	DECODE(pgp_pub_decrypt(patient.participant_object_query_enc, dearmor((SELECT * from private_key()))), 'BASE64'), 
	'UTF-8') as patient_participant_object_query, --decrypts value into base64 then decode into UTF-8 so it's readable
pgp_pub_decrypt(patient.participant_object_detail_enc, dearmor((SELECT * from private_key()))) as patient_participant_object_detail,
--info about the documents
document.participant_object_type_code_id as document_participant_object_type_code_id, 
document.participant_object_type_code_role_id as document_participant_object_type_code_role_id,
document.participant_object_data_lifecycle as document_participant_object_data_lifecycle, 
document.participant_object_id_type_code as document_participant_object_id_type_code,
document.participant_object_sensitivity as document_participant_object_sensitivity, 
document.participant_object_id as document_participant_object_id,
pgp_pub_decrypt(document.participant_object_name_enc, dearmor((SELECT * from private_key()))) as document_participant_object_name,
pgp_pub_decrypt(document.participant_object_query_enc, dearmor((SELECT * from private_key()))) as document_participant_object_query,
pgp_pub_decrypt(document.participant_object_detail_enc, dearmor((SELECT * from private_key()))) as document_participant_object_detail,
pgp_pub_decrypt(document.participant_object_detail_two_enc, dearmor((SELECT * from private_key()))) as document_participant_object_detail_two,
--audit source
audit_source.audit_enterprise_site_id,
audit_source.audit_source_type_code
FROM pulse.audit_event event
LEFT OUTER JOIN pulse.audit_request_source request_source ON event.audit_request_source_id = request_source.id
LEFT OUTER JOIN pulse.audit_request_destination request_dest ON event.audit_request_destination_id = request_dest.id
LEFT OUTER JOIN pulse.audit_event_human_requestor_map requestor_map ON event.id = requestor_map.audit_event_id
LEFT OUTER JOIN pulse.audit_human_requestor requestor ON requestor.id = requestor_map.audit_human_requestor_id
LEFT OUTER JOIN pulse.audit_query_parameters query_params ON event.audit_query_parameters_id = query_params.id
LEFT OUTER JOIN pulse.audit_event_patient_map patient_map ON event.id = patient_map.audit_event_id
LEFT OUTER JOIN pulse.audit_patient patient ON patient.id = patient_map.audit_patient_id
LEFT OUTER JOIN pulse.audit_document document ON event.id = document.audit_event_id
LEFT OUTER JOIN pulse.audit_source ON event.audit_source_id = audit_source.id
WHERE event.event_type_code = 'EV("ITI-55", "IHE Transactions", "Cross Gateway Patient Discovery")'
AND event.creation_date >= to_timestamp(:'startDate'||' 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
AND event.creation_date <= to_timestamp(:'endDate'||' 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
ORDER BY event.creation_date asc);

\copy (SELECT * from audit_patient_discovery) TO 'patient_discovery.csv' DELIMITER ',' CSV HEADER;
