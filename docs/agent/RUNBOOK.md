# DATE FACTORY agent orchestration runbook

## Roles

- Orchestrator: GPT 5.6 Sol in main Cursor Agent chat.
- Technical workers: Cursor Grok 4.5 custom subagents.
- Final acceptance: Orchestrator after independent QA.

## Workflow

1. User provides product goal or playtest issue.
2. Orchestrator defines intended player experience.
3. Researcher maps implementation if needed.
4. Orchestrator records decisions and acceptance.
5. Work is split into isolated packages.
6. Ownership is assigned.
7. Up to three independent workers run in parallel.
8. Results are integrated.
9. Orchestrator reviews diff and evidence.
10. QA independently replays the route.
11. Orchestrator accepts or rejects.

## Model policy

- Main: GPT 5.6 Sol selected manually.
- Workers: Cursor Grok 4.5.
- No Auto.
- No Fast.
- No inherit.
- No nested subagents.

## Do not multitask

- same scene/script;
- save schema;
- global time;
- autoload;
- dating state machine;
- city root;
- shared catalog.

## Good multitask candidates

- independent read-only research;
- separate scenes;
- asset audit versus gameplay code;
- content after schema freeze;
- independent QA after integration.

## Definition of done

Feature is done only when:

- normal player flow works;
- scene is reachable;
- state is preserved;
- no blocking runtime errors;
- screenshots prove the claim;
- QA passes;
- Orchestrator accepts.
