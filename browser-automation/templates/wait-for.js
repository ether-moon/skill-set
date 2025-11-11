#!/usr/bin/env node
/**
 * Wait for selector or timeout
 * Usage: node wait-for.js <url> <selector> [timeout_ms]
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const selector = process.argv[3];
const timeout = parseInt(process.argv[4]) || 30000;

if (!url || !selector) {
  console.error('Error: URL and selector are required');
  console.error('Usage: node wait-for.js <url> <selector> [timeout_ms]');
  console.error('Example: node wait-for.js https://example.com ".loaded" 10000');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url);

    console.log(`Waiting for selector: ${selector} (timeout: ${timeout}ms)`);
    await page.waitForSelector(selector, { timeout });

    console.log('Element found!');
    await page.waitForTimeout(2000);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
