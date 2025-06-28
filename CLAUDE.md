# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a documentation repository containing guidelines and best practices for working with AI assistants. It focuses on:
- ASCII art creation rules and templates
- Claude Code specific patterns and fixes
- Helper tools for accessing documentation

## Key Commands

### Running the airules CLI tool
```bash
# Make the tool executable (if needed)
chmod +x tools/bin/airules

# Show ASCII art basics
./tools/bin/airules ascii

# Show Claude Code rules
./tools/bin/airules claude

# List all available rules
./tools/bin/airules list

# Show specific rule file
./tools/bin/airules ascii-art/tables.md
```

## Repository Structure

The repository is organized into four main areas:

1. **ascii-art/** - Contains all ASCII art creation guidelines:
   - `basics.md` - Fundamental ASCII art rules
   - `tables.md` - Table formatting guidelines
   - `diagrams.md` - Flow charts and architecture diagrams
   - `charts.md` - Bar charts, timelines, Gantt charts
   - `examples/` - Good and bad examples for reference
   - `templates/` - Reusable ASCII templates

2. **claude-code/** - Claude Code specific guidance:
   - `prompts/` - Effective prompting techniques
   - `patterns/` - Common usage patterns
   - `fixes/` - Solutions for common issues

3. **tools/bin/** - Contains the `airules` executable script that provides CLI access to documentation

4. **reference/** - Quick reference guides organized by type (charts, diagrams, tables)

## Development Notes

- This is a static documentation repository with no build process
- The `airules` script is a simple Bash tool that uses `cat` to display markdown files
- No external dependencies or package managers are used
- All content is in Markdown format
- The repository is self-contained and works immediately after cloning

## Adding New Documentation

When adding new documentation:
1. Place markdown files in the appropriate subdirectory
2. Follow the existing naming conventions (lowercase, hyphens for spaces)
3. New files are automatically discoverable by `airules list`
4. Consider adding examples in the `examples/` subdirectories

## Coding Rules for Different Tech Stacks

The repository includes specific coding guidelines for different technology stacks:

1. **coding-rules/shopify-php-laravel/** - Shopify apps with PHP Laravel on Cloudways
   - Laravel best practices for Shopify integration
   - Cloudways deployment and optimization
   - Webhook handling and API rate limiting
   - Database patterns for Shopify data

2. **coding-rules/node-postgres/** - Node.js apps with PostgreSQL on DigitalOcean
   - PostgreSQL connection patterns and security
   - DigitalOcean deployment with PM2
   - Managed database configuration
   - Performance optimization and monitoring

3. **coding-rules/gadget-dev/** - Gadget.dev platform applications
   - Gadget's serverless architecture patterns
   - Model actions and API usage
   - Built-in Shopify integration
   - Frontend patterns with React

Access these rules using:
```bash
./tools/bin/airules coding-rules/shopify-php-laravel/CLAUDE.md
./tools/bin/airules coding-rules/node-postgres/CLAUDE.md
./tools/bin/airules coding-rules/gadget-dev/CLAUDE.md
```

## Testing Guidelines

The repository includes comprehensive testing patterns and best practices:

1. **testing/** - Root directory for all testing guidelines
   - Main testing overview and principles
   
2. **testing/unit/** - Unit testing patterns
   - JavaScript/TypeScript with Jest
   - PHP Laravel with PHPUnit
   - Mocking strategies and test utilities

3. **testing/integration/** - Integration testing
   - Database testing with transactions
   - API integration testing
   - Test data management strategies

4. **testing/e2e/** - End-to-end testing with Playwright
   - **Persistent authentication profiles** to avoid repeated logins
   - Page Object Model patterns
   - Mobile testing strategies
   - Visual regression testing

5. **testing/performance/** - Performance and load testing
   - k6 for load testing
   - Artillery for API performance
   - Database performance testing
   - Memory profiling and monitoring

Access testing guides:
```bash
./tools/bin/airules testing/CLAUDE.md
./tools/bin/airules testing/unit/patterns.md
./tools/bin/airules testing/e2e/playwright-guide.md
./tools/bin/airules testing/performance/load-testing.md
```

## ASCII Art Guidelines for Claude

When creating ASCII art diagrams in ANY codebase, follow these rules:

### Core Principles
1. **Count characters precisely** - Each column must have exact character counts
2. **Use consistent box-drawing characters**: `┌─┬─┐│├─┼─┤└─┴─┘`
3. **Maintain equal padding** in all cells
4. **Test alignment** by checking if vertical lines form straight columns
5. **Never use tabs** - spaces only for consistent rendering

### Standard Table Format
```
┌──────────┬──────────┬──────────┐
│ Header 1 │ Header 2 │ Header 3 │
├──────────┼──────────┼──────────┤
│ Data 1   │ Data 2   │ Data 3   │
└──────────┴──────────┴──────────┘
```

### Flow Diagram Arrows
- Direct flow: `────▶`
- Optional: `- - ▶`
- Emphasized: `═══▶`
- Bidirectional: `◀─▶`

### Alignment Rules
- Text: Left-aligned (`│ Text     │`)
- Numbers: Right-aligned (`│     123 │`)
- Headers: Can be centered (`│  Header  │`)

### What to Avoid
- Bold/italic/colors (not ASCII)
- Mixed character styles in same diagram
- Trailing spaces
- Tab characters

For detailed rules and examples, use: `./tools/bin/airules ascii-art/[topic].md`