# Notes pour agents IA

## Contexte

- Repo utilisé pour mon homelab (Proxmox + LXC Debian).
- `bin/` contient les scripts utilisables en prod sur les LXC.
- `lab/` est une zone d'expérimentation (OK pour casser des choses).
- `projects/mp3-transcriber/` contient le pipeline MP3 -> texte -> DOCX.

## Comment m'aider

- Proposer des améliorations incrémentales, petits commits.
- Garder la compatibilité Debian stable (apt avant conteneurs/podman).
- Toujours documenter les nouvelles commandes dans les README.
- Ne jamais commit de secrets (utiliser .env.example).

## Priorités actuelles

- [ ] Mettre en place un script de transcription MP3 simple (bash + python).
- [ ] Choisir une stack de transcription (whisper.cpp, API OpenAI, etc.).
- [ ] Ajouter un Makefile dans `projects/mp3-transcriber`.

