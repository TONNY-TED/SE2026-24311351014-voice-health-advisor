DFD Level 0
Processes
P1. User Authentication

P2. Voice Query Processing

P3. Knowledge Base Search

P4. Advice Generation

P5. History Management

External Entity
Caregiver

Data Stores
D1 Users Database

D2 Query History

D3 Knowledge Base

Data Flows
Caregiver → P1 Authentication

P1 ↔ D1 Users Database

Caregiver → P2 Voice Query Processing

P2 → P3 Knowledge Base Search

P3 ↔ D3 Knowledge Base

P3 → P4 Advice Generation

P4 → Caregiver

P4 → D2 Query History

P5 ↔ D2 Query History