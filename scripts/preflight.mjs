#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const root = path.resolve(__dirname, "..", "..");

// Topology + allowlist config — manifest-driven. Edit
// agents/scripts/preflight-config.json (or .agents/scripts/...
// at child repos) to change what counts as a known repo / allowed
// top-level / per-product-repo extension.
const configPath = (() => {
  const candidates = [
    path.join(__dirname, "preflight-config.json"),
    path.join(root, "agents", "scripts", "preflight-config.json"),
    path.join(root, ".agents", "scripts", "preflight-config.json"),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  return null;
})();
const config = configPath
  ? JSON.parse(fs.readFileSync(configPath, "utf8"))
  : {
      activeRepos: [],
      publicOssRepos: [],
      rootWorkspaceAllowedTopLevel: [],
      productRepoCommonExtraTopLevel: [],
      productRepoAllowedTopLevel: {},
    };
const activeRepos = config.activeRepos || [];
const publicOssRepos = new Set(config.publicOssRepos || []);
const privateRepos = activeRepos.filter((repo) => !publicOssRepos.has(repo));
const policyFleetDir = path.join(root, "agents");
const propagatedFleetDir = path.join(root, ".agents");
const hasPolicyFleet = fs.existsSync(path.join(policyFleetDir, "OPERATING_MODEL.md"));
const hasPropagatedFleet = fs.existsSync(path.join(propagatedFleetDir, "OPERATING_MODEL.md"));
const rootRepoName = path.basename(root);
const isKnownProductRepo = activeRepos.includes(rootRepoName);
const isPublicOssProductRepo = publicOssRepos.has(rootRepoName);
const hasWorkspaceChildren = activeRepos.some((repo) => fs.existsSync(path.join(root, repo)));
const layout = hasPolicyFleet
  ? {
      mode: "policy-repo",
      fleetDir: policyFleetDir,
      fleetRel: "agents",
      childRoot: path.dirname(root),
      missingChildReposAreWarnings: true,
      checkActiveRepos: true,
      requireRootEntrypoints: true,
      workspaceLayoutRoot: path.dirname(root),
    }
  : {
      mode: hasPropagatedFleet ? (hasWorkspaceChildren ? "propagated-root" : "propagated-repo") : "missing-fleet",
      fleetDir: propagatedFleetDir,
      fleetRel: ".agents",
      childRoot: root,
      missingChildReposAreWarnings: !hasWorkspaceChildren,
      checkActiveRepos: hasWorkspaceChildren,
      requireRootEntrypoints: !isKnownProductRepo || !isPublicOssProductRepo,
      workspaceLayoutRoot: hasWorkspaceChildren ? root : root,
    };
const workspaceRoot = layout.workspaceLayoutRoot;

const localMcpRepos = layout.checkActiveRepos ? [".", ...activeRepos] : ["."];
const approvedMcpPath = path.join(layout.fleetDir, "mcp", "approved-defaults.json");
const rootWorkspaceAllowedTopLevel = new Set(
  config.rootWorkspaceAllowedTopLevel || [],
);
const productRepoCommonTopLevel = new Set([
  ...rootWorkspaceAllowedTopLevel,
  ...(config.productRepoCommonExtraTopLevel || []),
]);
const productRepoAllowedTopLevel = config.productRepoAllowedTopLevel || {};

const failures = [];
const warnings = [];
const passed = [];

function rel(absPath) {
  return path.relative(root, absPath) || ".";
}

function repoBase(repo) {
  return repo === "." ? root : path.join(layout.childRoot, repo);
}

function repoRel(repo, relPath) {
  return repo === "." ? relPath : path.join(repo, relPath);
}

function allowedTopLevelForCurrentLayout() {
  if (layout.mode === "propagated-repo" && isKnownProductRepo) {
    return new Set([
      ...productRepoCommonTopLevel,
      ...(productRepoAllowedTopLevel[rootRepoName] || []),
    ]);
  }
  return rootWorkspaceAllowedTopLevel;
}

function pass(message) {
  passed.push(message);
}

function warn(message) {
  warnings.push(message);
}

function fail(message) {
  failures.push(message);
}

function exists(relPath) {
  return fs.existsSync(path.join(root, relPath));
}

function readText(absPath) {
  return fs.readFileSync(absPath, "utf8");
}

function runGit(cwd, args) {
  return spawnSync("git", ["-C", cwd, ...args], { encoding: "utf8" });
}

function inspectStrings(value, visitor) {
  if (typeof value === "string") {
    visitor(value);
  } else if (Array.isArray(value)) {
    for (const item of value) inspectStrings(item, visitor);
  } else if (value && typeof value === "object") {
    for (const item of Object.values(value)) inspectStrings(item, visitor);
  }
}

function collectSkillFiles(dir, files = []) {
  if (!fs.existsSync(dir)) return files;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      collectSkillFiles(full, files);
    } else if (entry.isFile() && entry.name === "SKILL.md") {
      files.push(full);
    }
  }
  return files;
}

