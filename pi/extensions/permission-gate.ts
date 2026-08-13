/**
 * Permission Gate Extension
 *
 * Prompts for confirmation before running bash commands.
 *
 * For now this requires confirmation for *every* bash command, not just
 * dangerous ones (TODO: relax this back to only the dangerous patterns
 * below once things settle). Commands matching a dangerous pattern (rm -rf,
 * sudo, chmod/chown 777, force pushes, disk-wiping dd/mkfs) get a more
 * alarming prompt; everything else still requires a plain confirmation.
 *
 * Source: adapted from the pi-coding-agent `permission-gate.ts` example
 * (https://pi.dev docs/extensions).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const dangerousPatterns = [
		/\brm\s+(-rf?|--recursive)/i,
		/\bsudo\b/i,
		/\b(chmod|chown)\b.*777/i,
		/\bgit\s+push\b.*(--force|-f)\b/i,
		/\bjj\s+git\s+push\b.*--force/i,
		/\bdd\s+if=/i,
		/\bmkfs\b/i,
	];

	// TODO: for now every bash command requires confirmation; once this has
	// settled, flip back to only prompting when isDangerous is true.
	const REQUIRE_CONFIRMATION_FOR_ALL_BASH = false;

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;

		const command = event.input.command as string;
		const isDangerous = dangerousPatterns.some((p) => p.test(command));

		if (isDangerous || REQUIRE_CONFIRMATION_FOR_ALL_BASH) {
			if (!ctx.hasUI) {
				// In non-interactive mode, block by default
				return { block: true, reason: "Command blocked (no UI for confirmation)" };
			}

			const title = isDangerous ? "⚠️ Dangerous command" : "Run command?";
			const ok = await ctx.ui.confirm(title, command);

			if (!ok) {
				return { block: true, reason: "Blocked by user" };
			}
		}

		return undefined;
	});
}
