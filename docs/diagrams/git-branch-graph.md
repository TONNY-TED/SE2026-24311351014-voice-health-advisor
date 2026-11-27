Git Branch Graph - VoiceHealth

Purpose
Map source control structure and release flow.

Branches
main: Stable release branch
develop: Integration branch
feature/voice-input: Voice input feature
feature/settings-fix: Settings localization fix
fix/material-localizations: Settings MaterialLocalizations fix
docs/: Documentation updates

Graph
main
  |
  +-- 43fd19b Developer button added
  |
  +-- c4f91e2 Settings MaterialLocalizations fix
  |
develop
  |
  +-- feature/voice-input
  |     +-- voice controller and panel
  |     +-- speech service integration
  |
  +-- fix/material-localizations
  |     +-- settings import fix

Release Flow
main <- develop
develop <- feature branches
feature branches <- feature branches

Hotfixes
main <- hotfix/*

Current Status
Feature branches merged after validation.
Main kept stable.
Push and pull requests used for collaboration.
