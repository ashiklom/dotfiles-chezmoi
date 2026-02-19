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

In standalone scripts, use `library(package, include.only = c("function1", "function2"))` at the top of the file.
The `include.only` argument to `library` is available to in R >= 3.6.0 (2019).

In files that define functions (including in R packages and for `targets` projects), use `package::function` and specify dependencies elsewhere (e.g., in a `DESCRIPTION` file for packages; in the `_targets.R` file for `targets` pipelines).

Use `requireNamespace(package)` only with an `if` statement to define alternate behavior if a package is absent; for example:

```r
if (!requireNamespace("ggplot")) {
  warning("ggplot is not installed. falling back to base R plotting.")
}
```

# Early Returns

Prefer early returns over nested if/else structures. Early returns reduce nesting depth, make error conditions explicit upfront, and keep the main logic (the "happy path") unindented and easier to follow. This pattern helps agents reason about control flow more clearly.

## Basic validation

```r
# ❌ Nested condition obscures main logic
if (file.exists(fname)) {
  process_file(fname)
} else {
  return(NA_real_)
}

# ✅ Guard clause makes intent clear; main logic follows naturally
if (!file.exists(fname)) {
  return(NA_real_)
}
process_file(fname)
```

## Multiple guard clauses

```r
# ❌ Deep nesting makes code hard to follow
process_data <- function(data, threshold) {
  if (length(data) > 0) {
    if (!any(is.na(data))) {
      if (!is.null(threshold)) {
        return(data[data > threshold])
      } else {
        return(data)
      }
    } else {
      stop("Data contains NA values")
    }
  } else {
    return(numeric(0))
  }
}

# ✅ Stack guard clauses at the top; happy path is clear and unindented
process_data <- function(data, threshold) {
  if (length(data) == 0) {
    return(numeric(0))
  }
  if (any(is.na(data))) {
    stop("Data contains NA values")
  }
  if (is.null(threshold)) {
    return(data)
  }
  
  data[data > threshold]  # Main logic is clear and prominent
}
```

## Type and value checking

```r
# ❌ Nested structure for simple validation
calculate_metric <- function(x) {
  if (is.numeric(x)) {
    if (length(x) >= 3) {
      mean(x) / sd(x)
    } else {
      NA_real_
    }
  } else {
    stop("x must be numeric")
  }
}

# ✅ Validation guards upfront; calculation stands alone
calculate_metric <- function(x) {
  if (!is.numeric(x)) {
    stop("x must be numeric")
  }
  if (length(x) < 3) {
    return(NA_real_)
  }
  
  mean(x) / sd(x)
}
```

## Early returns in data processing

```r
# ❌ Unnecessary else after conditional processing
summarize_results <- function(results) {
  if (nrow(results) == 0) {
    message("No results to summarize")
    return(tibble())
  } else {
    results |>
      group_by(category) |>
      summarize(mean_value = mean(value), .groups = "drop")
  }
}

# ✅ Handle empty case early; main logic has no unnecessary else
summarize_results <- function(results) {
  if (nrow(results) == 0) {
    message("No results to summarize")
    return(tibble())
  }
  
  results |>
    group_by(category) |>
    summarize(mean_value = mean(value), .groups = "drop")
}
