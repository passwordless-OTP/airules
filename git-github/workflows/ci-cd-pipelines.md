# CI/CD Pipelines - Ship Fast, Break Nothing

## Multi-Environment Pipeline

```yaml
# .github/workflows/ci-cd-pipeline.yml
name: CI/CD Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  NODE_VERSION: '18'
  PHP_VERSION: '8.2'

jobs:
  # Parallel testing for speed
  test-backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
          
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ env.PHP_VERSION }}
          extensions: mbstring, pdo, pdo_pgsql
          coverage: xdebug
          
      - name: Cache dependencies
        uses: actions/cache@v3
        with:
          path: vendor
          key: php-${{ hashFiles('composer.lock') }}
          
      - name: Install dependencies
        run: composer install --no-progress --prefer-dist
        
      - name: Run tests
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test
        run: |
          php artisan migrate --force
          php artisan test --parallel --coverage-xml
          
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
          flags: backend

  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Lint
        run: npm run lint
        
      - name: Type check
        run: npm run type-check
        
      - name: Test
        run: npm run test:ci
        
      - name: Build
        run: npm run build

  e2e-tests:
    needs: [test-backend, test-frontend]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          
      - name: Install dependencies
        run: |
          npm ci
          npx playwright install --with-deps
          
      - name: Run E2E tests
        run: npm run test:e2e
        
      - name: Upload test results
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Trivy security scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
          
      - name: Upload results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  deploy-staging:
    needs: [e2e-tests, security-scan]
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to staging
        env:
          DEPLOY_KEY: ${{ secrets.STAGING_DEPLOY_KEY }}
        run: |
          # Deploy script
          ./scripts/deploy.sh staging
          
      - name: Run smoke tests
        run: |
          npm run test:smoke -- --url https://staging.example.com
          
      - name: Notify Slack
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Staging deployment ${{ job.status }}'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}

  deploy-production:
    needs: [e2e-tests, security-scan]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v3
      
      - name: Create deployment
        uses: actions/github-script@v6
        id: deployment
        with:
          script: |
            const deployment = await github.rest.repos.createDeployment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              ref: context.sha,
              environment: 'production',
              required_contexts: [],
              auto_merge: false
            });
            return deployment.data.id;
            
      - name: Deploy to production
        env:
          DEPLOY_KEY: ${{ secrets.PRODUCTION_DEPLOY_KEY }}
        run: |
          ./scripts/deploy.sh production
          
      - name: Update deployment status
        if: always()
        uses: actions/github-script@v6
        with:
          script: |
            await github.rest.repos.createDeploymentStatus({
              owner: context.repo.owner,
              repo: context.repo.repo,
              deployment_id: ${{ steps.deployment.outputs.result }},
              state: '${{ job.status }}',
              environment_url: 'https://example.com'
            });
```

## Optimized Docker Build

```yaml
# .github/workflows/docker-build.yml
name: Docker Build
on:
  push:
    branches: [main, develop]
    paths:
      - 'Dockerfile'
      - 'package*.json'
      - 'composer.json'
      - '.github/workflows/docker-build.yml'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
        
      - name: Login to registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
          
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:latest
            ghcr.io/${{ github.repository }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            BUILDKIT_INLINE_CACHE=1
```

## Database Migration Pipeline

```yaml
# .github/workflows/database-migrations.yml
name: Database Migrations
on:
  pull_request:
    paths:
      - 'migrations/**'
      - 'database/**'

jobs:
  validate-migrations:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
          
    steps:
      - uses: actions/checkout@v3
      
      - name: Test migration up
        run: |
          npm run migrate:up
          
      - name: Test migration down
        run: |
          npm run migrate:down
          npm run migrate:up
          
      - name: Check for conflicts
        run: |
          # Check if migration numbers conflict
          MIGRATIONS=$(ls migrations/*.sql | wc -l)
          UNIQUE=$(ls migrations/*.sql | cut -d'_' -f1 | sort -u | wc -l)
          if [ "$MIGRATIONS" != "$UNIQUE" ]; then
            echo "Migration number conflict detected!"
            exit 1
          fi
          
      - name: Generate migration report
        run: |
          echo "## Migration Report" > migration-report.md
          echo "### New Migrations" >> migration-report.md
          git diff --name-only origin/${{ github.base_ref }} -- migrations/ >> migration-report.md
          
      - name: Comment PR
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('migration-report.md', 'utf8');
            
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: report
            });
```

