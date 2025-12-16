import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional


@dataclass
class CMakeCallable:
    kind: str  # "function" or "macro"
    name: str
    args: List[str]
    doc_md: str
    line: int
    start_index: int
    end_index: int
    arg_specs: List["CMakeParseArgumentsSpec"]


@dataclass
class CMakeParseArgumentsSpec:
    prefix: str
    options: List[str]
    one_value_args: List[str]
    multi_value_args: List[str]
    required_options: List[str]
    required_one_value_args: List[str]
    required_multi_value_args: List[str]


class CMakeParser:
    def __init__(self, input_path: Path):
        self.input_path = input_path
        self._verify_libs()

    def _verify_libs(self):
        try:
            global parse_raw, Command, Comment
            from cmake_parser.parser import parse_raw
            from cmake_parser.ast import Command, Comment
        except ImportError:
            print("❌ Error: 'cmake-parser' not found. Run: uv sync", file=sys.stderr)
            sys.exit(1)

    def parse(self) -> List[CMakeCallable]:
        print(f"📖 Reading {self.input_path}...")
        try:
            content = self.input_path.read_text(encoding="utf-8")
        except FileNotFoundError:
            print(f"❌ Error: File not found: {self.input_path}", file=sys.stderr)
            sys.exit(1)

        ast_nodes = list(parse_raw(content))
        callables: list[CMakeCallable] = []

        # Track nested function/macro blocks so we can analyze bodies.
        stack: list[tuple[str, int, int]] = []
        # (kind, start_index, callable_index)

        for i, node in enumerate(ast_nodes):
            if not isinstance(node, Command):
                continue

            ident = node.identifier.lower()

            if ident in {"function", "macro"}:
                if not node.args:
                    continue

                kind = ident
                name = node.args[0].value
                args = [tok.value for tok in node.args[1:]]
                doc_md = self._extract_doc_block(ast_nodes, i)

                callable_index = len(callables)
                callables.append(
                    CMakeCallable(
                        kind=kind,
                        name=name,
                        args=args,
                        doc_md=doc_md,
                        line=int(getattr(node, "line", 1) or 1),
                        start_index=i,
                        end_index=len(ast_nodes) - 1,
                        arg_specs=[],
                    )
                )

                stack.append((kind, i, callable_index))
                continue

            if ident in {"endfunction", "endmacro"}:
                end_kind = "function" if ident == "endfunction" else "macro"

                # Pop until we find a matching opening (be tolerant of malformed files).
                while stack:
                    open_kind, open_idx, callable_index = stack.pop()
                    if open_kind == end_kind:
                        callables[callable_index].end_index = i
                        break
                continue

        # Analyze each callable body for cmake_parse_arguments usage.
        for c in callables:
            c.arg_specs = self._extract_cmake_parse_arguments_specs(
                ast_nodes, c.start_index, c.end_index
            )

        return callables

    def _extract_doc_block(self, nodes: list, current_index: int) -> str:
        doc_lines: list[str] = []
        prev_index = current_index - 1

        while prev_index >= 0:
            prev_node = nodes[prev_index]
            if isinstance(prev_node, Comment):
                line = (prev_node.comment or "").rstrip("\n")
                line = line.lstrip("#").rstrip()
                if line.startswith(" "):
                    line = line[1:]
                doc_lines.insert(0, line)
            else:
                break
            prev_index -= 1

        # Trim leading/trailing empties
        while doc_lines and not doc_lines[0].strip():
            doc_lines.pop(0)
        while doc_lines and not doc_lines[-1].strip():
            doc_lines.pop()

        return "\n".join(doc_lines).rstrip()

    def _extract_cmake_parse_arguments_specs(
        self,
        nodes: list,
        start_index: int,
        end_index: int,
    ) -> List[CMakeParseArgumentsSpec]:
        def _strip_quotes(v: str) -> str:
            if len(v) >= 2 and ((v[0] == v[-1] == '"') or (v[0] == v[-1] == "'")):
                return v[1:-1]
            return v

        def unwrap_var(v: str) -> Optional[str]:
            v = _strip_quotes(v.strip())
            m = re.match(r"^\$\{([^}]+)\}$", v)
            return m.group(1) if m else None

        def resolve_list(token: str, set_values: dict[str, List[str]]) -> List[str]:
            token = _strip_quotes(token.strip())
            if not token or token == '""' or token == "''":
                return []

            var = unwrap_var(token)
            if var is not None:
                return set_values.get(var, [])

            # Literal CMake list tokens. If the list was passed as "A;B" split on ';'.
            parts = [p for p in token.split(";") if p]
            return parts

        # Track simple `set(var <values...>)` assignments in this scope.
        set_values: dict[str, List[str]] = {}
        specs: list[CMakeParseArgumentsSpec] = []

        # Heuristic for "required" keyword arguments: if the function body calls
        # *_check_var_defined(<prefix>_<KEY>), treat KEY as required.
        required_vars: set[str] = set()

        for node in nodes[start_index + 1 : end_index]:
            if not isinstance(node, Command):
                continue

            ident = node.identifier
            ident_lower = ident.lower()
            if ident_lower.endswith("check_var_defined") and node.args:
                required_vars.add(node.args[0].value)
                continue

            if ident == "set" and node.args:
                var_name = node.args[0].value
                values = [tok.value for tok in node.args[1:]]
                set_values[var_name] = values
                continue

            if ident == "cmake_parse_arguments" and len(node.args) >= 4:
                prefix = _strip_quotes(node.args[0].value.strip())
                options_ref = node.args[1].value
                one_ref = node.args[2].value
                multi_ref = node.args[3].value

                options = resolve_list(options_ref, set_values)
                one_value_args = resolve_list(one_ref, set_values)
                multi_value_args = resolve_list(multi_ref, set_values)

                required_options = [
                    k for k in options if f"{prefix}_{k}" in required_vars
                ]
                required_one_value_args = [
                    k for k in one_value_args if f"{prefix}_{k}" in required_vars
                ]
                required_multi_value_args = [
                    k for k in multi_value_args if f"{prefix}_{k}" in required_vars
                ]

                specs.append(
                    CMakeParseArgumentsSpec(
                        prefix=prefix,
                        options=options,
                        one_value_args=one_value_args,
                        multi_value_args=multi_value_args,
                        required_options=required_options,
                        required_one_value_args=required_one_value_args,
                        required_multi_value_args=required_multi_value_args,
                    )
                )

        return specs


