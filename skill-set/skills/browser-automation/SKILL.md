---
name: browser-automation
description: Automates browser interactions with 19 Playwright templates - takes screenshots, generates PDFs, clicks elements, fills forms, monitors console/network. Use when testing web pages, automating browser tasks, or when user mentions screenshots, web testing, form automation, or Playwright
---

# Browser Automation

## Overview

MCP-like browser automation using pre-built Playwright templates. Provides 19 ready-to-use scripts for common automation tasks without MCP server overhead.

## When to Use

**Use this skill when you need to:**
- Take screenshots or generate PDFs
- Test web pages or forms
- Click elements or fill inputs
- Monitor console logs or network requests
- Automate browser interactions

**Don't use when:**
- Simple HTTP requests suffice (use fetch/curl)
- Need persistent browser sessions across conversations

## Available Templates

### Browser Control (3)
- Navigate to URL
- Navigate back
- Resize browser window

### Page Information (5)
- Take screenshot
- Capture accessibility snapshot
- Get console messages
- Get network requests
- Generate PDF

### User Interactions (6)
- Click element
- Fill form field
- Hover over element
- Drag and drop
- Press keyboard key
- Select dropdown option

### Form Handling (2)
- Fill multiple fields (bulk)
- Upload file

### Advanced (3)
- Evaluate JavaScript
- Handle dialogs (alert/confirm/prompt)
- Wait for element

## Quick Start

First time setup (in skill directory):
```bash
cd $SKILL_DIR
npm install playwright
npx playwright install chromium
```

Example usage:
```bash
node $SKILL_DIR/templates/screenshot.js https://example.com ./tmp/playwright/screenshot.png
node $SKILL_DIR/templates/click.js https://example.com "button:has-text('Submit')"
```

**Important Guidelines:**
- `$SKILL_DIR` is automatically set to the skill's absolute path by Claude
- Always use `$SKILL_DIR/templates/` prefix for template files
- Never use `cd` before running templates
- Always use the provided template files - never write inline Playwright code with `node -e` or heredocs
- If a template doesn't exist for your use case, combine multiple templates or use the evaluate.js template for custom JavaScript

**Note**: Output files (screenshots, PDFs, etc.) are saved to `./tmp/playwright/` in the current project directory by default.

## Documentation

- **Complete usage guide**: See [reference/TEMPLATES.md](reference/TEMPLATES.md)
- **Template reference**: Each template includes usage instructions in file header
