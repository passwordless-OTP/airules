# Git/GitHub Automation Rules - AUTOMATE OR DIE

This directory contains automation-first approaches to Git/GitHub workflows. Zero manual work, maximum efficiency.

## Core Philosophy: AUTOMATE OR DIE

1. **GitHub Projects = Single Source of Truth**
   - Issues auto-create project items
   - PRs auto-link to issues
   - Deployments auto-update status

2. **GitHub Actions = Your Robot Army**
   - Every repetitive task must be automated
   - If you do it twice, automate it
   - If it can fail, add monitoring

3. **Integration is Everything**
   - Slack notifications for everything
   - Auto-assign reviewers
   - Auto-merge when checks pass
   - Auto-deploy on merge

## Quick Access

```bash
# Project management automation
./tools/bin/airules git-github/project-management/github-projects.md

# CI/CD workflows
./tools/bin/airules git-github/workflows/

# Automation scripts
./tools/bin/airules git-github/automation/

# Branch strategies
./tools/bin/airules git-github/branch-strategies/
```

## The Automation Mandate

**If a human does it more than once, a robot should do it forever.**

Examples:
- PR descriptions auto-generated from commits
- Issues auto-labeled based on content
- Releases auto-created from merged PRs
- Changelogs auto-generated
- Dependencies auto-updated
- Tests auto-run
- Deployments auto-triggered

**NO EXCUSES. AUTOMATE OR GET REPLACED.**