def _slugify(s: str) -> str:
    s = s.strip().lower()
    s = s.replace("_", "-")
    s = re.sub(r"[^a-z0-9\-\s]", "", s)
    s = re.sub(r"\s+", "-", s)
    s = re.sub(r"-+", "-", s)
    return s.strip("-") or "section"


def _placeholder(name: str) -> str:
    # CMake docs typically use <arg> placeholders.
    name = name.strip()
    if not name:
        return "<>"

    # Common CMake convention: visibility is one of these keywords.
    if name.lower() == "visibility":
        return "<PRIVATE|PUBLIC|INTERFACE>"

    if name.startswith("<") and name.endswith(">"):
        return name
    return f"<{name}>"


def _call_synopsis_lines(c: CMakeCallable) -> list[str]:
    """Return a CMake-docs-style call synopsis for a callable.

    Example:
        my_func(<a> <b>
          [FLAG]
          KEY <value>
          [LIST <item>...]
        )
    """

    # Positional arguments from the definition: show as <arg> placeholders.
    positional = [_placeholder(a) for a in c.args]

    # Merge keyword args across all cmake_parse_arguments() specs.
    opt_required: set[str] = set()
    one_required: set[str] = set()
    multi_required: set[str] = set()

    options: set[str] = set()
    one_values: set[str] = set()
    multi_values: set[str] = set()
    for spec in c.arg_specs:
        options.update(spec.options)
        one_values.update(spec.one_value_args)
        multi_values.update(spec.multi_value_args)
        opt_required.update(spec.required_options)
        one_required.update(spec.required_one_value_args)
        multi_required.update(spec.required_multi_value_args)

    keyword_lines: list[str] = []
    for opt in sorted(options):
        # Options are almost always optional; keep bracketed for consistency.
        keyword_lines.append(f"[{opt}]")
    for key in sorted(one_values):
        core = f"{key} <value>"
        keyword_lines.append(core if key in one_required else f"[{core}]")
    for key in sorted(multi_values):
        core = f"{key} <item>..."
        keyword_lines.append(core if key in multi_required else f"[{core}]")

    if not positional and not keyword_lines:
        return [f"{c.name}()"]

    # Single-line synopsis when there are only positional args.
    if positional and not keyword_lines:
        return [f"{c.name}({' '.join(positional)})"]

    # Multi-line synopsis for readability with keyword args.
    lines: list[str] = []
    first_line = f"{c.name}(" + (" ".join(positional) if positional else "")
    lines.append(first_line.rstrip())
    for item in keyword_lines:
        lines.append(f"  {item}")
    lines.append(")")
    return lines


