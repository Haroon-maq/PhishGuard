// Listen for navigation events
safari.application.addEventListener("navigate", handleNavigation, true);

function handleNavigation(event) {
    const url = event.target.url;
    
    // Skip if no URL or if it's a chrome:// URL
    if (!url || url.startsWith("chrome://")) {
        return;
    }
    
    // Send URL to native app for scanning
    safari.extension.dispatchMessage("scanURL", { url: url });
}

// Listen for messages from the native app
safari.application.addEventListener("message", handleMessage, false);

function handleMessage(event) {
    if (event.name === "scanResult") {
        const result = event.message;
        
        if (result.error) {
            console.error("Error scanning URL:", result.error);
            return;
        }
        
        // Show warning if URL is unsafe
        if (!result.isSafe) {
            showWarning(result);
        }
    }
}

function showWarning(result) {
    // Create warning overlay
    const overlay = document.createElement("div");
    overlay.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.8);
        z-index: 999999;
        display: flex;
        justify-content: center;
        align-items: center;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    `;
    
    // Create warning content
    const content = document.createElement("div");
    content.style.cssText = `
        background-color: #1a1a1a;
        padding: 20px;
        border-radius: 10px;
        max-width: 400px;
        text-align: center;
        color: white;
    `;
    
    // Add warning icon
    const icon = document.createElement("div");
    icon.style.cssText = `
        font-size: 48px;
        margin-bottom: 20px;
        color: #ff4444;
    `;
    icon.textContent = "⚠️";
    
    // Add warning text
    const text = document.createElement("div");
    text.style.cssText = `
        margin-bottom: 20px;
        line-height: 1.5;
    `;
    text.innerHTML = `
        <h2 style="color: #ff4444; margin: 0 0 10px 0;">Security Warning</h2>
        <p>This website has been flagged as potentially unsafe:</p>
        <p>Malicious: ${result.malicious} | Suspicious: ${result.suspicious}</p>
    `;
    
    // Add buttons
    const buttons = document.createElement("div");
    buttons.style.cssText = `
        display: flex;
        gap: 10px;
        justify-content: center;
    `;
    
    const backButton = document.createElement("button");
    backButton.style.cssText = `
        padding: 10px 20px;
        background-color: #333;
        color: white;
        border: none;
        border-radius: 5px;
        cursor: pointer;
    `;
    backButton.textContent = "Go Back";
    backButton.onclick = () => window.history.back();
    
    const proceedButton = document.createElement("button");
    proceedButton.style.cssText = `
        padding: 10px 20px;
        background-color: #ff4444;
        color: white;
        border: none;
        border-radius: 5px;
        cursor: pointer;
    `;
    proceedButton.textContent = "Proceed Anyway";
    proceedButton.onclick = () => overlay.remove();
    
    // Assemble the warning
    buttons.appendChild(backButton);
    buttons.appendChild(proceedButton);
    content.appendChild(icon);
    content.appendChild(text);
    content.appendChild(buttons);
    overlay.appendChild(content);
    
    // Add to page
    document.body.appendChild(overlay);
} 