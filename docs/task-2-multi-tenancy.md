# Task 2 - Multi-Tenancy Architecture

This document describes the multi-tenancy model for the payroll platform serving Companies, Bureaus, and Employees. The design goal is strict tenant isolation for highly sensitive payroll data while keeping the solution coherent, free-tier-aware, and operationally manageable.

## 2a. Tenant Isolation Strategy

I chose a shared PostgreSQL database with strict tenant-aware logical isolation enforced through authenticated tenant context, application-layer request scoping, and database-level row filtering. I did not choose schema-per-tenant or database-per-tenant because those models increase provisioning, migration, and lifecycle management complexity without improving the overall assignment outcome enough to justify the additional operational overhead.

This model fits a sensitive payroll platform because isolation is not left to a single mechanism. The system already separates Companies, Bureaus, and Employees at the compute layer by running each portal on its own EC2 instance. The database layer then enforces tenant isolation by requiring every business row to be associated with a tenant identifier and by ensuring all queries are resolved using the authenticated tenant context rather than trusting identifiers passed from the client.

### Login and tenant context establishment

Tenant context is established at login time. After successful authentication, the platform resolves and binds the following identity attributes to the authenticated session or token:

- `portal_type`: `company`, `bureau`, or `employee`
- `tenant_id`: the owning tenant identifier
- `subject_id`: a more specific entity identifier where needed, such as `employee_id`
- `access_scope`: optional assignment scope, such as the list of client companies a Bureau is allowed to manage

This means identity is not just “user X is logged in.” Identity is “user X is logged in as portal type Y for tenant Z with scope S.”

### Request lifecycle propagation

Every request passes through authentication and authorization middleware before reaching business logic. That middleware validates the token, extracts `portal_type`, `tenant_id`, and any scope metadata, and injects them into the request context.

Downstream services are not allowed to execute data access without this context. Repository or service-layer methods read tenant context from the authenticated request rather than from user-controlled input. Frontend-supplied tenant identifiers are not trusted as authorization boundaries.

### Query and API isolation

To prevent cross-tenant leakage, the application never issues unrestricted reads. All database access is scoped using the authenticated tenant context. At the database layer, PostgreSQL Row Level Security (RLS) is used to enforce tenant-scoped row visibility, so even if an application-level filter is missed, queries cannot return rows outside the authenticated tenant context.

Examples:
- A Company user can read only records where `tenant_id` matches that Company.
- A Bureau user can read only records for the companies assigned to that Bureau.
- An Employee user can read only their own payroll records and profile data.

At the database layer, row-level filtering rules are used so that access outside the active tenant context is denied even if an application-level filter is accidentally missed. Queries are parameterized and built from authenticated context, not from raw client-supplied tenant values.

This creates a layered guarantee:
1. The user authenticates into exactly one portal context.
2. The application resolves tenant context from the authenticated identity.
3. Every service call inherits that context.
4. Every database query is scoped to that context.
5. The database enforces row visibility boundaries.
6. Infrastructure controls still exist as a second boundary if application logic fails.

### Why this model was chosen

I considered schema-per-tenant because it provides stronger namespace separation than simple tenant_id filtering. I rejected it for this assignment because it would require additional schema lifecycle orchestration, schema migrations across tenants, more complicated onboarding/offboarding logic, and more complex Bureau-to-client access modeling. I also rejected database-per-tenant because it would impose the highest operational and cost overhead and is not well aligned with a free-tier-aware design.

The selected model gives the best balance for this assignment:
- strong tenant isolation through layered controls,
- simpler onboarding and lifecycle management,
- lower operational complexity,
- easier explanation and validation within the scope of the assignment.

## 2b. Access Boundaries at the Infrastructure Layer

Application-level tenant logic is necessary but not sufficient for a payroll system. Infrastructure must act as a second enforcement boundary so that a coding mistake does not automatically become cross-tenant data exposure.

### IAM role boundaries

The platform uses separate IAM roles for each portal type:

- `company-portal-role`
- `bureau-portal-role`
- `employee-portal-role`

Each EC2 instance assumes only the role associated with its portal. These roles are least-privilege by design and are limited to only the AWS actions and resource paths needed by that portal.

