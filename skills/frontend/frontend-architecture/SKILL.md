---
name: frontend-architecture
description: >
  Folder structure, layer boundaries, routing, state ownership and session handling for vera-fe.
  Use this skill whenever creating a page, a feature, a route, a provider, or deciding where a file
  belongs, and when the lint says "Import cruza fronteira proibida". Triggers on: "nova tela", "new
  page", "feature", "rota", "route", "router", "estrutura", "onde colocar", "provider", "context",
  "estado global", "state", "arquitetura", "boundaries", "fronteira", "componente novo".
---

# Frontend architecture — vera-fe

React 19 + TypeScript strict, Vite, TanStack Router (file-based, typed), TanStack Query, Tailwind v4.
One build serves every environment; anything that differs between them (API URL, flags) comes from
zod-parsed `VITE_*` variables at build, never from branching on the hostname.

## Folder structure

```
src/
├── app/
│   ├── providers/      # query, i18n, session, toast providers (+ session-context.ts)
│   └── layouts/        # app-shell.tsx (AppShell, SetupShell), user-menu, support-button
├── routes/             # TanStack Router file tree; routeTree.gen.ts is generated and committed
│   └── -specs/         # route-level specs (the "-" prefix keeps them out of the route tree)
├── features/<feature>/
│   ├── api/            # query/mutation hooks + <feature>-keys.ts — the only code that touches the API client
│   ├── components/     # components that know this domain
│   ├── pages/          # route-level components
│   ├── lib/            # pure logic and feature hooks (use-*.ts) with no data access
│   ├── schemas/        # zod schemas for forms (*.schema.ts)
│   ├── content/        # static domain content (copy maps, variable lists)
│   └── types.ts        # types derived from the generated API types
├── shared/
│   ├── ui/             # design system primitives, no domain knowledge
│   ├── lib/            # api client, i18n, formatters, generic hooks (use-*.ts), cn
│   ├── config/         # env (zod-parsed VITE_*)
│   └── assets/
├── i18next.d.ts        # typed translation keys
├── index.css           # Tailwind v4 @theme tokens
└── main.tsx
test/                   # msw, fixtures, render helpers, setup (see the testing skill)
```

Not every feature has every folder (a feature with no screen of its own has no `pages`). A big
feature may nest sub-features with the same shape: `features/portfolio/allocation/{api,
components,lib,pages}` and `features/portfolio/rebalancing/...`. A nested folder is still
the same feature for the boundary rules. There is no `shared/hooks/` and no per-feature `hooks/`: hooks
live in `lib/` as `use-*.ts`.

## Boundaries (enforced by eslint-plugin-boundaries)

Elements: `shared`, `app`, `routes`, `feature` (one per `src/features/*`). Default is **disallow**;
allowed imports:

| From      | May import                                               |
| --------- | -------------------------------------------------------- |
| `shared`  | `shared`                                                 |
| `app`     | `shared`, `app`, any `feature`                           |
| `routes`  | `shared`, `app`, `routes`, any `feature`                 |
| `feature` | `shared`, `app`, **itself only** (same captured feature) |

Consequences:

1. **A feature never imports another feature.** If two need the same thing, move the generic part to
   `shared/` or compose both in a `route` or in `app`. This is why `routes/dashboard.index.tsx` can use
   `features/portfolio` and `features/spending` together, but `features/spending` cannot import `features/portfolio`.
2. **`shared` knows nothing about the domain** — no `app`, no `feature`, no `routes`. `shared/ui` has no
   `<AllocationCard>`; if it knows what an allocation is it belongs to a feature.
3. **`app` may import features** only for wiring (the session provider restores the session through
   `features/auth/api`). No business logic in `app/`.
4. Failure message is `Import cruza fronteira proibida (frontend-architecture skill)`.
   Flat config replaces rules per file, so do not add a second `boundaries/dependencies` block.

## Only the data layer touches the API client