def render_markdown(
    project_title: str, input_file: Path, callables: Iterable[CMakeCallable]
) -> str:
    # Hide internal helpers from the generated docs.
    # Convention: names starting with '_' are not part of the public API.
    callables = [c for c in callables if not c.name.startswith("_")]

    slug_counts: dict[str, int] = {}

    def unique_slug(name: str) -> str:
        base = _slugify(name)
        n = slug_counts.get(base, 0) + 1
        slug_counts[base] = n
        return base if n == 1 else f"{base}-{n}"

    entries: list[tuple[CMakeCallable, str]] = [
        (c, unique_slug(c.name)) for c in callables
    ]

    lines: list[str] = []
    lines.append(f"# {project_title}")
    lines.append("")
    lines.append(f"Generated from `{input_file.name}`.")
    lines.append("")

    if entries:
        lines.append("## Index")
        lines.append("")
        for c, slug in entries:
            loc = f"[{input_file.name}#L{c.line}]({input_file.name}#L{c.line})"
            lines.append(f"- [{c.name}](#{slug}) — `{c.kind}` — {loc}")
        lines.append("")

    for c, slug in entries:
        lines.append(f'<a id="{slug}"></a>')
        lines.append(f"# {c.name}")
        lines.append("")
        lines.append("```cpp")  # Using cpp for a better syntax highlight in GitHub
        lines.extend(_call_synopsis_lines(c))
        lines.append("```")
        lines.append("")
        lines.append(f"**Type**: `{c.kind}`")
        lines.append("")

        # Standardized parameter listing (Sphinx-style) so each arg can be reviewed/commented.
        lines.append("### Parameters")
        lines.append("")
        if c.args:
            for p in c.args:
                lines.append(f"- `{p}`: _Describe this parameter._")
        else:
            lines.append("- _none_")
        lines.append("")

        if c.arg_specs:
            lines.append("### Keyword arguments")
            lines.append("")
            for spec in c.arg_specs:
                lines.append(f"Parsed from `cmake_parse_arguments({spec.prefix} ...)`:")
                lines.append("")
                for opt in spec.options:
                    lines.append(f"- `{opt}` (option): _Describe this keyword._")
                for one in spec.one_value_args:
                    lines.append(f"- `{one}` (one-value): _Describe this keyword._")
                for multi in spec.multi_value_args:
                    lines.append(f"- `{multi}` (multi-value): _Describe this keyword._")

                if not (spec.options or spec.one_value_args or spec.multi_value_args):
                    lines.append("- _none_")

                lines.append("")

        if c.doc_md.strip():
            lines.append(c.doc_md.rstrip())
        else:
            lines.append("_No documentation available._")
        lines.append("")

    if not entries:
        lines.append("> No functions or macros found.")
        lines.append("")

    return "\n".join(lines)


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Generate Markdown docs from CMake functions/macros (GitHub-friendly)."
    )
    ap.add_argument("input", nargs="?", default="utils.cmake", help="Input CMake file")
    ap.add_argument("-o", "--output", default="docs.md", help="Output Markdown file")
    ap.add_argument(
        "-t", "--title", default="CMake Documentation", help="Document title"
    )

    args = ap.parse_args()

    input_file = Path(args.input)
    output_file = Path(args.output)

    parser = CMakeParser(input_file)
    callables = parser.parse()

    if not callables:
        print("⚠️  Warning: No functions/macros found in the file.")

    md = render_markdown(args.title, input_file, callables)
    output_file.write_text(md, encoding="utf-8")
    print(f"✅ Success! Output saved to: {output_file}")


if __name__ == "__main__":
    main()
