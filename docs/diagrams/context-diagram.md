Context Diagram
System
Voice Health Advisor Application

External Actors
Caregiver
Asks health questions
Receives spoken advice
Health Worker
Reviews health guidance
Provides feedback
Content Editor
Updates health content
Reviews sources
Clinician Reviewer
Approves medical advice
External Systems
Speech Recognition Engine
Converts speech to text
Text To Speech Engine
Converts text to spoken advice
Local Database
Stores users
Stores consultation history
Health Content Repository
Stores health advice and sources
Data Flows
Caregiver → Voice Question → Voice Health Advisor

Voice Health Advisor → Spoken Advice → Caregiver

Health Worker → Content Feedback → Voice Health Advisor

Content Editor → Updated Content → Voice Health Advisor

Voice Health Advisor ↔ Local Database

Voice Health Advisor ↔ Health Content Repository
