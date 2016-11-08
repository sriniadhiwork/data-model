DROP VIEW IF EXISTS pulse.patient_discovery_query_stats;
CREATE OR REPLACE VIEW pulse.patient_discovery_query_stats AS
SELECT 
	org.id as organization_id,
	org.name as organization_name,
	org.is_active as organization_is_active,
	org.adapter as organization_adapter,
	status.status,
	queryOrg.start_date,
	queryOrg.end_date
FROM pulse.query_organization queryOrg
LEFT OUTER JOIN pulse.organization org on 
	queryOrg.organization_id = org.id
LEFT OUTER JOIN pulse.query_organization_status status on 
	(queryOrg.query_organization_status_id IS NOT NULL 
	AND queryOrg.query_organization_status_id = status.id);