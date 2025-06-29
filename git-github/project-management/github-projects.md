# GitHub Projects Automation - Task Management That Works

## Project Setup Automation

### 1. Auto-Create Project from Template
```yaml
# .github/workflows/project-setup.yml
name: Auto Project Setup
on:
  repository_dispatch:
    types: [new-sprint]

jobs:
  create-project:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/github-script@v6
        with:
          script: |
            const project = await github.rest.projects.createForRepo({
              owner: context.repo.owner,
              repo: context.repo.repo,
              name: `Sprint ${new Date().toISOString().split('T')[0]}`,
              body: 'Auto-generated sprint project'
            });
            
            // Create columns
            const columns = ['Backlog', 'Ready', 'In Progress', 'Review', 'Done'];
            for (const name of columns) {
              await github.rest.projects.createColumn({
                project_id: project.data.id,
                name
              });
            }
```

### 2. Issue to Project Card Automation
```yaml
# .github/workflows/issue-to-project.yml
name: Auto Add Issues to Project
on:
  issues:
    types: [opened, labeled]

jobs:
  add-to-project:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/add-to-project@v0.5.0
        with:
          project-url: https://github.com/orgs/${{ github.repository_owner }}/projects/1
          github-token: ${{ secrets.PROJECT_TOKEN }}
          labeled: bug, feature, task
          label-operator: OR
```

## Task Automation Rules

### Auto-Assign Based on Labels
```yaml
# .github/CODEOWNERS
# Backend tasks
*.php @backend-team
*.py @backend-team
/api/ @backend-team

# Frontend tasks
*.jsx @frontend-team
*.tsx @frontend-team
/components/ @frontend-team

# Database changes
/migrations/ @database-team
*.sql @database-team
```

### Auto-Label Based on Content
```yaml
# .github/labeler.yml
backend:
  - api/**/*
  - src/services/**/*
  
frontend:
  - src/components/**/*
  - src/pages/**/*
  
database:
  - migrations/**/*
  - seeds/**/*
  
tests:
  - '**/*.test.js'
  - '**/*.spec.js'
  - tests/**/*
```

## GitHub Projects API Automation

### Create Tasks from Code Comments
```javascript
// scripts/todo-to-issues.js
const { Octokit } = require("@octokit/rest");
const glob = require("glob");
const fs = require("fs");

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });

async function scanAndCreateIssues() {
  const files = glob.sync("**/*.{js,jsx,ts,tsx,php,py}", {
    ignore: ["node_modules/**", "vendor/**"]
  });
  
  for (const file of files) {
    const content = fs.readFileSync(file, "utf8");
    const todoRegex = /\/\/\s*TODO\s*(\[[\w-]+\])?\s*:?\s*(.+)/g;
    let match;
    
    while ((match = todoRegex.exec(content)) !== null) {
      const assignee = match[1]?.replace(/[\[\]]/g, "");
      const title = match[2].trim();
      
      // Create issue
      const issue = await octokit.issues.create({
        owner: process.env.GITHUB_OWNER,
        repo: process.env.GITHUB_REPO,
        title: `TODO: ${title}`,
        body: `Found in \`${file}\`\n\nLine: ${content.split('\n').findIndex(l => l.includes(match[0])) + 1}`,
        labels: ["todo", "automated"],
        assignees: assignee ? [assignee] : []
      });
      
      console.log(`Created issue #${issue.data.number}: ${title}`);
    }
  }
}

scanAndCreateIssues();
```

### Sprint Planning Automation
```javascript
// scripts/sprint-planner.js
async function planSprint() {
  // Get all issues with effort labels
  const issues = await octokit.issues.listForRepo({
    owner: process.env.GITHUB_OWNER,
    repo: process.env.GITHUB_REPO,
    labels: 'ready-for-sprint',
    state: 'open',
    per_page: 100
  });
  
  const sprintCapacity = 40; // story points
  let currentCapacity = 0;
  const sprintIssues = [];
  
  // Sort by priority and ROI
  const prioritized = issues.data.sort((a, b) => {
    const aPriority = a.labels.find(l => l.name.startsWith('priority-'))?.name.split('-')[1] || 'low';
    const bPriority = b.labels.find(l => l.name.startsWith('priority-'))?.name.split('-')[1] || 'low';
    return aPriority.localeCompare(bPriority);
  });
  
  // Auto-assign to sprint
  for (const issue of prioritized) {
    const effort = parseInt(issue.labels.find(l => l.name.startsWith('effort-'))?.name.split('-')[1] || '0');
    
    if (currentCapacity + effort <= sprintCapacity) {
      currentCapacity += effort;
      sprintIssues.push(issue);
      
      // Add to current sprint
      await octokit.issues.update({
        owner: process.env.GITHUB_OWNER,
        repo: process.env.GITHUB_REPO,
        issue_number: issue.number,
        milestone: currentSprintNumber
      });
    }
  }
  
  console.log(`Planned ${sprintIssues.length} issues for sprint (${currentCapacity} points)`);
}
```

## Status Automation

### Auto-Move Cards Based on PR Status
```yaml
# .github/workflows/pr-card-automation.yml
name: PR Card Automation
on:
  pull_request:
    types: [opened, ready_for_review, closed]
  pull_request_review:
    types: [submitted]

jobs:
  move-card:
    runs-on: ubuntu-latest
    steps:
      - uses: alex-page/github-project-automation-plus@v0.8.3
        with:
          project: Sprint Board
          column: ${{ 
            github.event.action == 'opened' && 'In Progress' ||
            github.event.action == 'ready_for_review' && 'Review' ||
            github.event.pull_request.merged && 'Done' ||
            'In Progress'
          }}
          repo-token: ${{ secrets.GITHUB_TOKEN }}
