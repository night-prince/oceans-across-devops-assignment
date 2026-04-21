# DevOps Engineer Technical Assignment – Oceans Across

Security-first AWS infrastructure design for a UK payroll platform serving Companies, Bureaus, and Employees.

---

## 1. Executive Summary
This repository contains the infrastructure design, deployment workflow, architecture decisions, security model, monitoring approach, compliance notes, and supporting documentation for the Oceans Across DevOps technical assignment.

This solution is intentionally optimized for:
- security-first design
- tenant isolation
- least privilege
- operational simplicity
- clear trade-off reasoning
- professional presentation without unnecessary complexity

The platform is designed around:
- Terraform-managed AWS infrastructure
- one EC2 instance per portal type
- private PostgreSQL on RDS
- versioned S3 document storage
- strict IAM separation
- private-first networking
- GitHub Actions CI/CD with AWS Systems Manager deployment
- CloudWatch and SNS for observability
- separate incident runbook and AI usage log files

---

## 2. Assignment Coverage Map
The table below maps each assignment requirement to the relevant files and sections.

| Assignment Requirement | Where It Is Covered |
|---|---|
| Task 1 – AWS Infrastructure Setup | `terraform/providers.tf`, `terraform/variables.tf`, `terraform/main.tf`, `terraform/network.tf`, `terraform/rds.tf`, `terraform/s3.tf`, `terraform/iam.tf`, `terraform/outputs.tf`, `diagrams/architecture-task1-final.png`, and Sections 7, 8, 9, 11, and 15 |
| Task 2 – Multi-Tenancy Architecture | Sections 10 & 11 and docs/task-2-multi-tenancy.md|
| Task 3 – Security & Access Control | `terraform/iam.tf`, `terraform/secrets.tf`,Section 11 |
| Task 4 – CI/CD Pipeline | `.github/workflows/` + Section 12 |
| Task 5 – Monitoring & Incident Readiness | `terraform/monitoring.tf`, `incident-runbook.md`, Section 13 |
| Task 6 – UK Compliance Considerations | Section 14 |
| Architecture Diagram | `diagrams/architecture-task1-final.png`, `diagrams/architecture-task1-final.drawio`, `diagrams/complete-architecture-final.png`, `diagrams/complete-architecture-final.drawio` |
| AI Usage Log (mandatory) | `ai_log.md` |
| Incident Response Runbook | `incident-runbook.md` |

---

## 3. Repository File Map

```text
.
├── README.md
├── ai_log.md
├── incident-runbook.md
├── diagrams/
│   ├── architecture-task1-final.png
│   ├── architecture-task1-final.drawio
│   ├── complete-architecture-final.drawio
│   └── complete-architecture-final.png
├── docker/
│   ├── Dockerfile
├── terraform/
│   ├── providers.tf # Terraform version, AWS provider, random provider, and default tags
│   ├── variables.tf # Region, naming, VPC CIDR, subnet CIDRs, admin CIDRs, AMI IDs, and DB inputs
│   ├── outputs.tf # VPC, subnet, EC2, RDS, S3, and SG outputs
│   ├── main.tf # Shared locals, naming/tags, random bucket suffix, and one EC2 instance per portal type
│   ├── iam.tf # Company/Bureau/Employee IAM roles, S3 policies, and instance profiles
│   ├── rds.tf # Private PostgreSQL RDS db.t3.micro
│   ├── s3.tf # Payroll documents bucket with versioning, encryption, public access block, and bucket policy
│   ├── secrets.tf # SSM Parameter Store SecureString parameters, tenant-scoped parameter paths, and IAM policy attachments for runtime secret retrieval without hardcoded credentials
│   ├── monitoring.tf # CloudWatch log groups, EC2 CPU alarms, RDS connection alarm, SNS critical alert topic, and alarm-to-notification wiring
│   ├── network.tf # VPC, IGW, public/private subnets, route tables, DB subnet group, NACLs, and SGs
└── .github/
    └── workflows/
        └── deploy.yml
```

---

## 4. How To Extend This README
-

---

## 5. Project Overview
The goal of this assignment is to design a secure, auditable, and maintainable AWS platform for a payroll system handling highly sensitive employee and payroll data.

The platform serves three distinct user groups:
- Companies
- Bureaus
- Employees

The design treats tenant isolation, least privilege, and infrastructure-level enforcement as first-class concerns.

I intentionally stopped at validated infrastructure-as-code and documentation quality because the assignment explicitly states that live deployment is optional and that well-structured Terraform, a clear architecture diagram, and a detailed README are sufficient for evaluation.

