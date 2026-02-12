---
name: python-dev
description: Use this skill whenever writing, debugging, or reviewing Python code. Triggers include any Python script creation, code refactoring, debugging Python errors, package management with pip/conda, virtual environment setup, test writing, or when the user mentions .py files or Python-specific tools/libraries. Apply these patterns for code structure, logging, error handling, and architectural preferences.
---

# Dependencies

If you need to install, update, or otherwise modify Python dependencies, use the `python-dependencies` skill.

# Python version

Assume you are using Python 3.10 or greater; older versions have reached end of life.
This means you can safely use the following:

- Improved type hinting, with less reliance on `Typing` module
    - Generics can be used --- such as `list[str]` and `dict[str, int]` --- without needing to use `List`, `Dict`, etc. from the `Typing` module
    - Can use `|` for union types. For example, use `str | None` instead of `Optional[str]` and `int | float` instead of `Union[int, float]`

- The walrus operator (`:=`) that assigns values to variables as part of a larger expression. Don't over use this, but use it where it is clear and idiomatic

    ```python
    if (n := len(a)) > 10:  # Assign to `n` and return; avoids redundant `len` call.
        print(f"List is too long ({n} elements, expected <= 10)")

    # Regular expression match objects
    discount = 0.0
    if (mo := re.search(r'(\d+)% discount', advertisement)):
        discount = float(mo.group(1)) / 100.0

    while (block := f.read(256)) != '':
        process(block)

    # List comprehensions with filtering conditions
    [clean_name.title() for name in names
     if (clean_name := normalize('NFC', name)) in allowed_names]
    ```

- Positional-only parameters. Use the function parameter syntax `/` to indicate that some function parameters must be specified positionally and cannot be used as keyword arguments.
    One useful application is that it allows the parameter name to be changed in the future without risk of breaking client code.

    ```python
    # a, b -- positional only
    # c, d -- positional or keyword
    # e, f -- required to be keywords
    def f(a, b, /, c, d, *, e, f):
        print(a, b, c, d, e, f)

    # Valid
    f(10, 20, 30, d=40, e=50, f=60)

    # Invalid
    f(10, b=20, c=30, d=40, e=50, f=60)   # b cannot be a keyword argument
    f(10, 20, 30, 40, 50, f=60)           # e must be a keyword argument
    ```

- `=` in f-strings. An f-string such as f'{expr=}' will expand to the text of the expression, an equal sign, then the representation of the evaluated expression

    ```
    >>> user = 'eric_idle'
    >>> member_since = date(1975, 7, 31)
    >>> f'{user=} {member_since=}'
    "user='eric_idle' member_since=datetime.date(1975, 7, 31)"

    >>> delta = date.today() - member_since
    >>> f'{user=!s}  {delta.days=:,d}'
    'user=eric_idle  delta.days=16,075'

    # left side of `=` will always display the whole expression
    >>> print(f'{theta=}  {cos(radians(theta))=:.3f}')
    "theta=30  cos(radians(theta))=0.866"
    ```

- `dict` merge (`|`) and update (`|=`) operators

- `str.removeprefix(prefix)` and `str.removesuffix(suffix)`

- `zoneinfo` standard library module for getting timezone info from IANA time zone database

    ```python
    from zoneinfo import ZoneInfo
    from datetime import datetime, timedelta

    # Daylight saving time
    dt = datetime(2020, 10, 31, 12, tzinfo=ZoneInfo("America/Los_Angeles"))
    print(dt)
    # 2020-10-31 12:00:00-07:00

    dt.tzname()
    # PDT

    # Standard time
    dt += timedelta(days=7)
    print(dt)
    # 2020-11-07 12:00:00-08:00

    print(dt.tzname())
    # PST
    ```

- `graphlib` standard library module with `graphlib.TopologicalSorter` method

- Structural pattern matching with `match <...>` statement. For more examples, see `pattern-matching.md`.

    ```python
    def http_error(status):
        match status:
            case 400:
                return "Bad request"
            case 404:
                return "Not found"
            case 418:
                return "I'm a teapot"
            # Combine multiple cases with `|`
            case 401 | 403:
                return "Not allowed"
            case _:
                return "Something's wrong with the internet"
    ```

# Logging

Prefer the `logging` module to `print` statements in production code.
Use `print` only in short code snippets, minimal examples (when explaining something to the user), or for debugging.

# Reporting

Prefer structured reporting via classes and rendering methods.
For example:

```python
@dataclass
class BenchmarkResults:
    name: str
    mean_ms: float
    std_ms: float

def render_text_report(list[BenchmarkResults]) -> str:
    lines = [
        "Benchmark Report",
        "=" * 40,
        "",
    ]
    for r in results:
        lines.append(f"{r.name:20s}: {r.mean_ms:.3f} ± {r.std_ms:.3f} ms")
    return "\n".join(lines)

report = render_text_report(results)

with open("report.txt", "w") as f:
    f.write(report)
```

Avoid long sequences of multiple `f.write("...")` statements.

# Type Safety and Data Structures

## Dataclasses for structured data

When defining data structures that hold multiple related fields, prefer `dataclasses` over dictionaries or plain classes:

```python
from dataclasses import dataclass

@dataclass
class Config:
    model_name: str
    learning_rate: float
    batch_size: int = 32  # with sensible defaults
```

**When to use dataclasses:**
- Representing configuration objects
- Return values with multiple related fields
- Domain objects with clear schemas
- Data that gets passed between functions

**When dictionaries are fine:**
- Simple key-value lookups with dynamic keys
- JSON-like data being serialized/deserialized immediately
- Truly heterogeneous collections
- One-off data structures in small scripts

## Type Annotations

Use precise type annotations for function signatures and class attributes, especially in:

- Public APIs and library code
- Functions with non-obvious parameter types
- Code that will be maintained by multiple people

```python
from pathlib import Path

def load_config(path: Path, validate: bool = True) -> Config:
    """Load configuration from file."""
    ...

def process_results(
    data: list[dict[str, float]], 
    threshold: float | None = None
) -> dict[str, list[float]]:
    """Process and group results by category."""
    ...
```

**Don't over-annotate:**
- Skip annotations where types are immediately obvious from context
- Use `# type: ignore` sparingly for legitimate edge cases
- Avoid overly complex generic types that reduce readability

## When to skip this pattern

- Quick exploratory scripts or notebooks
- Prototyping where the data structure is still evolving
- Simple scripts under ~100 lines with obvious data flow
- Performance-critical code where overhead matters (though dataclasses are quite fast)

## Paths

Use `pathlib.Path` objects and their methods when representing and manipulating paths.
Avoid using strings for paths.

When writing functions that work with paths, prefer the strict `argument: Path` annotation.

Be aware that some Python functions may expect strings and be unable to handle `Path` objects.
In these cases, cast the `Path` to a `str` when calling the function:

```python
from pathlib import Path

myfile = Path("~").expanduser() / "data" / "myfile"

def some_function(filename: str):  # NOTE: Expects `str`, not `Path`
    # ...

some_function(str(myfile))  # Convert path to string only for the function call
```
