Housing Management & Rental System
📌 Overview

The Housing Management & Rental System is a database-driven project designed to streamline property management, tenant applications, lease tracking, and subsidy monitoring. It addresses challenges in Canada’s affordable housing sector by providing an organized and scalable SQL-based solution.

🎯 Objectives

Manage rental property listings (apartments, units, and houses).

Track tenant applications and approvals.

Automate lease agreements and payment records.

Monitor government housing subsidies for compliance and reporting.

Provide insights for landlords, tenants, and policymakers.

🛠️ Tech Stack

Database: SQL (MySQL / PostgreSQL)

Languages: SQL, Python (optional for scripts/ETL)

Tools: ERD diagrams, query optimization, data analysis

📂 Project Structure
sql_project/
│── schema/              # SQL scripts for creating tables
│── data/                # Sample datasets (CSV/SQL inserts)
│── queries/             # Example queries and reports
│── docs/                # ER diagrams, project documentation
│── scripts/             # (Optional) Python ETL / automation scripts
└── README.md            # Project documentation

📊 Features

Property Management: Add, update, and remove housing units.

Tenant Applications: Record and manage tenant information.

Lease Tracking: Automate start/end dates, renewals, and payments.

Subsidy Monitoring: Link tenants with government housing programs.

Reporting: Generate insights such as occupancy rates, overdue payments, and subsidy utilization.

🚀 Getting Started

Clone the repository:

git clone https://github.com/danger1020/sql_project.git


Navigate to the project folder:

cd sql_project


Import the schema into your SQL database:

SOURCE schema/housing_management.sql;


Load sample data:

SOURCE data/sample_data.sql;


Run example queries from the queries/ folder.

📖 Example Queries

List all available units by location.

Find tenants receiving subsidies.

Track overdue payments.

Calculate average occupancy rate by property type.
