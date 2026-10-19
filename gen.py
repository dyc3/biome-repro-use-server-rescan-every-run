"""Generates FILES TypeScript modules under src/. Each module imports its two
neighbours, so the module graph has edges, and has enough code that its syntax
tree takes a noticeable amount of memory."""
import os
import sys

FILES = int(sys.argv[1]) if len(sys.argv) > 1 else 400
FUNCTIONS = 40

os.makedirs("src", exist_ok=True)
for i in range(FILES):
    lines = [
        f'import {{ value{(i + 1) % FILES} }} from "./module{(i + 1) % FILES}";',
        f'import {{ value{(i + 2) % FILES} }} from "./module{(i + 2) % FILES}";',
        "",
        f"export const value{i} = {i};",
        "",
    ]
    for f in range(FUNCTIONS):
        lines += [
            f"export function compute{i}x{f}(items: number[], factor: number): number {{",
            "\tlet total = 0;",
            "\tfor (const item of items) {",
            "\t\tif (item > factor) {",
            f"\t\t\ttotal += item * factor + value{(i + 1) % FILES};",
            "\t\t} else {",
            f"\t\t\ttotal -= item - value{(i + 2) % FILES};",
            "\t\t}",
            "\t}",
            "\treturn total;",
            "}",
            "",
        ]
    with open(f"src/module{i}.ts", "w") as out:
        out.write("\n".join(lines))
