# Processing Profiles — Retaia Core + Retaia Agent

Ce document définit les profils de processing normatifs par type de média.
Il complète la machine à états et les job types.

## 1) Principe

Un `processing_profile` détermine les jobs requis pour atteindre `PROCESSED`.

Règles :

* un asset DOIT avoir exactement un `processing_profile`
* le profil est fixé à la découverte (auto) et peut être modifié manuellement avant le premier claim
* après le premier claim de job review, tout changement de profil exige un reprocess explicite
* `PROCESSED` est atteint uniquement quand tous les jobs `required` du profil sont `completed`

## 2) Profils canoniques v1

### `video_standard`

Usage : rush vidéo standard.

Jobs required :

* `extract_facts`
* `generate_proxy`
* `generate_thumbnails`

Jobs optional :

* `generate_audio_waveform` (si piste audio exploitable)
* `transcribe_audio` (si activé, **v1+**)
* `suggest_tags` (si activé, **v1.1+**)

### `audio_music`

Usage : musique / ambiances sans besoin de transcript.

Jobs required :

* `extract_facts`
* `generate_proxy`
* `generate_thumbnails`
* `generate_audio_waveform`

Jobs optional :

* `suggest_tags`
  (AI-powered, **v1.1+**)

Jobs forbidden :

* `transcribe_audio`

### `audio_voice`

Usage : prises de son voix/interview.

Jobs required :

* `extract_facts`
* `generate_proxy`
* `generate_thumbnails`
* `generate_audio_waveform`
* `transcribe_audio`

Jobs optional :

* `suggest_tags`
  (AI-powered, **v1.1+**)

### `photo_standard`

Usage : photo fixe.

Jobs required :

* `extract_facts`
* `generate_proxy`
* `generate_thumbnails`

Jobs optional :

* `suggest_tags`
  (AI-powered, **v1.1+**)

Jobs forbidden :

* `generate_audio_waveform`
* `transcribe_audio`

## 3) Résolution auto du profil (normative)

Détection par défaut (override humain autorisé) :

* `VIDEO` -> `video_standard`
* `PHOTO` -> `photo_standard`
* `AUDIO` -> `audio_music`

Pour `AUDIO`, l'utilisateur peut forcer `audio_voice` avant claim si transcript requis.

Règles explicites :

* aucune détection implicite par IA/LLM
* aucune inférence implicite depuis tags non validés
* seules les métadonnées techniques et le choix humain explicite sont autorisés

## 3.1) Mutation de profil

Avant premier claim de job review :

* mutation autorisée `* -> *` par action humaine explicite

Après premier claim :

* mutation interdite sans reprocess
* workflow obligatoire : `POST /assets/{uuid}/reprocess` puis mutation de profil puis reprise processing

## 4) Invariants

* `extract_facts`, `generate_proxy`, `generate_thumbnails` sont requis pour tout profil v1
* les profils ne prennent jamais de décision KEEP/REJECT
* les profils n'autorisent aucune écriture directe agent sur NAS dérivés

## 5) Évolution

* ajout d'un profil: changement compatible
* suppression ou changement des jobs `required` d'un profil existant: changement structurel
* toute évolution de profil DOIT être reflétée dans:
  * `STATE-MACHINE.md`
  * `JOB-TYPES.md`
  * `API-CONTRACTS.md`
  * `api/openapi/v1.yaml`

## Références associées

* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [JOB-TYPES.md](JOB-TYPES.md)
* [WORKFLOWS.md](../workflows/WORKFLOWS.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
