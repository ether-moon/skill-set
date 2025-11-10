#!/usr/bin/env node
/**
 * Generate PDF from a webpage
 * Usage: node pdf.js <url> [output_path]
 * Default output: ./tmp/playwright/page.pdf
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const url = process.argv[2];
const outputPath = process.argv[3] || './tmp/playwright/page.pdf';

if (!url) {
  console.error('Error: URL is required');
  console.error('Usage: node pdf.js <url> [output_path]');
  console.error('Example: node pdf.js https://example.com ./tmp/playwright/result.pdf');
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

    console.log(`Generating PDF: ${outputPath}`);
    await page.pdf({
      path: outputPath,
      format: 'A4',
      printBackground: true
    });

    console.log('PDF generated successfully');
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
