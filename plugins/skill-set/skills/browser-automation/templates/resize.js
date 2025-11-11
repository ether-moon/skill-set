#!/usr/bin/env node
/**
 * Resize browser window
 * Usage: node resize.js <url> <width> <height>
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const width = parseInt(process.argv[3]);
const height = parseInt(process.argv[4]);

if (!url || !width || !height) {
  console.error('Error: URL, width, and height are required');
  console.error('Usage: node resize.js <url> <width> <height>');
  console.error('Example: node resize.js https://example.com 1920 1080');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  try {
    console.log(`Setting viewport to ${width}x${height}`);
    await page.setViewportSize({ width, height });

    console.log(`Navigating to: ${url}`);
    await page.goto(url);

    console.log('Resize successful');
    await page.waitForTimeout(3000); // Wait to see the result
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
