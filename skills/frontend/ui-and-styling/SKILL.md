---
name: ui-and-styling
description: >
  Design system rules for vera-fe: Tailwind v4 semantic tokens, shared/ui components, Radix,
  theming and dark mode, and the whole i18n setup (namespaces, translation keys, parity, typed keys, locale
  resolution, money/date formatting, API error codes). Use whenever building UI, styling, adding a string
  the user reads, adding a translation key or formatting money/dates. Triggers on: "componente", "component",
  "estilo", "style", "tailwind", "cor", "token", "tema", "dark mode", "tabela", "moeda", "formatar",
  "i18n", "tradução", "translation", "locale", "idioma", "useTranslation", "no-literal-string", "no-fixed-color".
---

# UI & styling — vera-fe

Tailwind v4 (`@tailwindcss/vite`, `@import 'tailwindcss'` in `src/index.css`), Radix primitives, `lucide-react`
icons, `class-variance-authority` for variants, `cn()` (`clsx` + `tailwind-merge`) from `@/shared/lib/cn`.

## Tokens, not colours

Colours are semantic tokens declared in `@theme` in `src/index.css`: `canvas`, `surface`, `surface-muted`,
`border`, `border-strong`, `content`, `content-muted`, `content-subtle`, `accent`, `accent-contrast`,
`positive`, `caution`, `critical`, `info`, `highlight`, `topbar*`, plus `brand` and the `*-soft` mixes. They become utilities: `bg-surface`, `text-content-muted`, `border-border`,
`bg-critical/10`. Also `rounded-control`, `rounded-card`, `shadow-card`, `text-2xs`, `px-page-x`.

- **No literal colour.** `local/no-fixed-color` (`eslint-rules/no-fixed-color.mjs`) fails on `bg-[#DA2640]`,
  `[rgb(`, `[hsl(`, `[oklch(` inside `className`/`cn()`/`cva()` and on a hex/rgb/hsl/oklch value in a `style` colour
  property. Use `var(--color-...)` in `style`. A genuinely new colour enters `index.css` as a token with a purpose.
- **Theming is tokens.** The theme (light by default, pink base) is a set of overrides of the same tokens;
  components never branch on theme for colour — they use the token and the theme re-skins it.
- **Dark mode** is the `.dark` class flipping the same tokens (`@custom-variant dark`). Never a second component.

## Composition rules

1. `shared/ui` holds generic primitives; it cannot import `app` or `features`. Import **per file**
   (`@/shared/ui/button`), not from `shared/ui/index.ts` — the barrel exists but nothing uses it, and the project
   rule is no barrels.
2. Variants come from `cva`, annotated by hand (see `button.tsx`: `const buttonVariants: (props?: ButtonVariantProps) => string = cva(...)`).
3. Existing components (check before creating): `Alert`, `Avatar`, `Badge`, `Button`, `Card`, `ConfirmDialog`,
   `CopyField`, `DateField`, `EmptyState`, `FailureAlert`, `Field`, `FileDrop`, `IconTile`, `Kpi`, `Modal`, `Money`,
   `OtpInput`, `Pager`, `PeriodRangePicker`, `PillNav`, `SearchInput`, `SelectMenu`, `Skeleton*`,
   `StatusDot`, `Stepper`, `Table`, `TabNav`, `Toast`, `Tooltip`.
   Show a new one in `routes/_dev/ui.tsx`.
4. Every list/data screen has four states: loading (skeleton shaped like the content), empty (`EmptyState`, with the
   action that fills it), error (`Alert`/`FailureAlert`, retry) and content.
5. Accessibility: `eslint-plugin-jsx-a11y` is on. Icon-only buttons get a translated `aria-label`, decorative
   icons `aria-hidden="true"`, alerts `role="alert"`.
6. Feedback: destructive actions use `ConfirmDialog` and name the consequence. Toasts via `useToast()`
   (`tone`: `positive` | `caution` | `critical` | `neutral`; critical toasts do not auto-dismiss), past tense.
7. Functions stay under 40 lines: split JSX into small named components in the same file or a sibling file.

## i18n — every user-visible string is a key

Vera ships in **pt-BR and en** (rule and rationale in the org `conventions` skill). Stack: `i18next` +
`react-i18next`, static resources, no HTTP backend.

**Where things live** (`src/shared/lib/i18n/`):

