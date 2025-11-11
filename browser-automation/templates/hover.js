#!/usr/bin/env node
/**
 * Hover over an element
 * Usage: node hover.js <url> <selector>
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const selector = process.argv[3];

if (!url || !selector) {
  console.error('Error: URL and selector are required');
  console.error('Usage: node hover.js <url> <selector>');
  console.error('Example: node hover.js https://example.com ".menu-item"');
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

    console.log(`Hovering over: ${selector}`);
    await page.hover(selector);

    console.log('Hover successful');
    await page.waitForTimeout(3000); // Wait to see the hover effect
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
