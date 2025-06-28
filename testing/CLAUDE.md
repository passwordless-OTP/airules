# Testing Guidelines for Claude Code

This directory contains comprehensive testing patterns and best practices for different types of tests across various technology stacks.

## Testing Categories

### 1. Unit Tests (`/unit`)
- Testing individual functions and components in isolation
- Mocking external dependencies
- Fast execution, run frequently

### 2. Integration Tests (`/integration`)
- Testing interactions between multiple components
- Database and API integration testing
- Moderate execution time

### 3. End-to-End Tests (`/e2e`)
- Testing complete user workflows
- Browser automation testing
- Slower execution, run before deployments

### 4. Performance Tests (`/performance`)
- Load testing patterns
- Stress testing configurations
- Performance benchmarking

## Quick Access

```bash
# View unit testing patterns
./tools/bin/airules testing/unit/patterns.md

# View integration testing guides
./tools/bin/airules testing/integration/database-testing.md

# View E2E testing frameworks
./tools/bin/airules testing/e2e/playwright-guide.md

# View performance testing tools
./tools/bin/airules testing/performance/load-testing.md
```

## Technology-Specific Testing

Each subdirectory contains testing patterns for:
- PHP Laravel (PHPUnit, Pest)
- Node.js (Jest, Mocha, Vitest)
- React (React Testing Library, Enzyme)
- Shopify Apps (App Bridge testing)
- API Testing (Postman, REST Client)
- Database Testing (Transactions, Fixtures)

## Core Testing Principles

1. **Test Pyramid**
   - Many unit tests (fast, isolated)
   - Some integration tests (component interactions)
   - Few E2E tests (critical user paths)

2. **Test Organization**
   - Group by feature, not by type
   - Clear naming conventions
   - Consistent file structure

3. **Test Quality**
   - Each test should test one thing
   - Tests should be independent
   - Use descriptive test names
   - Follow AAA pattern (Arrange, Act, Assert)

4. **Continuous Integration**
   - All tests must pass before merge
   - Run appropriate test suites for changes
   - Maintain fast feedback loops