# Actugate: Python -> Nim Migration Report

> Дата: 24 июня 2026
> Python-версия: `/home/user/code/actugate-old` (v0.4, ~1600 строк)
> Nim-версия: `/home/user/code/actugate` (v0.00002, ~967 строк)
> Техсправка: https://telegra.ph/Actugate-06-09

---

## Оглавление

1. [Сводная таблица различий](#1-сводная-таблица-различий)
2. [Архитектура](#2-архитектура)
   - 2.1 [Структура проектов](#21-структура-проектов)
   - 2.2 [Хранилище мира (World Storage)](#22-хранилище-мира-world-storage)
   - 2.3 [Система типов и домен](#23-система-типов-и-домен)
   - 2.4 [Рендеринг](#24-рендеринг)
   - 2.5 [Ввод и управление](#25-ввод-и-управление)
   - 2.6 [Сохранение/загрузка](#26-сохранениезагрузка)
3. [Производительность](#3-производительность)
   - 3.1 [Язык и рантайм](#31-язык-и-рантайм)
   - 3.2 [Структуры данных](#32-структуры-данных)
   - 3.3 [Цикл симуляции](#33-цикл-симуляции)
   - 3.4 [Рендеринг](#34-рендеринг)
4. [Функционал](#4-функционал)
   - 4.1 [Полная матрица функций](#41-полная-матрица-функций)
   - 4.2 [Детальные различия по механикам](#42-детальные-различия-по-механикам)
5. [Что можно сделать лучше в Nim-версии](#5-что-можно-сделать-лучше-в-nim-версии)
   - 5.1 [Критические пробелы (без них нет паритета)](#51-критические-пробелы-без-них-нет-паритета)
   - 5.2 [Архитектурные улучшения](#52-архитектурные-улучшения)
   - 5.3 [Производительность](#53-производительность)
   - 5.4 [Новые возможности](#54-новые-возможности)
   - 5.5 [Качество кода и инфраструктура](#55-качество-кода-и-инфраструктура)

---

## 1. Сводная таблица различий

| Аспект | Python (old) | Nim (new) | Статус |
|--------|-------------|-----------|--------|
| **Язык** | Python 3.14 | Nim 2.0+ | -- |
| **LOC (без тестов)** | ~1600 | ~900 | Nim компактнее |
| **Графика** | pyray (raylib bindings) | naylib (raylib bindings) | Паритет по бэкенду |
| **Типы клеток** | 5 (Activator, Piston, StickyPiston, Rod, Box) | 3 (Activator, Piston, Rod) | **Nim отстает** |
| **Типы планов** | 3 (Keep, ExtendRod, StickyRetractRod) | 2 (ExtendRod, RetractRod) | **Nim отстает** |
| **Система приоритетов** | Полная (-9..9) | Частичная (поле есть, UI неполный) | **Nim отстает** |
| **Условная активация** | Да (Box + operator + color) | Нет | **Nim отстает** |
| **Sticky Piston** | Полная реализация | Нет | **Nim отстает** |
| **Box (коробка)** | Полная (256 цветов, hex ID) | Нет | **Nim отстает** |
| **Сохранение на диск** | Бинарный `.acts` с CRC32 | Только in-memory | **Nim отстает** |
| **Анимации** | Полные (movement lerp, appear/delete, priority) | Нет (мгновенная отрисовка) | **Nim отстает** |
| **Текстуры** | Pre-rendered RenderTexture2D | Immediate-mode rectangles | **Nim отстает** |
| **Камера** | Smooth zoom + smooth pan | Smooth zoom + momentum pan | Nim лучше (momentum) |
| **Сетка** | Fade по зуму | Адаптивный LOD | Nim лучше |
| **Terminal REPL** | Нет | Полный CLI | **Nim уникальный** |
| **Тест-генерация** | Нет | Автогенерация тестов из REPL | **Nim уникальный** |
| **HUD** | FPS, coords, cell name | FPS, tick, coords, cell type | Паритет |
| **Hotbar** | Клавиши 1-4 + Q (pick) | CLI-команды (A, Pd, etc.) | Подходы разные |
| **Resize окна** | Нет | Да | **Nim лучше** |
| **ID-аллокатор** | Нет (identity-based hash) | SmartCounter (free-list) | Nim лучше |
| **Fixed timestep** | Да (TPS=15) | Да (TPS=1 в GUI) | Python лучше (TPS) |

---

## 2. Архитектура

### 2.1 Структура проектов

**Python:**
```
actugate-old/
├── main.py                 # Точка входа
├── Content.py              # Клетки + планы (домен)
├── Enums.py                # Direction, ConditionOperator, CursorChange
├── Utils.py                # Util + RenderUtil
├── World.py                # Движок симуляции
├── SaveSystem.py           # Бинарная сериализация
├── test.py                 # Бенчмарк raylib
└── Renderer/
    ├── Config.py           # Конфигурация рендера
    ├── GameIOSystem.py     # Главный цикл + ввод
    └── WorldRender.py      # 644 строки рендеринга!
```

**Nim:**
```
actugate/
├── src/
│   ├── actugate.nim        # Точка входа + REPL + GUI
│   ├── data/
│   │   ├── cells.nim       # Типы клеток
│   │   ├── plans.nim       # Типы планов
│   │   └── spatial.nim     # Position, Direction
│   ├── core/
│   │   ├── core.nim        # Движок симуляции
│   │   └── utils.nim       # Утилиты + макрос
│   └── render/
│       ├── camera.nim      # Камера
│       ├── colors.nim      # Цвета
│       ├── coords.nim      # Screen -> Cell
│       ├── draw.nim        # Отрисовка клеток
│       ├── grid.nim        # Фоновая сетка
│       ├── renderer.nim    # Инициализация
│       ├── types.nim       # Render types
│       └── utils.nim       # Resize
└── tests/                  # Автосгенерированные тесты
```

**Ключевые архитектурные различия:**

| Аспект | Python | Nim |
|--------|--------|-----|
| Модульность рендера | 1 монолитный файл (644 LOC) | 8 мелких файлов (246 LOC суммарно) |
| Разделение слоев | 2 слоя (Logic + Renderer) | 3 слоя (Data + Core + Render) |
| Entry point | Чистый GUI | REPL + опциональный GUI |
| Конфигурация | Класс `Config` с мета-программированием | `RenderConfig` record + inline-константы |

**Вывод:** Nim-версия имеет лучшее разделение ответственности с чистой 3-слойной архитектурой (`data/` -> `core/` -> `render/`). Python-версия более монолитна, особенно в рендеринге.

### 2.2 Хранилище мира (World Storage)

| Аспект | Python | Nim |
|--------|--------|-----|
| Основная структура | `bidict[Position, Cell]` | `Table[Position, Cell]` |
| Гарантия 1:1 | Да (bidict enforced) | Нет (только pos->cell) |
| Обратный поиск (cell->pos) | O(1) через `bidict.inverse` | O(n) через `idget` (linear scan) |
| Pending буфер | `bidict[Position, Cell]` | `Table[Position, Cell]` |
| ID ячеек | `id(obj)` (Python identity) | `SmartCounter` (free-list allocator) |
| Swap стратегия | `self.current, self.pending = self.pending, self.current` | `swap(self.current, self.pending)` |

**Анализ:** Python использует `bidict` для двустороннего маппинга position<->cell, что критично для `WorldRender.get_renders()` (быстрый поиск cell->pos). Nim использует обычный `Table`, и обратный поиск по ID через линейный скан `idget` -- это O(n) вместо O(1). Однако `idget` используется только в REPL, а не в simulation loop, поэтому пока это не bottleneck.

### 2.3 Система типов и домен

**Python -- Class Hierarchy + Registry:**
```
Cell (base)
  ├── Activator     TYPE_ID=0
  ├── Piston        TYPE_ID=1
  ├── StickyPiston  TYPE_ID=2 (extends Piston)
  ├── Rod           TYPE_ID=3
  └── Box           TYPE_ID=4

Plan (base)
  ├── Keep          TYPE_ID=0
  ├── ExtendRod     TYPE_ID=1
  └── StickyRetractRod TYPE_ID=2
```
Используется паттерн Registry через декоратор `@type_accounting(id)`. Каждый класс автоматически регистрируется в `Cell.TYPE_MAP` и `Render.TYPE_MAP`.

**Nim -- Variant Objects (Tagged Unions):**
```nim
CellKind = enum ckNone, ckActivator, ckPiston, ckRod
Cell = object
  case kind: CellKind
  of ckActivator, ckNone: discard
  of ckPiston: direction, priority, activated, rod
  of ckRod: pistonDirection, pistonPosition

PlanKind = enum pkExtendRod, pkRetractRod
Plan = ref object
  case kind: PlanKind
  of pkExtendRod: target, chain
  of pkRetractRod: pistonPosition
```

**Сравнение подходов:**

| Аспект | Python (class hierarchy) | Nim (variant objects) |
|--------|--------------------------|----------------------|
| Полиморфизм | Runtime (vtable) | Compile-time (tag dispatch) |
| Аллокация | Heap (каждый Cell -- объект в куче) | Stack (Cell -- value type, кроме Plan) |
| Расширяемость | Легко добавить новый подкласс | Нужно менять enum + case |
| Паттерн-матчинг | isinstance() checks | case kind (exhaustive) |
| Sizeof | ~120-200 bytes (Python object overhead) | ~40-60 bytes (union size) |
| Безопасность | Можно забыть isinstance check | Компилятор проверяет exhaustiveness |

**Критическое отличие:** В Python `Cell.__hash__` использует `id(self)` (identity-based), а `__eq__` -- value-based сравнение. Это намеренное нарушение hash/eq контракта для работы с `bidict`, где каждый экземпляр Cell уникален. В Nim такой проблемы нет -- `Cell` это value type с автоматическим structural equality.

### 2.4 Рендеринг

**Python (WorldRender.py, 644 строки):**
- Pre-rendered текстуры через `RenderTexture2D` для каждого типа клетки
- Полноценная система анимаций:
  - Movement lerp (ease-out cubic) между старой и новой позицией
  - Appear/Delete scale animations
  - Priority indicator animations (arrows up/down + text)
  - Rod extension/retraction animation
  - Cursor ghost cell с плавным следованием
- Registry паттерн для рендер-классов (`Render.TYPE_MAP`)
- Раздельные рендер-классы: `ActivatorRender`, `BoxRender`, `PistonRender`, `StickyPistonRender`
- Luminance-based адаптивный контраст текста для Box

**Nim (render/*.nim, 246 строк суммарно):**
- Immediate-mode отрисовка через `drawRectangleRec` / `drawRectangleLinesEx`
- Без анимаций -- мгновенное перемещение
- Без текстур -- все рисуется геометрическими примитивами каждый кадр
- Без cursor ghost cell
- Простой `for pos, cell in world.current: drawCell(cell, pos)` цикл
- Adaptive grid с LOD (major/minor линии, динамический пропуск при зуме)

**Вывод:** Python-версия на порядок сложнее в рендеринге. Nim-версия минималистична и функциональна, но визуально примитивна.

### 2.5 Ввод и управление

**Python (GameIOSystem.py):**
| Действие | Реализация |
|----------|------------|
| Размещение клетки | Left-click drag (с cursor ghost preview) |
| Удаление | Right-click drag |
| Активация поршня | Left-click (на пустую ячейку / без cursor cell) |
| Зум | Ctrl + scroll wheel, smooth lerp |
| Панорама | Middle mouse drag, smooth lerp |
| Направление | W/A/S/D (меняет direction клетки) |
| Hotbar | Клавиши 1-4 (Sticky, Activator, Box, Piston) |
| Выбор/Отмена | Q (pick cell / deselect) |
| Приоритет | Shift+scroll (change), Shift+MMB (reset) |

**Nim (actugate.nim):**
| Действие | Реализация |
|----------|------------|
| Размещение | CLI: `A` (activator), `Pd` (piston+direction) |
| Удаление | CLI: `E` / `e` |
| Инспекция | CLI: `i` |
| Зум | Scroll wheel, smooth lerp + anchor-toward-cursor |
| Панорама | MMB drag + momentum (friction-based deceleration) |
| Направление | CLI: `Pw`, `Pa`, `Ps`, `Pd` |
| Приоритет | CLI: `p5`, `p-3` |
| Сохранение | CLI: `S name` / `L name` (in-memory) |
| Тик | CLI: `t` / GUI: автоматический |
| GUI | CLI: `gui` / `G` (открывает окно) |
| Тест-генерация | CLI: `T name save1\|save2\|save3` |

**Вывод:** Python-версия имеет полноценный GUI workflow. Nim-версия имеет уникальный dual-mode (CLI + GUI), но GUI-управление сейчас ограничено только камерой -- все размещение через CLI.

### 2.6 Сохранение/загрузка

**Python (SaveSystem.py, 224 строки):**
- Полная бинарная сериализация в `.acts` формат
- Структура: HEADER (magic + version + count) + OBJECTS + CRC32
- Поддержка всех типов клеток со всеми полями
- Инкрементальный CRC32 через `zlib.crc32`
- Кастомные исключения: `FileSignatureMismatchError`, `UnsupportedVersionError`, `InvalidSaveDataError`, `CorruptedDataError`
- Утилита `BitInt` для bit-field packing
- Version-based dispatch для forward compatibility

**Nim:**
- **Отсутствует полностью.** Только in-memory saves через `Table[string, (int, World)]`
- Saves теряются при выходе из программы
- Нет бинарного формата
- Нет checksums
- Нет обработки ошибок I/O

---

## 3. Производительность

### 3.1 Язык и рантайм

| Аспект | Python | Nim |
|--------|--------|-----|
| Исполнение | Интерпретатор CPython 3.14 | Нативный код (компиляция в C -> binary) |
| GC | Reference counting + cycle detector | ARC/ORC (deterministic) |
| Типизация | Динамическая | Статическая с выводом типов |
| FFI overhead | cffi -> raylib (через Python object wrapping) | Прямая компиляция в C вызовы |
| Startup | ~200-500ms (import + JIT warmup) | ~1-5ms (native binary) |
| Baseline memory | ~30-50MB (Python runtime) | ~2-5MB (minimal runtime) |
| Object overhead | ~56 bytes per object (PyObject header) | 0 bytes (value types on stack) |

**Оценка ускорения Nim vs Python для CPU-bound кода:** 10x-100x для simulation loop, 2x-5x для rendering (оба используют raylib C через FFI, но Python имеет wrapping overhead).

### 3.2 Структуры данных

| Структура | Python | Nim | Влияние |
|-----------|--------|-----|---------|
| World cells | `bidict` (~2x hash table) | `Table` (~1x hash table) | Nim: 2x меньше памяти, но нет reverse lookup |
| Position | `tuple` (immutable, cached hash) | `tuple[x,y: int]` (value type, computed hash) | Сопоставимо |
| Cell | Heap-allocated class instance | Stack-allocated variant object | Nim: 10x-50x меньше аллокаций |
| Plans dict | `dict[pos, list[Plan]]` | `Table[pos, Plan]` | Nim: макс 1 plan/pos vs Python list |
| Plan chain | `dict[from_pos, to_pos]` | `OrderedTable[pos, pos]` | Nim: ordered, но с TODO на `seq` |
| Direction | Enum class instance | Enum (compile-time integer) | Nim: zero overhead |

**Ключевое различие:** В Python `plans` это `dict[pos, list[Plan]]` -- на каждую позицию может быть несколько планов, а конфликты разрешаются в `resolve_conflicts`. В Nim `plans` это `Table[pos, Plan]` -- максимум один план на позицию, что упрощает resolve но может быть семантически ограничивающим.

### 3.3 Цикл симуляции

Согласно бенчмарку Python-версии (`01.06.2026.BENCHMARK.md`), при 10,000 клетках:
- `collect_plans`: **78.5%** тикового времени
- `resolve_conflicts`: ~15%
- `apply_plans`: ~6.5%

**Bottleneck**: итерация по всем клеткам + проверка соседей для каждого поршня.

**Python collect_plans:**
```python
for pos, cell in self.current.items():
    if isinstance(cell, (Piston, StickyPiston)):
        # Check neighbors (4 dict lookups)
        # Build chain (while loop с dict lookups)
```
Каждая итерация: isinstance check (Python динамическая типизация), 4 dict lookup для соседей, возможно N dict lookups для chain.

**Nim collect_plans:**
```nim
for pos, cell in self.current:
    if cell.kind == ckPiston:
        # Check neighbors (4 table lookups)
        # Build chain (while loop)
```
Каждая итерация: integer comparison для kind, 4 table lookups для соседей, возможно N lookups для chain.

**Преимущество Nim:**
- `cell.kind == ckPiston` -- сравнение одного integer vs Python `isinstance()` (проход по MRO)
- Table lookup -- нативный hash без Python object wrapping
- Отсутствие GIL -- потенциально можно распараллелить (Python не может)
- Inline функции `dx`, `dy`, `apply` -- zero overhead vs Python method calls

### 3.4 Рендеринг

**Python:**
- Pre-rendered текстуры (один draw call per cell): хорошо для GPU
- Создание render objects каждый тик (allocation pressure)
- Lerp анимации добавляют вычислительную нагрузку каждый кадр
- Grid: простые линии с alpha fade

**Nim:**
- Immediate-mode rectangles: больше draw calls, но проще
- Нет аллокаций для рендеринга (все на стеке)
- Нет анимаций -- минимальная нагрузка per frame
- Grid: адаптивный LOD (лучше при высоком zoom-out)

**Вывод:** Nim-версия рендерит быстрее за счет простоты, но визуально беднее. Python-версия имеет лучшую GPU-утилизацию (текстуры, батчинг) но больше CPU overhead на анимации.

---

## 4. Функционал

### 4.1 Полная матрица функций

| Функция | Техсправка | Python | Nim | Примечания |
|---------|------------|--------|-----|------------|
| **Activator** | Да | Да | Да | Паритет |
| **Piston** | Да | Да | Да | Паритет |
| **Sticky Piston** | Да | Да | **Нет** | Nim не реализован |
| **Rod** | Да | Да | Да | Паритет |
| **Box** | Да | Да | **Нет** | Nim не реализован |
| **Условная активация** | Да | Да | **Нет** | Зависит от Box |
| **Приоритеты клеток** | Да (-9..9) | Да | Частично | Поле есть, но UI неполный в GUI |
| **Конфликты позиций** | Да | Да | Да | Паритет (разная реализация) |
| **Тик: сбор планов** | Да | Да | Да | Паритет |
| **Тик: разрешение конфликтов** | Да | Да | Да | Паритет |
| **Тик: применение планов** | Да | Да | Да | Паритет |
| **Детерминизм** | Да | Да | Да | Обе версии детерминированы |
| **Бесконечный мир** | Да | Да | Да | Обе: hash table без границ |
| **Анимации движения** | Подразумевается | Да (cubic ease-out) | **Нет** | |
| **Анимации появления/удаления** | Подразумевается | Да | **Нет** | |
| **Звуки** | Да (по техсправке) | **Нет** | **Нет** | Не реализовано ни в одной |
| **Меню** | Да (по техсправке) | **Нет** | **Нет** | Не реализовано ни в одной |
| **Сохранение на диск** | Да (.acts binary) | Да | **Нет** | |
| **Тулбар / Hotbar** | Да (по техсправке) | Да (1-4 + Q) | **Нет** (CLI) | |
| **Настройки** | Да (по техсправке) | Частично (Config.py) | **Нет** | |
| **MSAA** | -- | Конфигурируемый | **Нет** | |
| **VSync** | -- | Конфигурируемый | Да (hardcoded) | |
| **TPS настройка** | -- | Да (Config.TPS=15) | Hardcoded (1 тик/сек) | |
| **Resize окна** | -- | Нет | Да | |
| **Terminal REPL** | -- | **Нет** | Да | Уникально для Nim |
| **Генерация тестов** | -- | **Нет** | Да | Уникально для Nim |
| **ASCII-рендер** | -- | **Нет** | Да | Уникально для Nim |
| **Камера momentum** | -- | **Нет** (только smooth) | Да | |
| **Zoom к курсору** | -- | **Нет** (zoom к центру) | Да | |
| **Adaptive grid LOD** | -- | **Нет** (alpha fade) | Да | |

### 4.2 Детальные различия по механикам

#### 4.2.1 Keep Plan

**Python:** Explicit `Keep` plan type. Каждая "живая" клетка получает `Keep` plan в `collect_plans`. Конфликты между `Keep` и `ExtendRod` разрешаются через удаление `Keep` при overlap.

**Nim:** Implicit `keep` boolean на самой `Cell`. Поле `keep = true` ставится по умолчанию в `collect_plans`. В `apply_plans` копируются только клетки с `keep = true`. Нет отдельного типа плана.

**Влияние:** Nim-подход проще и эффективнее (нет аллокации Plan объектов для Keep), но менее гибок для расширения.

#### 4.2.2 Retract Rod

**Python:** `StickyRetractRod` plan -- при деактивации StickyPiston забирает 1 клетку обратно (тянет через позицию rod). Обычный Piston просто удаляет rod.

**Nim:** `RetractRod` plan -- просто удаляет rod (очищает `piston.rod` поле). Нет pull-back механики, т.к. StickyPiston не реализован.

#### 4.2.3 Активация

**Python:**
```python
# 3 условия активации:
# 1. Manual (active_pos == pos)
# 2. Adjacent Activator (не в direction поршня)
# 3. Adjacent Box с условием (operator + color_id)
```

**Nim:**
```nim
# 1 условие активации:
# Adjacent Activator (не в direction поршня)
```

Manual activation и conditional activation из Box отсутствуют.

#### 4.2.4 Conflict Resolution

**Python:**
```python
best = min(plan_list, key=lambda p: (-p[1].priority, p[0][1], p[0][0]))
```
Сортировка: highest priority -> topmost (min Y) -> leftmost (min X).

**Nim:**
```nim
func best_plan(entry: tuple): (int, int, int) =
  (-entry[1].priority, entry[0].y, entry[0].x)
# Used with minBy
```
Идентичная логика, но реализованная через `minBy` вместо `min` с key.

---

## 5. Что можно сделать лучше в Nim-версии

### 5.1 Критические пробелы (без них нет паритета)

#### 5.1.1 Реализовать StickyPiston

**Что:** Добавить `ckStickyPiston` в `CellKind` и `pkStickyRetractRod` в `PlanKind`.

**Почему:** Согласно техсправке, StickyPiston -- ключевая механика, без которой "механизмы не могут возвращаться в начальное состояние", что делает игру "не просто функцией, а сложным алгоритмом".

**Как:**
- `cells.nim`: Добавить `ckStickyPiston` variant с теми же полями что `ckPiston`
- `plans.nim`: Добавить `pkStickyRetractRod` variant с `target`, `pullPos`
- `core.nim` `collect_plans`: При деактивации StickyPiston -- создавать `StickyRetractRod` plan
- `core.nim` `apply_plans`: Обработать `StickyRetractRod` -- переместить клетку из `pullPos` в `target`
- `draw.nim`: Отрисовка с другим цветом (`StickyPiston` color уже определен в `colors.nim:15`)

#### 5.1.2 Реализовать Box

**Что:** Добавить `ckBox` в `CellKind` с полем `colorId: int` (0-255, -1 = colorless).

**Почему:** Box -- основа условной активации поршней, без которой невозможны компактные логические схемы (техсправка: "несколько поршней должны активироваться по-разному").

**Как:**
- `cells.nim`: Добавить `ckBox` variant с `colorId` и `priority`
- `core.nim` `try_activate_piston`: Расширить логику -- если рядом Box с `colorId >= 0` и у поршня есть `ActivateCondition`, проверить condition
- `cells.nim`: Добавить `ActivateCondition` тип (operator + colorId)
- `draw.nim`: Отрисовка Box с цветом из color table

#### 5.1.3 Реализовать SaveSystem

**Что:** Бинарная сериализация мира на диск в формате `.acts`.

**Почему:** Техсправка: "продуманная система упаковки сохранения в бинарный формат". Без persistent saves игра бесполезна для пользователей.

**Как:**
- Создать `src/save/` модуль
- Формат: Header (magic "Actuate\0" + version u16 + count u32) + Objects + CRC32
- Использовать Nim `streams` или raw `File` I/O
- Bit-packing для flags (Nim bitfields или manual bit ops)
- CRC32 через `std/crc32` или ручная реализация
- Custom error types через `object of CatchableError`

#### 5.1.4 Manual Activation (click-to-activate)

**Что:** В GUI-режиме клик по поршню должен вручную активировать его на 1 тик.

**Почему:** Это единственный способ тестировать поршни без рядом стоящего активатора. Python-версия имеет `world.active_pos`.

**Как:** Добавить `activePos: Option[Position]` в `World` или передавать через параметр `update`.

### 5.2 Архитектурные улучшения

#### 5.2.1 Reverse Index для Cell -> Position

**Проблема:** `idget` в `core.nim:33` -- O(n) линейный скан. При масштабировании до 1M клеток (техсправка: "работает до миллиона") это станет bottleneck.

**Решение:**
```nim
World = object
  current: Table[Position, Cell]
  cellIndex: Table[CellID, Position]  # Обратный индекс
```
Поддерживать `cellIndex` синхронно с `current` при каждом `place`/`remove`/`swap`.

**Альтернатива:** Если `bidict`-подобная семантика нужна часто, написать Nim-версию `BiTable[A, B]`.

#### 5.2.2 Plans как Table[Position, seq[Plan]]

**Проблема:** Текущий `Table[Position, Plan]` ограничен 1 планом на позицию. В Python -- `dict[pos, list[Plan]]`. Это может стать проблемой при добавлении StickyPiston и Box (несколько планов на одну позицию).

**Решение:** Вернуться к `Table[Position, seq[Plan]]` или использовать flat array с индексом.

#### 5.2.3 Разделить actugate.nim

**Проблема:** `actugate.nim` (371 строк) -- monolith, содержащий REPL, GUI loop, тест-генерацию и command dispatcher.

**Решение:**
```
src/
├── actugate.nim        # Entry point (30 строк)
├── cli/
│   ├── repl.nim        # REPL loop + handle()
│   ├── commands.nim    # Command parsing
│   └── ascii.nim       # Terminal renderer
├── gui/
│   ├── loop.nim        # GUI main loop (runGui)
│   ├── input.nim       # GUI input handling
│   └── hud.nim         # HUD overlay
└── testing/
    └── generator.nim   # Test file generation
```

#### 5.2.4 ECS (Entity Component System) вместо Variant Object

**Проблема:** С ростом числа типов клеток (техсправка упоминает будущие обновления) variant object становится все менее удобным -- каждое новое поле требует изменения всех `case` блоков.

**Рассмотреть:** Переход на ECS-подобную архитектуру:
```nim
type
  Entity = distinct int
  Components = object
    positions: Table[Entity, Position]
    directions: Table[Entity, Direction]
    priorities: Table[Entity, int]
    activations: Table[Entity, bool]
    rods: Table[Entity, Entity]  # piston -> rod
    colors: Table[Entity, int]   # box color
    conditions: Table[Entity, ActivateCondition]
```
**Плюсы:** Гибкость, cache-friendly при итерации по компонентам, легко добавить новые компоненты.
**Минусы:** Complexity overhead, потеря compile-time type safety variant objects.
**Рекомендация:** Отложить до появления 7+ типов клеток. Для текущих 5 типов variant object оптимален.

#### 5.2.5 Render Object Pool

**Проблема Python-версии:** `WorldRender.get_renders()` создает новые Render objects каждый тик. Это allocation pressure.

**Решение для Nim:** Если/когда будет анимационная система, использовать object pool или arena allocator вместо `seq[Render]`. Nim позволяет control allocation strategy на уровне типа.

### 5.3 Производительность

#### 5.3.1 Spatial Hashing / Chunked World

**Проблема:** При 1M клеток `Table[Position, Cell]` имеет значительный overhead (hash per lookup, cache misses из-за разбросанных entries).

**Решение:**
```nim
const ChunkSize = 64  # 64x64 cells per chunk
type
  ChunkPos = tuple[cx, cy: int]
  Chunk = object
    cells: array[ChunkSize * ChunkSize, Cell]
    count: int
  World = object
    chunks: Table[ChunkPos, Chunk]
```
**Плюсы:**
- Cache-friendly итерация (cells внутри chunk contiguous в памяти)
- O(1) lookup без hash для клеток внутри chunk
- Естественный frustum culling для рендеринга (рисуем только видимые chunks)
- Легко параллелить: chunks можно обрабатывать в разных threads

**Минусы:** Complexity, overhead для sparse worlds (много пустых chunks).

**Рекомендация:** Реализовать когда текущая Table станет bottleneck (~100K+ клеток).

#### 5.3.2 Compile с `-d:release` / `-d:danger`

**Проблема:** `nim.cfg` содержит `debugger = "native"` и `stacktrace = "on"`. Это debug-конфигурация с bounds checking, overflow checking, etc.

**Решение:** Добавить release profile:
```
# nim.cfg (или nimble task)
when defined(release):
  --opt:speed
  --passC:"-flto"
  --passL:"-flto"
```
**Ожидаемое ускорение:** 2x-5x для CPU-bound simulation code.

#### 5.3.3 `func` enforcement

**Наблюдение:** Все simulation procs в Nim уже `func` (compile-time no side effects). Это отлично -- компилятор может оптимизировать aliasing и inline агрессивнее. **Продолжать эту практику** при добавлении новых mechanics.

#### 5.3.4 Избавиться от `OrderedTable` в chain

**Проблема:** `Plan.chain: OrderedTable[Position, Position]` -- тяжелая структура. TODO в `plans.nim:13` уже отмечает это.

**Решение:**
```nim
Plan = ref object
  ...
  of pkExtendRod:
    target: Position
    chain: seq[(Position, Position)]  # Lightweight, contiguous memory
```
`seq` аллоцируется один раз и contiguous в памяти. `OrderedTable` имеет hash overhead + pointer chasing.

#### 5.3.5 Plan как value type

**Проблема:** `Plan = ref object` -- единственный ref type в кодовой базе. Каждый Plan аллоцируется в куче и подлежит GC.

**Решение:** Если chain будет `seq`, Plan становится крупнее, но всё ещё может быть value type с move semantics:
```nim
Plan = object  # value type, no GC
  priority: int
  case kind: PlanKind
  of pkExtendRod:
    target: Position
    chain: seq[(Position, Position)]  # seq is move-friendly
  of pkRetractRod:
    pistonPosition: Position
```
Nim 2.0+ с ARC будет делать move для `seq` вместо copy.

#### 5.3.6 Parallel collect_plans

**Проблема:** `collect_plans` -- 78.5% тикового времени (по бенчмарку Python). В Nim нет GIL, поэтому можно параллелить.

**Подход:**
```nim
import std/threadpool
# Split world into N chunks, each thread collects plans for its chunk
# Merge plans after all threads finish
```
**Сложность:** Medium-high. Нужно гарантировать что чтение `current` world потокобезопасно (оно read-only во время collect_plans -- уже thread-safe). Запись планов потребует per-thread local plans + merge.

**Рекомендация:** Реализовать после того как single-threaded performance станет bottleneck (~500K+ клеток).

### 5.4 Новые возможности

#### 5.4.1 Анимационная система

**Что:** Smooth lerp movement, appear/delete effects, rod extension animation.

**Как в Python:** Каждый тик создается `Render` object с `old_pos` и `new_pos`. Между тиками `tick_progress` интерполируется от 0 до 1, и `get_moved()` возвращает lerp позицию.

**Как сделать в Nim:**
```nim
type
  CellAnimation = object
    oldPos, newPos: Position
    phase: float32  # 0.0 .. 1.0
    kind: AnimKind   # Move, Appear, Delete

proc interpolate(anim: CellAnimation): Vector2 =
  let t = easeOutCubic(anim.phase)
  lerp(anim.oldPos.toVec2, anim.newPos.toVec2, t)
```
Хранить `seq[CellAnimation]` отдельно от `World` (separation of concerns). Обновлять phase каждый кадр, удалять завершенные анимации.

#### 5.4.2 Pre-rendered текстуры

**Что:** Рисовать каждый тип клетки в `RenderTexture2D` один раз, затем `drawTexture` вместо `drawRectangle`.

**Зачем:** Уменьшает количество draw calls. При 10K+ клетках immediate-mode прямоугольники становятся bottleneck.

**Как:**
```nim
proc initCellTextures() =
  # For each cell type:
  let tex = loadRenderTexture(CellSize, CellSize)
  beginTextureMode(tex)
  # Draw cell geometry once
  endTextureMode()
  # Store tex for reuse
```

#### 5.4.3 GUI Input (размещение через мышь)

**Что:** Click-to-place, drag-to-place, right-click-to-delete, hotbar.

**Реализация:**
- Добавить `cursorCell: Option[CellKind]` в state
- Left click/drag: `world.place(screenToCell(mousePos), newCell(cursorCell))`
- Right click/drag: `world.remove(screenToCell(mousePos))`
- Keys 1-4: выбор типа клетки
- Ghost cell (полупрозрачная preview)

#### 5.4.4 Звуковая система

**Техсправка:** "Все клетки имеют свой уникальный звук с 4 вариациями."

Raylib/naylib имеет встроенную звуковую поддержку:
```nim
import raylib
let sound = loadSound("activator_1.wav")
playSound(sound)
```

#### 5.4.5 Система меню

**Техсправка:** "Три кнопки: выбрать сохранение, настройки, выход."

Реализовать FSM (Finite State Machine) для состояний приложения:
```nim
type
  AppState = enum asMenu, asGame, asSettings
```

#### 5.4.6 TPS-настройка в GUI

**Проблема:** TPS захардкожен как 1 тик/сек в GUI (`TickRate = 1`). Python использует 15 TPS.

**Решение:** Сделать `TickRate` конфигурируемым. Добавить клавиши +/- для runtime изменения TPS.

### 5.5 Качество кода и инфраструктура

#### 5.5.1 Настроить `nimble test`

**Проблема:** Тесты есть (`tests/*.nim`), но нет nimble task для их запуска.

**Решение в `actugate.nimble`:**
```nim
task test, "Run tests":
  for f in listFiles("tests"):
    if f.endsWith(".nim"):
      exec "nim c -r " & f
```

#### 5.5.2 Удалить артефакты из репозитория

- `src/core/core.exe` -- stale Windows binary, не должен быть в git
- `nimble.paths` -- в `.gitignore`, но tracked

#### 5.5.3 Исправить опечатки

`actugate.nim:266`: `"pidtonDirection"` и `"pidtonPosition"` -> `"pistonDirection"` и `"pistonPosition"`.

#### 5.5.4 Config система

**Проблема:** Конфигурация разбросана по inline-константам в разных файлах (`draw.nim:CELL_SIZE=32`, `actugate.nim:tileSize=32`, `camera.nim:MinZoom=0.5`).

**Решение:** Единый `config.nim` модуль:
```nim
# src/config.nim
const
  CellSize* = 32
  DefaultTPS* = 15
  WindowWidth* = 1280
  WindowHeight* = 720
  CameraMinZoom* = 0.5
  CameraMaxZoom* = 4.0
  CellPadding* = CellSize div 7
  # ...
```

#### 5.5.5 Error handling strategy

**Проблема:** Nil error handling в Nim-версии. Нет кастомных exceptions, нет обработки невалидных вводов в REPL (кроме basic parsing).

**Решение:** Определить иерархию ошибок:
```nim
type
  ActugateError = object of CatchableError
  SaveError = object of ActugateError
  InvalidSaveError = object of SaveError
  CorruptedSaveError = object of SaveError
```

---

## Приоритизированный план действий

### Фаза 1: Паритет с Python (критический функционал)
1. StickyPiston (ckStickyPiston + StickyRetractRod plan)
2. Box (ckBox + color system + conditional activation)
3. GUI input (click-to-place, drag, hotbar, ghost cell)
4. Manual piston activation (click)
5. TPS настройка (поднять до 15, сделать регулируемым)
6. SaveSystem (бинарный .acts формат)

### Фаза 2: Визуальное качество
7. Анимации движения (lerp с ease-out)
8. Анимации appear/delete
9. Pre-rendered текстуры (RenderTexture2D)
10. Priority indicators (стрелки + число)
11. Cursor ghost cell с smooth following

### Фаза 3: Оптимизация
12. Reverse index (CellID -> Position)
13. Plan.chain: OrderedTable -> seq
14. Plan: ref object -> value object
15. Release build profile (-d:release, LTO)
16. Config централизация

### Фаза 4: Масштабирование
17. Spatial chunking для 100K+ клеток
18. Parallel collect_plans
19. Frustum culling по chunks

### Фаза 5: Полнота продукта
20. Звуковая система
21. Главное меню
22. Settings UI
23. Challenge mode (по техсправке)
