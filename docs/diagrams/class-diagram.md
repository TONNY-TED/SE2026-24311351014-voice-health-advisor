Class Diagram
HealthService

findForQuery()
NlpService

parse()
normalize()
SpeechService

listen()
TtsService

speak()
KnowledgeBaseService

loadEntries()
LocalDbService

insertUser()
getUser()
addHistory()
recentHistory()
AuthService

login()
register()
Relationships

SpeechService → NlpService

NlpService → KnowledgeBaseService

HealthService → KnowledgeBaseService

AuthService → LocalDbService

LocalDbService → History