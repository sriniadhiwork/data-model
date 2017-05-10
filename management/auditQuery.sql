DO $$
BEGIN
raise notice 'ATNA Standard Event Audit Records';
END; 
$$;

SELECT 
-- audit event fields
event.id, event.event_id, event.event_action_code_id, event.event_date_time,
event.event_outcome_indicator, event.event_type_code, 
-- request source fields
request_source.user_id as src_user_id,
request_source.alternative_user_id as src_alternative_user_id,
request_source.user_name as src_user_name,
request_source.user_is_requestor as src_user_is_requestor,
request_source.role_id_code as src_role_id_code,
request_source.network_access_point_type_code_id as src_network_access_point_type_code_id,
request_source.network_access_point_id as src_network_access_point_id,
--request destination fields
request_dest.user_id as src_user_id,
request_dest.alternative_user_id as src_alternative_user_id,
request_dest.user_name as src_user_name,
request_dest.user_is_requestor as src_user_is_requestor,
request_dest.role_id_code as src_role_id_code,
request_dest.network_access_point_type_code_id as src_network_access_point_type_code_id,
request_dest.network_access_point_id as src_network_access_point_id,
-- who made the request
requestor.user_id as requestor_user_id,
requestor.alternative_user_id as src_alternative_user_id,
requestor.user_name as src_user_name,
requestor.user_is_requestor as src_user_is_requestor,
requestor.role_id_code as src_role_id_code,
requestor.network_access_point_type_code_id as src_network_access_point_type_code_id,
requestor.network_access_point_id as src_network_access_point_id, 
-- what was in the request
query_params.participant_object_type_code_id as queryparams_participant_object_type_code_id, 
query_params.participant_object_type_code_role_id as queryparams_participant_object_type_code_role_id,
query_params.participant_object_data_lifecycle as queryparams_participant_object_data_lifecycle, 
query_params.participant_object_id_type_code as queryparams_participant_object_id_type_code,
query_params.participant_object_sensitivity as queryparams_participant_object_sensitivity, 
query_params.participant_object_id as queryparams_participant_object_id,
pgp_pub_decrypt(query_params.participant_object_name_enc, dearmor((SELECT * from private_key()))) as queryparams_participant_object_name,
pgp_pub_decrypt(query_params.participant_object_query_enc, dearmor((SELECT * from private_key()))) as queryparams_participant_object_query_base64enc,
pgp_pub_decrypt(query_params.participant_object_detail_enc, dearmor((SELECT * from private_key()))) as queryparams_participant_object_detail,
--info about the patient
patient.participant_object_type_code_id as patient_participant_object_type_code_id, 
patient.participant_object_type_code_role_id as patient_participant_object_type_code_role_id,
patient.participant_object_data_lifecycle as patient_participant_object_data_lifecycle, 
patient.participant_object_id_type_code as patient_participant_object_id_type_code,
patient.participant_object_sensitivity as patient_participant_object_sensitivity, 
patient.participant_object_id as patient_participant_object_id,
pgp_pub_decrypt(patient.participant_object_name_enc, dearmor((SELECT * from private_key()))) as patient_participant_object_name,
pgp_pub_decrypt(patient.participant_object_query_enc, dearmor((SELECT * from private_key()))) as patient_participant_object_query_base64enc,
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
ORDER BY event.creation_date asc;


DO $$
BEGIN
raise notice 'PULSE Internal Event Audit Records';
END; 
$$;

SELECT 
action.username,
action_code.code,
action_code.description,
action.action_tstamp,
pgp_pub_decrypt(action.action_json_enc, dearmor((SELECT * from private_key()))) as action_json
FROM pulse.pulse_event_action action
LEFT OUTER JOIN pulse.pulse_event_action_code action_code ON action.pulse_event_action_code_id = action_code.id
ORDER BY action.creation_date asc;


