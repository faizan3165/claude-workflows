# Form example: schema → server action → React Hook Form + shadcn Field

A complete create form for Zod 4, React Hook Form 7, `@hookform/resolvers` 5, and shadcn/ui with the `field`, `select`, `checkbox`, `spinner` and `sonner` components. `requireUser` and `createProject` stand in for your auth helper and domain function.

## Shared schema: `src/lib/projects/schema.ts`

```ts
import * as z from "zod"

export const projectSchema = z.object({
  name: z.string().trim().min(2, "Use at least 2 characters").max(80, "Keep it under 80 characters"),
  visibility: z.enum(["private", "team", "public"]),
  notify: z.boolean(),
})

export type ProjectInput = z.infer<typeof projectSchema>
```

## Server action: `src/actions/projects.ts`

```ts
"use server"

import { revalidatePath } from "next/cache"
import * as z from "zod"
import { requireUser } from "@/lib/auth/session"
import { AppError, toActionError, type ActionResult } from "@/lib/errors/app-error"
import { createProject } from "@/lib/projects/service"
import { projectSchema } from "@/lib/projects/schema"

export async function createProjectAction(input: unknown): Promise<ActionResult<{ id: string }>> {
  try {
    const user = await requireUser()
    const parsed = projectSchema.safeParse(input)
    if (!parsed.success) {
      throw new AppError("VALIDATION_FAILED", "Check the highlighted fields.", {
        fieldErrors: z.flattenError(parsed.error).fieldErrors,
      })
    }
    const project = await createProject(user.id, parsed.data)
    revalidatePath("/projects")
    return { ok: true, data: { id: project.id } }
  } catch (error) {
    return toActionError(error)
  }
}
```

The ownership and role checks live in `createProject` (the domain layer), so the route handler gets them too.

## Hook: `app/(app)/projects/new/_hooks/use-create-project-form.ts`

```ts
import { useTransition } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { toast } from "sonner"
import { createProjectAction } from "@/actions/projects"
import { projectSchema, type ProjectInput } from "@/lib/projects/schema"

export function useCreateProjectForm() {
  const [pending, startTransition] = useTransition()
  const form = useForm<ProjectInput>({
    resolver: zodResolver(projectSchema),
    defaultValues: { name: "", visibility: "private", notify: false },
  })

  const onSubmit = form.handleSubmit((values) =>
    startTransition(async () => {
      const result = await createProjectAction(values)
      if (result.ok) {
        toast.success("Project created")
        form.reset()
        return
      }
      for (const [name, messages] of Object.entries(result.error.fieldErrors ?? {})) {
        if (messages?.[0]) form.setError(name as keyof ProjectInput, { message: messages[0] })
      }
      toast.error(result.error.message)
    }),
  )

  return { form, onSubmit, pending }
}
```

## Form: `app/(app)/projects/new/_components/create-project-form.tsx`

```tsx
"use client"

import { Controller } from "react-hook-form"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Field, FieldError, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Spinner } from "@/components/ui/spinner"
import { useCreateProjectForm } from "../_hooks/use-create-project-form"

export function CreateProjectForm() {
  const { form, onSubmit, pending } = useCreateProjectForm()

  return (
    <form onSubmit={onSubmit} noValidate>
      <FieldGroup>
        <Controller
          name="name"
          control={form.control}
          render={({ field, fieldState }) => (
            <Field data-invalid={fieldState.invalid}>
              <FieldLabel htmlFor={field.name}>Name</FieldLabel>
              <Input {...field} id={field.name} aria-invalid={fieldState.invalid} autoComplete="off" />
              {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
            </Field>
          )}
        />
        <Controller
          name="visibility"
          control={form.control}
          render={({ field, fieldState }) => (
            <Field data-invalid={fieldState.invalid}>
              <FieldLabel htmlFor={field.name}>Visibility</FieldLabel>
              <Select name={field.name} value={field.value} onValueChange={field.onChange}>
                <SelectTrigger id={field.name} aria-invalid={fieldState.invalid}>
                  <SelectValue placeholder="Choose who can see it" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="private">Only me</SelectItem>
                  <SelectItem value="team">My team</SelectItem>
                  <SelectItem value="public">Everyone</SelectItem>
                </SelectContent>
              </Select>
              {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
            </Field>
          )}
        />
        <Controller
          name="notify"
          control={form.control}
          render={({ field }) => (
            <Field orientation="horizontal">
              <Checkbox id={field.name} checked={field.value} onCheckedChange={field.onChange} />
              <FieldLabel htmlFor={field.name}>Email me about activity</FieldLabel>
            </Field>
          )}
        />
      </FieldGroup>
      <Button type="submit" disabled={pending}>
        {pending && <Spinner />}
        Create project
      </Button>
    </form>
  )
}
```

## Page: `app/(app)/projects/new/page.tsx`

```tsx
import { CreateProjectForm } from "./_components/create-project-form"

export default function NewProjectPage() {
  return <CreateProjectForm />
}
```

Things to keep:
- The page stays a Server Component.
- The handler lives in a hook, not inline JSX.
- One schema serves both the form and the action.
- Every field goes through `Controller`.
- Errors surface inline and in a toast.
- The button shows the pending state.
