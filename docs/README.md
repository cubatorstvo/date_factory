# DATE FACTORY v2 — docs

This repository `main` branch is the **new** Date Factory project.

The previous prototype lives only as a read-only donor:

- path: `../date_factory_legacy`
- branch / tag: `legacy-v1`

## Product truth

When a new Master GDD is provided, place it at:

```text
docs/MASTER_GDD.md
```

Conflict priority:

```text
new MASTER_GDD
>
explicit latest user instruction
>
new project code
>
legacy donor documentation/code
```

Legacy documentation in the donor is reference material about the old implementation only. It does **not** define requirements for v2.
