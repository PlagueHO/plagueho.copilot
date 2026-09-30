#!/usr/bin/env python3
"""Find documentation commits in exact sections of private Azure docs repos.

Parameters:
    --repository: Supported private MicrosoftDocs repository.
    --section: Exact path beneath articles/; may be repeated.
    --since: Last-updated date in YYYY-MM-DD format.

Usage:
    python check-private-azure-docs-commits.py --repository MicrosoftDocs/azure-docs-pr \
        --section articles/app-service --since 2026-01-15
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import date, datetime
from typing import Any
from urllib.parse import quote, urlencode


SUPPORTED_REPOSITORIES = {
    "MicrosoftDocs/azure-ai-docs-pr",
    "MicrosoftDocs/azure-docs-pr",
}
DOCUMENTATION_EXTENSIONS = {".md", ".yml", ".yaml"}
PAGE_SIZE = 100
MAX_COMMIT_FILES = 300


class ApiError(RuntimeError):
    """Raised when GitHub CLI or API access fails."""


def validate_repository(repository: str) -> None:
    if repository not in SUPPORTED_REPOSITORIES:
        raise ValueError(
            f"Unsupported repository {repository!r}; choose one of: "
            + ", ".join(sorted(SUPPORTED_REPOSITORIES))
        )


def validate_section(section: str) -> str:
    if "\\" in section or section.startswith("/") or section.endswith("/"):
        raise ValueError(f"Invalid section path {section!r}")

    parts = section.split("/")
    if (
        len(parts) < 2
        or parts[0] != "articles"
        or any(part in {"", ".", ".."} for part in parts)
        or any(part.strip() != part for part in parts)
    ):
        raise ValueError(
            f"Section must be an exact path beneath articles/: {section!r}"
        )
    return section


def parse_cutoff(value: str) -> date:
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
        raise ValueError(f"Invalid cutoff date {value!r}; expected YYYY-MM-DD")
    try:
        return date.fromisoformat(value)
    except ValueError as error:
        raise ValueError(f"Invalid cutoff date {value!r}; expected YYYY-MM-DD") from error


def api_get(endpoint: str) -> Any:
    try:
        result = subprocess.run(
            ["gh", "api", endpoint],
            check=False,
            capture_output=True,
            text=True,
            timeout=60,
        )
    except FileNotFoundError as error:
        raise ApiError("GitHub CLI 'gh' was not found on PATH.") from error
    except subprocess.TimeoutExpired as error:
        raise ApiError(f"GitHub API request timed out after {error.timeout} seconds.") from error

    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise ApiError(f"GitHub API request failed: {detail}")

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ApiError(f"GitHub CLI returned invalid JSON: {error}") from error


def utc_commit_date(value: str) -> datetime:
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ApiError(f"GitHub returned an invalid commit date: {value!r}") from error


def is_documentation_file(path: str, sections: list[str]) -> bool:
    in_selected_section = any(path.startswith(section + "/") for section in sections)
    extension = "." + path.rsplit(".", maxsplit=1)[-1].lower() if "." in path else ""
    return in_selected_section and extension in DOCUMENTATION_EXTENSIONS


def section_endpoint(repository: str, section: str) -> str:
    return f"repos/{repository}/contents/{quote(section, safe='/')}"


def commits_endpoint(
    repository: str, section: str, cutoff: date, page: int
) -> str:
    query = urlencode(
        {
            "path": section,
            "since": f"{cutoff.isoformat()}T00:00:00Z",
            "per_page": str(PAGE_SIZE),
            "page": str(page),
        }
    )
    return f"repos/{repository}/commits?{query}"


def fetch_section_commits(
    repository: str, section: str, cutoff: date
) -> list[dict[str, Any]]:
    contents = api_get(section_endpoint(repository, section))
    if not isinstance(contents, list):
        raise ApiError(f"GitHub did not return a section directory for {section}.")

    commits: list[dict[str, Any]] = []
    page = 1
    while True:
        result = api_get(commits_endpoint(repository, section, cutoff, page))
        if not isinstance(result, list):
            raise ApiError(f"GitHub returned an invalid commit list for {section}.")
        commits.extend(result)
        if len(result) < PAGE_SIZE:
            return commits
        page += 1


def collect_changes(
    repository: str,
    sections: list[str],
    cutoff: date,
) -> dict[str, Any]:
    validate_repository(repository)
    normalized_sections = sorted({validate_section(section) for section in sections})
    if not normalized_sections:
        raise ValueError("Provide at least one --section path.")

    commits_by_sha: dict[str, dict[str, Any]] = {}
    for section in normalized_sections:
        for commit in fetch_section_commits(repository, section, cutoff):
            sha = commit.get("sha")
            metadata = commit.get("commit", {})
            committer = metadata.get("committer") or {}
            commit_date_value = committer.get("date")
            if not isinstance(sha, str) or not isinstance(commit_date_value, str):
                raise ApiError("GitHub returned a commit without its SHA or committer date.")
            if utc_commit_date(commit_date_value).date() <= cutoff:
                continue
            message = metadata.get("message", "")
            commits_by_sha.setdefault(
                sha,
                {
                    "sha": sha,
                    "date": commit_date_value,
                    "subject": message.splitlines()[0] if message else "",
                },
            )

    results = []
    for sha, metadata in commits_by_sha.items():
        details = api_get(f"repos/{repository}/commits/{quote(sha, safe='')}")
        if not isinstance(details, dict):
            raise ApiError(f"GitHub returned an invalid detail response for commit {sha}.")
        files = details.get("files")
        if not isinstance(files, list):
            raise ApiError(f"GitHub returned no changed-file list for commit {sha}.")
        if len(files) >= MAX_COMMIT_FILES:
            raise ApiError(
                f"Commit {sha} has {MAX_COMMIT_FILES} or more changed files; "
                "GitHub may have truncated the file list, so the section filter "
                "cannot be verified safely."
            )

        relevant_files = []
        for changed_file in files:
            path = changed_file.get("filename")
            if not isinstance(path, str) or not is_documentation_file(
                path, normalized_sections
            ):
                continue
            relevant_files.append(
                {
                    "path": path,
                    "status": changed_file.get("status", ""),
                    "additions": changed_file.get("additions", 0),
                    "deletions": changed_file.get("deletions", 0),
                }
            )
        if relevant_files:
            results.append(
                {
                    **metadata,
                    "files": sorted(relevant_files, key=lambda item: item["path"]),
                }
            )

    results.sort(key=lambda item: (item["date"], item["sha"]), reverse=True)
    return {
        "repository": repository,
        "sections": normalized_sections,
        "since": cutoff.isoformat(),
        "commits": results,
    }


def parse_args(arguments: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repository",
        required=True,
        choices=sorted(SUPPORTED_REPOSITORIES),
        help="Private MicrosoftDocs repository to query.",
    )
    parser.add_argument(
        "--section",
        required=True,
        action="append",
        help="Exact product section path beneath articles/; repeat for multiple sections.",
    )
    parser.add_argument(
        "--since",
        required=True,
        help="Target document last-updated date in YYYY-MM-DD format.",
    )
    return parser.parse_args(arguments)


def main(arguments: list[str] | None = None) -> int:
    try:
        args = parse_args(arguments)
        report = collect_changes(
            args.repository,
            args.section,
            parse_cutoff(args.since),
        )
    except (ApiError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 2

    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