```

### Daily Standup Report
```yaml
# .github/workflows/daily-standup.yml
name: Daily Standup Report
on:
  schedule:
    - cron: '0 9 * * 1-5' # 9 AM Mon-Fri

jobs:
  standup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/github-script@v6
        with:
          script: |
            const today = new Date().toISOString().split('T')[0];
            
            // Get yesterday's closed issues
            const closed = await github.rest.issues.listForRepo({
              owner: context.repo.owner,
              repo: context.repo.repo,
              state: 'closed',
              since: new Date(Date.now() - 86400000).toISOString()
            });
            
            // Get in-progress issues
            const inProgress = await github.rest.issues.listForRepo({
              owner: context.repo.owner,
              repo: context.repo.repo,
              labels: 'in-progress'
            });
            
            // Create standup issue
            await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `Daily Standup - ${today}`,
              body: `## Yesterday's Completed
            ${closed.data.map(i => `- [x] #${i.number} ${i.title}`).join('\n')}
            
            ## Today's Focus
            ${inProgress.data.map(i => `- [ ] #${i.number} ${i.title} (@${i.assignee?.login || 'unassigned'})`).join('\n')}
            
            ## Blockers
            _Reply in comments_`,
              labels: ['standup', 'automated']
            });
```

## Deployment Automation

### Auto-Deploy on Issue Close
```yaml
# .github/workflows/deploy-on-close.yml
name: Deploy on Issue Close
on:
  issues:
    types: [closed]

jobs:
  deploy:
    if: contains(github.event.issue.labels.*.name, 'deploy-on-close')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to environment
        run: |
          ENVIRONMENT=$(echo "${{ github.event.issue.title }}" | grep -oP 'deploy to \K\w+' || echo "staging")
          ./scripts/deploy.sh $ENVIRONMENT
          
      - name: Update issue
        uses: actions/github-script@v6
        with:
          script: |
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: '✅ Deployed to ' + process.env.ENVIRONMENT
            });
```

## Metrics & Reporting

### Weekly Velocity Report
```javascript
// scripts/velocity-report.js
async function generateVelocityReport() {
  const weeks = 8; // Last 8 weeks
  const report = [];
  
  for (let i = 0; i < weeks; i++) {
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - (i + 1) * 7);
    const weekEnd = new Date();
    weekEnd.setDate(weekEnd.getDate() - i * 7);
    
    const closed = await octokit.issues.listForRepo({
      owner: process.env.GITHUB_OWNER,
      repo: process.env.GITHUB_REPO,
      state: 'closed',
      since: weekStart.toISOString(),
      until: weekEnd.toISOString()
    });
    
    const points = closed.data.reduce((sum, issue) => {
      const effort = issue.labels.find(l => l.name.startsWith('effort-'));
      return sum + (effort ? parseInt(effort.name.split('-')[1]) : 0);
    }, 0);
    
    report.push({
      week: `Week of ${weekStart.toISOString().split('T')[0]}`,
      issues: closed.data.length,
      points
    });
  }
  
  // Create markdown report
  const markdown = `# Velocity Report

| Week | Issues Closed | Story Points |
|------|---------------|--------------|
${report.map(w => `| ${w.week} | ${w.issues} | ${w.points} |`).join('\n')}

Average velocity: ${Math.round(report.reduce((sum, w) => sum + w.points, 0) / weeks)} points/week
`;
  
  // Create issue with report
  await octokit.issues.create({
    owner: process.env.GITHUB_OWNER,
    repo: process.env.GITHUB_REPO,
    title: `Velocity Report - ${new Date().toISOString().split('T')[0]}`,
    body: markdown,
    labels: ['report', 'automated']
  });
}
```

## Integration Examples

### Slack Integration
```javascript
// .github/actions/slack-notify/index.js
const core = require('@actions/core');
const { WebClient } = require('@slack/web-api');

async function notifySlack() {
  const slack = new WebClient(process.env.SLACK_TOKEN);
  const channel = '#dev-updates';
  
  await slack.chat.postMessage({
    channel,
    blocks: [{
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `*${core.getInput('title')}*\n${core.getInput('message')}`
      }
    }]
  });
}
```

### Jira Sync (if needed)
```yaml
# .github/workflows/jira-sync.yml
name: Sync with Jira
on:
  issues:
    types: [opened, closed]

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Sync to Jira
        env:
          JIRA_URL: ${{ secrets.JIRA_URL }}
          JIRA_TOKEN: ${{ secrets.JIRA_TOKEN }}
        run: |
          # Only sync if issue has 'sync-jira' label
          if [[ "${{ contains(github.event.issue.labels.*.name, 'sync-jira') }}" == "true" ]]; then
            curl -X POST "$JIRA_URL/rest/api/2/issue" \
              -H "Authorization: Bearer $JIRA_TOKEN" \
              -H "Content-Type: application/json" \
              -d '{
                "fields": {
                  "project": {"key": "PROJ"},
                  "summary": "${{ github.event.issue.title }}",
                  "description": "${{ github.event.issue.body }}",
                  "issuetype": {"name": "Task"}
                }
              }'
          fi
```

## The Golden Rules

1. **Every issue must auto-link to a project**
2. **Every PR must auto-link to an issue**
3. **Every merge must auto-update project status**
4. **Every deploy must auto-update issue status**
5. **Every standup must be auto-generated**
6. **Every report must be auto-created**

**REMEMBER: If you're updating a project board manually, you're doing it wrong.**