import { Octokit } from "@octokit/rest";

/**
 * constants
 */

const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const ISSUE_NUMBER = parseInt(process.env.ISSUE_NUMBER ?? "0", 10);
const ISSUE_BODY = process.env.ISSUE_BODY || "";
const ISSUE_TITLE = process.env.ISSUE_TITLE || "";
const ISSUE_LABELS = process.env.ISSUE_LABELS || "[]";
const REPO_OWNER = process.env.REPO_OWNER || "";
const REPO_NAME = process.env.REPO_NAME || "";
const DRY_RUN = process.env.DRY_RUN === "true";

const ERROR = 84;
const SUCCESS = 0;

/**
 * client
 */

const octokit = new Octokit({ auth: GITHUB_TOKEN });

/**
 * prefix
 */

const LABEL_PREFIX_MAP: Record<string, string> = {
  bug: "fix",
  feature: "feat",
  documentation: "docs",
  "ci/cd": "ci",
  test: "test",
  perf: "perf",
  refactor: "refactor",
  style: "style",
  chore: "chore",
};

/**
 * get the prefix based on labels || chore
 */

function getPrefix(labels: string[]): string {
  const foundLabel = labels.find((label) => LABEL_PREFIX_MAP[label]);
  return foundLabel ? LABEL_PREFIX_MAP[foundLabel] : "chore";
}

/**
 * helpers
 */

function extractFromBody(regex: RegExp, body: string): string {
  const match = body.match(regex);
  return match ? match[1].trim() : "";
}

async function updateTitle(
  octokit: Octokit,
  owner: string,
  repo: string,
  issueNumber: number,
  newTitle: string,
): Promise<void> {
  if (DRY_RUN) {
    console.log(
      `[DRY_RUN] Would update issue #${issueNumber} title to: "${newTitle}"`,
    );
    return;
  }
  await octokit.rest.issues.update({
    owner,
    repo,
    issue_number: issueNumber,
    title: newTitle,
  });
  console.log(`Issue title updated to: ${newTitle}`);
}

async function addLabelIfMissing(
  octokit: Octokit,
  owner: string,
  repo: string,
  issueNumber: number,
  currentLabels: string[],
  context: string,
): Promise<void> {
  if (!currentLabels.includes(context)) {
    if (DRY_RUN) {
      console.log(
        `[DRY_RUN] Would add label: "${context}" to issue #${issueNumber}`,
      );
      return;
    }
    await octokit.rest.issues.addLabels({
      owner,
      repo,
      issue_number: issueNumber,
      labels: [context],
    });
    console.log(`Added label: ${context}`);
  }
}

async function createComment(
  octokit: Octokit,
  owner: string,
  repo: string,
  issueNumber: number,
  message: string,
): Promise<void> {
  if (DRY_RUN) {
    console.log(
      `[DRY_RUN] Would create comment on issue #${issueNumber}: "${message}"`,
    );
    return;
  }
  await octokit.rest.issues.createComment({
    owner,
    repo,
    issue_number: issueNumber,
    body: message,
  });
}

/**
 * update issue title
 */

async function updateIssueTitle(): Promise<number> {
  try {
    const labels: string[] = JSON.parse(ISSUE_LABELS).map(
      (label: { name: string }) => label.name,
    );

    const context = extractFromBody(
      /### Context\s*([\s\S]*?)(?=###|$)/,
      ISSUE_BODY,
    );
    const summary = extractFromBody(
      /### Summary\s*([\s\S]*?)(?=###|$)/,
      ISSUE_BODY,
    );

    if (!context || !summary) {
      console.error("Missing context or summary. Skipping title update.");
      return ERROR;
    }

    if (!REPO_OWNER || !REPO_NAME) {
      console.error("Missing REPO_OWNER or REPO_NAME.");
      return ERROR;
    }

    const prefix = getPrefix(labels);
    const newTitle = `${prefix}(${context}): ${summary}`;

    if (newTitle === ISSUE_TITLE) {
      console.log("Title already matches. No update needed.");
      return SUCCESS;
    }

    await updateTitle(octokit, REPO_OWNER, REPO_NAME, ISSUE_NUMBER, newTitle);
    await addLabelIfMissing(
      octokit,
      REPO_OWNER,
      REPO_NAME,
      ISSUE_NUMBER,
      labels,
      context,
    );
    await createComment(
      octokit,
      REPO_OWNER,
      REPO_NAME,
      ISSUE_NUMBER,
      "Issue title has been automatically updated based on the provided context and summary.",
    );

    return SUCCESS;
  } catch (error) {
    console.error("Error updating issue:", error);
    return ERROR;
  }
}

updateIssueTitle()
  .then((code) => process.exit(code))
  .catch(() => process.exit(ERROR));
