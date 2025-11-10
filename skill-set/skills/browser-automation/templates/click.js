#!/usr/bin/env node
/**
 * Navigate to a URL and click an element
 * Usage: node click.js <url> <selector>
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const selector = process.argv[3];

if (!url || !selector) {
  console.error('Error: URL and selector are required');
  console.error('Usage: node click.js <url> <selector>');
  console.error('Example: node click.js https://example.com "button:has-text(\\"Submit\\")"');
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

    console.log(`Clicking: ${selector}`);
    await page.click(selector);

    console.log('Click successful');
    await page.waitForTimeout(2000); // Wait to see the result
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
