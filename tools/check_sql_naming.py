import re
import sys

PREFIX_BY_KIND: dict[str, str] = {
    "PRIMARY KEY": "PK_",
    "FOREIGN KEY": "FK_",
    "CHECK": "CK_",
    "UNIQUE": "UQ_",
    "DEFAULT": "DF_",
}

CONSTRAINT_RE = re.compile(
    r"CONSTRAINT\s+(?P<name>\w+)\s+(?P<kind>PRIMARY KEY|FOREIGN KEY|CHECK|UNIQUE|DEFAULT)",
    re.IGNORECASE,
)


def check_file(path: str) -> list[str]:
    text = open(path, encoding="utf-8").read()
    errors = []
    for match in CONSTRAINT_RE.finditer(text):
        name = match.group("name")
        kind = match.group("kind").upper()
        expected_prefix = PREFIX_BY_KIND[kind]
        if not name.upper().startswith(expected_prefix):
            line_no = text.count("\n", 0, match.start()) + 1
            errors.append(
                f"{path}:{line_no}: '{name}' ({kind}) powinno zaczynać się od '{expected_prefix}'"
            )
    return errors


def main(paths: list[str]) -> int:
    all_errors = [err for path in paths if path.endswith(".sql") for err in check_file(path)]
    if all_errors:
        print("\n".join(all_errors))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
