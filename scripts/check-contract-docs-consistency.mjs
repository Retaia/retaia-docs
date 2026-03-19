import { readFileSync } from "node:fs";

const manifestPath = "contracts/api-contracts-v1.required.json";
const openapiPath = "api/openapi/v1.yaml";

const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
const openapi = readFileSync(openapiPath, "utf8");
const failures = [];

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function requireMatch(regex, message) {
  if (!regex.test(openapi)) {
    failures.push(message);
  }
}

function getSchemaBlock(schemaName) {
  const startPattern = new RegExp(`^\\s{4}${escapeRegExp(schemaName)}:\\n`, "m");
  const startMatch = startPattern.exec(openapi);

  if (!startMatch) {
    failures.push(`contract-docs-consistency: missing schema ${schemaName}`);
    return "";
  }

  const start = startMatch.index;
  const nextPattern = /^\s{4}[A-Za-z0-9_]+:\n/gm;
  nextPattern.lastIndex = start + startMatch[0].length;

  const nextMatch = nextPattern.exec(openapi);
  const end = nextMatch ? nextMatch.index : openapi.length;

  return openapi.slice(start, end);
}

for (const path of manifest.paths) {
  requireMatch(
    new RegExp(`^\\s{2}${escapeRegExp(path)}:\\n`, "m"),
    `contract-docs-consistency: missing path ${path} in ${openapiPath}`
  );
}

for (const [schemaName, schemaRules] of Object.entries(manifest.schemas)) {
  const block = getSchemaBlock(schemaName);

  if (!block) {
    continue;
  }

  for (const propertyName of schemaRules.properties ?? []) {
    const propertyPattern = new RegExp(`^\\s{8}${escapeRegExp(propertyName)}:\\n`, "m");
    if (!propertyPattern.test(block)) {
      failures.push(
        `contract-docs-consistency: missing property ${schemaName}.${propertyName} in ${openapiPath}`
      );
    }
  }
}

if (failures.length > 0) {
  for (const failure of failures) {
    console.error(failure);
  }
  process.exit(1);
}

console.log("contract-docs-consistency: OK");
