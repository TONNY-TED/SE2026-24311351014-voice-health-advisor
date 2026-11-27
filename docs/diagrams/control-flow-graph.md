Control Flow Graph - VoiceHealth

Purpose
Map control flow for the voice query lifecycle.

Start
User taps microphone

Check Mic Permission
Denied?
Yes -> Show Error State
No -> Continue

Initialize SpeechService

Listen For Speech
Silence Timer Running?
Yes -> Finalize
No -> Continue Listening

Finalise Transcript
Stop Mic
Run NlpService
Run KnowledgeBaseService
Generate Advice
Speak Advice
Return Result

Done
Error?
Yes -> Show Error State
No -> Done

Nodes
Start
Decision: Mic Permission
Action: Initialize SpeechService
Action: Listen For Speech
Decision: Silence Timer
Action: Finalize Transcript
Action: Stop Mic
Action: Run NlpService
Action: Run KnowledgeBaseService
Action: Generate Advice
Action: Speak Advice
Decision: Error
End

Transitions
Start -> Decision: Mic Permission
Decision(denied) -> Start: No -> Continue
Decision(denied) -> End: Yes -> Show Error State
Decision(not denied) -> Action: Initialize SpeechService
Action -> Decision: Silence Timer
Decision(running) -> Action: Finalize Transcript
Decision(not running) -> Action: Continue Listening
Action -> Action: Stop Mic
Action -> Action: Run NlpService
Action -> Action: Run KnowledgeBaseService
Action -> Action: Generate Advice
Action -> Action: Speak Advice
Decision(error) -> Action: Show Error State
