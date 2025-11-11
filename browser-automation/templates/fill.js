#!/usr/bin/env node
/**
 * Navigate to a URL and fill a form field
 * Usage: node fill.js <url> <selector> <text>
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const selector = process.argv[3];
const text = process.argv[4];

if (!url || !selector || !text) {
  console.error('Error: URL, selector, and text are required');
  console.error('Usage: node fill.js <url> <selector> <text>');
  console.error('Example: node fill.js https://example.com "input[name=\\"email\\"]" "test@example.com"');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });

    console.log(`Waiting for selector: ${selector}`);
    await page.waitForSelector(selector, { timeout: 10000 });

    console.log(`Filling: ${selector} with "${text}"`);
    await page.fill(selector, text);

    console.log('Fill successful');
    await page.waitForTimeout(2000); // Wait to see the result
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
