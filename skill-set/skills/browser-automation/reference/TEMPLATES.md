# Browser Automation Reference

Hybrid approach using Playwright CLI for simple tasks and templates for complex interactions.

## Setup

First time only:
```bash
npm install -g playwright
npx playwright install chromium
```

## CLI-First Approach

**Always prefer CLI** for these simple tasks:

### Screenshot
```bash
npx playwright screenshot <url> <filename>

# Example
npx playwright screenshot https://example.com ./tmp/playwright/screenshot.png
```

### PDF Generation
```bash
npx playwright pdf <url> <filename>

# Example
npx playwright pdf https://example.com ./tmp/playwright/page.pdf
```

### Open Browser (Manual Inspection)
```bash
npx playwright open <url>

# Example - opens browser for manual testing
npx playwright open https://example.com
```

---

## Templates for Complex Tasks

Use templates when you need state management, event listening, or multi-step logic.

**Pattern**: `node $SKILL_DIR/templates/<template-name>.js <arguments>`

**Output files**: Generated files are saved to `./tmp/playwright/` by default.

### Page Monitoring

**Capture accessibility snapshot**
```bash
node $SKILL_DIR/templates/snapshot.js https://example.com
```

**Get console messages** (requires event listening)
```bash
node $SKILL_DIR/templates/console-messages.js https://example.com
```

**Get network requests** (requires event listening)
```bash
node $SKILL_DIR/templates/network-requests.js https://example.com
```

### Browser Control

**Navigate back** (with wait logic)
```bash
node $SKILL_DIR/templates/navigate-back.js https://example.com
```

**Resize window**
```bash
node $SKILL_DIR/templates/resize.js https://example.com 1920 1080
```

### User Interactions

**Click element**
```bash
node $SKILL_DIR/templates/click.js https://example.com "button:has-text('Submit')"
```

**Fill form field**
```bash
node $SKILL_DIR/templates/fill.js https://example.com "input[name='email']" "test@example.com"
```

**Hover over element**
```bash
node $SKILL_DIR/templates/hover.js https://example.com ".menu-item"
```

**Drag and drop**
```bash
node $SKILL_DIR/templates/drag.js https://example.com "#source" "#target"
```

**Press keyboard key**
```bash
node $SKILL_DIR/templates/press-key.js https://example.com Enter
```
Common keys: Enter, Escape, ArrowDown, ArrowUp, Tab, Space

**Select dropdown option**
```bash
node $SKILL_DIR/templates/select.js https://example.com "select[name='country']" "US"
```

### Form Handling

**Fill multiple form fields**
```bash
node $SKILL_DIR/templates/fill-form.js https://example.com '{"input[name=email]":"test@example.com","input[name=name]":"John"}'
```

**Upload file**
```bash
node $SKILL_DIR/templates/file-upload.js https://example.com "input[type=file]" "./tmp/playwright/upload.pdf"
```

### Advanced

**Evaluate JavaScript**
```bash
node $SKILL_DIR/templates/evaluate.js https://example.com "document.title"

# Examples
node $SKILL_DIR/templates/evaluate.js https://example.com "document.querySelectorAll('a').length"
node $SKILL_DIR/templates/evaluate.js https://example.com "Array.from(document.querySelectorAll('h1')).map(h => h.textContent)"
```

**Handle dialogs**
```bash
# Accept alert/confirm
node $SKILL_DIR/templates/handle-dialog.js https://example.com accept

# Accept prompt with text
node $SKILL_DIR/templates/handle-dialog.js https://example.com accept "My Input"

# Dismiss dialog
node $SKILL_DIR/templates/handle-dialog.js https://example.com dismiss
```

**Wait for element**
```bash
node $SKILL_DIR/templates/wait-for.js https://example.com ".loaded" 10000
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
