**Overview:-**

This project implements a comprehensive Crime Record and Investigation Database using PostgreSQL. It is designed to store, organize, and analyze real-world criminal investigations—tracking cases, suspects, officers, evidence, witnesses, and case outcomes. The system provides advanced auditing (e.g., for evidence chain-of-custody), complex analytical queries, officer workload reporting, and flexible export of investigation summaries.

**Main Use Cases:**
Storing all entities and events involved in criminal investigations

Supporting real-world data integrity (with foreign keys, triggers, audit/history logging)

Querying for reporting, analysis, and decision support

User-friendly investigation summary exports

**Schema:** Database Structure
Entity relationships have been carefully designed for normalization, traceability, and performance.

cases_record: Tracks each criminal case (type, category, status, assigned officers, timeline, outcome).

officers: Police or investigative officers (roles, rank, department, assignments).

suspects: Individual suspects with their profiles and histories.

evidence: Records all evidence, its custody chain, collection details, and court eligibility.

witnesses: Details of witnesses, their statements, and reliability.

case_suspects, case_officers: Many-to-many relationships for suspects/officers per case.

forensic_analysis: Stores forensic work performed on evidence.

case_timeline: Tracks significant events in each case (arrests, evidence collected, etc).

crime_statistics: Aggregated stats for crime analysis and reporting.

**Key Features & How They Meet Project Criteria**
1. Well-Defined Relational Schema
10+ normalized tables with all relationships and integrity constraints.

Example (table creation): See schema.sql or below.

2. Indexing
Optimized search and analytic queries with indexes on:

Case IDs, statuses, crime category, officer and suspect names, etc.

3. Advanced Analytical Queries
Solved/unsolved, status, and time-to-resolution reporting

Analysis of officer workloads, department/case performance

Long-running, unsolved cases

4. Officer Workload Views
officer_workload_summary: Per-officer case statistics and real-time workload status

officer_active_cases: List of ongoing assignments

department_workload: Aggregate performance and vertical reporting

overloaded_officers_alert: Alert view identifying overloaded officers

5. Audit/Trigger for Evidence Chain
Logs every change to evidence.chain_of_custody in a dedicated audit table (compliant with legal traceability)

See triggeres.sql: includes PL/pgSQL trigger function and demonstration queries

6. Summaries & Reporting/Export
User-facing views and a function for exporting detailed investigation summaries

Example: case_summary_export view; generate_case_investigation_report() function for reports per case


