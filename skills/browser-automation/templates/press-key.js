#!/usr/bin/env node
/**
 * Press a keyboard key
 * Usage: node press-key.js <url> <key>
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const key = process.argv[3];

if (!url || !key) {
  console.error('Error: URL and key are required');
  console.error('Usage: node press-key.js <url> <key>');
  console.error('Example: node press-key.js https://example.com Enter');
  console.error('Common keys: Enter, Escape, ArrowDown, ArrowUp, Tab, Space');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });

    console.log(`Pressing key: ${key}`);
    await page.keyboard.press(key);

    console.log('Key press successful');
    await page.waitForTimeout(2000);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
