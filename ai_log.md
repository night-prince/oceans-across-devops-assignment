# AI Usage Log

## Entry 1
Prompt:
"access the file with the shared info on the assignment I am intending to commence. Would I face hiccups anywhere throughout the assignment without AWS account (like would be better if I had the account to test XYZ or something specific in the assignment)? Also give me a final list of resources I need to initialise and keep ready to have all my tools ready before I begin the work"

AI Output Used:
Suggested that live AWS deployment was optional under the assignment and that a well-structured IaC submission would still be acceptable. Also it gave me a list of tools to install locally, VS code extensions, repo structure and files to create.

What I Changed:
I followed up and asked if AWS testing would be a time sink for my assignment given limited time. Based on response, I decided to create an AWS account. I may not live deploy as time is limited.

---

## Entry 2
Prompt:
"what must be included in the README file?"

AI Output Used:
Suggested a README structure with what sections to include. Gave me example texts to be replaced. 

What I Changed and follow up:
Adapted my structure eventually to final README sections.

---

## Entry 3
Prompt:
"what is your recommended strategy to finish the assignment. I have done the necessary installations, created AWS account, made the empty files. Do I go task by task ?"

AI Output Used:
Suggested a task order and overall execution strategy with the following steps:

Architecture decisions.
README skeleton first.
Task 1 IaC.
Architecture diagram.
Terraform validation.
Task 2 multi-tenancy write-up.
Task 3 security controls.
Task 4 CI/CD.
Task 5 monitoring + runbook.
Task 6 compliance.
Optional minimal live AWS proof.
AI log audit
Final repo cleanup


For architecture decisions, recommended the following:
1. Tenancy model
2. IAM boundary model
3. Network segmentation model
4. CI/CD deployment model
5. Compliance approach
6. Secrets management model 
7. Observability model 


---

## Entry 4
Prompt:
"Give me example tenancy models and recommend the best one for my use case"

AI Output Used:
Listed and explained the 3 tenancy models mentioned in the assignment requirements. Also explained pros and cons.
Options listed:
1. Shared Database, tenant_id scoping
2. Schema-per-tenant
3. Database-per-tenant

It recommended Database-per-tenant and said the following:
Your assignment literally says:
1. highly sensitive payroll data
2. strict isolation
3. “no cross-tenant leakage under any condition”
That wording almost pushes you toward this answer.

What I Changed and follow up:
I followed up with question on how database-per-tenent would work given the constraint of using a single RDS DB in the assignment requirements. It asked me to explain it as current model and then keep space for a future preferred model to be DB-per-tenent. Basically to explain it as Demo implementation for assignment scope vs Production target architecture.

---

## Entry 5
Prompt:
"database per tenant would have massive redundancies though and can lead to too much duplication at the requirement's scale"

AI Output Used:
Based on that follow-up, it recommended schema-per-tenant because separate schemas improve isolation while avoiding the duplication of database-per-tenant.

NOTE 1: I eventually choose shared-db and give the reasoning for it below in the appropriate entry(free-tier-aware design). Heads-up, database-enforced tenant isolation is described in the design.

NOTE 2: I had problems with my AI at this point and had to switch up my AI tool and hence may make certain changes to what's been previously decided(schema-per-tenant was previously decided).

---

## Entry 6
Prompt:
"Given the steps I have decided on based on strategy shared, give me a table with non-negotiables (where necessary) for each step and exact output I must produce at the end of that step."

AI output used:
The AI broke the assignment into step-wise checkpoints and paired each step with the concrete deliverable expected at the end of that phase. I used that to structure the work sequence and keep the submission aligned to the mandatory task outputs.

What I changed/follow up:
I used the structure as a planning aid rather than following it mechanically. As implementation progressed, I adjusted the order slightly and refined some decisions in later prompts where the Terraform design, tenancy model, and security documentation needed to stay consistent.

---

## Entry 7
Prompt:
"for each of these architectural decisions listed, and considering the non-negotiables listed, give me the best decisions you would recommend for each of the 12 decisions I must make. 

Decisions: 1) Tenancy model, 2) IAM boundary model, 3) Network segmentation model, 4) CI/CD deployment model, 5) Compliance approach, 6) Secrets management model, 7) Observability model, 8) Compute isolation model, 9) Data storage model, 10) Encryption model, 11) Environment strategy, 12) Live deployment strategy

