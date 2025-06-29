# GitHub Automation Scripts - ZERO MANUAL WORK

## Auto-PR Description Generator

### From Commits
```yaml
# .github/workflows/auto-pr-description.yml
name: Auto PR Description
on:
  pull_request:
    types: [opened]

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
          
      - name: Generate PR Description
        uses: actions/github-script@v6
        with:
          script: |
            const commits = await github.rest.pulls.listCommits({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number
            });
            
            // Extract ticket numbers
            const tickets = [...new Set(commits.data
              .map(c => c.commit.message.match(/\[#(\d+)\]/g))
              .flat()
              .filter(Boolean))];
            
            // Group commits by type
            const grouped = commits.data.reduce((acc, commit) => {
              const type = commit.commit.message.match(/^(\w+):/)?.[1] || 'other';
              acc[type] = acc[type] || [];
              acc[type].push(commit.commit.message);
              return acc;
            }, {});
            
            // Generate description
            const description = `## Summary
            ${context.payload.pull_request.title}
            
            ## Changes
            ${Object.entries(grouped).map(([type, msgs]) => 
              `### ${type.charAt(0).toUpperCase() + type.slice(1)}\n${msgs.map(m => `- ${m}`).join('\n')}`
            ).join('\n\n')}
            
            ## Related Issues
            ${tickets.map(t => `- Fixes ${t}`).join('\n')}
            
            ## Testing
            - [ ] Unit tests pass
            - [ ] Integration tests pass
            - [ ] Manual testing completed
            
            ## Checklist
            - [ ] Code follows style guidelines
            - [ ] Self-review completed
            - [ ] Documentation updated
            `;
            
            await github.rest.pulls.update({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number,
              body: description
            });
```

## Auto-Merge When Ready

```yaml
# .github/workflows/auto-merge.yml
name: Auto Merge
on:
  pull_request_review:
    types: [submitted]
  check_suite:
    types: [completed]
  pull_request:
    types: [labeled]

jobs:
  automerge:
    runs-on: ubuntu-latest
    if: contains(github.event.pull_request.labels.*.name, 'ready-to-merge')
    steps:
      - name: Check conditions
        id: check
        uses: actions/github-script@v6
        with:
          script: |
            const pr = await github.rest.pulls.get({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number
            });
            
            // Check approvals
            const reviews = await github.rest.pulls.listReviews({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number
            });
            
            const approvals = reviews.data.filter(r => r.state === 'APPROVED').length;
            const requiredApprovals = 2;
            
            // Check CI status
            const checks = await github.rest.checks.listForRef({
              owner: context.repo.owner,
              repo: context.repo.repo,
              ref: pr.data.head.sha
            });
            
            const allChecksPassed = checks.data.check_runs.every(
              check => check.conclusion === 'success'
            );
            
            return approvals >= requiredApprovals && allChecksPassed;
            
      - name: Auto merge
        if: steps.check.outputs.result == 'true'
        uses: pascalgn/merge-action@v0.1.1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          MERGE_METHOD: squash
          MERGE_COMMIT_MESSAGE: pull-request-title
```

## Auto-Release Creation

```yaml
# .github/workflows/auto-release.yml
name: Auto Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
          
      - name: Generate Changelog
        id: changelog
        run: |
          # Get commits since last tag
          LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
          if [ -z "$LAST_TAG" ]; then
            COMMITS=$(git log --pretty=format:"- %s" --no-merges)
          else
            COMMITS=$(git log ${LAST_TAG}..HEAD --pretty=format:"- %s" --no-merges)
          fi
          
          # Group by type
          echo "## Changes" > CHANGELOG.md
          echo "" >> CHANGELOG.md
          
          echo "### Features" >> CHANGELOG.md
          echo "$COMMITS" | grep "^- feat:" | sed 's/^- feat: /- /' >> CHANGELOG.md
          
          echo "" >> CHANGELOG.md
          echo "### Bug Fixes" >> CHANGELOG.md
          echo "$COMMITS" | grep "^- fix:" | sed 's/^- fix: /- /' >> CHANGELOG.md
          
          echo "" >> CHANGELOG.md
          echo "### Other Changes" >> CHANGELOG.md
          echo "$COMMITS" | grep -v "^- feat:" | grep -v "^- fix:" >> CHANGELOG.md
          
      - name: Bump version
        id: version
        run: |
          # Determine version bump based on commits
          if echo "$COMMITS" | grep -q "BREAKING CHANGE"; then
            VERSION_BUMP="major"
          elif echo "$COMMITS" | grep -q "^- feat:"; then
            VERSION_BUMP="minor"
          else
            VERSION_BUMP="patch"
          fi
          
          # Get current version
          CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
          
          # Bump version
          IFS='.' read -r -a VERSION_PARTS <<< "${CURRENT_VERSION#v}"
          MAJOR="${VERSION_PARTS[0]}"
          MINOR="${VERSION_PARTS[1]}"
          PATCH="${VERSION_PARTS[2]}"
          
          case $VERSION_BUMP in
            major)
              MAJOR=$((MAJOR + 1))
              MINOR=0
              PATCH=0
              ;;
            minor)
              MINOR=$((MINOR + 1))
              PATCH=0
              ;;
            patch)
              PATCH=$((PATCH + 1))
              ;;
          esac
          
          NEW_VERSION="v${MAJOR}.${MINOR}.${PATCH}"
          echo "new_version=$NEW_VERSION" >> $GITHUB_OUTPUT
          
      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ steps.version.outputs.new_version }}
          release_name: Release ${{ steps.version.outputs.new_version }}
          body_path: CHANGELOG.md
          draft: false
          prerelease: false
```