---

## 6. Assumptions
- Primary deployment region is `eu-west-2`.
- The solution is optimized for assignment scope, cost awareness, and security posture rather than production-scale throughput.
- A placeholder Dockerized backend service is sufficient for CI/CD demonstration.
- Live deployment is optional and secondary to validated Terraform and strong documentation.
- Only free-tier-safe or assignment-approved AWS services are used if anything is deployed live.
- AMI IDs for the Company, Bureau, and Employee portal instances are supplied externally at plan/apply time.
- The PostgreSQL password is supplied externally through a non-committed `.tfvars` file or `TF_VAR_db_password`; it is not hardcoded in Terraform.
- For Task 1 simplicity, the three portal EC2 instances are currently placed in public subnets, while the RDS instance remains private in dedicated DB subnets.

---

## 7. Setup Instructions

### Prerequisites
- Terraform `>= 1.x`
- AWS CLI configured
- Docker installed
- GitHub repository secrets configured
- Access to an AWS account only if doing optional live validation

### Terraform
```bash
cd terraform

terraform init

terraform fmt -recursive

terraform validate

# Example Terraform Plan (Illustrative)
# The following example command can be used to generate a Terraform execution plan using environment variables and example AMI inputs:

export TF_VAR_db_password='replace-me-securely'

terraform plan \
  -var="company_ami_id=ami-xxxxxxxxxxxxxxxxx" \
  -var="bureau_ami_id=ami-yyyyyyyyyyyyyyyyy" \
  -var="employee_ami_id=ami-zzzzzzzzzzzzzzzzz"
```

**Validation note:** `terraform fmt -recursive` is used to normalize formatting across all Terraform files before review or CI checks, and `terraform validate` is used after `terraform init` to verify Terraform syntax, references, and internal consistency.

**Input note:** the current Terraform requires three AMI IDs (`company_ami_id`, `bureau_ami_id`, and `employee_ami_id`) and one sensitive PostgreSQL password input (`db_password`) to produce a valid plan.

**Output note:** `outputs.tf` exports the VPC ID, public/private subnet IDs, DB subnet group name, tenant EC2 instance IDs and public IPs, the RDS endpoint, the S3 bucket name, and the security group IDs for downstream use.

### Application Container
```bash
cd app
docker build -t oceans-across-payroll-app .
docker run -p 8080:8080 oceans-across-payroll-app
```

### CI/CD
- Push to `main` to trigger the pipeline.
- The workflow builds and tests the application on every push to `main`.
- Deployment is performed through AWS Systems Manager rather than direct SSH.
- Environment-specific values are injected through Terraform variables, GitHub Variables, GitHub Environments, and AWS Systems Manager Parameter Store instead of being hardcoded in workflow YAML.

### Terraform File Split
The Terraform implementation is split across providers.tf, variables.tf, main.tf, network.tf, rds.tf, s3.tf, iam.tf, secrets.tf, monitoring.tf, and outputs.tf.

providers.tf defines Terraform and provider requirements and applies default tags.

variables.tf defines reusable inputs for region, naming, CIDR ranges, AMI IDs, admin CIDRs, and database settings.

main.tf defines shared locals and provisions one EC2 instance per portal type.

network.tf builds the VPC, subnets, route tables, DB subnet group, NACLs, and security groups.

rds.tf provisions a private PostgreSQL db.t3.micro instance.

s3.tf provisions the payroll documents bucket with versioning, server-side encryption, public access blocking, and secure transport enforcement.

iam.tf creates tenant-scoped IAM roles, policies, and instance profiles.

secrets.tf provisions SSM Parameter Store parameters and IAM-scoped runtime retrieval paths for sensitive configuration.

monitoring.tf provisions CloudWatch log groups, alarms, and SNS alerting resources.

outputs.tf exports the values that later infrastructure layers should consume instead of hardcoding identifiers.

---

## 8. Architecture Decisions

### 8.1 Tenancy Model
**Chosen:** Shared PostgreSQL database with strict tenant scoping and database-enforced row isolation, combined with portal-level separation in compute and IAM.

**Reason:**  
I chose a shared PostgreSQL database with strict tenant scoping and database-enforced row isolation, combined with portal-level separation in compute and IAM, because it provides strong isolation with lower operational complexity than schema-per-tenant or database-per-tenant for this assignment’s free-tier constraints.

### 8.2 IAM Boundary Model
**Chosen:** Separate IAM roles and least-privilege policies for each portal type.

