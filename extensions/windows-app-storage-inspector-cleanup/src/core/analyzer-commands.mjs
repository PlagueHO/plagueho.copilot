import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const COMMAND_TIMEOUT_MS = 120_000;
const MAX_OUTPUT_BYTES = 1_048_576;

const COMMANDS = {
    "docker-images": [
        {
            id: "docker-image-prune",
            label: "Remove dangling images",
            command: "docker image prune --force",
            shell: "PowerShell",
            description: "Removes untagged image layers that are not referenced by a container.",
            requiresElevation: false,
            requiresConfirmation: true,
            executable: "docker.exe",
            arguments: ["image", "prune", "--force"],
        },
        {
            id: "docker-image-prune-all",
            label: "Remove unused images",
            command: "docker image prune --all --force",
            shell: "PowerShell",
            description: "Removes images not referenced by any container. Review the image list first.",
            requiresElevation: false,
            requiresConfirmation: true,
            executable: "docker.exe",
            arguments: ["image", "prune", "--all", "--force"],
        },
        {
            id: "docker-system-df",
            label: "Review all reclaimable Docker data",
            command: "docker system df",
            shell: "PowerShell",
            description: "Reports reclaimable images, containers, local volumes, and build cache without deleting anything.",
            requiresElevation: false,
            requiresConfirmation: false,
            executable: "docker.exe",
            arguments: ["system", "df"],
        },
    ],
};

function getCommand(analyzerId, commandId) {
    const command = COMMANDS[analyzerId]?.find((item) => item.id === commandId);
    if (!command) {
        const error = new Error(`Unknown analyzer command: ${commandId}`);
        error.code = "analyzer_command_unknown";
        throw error;
    }
    return command;
}

export function getAnalyzerCommands(analyzerId) {
    return (COMMANDS[analyzerId] ?? []).map((command) => {
        const {
            executable,
            arguments: args,
            ...displayCommand
        } = command;
        return displayCommand;
    });
}

function getOutput(error) {
    return String(error?.stdout || error?.stderr || error?.message || "The command failed.");
}

export async function executeAnalyzerCommand(analyzerId, commandId, confirmed = false) {
    const command = getCommand(analyzerId, commandId);
    if (command.requiresConfirmation && confirmed !== true) {
        const error = new Error("Explicit confirmation is required before running this cleanup command");
        error.code = "analyzer_command_confirmation_required";
        throw error;
    }

    try {
        const result = await execFileAsync(command.executable, command.arguments, {
            windowsHide: true,
            timeout: COMMAND_TIMEOUT_MS,
            maxBuffer: MAX_OUTPUT_BYTES,
        });
        return {
            commandId: command.id,
            command: command.command,
            status: "completed",
            output: String(result.stdout || result.stderr || ""),
        };
    } catch (error) {
        const commandError = new Error(`Command failed: ${getOutput(error)}`);
        commandError.code = error?.code === "ETIMEDOUT"
            ? "analyzer_command_timeout"
            : "analyzer_command_failed";
        throw commandError;
    }
}
