import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile, utimes, access, rm, stat } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { CategorizerStore } from "../src/core/categorizers.mjs";
import { executeAnalyzerCommand, getAnalyzerCommands } from "../src/core/analyzer-commands.mjs";
import { createCleanupPreview, executeCleanupPreview } from "../src/core/cleanup.mjs";
import { listCustomAnalyzers } from "../src/analyzers/custom-analyzers.mjs";
import { inspectStorageItem } from "../src/core/item-inspector.mjs";
import {
    buildFolderExplanationPrompt,
    parseFolderExplanation,
    parseFolderExplanationCandidates,
} from "../src/core/folder-explanation.mjs";
import { scanStorage } from "../src/core/scanner.mjs";
import { analyzeVsCodeInsiders } from "../src/analyzers/vscode-insiders.mjs";
import { WINDOWS_ONLY_MESSAGE, assertWindowsPlatform, isWindowsPlatform } from "../src/core/platform.mjs";

const root = await mkdtemp(path.join(os.tmpdir(), "storage-inspector-test-"));
const stateRoot = await mkdtemp(path.join(os.tmpdir(), "storage-inspector-state-"));
try {
    assert.equal(isWindowsPlatform("win32"), true);
    assert.equal(isWindowsPlatform("linux"), false);
    assert.throws(() => assertWindowsPlatform("linux"), (error) => (
        error.code === "windows_only" && error.message === WINDOWS_ONLY_MESSAGE
    ));
    assert.deepEqual(
        listCustomAnalyzers().map((analyzer) => analyzer.id),
        ["vscode-insiders", "microsoft-scout", "docker-images"],
    );
    const dockerCommands = getAnalyzerCommands("docker-images");
    assert.deepEqual(
        dockerCommands.map((command) => command.id),
        ["docker-image-prune", "docker-image-prune-all", "docker-system-df"],
    );
    assert.equal(dockerCommands[0].requiresConfirmation, true);
    assert.equal(dockerCommands[2].requiresConfirmation, false);
    assert.equal("executable" in dockerCommands[0], false);
    await assert.rejects(
        executeAnalyzerCommand("docker-images", "docker-image-prune", false),
        { code: "analyzer_command_confirmation_required" },
    );

    const cacheDirectory = path.join(root, "AppData", "Local", "GitHub Copilot", "Cache");
    const regularDirectory = path.join(root, "Documents");
    await mkdir(cacheDirectory, { recursive: true });
    await mkdir(regularDirectory, { recursive: true });
    const cacheFile = path.join(cacheDirectory, "stale-cache.bin");
    const regularFile = path.join(regularDirectory, "keep.txt");
    const foundryCache = path.join(root, "AppData", "Local", "Foundry", "models");
    const foundryModel = path.join(foundryCache, "model.onnx");
    await writeFile(cacheFile, Buffer.alloc(4096, 1));
    await writeFile(regularFile, "keep");
    await mkdir(foundryCache, { recursive: true });
    await writeFile(foundryModel, Buffer.alloc(2048, 1));
    const oldDate = new Date(Date.now() - 30 * 86_400_000);
    await utimes(cacheFile, oldDate, oldDate);

    const result = await scanStorage({
        roots: [{ id: "test", label: "Test root", path: root }],
    });
    assert.equal(result.summary.files, 3);
    assert.equal(result.summary.bytes, 6148);
    assert.equal(result.summary.cloudOnlyBytes, 0);
    assert.equal(result.summary.cloudOnlyFiles, 0);
    assert.equal(result.candidates.length, 1);
    assert.equal(result.candidates[0].app, "GitHub Copilot");

    const preview = await createCleanupPreview({
        itemIds: [result.candidates[0].id],
        candidates: result.candidates,
        source: { type: "scan" },
        approvedRoots: [{ id: "test", label: "Test root", path: root }],
    });
    assert.equal(preview.entries.length, 1);
    const cleanupProgress = [];
    const cleanup = await executeCleanupPreview({
        preview,
        confirmed: true,
        onProgress: (progress) => cleanupProgress.push(progress),
    });
    assert.equal(cleanup.succeeded.length, 1);
    assert.ok(cleanupProgress.some((progress) => progress.phase === "validating"));
    assert.ok(cleanupProgress.some((progress) => progress.phase === "recycling" && progress.completed === 1));
    await assert.rejects(access(cacheFile));
    await access(regularFile);

    const dockerRoot = path.join(root, "AppData", "Local", "Docker", "wsl");
    const dockerData = path.join(dockerRoot, "docker-data.bin");
    await mkdir(dockerRoot, { recursive: true });
    await writeFile(dockerData, Buffer.alloc(1024, 1));

    const analyzerDirectory = path.join(root, "AnalyzerCache");
    await mkdir(analyzerDirectory);
    await writeFile(path.join(analyzerDirectory, "cache.bin"), Buffer.alloc(128, 1));
    const analyzerStats = await stat(analyzerDirectory);
    const analyzerPreview = await createCleanupPreview({
        itemIds: ["analyzer-cache"],
        candidates: [{
            id: "analyzer-cache",
            path: analyzerDirectory,
            bytes: 128,
            modifiedAt: analyzerStats.mtime.toISOString(),
            entryType: "directory",
            cleanupEligible: true,
            reason: "Test cache",
            risk: "low",
        }],
        source: { type: "analyzer", analyzerId: "test-analyzer" },
        approvedRoots: [{ id: "test", label: "Test root", path: root }],
    });
    assert.equal(analyzerPreview.source.type, "analyzer");
    assert.equal(analyzerPreview.entries[0].entryType, "directory");
    assert.equal(analyzerPreview.totalBytes, 128);

    const controller = new AbortController();
    controller.abort();
    await assert.rejects(
        scanStorage({
            roots: [{ id: "test", label: "Test root", path: root }],
            signal: controller.signal,
        }),
        { code: "ABORT_ERR" },
    );

    const vscodeAnalysis = await analyzeVsCodeInsiders(result);
    assert.ok(["not-found", "not-running", "running", "unsupported"].includes(vscodeAnalysis.status));

    const categorizerStore = new CategorizerStore({
        storagePath: path.join(stateRoot, "categorizers.json"),
    });
    const categorizer = await categorizerStore.add({
        path: foundryCache,
        name: "Microsoft Foundry Local",
        category: "AI model cache",
        description: "Downloaded local models",
        approvedRoots: [{ path: root }],
    });
    assert.equal(categorizer.name, "Microsoft Foundry Local");
    const persistedStore = new CategorizerStore({
        storagePath: path.join(stateRoot, "categorizers.json"),
    });
    assert.equal((await persistedStore.list()).custom.length, 1);
    assert.ok((await persistedStore.list()).builtIn.some((rule) => rule.name === "Docker Desktop"));

    const categorizedResult = await scanStorage({
        roots: [{ id: "test", label: "Test root", path: root }],
        categorizers: await persistedStore.all(),
    });
    assert.ok(categorizedResult.apps.some((item) => item.name === "Microsoft Foundry Local" && item.bytes === 2048));
    assert.ok(categorizedResult.apps.some((item) => item.name === "Docker Desktop" && item.bytes === 1024));
    assert.ok(categorizedResult.categories.some((item) => item.name === "AI model cache" && item.bytes === 2048));
    const inspection = await inspectStorageItem({
        targetPath: foundryCache,
        roots: categorizedResult.roots,
        result: categorizedResult,
        categorizers: await persistedStore.all(),
    });
    assert.equal(inspection.categorizer.name, "Microsoft Foundry Local");
    assert.equal(inspection.directContents.samples[0].name, "model.onnx");
    const explanationPrompt = buildFolderExplanationPrompt(inspection);
    assert.match(explanationPrompt, /Return ONLY one JSON object/);
    assert.match(explanationPrompt, /"recommendation": "safe \| conditional \| not-recommended \| unknown"/);
    const explanation = parseFolderExplanation(`\`\`\`json
{
  "version": 1,
  "title": "Model cache",
  "summary": "Downloaded model files.",
  "contents": [{ "name": "Models", "description": "Reusable model artifacts." }],
  "typicalUses": ["Offline inference"],
  "cleanup": {
    "recommendation": "conditional",
    "summary": "Remove only models that are no longer needed.",
    "risk": "Models must be downloaded again.",
    "impact": "Offline inference is unavailable until restoration.",
    "commands": [{
      "label": "List cache",
      "command": "example cache list",
      "shell": "PowerShell",
      "description": "Lists cached items.",
      "requiresElevation": false
    }],
    "steps": ["Review cached models."],
    "warnings": ["Do not remove active models."]
  },
  "sources": [{ "title": "Example docs", "url": "https://example.com/docs" }]
}
\`\`\``);
    assert.equal(explanation.cleanup.recommendation, "conditional");
    assert.equal(explanation.cleanup.commands[0].command, "example cache list");
    assert.equal(explanation.sources[0].url, "https://example.com/docs");
    assert.equal(
        parseFolderExplanationCandidates([
            "Copilot is still researching.",
            JSON.stringify(explanation),
        ]).title,
        "Model cache",
    );
    assert.throws(
        () => parseFolderExplanation('{"version":1,"title":"Bad"}'),
        { code: "folder_explanation_invalid" },
    );

    await persistedStore.remove(categorizer.id);
    assert.equal((await persistedStore.list()).custom.length, 0);
} finally {
    await rm(root, { recursive: true, force: true });
    await rm(stateRoot, { recursive: true, force: true });
}
