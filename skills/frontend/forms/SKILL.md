---
name: forms
description: >
  Form patterns for vera-fe: react-hook-form + zod with translated messages, schema factories,
  submit states, masks and accessibility. Use whenever building or changing a form, validation, or
  handling submit errors. Triggers on: "form", "formulário", "input", "validação", "validation", "zod",
  "react-hook-form", "useForm", "zodResolver", "submit", "erro de campo", "field error", "máscara", "Field".
---

# Forms — vera-fe

**react-hook-form + `@hookform/resolvers/zod` + zod 3.** Reference implementations:
`features/auth/components/email-step.tsx` (small form) and `features/settings/components/profile-form.tsx`
(masks, sections, nullable fields).

## Schemas are factories that take `t`

Validation messages are user-facing, so they are translation keys like any other text. A schema therefore
lives in `features/<feature>/schemas/<name>.schema.ts` as a **function of `t`**, and the form memoizes it:

```ts
export function createEmailSchema(
  t: TFunction<"auth">,
): ZodObject<{ email: ZodString }> {
  return z.object({
    email: z
      .string()
      .trim()
      .min(1, t("emailRequired"))
      .email(t("emailInvalid")),
  });
}
export type EmailInput = z.infer<ReturnType<typeof createEmailSchema>>;
```

```ts
const schema = useMemo(
  (): ZodObject<{ email: ZodString }> => createEmailSchema(t),
  [t],
);
const form: UseFormReturn<EmailInput> = useForm<EmailInput>({
  resolver: zodResolver(schema),
  mode: "onTouched",
  defaultValues: { email: "" },
});
```

- `*.schema.ts` is exempt from `typedef.variableDeclaration` (annotating would collapse `z.infer`); everything else
  in the file is still typed.
- The error keys (`emailRequired`, `profile.errors.name_required`) are added to the every locale's files
  of the feature's namespace (see `ui-and-styling`).
- Constants such as regexes and max lengths are named `const`s at the top of the schema file.

## Rules

1. **Mirror the API rules, do not invent new ones.** The API is the authority; the schema states the same limits
   so the user sees them before submitting (`MAX_LENGTH`, 11-digit CPF, 6-digit code).
2. **`mode: 'onTouched'`** — validate on blur, revalidate on change. Never shout at an untouched field.
3. **Normalize before validating.** Masked inputs keep the formatted value in the field and strip it in the schema
   with `z.preprocess(digitsOnly, ...)`; empty optional values become `null` via `.transform(toNullable)`. Masks
   (`maskCpf`, `maskCep`, `maskPhoneBr`, `maskUf`) are in `shared/lib/format/input-masks.ts`; the `masked()` helper
   in `profile-form.tsx` wraps `register` and applies the mask in `onChange`. Convert form values to the API
   body in a small `toApiInput` function, not inline.
4. **API errors.** The error code goes through the feature's `lib/*-error-message.ts` (see `data-fetching`) and is
   shown as a toast (`useToast().show({ tone: 'critical', ... })`), an `Alert`, or `FailureAlert` above the form.
   `ApiError.fieldIssues()` returns `{ path, message }[]` from `meta.errors` when a field-level mapping is needed
   (`form.setError(path, ...)`); the message shown to the user must still be a translated one, not the raw API text.
   On a failed submit, `form.setFocus(...)` the first relevant field.
5. **Disable submit while pending and say what is happening.** `Button` takes `loading` and sets `aria-busy`;
   swap the label too (`busy ? t('sendingCode') : t('sendCode')`). `busy` combines `formState.isSubmitting` with
   every mutation `isPending` on the form.
6. **A form does not navigate by itself.** It receives `onCodeSent` / `onAuthenticated`-style callbacks; the page
   decides what comes next.
7. Submit through `form.handleSubmit(async (input) => { try { await mutation.mutateAsync(...) } catch ... })` and
   render `<form noValidate>` so the browser does not preempt the zod messages.

## Fields and accessibility

Use `Field` from `@/shared/ui/field` (label bound by id, `aria-invalid`, `aria-describedby`, error with
`role="alert"`, built-in show/hide for `type="password"`):

```tsx
<Field
  label={t("emailLabel")}
  type="email"
  placeholder={t("emailPlaceholder")}
  hint={t("emailHint")}
  error={form.formState.errors.email?.message}
  {...form.register("email")}
/>
```

Other controls: `OtpInput`, `SelectMenu` (Radix select), `DateField`, `SearchInput`, `TokenField`, `FileDrop`,
`CopyField`. Every label, placeholder, hint and `aria-label` is a `t()` call — `i18next/no-literal-string` fails the
build otherwise.

## Sensitive fields

- Codes: `inputMode="numeric"` and `autoComplete="one-time-code"` (`OtpInput`); 6 digits validated by regex.
- Never log form values, never put them in query params, never persist drafts that touch credentials. (Drafts of
  non-sensitive content such as the entry message are persisted through the API, not browser storage.)
