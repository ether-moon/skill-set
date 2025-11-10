#!/usr/bin/env node
/**
 * Take a screenshot of a webpage
 * Usage: node screenshot.js <url> [output_path]
 * Default output: ./tmp/playwright/screenshot.png
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const url = process.argv[2];
const outputPath = process.argv[3] || './tmp/playwright/screenshot.png';

if (!url) {
  console.error('Error: URL is required');
  console.error('Usage: node screenshot.js <url> [output_path]');
  console.error('Example: node screenshot.js https://example.com ./tmp/playwright/result.png');
  process.exit(1);
}

// Ensure output directory exists
const outputDir = path.dirname(outputPath);
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });

    console.log(`Taking screenshot: ${outputPath}`);
    await page.screenshot({ path: outputPath, fullPage: true });

    console.log('Screenshot saved successfully');
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
