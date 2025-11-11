#!/usr/bin/env node
/**
 * Navigate to a URL then go back
 * Usage: node navigate-back.js <url>
 */

const { chromium } = require('playwright');

const url = process.argv[2];

if (!url) {
  console.error('Error: URL is required');
  console.error('Usage: node navigate-back.js <url>');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url);
    await page.waitForTimeout(2000);

    console.log('Navigating back...');
    await page.goBack();
    console.log('Back navigation successful');

    await page.waitForTimeout(2000);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
