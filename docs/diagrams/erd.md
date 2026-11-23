Entity Relationship Diagram
Users
id (PK)
name
email
password
History
id (PK)
email (FK)
query
topic
intent
created_at
Relationship
User (1) -------- (Many) History