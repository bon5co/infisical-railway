// Seed the Infisical instance administrator over loopback, before the public
// listener exists. Upstream exposes POST /api/v1/admin/bootstrap with no
// authentication: it refuses only once the instance is already initialised, so
// on a public URL the first stranger to call it becomes superAdmin. Calling it
// ourselves during boot closes that window permanently.
const base = `http://127.0.0.1:${process.env.INFISICAL_BOOT_PORT}`;
const email = process.env.INFISICAL_ADMIN_EMAIL;
const password = process.env.INFISICAL_ADMIN_PASSWORD;
const organization = process.env.INFISICAL_ORG_NAME || "Admin Org";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function waitReady(timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(`${base}/api/status`);
      if (res.ok) return true;
    } catch {}
    await sleep(2000);
  }
  return false;
}

if (!(await waitReady(300000))) {
  console.error("[railway] server did not become ready on the bootstrap port");
  process.exit(1);
}

const res = await fetch(`${base}/api/v1/admin/bootstrap`, {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ email, password, organization }),
});
const body = await res.text();

if (res.ok) {
  console.log("[railway] instance administrator seeded");
  process.exit(0);
}
// Already initialised is the normal path on every redeploy.
if (body.includes("already been set up") || body.includes("already")) {
  console.log("[railway] instance already initialised, leaving it alone");
  process.exit(0);
}
console.error(`[railway] bootstrap failed: ${res.status} ${body}`);
process.exit(1);
