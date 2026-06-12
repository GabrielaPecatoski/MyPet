"""Remove comentarios de arquivos TS/JS/Dart sem tocar em strings/regex.

Uso: python scripts/strip_comments.py <arquivo> [<arquivo> ...]
A linguagem e inferida pela extensao. Pragmas funcionais sao preservados
(// ignore: / // ignore_for_file: no Dart; @ts-ignore/@ts-expect-error/
biome-ignore no TS, se existirem).
"""

import re
import sys

DART_PRAGMA = re.compile(r"^//\s*ignore(_for_file)?:")
TS_PRAGMA = re.compile(r"@ts-ignore|@ts-expect-error|biome-ignore|^///\s*<reference")

REGEX_PRECEDERS = set("(,=:[!&|?{};+-*%~^<>")
REGEX_PREV_WORDS = {
    "return", "typeof", "case", "in", "of", "new", "delete", "void",
    "instanceof", "do", "else", "yield", "await",
}


def prev_significant(out: list[str]) -> tuple[str, str]:
    """Ultimo char nao-espaco do output e a ultima palavra (para regex vs divisao)."""
    i = len(out) - 1
    while i >= 0 and out[i] in " \t\r\n":
        i -= 1
    if i < 0:
        return "", ""
    ch = out[i]
    j = i
    while j >= 0 and (out[j].isalnum() or out[j] == "_"):
        j -= 1
    word = "".join(out[j + 1 : i + 1])
    return ch, word


def strip_ts(src: str) -> str:
    out: list[str] = []
    i, n = 0, len(src)
    # pilha de contextos para template literals: 'tpl' dentro de `...`, 'code' dentro de ${}
    tpl_stack: list[int] = []  # contagem de chaves abertas dentro de ${}

    def line_comment_end(k: int) -> int:
        while k < n and src[k] not in "\r\n":
            k += 1
        return k

    state = "code"
    while i < n:
        c = src[i]
        if state == "code":
            if c == "/" and i + 1 < n and src[i + 1] == "/":
                end = line_comment_end(i)
                text = src[i:end]
                if TS_PRAGMA.search(text):
                    out.append(text)
                i = end
                continue
            if c == "/" and i + 1 < n and src[i + 1] == "*":
                j = src.find("*/", i + 2)
                j = n if j == -1 else j + 2
                # preserva quebras de linha do bloco para o pos-processamento
                out.extend(ch for ch in src[i:j] if ch in "\r\n")
                i = j
                continue
            if c == "/":
                ch, word = prev_significant(out)
                if ch == "" or ch in REGEX_PRECEDERS or word in REGEX_PREV_WORDS:
                    # literal de regex: consome ate a / final (respeitando [...] e escapes)
                    out.append(c)
                    i += 1
                    in_class = False
                    while i < n:
                        rc = src[i]
                        out.append(rc)
                        i += 1
                        if rc == "\\" and i < n:
                            out.append(src[i])
                            i += 1
                        elif rc == "[":
                            in_class = True
                        elif rc == "]":
                            in_class = False
                        elif rc == "/" and not in_class:
                            break
                    while i < n and (src[i].isalpha()):
                        out.append(src[i])
                        i += 1
                    continue
                out.append(c)
                i += 1
                continue
            if c in "'\"":
                state = c
                out.append(c)
                i += 1
                continue
            if c == "`":
                state = "tpl"
                out.append(c)
                i += 1
                continue
            if c == "}" and tpl_stack:
                if tpl_stack[-1] == 0:
                    tpl_stack.pop()
                    state = "tpl"
                else:
                    tpl_stack[-1] -= 1
                out.append(c)
                i += 1
                continue
            if c == "{" and tpl_stack:
                tpl_stack[-1] += 1
                out.append(c)
                i += 1
                continue
            out.append(c)
            i += 1
        elif state in ("'", '"'):
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(src[i + 1])
                i += 2
                continue
            if c == state or c in "\r\n":
                state = "code"
            i += 1
        elif state == "tpl":
            if c == "\\" and i + 1 < n:
                out.append(c)
                out.append(src[i + 1])
                i += 2
                continue
            if c == "$" and i + 1 < n and src[i + 1] == "{":
                out.append("${")
                tpl_stack.append(0)
                state = "code"
                i += 2
                continue
            out.append(c)
            if c == "`":
                state = "code"
            i += 1
    return "".join(out)


def strip_dart(src: str) -> str:
    out: list[str] = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            end = i
            while end < n and src[end] not in "\r\n":
                end += 1
            text = src[i:end]
            if DART_PRAGMA.match(text):
                out.append(text)
            i = end
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            depth = 1
            j = i + 2
            while j < n and depth > 0:
                if src.startswith("/*", j):
                    depth += 1
                    j += 2
                elif src.startswith("*/", j):
                    depth -= 1
                    j += 2
                else:
                    if src[j] in "\r\n":
                        out.append(src[j])
                    j += 1
            i = j
            continue
        if c in "'\"":
            raw = bool(out) and out[-1] == "r"
            triple = src.startswith(c * 3, i)
            quote = c * 3 if triple else c
            out.append(src[i : i + len(quote)])
            i += len(quote)
            while i < n:
                if not raw and src[i] == "\\" and i + 1 < n:
                    out.append(src[i : i + 2])
                    i += 2
                    continue
                if src.startswith(quote, i):
                    out.append(quote)
                    i += len(quote)
                    break
                if not triple and src[i] in "\r\n":
                    break
                out.append(src[i])
                i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def postprocess(original: str, stripped: str) -> str:
    """Apaga linhas que viraram so-espaco (eram comentario inteiro)."""
    orig_lines = original.splitlines(keepends=True)
    new_lines = stripped.splitlines(keepends=True)
    result = []
    for k, line in enumerate(new_lines):
        body = line.rstrip("\r\n")
        had_content = k < len(orig_lines) and orig_lines[k].strip() != ""
        if body.strip() == "" and had_content:
            continue
        result.append(line.rstrip() + line[len(line.rstrip()):].replace(" ", "").replace("\t", ""))
    return "".join(result)


def main() -> None:
    changed = 0
    for path in sys.argv[1:]:
        with open(path, encoding="utf-8", newline="") as f:
            src = f.read()
        if path.endswith(".dart"):
            stripped = strip_dart(src)
        else:
            stripped = strip_ts(src)
        result = postprocess(src, stripped)
        if result != src:
            with open(path, "w", encoding="utf-8", newline="") as f:
                f.write(result)
            changed += 1
    print(f"{changed} arquivo(s) alterado(s) de {len(sys.argv) - 1}")


if __name__ == "__main__":
    main()
