# Keyboard Shortcuts Registry

> Statut: registre UI global de reference.
> Source de verite normative complementaire: `UI-GLOBAL-SPEC.md`.

## Objectif

Fournir un registre unique des raccourcis et des regles de gouvernance pour eviter les collisions UX/a11y pendant les refactors.

## Regles de gouvernance

- Priorites: `P1 navigation/surete`, `P2 actions de flux`, `P3 presets/confort`.
- Un raccourci global ne doit jamais casser la saisie dans `input/textarea/select`.
- Les raccourcis destructifs ou bulk doivent rester explicites et testés.
- En cas de conflit, garder la semantique historique du flux review avant d'ajouter un nouveau binding.
- Toute modification de binding doit mettre a jour: ce registre, les tests shortcuts, l'aide UI.

## Contextes de blocage

- Blocage global en contexte de saisie (`input`, `textarea`, `select`, `contenteditable`).
- Exception explicite: `Escape` dans le champ de recherche peut vider la valeur locale.

## Registry (v1)

| Key / Combo | Commande | Priorite | Scope | Bloque en saisie |
| --- | --- | --- | --- | --- |
| `j`, `ArrowDown` | deplacer selection suivante | P1 | review list | oui |
| `k`, `ArrowUp` | deplacer selection precedente | P1 | review list | oui |
| `Shift+ArrowDown/Up` | etendre selection batch | P1 | review list | oui |
| `Enter` | ouvrir premier asset visible (si rien selectionne) | P1 | review list | oui |
| `Home`, `End` | aller premier/dernier asset visible | P2 | review list | oui |
| `Escape` | clear selection | P1 | review workspace | oui |
| `Escape` (search input) | clear recherche | P1 | search input | non |
| `/` | focus recherche | P2 | review workspace | oui |
| `Shift+Space` | toggle asset courant dans batch | P1 | review list | oui |
| `Ctrl/Cmd+A` | ajouter visibles au batch | P1 | review workspace | oui |
| `g` | appliquer KEEP selection | P2 | detail/review | oui |
| `v` | appliquer REJECT selection | P2 | detail/review | oui |
| `x` | appliquer CLEAR selection | P2 | detail/review | oui |
| `b` | toggle mode batch-only | P2 | review workspace | oui |
| `Shift+Enter` | confirmer execution batch pending | P1 | batch execution | oui |
| `r` | refresh report batch | P2 | reports/workspace | oui |
| `l` | vider action log | P3 | workspace | oui |
| `Ctrl/Cmd+Z` | undo derniere action | P1 | workspace | oui |
| `p` | focus pending | P2 | workspace | oui |
| `n` | ouvrir prochain pending | P2 | workspace | oui |
| `d` | toggle densite liste | P3 | workspace | oui |
| `1`, `2`, `3` | appliquer presets filtres | P3 | workspace | oui |
| `?` | toggle panneau aide raccourcis | P3 | workspace | non |

## Process de changement

1. Ajouter/mettre a jour l'entree dans ce registre.
2. Mettre a jour `src/application/review/keyboardShortcutResolution.ts`.
3. Mettre a jour les tests (`src/app.shortcuts.test.tsx`, `src/pages/ReviewPage.test.tsx`, tests BDD si impact cross-page).
4. Mettre a jour l'aide visuelle et les libelles i18n.
5. Documenter le risque de collision dans la PR.

## References

- `src/application/review/keyboardShortcutResolution.ts`
- `src/hooks/useReviewKeyboardShortcuts.ts`
- `src/components/app/ActionShortcutsSection.tsx`
- `UI-GLOBAL-SPEC.md`