**Reason:**  
I use separate IAM roles and least-privilege policies for Company, Bureau, and Employee portals, with access limited to only the resources and S3 paths relevant to each portal type, so infrastructure remains a second enforcement layer if application logic fails.

### 8.3 Network Segmentation Model
**Chosen:** One VPC across two AZs with public and private subnets.

**Reason:**  
I use one VPC across two AZs with public and private subnets, keeping application and database resources private by default and restricting traffic through tightly scoped Security Groups and NACLs.

**Implementation detail:** the VPC is split into two public subnets, two private application subnets, and two private database subnets across two availability zones. The three portal EC2 instances are placed in public subnets for direct portal reachability in the current Task 1 design, while the PostgreSQL RDS instance is placed in private DB subnets through a dedicated DB subnet group and is not publicly accessible.

### 8.4 CI/CD Deployment Model
**Chosen:** GitHub Actions with deployment to EC2 through AWS Systems Manager.

**Reason:**  
I use GitHub Actions to build and test on every push to `main` and deploy to EC2 through AWS Systems Manager, avoiding direct SSH exposure and keeping the deployment path consistent with a security-first design.

### 8.5 Compliance Approach
**Chosen:** UK/EU region pinning with encryption, auditability, least privilege, and deletion workflow.

**Reason:**  
I pin the solution to UK/EU regions, minimize access through least privilege, encrypt data at rest and in transit, log access and changes, and define a documented deletion workflow to support UK GDPR obligations.

### 8.6 Secrets Management Model
**Chosen:** AWS Systems Manager Parameter Store with runtime retrieval through IAM roles.

**Reason:**  
I use AWS Systems Manager Parameter Store for runtime secret retrieval so sensitive values stay out of source control, Terraform defaults, and pipeline YAML.

**Current implementation note:** 
The current Terraform avoids hardcoded credentials by requiring the initial database password to be passed in as a sensitive input variable, while secrets.tf defines SSM Parameter Store resources and IAM-scoped runtime retrieval for ongoing secret access.

### 8.7 Observability Model
**Chosen:** CloudWatch metrics, alarms, and log groups with SNS notifications.

**Reason:**  
I use CloudWatch metrics, alarms, and log groups with SNS notifications for critical failures, which satisfies the assignment while keeping observability simple and operationally realistic.

### 8.8 Compute Isolation Model
**Chosen:** One EC2 instance per portal type.

**Reason:**  
I provision one EC2 instance per portal type—Companies, Bureaus, and Employees—to meet the assignment requirement and reduce the blast radius between user groups.

**Implementation detail:** the compute layer is implemented as a reusable tenant map pattern in `main.tf`, instantiated for `companies`, `bureaus`, and `employees`, with a dedicated security group and IAM instance profile attached to each portal instance.

### 8.9 Data Storage Model
**Chosen:** RDS PostgreSQL for structured data and versioned S3 for documents/reports.

**Reason:**  
I store structured payroll data in a private PostgreSQL RDS instance and documents or payroll reports in a versioned S3 bucket with scoped prefixes and access controls.

**Implementation detail:** the PostgreSQL instance is provisioned as `db.t3.micro` with storage encryption enabled and private subnet placement, while the S3 bucket has versioning enabled, AES256 server-side encryption, public access blocked, and tenant-specific access boundaries enforced through IAM policies scoped to `companies/*`, `bureaus/*`, and `employees/*`.

### 8.10 Encryption Model
**Chosen:** Encryption at rest for storage and database, plus TLS in transit.

**Reason:**  
I enable encryption at rest for RDS and S3 and require TLS for all network-exposed services, documenting how data remains protected both at rest and in transit.

### 8.11 Environment Strategy
**Chosen:** Single codebase with environment-specific values injected externally.

**Reason:**  
I use one codebase with environment-specific values injected through Terraform variables and secret stores rather than embedding configuration directly in workflow files or source code.

### 8.12 Live Deployment Strategy
**Chosen:** Live deployment is optional and secondary to validated design quality.

**Reason:**  
I treat live AWS deployment as optional and focus first on validated Terraform, strong documentation, and submission completeness, using only free-tier-safe services if I choose to demonstrate anything live.

---

## 9. Infrastructure Design (Task 1)
This section covers the core Terraform foundation implemented for Task 1: VPC, subnets across two AZs, route tables, one EC2 instance per portal type, private PostgreSQL RDS, versioned and encrypted S3, tenant-scoped IAM roles and instance profiles, Security Groups, NACLs, and outputs. Monitoring, alerting, and runtime secret retrieval are implemented in companion Terraform files (monitoring.tf and secrets.tf) and are reflected in the full end-to-end architecture. 

