
const VALID_URLS = [
    "http://127.0.0.1:8080/health",
    "http://localhost:3000/health"
];

async function checkUrl(url) {
    console.log(`\n🔍 Checking: ${url}`);
    try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 2000);

        // Mimic the exact GET request from Resizer.res (no body)
        const res = await fetch(url, {
            method: 'GET',
            headers: {},
            signal: controller.signal
        });
        clearTimeout(timeout);

        console.log(`   Status: ${res.status} ${res.statusText}`);
        const text = await res.text();
        console.log(`   Body: "${text.trim()}"`);

        if (res.ok && text.includes("Remax VTB Backend is running")) {
            console.log("   ✅ SUCCESS");
            return true;
        } else {
            console.log("   ❌ FAILED (Invalid Content or Status)");
            return false;
        }
    } catch (e) {
        console.log(`   ❌ ERROR: ${e.message}`);
        if (e.cause) console.log(`      Cause: ${e.cause}`);
        return false;
    }
}

async function run() {
    console.log("🛠️  Starting Automated Connectivity Diagnosis...");

    const results = [];
    for (const url of VALID_URLS) {
        results.push(await checkUrl(url));
    }

    console.log("\n--- SUMMARY ---");
    console.log(`Direct to Backend (8080): ${results[0] ? "✅ PASS" : "❌ FAIL"}`);
    console.log(`Via Frontend Proxy (3000): ${results[1] ? "✅ PASS" : "❌ FAIL"}`);

    if (results[0] && !results[1]) {
        console.log("\n结论: Backend is UP, but Proxy is BROKEN.");
    } else if (!results[0]) {
        console.log("\n结论: Backend is DOWN or unreachable.");
    } else {
        console.log("\n结论: Both paths work in Node.js. Issue is likely BROWSER SPECIFIC (CORS, Service Worker, etc).");
    }
}

run();
