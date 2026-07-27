/**
 * residencyR licensing backend -- reference implementation.
 *
 * This is a STARTER you deploy yourself (Render, Railway, a VPS,
 * or a serverless function) -- it is not hosted anywhere by default.
 *
 * SECURITY -- read before deploying:
 *   - PAYSTACK_SECRET_KEY and LICENSE_PRIVATE_KEY_PEM must be set as
 *     environment variables on your server. NEVER commit them to
 *     git, NEVER put them in this file, NEVER expose them to the
 *     frontend. Only the PUBLIC key belongs in the open-source R
 *     package.
 *   - The frontend only ever sees your Paystack PUBLIC key. The
 *     secret key is used here, server-side, only.
 *   - Always verify transactions server-side (this file does that)
 *     -- never trust a client-side "payment succeeded" callback by
 *     itself. A user could fake that in their browser console.
 *
 * Endpoints:
 *   POST /verify-and-issue   -- called by the frontend after the
 *                               Paystack popup closes. Verifies the
 *                               transaction server-side, then issues
 *                               a signed license.
 *   POST /paystack-webhook   -- called BY Paystack on subscription
 *                               renewal / cancellation events. Issues
 *                               a fresh license on each successful
 *                               renewal charge, so the customer's
 *                               license never has to be manually
 *                               reissued.
 *
 * Install: npm install express node-fetch
 * Run:     PAYSTACK_SECRET_KEY=sk_... LICENSE_PRIVATE_KEY_PEM="$(cat private_key.pem)" node server.js
 */

const express = require("express");
const crypto = require("crypto");

const app = express();
app.use(express.json());

const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY; // sk_live_... or sk_test_...
const LICENSE_PRIVATE_KEY_PEM = process.env.LICENSE_PRIVATE_KEY_PEM; // the private half of the keypair embedded (public half) in R/license.R

if (!PAYSTACK_SECRET_KEY || !LICENSE_PRIVATE_KEY_PEM) {
  console.warn("WARNING: PAYSTACK_SECRET_KEY and/or LICENSE_PRIVATE_KEY_PEM env vars are not set. Set them before going live.");
}

// Plan -> license duration mapping. Adjust to match your actual
// Paystack Plan codes (created in your Paystack dashboard).
const PLAN_DURATIONS_DAYS = {
  assessment: 60, // one-time Compliance Readiness Assessment engagement window
  monthly: 31,
  annual: 366,
};

/** Builds the exact canonical string the R package will re-derive and verify against. */
function canonicalLicenseString({ licensee, email, plan, issued, expires }) {
  return [licensee, email, plan, issued, expires].join("|");
}

/** Signs a license and returns the full .lic file text, in the same
 *  key: value format R/license.R's parser expects. */
function issueLicense({ licensee, email, plan }) {
  const issued = new Date().toISOString().slice(0, 10);
  const durationDays = PLAN_DURATIONS_DAYS[plan] || 366;
  const expiresDate = new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000);
  const expires = expiresDate.toISOString().slice(0, 10);

  const canonical = canonicalLicenseString({ licensee, email, plan, issued, expires });
  const signer = crypto.createSign("RSA-SHA256");
  signer.update(canonical);
  const signature = signer.sign(LICENSE_PRIVATE_KEY_PEM, "base64");

  return [
    `LICENSEE: ${licensee}`,
    `EMAIL: ${email}`,
    `PLAN: ${plan}`,
    `ISSUED: ${issued}`,
    `EXPIRES: ${expires}`,
    `SIGNATURE: ${signature}`,
  ].join("\n");
}

/** Verifies a Paystack transaction reference server-side before
 *  trusting it. Never skip this step. */
async function verifyPaystackTransaction(reference) {
  const res = await fetch(`https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`, {
    headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` },
  });
  const body = await res.json();
  if (!body.status || body.data.status !== "success") {
    throw new Error("Transaction not successful or could not be verified.");
  }
  return body.data; // contains amount, customer, plan, metadata, etc.
}

// ---------------------------------------------------------------
// POST /verify-and-issue
// Body: { reference: string, plan: "monthly" | "annual" }
// Called by the frontend right after the Paystack popup reports success.
// ---------------------------------------------------------------
app.post("/verify-and-issue", async (req, res) => {
  try {
    const { reference, plan } = req.body;
    if (!reference || !plan) return res.status(400).json({ error: "Missing reference or plan." });

    const txn = await verifyPaystackTransaction(reference);

    const licenseText = issueLicense({
      licensee: txn.metadata?.bank_name || txn.customer.email,
      email: txn.customer.email,
      plan,
    });

    // In production: also email this to the customer, and store a
    // record (customer, plan, paystack subscription code, expiry) in
    // your own database so /paystack-webhook can find and renew it.
    res.json({ success: true, license: licenseText });
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
  }
});

// ---------------------------------------------------------------
// POST /paystack-webhook
// Configure this URL in your Paystack dashboard under Settings > API Keys & Webhooks.
// Handles recurring subscription renewal charges automatically.
// ---------------------------------------------------------------
app.post(
  "/paystack-webhook",
  express.raw({ type: "application/json" }), // raw body needed for signature check
  (req, res) => {
    const signature = req.headers["x-paystack-signature"];
    const expectedSignature = crypto
      .createHmac("sha512", PAYSTACK_SECRET_KEY)
      .update(req.body)
      .digest("hex");

    if (signature !== expectedSignature) {
      return res.status(401).send("Invalid webhook signature.");
    }

    const event = JSON.parse(req.body);

    if (event.event === "charge.success" && event.data.plan) {
      // A subscription renewal charge succeeded -- issue a fresh license.
      const licenseText = issueLicense({
        licensee: event.data.metadata?.bank_name || event.data.customer.email,
        email: event.data.customer.email,
        plan: event.data.plan.interval === "monthly" ? "monthly" : "annual",
      });

      // TODO: email licenseText to the customer, or make it available
      // for download in a customer portal. This reference
      // implementation does not include email delivery.
      console.log("Renewal license issued for", event.data.customer.email);
    }

    if (event.event === "subscription.disable") {
      // Customer cancelled or a renewal charge failed repeatedly.
      // TODO: notify your team; the existing license will simply
      // expire on its EXPIRES date -- no action required to "revoke" it.
      console.log("Subscription disabled for", event.data.customer?.email);
    }

    res.sendStatus(200);
  }
);

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  app.listen(PORT, () => console.log(`residencyR licensing backend listening on port ${PORT}`));
}

module.exports = { issueLicense, canonicalLicenseString, app };
