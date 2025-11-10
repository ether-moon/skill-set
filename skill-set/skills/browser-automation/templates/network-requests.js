#!/usr/bin/env node
/**
 * Capture network requests from a page
 * Usage: node network-requests.js <url>
 */

const { chromium } = require('playwright');

const url = process.argv[2];

if (!url) {
  console.error('Error: URL is required');
  console.error('Usage: node network-requests.js <url>');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const requests = [];

  // Listen to network requests
  page.on('request', request => {
    requests.push({
      method: request.method(),
      url: request.url(),
      resourceType: request.resourceType(),
      headers: request.headers()
    });
  });

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });

    console.log('\nNetwork Requests:');
    console.log(JSON.stringify(requests, null, 2));
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
