---
name: rfc-adr-curator
description: Manages the lifecycle of architectural designs and feature proposals from inception (RFC), through implementation tracking, to permanent archival as Architecture Decision Records (ADRs). Helps agents review proposals against historical context, decompose approved designs into actionable tickets, and distill chaotic comment threads into clean, immutable ADRs.
license: Apache-2.0
metadata:
  author: Ivan De Marino (http://github.com/detro)
  version: 1.0.0
---

# RFC/ADR Curator

This skill manages the lifecycle of architectural design documents and feature proposals from early brainstorming (RFC) to production implementation and final archival as Architecture Decision Records (ADRs). It implements a Git-Ops approach to architecture governance, ensuring technical context is never lost.

## When to Use

- **Inception & Review Phase**: When a new feature or architectural change is proposed, and needs to be analyzed, reviewed against historical context, and debated.
- **Implementation Transition**: When an RFC is approved and needs to be broken down into actionable development tickets (e.g., GitHub Issues) to lock implementation scope.
- **Final Archival / Done Phase**: When implementation is complete, and the chaotic discussion needs to be distilled into a clean, immutable, and indexed Architecture Decision Record (ADR) in the repository.

## When Not to Use

- **Routine Bug Fixes**: For small codebase changes, hotfixes, or refactorings that do not affect system architecture or require cross-team consensus.
- **Product Requirement Docs (PRDs)**: This skill focuses on the *technical* "how", not the product "what" or business user stories, although it can be triggered by a PRD.

## Inputs

| Input            | Required | Description                                                                               |
|------------------|----------|-------------------------------------------------------------------------------------------|
| `workspace_path` | Yes      | The absolute path to the project root repository.                                         |
| `phase`          | Yes      | One of: `review`, `implement`, or `archive`.                                              |
| `document_path`  | Yes      | The path to the target RFC markdown file being processed.                                 |
| `issue_tracker`  | No       | Target tracker for ticket decomposition (e.g., `github` or `jira`). Defaults to `github`. |

## Workflow

### Step 1: Detect Phase and Validate Configuration

The agent must identify which of the three lifecycle phases to execute based on the `phase` input, and verify the repository has the standard document directories.

*Why: Validating directories upfront prevents the agent from creating documents in arbitrary folders, keeping the knowledge base organized and clean.*

1. Scan the repository for existing directories:
   - `/docs/rfcs/` (Active and proposed Requests for Comments)
   - `/docs/adrs/` (Permanent, immutable Architecture Decision Records)
   - `/docs/archived-rfcs/` (Closed or superseded RFC documents)
2. If these directories do not exist, create them under the project root.
3. Check if an index file `/docs/adrs/README.md` exists. If not, initialize it as the ADR catalog.

### Step 2: Execute Phase-Specific Tasks

Based on the validated phase, perform one of the following procedures:

#### Phase A: Inception & Review (`phase=review`)

The agent acts as an automated "devil's advocate" and historical reviewer for a newly proposed RFC markdown file.

*Why: Automated reviews prevent architectural regression by matching new proposals against past engineering mistakes and decisions documented in existing ADRs.*

1. **Parse the RFC**: Read the target RFC document (typically from a PR or local draft). Extract the proposed design, data models, and system integrations.
2. **Context-Match against past ADRs**:
   - Run a vector search or regex search (using `grep`/`rg`) across all existing files in `/docs/adrs/` for keywords matching the technologies, data models, or patterns in the RFC.
   - Look for conflicts or lessons learned (e.g., "We migrated off database X in ADR-0012 because of performance").
3. **Analyze Code Ownership**:
   - Check the `git log` or `git blame` of the code files touched/replaced by the proposal.
   - Identify the primary authors of those systems.
4. **Post Insights**:
   - Generate a structured review comment pointing out potential risks, edge cases, and architectural alignment.
   - Explicitly cite matching ADRs (e.g., *"This proposal introduces an N+1 query pattern that caused an outage in ADR-0024"*).
   - Suggest tagging the primary authors identified in the previous step.

#### Phase B: Transition to Implementation (`phase=implement`)

Once human reviewers reach consensus and approve the RFC, the agent locks the scope and automates issue decomposition.

*Why: Decomposing the design into granular, trackable tickets bridges the gap between high-level architecture and daily development tasks, preventing scope creep.*

1. **Update Document Status**:
   - Edit the RFC frontmatter to change `status` to `Accepted` or `Implementing`.
   - Add the approval date and list of human approvers to the frontmatter or header.
2. **Extract Requirements**:
   - Parse the "Implementation Plan" or "Milestones" section of the RFC.
   - Identify discrete tasks: database migrations, backend services, API contracts, frontend changes, and testing.
3. **Decompose and Create Tickets**:
   - For each task, generate a detailed technical description including dependencies, targeted files, and testing criteria.
   - Use the platform's API or CLI tools (e.g., `gh issue create`) to create tickets automatically.
   - Add a reference link to the approved RFC file in each created ticket.
4. **Link the Branch**:
   - Create or suggest a branch naming convention derived from the RFC ID (e.g., `feature/rfc-0042-auth`).

#### Phase C: Archival & ADR Distillation (`phase=archive`)

Once the implementation tickets are completed and merged, the agent transitions the design into a permanent historical record.

*Why: Distilling the chaotic RFC into an ADR keeps the documentation base crisp. It strips away outdated brainstorms and comment threads, leaving only the final engineering truth.*

1. **Locate the Completed RFC**: Ensure the corresponding code branch is merged and all relevant tickets are closed.
2. **Distill RFC into an ADR**:
   - Create a new markdown file under `/docs/adrs/` using the naming pattern `NNNN-title.md` (e.g., `0024-migration-to-postgres.md`), where `NNNN` is the auto-incremented index of the next ADR.
   - Format the ADR using the clean template below, capturing only the *final decision*, *context*, and *consequences*. Strip out the messy comment threads and discarded alternatives of the RFC.
3. **Update indices and files**:
   - Move the original RFC file from `/docs/rfcs/` to `/docs/archived-rfcs/`.
   - Update the status in the RFC's frontmatter to `Superseded` or `Archived`, pointing to the new ADR path.
   - Append the new ADR to the table of contents in `/docs/adrs/README.md`.
4. **Commit the Changes**:
   - Commit the new ADR, the moved RFC, and the updated index to git.

---

## ADR Template

Ensure all distilled ADR files follow this exact structure:

```markdown
# ADR-NNNN: <Title of Decision>

* **Status**: Approved
* **Date**: YYYY-MM-DD
* **Author(s)**: <Author Names>
* **Decided by**: <Reviewer/Approver Names>
* **RFC Reference**: [RFC-MMMM](../archived-rfcs/rfc-MMMM.md)

## Context and Problem Statement

<Describe the context, requirements, and what problem needed solving. Keep this concise and factual.>

## Decision Outcome

We decided to:
* <Action item 1>
* <Action item 2>

Because:
* <Reasoning 1: performance, cost, simplicity, etc.>
* <Reasoning 2>

## Consequences

### Positive
* <Benefit 1>
* <Benefit 2>

### Negative / Risks
* <Tradeoff 1>
* <Tradeoff 2>

## Technical Details (Implementation Summary)

* **Data Model Changes**: <Brief description or schema updates>
* **Impacted Services**: <List of systems updated>
* **Testing Strategy**: <How it was verified>
```

---

## Validation

- [ ] Repository directories `/docs/rfcs/`, `/docs/adrs/`, and `/docs/archived-rfcs/` exist.
- [ ] Active RFC files contain frontmatter with `status` and `date`.
- [ ] Distilled ADR files have a unique sequential ID (`NNNN`) that matches the file prefix.
- [ ] The catalog `/docs/adrs/README.md` is updated with a reference to the new ADR.
- [ ] Closed RFCs are cleanly moved to `/docs/archived-rfcs/` to prevent cluttering the active proposals folder.

## Common Pitfalls

| Pitfall                         | Solution                                                                                                                                                   |
|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Archiving too early**         | Ensure all implementation tickets are closed and merged before distilling an RFC into an ADR.                                                              |
| **Lost architectural context**  | When distilling the RFC to ADR, do not discard critical negative consequences or trade-offs that were discussed, as they are essential for future readers. |
| **Out-of-sequence ADR numbers** | Always check the active index `/docs/adrs/README.md` and file list to ensure the next available sequential number is used for a new ADR.                   |
