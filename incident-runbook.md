# Incident Runbook – RDS Accidentally Made Public

## Scenario
This runbook covers the response to a PostgreSQL RDS instance being accidentally made publicly accessible.

## Severity
Treat this as a high-severity security incident because the database stores sensitive payroll and employee data.

## Detection
Possible detection sources:
- Terraform drift or plan review shows `publicly_accessible = true`
- AWS Console or CLI confirms the RDS instance is public
- Security review finds a public route or broad DB security group rule
- CloudWatch alarms or logs show unusual database connection activity

Quick confirmation:
```bash
aws rds describe-db-instances \
  --db-instance-identifier <db-instance-id> \
  --query 'DBInstances.[PubliclyAccessible,DBSubnetGroup.DBSubnetGroupName,VpcSecurityGroups[*].VpcSecurityGroupId]'
```

## Investigation
Confirm:
- whether the instance is actually public
- whether the DB security group allows inbound 5432 from broad CIDRs
- how long the exposure existed
- whether CloudTrail shows who changed the DB or security settings
- whether CloudWatch metrics or DB logs show suspicious connections during the exposure window

Review:
- CloudTrail for `ModifyDBInstance` and security group changes
- RDS metrics such as `DatabaseConnections`
- relevant application, deployment, and infrastructure logs

## Containment
Take these actions immediately:
1. Set the RDS instance back to non-public:
   ```bash
   aws rds modify-db-instance \
     --db-instance-identifier <db-instance-id> \
     --no-publicly-accessible \
     --apply-immediately
   ```
2. Remove any broad inbound DB rules such as `0.0.0.0/0`.
3. Restrict inbound PostgreSQL access to only the approved application security groups.
4. Verify the DB subnet group still uses only private DB subnets.
5. Review NACLs and route tables to ensure no public path exists to the database layer.

## Remediation
- Reconcile the change in Terraform and remove any drift.
- Re-run `terraform validate` and `terraform plan`.
- Confirm the DB security group, subnet group, and route controls match the intended private design.
- Rotate DB credentials if the exposure window or logs suggest meaningful risk.
- Update SSM Parameter Store or Secrets Manager if credentials are rotated.

## Validation
Before closing the incident, confirm:
- `PubliclyAccessible = false`
- inbound DB access is limited to approved application security groups only
- no public CIDR remains on the DB security group
- the DB remains in private subnets
- the application can still connect normally from approved EC2 instances
- no evidence of unauthorized access remains in reviewed logs/metrics

## Recovery
- Restore normal service once the private DB posture is confirmed.
- Monitor DB connections and application health closely for a defined observation period.
- Confirm alerts and logging are functioning after the fix.

## Preventive Follow-Up
- Document the timeline, root cause, and actions taken.
- Record whether any unauthorized access was found.
- Add stronger review checks so `publicly_accessible = true` on RDS is caught before apply.
- Tighten IAM permissions for DB/network changes if needed.
- Update README and operational notes if any gaps were discovered.