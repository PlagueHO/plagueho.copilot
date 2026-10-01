"""Tests for path-scoped Azure documentation commit selection."""

from __future__ import annotations

import importlib.util
import unittest
from datetime import date
from pathlib import Path
from unittest.mock import patch
from urllib.parse import parse_qs, urlparse


SCRIPT_PATH = (
    Path(__file__).resolve().parents[2]
    / "skills"
    / "discover-multitenant-service-updates"
    / "scripts"
    / "check-private-azure-docs-commits.py"
)
SPEC = importlib.util.spec_from_file_location("private_azure_docs_commits", SCRIPT_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class CommitDiscoveryTests(unittest.TestCase):
    def commit_summary(self, sha: str, when: str, message: str = "Update docs"):
        return {
            "sha": sha,
            "commit": {
                "committer": {"date": when},
                "message": message,
            },
        }

    def changed_file(
        self,
        path: str,
        *,
        status: str = "modified",
        additions: int = 1,
        deletions: int = 0,
    ):
        return {
            "filename": path,
            "status": status,
            "additions": additions,
            "deletions": deletions,
        }

    def test_rejects_paths_outside_articles(self):
        with self.assertRaises(ValueError):
            MODULE.validate_section("articles/../private")
        with self.assertRaises(ValueError):
            MODULE.validate_section("other/app-service")

    def test_rejects_unsupported_repository(self):
        with self.assertRaises(ValueError):
            MODULE.validate_repository("someone/other-repo")

    def test_requires_iso_date_cutoff(self):
        with self.assertRaisesRegex(ValueError, "YYYY-MM-DD"):
            MODULE.parse_cutoff("20260115")

    def test_only_accepts_markdown_and_toc_yaml_files(self):
        sections = ["articles/app-service"]

        self.assertTrue(
            MODULE.is_documentation_file(
                "articles/app-service/new-feature.md",
                sections,
            )
        )
        self.assertTrue(
            MODULE.is_documentation_file(
                "articles/app-service/TOC.yaml",
                sections,
            )
        )
        self.assertFalse(
            MODULE.is_documentation_file(
                "articles/app-service/app-service.yml",
                sections,
            )
        )

    def test_paginates_section_history(self):
        endpoints = []

        def fake_api(endpoint):
            endpoints.append(endpoint)
            if "/contents/" in endpoint:
                return []
            page = parse_qs(urlparse(endpoint).query)["page"][0]
            if page == "1":
                return [{"sha": str(index)} for index in range(MODULE.PAGE_SIZE)]
            return []

        with patch.object(MODULE, "api_get", side_effect=fake_api):
            commits = MODULE.fetch_section_commits(
                "MicrosoftDocs/azure-docs-pr",
                "articles/app-service",
                date(2026, 1, 15),
            )

        self.assertEqual(len(commits), MODULE.PAGE_SIZE)
        history_pages = [
            parse_qs(urlparse(endpoint).query)["page"][0]
            for endpoint in endpoints
            if "/commits?" in endpoint
        ]
        self.assertEqual(history_pages, ["1", "2"])

    def test_filters_by_cutoff_and_exact_section_files(self):
        newer_sha = "a" * 40
        same_day_sha = "b" * 40
        calls = []

        def fake_api(endpoint):
            calls.append(endpoint)
            if "/contents/" in endpoint:
                return []
            if "/commits?" in endpoint:
                query = parse_qs(urlparse(endpoint).query)
                self.assertEqual(query["path"], ["articles/app-service"])
                self.assertEqual(query["since"], ["2026-01-15T00:00:00Z"])
                self.assertEqual(query["page"], ["1"])
                return [
                    self.commit_summary(
                        newer_sha,
                        "2026-01-16T10:00:00Z",
                        "Add App Service capability\n\nMore details",
                    ),
                    self.commit_summary(
                        same_day_sha,
                        "2026-01-15T21:00:00Z",
                        "Update App Service docs",
                    ),
                ]
            if f"/commits/{newer_sha}?" in endpoint:
                query = parse_qs(urlparse(endpoint).query)
                self.assertEqual(query["page"], ["1"])
                return {
                    "files": [
                        self.changed_file(
                            "articles/app-service/new-feature.md",
                            additions=8,
                            deletions=1,
                        ),
                        self.changed_file(
                            "articles/azure-functions/other.md",
                            additions=12,
                            deletions=2,
                        ),
                        self.changed_file("articles/app-service/toc.yml"),
                        self.changed_file("articles/app-service/app-service.yml"),
                        self.changed_file("articles/app-service/settings.json"),
                    ]
                }
            self.fail(f"Unexpected API endpoint: {endpoint}")

        with patch.object(MODULE, "api_get", side_effect=fake_api):
            report = MODULE.collect_changes(
                "MicrosoftDocs/azure-docs-pr",
                ["articles/app-service"],
                date(2026, 1, 15),
            )

        self.assertEqual(len(report["commits"]), 1)
        self.assertEqual(report["commits"][0]["sha"], newer_sha)
        self.assertEqual(
            [item["path"] for item in report["commits"][0]["files"]],
            [
                "articles/app-service/new-feature.md",
                "articles/app-service/toc.yml",
            ],
        )
        self.assertTrue(any("/commits?" in endpoint for endpoint in calls))

    def test_collect_changes_keeps_exactly_300_files(self):
        sha = "c" * 40
        detail_pages = []

        def fake_api(endpoint):
            if "/contents/" in endpoint:
                return []
            if "/commits?" in endpoint and f"/commits/{sha}?" not in endpoint:
                return [
                    self.commit_summary(
                        sha,
                        "2026-01-16T10:00:00Z",
                        "Large App Service refresh",
                    )
                ]
            if f"/commits/{sha}?" in endpoint:
                page = parse_qs(urlparse(endpoint).query)["page"][0]
                detail_pages.append(page)
                if page in {"1", "2", "3"}:
                    start = (int(page) - 1) * MODULE.PAGE_SIZE
                    return {
                        "files": [
                            self.changed_file(
                                f"articles/app-service/file-{index:03}.md"
                            )
                            for index in range(start, start + MODULE.PAGE_SIZE)
                        ]
                    }
                if page == "4":
                    return {"files": []}
            self.fail(f"Unexpected API endpoint: {endpoint}")

        with patch.object(MODULE, "api_get", side_effect=fake_api):
            report = MODULE.collect_changes(
                "MicrosoftDocs/azure-docs-pr",
                ["articles/app-service"],
                date(2026, 1, 15),
            )

        self.assertEqual(len(report["commits"]), 1)
        self.assertEqual(len(report["commits"][0]["files"]), 300)
        self.assertEqual(detail_pages, ["1", "2", "3", "4"])

    def test_collect_changes_aggregates_multi_page_commit_files(self):
        sha = "d" * 40
        detail_pages = []

        def fake_api(endpoint):
            if "/contents/" in endpoint:
                return []
            if "/commits?" in endpoint and f"/commits/{sha}?" not in endpoint:
                return [
                    self.commit_summary(
                        sha,
                        "2026-01-16T10:00:00Z",
                        "Paginated App Service update",
                    )
                ]
            if f"/commits/{sha}?" in endpoint:
                page = parse_qs(urlparse(endpoint).query)["page"][0]
                detail_pages.append(page)
                if page == "1":
                    return {
                        "files": [
                            self.changed_file(
                                f"articles/app-service/file-{index:03}.md"
                            )
                            for index in range(MODULE.PAGE_SIZE)
                        ]
                    }
                if page == "2":
                    return {
                        "files": [
                            self.changed_file("articles/app-service/TOC.yml"),
                            self.changed_file(
                                "articles/app-service/extra-feature.md"
                            ),
                        ]
                    }
            self.fail(f"Unexpected API endpoint: {endpoint}")

        with patch.object(MODULE, "api_get", side_effect=fake_api):
            report = MODULE.collect_changes(
                "MicrosoftDocs/azure-docs-pr",
                ["articles/app-service"],
                date(2026, 1, 15),
            )

        self.assertEqual(len(report["commits"]), 1)
        self.assertEqual(len(report["commits"][0]["files"]), MODULE.PAGE_SIZE + 2)
        reported_paths = [item["path"] for item in report["commits"][0]["files"]]
        self.assertIn("articles/app-service/TOC.yml", reported_paths)
        self.assertIn("articles/app-service/extra-feature.md", reported_paths)
        self.assertEqual(detail_pages, ["1", "2"])

    def test_collect_changes_fails_when_commit_reaches_retrievable_limit(self):
        sha = "e" * 40

        def fake_api(endpoint):
            if "/contents/" in endpoint:
                return []
            if "/commits?" in endpoint and f"/commits/{sha}?" not in endpoint:
                return [
                    self.commit_summary(
                        sha,
                        "2026-01-16T10:00:00Z",
                        "Huge App Service update",
                    )
                ]
            if f"/commits/{sha}?" in endpoint:
                return {
                    "files": [
                        self.changed_file(
                            f"articles/app-service/file-{index:04}.md"
                        )
                        for index in range(MODULE.PAGE_SIZE)
                    ]
                }
            self.fail(f"Unexpected API endpoint: {endpoint}")

        with patch.object(MODULE, "api_get", side_effect=fake_api):
            with self.assertRaisesRegex(MODULE.ApiError, str(MODULE.MAX_COMMIT_FILES)):
                MODULE.collect_changes(
                    "MicrosoftDocs/azure-docs-pr",
                    ["articles/app-service"],
                    date(2026, 1, 15),
                )

    def test_surfaces_authentication_and_api_failures(self):
        with patch.object(
            MODULE,
            "api_get",
            side_effect=MODULE.ApiError("HTTP 403: SSO authorization required"),
        ):
            with self.assertRaisesRegex(MODULE.ApiError, "SSO authorization required"):
                MODULE.collect_changes(
                    "MicrosoftDocs/azure-docs-pr",
                    ["articles/app-service"],
                    date(2026, 1, 15),
                )


if __name__ == "__main__":
    unittest.main()