### Implemented Terraform Components
- one AWS VPC spanning two availability zones
- two public subnets, two private application subnets, and two private database subnets
- one Internet Gateway and separate public and private route tables
- one EC2 instance for each portal type: Companies, Bureaus, and Employees
- one private PostgreSQL RDS instance (`db.t3.micro`) placed in private DB subnets
- one S3 bucket for payroll documents and reports with versioning enabled
- server-side encryption and public access blocking on S3
- separate IAM roles, S3 policies, and instance profiles for Company, Bureau, and Employee portal instances
- Security Groups and NACLs for traffic restriction and subnet-level segmentation
- exported Terraform outputs for IDs, endpoints, and names needed by later layers

### Design Principles
- private database posture
- least privilege by default
- portal-level compute isolation
- tenant-aware storage and IAM boundaries
- layered security controls across compute, network, data, and access

### Terraform File Responsibilities
- `providers.tf` sets Terraform and provider requirements and applies default tags to resources.
- `variables.tf` centralizes region, naming, subnet CIDRs, admin CIDRs, AMI IDs, and database inputs.
- `main.tf` defines naming locals and provisions the three tenant EC2 portal instances.
- `network.tf` builds the VPC, subnets, route tables, DB subnet group, NACLs, and security groups.
- `rds.tf` provisions the private PostgreSQL database layer.
- `s3.tf` provisions the versioned and encrypted payroll documents bucket and applies restrictive bucket controls.
- `iam.tf` enforces tenant IAM separation through distinct roles, S3 policies, and instance profiles.
- `outputs.tf` exports the network, compute, storage, and security identifiers needed by later infrastructure layers.

### Architecture Diagram
Reference:
- `diagrams/architecture-task1-final.png`
- `diagrams/architecture-task1-final.drawio`
- `diagrams/complete-architecture-final.png`
- `diagrams/complete-architecture-final.drawio`

---

## 10. Multi-Tenancy Architecture (Task 2)

This section explains how tenant isolation works end to end.

### Tenant Isolation Strategy
The platform uses a shared PostgreSQL database with strict tenant scoping and database-enforced row isolation, reinforced by portal-level compute separation and IAM boundaries.

### Why This Model Was Chosen
- stronger than relying only on application-level filtering
- operationally simpler than schema-per-tenant
- far less complex than database-per-tenant
- fits the assignment’s free-tier-aware and security-first goals

### Cross-Tenant Leakage Prevention
- tenant identity is established at authentication time
- every request carries validated tenant context
- queries are constrained to the authenticated tenant
- infrastructure access is separated by IAM role and resource scope
- S3 access is limited through scoped prefixes and policies
- database and network controls still reduce risk if application logic fails

### Alternatives Considered
#### Shared database with weak application-only filtering
Rejected because the leakage risk is too high for payroll data.

#### Schema-per-tenant
Rejected because it adds more operational overhead than needed for this assignment.

#### Database-per-tenant
Rejected because it is too heavy for the scope, cost posture, and time constraints of the exercise.

### Trade-off
This model does not provide the absolute maximum isolation possible, but it gives the best balance between security, maintainability, and assignment-fit.

---

## 11. Tenant Enforcement, Security, and Access Control (Task 2 + Task 3)

### Tenant Context Establishment
Tenant identity is established at login and attached to the authenticated request context using trusted claims for portal type, tenant ID, and user ID.

### Tenant Context Propagation
Every downstream API call and service action must carry validated tenant context. Requests with missing, invalid, or inconsistent tenant context are rejected before data access.

### Data Access Enforcement
Application queries are constrained to the authenticated tenant, and the database layer reinforces this through tenant-aware query constraints and least-privilege access patterns. This prevents cross-tenant leakage even if one application control fails.

### IAM & RBAC
The platform uses three separate IAM roles and instance profiles, one for each portal type: Company, Bureau, and Employee. This preserves a hard infrastructure boundary between portal workloads and ensures that each EC2 instance receives temporary AWS credentials through its attached role instead of static access keys.

Least privilege is enforced in two places. First, S3 access is scoped by tenant prefix: the Company role can access only `companies/*`, the Bureau role can access only `bureaus/*`, and the Employee role can access only `employees/*`. Second, runtime parameter access is scoped by SSM Parameter Store path so that each portal role can read only shared DB connection metadata plus its own tenant-specific secret path.

