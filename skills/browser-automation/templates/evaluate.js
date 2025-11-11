#!/usr/bin/env node
/**
 * Evaluate JavaScript on a page
 * Usage: node evaluate.js <url> <script>
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const script = process.argv[3];

if (!url || !script) {
  console.error('Error: URL and script are required');
  console.error('Usage: node evaluate.js <url> <script>');
  console.error('Example: node evaluate.js https://example.com "document.title"');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });

    console.log(`Evaluating: ${script}`);
    const result = await page.evaluate(script);

    console.log('\nResult:');
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