Non-negotiables: Must state: Terraform not CloudFormation as already started; one VPC across at least 2 AZs; public/private subnets; 3 EC2 instances split by portal type; private PostgreSQL RDS; versioned S3; per-portal IAM roles; SG/NACL isolation; free-tier-aware design. For Task 2, explicitly choose and justify the tenancy model for sensitive payroll data. For Task 3, state no hardcoded secrets, encryption at rest/in transit, least privilege, and private DB posture. For Task 4, pick SSH or SSM deployment model now and do not change later. For Task 6, state UK/EU region pinning and right-to-erasure design now."

AI output used:
The AI provided me with the recommended decisions for each. I shall review these decisions again as I keep moving forward and reach the appropriate sections.

What I changed/follow up:
I had chosen to do schema-per-tenant but upon following up, I came to the conclusion that choosing schema-per-tenant creates a risk: I may sound like I picked the “stronger” model without fully addressing how it is provisioned, migrated, queried, and cleaned up, given the time constraints. Hence executing shared DB with DB-enforced tenant isolation. Also, I considered schema-per-tenant because it offers stronger namespace isolation than simple tenant_id filtering, but I chose a shared PostgreSQL database with mandatory tenant context propagation and database-enforced row-level security because it provides strong tenant isolation with lower operational complexity for onboarding, migrations, and free-tier-aware operation, while still being reinforced by portal-level compute isolation, IAM boundaries, S3 prefix isolation, and private network controls.
I have detailed my resoning for other decisions in the README doc "Architecture Decisions" section.

Final decision used in submission: shared PostgreSQL with tenant-scoped enforcement.
--

## Entry 8
Prompt:
"Build the README skeleton and file map for me, given my current README file looks like this (below). Also mentioned is the non-negotiables below.

**OLD README file was pasted here**

Non-negotiables:
README must include setup instructions, decisions made, trade-offs considered, and Task 6 answers. AI log is mandatory and must be a separate file, so add a README pointer to ai_log.md now. Incident runbook can be separate or in README, but since you already have incident-runbook.md, keep it separate and reference it."

AI output used:
README file skeleton provided along with file structure for the project.

What I changed/follow up:
I asked it to add the file map in the README itself as a follow up.

--

## Entry 9
Prompt:
"Give me the titles of all the sections of README along with the section numbers"

AI output used:
Provided a table with all section numbers

What I changed/follow up:
Easy reference going forward.

--

## Entry 10
Prompt:
"help me finish task 1 now. Specifically help me with this: Build Terraform networking and shared core.
Complete providers.tf, variables.tf, main.tf, network.tf, outputs.tf with AWS provider, region variables, naming tags, VPC, at least 2 AZs, public/private subnets, IGW, route tables, DB subnet group, security group skeletons, and outputs.
Task 1 explicitly requires a VPC with public and private subnets across at least two AZs. Keep database and internal services non-public by design. Do not introduce fancy paid services. Stay free-tier-safe in thinking and naming."

AI output used:
provided code for providers.tf, variables.tf, main.tf, network.tf, and outputs.tf

What I changed/follow up:
Entry output was discarded eventually as new .tf files resulted in changes in older files.

--

## Entry 11
Prompt:
"as per the instructions detailed below and as per the requirements of the assignment, generate the final versions of the necessary files mentioned in the instructions. 