No role is granted cross-tenant S3 access, and no role is granted blanket access to all Parameter Store paths. This means the IAM layer remains a second enforcement boundary even if application-level tenant checks fail.

No hardcoded credentials are stored in Terraform defaults, application code, or pipeline YAML. EC2 instances use IMDSv2-backed temporary role credentials, and the database password is provided externally at plan/apply time and then delivered to workloads through SSM Parameter Store.

### Secrets Management
The current Terraform implementation does not hardcode database credentials. The PostgreSQL password is defined as a sensitive input variable and must be supplied externally through a non-committed `.tfvars` file or an environment variable such as `TF_VAR_db_password`.

For runtime secrets management, the current Terraform implementation uses AWS Systems Manager Parameter Store with IAM-scoped retrieval from EC2 instance roles. The `secrets.tf` file provisions tenant-scoped parameters for shared DB metadata and tenant-specific DB credentials, while `iam.tf` restricts each portal role to only its own parameter path plus the shared DB path. This keeps secrets out of source control, Terraform defaults, and pipeline YAML, while allowing runtime injection on the instance through temporary role credentials.

### Encryption
Encryption at rest is enabled for the primary data stores. The PostgreSQL RDS instance is created with `storage_encrypted = true`, and the payroll documents S3 bucket is configured with default AES256 server-side encryption. The S3 bucket policy also denies object uploads that do not request server-side encryption.

The compute layer also uses encrypted storage for the EC2 root volumes. This is not the main Task 3 requirement, but it reduces exposure of temporary application data on instance disks.

Data in transit is protected in three ways. First, the S3 bucket policy denies insecure transport, so bucket operations must use TLS. Second, public application traffic is intended to terminate over HTTPS on TCP 443, with HTTP redirected to HTTPS at the web server or reverse proxy layer. Third, database connections from the portal applications to PostgreSQL should use SSL with `sslmode=require` (or stricter CA validation in production) so credentials and payroll data are not sent in plaintext inside the VPC.

For the purposes of this assignment, the Terraform network layer opens TCP 443 for exposed services and enforces TLS-only access to S3. The application deployment should ensure that the portal service listens on HTTPS and that PostgreSQL clients are configured to require SSL.

- RDS encryption at rest is enabled.
- S3 encryption at rest is enabled.
- TLS is required for network-exposed services.
- Data protection is documented for both at-rest and in-transit paths.

### Network Security
The network is segmented into public subnets, private application subnets, and private database subnets across two availability zones. The portal EC2 instances are currently placed in public subnets for assignment simplicity, but the database layer remains private through private DB subnet placement, private route table association, a DB subnet group, and `publicly_accessible = false` on the RDS instance.

Security Groups enforce the exact compute-to-data paths. Each portal instance has its own tenant-specific security group. The database has its own dedicated RDS security group. The only database path allowed is PostgreSQL TCP 5432 from the three portal security groups to the RDS security group.

Exact allowed traffic paths:
- Internet users may reach portal EC2 instances on TCP 80 and 443.
- Administrative SSH access to portal EC2 instances is limited to TCP 22 from `allowed_admin_cidrs`.
- Portal EC2 instances may initiate outbound TCP 443 to the internet for package retrieval and AWS API access.
- Portal EC2 instances may initiate outbound TCP 5432 only to the RDS security group.
- The RDS security group accepts inbound TCP 5432 only from the three tenant portal security groups.
- No public internet source can connect directly to the database security group.
- The S3 bucket denies insecure transport and denies object uploads that do not request AES256 server-side encryption.

NACLs provide an additional subnet-level boundary. The public NACL allows inbound 80, 443, 22, and ephemeral ports and permits outbound internet traffic. The private application NACL allows only the VPC-internal and outbound paths needed for HTTPS and PostgreSQL. The private DB NACL allows PostgreSQL and return traffic only within the VPC boundary.

Tenant-to-tenant reachability is restricted in two layers. First, there is no explicit security-group-based trust from one tenant portal security group into another. Second, data-layer access is not broad VPC access; it is narrowed to PostgreSQL 5432 into the RDS security group only. S3 access is then separated again by IAM prefix policy so that one portal role cannot read or write another tenant area in the bucket.

- The database is private-only and not publicly accessible.
- Security Groups allow only required traffic flows.
- NACLs provide additional subnet-level restriction.
- Application and database layers are segmented to reduce lateral movement risk.

