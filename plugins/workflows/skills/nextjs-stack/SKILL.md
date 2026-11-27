---
name: nextjs-stack
description: Conventions for Next.js App Router apps on React 19, TypeScript, Tailwind CSS v4, shadcn/ui, React Hook Form and Zod. Covers route co-location, server components and streaming, server actions over a shared domain layer, thin route handlers, three-layer validation, structured errors, shadcn Field + Controller forms, sonner feedback, design tokens in globals.css with cn() and CVA, loading and destructive-action patterns, security, accessibility and tests. Use when writing, refactoring or reviewing code in a Next.js App Router project. The repo's own rules and existing patterns win.
---

# Next.js App Router stack

## When it applies

- `next` is in `package.json` and there's an `app/` or `src/app/` folder. In a Pages Router repo, use only the UI, form, validation and error sections.
- Read the installed major versions first (`next`, `react`, `tailwindcss`, `zod`, `react-hook-form`, `@hookform/resolvers`) and write code for those versions.
- The repo's rules and the patterns already in the code beat this skill. Copy the nearest existing example before inventing one.

Full examples: [references/forms.md](references/forms.md) (schema → action → form) and [references/actions-and-errors.md](references/actions-and-errors.md) (errors, route handlers).

## 1. Routes and co-location

```
app/(group)/route-name/
├── page.tsx        ← Server Component only. Never 'use client'. Fetch + compose.
├── loading.tsx     ← skeleton for the route (or <Suspense> inside the page)
├── error.tsx       ← error boundary where the route can fail
├── _components/    ← UI used only by this route
├── _hooks/         ← client hooks used only by this route
├── _actions/       ← server actions used only by this route
└── _lib/           ← pure helpers, handlers, types. No React.
```

Hard rules:
1. `page.tsx` is always a Server Component.
2. No logic in JSX. Handlers and helpers go in `_lib/` or a hook; components render and delegate.
3. No client-side fetching of app data (`useEffect` + `fetch`). Fetch on the server.
4. Mutations go through server actions.
5. Next.js 15+: `params` and `searchParams` are Promises (`const { id } = await params`); `cookies()` and `headers()` are async.

**Promotion:** once something is used by 2 or more routes, move it to the shared layer. `_components` → `src/components`, `_hooks` → `src/hooks`, `_actions` → `src/actions/<domain>.ts`, `_lib` → `src/lib/<domain>/` (domain logic) or `src/utils/` (generic helpers).

**File size (new work):** `page.tsx` stays thin. Components have a soft cap of about 150 lines; split sections into siblings. No "god" helper files. When you touch a legacy route, move it toward this layout.

## 2. Data fetching

- **Awaited:** `const data = await getData()` in an async `page.tsx`, passed to a view.
- **Streamed (preferred for slow data):** the page calls `getData()` without awaiting and passes the promise to a client component, which calls `use(promise)` inside `<Suspense fallback={<Skeleton… />}>`.
- Put `import "server-only"` at the top of modules that touch the database, secrets or private APIs.
- Pass client components only the serializable fields they need, never whole DB rows or secrets.

## 3. Server actions and the domain layer

- Business logic lives in `src/lib/<domain>/`: DB access, payments, storage, email, authorization rules.
- Actions (`'use server'`) in `_actions/` or `src/actions/<domain>.ts` call that layer. Route handlers call the same functions. Never duplicate logic between an action and a route.
- Every action runs in this order: authenticate → authorize (ownership and role) → Zod parse → call lib → revalidate (`revalidatePath`/`revalidateTag` from `next/cache`) → return a typed result.
- Return `{ ok: true, data } | { ok: false, error: { code, message, fieldErrors? } }`. Don't throw raw errors across the boundary.
- `redirect()` and `notFound()` work by throwing. Call them outside `try/catch`.
- Progressive-enhancement forms use `useActionState` (from `react`) with the action. Rich client forms use React Hook Form and call the action inside `startTransition`. Follow whichever the repo already uses.

## 4. Route handlers (`app/api/**/route.ts`)

Only when HTTP is needed: webhooks, mobile or third-party clients, uploads with progress, streaming. If a mobile client will need an endpoint, ship it with the feature, not in a later API sprint.

Each handler is a thin controller: parse with Zod → call the same lib function → `NextResponse.json(data, { status })`. Errors return `{ error: { code, message } }` with the right 4xx or 5xx. Webhooks verify the signature against the raw body.

## 5. Validation: three layers

1. **UI:** React Hook Form + Zod, for instant field feedback.
2. **Server:** the action or route parses again with the same schema. Never trust the client.
3. **Database:** constraints, unique indexes, foreign keys, ownership checks.

- Schemas live in shared modules (`src/lib/<domain>/schema.ts` or `src/schemas/<domain>.ts`), imported by both the form and the action.
- Derive types with `z.infer<typeof schema>`; don't write a duplicate interface.
- Zod 4: `import * as z from "zod"`, field errors via `z.flattenError(error).fieldErrors`. Zod 3: `import { z } from "zod"`, `error.flatten().fieldErrors`.
- Normalize inside the schema: `.trim()` text; lowercase emails and usernames before uniqueness checks.

## 6. Errors

- A small `AppError` (code, user-safe message, HTTP status, optional field errors and cause) in `src/lib/errors/`.
- Catch at the action or route boundary and map: validation → 422 with field errors; unauthenticated → 401; forbidden → 403; missing → 404; conflict → 409; unexpected → 500, logged server-side with context.
- Never show "Something went wrong" for a known failure. Say what happened and what to do.