## Performance Testing Pipeline

```yaml
# .github/workflows/performance.yml
name: Performance Tests
on:
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * *' # Daily at 2 AM

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v9
        with:
          urls: |
            http://localhost:3000
            http://localhost:3000/products
            http://localhost:3000/checkout
          uploadArtifacts: true
          temporaryPublicStorage: true
          
      - name: Format results
        run: |
          echo "## Lighthouse Results" > lighthouse-results.md
          echo "| URL | Performance | Accessibility | SEO |" >> lighthouse-results.md
          echo "|-----|-------------|---------------|-----|" >> lighthouse-results.md
          # Parse and format results
          
      - name: Comment PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const results = fs.readFileSync('lighthouse-results.md', 'utf8');
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: results
            });

  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run k6 tests
        uses: grafana/k6-action@v0.2.0
        with:
          filename: tests/load/script.js
          flags: --out json=results.json
          
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: k6-results
          path: results.json
```

## Rollback Automation

```yaml
# .github/workflows/rollback.yml
name: Automated Rollback
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to rollback'
        required: true
        type: choice
        options:
          - staging
          - production
      version:
        description: 'Version to rollback to (leave empty for previous)'
        required: false

jobs:
  rollback:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Get rollback version
        id: version
        run: |
          if [ -z "${{ inputs.version }}" ]; then
            # Get previous successful deployment
            VERSION=$(curl -s -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
              "https://api.github.com/repos/${{ github.repository }}/deployments?environment=${{ inputs.environment }}&per_page=2" \
              | jq -r '.[1].ref')
          else
            VERSION="${{ inputs.version }}"
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          
      - name: Rollback deployment
        run: |
          ./scripts/rollback.sh ${{ inputs.environment }} ${{ steps.version.outputs.version }}
          
      - name: Create issue
        uses: actions/github-script@v6
        with:
          script: |
            await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `🔄 Rollback performed on ${{ inputs.environment }}`,
              body: `## Rollback Details
              
**Environment:** ${{ inputs.environment }}
**Rolled back to:** ${{ steps.version.outputs.version }}
**Triggered by:** @${{ github.actor }}
**Time:** ${new Date().toISOString()}

### Action Items
- [ ] Investigate root cause
- [ ] Fix forward
- [ ] Update runbook`,
              labels: ['rollback', 'incident', inputs.environment],
              assignees: [context.actor]
            });
```

## Monitoring Integration

```yaml
# .github/workflows/deploy-monitor.yml
name: Deploy and Monitor
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    outputs:
      deployment_id: ${{ steps.deploy.outputs.deployment_id }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy
        id: deploy
        run: |
          DEPLOYMENT_ID=$(./scripts/deploy.sh production)
          echo "deployment_id=$DEPLOYMENT_ID" >> $GITHUB_OUTPUT
          
  monitor:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - name: Wait for stability
        run: sleep 300 # 5 minutes
        
      - name: Check metrics
        run: |
          # Check error rate
          ERROR_RATE=$(curl -s "https://api.monitoring.com/error-rate?deployment=${{ needs.deploy.outputs.deployment_id }}")
          
          if (( $(echo "$ERROR_RATE > 5" | bc -l) )); then
            echo "High error rate detected: $ERROR_RATE%"
            exit 1
          fi
          
          # Check response time
          RESPONSE_TIME=$(curl -s "https://api.monitoring.com/response-time?deployment=${{ needs.deploy.outputs.deployment_id }}")
          
          if (( $(echo "$RESPONSE_TIME > 1000" | bc -l) )); then
            echo "High response time detected: ${RESPONSE_TIME}ms"
            exit 1
          fi
          
      - name: Auto-rollback on failure
        if: failure()
        run: |
          gh workflow run rollback.yml -f environment=production
```

## The Pipeline Principles

1. **Fail fast** - Catch issues early
2. **Run in parallel** - Speed is king
3. **Cache everything** - Don't repeat work
4. **Monitor post-deploy** - Trust but verify
5. **Rollback automatically** - Self-healing systems
6. **Report everything** - Visibility is power

**MANUAL DEPLOYMENTS ARE DEAD. AUTOMATE OR BE REPLACED.**