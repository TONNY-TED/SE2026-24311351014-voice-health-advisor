Sequence Diagram - Voice Question To Spoken Advice
Caregiver

↓

SpeechService

↓

NlpService

↓

KnowledgeBaseService

↓

HealthService

↓

TtsService

Flow:

Caregiver speaks question
SpeechService converts speech to text
NlpService analyzes query
KnowledgeBaseService retrieves advice
HealthService prepares response
TtsService speaks advice
Advice returned to Caregiver