| Path                             | What                                                                   |
| -------------------------------- | ---------------------------------------------------------------------- |
| `index.ts`                       | `init`, the `resources` map, `ns` list, `i18n` instance, `useLocale()` |
| `resolve-locale.ts`              | `SupportedLocale`, `DEFAULT_LOCALE = 'pt-BR'`, `resolveLocale()`       |
| `resources/{pt-BR,en}/<ns>.json` | the dictionaries, one file per namespace per locale                    |
| `resources/parity.spec.ts`       | fails if the locales have different key sets                           |
| `typecheck.spec-d.ts`            | type test: unknown key rejected (run with `npm run test:types`)        |
| `src/i18next.d.ts`               | `CustomTypeOptions` — pt-BR JSON is the source of truth for key types  |

Namespaces: `common` (default; generic UI words), `auth`, `onboarding`, and one per feature as it
appears (e.g. `portfolio`, `spending`). One namespace per feature, camelCase name.

**Adding a string:**

1. Add the key to `pt-BR/<ns>.json` and `en/<ns>.json` in the same position.
2. Use it: `const { t }: UseTranslationResponse<'auth', undefined> = useTranslation('auth');` then `t('emailLabel')`.
   Keys are type-checked; a typo breaks `npm run typecheck`. `common` keys need no namespace argument.
3. **New namespace:** create the JSON files (one per locale), then register it in four places — the imports, `resources` type
   and map and `ns` array in `index.ts`, the `resources` in `src/i18next.d.ts`, and the `NAMESPACES` list in
   `parity.spec.ts`.
4. Interpolation `{{account}}` and plurals (`title_one` / `title_other` with `count`) are used; never concatenate
   translated fragments or build sentences from pieces.

**Key naming:** follow the style of the namespace you edit. `common` and `auth` are flat camelCase
(`emailLabel`, `errorInvalidCode`); feature namespaces group by screen/area with nesting
(`import.error_generic`, `errors.invalidFile`, `profile.errors.name_required`). Do not mix styles inside one file.

**Lint:** `i18next/no-literal-string` in `jsx-only` mode flags literal text and literal user-facing props
(`placeholder`, `aria-label`, `title`, `alt`...). Excluded attributes are technical ones (`className`, `style`,
`type`, `key`, `id`, `data-*`, `to`, `href`, `role`, `name`, `htmlFor`, `variant`, `size`, ...). Specs and `test/**`
are exempt. Strings outside JSX (toast titles, helpers) are not caught by the rule: still use `t`, passing `t` into
the helper as `TFunction<'ns'>` (`authFailureToast(t, ...)`, `importErrorMessage(t, error)`).

**Locale resolution:** `resolveLocale({ userLocale, companyLocale, navigatorLanguage })` picks user, then company,
then browser, normalizing any variant to `pt-BR`/`en` (`en-GB` -> `en`, `pt-PT` -> `pt-BR`) with fallback
`pt-BR`. At the moment only the browser link is fed (`index.ts`); user/company will be wired when that data exists.
Components read the active locale with `useLocale()`. `I18nProvider` keeps `<html lang>` in sync. Specs run in pt-BR
(`test/setup.ts` calls `i18n.changeLanguage('pt-BR')`).

**API error codes -> messages:** the API returns `problem.type` as the code and never UI text; the mapping lives in
the feature's `lib/*-error-message.ts` (full pattern in `data-fetching`). Add the key to every dictionary.

## Money, dates and numbers

All formatting goes through `Intl` with the **resolved locale** and the **data's own currency / company time zone** —
never a hard-coded `'pt-BR'`/`'BRL'`:

- Money: `<Money amountMinor={...} currency={...} />` or `formatMoney(amountMinor, currency, locale)`
  (`shared/lib/format/currency.ts`). Amounts are integers in the currency's minor unit; the exponent comes from
  `Intl` (CLP has none, BRL has two). Never `toFixed` or manual `R$` concatenation.
- Dates: `formatDate(date, locale, timeZone)` (`shared/lib/format/date.ts`); transaction times use the
  **company's** time zone, not the browser's. Also `format/number.ts`, `period-range.ts`.
- Domain vocabulary in code is English per the mapping table in the `conventions` skill (`netWorth`,
  `expense`, `budget`); the pt-BR words live only in the dictionaries.
