Feature: Voice Health Advisor Acceptance Tests

Scenario: User asks a health question using voice
  Given the user is logged in
  When the user speaks a health question
  Then the system shall convert speech to text
  And the system shall analyze the query

Scenario: User receives spoken advice
  Given a valid health question
  When advice is generated
  Then the system shall display the advice
  And the system shall read the advice aloud

Scenario: Emergency symptom detection for difficulty breathing
  Given a caregiver submits a question
  When the query contains "difficulty breathing"
  Then the system shall classify the query as an emergency
  And the system shall provide urgent referral advice

Scenario: Emergency symptom detection for seizure
  Given a caregiver submits a question
  When the query contains "seizure"
  Then the system shall classify the query as an emergency
  And the system shall provide urgent referral advice

Scenario: Emergency symptom detection for unconscious patient
  Given a caregiver submits a question
  When the query contains "unconscious"
  Then the system shall provide urgent referral advice

Scenario: Retrieval of health knowledge
  Given a user asks about malaria
  When the knowledge base contains malaria information
  Then the system shall return the appropriate advice

Scenario: Save query history
  Given a user receives health advice
  When the consultation is completed
  Then the query shall be stored in the history database

Scenario: Display query history
  Given a user has previous consultations
  When the history screen is opened
  Then the stored queries shall be displayed

Scenario: Offline advice retrieval
  Given the internet connection is unavailable
  When the user asks a supported health question
  Then the system shall retrieve advice from local storage

Scenario: Chichewa speech recognition
  Given the user selects Chichewa language
  When the user asks a health question in Chichewa
  Then the system shall correctly determine the user's intent