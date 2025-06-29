# Automated Git Flow - Branch Strategy That Works

## Branch Protection Rules (ENFORCE AUTOMATICALLY)

```yaml
# .github/branch-protection.yml
# Apply via GitHub API or Terraform
protection_rules:
  main:
    required_reviews: 2
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
    required_status_checks:
      - "test-backend"
      - "test-frontend"
      - "security-scan"
    enforce_admins: true
    restrictions: null
    allow_force_pushes: false
    allow_deletions: false
    
  develop:
    required_reviews: 1
    dismiss_stale_reviews: true
    required_status_checks:
      - "test-backend"
      - "test-frontend"
    enforce_admins: false
    
  "release/*":
    required_reviews: 2
    required_status_checks:
      - "test-backend"
      - "test-frontend"
      - "e2e-tests"
    restrictions:
      users: ["release-manager"]
```

## Automated Branch Creation

### Feature Branches from Issues
```yaml
# .github/workflows/create-feature-branch.yml
name: Create Feature Branch
on:
  issues:
    types: [assigned]

jobs:
  create-branch:
    if: contains(github.event.issue.labels.*.name, 'ready-for-development')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Create branch
        run: |
          BRANCH_NAME="feature/${{ github.event.issue.number }}-$(echo "${{ github.event.issue.title }}" | tr ' ' '-' | tr -cd '[:alnum:]-' | tr '[:upper:]' '[:lower:]' | cut -c1-50)"
          
          git checkout -b "$BRANCH_NAME"
          git push origin "$BRANCH_NAME"
          
      - name: Update issue
        uses: actions/github-script@v6
        with:
          script: |
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: `Branch created: \`${process.env.BRANCH_NAME}\`
              
              \`\`\`bash
              git fetch origin
              git checkout ${process.env.BRANCH_NAME}
              \`\`\``
            });
```

### Release Branch Automation
```yaml
# .github/workflows/create-release-branch.yml
name: Create Release Branch
on:
  schedule:
    - cron: '0 9 * * 1' # Every Monday at 9 AM
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version'
        required: true

jobs:
  create-release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          ref: develop
          
      - name: Determine version
        id: version
        run: |
          if [ -n "${{ inputs.version }}" ]; then
            VERSION="${{ inputs.version }}"
          else
            # Auto-increment version
            LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
            VERSION=$(echo $LAST_TAG | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g')
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          
      - name: Create release branch
        run: |
          git checkout -b "release/${{ steps.version.outputs.version }}"
          
          # Update version in files
          npm version ${{ steps.version.outputs.version }} --no-git-tag-version
          
          git add .
          git commit -m "chore: bump version to ${{ steps.version.outputs.version }}"
          git push origin "release/${{ steps.version.outputs.version }}"
          
      - name: Create PR
        uses: actions/github-script@v6
        with:
          script: |
            const pr = await github.rest.pulls.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `Release ${{ steps.version.outputs.version }}`,
              head: `release/${{ steps.version.outputs.version }}`,
              base: 'main',
              body: `## Release ${{ steps.version.outputs.version }}
              
              ### Checklist
              - [ ] All tests passing
              - [ ] Documentation updated
              - [ ] CHANGELOG.md updated
              - [ ] Version bumped
              
              ### Included Changes
              _Auto-generated list of changes will appear here_`
            });
            
            // Auto-generate changelog
            const commits = await github.rest.repos.compareCommits({
              owner: context.repo.owner,
              repo: context.repo.repo,
              base: 'main',
              head: `release/${{ steps.version.outputs.version }}`
            });
            
            const changelog = commits.data.commits
              .map(c => `- ${c.commit.message}`)
              .join('\n');
              
            await github.rest.pulls.update({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: pr.data.number,
              body: pr.data.body.replace('_Auto-generated list of changes will appear here_', changelog)
            });
```

## Auto-Merge Strategies

### Develop to Feature Sync
```yaml
# .github/workflows/sync-branches.yml
name: Sync Feature Branches
on:
  push:
    branches: [develop]

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
          
      - name: Get feature branches
        id: branches
        run: |
          BRANCHES=$(git branch -r | grep 'origin/feature/' | sed 's/origin\///')
          echo "branches=$BRANCHES" >> $GITHUB_OUTPUT
          
      - name: Create sync PRs
        uses: actions/github-script@v6
        with:
          script: |
            const branches = '${{ steps.branches.outputs.branches }}'.split('\n').filter(Boolean);
            
            for (const branch of branches) {
              try {
                const pr = await github.rest.pulls.create({
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  title: `🔄 Sync develop into ${branch}`,
                  head: 'develop',
                  base: branch,
                  body: 'Auto-sync from develop branch to prevent conflicts'
                });
                
                // Auto-merge if no conflicts
                await github.rest.pulls.merge({
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  pull_number: pr.data.number,
                  merge_method: 'merge'
                });
              } catch (error) {
                console.log(`Conflict in ${branch}, manual intervention needed`);
              }
            }
```

### Hotfix Automation
```yaml
# .github/workflows/hotfix.yml
name: Hotfix Flow
on:
  workflow_dispatch:
    inputs:
      issue_number:
        description: 'Issue number for hotfix'
        required: true

