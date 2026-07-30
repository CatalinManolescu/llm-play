# Data Governance for Large Language Models (LLMs)

## Overview

Data governance for Large Language Models (LLMs) is the framework of policies, controls, and operational processes that govern:

- What data enters AI systems
- What data leaves AI systems
- Who can access AI capabilities and data
- How AI-generated outputs are used

Effective governance ensures AI systems operate securely, maintain regulatory compliance, protect sensitive information, and provide accountability across the entire AI lifecycle.

## Governance Domains

### Training and Data Ingestion  Governance

This area focuses on controlling the data used to train, fine-tune, or enrich AI models.

#### Key Controls

- Validate and approve training datasets before use
- Remove or redact Personally Identifiable Information (PII)
- Track consent and data usage rights
- Maintain full data lineage and provenance records
- Detect and prevent poisoned, manipulated, or biased training data

#### Risks Mitigated

- Privacy violations
- Regulatory non-compliance
- Biased model behavior
- Model poisoning attacks

### Input Governance (Prompt Control)

Input governance controls what users and systems can send to an LLM.

#### Key Controls

- Detect and filter sensitive information before it reaches the model
- Prevent exposure of secrets, intellectual property, and regulated data
- Mitigate prompt injection attacks
- Enforce role-based access controls for AI capabilities

#### Examples

Sensitive information that should be filtered or blocked includes:

- API keys
- Passwords
- Access tokens
- Customer PII
- Proprietary source code
- Confidential business information

#### Risks Mitigated

- Data leakage
- Unauthorized access
- Prompt manipulation
- Compliance violations

### Output Governance

Output governance ensures AI-generated content is safe, compliant, and appropriate.

#### Key Controls

- Audit and log AI responses
- Detect and prevent sensitive data leakage
- Apply toxicity and content filtering
- Monitor hallucinations and inaccurate outputs
- Enforce response review processes for high-risk use cases

#### Risks Mitigated

- Confidential data exposure
- Harmful or inappropriate content
- Regulatory violations
- Reputational damage

### Retrieval-Augmented Generation (RAG) Governance

RAG systems enhance LLM responses by retrieving information from external knowledge sources. Governance ensures retrieval mechanisms respect organizational access controls.

#### Key Controls

- Restrict document access based on user permissions
- Apply authorization checks before retrieval
- Maintain source attribution and traceability
- Ensure data freshness and synchronization with source systems

#### Governance Principle

A user must never gain access to information through an AI system that they would not be able to access directly.

#### Risks Mitigated

- Unauthorized information disclosure
- Permission bypasses
- Stale or outdated responses
- Lack of response traceability

### Agentic AI Governance

Agentic AI systems can autonomously plan, reason, and perform actions using tools, APIs, databases, and external systems.

Because these systems execute actions rather than simply generate content, they require the strongest governance controls.

#### Key Controls

**Tool and Action Authorization**

Define which tools, systems, APIs, and databases an agent can access.

**Blast Radius Control**

Limit the scope of potential damage from incorrect, malicious, or unexpected actions.

**Human-in-the-Loop Approval**

Require human approval before high-risk or irreversible actions.

**Auditability**

Maintain complete traceability of agent decisions and actions.

#### Risks Mitigated

- Unauthorized changes
- System outages
- Excessive automation
- Security incidents
- Regulatory non-compliance

## Governance Concerns and Organizational Controls

### Core Governance Concerns

| Concern | Description |
|----------|-------------|
| Privacy | AI systems storing or exposing user data and conversations |
| Compliance | Meeting GDPR, HIPAA, SOC2, and other regulatory requirements |
| Shadow AI | Employees using unapproved AI tools with corporate data |
| Data Residency | Ensuring data is processed and stored in approved geographic regions |
| Model Drift | Changes in model behavior over time without governance review |

### Data Governance in a DevSecOps Environment

When using AI-powered development assistants, controls should implement for:

#### Source Code Protection

- Control which repositories and codebases can be accessed
- Prevent proprietary code from being used in unauthorized contexts

#### Secure Code Generation

- Ensure generated code does not reproduce protected training data
- Monitor outputs for licensing and intellectual property risks