`no-restricted-imports` forbids importing `**/shared/lib/api/client`, and `no-restricted-syntax`
forbids calling `fetch`, everywhere **except** `src/app/providers/**/*.tsx`, `src/features/*/api/**/*.ts`,
`src/features/*/*/api/**/*.ts` and `src/shared/lib/api/**`. Components and pages call hooks. Details in
the `data-fetching` skill.

## Routing (TanStack Router, file-based)

- Files in `src/routes/`: `login.tsx`, `transactions.$transactionId.tsx`, `accounts.$accountId.edit.tsx`,
  `onboarding_.assets.tsx` (the `_` after the segment opts out of the parent layout), `settings.profile.tsx`.
  `vite.config.ts` runs `tanstackRouter({ target: 'react', autoCodeSplitting: true })`, which regenerates
  `src/routeTree.gen.ts`. Never edit that file; it is excluded from lint.
- **Routes stay thin**: a route file is `createFileRoute('/settings/profile')({ component: ProfilePage })`
  importing the page from `features/<x>/pages`. Small glue that composes several features (e.g.
  `dashboard.index.tsx` reading a search param and composing two features) may live in the route.
- Search params are validated with zod through `validateSearch` (`dashboard.index.tsx`, `login.tsx`,
  `onboarding.tsx`), using `.optional().catch(undefined)` so a bad value degrades
  instead of throwing. Read them with `Route.useSearch()`, never by parsing `window.location`.
- `src/main.tsx` registers the router type (`declare module '@tanstack/react-router' { interface Register }`).
  Annotating `createRouter(...)` would kill path typing app-wide, which is why `routes/**/*.tsx` and
  `main.tsx` are in the typedef exemption list (see the `conventions` skill).
- The auth guard is `RequireSession` in `routes/__root.tsx`, not per page. Public prefixes
  (`/login`, `/_dev`), bare layout prefixes and setup shells (`/onboarding`) are decided there from the pathname. A new public route must be added to those lists.
- `routes/_dev/ui.tsx` is a design-system showcase, redirected to `/` outside `import.meta.env.DEV`.
  Add new `shared/ui` components to it.
- Route specs live in `src/routes/-specs/<route>.spec.tsx` and use `renderRouterAt` (see `testing`).

## State ownership

| Kind of state                          | Where it lives                                            |
| -------------------------------------- | --------------------------------------------------------- |
| Server data                            | TanStack Query — never mirrored into `useState`           |
| URL state (tab, return flags, filters) | route search params                                       |
| Form state                             | react-hook-form (see `forms`)                             |
| Session (user)                         | `SessionProvider` (`useSession()`), token in `tokenStore` |
| Toasts                                 | `ToastProvider` (`useToast().show({ tone, title })`)      |
| Ephemeral UI (modal open, hover)       | `useState` in the component                               |

There is no Zustand or Redux; do not add one without a second real case.

## Session

- The access token lives **in memory** (`tokenStore` in `shared/lib/api/token-store.ts`), never in
  `localStorage`/`sessionStorage`. The refresh token is an httpOnly cookie; the client middleware calls
  `POST /auth/refresh` on a 401 and retries once (see `data-fetching`).
- `SessionProvider` restores the session on boot (`restoreSession`) and clears `user` when the token store
  is cleared.

## Component shape

- One component per file, named export, kebab-case file (`account-card.tsx` exports `AccountCard`).
  Props are an exported `interface` above the component, all `readonly`.
- Every function is at most **40 lines** (`max-lines-per-function`), at most 3 levels of nesting and
  complexity 10. Stay under it by extracting subcomponents (`RevealToggle` inside `field.tsx`), custom hooks
  (`useImportFlow` in `import-page.tsx`) and pure helpers into `lib/`. A page composes; it does not hold
  300 lines of JSX.
- Early returns (loading, error, empty) before the main JSX; no `else` (`local/no-else`).
- `useEffect` is a last resort: derived state is computed, server state is Query's, events are handlers.
- No domain string literal in code: status, provider and the like are `as const` objects with a
  union type (`ASSET_KIND`, `ONBOARDING_STEPS`), or types derived from the API schema.
