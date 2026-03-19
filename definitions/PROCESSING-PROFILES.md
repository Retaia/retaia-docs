# Processing Profiles — Retaia multi-apps

Ce document définit les profils de processing normatifs par type de média.
Il complète la machine à états et les job types.

## 1) Principe

Un `processing_profile` détermine les jobs requis pour atteindre `PROCESSED`.

Règles :

* un asset DOIT avoir exactement un `processing_profile`
* le profil est fixé à la découverte (auto) et peut être modifié manuellement avant le premier claim
* après le premier claim de job review, tout changement de profil exige un reprocess explicite
* `PROCESSED` est atteint uniquement quand tous les jobs `required` du profil sont `completed`
* à partir de la phase `v1.1+` validée, `transcribe_audio` devient requis pour tout média avec piste audio exploitable; avant cette phase validée, il PEUT être exercé plus tôt sous `feature_flags`
* pour un asset `AUDIO`, le profil auto par défaut est `audio_undefined` tant qu'un humain n'a pas qualifié explicitement le média
* `audio_undefined` bloque le passage à `PROCESSED` et force un choix explicite via `UI_WEB` pendant la review

## 2) Profils canoniques v1

### `video_standard`

Usage : rush vidéo standard.

Jobs required :

* `extract_facts`
* `generate_proxy`
* `generate_thumbnails`
* `generate_audio_waveform` (si piste audio exploitable)

Jobs optional avant validation `v1.1+` :

* `transcribe_audio` (si activé, **v1.1+**, activable plus tôt sous `feature_flags` si piste audio exploitable)
* `suggest_tags` (si activé, **v1.1+**)

Jobs required dès validation `v1.1+` :

* `transcribe_audio` (si piste audio exploitable)

### `audio_music`

Usage : musique / ambiances. La transcription n'est pas requise.

Jobs required :

* `extract_facts`
* `generate_proxy`
* `generate_thumbnails`
* `generate_audio_waveform`

Jobs optional avant validation `v1.1+` :

* `suggest_tags`
  (dépendant de l'AI, **v1.1+**)


### `audio_voice`

Usage : prises de son voix/interview.

Jobs required :

* `extract_facts`
* `generate_proxy`
* `generate_thumbnails`
* `generate_audio_waveform`

Jobs optional avant validation `v1.1+` du profil :

* `transcribe_audio`
  (dépendant de l'AI, **v1.1+**, activable plus tôt uniquement sous `feature_flags`)
* `suggest_tags`
  (dépendant de l'AI, **v1.1+**)

Jobs required dès validation `v1.1+` du profil :

* `transcribe_audio`

### `audio_undefined`

Usage : audio découvert automatiquement mais non encore qualifié par un humain entre `audio_music` et `audio_voice`.

Jobs required :

* `extract_facts`
* `generate_proxy`
* `generate_thumbnails`
* `generate_audio_waveform`

Jobs forbidden tant que le profil n'a pas été choisi explicitement :

* `transcribe_audio`
* `suggest_tags`

Règles spécifiques :

* `audio_undefined` NE DOIT JAMAIS permettre le passage à `PROCESSED`
* un utilisateur humain DOIT choisir explicitement `audio_music` ou `audio_voice` via `UI_WEB`
* ce choix DOIT être audité
* si le profil choisi rend `transcribe_audio` requis dans la phase active, Core DOIT créer automatiquement ce job après mutation du profil

### `photo_standard`

Usage : photo fixe.

Jobs required :

* `extract_facts`
* `generate_proxy`
* `generate_thumbnails`

Jobs optional avant validation `v1.1+` :

* `suggest_tags`
  (dépendant de l'AI, **v1.1+**)

Jobs forbidden :

* `generate_audio_waveform`
* `transcribe_audio`

## 3) Résolution auto du profil (normative)

Détection par défaut (override humain autorisé) :

* `VIDEO` -> `video_standard`
* `PHOTO` -> `photo_standard`
* `AUDIO` -> `audio_undefined`

Règles explicites :

* aucune détection implicite par IA/LLM
* aucune inférence implicite depuis tags non validés
* seules les métadonnées techniques et le choix humain explicite sont autorisés
* pour `AUDIO`, seul un choix humain explicite dans `UI_WEB` PEUT fixer `audio_music` ou `audio_voice`

## 3.1) Mutation de profil

Avant premier claim de job review :

* mutation autorisée `* -> *` par action humaine explicite
* pour `audio_undefined`, mutation humaine explicite obligatoire avant toute clôture de processing review

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
