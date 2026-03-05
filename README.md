# 🏢 Non-Profit Organization (NGO) Management System

## 🌟 Project Overview
This project is a real-world database solution designed to streamline the operations of a Non-Profit Organization.  
It manages the full lifecycle of social work—from internal employee administration and departmental oversight to beneficiary field research, financial aid distribution, and home visitation tracking.

The system replaces manual record-keeping with a robust relational database, ensuring **data accuracy** for sensitive information such as loan approvals and social support services.

---

## 🏗️ System Architecture & Features

### 1. Core Administration
- **Employee & Department Management**: Staff records, hierarchical reporting (self-referencing supervisors), and departmental assignments.  
- **Committee Oversight**: Specialized committees (Loan Committee, Education Committee) that review and approve support requests.

### 2. Beneficiary & Family Tracking
- **Comprehensive Profiles**: Detailed data on beneficiaries, occupations, household demographics, and contact info.  
- **Kinship Mapping**: Tracks relatives and family members to provide a holistic view during the research phase.

### 3. Social Support & Financial Aid
- **Loan Management**: Micro-loan applications, status tracking, required documentation (utility bills, ID copies), and project links.  
- **Support Services**: Categorizes and logs aid types (Cash, Medical, Food, Educational).  
- **Micro-Projects**: Links beneficiaries to small-scale business projects fostering financial independence.

### 4. Fieldwork & Awareness
- **Home Visit Documentation**: Logs visits, observations, and progress notes by social workers.  
- **Awareness Campaigns**: Connects home visits with educational topics (Health, Literacy, Family Planning) to measure outreach impact.

---

## 🛠️ Technical Stack
- **Engine**: Microsoft SQL Server (MS SQL)  
- **Language**: T-SQL (Transact-SQL)  
- **Key Techniques**: Advanced constraints (PK, FK, Unique, Not Null) for data integrity  
- **Automation**: T-SQL loops and batch scripts for realistic test data  
- **Relational Mapping**: Complex Many-to-Many relationships via junction tables  

---

## 📈 Database Schema (ERD)
The system is built on a **highly normalized relational model** to prevent redundancy.

- **Primary Entities**: Employees, Beneficiaries, Loans, Projects, Support Services  
- **Junction Entities**:  
  - Employees_Make_HomeVisits  
  - Beneficiaries_Benefit_SupportServices  
  - HomeVisits_Cover_Awareness  

*(See ERD diagram in project files for full schema.)*

---

## 🚀 Deployment & Usage
1. **Database Creation**: Run `create database Non_Profit_Org` script.  
2. **Schema Setup**: Execute table creation scripts (11+ core tables).  
3. **Data Population**: Use provided `INSERT` statements and `WHILE` loops to generate test data.  
4. **Verification**: Run audit queries to view interconnected data across modules.  

---

## 💡 Real-World Impact
- **Transparency**: Every dollar of support is traced back to a specific beneficiary and committee approval.  
- **Efficiency**: Social workers can quickly access a beneficiary’s history before making new recommendations.  
- **Scalability**: New support types or committees can be added without breaking workflows.  

---

## 📂 Project Files
- `Non_Profit_Org.sql` → Database creation & schema setup  
- `Data_Population.sql` → Scripts for inserting realistic test data  
- `Audit_Queries.sql` → Verification queries  
- `Non_Profit OrgERD.pdf` → Entity Relationship Diagram  

---

## 👩‍💻 Authors
Developed by:   
- **Mohamed Mansour**  
- **George Samir**
- **Aliaa Ahmed** 
---