## 7. UI with shadcn/ui

- All UI comes from `components/ui` (shadcn) or thin wrappers around it. Add missing pieces with `npx shadcn@latest add <component>`.
- Don't fork generated primitives. Customize through tokens, composition and CVA variants (`class-variance-authority`). Merge classes with `cn()` from `@/lib/utils` (clsx + tailwind-merge).
- Icons: whatever the repo uses (shadcn's default is `lucide-react`).
- **Feedback on every user action:**
  - Loading: disable the control and show `Spinner` or a skeleton; block double submits.
  - Success: a toast via `sonner` (`import { toast } from "sonner"`, `<Toaster />` from `@/components/ui/sonner` once in the root layout) or an inline confirmation.
  - Failure: a toast or an inline `Alert`. Never fail silently, and never use `window.alert` or `confirm`.
- **Destructive or irreversible actions** open an `AlertDialog` confirmation first, through one shared `ConfirmDialog` wrapper. Never call a delete action directly from `onClick`. The exception is ephemeral form state, such as removing an unsaved chip.
- **Loading states:** every async route gets `<Suspense>` or `loading.tsx` with a `Skeleton` that matches the final layout, never a blank page.
- Build reusable wrappers early (`SubmitButton`, `PageHeader`, `EmptyState`, `ConfirmDialog`, `PasswordField`) and promote them at the second use.

## 8. Forms: React Hook Form + Zod + shadcn Field

- `useForm({ resolver: zodResolver(schema), defaultValues })`, with `zodResolver` from `@hookform/resolvers/zod`. Always set `defaultValues` for every field.
- Every field goes through `<Controller />` and renders shadcn `Field`, `FieldLabel`, `FieldDescription` and `FieldError`:
  - `data-invalid={fieldState.invalid}` on `Field`, and `aria-invalid={fieldState.invalid}` on the control.
  - `id={field.name}` on the control, `htmlFor={field.name}` on the label.
  - `{fieldState.invalid && <FieldError errors={[fieldState.error]} />}`.
- Wiring by control:
  - `Input` and `Textarea`: spread `{...field}`.
  - `Select`: `value={field.value} onValueChange={field.onChange}`, with `aria-invalid` on `SelectTrigger`.
  - `Checkbox` and `Switch`: `checked={field.value} onCheckedChange={field.onChange}`.
  - `RadioGroup`: `value` + `onValueChange`.
  - Groups: `FieldSet` + `FieldLegend` + `FieldGroup` (`data-slot="checkbox-group"` for checkbox lists).
- Dynamic lists: `useFieldArray`, with `key={field.id}`, never the index.
- Server field errors go to `form.setError(name, { message })`; form-level errors to `form.setError("root", …)` or a toast.
- Put `noValidate` on `<form>` so inline errors show instead of browser bubbles. The submit button reflects pending state.
- Older repos on shadcn's `Form`/`FormField`/`FormMessage` wrappers: keep that pattern there.
- **Auth fields:**
  - Passwords use a shared `PasswordField` with a show/hide toggle (with an `aria-label`) and the right `autoComplete` (`current-password` or `new-password`).
  - Usernames and emails get `autoCapitalize="none"`, `autoCorrect="off"` and `spellCheck={false}`.

## 9. Tailwind v4 and design tokens

- CSS-first config: `@import "tailwindcss";` in `app/globals.css`. Tokens are CSS variables in `:root` and `.dark`, mapped with `@theme inline { --color-primary: var(--primary); … }`. New v4 projects have no `tailwind.config.js`.
- Use semantic token classes (`bg-primary`, `text-muted-foreground`, `border-border`), not raw hex or arbitrary values, wherever a token exists. Map shadcn's variables to the brand tokens in `globals.css` so `components/ui` stays on brand untouched.
- A long class string repeated 3 or more times becomes a component with CVA variants or an `@utility` in `globals.css`. No new per-feature CSS files.
- Layout chrome (page shell, sidebar, headers) is a reusable component, not copied JSX.
- Use logical properties (`ms-*`, `me-*`, `ps-*`, `pe-*`, `start-*`, `end-*`) so RTL works when it's needed.
- Dark mode follows the repo's approach (shadcn uses the `.dark` class, usually with `next-themes`).

## 10. Security and data

- Authorization is enforced server-side on every action, route and query (ownership and role), never just by hiding nav items.
- Secrets live only in server code. `NEXT_PUBLIC_` is for values that are safe to expose. Validate env vars with Zod at startup if the repo does.
- Database migrations are versioned in git (Drizzle, Prisma or the repo's tool). No manual production schema drift.
- No `dangerouslySetInnerHTML` with user content unless it's sanitized.

## 11. Accessibility and responsive

WCAG 2.1 AA on new UI: keyboard access, visible focus, labels on every control, contrast, `aria-*` on custom widgets. It must work at mobile, tablet and desktop widths.

## 12. Tests

- Use the repo's runner (Vitest or Jest with Testing Library; Playwright for end-to-end).
- Every new or changed server action and route handler gets tests in the same change:
  - Test the lib function and its error mapping.
  - For routes, assert status codes, the JSON shape and 4xx validation failures.
- Interactive components get component tests where the repo has them. Mock external I/O (database, payments, email, storage).
- Behavior changes update tests in the same PR, never in a follow-up.