#### Activity Logging

- Retain audit logs of AI interactions
- Enable investigations and compliance reviews

#### Repository Scope Enforcement

- Restrict AI assistants to authorized projects only
- Apply least-privilege access principles

## Agentic AI Governance Patterns

### Pattern 1: Least-Privilege Tool Authorization

Agents should be granted only the permissions necessary to complete a task.

#### Best Practices

- Use tool allowlists
- Default to read-only permissions
- Issue short-lived credentials
- Separate agent identities from human identities

#### Example Policy

```yaml
agent_policy:
  name: code-review-agent
  allowed_tools:
    - read_repository
    - read_merge_request
    - post_comment
  denied_tools:
    - delete_branch
    - modify_pipeline
    - access_secrets
  token_ttl: 3600
```

#### Benefits

- Reduces attack surface
- Limits misuse opportunities
- Improves accountability

### Pattern 2: Human-in-the-Loop Checkpoints

Require human approval before risky actions are performed.

#### Recommended Risk Framework

| Risk Level | Example Action | Control |
|------------|----------------|----------|
| Low | Read files, summarize content | Automated |
| Medium | Create issues, post comments | Log and notify |
| High | Merge code, deploy applications | Human approval required |
| Critical | Delete data, modify permissions | Block and escalate |

#### Best Practices

- Define risk classification policies
- Implement approval workflows
- Record approver identity
- Include timeout and escalation procedures

### Pattern 3: Blast Radius Containment

Limit the impact of agent failures or malicious behavior.

#### Controls

##### Sandboxing

Run agents in isolated environments with no default production access.

##### Rate Limiting

Restrict the number of actions allowed during execution.

**Example:** Maximum of 10 file modifications per session.

##### Rollback Mechanisms

Enable recovery from agent actions whenever possible.

##### Scope Fencing

Restrict agents to:

- Specific projects
- Namespaces
- Repositories
- Data domains

### Pattern 4: Prompt Injection Defense

Prompt injection occurs when untrusted content attempts to manipulate agent behavior.

#### Common Malicious Instructions

- "Ignore previous instructions"
- "You are now..."
- "Disregard all previous guidance"

#### Mitigation Strategies

- Separate system prompts from retrieved content
- Treat all external content as untrusted
- Validate outputs before execution
- Scan retrieved content for instruction-like patterns

#### Example Detection Logic

```python
import re

def sanitize_retrieved_content(content: str) -> str:
    injection_patterns = [
        r"ignore (all |previous )?instructions",
        r"you are now",
        r"new system prompt",
        r"disregard (your |all )?previous"
    ]

    for pattern in injection_patterns:
        if re.search(pattern, content, re.IGNORECASE):
            raise ValueError(
                "Potential prompt injection detected"
            )

    return content
```

### Pattern 5: Full Decision Chain Auditability

Every agent action should be traceable back to the originating request.

#### Audit Records Should Include

- User identity
- Session identifier
- Original objective or prompt
- Tool usage records
- Inputs and outputs
- Timestamps
- Human approvals
- Final actions performed

#### Example Audit Record

```json
{
  "session_id": "agt-20260729-abc123",
  "user_id": "user-456",
  "goal": "Review and summarize open merge requests",
  "steps": [
    {
      "step": 1,
      "tool": "list_merge_requests",
      "input": {
        "state": "opened",
        "project_id": 789
      },
      "output": "[MR #101, MR #102]",
      "timestamp": "2026-07-29T10:00:01Z"
    },
    {
      "step": 2,
      "tool": "read_merge_request",
      "input": {
        "id": 101
      },
      "output": "{ title: 'Fix login bug', diff: '...' }",
      "timestamp": "2026-07-29T10:00:03Z"
    }
  ],
  "final_action": "post_comment",
  "approved_by": null,
  "completed_at": "2026-07-29T10:00:10Z"
}
```

## Retrieval-Augmented Generation (RAG) Governance Controls

### The Permission Gap

Without proper controls, a RAG system may expose restricted information.

#### Example