function unquoteYamlScalar(value) {
  const trimmed = value.trim();
  if ((trimmed.startsWith('"') && trimmed.endsWith('"')) || (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
    return trimmed.slice(1, -1);
  }
  return trimmed;
}

function validateSkillFrontmatter() {
  const skillFiles = [];
  collectSkillFiles(path.join(layout.fleetDir, "skills"), skillFiles);
  collectSkillFiles(path.join(root, ".claude", "skills"), skillFiles);
  if (layout.checkActiveRepos) {
    for (const repo of activeRepos) {
      const base = repoBase(repo);
      if (!fs.existsSync(base)) continue;
      collectSkillFiles(path.join(base, ".agents", "skills"), skillFiles);
      collectSkillFiles(path.join(base, ".claude", "skills"), skillFiles);
    }
  }

  for (const file of skillFiles) {
    const text = readText(file);
    const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
    if (!match) {
      fail(`${rel(file)}: missing YAML frontmatter`);
      continue;
    }

    const data = {};
    const lines = match[1].split(/\r?\n/).filter((line) => line.trim().length > 0);
    for (const line of lines) {
      const parsed = line.match(/^([A-Za-z0-9_-]+):(?:\s*(.*))?$/);
      if (!parsed) {
        fail(`${rel(file)}: unsupported frontmatter line: ${line}`);
        continue;
      }
      const [, key, rawValue = ""] = parsed;
      const trimmed = rawValue.trim();
      const quoted = (trimmed.startsWith('"') && trimmed.endsWith('"')) || (trimmed.startsWith("'") && trimmed.endsWith("'"));
      if (!quoted && trimmed.includes(": ")) {
        fail(`${rel(file)}: unquoted scalar contains ': ' in ${key}`);
      }
      data[key] = unquoteYamlScalar(trimmed);
    }

    if (!data.name) fail(`${rel(file)}: missing name`);
    if (!data.description) fail(`${rel(file)}: missing description`);
  }

  if (skillFiles.length === 0) {
    fail("No skill files found under root or active repos");
  } else {
    pass(`skill frontmatter: ${skillFiles.length} files checked`);
  }
}

function validateJsonAt(absPath, label, { allowPlaceholders = false } = {}) {
  if (!fs.existsSync(absPath)) {
    fail(`${label}: missing JSON file`);
    return null;
  }
  try {
    const parsed = JSON.parse(readText(absPath));
    if (!parsed || typeof parsed !== "object") fail(`${label}: JSON root is not an object`);
    pass(`${label}: valid JSON`);
    return parsed;
  } catch (error) {
    fail(`${label}: invalid JSON: ${error.message}`);
    return null;
  }
}

function validateMcpExamples() {
  const examplePath = path.join(workspaceRoot, ".mcp.example.json");
  if (layout.mode === "propagated-repo" && !fs.existsSync(examplePath)) {
    pass(".mcp.example.json: absent in product repo; default baseline uses no MCP servers");
    return;
  }
  validateJsonAt(examplePath, ".mcp.example.json", { allowPlaceholders: true });
}

function loadApprovedDefaultMcpServers() {
  if (!fs.existsSync(approvedMcpPath)) {
    fail(`${rel(approvedMcpPath)}: missing approved MCP defaults file`);
    return new Set();
  }
  try {
    const parsed = JSON.parse(readText(approvedMcpPath));
    const names = Array.isArray(parsed.defaultMcpServers) ? parsed.defaultMcpServers : [];
    for (const name of names) {
      if (typeof name !== "string" || name.length === 0) {
        fail(`${rel(approvedMcpPath)}: defaultMcpServers must contain only non-empty strings`);
      }
    }
    pass(`${rel(approvedMcpPath)}: ${names.length} approved default MCP server(s)`);
    return new Set(names);
  } catch (error) {
    fail(`${rel(approvedMcpPath)}: invalid JSON: ${error.message}`);
    return new Set();
  }
}

function validateLocalMcpConfig() {
  const approvedServers = loadApprovedDefaultMcpServers();
  for (const repo of localMcpRepos) {
    const base = repoBase(repo);
    if (repo !== "." && !fs.existsSync(base)) continue;
    const relPath = repoRel(repo, ".mcp.json");
    const absPath = path.join(base, ".mcp.json");
    if (!fs.existsSync(absPath)) {
      pass(`${relPath}: local MCP config absent; default baseline uses no MCP servers`);
      continue;
    }
    const config = validateJsonAt(absPath, relPath);
    if (!config) continue;

    const servers = config.mcpServers && typeof config.mcpServers === "object" ? config.mcpServers : {};
    for (const name of Object.keys(servers)) {
      if (!approvedServers.has(name)) {
        fail(`${relPath}: MCP server '${name}' is not in .agents/mcp/approved-defaults.json`);
      }
    }

    inspectStrings(config, (value) => {
      if (value.includes("C:/") || value.includes("C:\\")) {
        fail(`${relPath}: Windows path remains in active Linux config: ${value}`);
      }
      if (value.startsWith("/var/home/") && !fs.existsSync(value)) {
        fail(`${relPath}: referenced local path does not exist: ${value}`);
      }
    });
  }
}

function validateGitIgnorePolicy() {
  const repos = layout.checkActiveRepos ? [".", ...activeRepos] : ["."];
  for (const repo of repos) {
    const cwd = repoBase(repo);
    if (!fs.existsSync(cwd)) {
      if (layout.missingChildReposAreWarnings && repo !== ".") {
        warn(`${repo}: active repo directory absent in parent workspace; skipping repo-specific checks`);
      } else {
        fail(`${repo}: active repo directory missing`);
      }
      continue;
    }
    for (const file of [".mcp.json", ".mcp.local.json"]) {
      const ignored = runGit(cwd, ["check-ignore", "-q", "--no-index", file]);
      if (ignored.status !== 0) {
        fail(`${repo}: ${file} is not ignored`);
      }
    }
  }

  for (const repo of localMcpRepos) {
    const cwd = repoBase(repo);
    if (!fs.existsSync(cwd)) continue;
    const tracked = runGit(cwd, ["ls-files", "--error-unmatch", ".mcp.json"]);
    if (tracked.status === 0) {
      fail(`${repo}: .mcp.json is tracked; it must remain machine-local`);
    }
  }
  pass("MCP ignore policy checked for root and active repos");
}

function validateEntrypoints() {
  if (layout.mode === "missing-fleet") {
    fail("fleet policy missing: expected agents/OPERATING_MODEL.md or .agents/OPERATING_MODEL.md");
  } else {
    pass(`preflight layout: ${layout.mode} (${layout.fleetRel}/)`);
  }

  // Required at root: agent-agnostic AGENTS.md + WORKFLOW.md, plus the fleet
  // control plane. Agent-specific files (CLAUDE.md, GEMINI.md) are optional
  // additive imports of AGENTS.md.
  const requiredRoot = [
    `${layout.fleetRel}/OPERATING_MODEL.md`,
    `${layout.fleetRel}/DOCUMENTATION_GUIDE.md`,
    `${layout.fleetRel}/SKILL_REGISTRY.md`,
    `${layout.fleetRel}/WORKSPACE_LAYOUT.md`,
    `${layout.fleetRel}/MODEL_ROUTING.md`,
    `${layout.fleetRel}/GREEN_ROOM_EVALUATION.md`,
    `${layout.fleetRel}/mcp/README.md`,
    `${layout.fleetRel}/mcp/approved-defaults.json`,
  ];
  if (layout.requireRootEntrypoints) {
    requiredRoot.unshift("AGENTS.md", "WORKFLOW.md");
  }
  const optionalRoot = ["CLAUDE.md", "GEMINI.md"];
  for (const relPath of requiredRoot) {
    if (exists(relPath)) pass(`${relPath}: present`);
    else fail(`${relPath}: missing`);
  }
  const checkOssTrackedOrUngitignored = (relPath) => {
    if (!exists(relPath)) return null;
    const full = path.join(root, relPath);
    const cwd = path.dirname(full);
    const tracked = runGit(cwd, ["ls-files", "--error-unmatch", path.basename(full)]);
    if (tracked.status === 0) return "tracked";
    const ignored = runGit(cwd, ["check-ignore", "-q", path.basename(full)]);
    if (ignored.status !== 0) return "not-ignored";
    return null;
  };

  for (const relPath of optionalRoot) {
    if (exists(relPath)) {
      if (isPublicOssProductRepo && layout.mode === "propagated-repo") {
        const reason = checkOssTrackedOrUngitignored(relPath);
        if (reason === "tracked") {
          fail(`${relPath}: tracked in public OSS repo; root-level agent docs must not reach the public surface`);
        } else if (reason === "not-ignored") {
          fail(`${relPath}: present in public OSS repo and NOT gitignored; agent infrastructure must stay local-only per OPERATING_MODEL Public OSS posture`);
        } else {
          pass(`${relPath}: present locally; gitignored per Public OSS posture`);
        }
      } else {
        pass(`${relPath}: present (optional agent-specific extension)`);
      }
    }
  }

  if (isPublicOssProductRepo && layout.mode === "propagated-repo") {
    for (const relPath of ["AGENTS.md", "WORKFLOW.md"]) {
      if (!exists(relPath)) continue;
      const reason = checkOssTrackedOrUngitignored(relPath);
      if (reason === "tracked") {
        fail(`${relPath}: tracked in public OSS repo; root-level agent docs must not reach the public surface`);
      } else if (reason === "not-ignored") {
        fail(`${relPath}: present in public OSS repo and NOT gitignored; agent infrastructure must stay local-only per OPERATING_MODEL Public OSS posture`);
      } else {
        pass(`${relPath}: present locally; gitignored per Public OSS posture`);
      }
    }
  }

  if (layout.checkActiveRepos) {
    for (const repo of privateRepos) {
      const base = repoBase(repo);
      if (!fs.existsSync(base)) {
        if (layout.missingChildReposAreWarnings) {
          warn(`${repo}: active repo directory absent in parent workspace; skipping entrypoint checks`);
        } else {
          fail(`${repo}: active repo directory missing`);
        }
        continue;
      }
      // AGENTS.md + WORKFLOW.md required. CLAUDE.md/GEMINI.md optional.
      for (const relPath of ["AGENTS.md", "WORKFLOW.md"]) {
        const full = path.join(base, relPath);
        if (!fs.existsSync(full)) fail(`${repo}/${relPath}: missing`);
      }
    }

    for (const repo of publicOssRepos) {
      const cwd = repoBase(repo);
      if (!fs.existsSync(cwd)) {
        if (layout.missingChildReposAreWarnings) {
          warn(`${repo}: active repo directory absent in parent workspace; skipping public-OSS checks`);
        } else {
          fail(`${repo}: active repo directory missing`);
        }
        continue;
      }
      // Root-level agent docs MUST NOT reach the public surface. Working-tree
      // presence is permitted for local agent tooling; only tracked (or
      // un-gitignored) instances are blocking — matching the contract for
      // .agents/ and .claude/ below.
      for (const relPath of ["AGENTS.md", "CLAUDE.md", "GEMINI.md", "WORKFLOW.md"]) {
        const full = path.join(cwd, relPath);
        if (!fs.existsSync(full)) continue;
        const tracked = runGit(cwd, ["ls-files", "--error-unmatch", relPath]);
        if (tracked.status === 0) {
          fail(`${repo}/${relPath}: tracked in public OSS repo; root-level agent docs must not reach the public surface`);
          continue;
        }
        const ignored = runGit(cwd, ["check-ignore", "-q", relPath]);
        if (ignored.status !== 0) {
          fail(`${repo}/${relPath}: present in public OSS repo and NOT gitignored; agent infrastructure must stay local-only per OPERATING_MODEL Public OSS posture`);
        }
      }
      // .agents/ and .claude/ MAY exist locally for agent tooling, but MUST be
      // gitignored per OPERATING_MODEL "Public OSS posture".
      for (const relPath of [".agents", ".claude"]) {
        const full = path.join(cwd, relPath);
        if (!fs.existsSync(full)) continue;
        const ignored = runGit(cwd, ["check-ignore", "-q", relPath]);
        if (ignored.status !== 0) {
          fail(`${repo}/${relPath}: present in public OSS repo and NOT gitignored; agent infrastructure must stay local-only per OPERATING_MODEL Public OSS posture`);
        }
      }
    }
  } else if (isPublicOssProductRepo) {
    for (const relPath of [".agents", ".claude"]) {
      const full = path.join(root, relPath);
      if (!fs.existsSync(full)) continue;
      const ignored = runGit(root, ["check-ignore", "-q", relPath]);
      if (ignored.status !== 0) {
        fail(`${relPath}: present in public OSS repo and NOT gitignored; agent infrastructure must stay local-only per OPERATING_MODEL Public OSS posture`);
      } else {
        pass(`${relPath}: public OSS local agent infrastructure is gitignored`);
      }
    }
  }
  pass("entrypoints checked: AGENTS.md required, agent-specific files optional, public-OSS exclusions enforced");
}

function validateWorkspaceLayout() {
  const allowedTopLevel = allowedTopLevelForCurrentLayout();
  const entries = fs.readdirSync(workspaceRoot, { withFileTypes: true });
  const unmanaged = [];
  for (const entry of entries) {
    if (!allowedTopLevel.has(entry.name)) unmanaged.push(entry.name);
  }
  if (unmanaged.length > 0) {
    warn(`unmanaged top-level entries: ${unmanaged.sort().join(", ")}. Declare fleet-owned paths in your policy repo workspace-layout doc and agents/scripts/preflight-config.json, then propagate, or move via approved migration spec.`);
  } else {
    pass("top-level workspace layout: all entries classified");
  }
}

function validateToolPresence() {
  const codex = spawnSync("codex", ["--version"], { encoding: "utf8" });
  if (codex.status === 0) pass(`codex: ${codex.stdout.trim() || "available"}`);
  else warn("codex --version did not run; codex app-server check may fail later");
}

validateEntrypoints();
validateWorkspaceLayout();
validateSkillFrontmatter();
validateMcpExamples();
validateLocalMcpConfig();
validateGitIgnorePolicy();
validateToolPresence();

for (const message of passed) console.log(`ok: ${message}`);
for (const message of warnings) console.warn(`warn: ${message}`);
if (failures.length > 0) {
  for (const message of failures) console.error(`fail: ${message}`);
  process.exit(1);
}
console.log(`preflight passed with ${warnings.length} warning(s).`);
