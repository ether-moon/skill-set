#!/usr/bin/env node
/**
 * Navigate to a URL and select an option from a dropdown
 * Usage: node select.js <url> <selector> <value>
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const selector = process.argv[3];
const value = process.argv[4];

if (!url || !selector || !value) {
  console.error('Error: URL, selector, and value are required');
  console.error('Usage: node select.js <url> <selector> <value>');
  console.error('Example: node select.js https://example.com "select[name=\\"country\\"]" "US"');
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

    console.log(`Selecting option: ${value}`);
    await page.selectOption(selector, value);

    console.log('Selection successful');
    await page.waitForTimeout(2000); // Wait to see the result
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
