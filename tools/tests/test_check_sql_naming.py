from pathlib import Path

from check_sql_naming import check_file, main


def write_sql(tmp_path: Path, content: str) -> str:
    path = tmp_path / "migration.sql"
    path.write_text(content, encoding="utf-8")
    return str(path)


def test_correct_prefixes_produce_no_errors(tmp_path: Path) -> None:
    sql = """
    CREATE TABLE klienci (
        id INT IDENTITY,
        nazwa NVARCHAR(200) NOT NULL,
        CONSTRAINT PK_klienci PRIMARY KEY (id),
        CONSTRAINT UQ_klienci_nazwa UNIQUE (nazwa),
        CONSTRAINT CK_klienci_nazwa CHECK (nazwa <> ''),
        CONSTRAINT FK_klienci_region FOREIGN KEY (region_id) REFERENCES regiony(id),
        CONSTRAINT DF_klienci_status DEFAULT ('nowy') FOR status
    );
    """
    assert check_file(write_sql(tmp_path, sql)) == []


def test_wrong_prefix_is_reported(tmp_path: Path) -> None:
    sql = "CREATE TABLE x (id INT, CONSTRAINT zle_imie PRIMARY KEY (id));"
    errors = check_file(write_sql(tmp_path, sql))
    assert len(errors) == 1
    assert "zle_imie" in errors[0]
    assert "PK_" in errors[0]


def test_error_message_includes_correct_line_number(tmp_path: Path) -> None:
    sql = "-- comment\n-- comment\nCONSTRAINT bad_fk FOREIGN KEY (x) REFERENCES y(id)"
    [error] = check_file(write_sql(tmp_path, sql))
    assert ":3:" in error


def test_matching_is_case_insensitive(tmp_path: Path) -> None:
    sql = "constraint pk_ok primary key (id)"
    assert check_file(write_sql(tmp_path, sql)) == []

    sql_bad = "constraint zle primary key (id)"
    assert len(check_file(write_sql(tmp_path, sql_bad))) == 1


def test_multiple_constraints_report_each_violation(tmp_path: Path) -> None:
    sql = """
    CONSTRAINT zle1 PRIMARY KEY (id),
    CONSTRAINT zle2 UNIQUE (nazwa)
    """
    errors = check_file(write_sql(tmp_path, sql))
    assert len(errors) == 2


def test_main_returns_zero_when_no_errors(tmp_path: Path) -> None:
    path = write_sql(tmp_path, "CONSTRAINT PK_ok PRIMARY KEY (id)")
    assert main([path]) == 0


def test_main_returns_one_and_prints_when_errors(tmp_path: Path, capsys) -> None:
    path = write_sql(tmp_path, "CONSTRAINT zle PRIMARY KEY (id)")
    assert main([path]) == 1
    assert "zle" in capsys.readouterr().out


def test_main_ignores_non_sql_files(tmp_path: Path) -> None:
    path = tmp_path / "notes.md"
    path.write_text("CONSTRAINT zle PRIMARY KEY (id)", encoding="utf-8")
    assert main([str(path)]) == 0
