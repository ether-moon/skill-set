---
name: browser-automation
description: Automates browser interactions using Playwright CLI and templates - takes screenshots, generates PDFs, clicks elements, fills forms, monitors console/network. Use when testing web pages, automating browser tasks, or when user mentions screenshots, web testing, form automation, or Playwright
allowed-tools: "Bash(npx:*) Bash(node:*) Bash(npm:*)"
---

# Browser Automation

## Overview

Hybrid browser automation using Playwright CLI for simple tasks and templates for complex interactions. Provides efficient automation without MCP server overhead.

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

## Hybrid Approach

### CLI-Native (Simple Tasks)
Use Playwright CLI directly for:
- **Screenshot**: `npx playwright screenshot <url> <filename>`
- **PDF**: `npx playwright pdf <url> <filename>`
- **Open browser**: `npx playwright open <url>` (for manual inspection)

### Templates (Complex Interactions)
Use templates (16 total) for tasks requiring state management, event handling, or multi-step logic:

**User Interactions (6)**
- Click element with wait
- Fill form field with validation
- Hover over element
- Drag and drop
- Press keyboard key
- Select dropdown option

**Form Handling (2)**
- Fill multiple fields (bulk)
- Upload file

**Page Monitoring (3)**
- Capture accessibility snapshot
- Get console messages (event listening)
- Get network requests (event listening)

**Advanced (5)**
- Evaluate JavaScript
- Navigate back with wait
- Resize browser window
- Handle dialogs (alert/confirm/prompt)
- Wait for element with timeout

## Quick Start

First time setup:
```bash
npm install -g playwright
npx playwright install chromium
```

### CLI Examples (Simple Tasks)
```bash
# Screenshot
npx playwright screenshot https://example.com ./tmp/playwright/screenshot.png

# PDF
npx playwright pdf https://example.com ./tmp/playwright/page.pdf

# Open browser for manual inspection
npx playwright open https://example.com
```

### Template Examples (Complex Tasks)
```bash
# Click element (requires wait logic)
node $SKILL_DIR/templates/click.js https://example.com "button:has-text('Submit')"

# Fill form (multiple fields)
node $SKILL_DIR/templates/fill-form.js https://example.com '{"input[name=email]":"test@example.com"}'

# Monitor console (event listening)
node $SKILL_DIR/templates/console-messages.js https://example.com
```

**Important Guidelines:**
- **Prefer CLI first**: Use `npx playwright` for screenshots, PDFs, and simple evaluation
- **Use templates when needed**: Complex interactions, event listening, multi-step logic
- `$SKILL_DIR` is automatically set to the skill's absolute path by Claude
- Never use `cd` before running commands
- Never write inline Playwright code with `node -e` or heredocs

**Note**: Output files are saved to `./tmp/playwright/` in the current project directory by default.

## Troubleshooting

### Playwright Installation Fails

**"npm ERR! code EACCES"**
- Permission issue with global install
- Solution: Use `npx` prefix instead of global install, or fix npm permissions

**"Playwright browsers not installed"**
- Run: `npx playwright install chromium`
- For all browsers: `npx playwright install`

### Browser Not Found

**"browserType.launch: Executable doesn't exist"**
- Browsers not installed after Playwright installation
- Solution: `npx playwright install chromium`

**"Protocol error (Target.createTarget)"**
- Browser crashed or didn't start properly
- Solution: Close other browser instances, retry

### Timeout Issues

**"Timeout 30000ms exceeded"**
- Page or element took too long to load
- Solutions:
  - Increase timeout in template
  - Check network connectivity
  - Verify URL is accessible

**"Element not found"**
- Selector doesn't match any element
- Solutions:
  - Verify selector in browser DevTools
  - Wait for dynamic content to load
  - Check for iframes

### Permission Problems

**"Navigation failed because page crashed"**
- System resource limits
- Solution: Close other applications, increase memory limits

**"net::ERR_CERT_AUTHORITY_INVALID"**
- SSL certificate issue
- Solution: For testing only, add `--ignore-https-errors` flag

### Common Fixes

```bash
# Reinstall Playwright
npm uninstall playwright && npm install playwright
npx playwright install

# Check Playwright version
npx playwright --version

# Run with debug logging
DEBUG=pw:api npx playwright screenshot https://example.com test.png
```

## Documentation

- **Complete usage guide**: See [reference/TEMPLATES.md](reference/TEMPLATES.md)
- **Template reference**: Each template includes usage instructions in file header
