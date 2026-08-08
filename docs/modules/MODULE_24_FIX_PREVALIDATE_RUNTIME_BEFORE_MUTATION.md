# MODULE 24 FIX — PREVALIDATE RUNTIME BEFORE MUTATION

Остался один acceptance blocker в MODULE 24.

## Проблема

Текущий flow:

```text
_read_validate_payload()
→ проверяет schema/root/day/наличие CloneIncremental keys
→ _restore_validated_payload()
→ GameState.restore_save_state()   # УЖЕ МУТИРУЕТ GAME STATE
→ GameDay.restore_day()
→ CloneIncremental.restore_runtime_state()
```

`CloneIncremental.restore_runtime_state()` может вернуть `false`, например при:

```text
production_elapsed_seconds < 0
money_fraction < 0
date_fraction < 0
```

В этом случае load возвращает `RESTORE_FAILED`, но GameState уже заменён содержимым неуспешно загруженного save.

Это нарушает MODULE24:

```text
validate fully before mutation
load failure does not mutate current game
```

## Требуемый фикс

### 1. Pure validation seam в CloneIncremental

Добавить в:

```text
game/clone_incremental/clone_incremental.gd
```

pure method:

```gdscript
func validate_runtime_state(data: Dictionary) -> bool:
```

или лучше:

```gdscript
func normalize_runtime_state(data: Dictionary) -> Dictionary:
```

Preferred `normalize_runtime_state`, потому что текущий restore ещё нормализует fractions.

Semantic:

```text
input must contain:
production_elapsed_seconds
money_fraction
date_fraction

all values must be finite numeric
production_elapsed_seconds >= 0
money_fraction >= 0
date_fraction >= 0

normalize fractions:
fraction = fraction - floor(fraction)

output:
{
  ok=true,
  production_elapsed_seconds=...,
  money_fraction normalized [0,1),
  date_fraction normalized [0,1)
}
```

При ошибке:

```text
{ok=false}
```

NO mutation.

### 2. restore_runtime_state reuse

`restore_runtime_state(data)` НЕ должен иметь отдельную вторую реализацию правил.

Он вызывает тот же pure normalizer:

```text
normalized = normalize_runtime_state(data)
if !ok:
    return false

apply normalized values
recalculate_rates()
resolve production
return true
```

Одна validation truth.

### 3. SaveSystem prevalidation

В `_read_validate_payload()` ДО возврата:

```text
{"ok": true, ...}
```

получить `/root/CloneIncremental` и вызвать pure validation/normalization для:

```text
runtime.clone_incremental
```

Если invalid:

```text
VALIDATION_FAILED
```

Load не должен доходить до `_restore_validated_payload()`.

Не надо хранить normalized payload отдельно, если restore повторно вызывает тот же pure normalizer.

### 4. Finite values

Проверить:

```text
NaN
INF
-INF
```

если они могут попасть через runtime/test payload.

Reject.

Не допускай бесконечный while в `_resolve_production_spawns()` из-за non-finite elapsed.

### 5. Test — critical no-mutation

Добавить в:

```text
persistence/test/save_system_self_test.gd
```

exact regression:

1. Создать valid save payload A с отличимым GameState, например:
   ```text
   Money = 1234
   Stage = 3
   Day = 9
   ```
2. Записать его в slot.
3. Отредактировать save:
   ```text
   runtime.clone_incremental.money_fraction = -1.0
   ```
   остальной payload оставить valid.
4. Текущий live state перед load установить:
   ```text
   Money = 77777
   Stage = 1
   Day = 4
   ```
5. `load_slot()`.

Expected:

```text
ok = false
error = VALIDATION_FAILED
live Money remains 77777
live Stage remains 1
live Day remains 4
CloneIncremental live runtime remains unchanged
```

То есть reject происходит ДО любой mutation.

### 6. Additional runtime corrupt cases

Test at least:

```text
production_elapsed_seconds = -0.1
date_fraction = -0.1
```

Can batch them.

If practical also test non-finite via direct validator unit test.

### 7. Do not overbuild transaction rollback

НЕ нужно создавать:

```text
SaveTransaction
rollback snapshot
double GameState clone
generic transactional persistence engine
```

Правильное решение здесь — просто полностью prevalidate все потенциально-failing persistent blocks до первого mutation.

### 8. Existing behavior stays

Не менять:

```text
schema v1
slots
autosave
backup
settings
world fallback
stable-save guard
fraction persistence
no offline progress
```

## Definition of Done

- [ ] CloneIncremental runtime validation has a pure no-mutation seam.
- [ ] restore_runtime_state reuses the same validation.
- [ ] SaveSystem validates CloneIncremental runtime before GameState restore.
- [ ] negative/non-finite runtime is rejected before mutation.
- [ ] failed runtime validation leaves GameState, GameDay and CloneIncremental live state untouched.
- [ ] new regression test proves this.
- [ ] all MODULE24 save tests pass.
- [ ] all previous regressions pass.
- [ ] STOP. Do not begin MODULE25.
