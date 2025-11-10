#!/usr/bin/env node
/**
 * Navigate to a URL
 * Usage: node navigate.js <url>
 */

const { chromium } = require('playwright');

const url = process.argv[2];

if (!url) {
  console.error('Error: URL is required');
  console.error('Usage: node navigate.js <url>');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url);
    const title = await page.title();
    console.log(`Page title: ${title}`);
    console.log('Navigation successful');
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
