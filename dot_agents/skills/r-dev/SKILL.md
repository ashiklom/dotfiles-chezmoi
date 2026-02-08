---
name: r-dev
description: Use this skill whenever writing, debugging, or reviewing R code. Triggers include any R script creation, statistical analysis code, data visualization with ggplot2, tidyverse workflows, package development, Rmarkdown/Quarto documents, or when the user mentions .R/.Rmd files or R-specific packages. Apply these patterns for code style, data manipulation preferences, and project structure.
---

# Formatting

If `air` is installed, use `air format <script.R>` to format scripts or `air format <directory>` to format all R code in `<directory>`.

# When to use tidyverse vs base R

For new scripts, prefer tidyverse when:
- Working with data frames/tibbles
- Performing multi-step data transformations
- Creating visualizations

Use base R for:
- Simple vector operations
- Performance-critical code
- Minimal-dependency contexts (e.g., package internals)

# Tidyverse 

If you are already using `tidyverse` packages (e.g., `dplyr`, `tidyr`, `tibble`, `purrr`, `ggplot`, `rlang`), avoid base R approaches that have `tidyverse` equivalents.
If you've loaded `dplyr`, consistently use `tibble::tibble` instead of `data.frame`.
If `purrr` is already installed, use `purrr::map` and other `purrr` functions instead of `lapply`, `vapply`, etc.

For grouped operations, prefer the `.by` argument; e.g. `summarize(..., .by = c(column1, column2))`, not `group_by(c(column1, column2) |> summarize(...)`.

# Pipes

Prefer the native pipe `|>` over magrittr's `%>%` in new code.
Use `%>%` only when you need magrittr-specific features (e.g., `.` placeholder in complex positions).

# Reporting

For informational/status messages, prefer `message`.
Use `print` only for displaying objects, and mostly in debugging contexts.
Use `cat` only for specific low-level output formatting (e.g., when defining `print` methods for new objects).

# Loading packages 

In standalone scripts, use `library(package, include.only = c("function1", "function2")` at the top of the file.
The `include.only` argument to `library` is available to in R >= 3.6.0 (2019).

In files that define functions (including in R packages and for `targets` projects), use `package::function` and specify dependencies elsewhere (e.g., in a `DESCRIPTION` file for packages; in the `_targets.R` file for `targets` pipelines).

Use `requireNamespace(package)` only with an `if` statement to define alternate behavior if a package is absent; for example:

```r
if (!requireNamespace("ggplot")) {
  warning("ggplot is not installed. falling back to base R plotting.")
}
```