Build Terraform networking and shared core.
Complete providers.tf, variables.tf, [main.tf](http://main.tf/), network.tf, outputs.tf with AWS provider, region variables, naming tags, VPC, at least 2 AZs, public/private subnets, IGW, route tables, DB subnet group, security group skeletons, and outputs.
Task 1 explicitly requires a VPC with public and private subnets across at least two AZs. Keep database and internal services non-public by design. Do not introduce fancy paid services. Stay free-tier-safe in thinking and naming.

Build Terraform compute, database, and object storage.
Complete main.tf/rds.tf/s3.tf with 3 EC2 instances or a reusable EC2 pattern instantiated three times for Companies, Bureaus, Employees; PostgreSQL db.t3.micro; private subnet placement for RDS; S3 bucket for payroll docs/reports with versioning and encryption.
Task 1 requires one EC2 instance per tenant type to reflect isolation at compute layer. RDS must be PostgreSQL db.t3.micro in a private subnet. S3 must have versioning enabled. Do not hardcode DB credentials anywhere because Task 3 forbids hardcoded credentials.

Build IAM and access boundary layer.
Complete iam.tf with separate portal roles/policies and instance profiles if applicable; define S3 access pattern per portal and, if you go one level deeper, per tenant prefix strategy inside each portal area.
Task 1 requires IAM roles scoped per tenant boundary. Task 2b requires separate IAM roles for Company, Bureau, Employee with access strictly limited to their resources, plus S3 bucket policy or prefixes preventing cross-access. Task 3a requires least-privilege roles and no role with access outside its boundary.

Build network security rules.
Finish Security Groups and NACLs in network.tf.
Task 1 requires SGs and NACLs configured to isolate traffic between tenant environments. Task 3d requires traffic restricted strictly to what is required, internal services not publicly accessible, and an explanation of how one tenant’s traffic cannot reach another tenant’s compute/data layer."

AI output used:
The output produced included files: providers.tf, variables.tf, main.tf, network.tf, rds.tf, s3.tf, iam.tf, outputs.tf.

What I changed/follow up:
A few follow-up prompts were needed to ensure consistency across the generated Terraform files. I was suggested to run init and validate as well for terraform files, which I did.

--

## Entry 12
Prompt:
"│ Error: Cycle: aws_security_group.portal_ec2, aws_security_group.rds"

AI output used:
Explained circular dependency and then made the required corrections.

What I changed/follow up:
split SG rules into separate resources to remove the circular dependency.

--

## Entry 13
Prompt:
"Task 1 explicitly asks for a clear architecture diagram. The diagram must match the Terraform exactly. No fantasy components. Simplicity and readability beat style. If you can't generate, guide me to draw it on draw.io"

AI output used:
Produced mermaid(.mmd) file.

What I changed/follow up:
I followed up on steps to use the .mmd file with draw.io (editing text, shapes, etc) and generated a .png file and .drawio file.

--

## Entry 14
Prompt:
"Below attached is the README file. Suggest necessary additions based on all the final generated .tf files in this thread(providers.tf, variables.tf, main.tf, network.tf, rds.tf, s3.tf, iam.tf, outputs.tf, etc). For network.tf, add README notes describing exact allowed traffic paths.
Also add terraform fmt and terraform validate, i.e add validation commands to README."
#README file was attached.

AI output used:
Suggested additions based on the README skeleton designed earlier and provided prompt.

What I changed/follow up:
I edited the README file as per the generated response, wherever the relevant points related to particular .tf file made sense to the AI. Also the traffic paths for network.tf and terraform validation commands README data was also obtained.

--

## Entry 15
Prompt:
"task 2 description:
Help me with Task 2 with sections 2a Tenant Isolation Strategy, 2b Access Boundaries at Infrastructure Layer, 2c Tenant Onboarding & Offboarding.
Task 2a: choose and justify one tenancy model and explain why it fits sensitive payroll data; explain login tenant context establishment, request propagation, and guaranteed query/API isolation with no cross-tenant leakage. Task 2b: define separate IAM roles, S3 isolation, and infrastructure as second enforcement boundary if app logic fails. Task 2c: describe what gets created during onboarding, how isolation exists from day one, and how offboarding handles data deletion, access revocation, and audit trail"

AI output used:
Produced the task2-multi-tenancy.md document.

What I changed/follow up:
Added the produced output in the docs folder. Also made a reference to it in the README.md file and I also stuck with the decisions made during Architecture decisions, which can affect future tasks, in order to complete the task 2 requirements. Followed up with the AI to ensure this.

Decisions to stick with- Task 3 should reuse the same three IAM roles, private RDS stance, no hardcoded secrets, encryption at rest and in transit, and SG/NACL isolation.
Task 4 uses SSM instead of SSH.
Task 5 should treat CloudWatch, SNS, and log groups as extensions of this same layered boundary model.
Task 6 should extend offboarding into right-to-erasure language for database rows, S3 objects, access revocation, and audit evidence.

--

## Entry 16
Prompt:
"help with task 3 now. Below are the instructions:

Task 3a, Task 3b, Task 3c, Task 3d
Write the security section and align Terraform/comments to it.
Fill README Task 3 with four subsections: 3a IAM & RBAC, 3b Secrets Management, 3c Encryption, 3d Network Security; add missing Terraform settings/comments if needed (to the files in the thread earlier).
Task 3a: least privilege, separate access boundaries, no hardcoded creds. Task 3b: use AWS Secrets Manager or SSM Parameter Store, and explain runtime injection without exposing secrets in code/logs. Task 3c: enable encryption at rest for RDS and S3, configure SSL/TLS for exposed services, and document data in transit protection. Task 3d: restrict traffic, keep DB/internal services private, prevent tenant-to-tenant reachability.

Also ensure, Task 3 should reuse the same three IAM roles, private RDS stance, no hardcoded secrets, encryption at rest and in transit, and SG/NACL isolation."

AI output used:
Suggested to use SSM Parameter Store as it is the cleanest addition to the .tf files. Created secrets.tf, and appended iam.tf, outputs.tf. Also added README.md additions for tasks 3a(IAM & RBAC), 3b(Secrets Management), 3c(Encryption) and 3d(Network Security), in the indicated respective sections of the file.

What I changed/follow up:
I followed up to help fix terraform validation error using init command and then validated again.
(Error: missing or corrupted provider plugins:
│ - registry.terraform.io/hashicorp/aws: the cached package for registry.terraform.io/hashicorp/aws 5.100.0 (in .terraform/providers) does not match any of the checksums recorded in the dependency lock file
│ - registry.terraform.io/hashicorp/random: the cached package for registry.terraform.io/hashicorp/random 3.8.1 (in .terraform/providers) does not match any of the checksums recorded in the dependency lock file)

--

## Entry 17
Prompt:
"help complete task 4 with the following requirements:
Build CI/CD workflow and Docker placeholder app.
Complete .github/workflows/deploy.yml and docker/Dockerfile; README Task 4 explains trigger, build/test, deployment path, and env config handling.
Task 4 requires the pipeline to run on every push to main, build and test a simple Dockerised app, deploy to EC2 using AWS SSM, and handle environment-specific config without exposing secrets in pipeline YAML. It must also allow frontend, backend, and AI teams to trigger deployments independently without interfering with each other, so design jobs or paths/service inputs accordingly.

Also ensure Task 4 should keep the selected deployment path fixed and not switch later between SSH and SSM. SSM was selected for task 3"

AI output used:
Added 2 files to repo: .github/workflows/deploy.yml & docker/Dockerfile. Also made README.md additions to Section 12 of the file. This workflow assumes the repo is publicly downloadable for assignment use because the remote EC2 host pulls the archive from GitHub over HTTPS.
The placeholder app itself is the docker/Dockerfile, which writes a tiny Python HTTP server exposing / and /health

What I changed/follow up:
Accepted the workflow structure, kept SSM as the fixed deployment path, and added the generated CI/CD details to README Section 12.

--

## Entry 18
Prompt:
"help me with task 5 now. 
the requirements are as follows:
Build monitoring config and docs.
Complete monitoring.tf and README Task 5 with EC2 CPU alarm, RDS connection alarm, CloudWatch log groups with retention, and SNS critical alert.
Task 5 explicitly requires CloudWatch alarms for EC2 CPU utilisation and RDS connection thresholds, CloudWatch log groups for app/infrastructure logs with a sensible retention policy, and at least one SNS alert for critical failure. Use realistic thresholds and say what each alert protects against.

Also ensure Task 5 should treat CloudWatch, SNS, and log groups as extensions of this same layered boundary model."

AI output used:
monitoring.tf was generated and added to the repo. Also additions were appended to variables.tf & outputs.tf. Task 5 explicitly requires CloudWatch alarms, log groups, and SNS alerting, so README Section 13 was added with info about what is monitored, why the thresholds were chosen, and how this extends the same layered boundary model already used in IAM, network, and storage.

What I changed/follow up:
I got error while validating the terraform files where local .terraform/providers cache did not match .terraform.lock.hcl, so terraform validate failed checksum verification. Performed the init and validation steps again.

--

## Entry 19
Prompt:
"Also need to close this from task 5:
Task 5 incident readiness: Write the runbook.
Finish incident-runbook.md with detection, investigation, containment, remediation, validation, recovery, and preventive follow-up steps for an RDS instance accidentally made public.
Task 5 explicitly asks for a brief incident response runbook covering how you would detect, investigate, and recover from a DB being accidentally made publicly accessible. Include concrete actions: confirm exposure, remove public access, tighten SG/NACL, review logs, rotate secrets if warranted, validate no unauthorized access, document incident."

AI output used:
Updated the incident-runbook.md file from the AI output, and I also added an entry in the README.md file in Section 13.

What I changed/follow up:
Made it one page as a follow up.

--

## Entry 20
Prompt:
"Let us close task 6 now and follow the below requirement:
Fill README.md Task 6 with three direct answers and no fluff.
Task 6 requires answers to exactly these three questions: what AWS-native controls help UK GDPR for employee PII and bank data; how you ensure data residency within UK/EU; how you permanently delete an employee’s data across all services for right to erasure. Keep it concrete: region selection, encryption, access controls, logs, retention, deletion workflow, and proof/audit trail.
Ensure that Task 6 should extend offboarding into right-to-erasure language for database rows, S3 objects, access revocation, and audit evidence."

AI output used:
Put the generated output in README.md section 14. Also explicity added tenent offboarding details in section 11 of the same doc.

What I changed/follow up:
accepted with minor wording edits and inserted into Section 14.

--

## Entry 21
Prompt:
"update the below mermaid code to extend the architecture diagram with new additions to the architecture post the completion of task 1 from the assignment. 

Old mermaid code:
flowchart LR
    U[Internet users\\nCompanies / Bureaus / Employees]
    S3[S3 bucket\\npayroll docs / reports\\nversioning + AES256 + public access block]
    IAM[IAM tenant roles + instance profiles\\ncompany / bureau / employee\\nS3 prefixes scoped per tenant]

    subgraph REGION[AWS Region eu-west-2]
      subgraph VPC[VPC 10.20.0.0/16]
        IGW[Internet Gateway]

        subgraph AZ1[Availability Zone eu-west-2a]
          subgraph PUB1[Public subnet 1\\n10.20.1.0/24\\npublic route table\\npublic NACL]
            CEC2[EC2 Companies portal\\nt3.micro]
            EEC2[EC2 Employees portal\\nt3.micro]
          end
          subgraph APP1[Private app subnet 1\\n10.20.11.0/24\\nprivate app route table\\nprivate app NACL]
            A1[Reserved internal services space]
          end
          subgraph DB1[Private DB subnet 1\\n10.20.21.0/24\\nprivate DB route table\\nprivate DB NACL]
            RDS[RDS PostgreSQL db.t3.micro\\npublicly_accessible=false]
          end
        end

        subgraph AZ2[Availability Zone eu-west-2b]
          subgraph PUB2[Public subnet 2\\n10.20.2.0/24\\npublic route table\\npublic NACL]
            BEC2[EC2 Bureaus portal\\nt3.micro]
          end
          subgraph APP2[Private app subnet 2\\n10.20.12.0/24\\nprivate app route table\\nprivate app NACL]
            A2[Reserved internal services space]
          end
          subgraph DB2[Private DB subnet 2\\n10.20.22.0/24\\nprivate DB route table\\nprivate DB NACL]
            DBSG[DB subnet group coverage]
          end
        end
      end
    end

    U --> IGW
    IGW --> CEC2
    IGW --> EEC2
    IGW --> BEC2

    CEC2 -->|5432 only via SG rule| RDS
    EEC2 -->|5432 only via SG rule| RDS
    BEC2 -->|5432 only via SG rule| RDS

    CEC2 --> S3
    EEC2 --> S3
    BEC2 --> S3

    IAM -. attach instance profile .-> CEC2
    IAM -. attach instance profile .-> EEC2
    IAM -. attach instance profile .-> BEC2

New expected additions:
Add these to the final end-to-end diagram once you implement those tasks:
SSM Parameter Store — for DB credentials, API keys, and runtime secret injection.
GitHub Actions — showing the CI/CD path from repository push to build/test and deployment to EC2 via SSH or AWS Systems Manager.
CloudWatch — for EC2 CPU alarms, RDS connection alarms, log groups, and monitoring visibility.
SNS — for critical alert notifications triggered by CloudWatch alarms.
Optional diagram additions
These are not always standalone AWS boxes, but they may need to be represented in labels or arrows in the final diagram because the brief expects them conceptually:
Secret injection path from Secrets Manager/SSM to the application runtime.
Deployment path from GitHub Actions to EC2 through SSM or SSH.
Monitoring path from EC2/RDS/logs into CloudWatch, then from CloudWatch to SNS.
Tenant-scoped S3 prefix boundary note if you want the diagram to reflect Task 2b more explicitly.

Refer the final generated .tf files in the thread and add anything I may have missed as well."

AI output used:
Provided the new mermaid code.

What I changed/follow up:
I generated the diagram on draw.io using the mermaid code. I used a follow-up prompt to cross-check that the final diagram still matched the Terraform resources and traffic paths.

--