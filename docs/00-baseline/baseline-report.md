Voice Health Advisor Baseline Report

Project Information

Student ID: 24311351014



Project Name: Voice Health Advisor



Baseline Tag: v0.7-asbuilt



Date: 21 November 2026



1\. Existing Features

Feature	Status	Notes

Voice Input	Investigating

Speech Recognition	Investigating

Text-to-Speech	Investigating

Health Advice Retrieval	Investigating

Emergency Detection	Investigating

Chichewa Support	Investigating

Offline Support	Investigating

Content Management	Investigating

2\. Partially Implemented Features

Feature	Current State	Gap

3\. Missing Features

Feature	Required By Assignment

4\. Existing Defects

ID	Description	Severity

D1	Not yet identified	TBD

D2	Not yet identified	TBD

5\. Signature Challenge Gap Analysis

5.1 Triage Safety

Current State

To be investigated.



Gap

To be determined.



5.2 Speech Robustness

Current State

To be investigated.



Gap

To be determined.



5.3 Offline Fallback

Current State

To be investigated.



Gap

To be determined.



5.4 Content Governance

Current State

To be investigated.



Gap

To be determined.



6\. Initial Codebase Assessment

Flutter Version

To be recorded.



Project Structure

To be recorded.



Database Technology

To be recorded.



State Management

To be recorded.



External APIs

To be recorded.



7\. Baseline Conclusions

The Voice Health Advisor project has been recovered and tagged as v0.7-asbuilt. Further inspection is required to determine implemented features, defects, architecture, test coverage and compliance with the Signature Challenge requirements.

Emergency Detection
Status: Implemented

Evidence:

NlpService contains emergency detection logic using keyword-based pattern matching.

Detected emergencies include:

Difficulty breathing
Chest pain
Unconsciousness
Severe bleeding
Seizure
Stroke indicators
Self-harm indicators
Gap:

Currently rule-based matching only. No Chain of Responsibility implementation yet. Testing evidence not yet available.

Baseline Findings
The application is substantially implemented and contains:

Speech recognition
Text-to-speech
Local SQLite storage
Authentication
Health knowledge base
NLP-based intent classification
Emergency symptom detection
Source registry management
Emergency detection currently relies on rule-based keyword matching.

Further work is required to:

Support Chichewa speech and intent recognition
Implement content versioning
Implement content synchronization
Introduce required software design patterns
Complete testing requirements



Baseline Summary

The Voice Health Advisor application is substantially implemented.



Verified functionality includes:



User registration and login

Speech recognition

Text-to-speech

NLP intent classification

Emergency symptom detection

Health knowledge base

Local SQLite database

Query history

Knowledge source registry

Offline fallback advice

The main gaps identified are:



Chichewa language support

Content version management

Offline synchronization mechanism

Required design patterns

Formal testing evidence

Performance and reliability testing

