# Browser Automation Templates

This directory contains 19 ready-to-use Playwright automation templates that work like MCP tools.

## Setup

First time only, in the skill directory:
```bash
cd ~/.claude/skills/browser-automation
npm install playwright
npx playwright install chromium
```

## Quick Start

All templates follow the pattern:
```bash
node ~/.claude/skills/browser-automation/templates/<template-name>.js <arguments>
```

No need to `cd` to the skill directory - use absolute paths from anywhere.

**Output files**: Screenshots, PDFs, and other generated files are saved to `./tmp/playwright/` in your current working directory by default. The directory is created automatically if it doesn't exist.

## Templates by Category

### Browser Control

**Navigate to URL**
```bash
node ~/.claude/skills/browser-automation/templates/navigate.js https://example.com
```

**Navigate back**
```bash
node ~/.claude/skills/browser-automation/templates/navigate-back.js https://example.com
```

**Resize window**
```bash
node ~/.claude/skills/browser-automation/templates/resize.js https://example.com 1920 1080
```

### Page Information

**Take screenshot**
```bash
node ~/.claude/skills/browser-automation/templates/screenshot.js https://example.com
# Output: ./tmp/playwright/screenshot.png

# Custom path
node ~/.claude/skills/browser-automation/templates/screenshot.js https://example.com ./tmp/playwright/custom.png
```

**Capture accessibility snapshot**
```bash
node ~/.claude/skills/browser-automation/templates/snapshot.js https://example.com
```

**Get console messages**
```bash
node ~/.claude/skills/browser-automation/templates/console-messages.js https://example.com
```

**Get network requests**
```bash
node ~/.claude/skills/browser-automation/templates/network-requests.js https://example.com
```

**Generate PDF**
```bash
node ~/.claude/skills/browser-automation/templates/pdf.js https://example.com
# Output: ./tmp/playwright/page.pdf

# Custom path
node ~/.claude/skills/browser-automation/templates/pdf.js https://example.com ./tmp/playwright/custom.pdf
```

### User Interactions

**Click element**
```bash
node ~/.claude/skills/browser-automation/templates/click.js https://example.com "button:has-text('Submit')"
```

**Fill form field**
```bash
node ~/.claude/skills/browser-automation/templates/fill.js https://example.com "input[name='email']" "test@example.com"
```

**Hover over element**
```bash
node ~/.claude/skills/browser-automation/templates/hover.js https://example.com ".menu-item"
```

**Drag and drop**
```bash
node ~/.claude/skills/browser-automation/templates/drag.js https://example.com "#source" "#target"
```

**Press keyboard key**
```bash
node ~/.claude/skills/browser-automation/templates/press-key.js https://example.com Enter
```
Common keys: Enter, Escape, ArrowDown, ArrowUp, Tab, Space

**Select dropdown option**
```bash
node ~/.claude/skills/browser-automation/templates/select.js https://example.com "select[name='country']" "US"
```

### Form Handling

**Fill multiple form fields**
```bash
node ~/.claude/skills/browser-automation/templates/fill-form.js https://example.com '{"input[name=email]":"test@example.com","input[name=name]":"John"}'
```

**Upload file**
```bash
node ~/.claude/skills/browser-automation/templates/file-upload.js https://example.com "input[type=file]" "./tmp/playwright/upload.pdf"
```

### Advanced

**Evaluate JavaScript**
```bash
node ~/.claude/skills/browser-automation/templates/evaluate.js https://example.com "document.title"
```

**Handle dialogs**
```bash
# Accept alert/confirm
node ~/.claude/skills/browser-automation/templates/handle-dialog.js https://example.com accept

# Accept prompt with text
node ~/.claude/skills/browser-automation/templates/handle-dialog.js https://example.com accept "My Input"

# Dismiss dialog
node ~/.claude/skills/browser-automation/templates/handle-dialog.js https://example.com dismiss
```

**Wait for element**
```bash
node ~/.claude/skills/browser-automation/templates/wait-for.js https://example.com ".loaded" 10000
```

## Selector Tips

Use stable, semantic selectors:
- ✅ Text-based: `"button:has-text('Submit')"`
- ✅ Role-based: `"role=button[name='Submit']"`
- ⚠️ Data attributes: `"[data-testid='submit-btn']"`
- ❌ CSS classes: `".btn-primary"` (fragile)

## Troubleshooting

**Module not found**
```bash
cd $SKILL_DIR && npm install playwright
```

**Browser not found**
```bash
npx playwright install chromium
```

**Element not found**
- Use more specific selectors
- Increase timeout: `node templates/wait-for.js <url> <selector> 30000`
- Check if element appears after page load

## Complete Reference

See individual template files for detailed usage and examples. Each template includes usage instructions in its header comment.
