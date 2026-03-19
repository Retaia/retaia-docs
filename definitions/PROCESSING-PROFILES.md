# Processing Profiles — Retaia multi-apps

Ce document définit les profils de processing normatifs par type de média.
Il complète la machine à états et les job types.

## 1) Principe

Un `processing_profile` détermine les jobs requis pour atteindre `PROCESSED`.

Le modèle courant distingue implicitement deux niveaux :

* une **baseline technique** pilotée par le `media_type`
* une **qualification métier** seulement quand elle change réellement les jobs requis

En `v1`, cette distinction reste portée par un seul champ `processing_profile`. Le champ NE DOIT donc PAS être lu comme une taxonomie métier exhaustive de tous les contenus; il exprime seulement les variantes qui changent le processing requis.

Règles :

* un asset DOIT avoir exactement un `processing_profile`
* le profil est fixé à la découverte (auto) et peut être modifié manuellement avant le premier claim
* après le premier claim de job review, tout changement de profil exige un reprocess explicite
* `PROCESSED` est atteint uniquement quand tous les jobs `required` du profil sont `completed`
* à partir de la phase `v1.1+` validée, `transcribe_audio` devient requis pour tout média dont le `processing_profile` l'exige; avant cette phase validée, il PEUT être exercé plus tôt sous `feature_flags`
* `suggest_tags` n'est pas structurant pour les profils : c'est un enrichissement AI transversal, piloté par la phase active, les `feature_flags`, les capabilities agent et la qualité des inputs disponibles
* pour un asset `AUDIO`, le profil auto par défaut est `audio_undefined` tant qu'un humain n'a pas qualifié explicitement le média
* `audio_undefined` mène à `REVIEW_PENDING_PROFILE` dès que les dérivés minimaux sont prêts et force un choix explicite via `UI_WEB`

## 2) Baselines techniques par type média

### `PHOTO`

Baseline technique requise :

* `extract_facts`
* `generate_preview`

### `AUDIO`

Baseline technique requise :

* `extract_facts`
* `generate_preview`
* `generate_audio_waveform`

### `VIDEO`

Baseline technique requise :

* `extract_facts`
* `generate_preview`
* `generate_thumbnails`
* `generate_audio_waveform` (si piste audio exploitable)

## 3) Profils canoniques v1

Les profils ci-dessous sont les seuls profils normatifs exposés en `v1`.

Catégories :

* `video_standard`, `audio_music`, `audio_voice`, `photo_standard` = profils de processing effectifs
* `audio_undefined` = profil transitoire de qualification, jamais profil final de processing complet

### Tableau canonique — `processing_profile -> jobs`

| `processing_profile` | Jobs required v1 | `transcribe_audio` avant `v1.1+` validée | `transcribe_audio` dès `v1.1+` validée | `suggest_tags` |
|---|---|---|---|---|
| `video_standard` | `extract_facts`, `generate_preview`, `generate_thumbnails`, `generate_audio_waveform` si piste audio exploitable | optionnel sous `feature_flags` si piste audio exploitable | requis si piste audio exploitable | enrichissement transversal non bloquant |
| `audio_music` | `extract_facts`, `generate_preview`, `generate_audio_waveform` | interdit | interdit | enrichissement transversal non bloquant |
| `audio_voice` | `extract_facts`, `generate_preview`, `generate_audio_waveform` | optionnel sous `feature_flags` | requis | enrichissement transversal non bloquant |
| `audio_undefined` | `extract_facts`, `generate_preview`, `generate_audio_waveform` | interdit | interdit tant qu'un humain n'a pas choisi le profil final | interdit tant que le profil n'a pas été choisi |
| `photo_standard` | `extract_facts`, `generate_preview` | interdit | interdit | enrichissement transversal non bloquant |

Règles de lecture :

* `audio_undefined` reste un profil transitoire de qualification, pas un profil final
* `suggest_tags` n'entre pas dans la complétude de `PROCESSED`
* `transcribe_audio` ne dépend jamais du seul `media_type`; il dépend du `processing_profile` effectif et de la phase active

### `video_standard`

Usage : rush vidéo standard.

Règle d'évolution :

* `video_standard` est le profil vidéo canonique en `v1`
* il PEUT être scindé dans une phase ultérieure si des besoins métier distincts apparaissent (ex: interview/parole, musique/performance, ambiance/B-roll)
* une telle scission future ne remet pas en cause la baseline jobs vidéo déjà définie

