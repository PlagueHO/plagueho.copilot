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
                    {
                        "sha": newer_sha,
                        "commit": {
                            "committer": {"date": "2026-01-16T10:00:00Z"},
                            "message": "Add App Service capability\n\nMore details",
                        },
                    },
                    {
                        "sha": same_day_sha,
                        "commit": {
                            "committer": {"date": "2026-01-15T21:00:00Z"},
                            "message": "Update App Service docs",
                        },
                    },
                ]
            if endpoint.endswith(newer_sha):
                return {
                    "files": [
                        {
                            "filename": "articles/app-service/new-feature.md",
                            "status": "modified",
                            "additions": 8,
                            "deletions": 1,
                        },
                        {
                            "filename": "articles/azure-functions/other.md",
                            "status": "modified",
                            "additions": 12,
                            "deletions": 2,
                        },
                        {
                            "filename": "articles/app-service/toc.yml",
                            "status": "modified",
                            "additions": 1,
                            "deletions": 0,
                        },
                        {
                            "filename": "articles/app-service/settings.json",
                            "status": "modified",
                            "additions": 1,
                            "deletions": 0,
                        },
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
