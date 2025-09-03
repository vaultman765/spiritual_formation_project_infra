// filepath: modules/lambda_edge_bot/code/index.js
// Node 18+ Lambda@Edge prerender - NO NETWORK CALLS VERSION
const BOT_RE = /(bot|facebookexternalhit|slackbot|twitterbot|linkedinbot|pinterest|embedly|quora|discordbot|whatsapp|telegram|vkShare|SkypeUriPreview)/i;

const SITE = "__SITE_ORIGIN__";
const TW_HANDLE = "@RCMentalPrayer";

exports.handler = async (event, _ctx, callback) => {
  const request = event.Records[0].cf.request;
  const ua = getHeader(request, "user-agent");
  const path = request.uri || "/";

  const m = path.match(/^\/days\/([^\/]+)\/([^\/]+)\/?$/) || path.match(/^\/arcs\/([^\/]+)\/?$/);
  const isBot = BOT_RE.test(ua);

  if (!m || !isBot) return callback(null, request);

  // Decide what we're rendering: /days or /arcs
  let html;
  if (path.startsWith("/days/")) {
    const arcId = decodeURIComponent(m[1]);
    const dayNum = decodeURIComponent(m[2]);
    const canonical = `${SITE}/days/${arcId}/${dayNum}`;

  // Format it into a display name
  const formattedArcName = arcId
    .replace(/^arc_/, '')
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');

    // Static title/description - no API calls allowed in viewer-request
    const title = `${formattedArcName} - Day ${dayNum} Meditation`;
    const description = "Pray with today's featured meditation and reflection on " + formattedArcName + ".";

    // FIX: Match the actual image path format
    const img = `${SITE}/images/social/arc_days/${arcId}_day_${String(dayNum).padStart(2, "0")}.jpg`;

    html = renderHtml({ title, description, image: img, canonical, twitterHandle: TW_HANDLE });
  } else {
    // For /arcs/:arc_id
    const arcId = decodeURIComponent(m[1]);
    const canonical = `${SITE}/arcs/${arcId}`;
    const formattedArcName = arcId
      .replace(/^arc_/, '')
      .split('_')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
    html = renderHtml({
      title: `Spiritual Exercise Series — ${formattedArcName}`,
      description: "Meditations for Ignatian Mental Prayer and meditation on " + formattedArcName + ".",
      image: `${SITE}/images/social/arc_whole/${arcId}.jpg`,
      canonical,
      twitterHandle: TW_HANDLE,
    });
  }

  const response = {
    status: "200",
    statusDescription: "OK",
    headers: {
      "content-type": [{ key: "Content-Type", value: "text/html; charset=utf-8" }],
      "cache-control": [{ key: "Cache-Control", value: "public, s-maxage=3600" }],
    },
    body: html,
  };
  return callback(null, response);
};

function getHeader(req, name) {
  const h = req.headers?.[name.toLowerCase()];
  return h && h[0] ? h[0].value : "";
}

function esc(s) {
  return String(s).replace(/[&<>"']/g, (m) => ({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[m]));
}

function renderHtml({ title, description, image, canonical, twitterHandle }) {
  return `<!doctype html><html lang="en"><head>
<meta charset="utf-8">
<title>${esc(title)}</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="canonical" href="${canonical}">
<meta property="og:site_name" content="Spiritual Formation Project">
<meta property="og:type" content="article">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(description)}">
<meta property="og:image" content="${image}">
<meta property="og:url" content="${canonical}">
<meta property="og:locale" content="en_US">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:site" content="${twitterHandle}">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${esc(description)}">
<meta name="twitter:image" content="${image}">
<meta name="twitter:url" content="${canonical}">
<meta name="twitter:creator" content="${twitterHandle}" />
</head><body></body></html>`;
}