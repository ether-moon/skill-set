#!/usr/bin/env node
/**
 * Capture accessibility snapshot of a page
 * Usage: node snapshot.js <url>
 */

const { chromium } = require('playwright');

const url = process.argv[2];

if (!url) {
  console.error('Error: URL is required');
  console.error('Usage: node snapshot.js <url>');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });

    console.log('Capturing accessibility snapshot...');
    const snapshot = await page.accessibility.snapshot();

    console.log('\nAccessibility Snapshot:');
    console.log(JSON.stringify(snapshot, null, 2));
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
