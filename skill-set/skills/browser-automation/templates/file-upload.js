#!/usr/bin/env node
/**
 * Upload a file
 * Usage: node file-upload.js <url> <file_input_selector> <file_path>
 */

const { chromium } = require('playwright');
const fs = require('fs');

const url = process.argv[2];
const selector = process.argv[3];
const filePath = process.argv[4];

if (!url || !selector || !filePath) {
  console.error('Error: URL, selector, and file path are required');
  console.error('Usage: node file-upload.js <url> <file_input_selector> <file_path>');
  console.error('Example: node file-upload.js https://example.com "input[type=file]" "/tmp/upload.pdf"');
  process.exit(1);
}

if (!fs.existsSync(filePath)) {
  console.error(`Error: File not found: ${filePath}`);
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });

    console.log(`Waiting for file input: ${selector}`);
    await page.waitForSelector(selector, { timeout: 10000 });

    console.log(`Uploading file: ${filePath}`);
    await page.setInputFiles(selector, filePath);

    console.log('File upload successful');
    await page.waitForTimeout(2000);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