```text
User (Low Privilege)
        ↓
Asks Question
        ↓
RAG Retrieves Restricted Document
        ↓
LLM Summarizes Content
        ↓
User Receives Restricted Information
```

#### Key Principle

Access control must be enforced **before** documents are retrieved and passed to the model.

### Control 1: Pre-Retrieval Identity Propagation

User identity and permissions must be passed to the retrieval system.

#### Requirements

- Apply permission filtering during retrieval
- Limit search results to authorized content
- Enforce security controls within the vector database

#### Example

```python
def retrieve_documents(query: str, user_context: UserContext):
    permission_filter = {
        "accessible_projects": user_context.project_ids,
        "clearance_level": user_context.clearance,
        "group_memberships": user_context.groups
    }

    return vector_store.search(
        query=query,
        top_k=10,
        filter=permission_filter
    )
```

#### Why Retrieval-Time Enforcement Matters

Post-retrieval filtering can still expose information because the model has already processed restricted content.

### Control 2: Document-Level Access Metadata

Every document should be tagged during ingestion.

#### Example Metadata

```json
{
  "document_id": "doc-789",
  "content": "Q3 financial projections...",
  "access_metadata": {
    "owner_group": "finance-team",
    "visibility": "internal",
    "allowed_roles": [
      "finance-analyst",
      "executive"
    ],
    "data_classification": "confidential",
    "expiry": "2026-12-31"
  }
}
```

#### Governance Requirements

- Mirror source-system permissions
- Synchronize permission updates
- Remove expired or deleted content
- Maintain classification metadata

### Control 3: Dynamic Permission Synchronization

Permissions change over time and must remain synchronized.

#### Recommended Process

```text
Permission Change
        ↓
Event Trigger
        ↓
Update Document Metadata
        ↓
Update Vector Store
        ↓
Remove Revoked Content Immediately
```

#### Key Principle

When access is revoked in the source system, access must be revoked immediately in the AI retrieval layer.

### Control 4: Source Attribution and Transparency

Responses should identify the documents used to generate answers.

#### Example Response

> Based on the Security Policy v2.3, the approved deployment window is Tuesday–Thursday between 10:00–16:00 UTC.

#### Sources

- Security Policy v2.3
- Deployment Runbook

#### Benefits

- Improved trust
- Easier validation
- Better audit capability
- Stronger governance

### Control 5: Sensitive Data Detection During Ingestion

Prevent sensitive content from entering the RAG index.

#### Scan For

**Personally Identifiable Information (PII)**

- Names
- Email addresses
- National identifiers

**Secrets**

- API keys
- Passwords
- Tokens

**Intellectual Property**

- Proprietary source code
- Product roadmaps
- Confidential designs

**Regulated Data**

- Payment card information
- Healthcare records

#### Example Process

```python
def pre_ingestion_scan(document):
    pii_detected = pii_scanner.scan(document.content)
    secrets_detected = secret_scanner.scan(document.content)

    if secrets_detected:
        raise IngestionBlockedError(
            "Secrets detected"
        )

    if pii_detected:
        document.content = pii_redactor.redact(
            document.content
        )
        document.access_metadata[
            "contains_redacted_pii"
        ] = True

    return document
```

## Governance Architecture

### Combined Governance Architecture

A secure and governed AI architecture should include controls at every stage of the AI lifecycle.

```text
User Request
     ↓
Identity & Authentication Layer
     ↓
Input Sanitization
     ↓
RAG Retrieval with Permission Filters
     ↓
Prompt Injection Detection
     ↓
LLM / Agent Execution
     ↓
Output Filtering
     ↓
Audit Logging
     ↓
User Response with Source Attribution
```

## Key Takeaways

1. Data governance extends beyond model training and includes inputs, outputs, retrieval systems, and agent actions.
2. RAG systems must enforce permissions before retrieval, not after.
3. Agentic AI requires least-privilege access, human approvals, and blast-radius controls.
4. Prompt injection and data leakage are critical risks that require dedicated safeguards.
5. Comprehensive auditability is essential for security, compliance, and accountability.
6. Governance should be embedded throughout the entire AI workflow—from ingestion to final response delivery.
