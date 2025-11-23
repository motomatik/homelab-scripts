# MP3 Transcriber

Pipeline d'automatisation pour convertir des fichiers MP3 en texte puis en DOCX.

## Objectif

- Prendre un MP3 en entrée
- Transcrire en texte (whisper, API, autre…)
- Post-traiter en paragraphe
- Exporter en DOCX

## Structure

- `src/` : scripts principaux (bash/python)
- `etc/` : configuration (.conf, .env.example)
- `data/input` : fichiers audio d'entrée (non versionnés)
- `data/output` : résultats texte/docx (non versionnés)
- `scripts/` : scripts d'admin / maintenance

## Usage (exemple)

```bash
make transcribe INPUT=monfichier.mp3

