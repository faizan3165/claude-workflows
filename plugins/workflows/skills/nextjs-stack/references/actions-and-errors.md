# Errors, action results and route handlers

## `src/lib/errors/app-error.ts`

```ts
export type ErrorCode =
  | "VALIDATION_FAILED"
  | "UNAUTHENTICATED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "CONFLICT"
  | "INTERNAL"

export type FieldErrors = Partial<Record<string, string[]>>

const STATUS: Record<ErrorCode, number> = {
  VALIDATION_FAILED: 422,
  UNAUTHENTICATED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL: 500,
}

export class AppError extends Error {
  readonly fieldErrors?: FieldErrors

  constructor(
    readonly code: ErrorCode,
    message: string,
    options: { fieldErrors?: FieldErrors; cause?: unknown } = {},
  ) {
    super(message, { cause: options.cause })
    this.fieldErrors = options.fieldErrors
  }

  get status() {
    return STATUS[this.code]
  }
}

export type ActionError = { code: ErrorCode; message: string; fieldErrors?: FieldErrors }
export type ActionResult<T> = { ok: true; data: T } | { ok: false; error: ActionError }

export function toActionError(error: unknown): { ok: false; error: ActionError } {
  if (error instanceof AppError) {
    return { ok: false, error: { code: error.code, message: error.message, fieldErrors: error.fieldErrors } }
  }
  console.error(error)
  return { ok: false, error: { code: "INTERNAL", message: "That didn't save. Try again in a moment." } }
}
```

Grow the code list as features need it (`ENTITLEMENT_REQUIRED`, `RATE_LIMITED`...). Codes are stable machine strings; messages are user-safe copy. Log the `cause` server-side, and never send it to the client.

## `src/lib/errors/http.ts`

```ts
import { NextResponse } from "next/server"
import { AppError, toActionError } from "./app-error"

export function toErrorResponse(error: unknown) {
  const { error: body } = toActionError(error)
  return NextResponse.json({ error: body }, { status: error instanceof AppError ? error.status : 500 })
}
```

## Route handler: `app/api/projects/route.ts`

```ts
import { NextResponse } from "next/server"
import * as z from "zod"
import { requireApiUser } from "@/lib/auth/api"
import { AppError } from "@/lib/errors/app-error"
import { toErrorResponse } from "@/lib/errors/http"
import { createProject } from "@/lib/projects/service"
import { projectSchema } from "@/lib/projects/schema"

export async function POST(request: Request) {
  try {
    const user = await requireApiUser(request)
    const body = await request.json().catch(() => null)
    const parsed = projectSchema.safeParse(body)
    if (!parsed.success) {
      throw new AppError("VALIDATION_FAILED", "Invalid project data", {
        fieldErrors: z.flattenError(parsed.error).fieldErrors,
      })
    }
    const project = await createProject(user.id, parsed.data)
    return NextResponse.json({ data: { id: project.id } }, { status: 201 })
  } catch (error) {
    return toErrorResponse(error)
  }
}
```

- The handler calls the same `createProject` as the server action. There is no second copy of the logic.
- Malformed JSON becomes `null`, so it fails validation (422) instead of crashing with a 500.

## Webhooks

- Read the raw body (`await request.text()`) and verify the provider's signature before parsing.
- Respond quickly, then do slow work in a queue or background job.
- Make handlers idempotent: the provider retries, so store and check event ids.

## Tests to write with each action or route

- Valid input → success result or 2xx, with the right shape.
- Invalid input → `VALIDATION_FAILED` / 422 with field errors.
- No session → 401. Another user's resource → 403 or 404, whichever the repo uses.
- A domain conflict → 409 with its code.
- Mock the database and external services. Test the domain function directly for the edge cases.
