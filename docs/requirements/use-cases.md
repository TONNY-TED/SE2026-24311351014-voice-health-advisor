Use Cases
UC01 - Voice Health Query
Actor
Caregiver

Preconditions
User is logged in
Microphone permission granted
Main Flow
User presses microphone button.
User asks a health question.
System converts speech to text.
System analyzes the query.
System finds matching health advice.
System displays advice.
System speaks advice using text-to-speech.
Postconditions
Advice delivered to user
Query saved in history
UC02 - Emergency Symptom Detection
Actor
Caregiver

Preconditions
User submits a voice or text query.
Main Flow
User describes symptoms.
System detects emergency keywords.
System classifies query as emergency.
System retrieves urgent referral advice.
System displays warning message.
System reads warning aloud.
Postconditions
User receives urgent referral guidance.
UC03 - Offline Advice Retrieval
Actor
Caregiver

Preconditions
Internet unavailable.
Main Flow
User asks a question.
System searches offline knowledge base.
System retrieves advice locally.
System displays advice.
System speaks advice.
Postconditions
Advice provided without internet connection.