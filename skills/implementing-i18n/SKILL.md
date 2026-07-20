---
name: implementing-i18n
description: >
  Use when implementing anything with user-facing text or locale-sensitive data —
  internationalization (i18n) and localization (l10n). Encodes best practice: externalize all
  strings, ICU-style messages with correct pluralization and gender/select, never concatenate
  translated fragments, locale-aware dates/numbers/currency, RTL support, a fallback locale, and
  translator context. Cross-cutting — backend and frontend executors follow it whenever a step
  touches user-visible copy or formatting. Triggers on "add i18n", "translate this", "localize
  the app", "internationalize", "make it localizable", "support multiple languages", "add a
  language/locale", "format the date/number/currency", "handle plurals", "pluralization", "RTL",
  "right-to-left support", "l10n".
---

# Implementing i18n

Cross-cutting execution craft, followed by whichever executor touches user-facing text
(`frontend-executor`, `backend-executor` for emails/API messages).

## Goal

Make user-facing output fully localizable and correct in every locale — so adding a language is
a translation task, not a code change.

## Stack

Plan/repo dictates the library (i18next, react-intl/FormatJS, ICU, gettext, Rails i18n) — match
its setup/key conventions, use context7 for exact API, don't roll your own if one exists.

## Craft checklist

1. **Externalize every string.** No hardcoded user-facing text — each is a keyed message. (Logs
   stay in the source language.)
2. **No concatenation of translated parts.** Word order/grammar differ by language — one
   parameterized message with placeholders, never joined fragments.
3. **Pluralization & select.** ICU plural/select (zero/one/two/few/many/other), never
   `count === 1 ? "item" : "items"`; `select` for gender/context.
4. **Locale-aware formatting.** Dates, numbers, currency, lists via the platform's Intl for the
   active locale — never manual formatting. Store timestamps in UTC; format at display.
5. **Key structure & context.** Namespaced, stable keys with translator context; never reuse a
   key for different meanings.
6. **Fallback locale.** A defined chain; missing translations fall back visibly-safe (never the
   raw key), reported not crashed.
7. **RTL & bidi.** Logical CSS properties, direction-aware layout, no hardcoded left/right.
8. **Loading.** Lazy-load locale bundles.
9. **Pseudolocalization / test.** Verify with a pseudo-locale or real second locale for layout
   and non-Latin scripts; no hardcoded strings leak.

## Guardrails

- User-visible → through the i18n layer, never inline; never concatenate translations.
- ICU plurals, not `=== 1`; formatting via Intl, not by hand.
- Fallback to a message, not the key or a crash; don't translate logs/internal identifiers.

## When to stop / complete

Complete when every user-facing string is externalized, plurals/formatting are locale-aware,
keys have translator context, and a fallback exists — verified against a pseudo/second locale.
Report keys added, any strings left inline (with why), or hand back if i18n setup is missing.

## Output

Keys/messages added (with context), Intl formatting, plural/select usage, RTL notes, fallback
behavior, any un-externalized string with reason.
</content>