### NACL Notes
- The public NACL allows inbound TCP 80, 443, 22, and ephemeral ports from `0.0.0.0/0`, with outbound traffic allowed to `0.0.0.0/0`.
- The private application NACL allows inbound TCP 80, 443, and ephemeral ports from the VPC CIDR, and outbound TCP 5432 to the VPC CIDR, outbound TCP 443 to `0.0.0.0/0`, and outbound ephemeral ports to the VPC CIDR.
- The private DB NACL allows inbound TCP 5432 and ephemeral ports from the VPC CIDR, and outbound ephemeral ports to the VPC CIDR.

### Isolation Rationale
- One tenant portal does not receive any explicit security-group-based trust into another tenant portal.
- Database access is constrained to TCP 5432 from the tenant portal security groups only.
- The database is private by subnet placement, private route table association, and `publicly_accessible = false`.
- S3 access is constrained by IAM prefix policy, so a Company role cannot list or manage Bureau or Employee objects, and the same boundary applies to the other tenant roles.

### Tenant Onboarding
Tenant onboarding creates the tenant record, assigns the correct portal boundary, provisions the required IAM and S3 scope, registers tenant metadata, and records an audit event. This ensures the tenant is isolated from day one.

### Tenant Offboarding
Tenant offboarding is extended into a formal right-to-erasure workflow covering database rows, S3 objects, access revocation, backup handling, and retained audit evidence.

---

## 12. CI/CD Pipeline (Task 4)

### Pipeline Scope
The CI/CD pipeline is implemented in `.github/workflows/deploy.yml` and runs on every push to `main`. It also supports manual `workflow_dispatch` so a specific service and environment can be selected without waiting for a code push.

The pipeline uses **AWS Systems Manager (SSM)** as the fixed deployment path to EC2. SSH is not used anywhere in the deployment workflow, which keeps the deployment model consistent with the security-first approach selected earlier.

The workflow builds and smoke-tests a simple Dockerized placeholder app from `docker/Dockerfile`. The same placeholder image pattern is reused for `frontend`, `backend`, and `ai` service lanes by passing the service name as a build argument.

The pipeline:
- runs on every push to `main`
- builds the Dockerized application
- runs basic validation and test steps
- deploys to EC2 using AWS Systems Manager
- avoids direct SSH-based deployment exposure
- keeps environment-specific configuration outside source code and workflow YAML

### Deployment Flow
1. A push to `main` or a manual `workflow_dispatch` starts the workflow.
2. The workflow detects which service paths changed (`frontend`, `backend`, `ai`) so teams can deploy independently.
3. The selected service is built with Docker using the shared placeholder `docker/Dockerfile`.
4. A smoke test runs the built container locally in GitHub Actions and checks the `/health` endpoint.
5. GitHub Actions assumes an AWS deployment role using OIDC instead of storing static AWS keys in the workflow YAML.
6. The workflow resolves the correct target EC2 instance for the selected service and environment.
7. Deployment is executed through AWS Systems Manager Run Command, which pulls the current repository archive, retrieves runtime configuration from SSM Parameter Store, rebuilds the container on the EC2 host, and restarts the service container.

If no relevant service files changed on a push, the workflow still runs but the unaffected service lanes exit cleanly without deployment.

### Environment Handling
Environment-specific configuration is handled outside the workflow YAML.

- GitHub Environments such as `dev` and `prod` are used to separate approval and runtime context.
- Non-secret values such as target EC2 instance IDs, AWS region, and project slug are stored as GitHub Variables.
- Sensitive values are not stored in workflow YAML and are not baked into the Docker image.
- Runtime secrets and service configuration are retrieved on the EC2 instance from AWS Systems Manager Parameter Store using the instance role created earlier in Task 3.
- The workflow itself only passes the selected environment and service name; the actual secret values remain in AWS.

This keeps the pipeline portable across environments without exposing credentials or environment secrets in source control.

### Multi-Team Separation
The workflow is structured so frontend, backend, and AI teams can trigger deployments independently.

- Each service has its own deployment lane within the workflow.
- Push-based deployments are path-aware, so a frontend-only change does not trigger backend or AI deployment unnecessarily.
- Manual runs support a `service` input (`frontend`, `backend`, `ai`, or `all`) so teams can deploy exactly their own service.
- Concurrency is scoped per service and environment, for example `deploy-backend-dev`, which prevents overlapping deployments of the same service while still allowing different services to deploy independently.
- Each service/environment pair resolves to its own target EC2 instance ID, so deployment commands do not interfere across service boundaries.

