## lint.sh

Static checks for shell scripts

## Synopsis

- `lint.sh [--staged] [--fix] [--strict]`
	- `--staged`	Check only files staged for commit
	- `--fix`		Automatically fix trailing whitespace and missing EOF newlines
	- `--strict`	Treat shellcheck findings as failures

Dictionary:

- Failures:		Bash syntax errors, whitespace issues (always blocked).
- Advisories:	Shellcheck findings (blocked only with --strict).

## Exit Codes

- `0`:	All checks passed
- `1`:	Usage error
- `2`:	Failure(s) found
