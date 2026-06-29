# Antigravity Custom Style Rules

## LaTeX Math Formatting Restriction
To ensure all generated text and documents are easily readable by human engineers, the following guidelines are mandatory:
*   **No LaTeX math delimiters**: Never use single `$` or double `$$` delimiters for mathematical variables, values, or expressions in responses or documentation.
*   **No LaTeX formatting commands**: Do not use commands like `\text{...}`, `\frac{...}{...}`, `\approx`, `\cdot`, `\times`, `^\circ`, or `^2`.
*   **Use Plain Text and Standard Symbols**: Use standard plain text representation for math and units:
    *   Use `mm` or `meters` instead of `\text{mm}` or `\text{m}`.
    *   Use `~` or `approx` instead of `\approx`.
    *   Use `*` or `x` instead of `\cdot` or `\times`.
    *   Use `(A) / (B)` or `A / B` instead of `\frac{A}{B}`.
    *   Use `°` instead of `^\circ`.
    *   Use plain subscripts like `x_abc` instead of `x_{abc}`.