## Auto-Dependency Updates

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "automated"
    reviewers:
      - "your-team"
    commit-message:
      prefix: "chore"
      
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "github-actions"
      - "automated"
```

### Auto-Merge Dependabot PRs
```yaml
# .github/workflows/auto-merge-dependabot.yml
name: Auto-merge Dependabot
on:
  pull_request:
    types: [opened, synchronize]

permissions:
  contents: write
  pull-requests: write

jobs:
  dependabot:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]'
    steps:
      - name: Enable auto-merge
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Auto-Issue Creation

### From Failed Deployments
```yaml
# .github/workflows/deployment-failure-issue.yml
name: Create Issue on Deploy Failure
on:
  workflow_run:
    workflows: ["Deploy"]
    types: [completed]

jobs:
  on-failure:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'failure' }}
    steps:
      - uses: actions/github-script@v6
        with:
          script: |
            const run = context.payload.workflow_run;
            
            await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `🚨 Deployment Failed: ${run.head_branch}`,
              body: `## Deployment Failure
              
              **Branch:** ${run.head_branch}
              **Commit:** ${run.head_sha}
              **Run:** ${run.html_url}
              **Time:** ${new Date().toISOString()}
              
              ### Action Items
              - [ ] Check deployment logs
              - [ ] Identify root cause
              - [ ] Fix and redeploy
              - [ ] Update runbook if needed
              
              @${run.actor.login} - Please investigate immediately.`,
              labels: ['bug', 'deployment', 'urgent'],
              assignees: [run.actor.login]
            });
```

### From Error Monitoring
```javascript
// scripts/sentry-to-github.js
const SentryWebhook = require('@sentry/webhook');

const webhook = new SentryWebhook({
  onError: async (error) => {
    // Only create issue for new errors
    if (error.isNew) {
      await octokit.issues.create({
        owner: process.env.GITHUB_OWNER,
        repo: process.env.GITHUB_REPO,
        title: `🐛 [Sentry] ${error.title}`,
        body: `## Error Details
        
**Message:** ${error.message}
**Count:** ${error.count}
**Users Affected:** ${error.userCount}
**First Seen:** ${error.firstSeen}
**URL:** ${error.url}

### Stack Trace
\`\`\`
${error.stackTrace}
\`\`\`

### Metadata
${JSON.stringify(error.metadata, null, 2)}
`,
        labels: ['bug', 'production', 'sentry'],
      });
    }
  }
});
```

## Auto-Documentation

### Generate API Docs
```yaml
# .github/workflows/api-docs.yml
name: Generate API Documentation
on:
  push:
    paths:
      - 'api/**'
      - 'src/controllers/**'

jobs:
  generate-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Generate OpenAPI spec
        run: |
          npm run generate:openapi
          
      - name: Generate Markdown docs
        run: |
          npx @redocly/openapi-cli build-docs openapi.json -o docs/api.md
          
      - name: Commit changes
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add docs/api.md
          git commit -m "docs: auto-update API documentation" || exit 0
          git push
```

## The Automation Commandments

1. **Thou shalt not manually update project boards**
2. **Thou shalt not manually write PR descriptions**
3. **Thou shalt not manually create releases**
4. **Thou shalt not manually merge PRs**
5. **Thou shalt not manually create issues from errors**
6. **Thou shalt not manually update dependencies**
7. **Thou shalt not manually generate reports**

**If you're doing it manually, you're stealing time from coding. AUTOMATE OR DIE.**