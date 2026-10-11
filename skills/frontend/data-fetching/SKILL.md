---
name: data-fetching
description: >
  How vera-fe talks to the API: generated OpenAPI client (openapi-fetch), TanStack Query hooks,
  query keys, invalidation, problem+json errors and the token refresh flow. Use whenever fetching or
  mutating data, creating a hook in features/*/api, or handling an API error. Triggers on: "fetch",
  "api", "query", "mutation", "useQuery", "useMutation", "cache", "invalidate", "erro da api", "loading",
  "openapi", "api:types", "schema.d.ts", "apiClient", "unwrap", "tipos da api", "refresh token", "ApiError".
---

# Data fetching — vera-fe

## The client is generated, never hand-written

`npm run api:types` downloads the OpenAPI document from the running API (`http://localhost:3333/docs-json`)
and regenerates `src/shared/lib/api/schema.d.ts` with `openapi-typescript`. The file is committed and
excluded from lint. Run it whenever the API contract changes; a breaking change then fails the typecheck at
the exact call site. A missing `.describe()` on the API side becomes a wrong type here.

`src/shared/lib/api/client.ts` exports:

- `apiClient` — `openapi-fetch` client typed by `paths`, `baseUrl = env.VITE_API_URL`, `credentials: 'include'`,
  with an auth middleware (bearer from `tokenStore`; on a 401 it calls `refreshSession()` once, deduplicated,
  and retries the original request). Auth endpoints that carry their own credentials are never retried.
- `unwrap(result)` — returns `data` or throws `ApiError`; `unwrapEmpty(result)` for calls with no body.
  Both report an `api_error` analytics event.

Never redeclare an API type by hand. Derive it in the feature's `types.ts`:

```ts
export type AccountView =
  paths["/accounts/{id}"]["get"]["responses"]["200"]["content"]["application/json"];
export type AccountKind = AccountView["kind"];
```

## Hooks are the only data access

Every call lives in `features/<feature>/api/` (or `features/<feature>/<sub>/api/`) as a hook. The lint
allows importing `@/shared/lib/api/client` and calling `fetch` only in those folders, in
`src/app/providers/**` and in `src/shared/lib/api/**`. Anywhere else it is an error
(`Só app/providers e módulos de dados podem importar o cliente da API`).

File naming: `use-<thing>.query.ts`, `use-<thing>.queries.ts` (several related), `use-<thing>.mutation.ts`,
`use-<thing>.mutations.ts`, and `<feature>-keys.ts`. Example (`features/accounts/api/use-account.query.ts`):

```ts
export function useAccount(id: string): UseQueryResult<AccountView> {
  return useQuery({
    queryKey: accountsKeys.detail(id),
    queryFn: async ({ signal }): Promise<AccountView> =>
      unwrap(
        await apiClient.GET("/accounts/{id}", {
          params: { path: { id } },
          signal,
        }),
      ),
  });
}
```

Always pass `signal`, annotate the hook's return type, and wrap with `unwrap`. Polling is a `refetchInterval`
callback on the query data (an import status hook polls every 2.5 s while `status === 'pending'`).

## Query keys

One factory per feature, in `api/<feature>-keys.ts`, with an explicit tuple type (the file is annotated; keys
are consumed as `readonly [...]`):

```ts
export const accountsKeys: {
  all: readonly ["accounts"];
  detail: (id: string) => readonly ["accounts", "detail", string];
} = {
  all: ["accounts"] as const,
  detail: (id: string): readonly ["accounts", "detail", string] =>
    [...accountsKeys.all, "detail", id] as const,
};
```

Never inline a raw array at a call site. Anything that changes the result goes into the key.

## Mutations and invalidation

- Share the `onSuccess` of a family of mutations with a private generic hook, as an `useInvalidatingAccount`
  (invalidates `detail()` and the list) or a profile mutation (writes the response with
  `queryClient.setQueryData`) does.
- Invalidate the narrowest key that could have changed. When the caller must see fresh data once the mutation
  resolves, `await Promise.all([queryClient.invalidateQueries(...), ...])` inside an async `onSuccess`.
- No optimistic updates in the codebase today. Keep it that way for anything touching money (balances,
  transactions, budgets): show real state or nothing.
- The mutation's outcome is surfaced by the caller (toast via `useToast`, inline `Alert`/`FailureAlert`).

## Errors: the API speaks problem+json, the UI speaks i18n

`unwrap` turns a failure into `ApiError` (`shared/lib/api/api-error.ts`) whose `problem` is
`{ type, title, status, detail, requestId, meta? }`.

- **`problem.type` IS the error code** (`auth.invalid_code`, `import.invalid_file`, `validation_failed`). There
  is no separate `code` field. `detail` is technical English for logs/support — it is not UI copy.
- The frontend owns `code -> translated message`. The pattern is a `lib/<feature>-error-message.ts` with a
  lookup table typed against the namespace and a generic fallback (`features/auth/lib/auth-error-message.ts`):

```ts
const ERROR_KEYS: Readonly<Record<string, AuthKey>> = {
    'auth.invalid_code': 'errorInvalidCode',
    validation_failed: 'errorValidationFailed'
};
export function authErrorMessage(t: TFunction<'auth'>, error: Error): string { ... }
```

An unknown code, or a non-`ApiError` (network failure), falls back to the namespace's generic key
(`errorGeneric`, `errors.generic`). When the API itself returns i18n keys (`titleKey`, `whyKey`), `translateApiKey` only translates keys that exist in the pt-BR dictionary and returns
anything else untouched. See `ui-and-styling` for where the dictionaries live.

- Add the new code's key to every locale's files in the same PR (the parity spec fails otherwise) and a
  test case to the `*-error-message.spec.ts`.
- `ApiError.fieldIssues()` extracts `meta.errors` (path + message) for field-level mapping; see `forms`.
- `FailureAlert` (`shared/ui`) renders `problem.detail`, and the `requestId` for 5xx only. Today it is used
  for generic load/toggle failures; prefer a translated message for anything the user is expected to act on.
- `429` is handled where it matters, with its own toast, never as a generic failure.

## Defaults

`QueryProvider` (`app/providers/query-provider.tsx`): `staleTime` 30 s, queries retry up to 2 times only for
5xx/network (never for an `ApiError` below 500), mutations never retry. Tests build their own `QueryClient`
with `retry: false`. Loading states use the skeletons in `shared/ui` (`skeleton-form`, `skeleton-table`).