This satisfies the assignment requirement that frontend, backend, and AI teams can operate independently without interfering with each other.

---

## 13. Monitoring & Incident Readiness (Task 5)

### Monitoring
The observability layer uses Amazon CloudWatch and Amazon SNS as extensions of the same layered security boundary model used elsewhere in the platform.

- CloudWatch alarms watch tenant-facing compute health and shared database pressure.
- CloudWatch log groups are separated into application and infrastructure scopes so portal-specific operational signals do not get mixed into shared operational streams.
- SNS provides a central critical-alert path for infrastructure failures that need immediate team attention.

This keeps monitoring aligned with the platform structure:
- compute issues are visible per portal boundary
- shared database pressure is visible at the data layer
- critical notifications are centralized without weakening tenant isolation

### Minimum Alerting Coverage
The current Terraform creates the following minimum alert set:

- **EC2 CPU utilisation alarm per portal instance**  
  One CloudWatch alarm is created for each tenant-facing EC2 instance: Companies, Bureaus, and Employees.  
  Threshold: average CPU utilisation >= 80% for 15 minutes.  
  Purpose: protects against sustained CPU saturation caused by runaway application processes, unhealthy deployments, traffic spikes, or crash-restart loops.

- **RDS connection threshold alarm**  
  One CloudWatch alarm is created for the shared PostgreSQL RDS instance.  
  Threshold: average `DatabaseConnections` >= 40 for 10 minutes.  
  Purpose: protects against connection pool leaks, stuck sessions, application retry storms, or approaching connection exhaustion on the `db.t3.micro` database tier.

- **SNS critical alert topic**  
  All critical CloudWatch alarms publish to a dedicated SNS topic.  
  Purpose: provides one central notification path for urgent infrastructure failures and keeps alert routing consistent across compute and database events.

### Log Groups and Retention
The Terraform creates CloudWatch log groups with a sensible default retention period of 30 days.

Application log groups:
- `/<project>-<environment>/application/companies`
- `/<project>-<environment>/application/bureaus`
- `/<project>-<environment>/application/employees`

Infrastructure log groups:
- `/<project>-<environment>/infrastructure/deployments`
- `/<project>-<environment>/infrastructure/ssm`
- `/<project>-<environment>/infrastructure/system`

The split is intentional:
- application logs remain separated by portal boundary
- infrastructure logs remain shared only where shared operational context makes sense
- retention is long enough for troubleshooting and incident review without keeping logs indefinitely

### Operational Signals
The current monitoring model is designed to detect the minimum signals required to operate the platform safely:

- **App health indicators**  
  High sustained CPU on a tenant portal instance may indicate degraded request handling, runaway background work, or a bad deployment.

- **DB connectivity indicators**  
  Elevated RDS connection count may indicate connection leaks, exhausted pools, application retry storms, or abnormal client behaviour.

- **Deployment failure indicators**  
  Infrastructure log groups provide a landing place for deployment and SSM execution logs so failed releases can be investigated without mixing those records into tenant application logs.

- **Critical failure notification path**  
  CloudWatch alarms publish to SNS so urgent infrastructure issues can be surfaced immediately through a single alert channel.

### Incident Response
The incident runbook\RDS Accidentally Made Public, is maintained separately in:
- `incident-runbook.md`

---

## 14. UK Compliance Considerations (Task 6)

### 14.1 What AWS-native controls would you put in place to stay compliant with UK GDPR when storing employee PII and bank data?
I would use the following AWS-native controls:

- least-privilege IAM roles and instance profiles so each workload can access only the AWS resources and data paths required for its function
- private-by-default networking so the database and internal services are not publicly accessible
- encryption at rest for RDS and S3, plus TLS for data in transit between users, application services, and the database
- AWS Systems Manager Parameter Store for database credentials and other sensitive values so secrets are not hardcoded in Terraform, source code, or pipeline YAML
- CloudWatch logs, CloudWatch alarms, SNS notifications, and CloudTrail audit records so privileged changes, operational anomalies, and security-relevant events can be detected and reviewed
- S3 versioning, retention controls, and access boundaries so payroll documents are protected against accidental overwrite while still remaining tightly scoped by role and tenant boundary

### 14.2 How would you ensure data residency within the UK/EU region?
I would ensure data residency by pinning the primary deployment region to `eu-west-2` and keeping production data stores, backups, and operational services in approved UK or EU regions only.

