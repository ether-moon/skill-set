#!/usr/bin/env node
/**
 * Handle dialog (alert, confirm, prompt)
 * Usage: node handle-dialog.js <url> <action> [prompt_text]
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const action = process.argv[3]; // 'accept' or 'dismiss'
const promptText = process.argv[4]; // For prompt dialogs

if (!url || !action) {
  console.error('Error: URL and action are required');
  console.error('Usage: node handle-dialog.js <url> <action> [prompt_text]');
  console.error('Example: node handle-dialog.js https://example.com accept');
  console.error('Example: node handle-dialog.js https://example.com accept "My Input"');
  process.exit(1);
}

if (action !== 'accept' && action !== 'dismiss') {
  console.error('Error: Action must be "accept" or "dismiss"');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  // Set up dialog handler
  page.on('dialog', async dialog => {
    console.log(`Dialog type: ${dialog.type()}`);
    console.log(`Dialog message: ${dialog.message()}`);

    if (action === 'accept') {
      if (dialog.type() === 'prompt' && promptText) {
        console.log(`Accepting with text: ${promptText}`);
        await dialog.accept(promptText);
      } else {
        console.log('Accepting dialog');
        await dialog.accept();
      }
    } else {
      console.log('Dismissing dialog');
      await dialog.dismiss();
    }
  });

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });

    console.log('Page loaded. Dialog handler is active.');
    console.log('Waiting for dialogs...');
    await page.waitForTimeout(5000);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
