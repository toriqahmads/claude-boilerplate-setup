---
name: implementing-i18n
description: >
  Use when implementing anything with user-facing text or locale-sensitive data —
  internationalization and localization. Encodes best practice: externalize all
  strings, ICU-style messages with correct pluralization and gender/select, never
  concatenate translated fragments, locale-aware dates/numbers/currency, RTL support,
  a fallback locale, and translator context. Cross-cutting — backend and frontend
  executors follow it whenever a step touches user-visible copy or formatting.
  Triggers on "add i18n", "translate this", "make it localizable", "support multiple
  languages", "format the date/number/currency", "handle plurals", "RTL".
---

# Implementing i18n

Cross-cutting execution craft for internationalization. Followed by whichever executor
touches user-facing text (`frontend-executor`, `backend-executor` for emails/API
messages). Runs on top of the domain skill and the execution method.

## Goal

Make user-facing output **fully localizable and correct in every target locale** —
text, plurals, and formatting — so adding a language is a translation task, not a code
change. If a string is user-visible, it goes through the i18n layer.

## Stack

The plan/repo dictates the i18n library (i18next, react-intl/FormatJS, ICU, gettext,
Rails i18n, ICU MessageFormat, etc). Match the repo's existing setup and key
conventions; use context7 for the library's exact API. Do not roll your own if one
exists.

## Craft checklist

1. **Externalize every string.** No hardcoded user-facing text in code/templates. Each
   string is a keyed message in the resource bundle. (Logs and internal errors stay in
   the source language — don't over-translate.)
2. **No concatenation of translated parts.** Never build a sentence by joining
   fragments/variables — word order and grammar differ by language. Use a single
   parameterized message with placeholders.
3. **Pluralization & select.** Use ICU plural/select (zero/one/two/few/many/other) —
   never `count === 1 ? "item" : "items"`. Handle gender/context via `select` where
   the language needs it.
4. **Locale-aware formatting.** Dates, times, numbers, currency, percentages, and
   lists via the platform's Intl/formatter for the active locale — never manual
   formatting or hardcoded symbols/separators. Store timestamps in UTC; format at
   display.
5. **Key structure & context.** Namespaced, stable keys; provide a description/context
   and the source string for translators; note placeholders. Don't reuse one key for
   different meanings.
6. **Fallback locale.** A defined fallback chain; missing translations fall back
   visibly-safe (not to the raw key) and are reported, not crashed.
7. **RTL & bidi.** Support right-to-left where a target locale needs it — logical CSS
   properties, direction-aware layout, no hardcoded left/right.
8. **Loading.** Lazy-load locale bundles; don't ship every language to every user.
9. **Pseudolocalization / test.** Verify with a pseudo-locale or a real second locale
   that layouts handle longer text and non-Latin scripts; assert no hardcoded strings
   leak.

## Guardrails

- **If it's user-visible, it's translated** — through the i18n layer, never inline.
- **Never concatenate translations;** one parameterized message per sentence.
- **ICU plurals, not `=== 1`.** Formatting via Intl, not by hand.
- **Fallback to a message, not the key or a crash.**
- **Don't translate logs/internal identifiers.**
- **Reuse the repo's i18n setup and key conventions.**

## When to stop / complete

Complete when every user-facing string in the step is externalized, plurals/formatting
are locale-aware, keys have translator context, and a fallback exists — verified
against a pseudo/second locale. Stop and report the keys added and any strings you had
to leave inline (with why), or hand back if the i18n setup itself is missing and the
plan didn't scope creating it.

## Output

Keys/messages added (with context), formatting handled via Intl, plural/select usage,
RTL notes, fallback behavior, and any string left un-externalized with the reason.