jobs:
  create-hotfix:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          ref: main
          
      - name: Create hotfix branch
        run: |
          BRANCH="hotfix/${{ inputs.issue_number }}"
          git checkout -b "$BRANCH"
          git push origin "$BRANCH"
          
      - name: Create PRs
        uses: actions/github-script@v6
        with:
          script: |
            // PR to main
            const mainPR = await github.rest.pulls.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `🚑 Hotfix #${{ inputs.issue_number }}`,
              head: `hotfix/${{ inputs.issue_number }}`,
              base: 'main',
              body: `Fixes #${{ inputs.issue_number }}`
            });
            
            // PR to develop
            const developPR = await github.rest.pulls.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `🚑 Hotfix #${{ inputs.issue_number }} (backport)`,
              head: `hotfix/${{ inputs.issue_number }}`,
              base: 'develop',
              body: `Backport of hotfix #${{ inputs.issue_number }}`
            });
```

## Automated Cleanup

### Delete Merged Branches
```yaml
# .github/workflows/cleanup-branches.yml
name: Cleanup Branches
on:
  pull_request:
    types: [closed]
  schedule:
    - cron: '0 0 * * 0' # Weekly

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Delete merged branch
        if: github.event.pull_request.merged == true
        run: |
          git push origin --delete ${{ github.event.pull_request.head.ref }}
          
      - name: Clean old branches
        if: github.event_name == 'schedule'
        run: |
          # Delete branches with no activity for 30 days
          for branch in $(git for-each-ref --format='%(refname:short) %(committerdate:unix)' refs/remotes/origin | awk '$2 < '"$(date -d '30 days ago' '+%s')"' {print $1}' | sed 's/origin\///'); do
            if [[ "$branch" =~ ^(feature|bugfix)/ ]]; then
              echo "Deleting old branch: $branch"
              git push origin --delete "$branch"
            fi
          done
```

## Branch Naming Enforcement

```yaml
# .github/workflows/branch-naming.yml
name: Enforce Branch Naming
on:
  create:

jobs:
  check-branch-name:
    if: github.ref_type == 'branch'
    runs-on: ubuntu-latest
    steps:
      - name: Check branch name
        run: |
          BRANCH=${GITHUB_REF#refs/heads/}
          VALID_PATTERN="^(main|develop|(feature|bugfix|hotfix|release)\/[a-z0-9.-]+)$"
          
          if ! [[ "$BRANCH" =~ $VALID_PATTERN ]]; then
            echo "❌ Invalid branch name: $BRANCH"
            echo "Branch names must match: $VALID_PATTERN"
            exit 1
          fi
          
      - name: Check issue reference
        if: startsWith(github.ref, 'refs/heads/feature/') || startsWith(github.ref, 'refs/heads/bugfix/')
        run: |
          BRANCH=${GITHUB_REF#refs/heads/}
          if ! [[ "$BRANCH" =~ [0-9]+ ]]; then
            echo "❌ Feature/bugfix branches must reference an issue number"
            exit 1
          fi
```

## Commit Message Automation

### Enforce Conventional Commits
```yaml
# .github/workflows/commit-lint.yml
name: Commit Lint
on:
  pull_request:

jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
          
      - name: Lint commits
        uses: wagoid/commitlint-github-action@v5
        with:
          configFile: '.commitlintrc.json'
```

```json
// .commitlintrc.json
{
  "extends": ["@commitlint/config-conventional"],
  "rules": {
    "type-enum": [
      2,
      "always",
      [
        "feat",
        "fix",
        "docs",
        "style",
        "refactor",
        "test",
        "chore",
        "perf",
        "ci"
      ]
    ],
    "subject-case": [2, "always", "lower-case"],
    "header-max-length": [2, "always", 72]
  }
}
```

### Auto-Format Commit Messages
```yaml
# .github/workflows/format-commits.yml
name: Format Commits
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          fetch-depth: 0
          
      - name: Format commits
        run: |
          # Get all commits in PR
          COMMITS=$(git log --format=%H origin/${{ github.base_ref }}..${{ github.head_ref }})
          
          for commit in $COMMITS; do
            MESSAGE=$(git log -1 --format=%s $commit)
            
            # Add issue number if missing
            if [[ ! "$MESSAGE" =~ \#[0-9]+ ]]; then
              ISSUE=$(echo "${{ github.head_ref }}" | grep -oP '\d+' | head -1)
              if [ -n "$ISSUE" ]; then
                NEW_MESSAGE="$MESSAGE (#$ISSUE)"
                git commit --amend -m "$NEW_MESSAGE"
              fi
            fi
          done
          
          git push --force-with-lease
```

## The Branch Strategy Laws

1. **No commits to main** - Everything through PRs
2. **Auto-delete merged branches** - Clean workspace
3. **Auto-sync to prevent conflicts** - Stay updated
4. **Auto-create from issues** - Traceability
5. **Auto-enforce naming** - Consistency
6. **Auto-protect branches** - Safety first

**MANUAL BRANCH MANAGEMENT IS CHAOS. AUTOMATE OR SUFFER.**