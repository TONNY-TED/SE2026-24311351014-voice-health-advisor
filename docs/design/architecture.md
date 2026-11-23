Software Architecture
Overview
Voice Health Advisor is a Flutter-based mobile application designed to provide health guidance through voice interaction.

Components
Presentation Layer
Login Screen
Registration Screen
Knowledge Screen
Doctors Screen
History Screen
Settings Screen
Service Layer
SpeechService
TtsService
NlpService
HealthService
AuthService
KnowledgeBaseService
LocalDbService
Data Layer
SQLite Database
knowledge_base.json
health_sources.json
Speech Recognition Flow
User Speech → SpeechService → Text Conversion → NlpService

Advice Flow
NlpService → KnowledgeBaseService → HealthService → Advice Response

Emergency Processing
NlpService → Emergency Detection → Urgent Referral Advice

Offline Processing
FallbackAdviceService → Local Knowledge Base → Advice Display

Data Persistence
SQLite stores:

Users
Query History
Future Improvements
Chichewa Support
Content Synchronization
Versioned Health Content
Chain of Responsibility Pattern