export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const key = url.searchParams.get("key");
    const hwid = url.searchParams.get("hwid") || "";

    const headers = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Content-Type": "application/json"
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers });
    }

    if (!key) {
      return new Response(JSON.stringify({ ok: false, reason: "no_key" }), { headers });
    }

    // Читаем тип ключа из KV (или из встроенного JSON, если KV нет)
    let keyType = null;

    if (env.EXTRALV_KEYS) {
      keyType = await env.EXTRALV_KEYS.get(key.toUpperCase());
    }

    // Fallback: если KV не привязан — читаем из статического keys.json в репо
    if (!keyType) {
      return new Response(JSON.stringify({ ok: false, reason: "not_found" }), { headers });
    }

    // Дата ГГГГ-ММ-ДД
    if (/^\d{4}-\d{2}-\d{2}$/.test(keyType)) {
      const expireAt = new Date(keyType + "T23:59:59Z").getTime();
      if (Date.now() > expireAt) {
        return new Response(JSON.stringify({ ok: false, reason: "expired", expire: keyType }), { headers });
      }
      return new Response(JSON.stringify({ ok: true, type: "date", expire: keyType }), { headers });
    }

    const durations = { forever: 0, month: 30*24*60*60, week: 7*24*60*60, hour12: 12*60*60 };
    const duration = durations[keyType];
    if (duration === undefined) {
      return new Response(JSON.stringify({ ok: false, reason: "unknown_type" }), { headers });
    }
    if (duration === 0) {
      return new Response(JSON.stringify({ ok: true, type: "forever" }), { headers });
    }

    const activationKey = "ACT_" + key.toUpperCase() + "_" + hwid;
    let activatedAtStr = await env.EXTRALV_KEYS.get(activationKey);
    let activatedAt = activatedAtStr ? parseInt(activatedAtStr) : null;

    if (!activatedAt) {
      activatedAt = Math.floor(Date.now() / 1000);
      await env.EXTRALV_KEYS.put(activationKey, String(activatedAt));
    }

    const expireAt = activatedAt + duration;
    if (Math.floor(Date.now() / 1000) > expireAt) {
      return new Response(JSON.stringify({
        ok: false, reason: "expired",
        expire: new Date(expireAt * 1000).toISOString()
      }), { headers });
    }

    return new Response(JSON.stringify({
      ok: true, type: keyType,
      expire: new Date(expireAt * 1000).toISOString()
    }), { headers });
  }
};