Examples:
- The Company portal role can access only Company-scoped storage paths and configuration.
- The Bureau portal role can access only Bureau-scoped resources and the specific data flows required for managing assigned clients.
- The Employee portal role has the narrowest scope and can access only employee-facing resources required for self-service payroll access.

No role is allowed broad access across all tenant resources.

### S3 isolation model

S3 document storage is logically segregated by prefix. A representative layout is:

- `s3://payroll-documents/company/<company_id>/`
- `s3://payroll-documents/bureau/<bureau_id>/`
- `s3://payroll-documents/employee/<employee_id>/`

IAM policies and bucket policies enforce that each portal role can access only the prefixes inside its allowed boundary. For example, the Company portal cannot read or write under Bureau or Employee prefixes, and the Employee portal cannot enumerate Company or Bureau documents.

This matters because it prevents cross-tenant document access even if the application accidentally constructs an invalid object key. The AWS authorization layer still blocks access outside the allowed path.

### Infrastructure as second enforcement boundary

The infrastructure layer is intentionally designed to reduce blast radius if application controls fail:

- Separate EC2 instances per portal reduce cross-portal impact.
- Separate IAM roles reduce AWS resource exposure.
- Scoped S3 prefixes reduce document exposure.
- RDS is private and not publicly accessible.
- Security Groups allow only required service-to-service traffic.
- NACLs reinforce subnet-level segmentation.

This means tenant isolation is enforced by multiple layers:
- authenticated request context,
- application authorization checks,
- database row isolation,
- IAM boundaries,
- S3 policy boundaries,
- network segmentation.

A defect in one layer does not remove all protections.

## 2c. Tenant Onboarding & Offboarding

Tenant lifecycle management is treated as a controlled security process. New tenants are created in a scoped state from day one, and offboarding is handled through a revocation-and-deletion workflow with auditability.

### Tenant onboarding

When a new Company or Bureau is onboarded, the platform creates the tenant’s logical identity and resource boundaries before any user is granted functional access.

For a new Company tenant, onboarding creates:
- a unique tenant record in PostgreSQL,
- company metadata and lifecycle status,
- administrator user linkage,
- Company-specific document prefix allocation in S3,
- portal access mapping for the Company portal,
- audit records for tenant creation.

For a new Bureau tenant, onboarding creates:
- a unique bureau tenant record,
- bureau metadata and lifecycle status,
- Bureau-specific S3 prefix allocation,
- assignment mappings defining which client companies the Bureau can manage,
- portal access mapping for the Bureau portal,
- audit records for tenant creation.

For Employee onboarding, the employee is created under an existing Company or Bureau context and is linked to exactly one employee identity and the payroll records that belong to that identity.

Isolation exists from day one because no tenant becomes active until all of the following exist:
- a unique tenant identifier,
- a valid portal association,
- scoped access mappings,
- dedicated S3 path boundaries,
- audit logging for the lifecycle event.

Access is deny-by-default until the tenant is fully provisioned.

### Tenant offboarding

Offboarding starts by revoking access before deleting data. This prevents further interaction with the tenant’s resources while the offboarding workflow is in progress.

The offboarding sequence is:

1. Disable or revoke tenant user access.
2. Expire active sessions and remove tenant routing or assignment mappings.
3. Prevent new application access to tenant resources.
4. Execute tenant-scoped data deletion or retention workflow, depending on policy and legal requirements.
5. Remove or invalidate resource access paths no longer needed.
6. Record every action in an audit trail.

For data deletion, tenant-owned records are deleted using tenant-scoped workflows in PostgreSQL, and tenant-owned documents are deleted from the tenant’s S3 prefixes. If retention is required for legal or audit reasons, the data is first moved into a restricted retention state and removed from standard production access until final deletion is allowed.

For access revocation, the platform removes or disables tenant-specific permissions, deactivates user access, and ensures that the tenant’s storage prefixes and application entry points are no longer reachable through normal workflows.

### Audit trail

Every onboarding and offboarding event is recorded with:
- actor,
- timestamp,
- tenant identifier,
- action performed,
- outcome.

This audit trail supports compliance evidence, incident investigation, and operational accountability.

### Summary

This tenant lifecycle model ensures that:
- onboarding creates isolated boundaries before first use,
- tenant access is deny-by-default until provisioning is complete,
- offboarding revokes access before data handling,
- deletion and revocation are auditable,
- no tenant exists in an undefined or shared-open state.