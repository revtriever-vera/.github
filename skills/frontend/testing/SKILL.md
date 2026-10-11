---
name: testing
description: >
  Test strategy for vera-fe: Vitest + React Testing Library + MSW, the test/ helpers, fixtures, coverage
  gate and what to test at each level. Use whenever writing or changing tests, adding an MSW handler or a
  fixture, or when coverage fails. Triggers on: "test", "teste", "spec", "vitest", "testing library", "RTL",
  "msw", "mock", "fixture", "renderWithProviders", "renderRouterAt", "cobertura", "coverage", "spec-d".
---

# Testing — vera-fe

**Vitest 4 + Testing Library + MSW 2**, jsdom environment.

## Commands and gates

| Command              | What                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------- |
| `npm test`           | `vitest run --config vitest.config.ts` (pre-push runs `typecheck` then this)          |
| `npm run test:cov`   | same with v8 coverage — what CI runs                                                  |
| `npm run test:types` | `--typecheck`: type tests (`*.spec-d.ts`), e.g. `shared/lib/i18n/typecheck.spec-d.ts` |

`vitest.config.ts`: `include: ['src/**/*.spec.{ts,tsx}', 'eslint-rules/**/*.spec.mjs']`, `globals: false` (import
`describe/it/expect/vi` from `vitest`), `setupFiles: ['./test/setup.ts']`, `testTimeout: 15_000`, `maxWorkers: 4`.
**Coverage thresholds: 85% lines, branches, functions and statements**, over `src/**/*.{ts,tsx}` excluding specs,
`routeTree.gen.ts`, `*.d.ts` and `main.tsx`. Coverage is a gate on the whole project: new code ships with its
spec, not with an exemption.

## Layout

- **Specs are colocated**: `foo.tsx` -> `foo.spec.tsx`, `foo.ts` -> `foo.spec.ts` (suffix `.spec.ts(x)`, never `.test`).
  Route specs are in `src/routes/-specs/<route>.spec.tsx` (the `-` keeps them out of the route tree).
- `test/setup.ts` — jest-dom matchers, imports the i18n provider module, starts the MSW server with
  `onUnhandledRequest: 'error'`, sets language to `pt-BR`, polyfills `scrollTo`, `scrollIntoView` and pointer
  capture (Radix), runs `cleanup()` and `server.resetHandlers()` after each test.
- `test/msw/server.ts` + `test/msw/handlers.ts` + `test/msw/handlers/<feature>.handlers.ts` — default handlers,
  one array per feature, spread into `handlers`. Defaults answer with the _empty/neutral_ state.
- `test/fixtures/<feature>.ts` — typed builders with overrides (`emptyAccountList()`, `pendingImport()`,
  `doneImport({ ... })`), typed with the real API types from the feature's `types.ts`.
- `test/helpers/` — small shared interaction helpers (`waitForImportStart`).
- `test/render.tsx` — `renderWithProviders(ui)`: `I18nProvider` + a fresh `QueryClient` (`retry: false`) +
  `ToastProvider`. Use it for any component that uses Query, i18n or toasts.
- `test/router.tsx` — `renderRouterAt(path, { signedIn? })`: the real `routeTree` on a memory history with all
  providers; stubs `POST */auth/refresh` and `GET */auth/me` for a signed-in owner unless the path is public
  (`/login`). Use it for route specs.
- Pure `shared/ui` components can use plain `render` from RTL (i18n is initialised globally by the setup).

## Rules

1. **Query by role and label, never by test id or class.** Text assertions use the **pt-BR** strings, since the
   suite runs in pt-BR (`screen.getByRole('button', { name: 'Receber código' })`). If something is hard to query,
   fix the accessibility, do not add `data-testid`.
2. **The API is mocked at the network layer with MSW**, not by stubbing hooks. Override per test with
   `server.use(http.post('*/auth/code', ...))` — the `*/` prefix matches any `VITE_API_URL`. Error handlers return
   the real problem+json shape: `{ type: 'auth.invalid_code', title, status, detail, requestId }`.
   Because unhandled requests fail the test, a new endpoint used by a rendered screen needs a default handler in
   `test/msw/handlers/<feature>.handlers.ts`.
3. **Test behaviour, not implementation.** "shows the invalid e-mail message after submit", not "calls useQuery".
4. A screen has at least: happy path, empty state, API error (translated message visible) and, if it has a form,
   one validation failure.
5. `await screen.findBy...` / `waitFor` for async; never `setTimeout`. For timers use `vi.useFakeTimers()` locally and
   restore. `userEvent.setup()` per test, typed `UserEvent`.
6. Hooks in `api/` are tested with `renderHook` and a wrapper with a `QueryClient` (`retry: false`), asserting
   `isSuccess` / `isError` and the invalidation they trigger (see `use-account.mutations.spec.tsx`).
7. Pure logic (`lib/`, schemas, key factories, error-message maps) gets plain unit specs. Error-message specs build
   the translator with `i18n.getFixedT('pt-BR', '<ns>')` and cover each known code plus the unknown and non-`ApiError`
   fallbacks.
8. `vi.mock` is for what the network cannot reach: `@/shared/config/env` (via `vi.hoisted`), browser SDKs (Google
   Identity, Facebook login), `@/shared/lib/analytics`. When mocking a module partially, spread
   `await vi.importActual(...)`.
9. Mind the lint: specs are exempt from `local/no-else`, `local/no-search-in-loop` and `i18next/no-literal-string`,
   but **not** from `local/no-comments`, typed declarations (`const user: UserEvent = ...`) or the 40-line function
   limit (split big `describe` bodies into helpers).

## i18n guards

- `parity.spec.ts` fails if a key exists in one locale and not in the others — add keys to every locale's file.
- `no-literal-string.spec.ts` asserts the lint rule is on and behaves as intended; do not weaken the config.
- Feature-specific catalogs (e.g. `import-error-catalog.spec.ts`) check dictionaries against a fixture generated
  from the API; regenerate the fixture when the API catalog changes.

## What NOT to test

The generated `schema.d.ts`, Radix internals, Tailwind classes, or that a library does what its docs say.
`eslint-rules/*.spec.mjs` exist for the custom lint rules (`no-fixed-color`): add one when adding a rule.
