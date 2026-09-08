#!/usr/bin/env node
import { spawnSync } from "node:child_process";

const expectedOptions = new Set(["vault", "path", "old", "new"]);
const options = {};

for (let index = 2; index < process.argv.length; index += 2) {
    const flag = process.argv[index];
    const value = process.argv[index + 1];
    const name = flag?.startsWith("--") ? flag.slice(2) : undefined;

    if (!name || !expectedOptions.has(name) || value === undefined || name in options) {
        console.error(
            "Usage: node scripts/replace-once.mjs --vault <name> --path <vault-relative.md> --old <exact text> --new <replacement>",
        );
        process.exit(2);
    }

    options[name] = value;
}

if (
    Object.keys(options).length !== expectedOptions.size ||
    !options.path.endsWith(".md") ||
    options.old.length === 0
) {
    console.error(
        "Require non-empty --old, a vault-relative .md --path, and exactly one value for --vault, --path, --old, and --new.",
    );
    process.exit(2);
}

const payload = JSON.stringify(options);
const code = `async () => {
    const input = ${payload};
    const file = app.vault.getFileByPath(input.path);
    if (!file || file.extension !== "md") throw new Error("Markdown file not found: " + input.path);

    let count = 0;
    await app.vault.process(file, (content) => {
        count = content.split(input.old).length - 1;
        if (count !== 1) throw new Error("Expected one exact match in " + input.path + "; found " + count);
        return content.replace(input.old, input.new);
    });

    return JSON.stringify({ path: file.path, replacements: count });
}`;

const result = spawnSync("obsidian", [`vault=${options.vault}`, "eval", `code=${code}`], {
    stdio: "inherit",
});

if (result.error) {
    console.error(`Could not run obsidian: ${result.error.message}`);
    process.exit(1);
}

process.exit(result.status ?? 1);
