# Oprisk database project

Oprisk Database Project is designed to automate a typical Operational Risk Management (ORM) framework used in banks and companies. It provides a structured relational database that enables risk managers to record and analyze incidents (loss events), define and assess risks, manage controls and mitigation measures, and monitor key risk indicators (KRIs).

The system supports full CRUD operations and incident workflows (from reporting to closure), linkage between risk objects, and soft deletion for critical records. While advanced analytics, audit logs, and dashboards are beyond this MVP, the database provides a solid foundation for scalable risk management automation.

Developed as a final project for CS50’s SQL course by Harvard University (2025).

## Specification

The project is composed of four files:

- [`DESIGN.md`](./oprisk_db/DESIGN.md), which is a rigorous design document describing Oprisk database’s purpose, scope, entities, relationships, optimizations, and limitations. The goal of the design document is to make my thinking visible. The design document includes:
  - An entity relationship diagram for the database.
  - A short video overview of the project.
- [`schema.sql`](./oprisk_db/schema.sql), which is an annotated set of `CREATE TABLE`, `CREATE INDEX`, `CREATE VIEW`, etc. statements that compose the database’s schema.
- [`test_data.sql`](./oprisk_db/test_data.sql), which is an annotated set of `INSERT` statements that feeds test data to the database’s schema.
- [`queries.sql`](./oprisk_db/queries.sql), which is an annotated set of `SELECT`, `UPDATE`, `DELETE`, etc. statements that users will commonly run on the Oprisk database.


You can explore comments inside the .sql files to get more details and hands-on instructions. 

## Further enhancements

Later the project was further developed to include the following:

1. Basel taxonomy (event types, business lines and link to internal risk categories).
2. Entity-specific audit tables and triggers (incident_audit, measure_audit, etc.).
3. Custom incident routing/early notifications (e.g. IT events in Retail auto routed to IT Ops Retail BU).
4. Stage-specific required fields – mandatory data entry for each stage of the incident workflow.
5. SLA-based monitoring - defines allowed X/Y/Z days for an incident to remain in a given state; triggers notifications for overdue items.
6. Simplified event types for UI to ensure early notifications for critical events.
7. Unified notifications table for all entities (incidents, measures, KRIs, etc.).
8. Plus some minor adjustments and refinements.

Here're the updated sql files:
- [`schema_v0_8_mvp.sql`](./oprisk_db_enhanced/schema_v0_8_mvp.sql), which is an annotated set of `CREATE TABLE`, `CREATE INDEX`, `CREATE VIEW`, etc. statements that compose the database’s schema.
- [`test_data_v0_8_mvp.sql`](./oprisk_db_enhanced/test_data_v0_8_mvp.sql), which is an annotated set of `INSERT` statements that feeds test data to the database’s schema.
- [`queries_v0_8_mvp.sql`](./oprisk_db_enhanced/queries_v0_8_mvp.sql), which is an annotated set of `SELECT`, `UPDATE`, `DELETE`, etc. statements that users will commonly run on the Oprisk database.


These enhanced Oprisk database files are intended to serve as the foundation for the MVP of a full-fledged web application.
