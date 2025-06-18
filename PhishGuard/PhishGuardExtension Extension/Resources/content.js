// Fake malicious URLs for testing
const maliciousURLs = [
  "http://localhost:8000",  // Replace with your test server URL
  "https://phishing-example.org",  // Keep as a placeholder, but note it won’t resolve
  "http://example.com"
];

// Check if the current URL is malicious
function checkURL() {
  const currentURL = window.location.href;
  if (maliciousURLs.some(url => currentURL.includes(url))) {
    alert("Warning: This URL is potentially malicious! Proceed with caution.");
  }
}

// Run on page load
window.onload = checkURL;

// Monitor dynamic changes (e.g., single-page apps)
const observer = new MutationObserver(checkURL);
observer.observe(document.body, { childList: true, subtree: true });