- RDS, S3, CloudWatch, SNS, and parameter or secret storage should all be provisioned in the selected UK or EU region unless there is an explicit compliance-approved reason not to do so
- cross-region replication should be disabled by default, and any snapshot, backup, or export workflow should be reviewed to ensure data is not copied outside the approved geography
- deployment configuration and infrastructure code should treat region selection as a controlled input so residency is enforced consistently rather than left to manual operator choice

### 14.3 How would you handle a scenario where an employee’s data needs to be permanently deleted across all services (right to erasure)?
I would run a controlled deletion workflow across every service that can store or reference the employee’s data.

- identify the employee record and all related identifiers so every database row, document, report, cache entry, and access artifact tied to that employee can be located reliably
- delete or anonymize the employee’s rows from PostgreSQL in line with the approved retention and legal basis rules for payroll data, and record exactly what was removed
- delete all related S3 objects, including prior object versions where policy allows, so payroll documents and reports linked to that employee are removed from active storage
- revoke any residual access tokens, sessions, application mappings, or secret references that could still expose the employee’s data indirectly
- review backups and retention policies so the deletion request is handled according to the approved backup lifecycle, and record any temporary limitation where immediate physical removal from immutable backups is not possible
- keep an audit trail showing request receipt, approval, systems searched, records deleted, objects removed, access revoked, operator identity, timestamps, and final verification that no active-system copy remains

---

## 15. Validation Performed

### Infrastructure Validation
- `terraform init`
- `terraform fmt -recursive`
- `terraform validate`

### Review Validation
- Manual review of Terraform resource references, variable wiring, IAM boundaries, security group flows, and README-to-code consistency

### Scope Note
- I intentionally stopped at validated infrastructure-as-code and documentation review because the assignment explicitly states that live deployment is optional and that a well-structured plan with working IaC is sufficient

---

## 16. Trade-Offs Considered

### Option 1: Database-per-tenant
**Pros**
- strongest isolation story
- simpler tenant-level blast radius control

**Cons**
- too much operational overhead
- poor fit for assignment scope and time
- less practical under free-tier-aware constraints

### Option 2: Schema-per-tenant
**Pros**
- stronger isolation than naive shared-table design
- clear namespace separation

**Cons**
- more operational overhead for onboarding, migrations, and management
- not enough additional value for this assignment compared to stricter shared-db enforcement

### Option 3: Shared database with strict tenant scoping and database-enforced isolation
**Pros**
- strong enough isolation when combined with compute and IAM boundaries
- simpler to manage than schema-per-tenant
- best balance for the assignment

**Cons**
- requires disciplined enforcement in auth, query design, and database policy

### Chosen Direction
The selected architecture uses layered isolation:
- compute separation by portal type
- strict tenant enforcement in the database layer
- IAM boundary separation
- private networking
- encrypted storage and transport
- simple, credible monitoring

### Option 4: Public portal EC2 instances vs. ALB-backed private application tier
**Pros**
- simpler Terraform for the assignment
- direct mapping to the requirement of one EC2 instance per portal type
- avoids introducing extra edge components before they are needed

**Cons**
- public HTTP/HTTPS exposure is broader than an ALB-fronted private-subnet design
- ingress is less tightly controlled than an ALB-to-private-compute model
- later hardening would likely move portal compute behind an ALB and reduce direct inbound exposure

### Current Direction
For Task 1, the design keeps the three portal EC2 instances directly reachable in public subnets for simplicity and clarity, while keeping PostgreSQL private and tightly restricted.

---

## 17. Limitations

- This repository is designed for assignment scope, not full production readiness.
- High availability, autoscaling, and disaster recovery may be simplified.
- Some hardening controls may be documented rather than exhaustively implemented.
- The tenancy model depends on correct and consistent enforcement across authentication, application, and database access paths.
- Full production-grade observability and compliance automation are outside the scope of this submission.
- The portal EC2 instances are internet-facing for Task 1 simplicity; a stronger production edge design would front them with an ALB and reduce direct inbound exposure.
- `allowed_admin_cidrs` is broad in the sample variables and must be tightened before any real deployment.

---

## 18. Future Improvements

- reusable Terraform modules
- automated tenant onboarding/offboarding workflows
- deeper policy-as-code enforcement
- stronger CI/CD quality gates
- centralized dashboards
- backup restore testing automation
- enhanced AWS-native security services where budget allows

---

## 19. Resources Used

- AWS documentation
- Terraform documentation
- GitHub Actions documentation
- PostgreSQL documentation

---

## 20. AI Usage Disclosure
AI usage is documented separately in:
- `ai_log.md`

---