Jobs required :

* baseline `VIDEO`

Jobs optional avant validation `v1.1+` :

* `transcribe_audio` (si activé, **v1.1+**, activable plus tôt sous `feature_flags` si piste audio exploitable)

Jobs required dès validation `v1.1+` :

* `transcribe_audio` (si piste audio exploitable)

### `audio_music`

Usage : musique / ambiances. La transcription n'est pas requise.

Jobs required :

* baseline `AUDIO`

Jobs optional avant validation `v1.1+` :

* aucun


### `audio_voice`

Usage : prises de son voix/interview.

Jobs required :

* baseline `AUDIO`

Jobs optional avant validation `v1.1+` du profil :

* `transcribe_audio`
  (dépendant de l'AI, **v1.1+**, activable plus tôt uniquement sous `feature_flags`)

Jobs required dès validation `v1.1+` du profil :

* `transcribe_audio`

### `audio_undefined`

Usage : audio découvert automatiquement mais non encore qualifié par un humain entre `audio_music` et `audio_voice`.

Nature :

* profil transitoire de qualification
* jamais profil final de processing complet

Jobs required :

* baseline `AUDIO`

Jobs forbidden tant que le profil n'a pas été choisi explicitement :

* `transcribe_audio`

Règles spécifiques :

* `audio_undefined` NE DOIT JAMAIS permettre un passage direct à `PROCESSED`
* un utilisateur humain DOIT choisir explicitement `audio_music` ou `audio_voice` via `UI_WEB`
* ce choix DOIT être audité
* si le profil choisi rend `transcribe_audio` requis dans la phase active, Core DOIT créer automatiquement ce job après mutation du profil et faire repasser l'asset en `READY`
* si le profil choisi ne nécessite aucun job supplémentaire, l'asset PEUT passer directement à `PROCESSED`

### `photo_standard`

Usage : photo fixe.

Jobs required :

* baseline `PHOTO`

Jobs optional avant validation `v1.1+` :

* aucun

Jobs forbidden :

* `generate_audio_waveform`
* `transcribe_audio`

## 4) Résolution auto du profil (normative)

Détection par défaut (override humain autorisé) :

* `VIDEO` -> `video_standard`
* `PHOTO` -> `photo_standard`
* `AUDIO` -> `audio_undefined`

Règles explicites :

* aucune détection implicite par IA/LLM
* aucune inférence implicite depuis tags non validés
* seules les métadonnées techniques et le choix humain explicite sont autorisés
* pour `AUDIO`, seul un choix humain explicite dans `UI_WEB` PEUT fixer `audio_music` ou `audio_voice`

## 4.1) Mutation de profil

Avant premier claim de job review :

* mutation autorisée `* -> *` par action humaine explicite
* pour `audio_undefined`, mutation humaine explicite obligatoire avant toute clôture du processing complet

Après premier claim :

* mutation interdite sans reprocess
* workflow obligatoire : `POST /assets/{uuid}/reprocess` puis mutation de profil puis reprise processing

## 5) Invariants

* les baselines techniques sont pilotées par le `media_type`
* les qualifications métier ne DOIVENT introduire une variante de profil que si elles changent réellement les jobs requis
* `extract_facts` et `generate_preview` sont requis pour tout profil v1
* `generate_thumbnails` n'est requis que pour les profils vidéo
* `generate_audio_waveform` est requis pour les profils audio et pour les profils vidéo avec piste audio exploitable
* `audio_undefined` ne DOIT JAMAIS être traité comme un profil final équivalent à `audio_music` ou `audio_voice`
* les profils ne prennent jamais de décision KEEP/REJECT
* les profils n'autorisent aucune écriture directe agent sur NAS dérivés

## 5.1) Enrichissements AI transversaux

Les enrichissements AI transversaux ne redéfinissent pas les profils.

`suggest_tags` :

* n'est pas un job structurant de `processing_profile`
* PEUT être rendu éligible selon la phase active, les `feature_flags`, les capabilities agent et la qualité des inputs disponibles
* reste non bloquant pour `PROCESSED`
* a généralement plus de valeur quand `facts` sont disponibles et, si présent, quand un transcript existe déjà

## 6) Évolution

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
