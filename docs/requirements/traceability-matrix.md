Requirements Traceability Matrix
Requirement	Use Case	Code Evidence	Test Case
FR01 User Registration	UC01	register_screen.dart, auth_service.dart	TC01
FR02 User Login	UC01	login_screen.dart, auth_service.dart	TC02
FR03 Voice Input	UC01	speech_service.dart	TC03
FR04 Speech to Text	UC01	speech_service.dart	TC04
FR05 Text to Speech	UC01	tts_service.dart	TC05
FR06 Search Knowledge Base	UC01	knowledge_base_service.dart	TC06
FR07 Intent Classification	UC01	nlp_service.dart	TC07
FR08 Identify Health Topics	UC01	health_service.dart	TC08
FR09 Emergency Detection	UC02	nlp_service.dart	TC09
FR10 Urgent Referral Advice	UC02	nlp_service.dart	TC10
FR11 Save Query History	UC01	local_db_service.dart	TC11
FR12 View Query History	UC01	history_screen.dart	TC12
FR13 Application Settings	UC01	settings_screen.dart	TC13
FR14 Health Sources Display	UC01	sources_screen.dart	TC14
FR15 Fallback Advice	UC03	fallback_advice_service.dart	TC15
FR16 Offline Advice Retrieval	UC03	fallback_advice_service.dart, local_db_service.dart	TC16
FR17 Chichewa Speech Recognition	UC01	To Be Implemented	TC17
FR18 Content Versioning	UC03	To Be Implemented	TC18
FR19 Content Synchronization	UC03	To Be Implemented	TC19
FR20 Source Traceability	UC03	source_registry.dart	TC20