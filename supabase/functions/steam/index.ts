// CritHit — Edge Function "steam"
//
// Proxy fino para a Steam Web API. Existe por dois motivos:
//   1. A Steam não libera CORS, então o Flutter Web não consegue chamá-la
//      direto do navegador.
//   2. A chave da Steam (STEAM_API_KEY) fica guardada como secret aqui no
//      servidor e nunca vai parar dentro do app/APK.
//
// O app manda: { "method": "IPlayerService/GetOwnedGames/v1", "params": {...} }
// e recebe exatamente o JSON que a Steam devolveu.
//
// Deploy:  supabase functions deploy steam
// Secret:  supabase secrets set STEAM_API_KEY=<sua chave>

const ALLOWED_METHODS = new Set([
  "ISteamUser/ResolveVanityURL/v1",
  "ISteamUser/GetPlayerSummaries/v2",
  "IPlayerService/GetOwnedGames/v1",
  "IPlayerService/GetTopAchievementsForGames/v1",
]);

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return json({ error: "Use POST." }, 405);
  }

  const apiKey = Deno.env.get("STEAM_API_KEY");
  if (!apiKey) {
    return json(
      { error: "A chave da Steam não está configurada no servidor." },
      500,
    );
  }

  let method: unknown;
  let params: Record<string, unknown> = {};
  try {
    const body = await req.json();
    method = body?.method;
    params = body?.params ?? {};
  } catch {
    return json({ error: "Corpo da requisição inválido." }, 400);
  }

  if (typeof method !== "string" || !ALLOWED_METHODS.has(method)) {
    return json({ error: "Método da Steam não permitido." }, 400);
  }

  const url = new URL(`https://api.steampowered.com/${method}/`);
  url.searchParams.set("key", apiKey);
  url.searchParams.set("format", "json");
  for (const [name, value] of Object.entries(params)) {
    if (Array.isArray(value)) {
      value.slice(0, 500).forEach((item, i) =>
        url.searchParams.set(`${name}[${i}]`, String(item))
      );
    } else if (value !== null && value !== undefined) {
      url.searchParams.set(name, String(value));
    }
  }

  let steam: Response;
  try {
    steam = await fetch(url, { signal: AbortSignal.timeout(15000) });
  } catch {
    return json({ error: "Não consegui falar com a Steam agora." }, 502);
  }

  if (steam.status === 401 || steam.status === 403) {
    return json({ error: "A chave da Steam Web API é inválida." }, 502);
  }
  if (steam.status === 429) {
    return json(
      { error: "A Steam pediu pra gente ir com calma. Tenta de novo em 1 minuto." },
      429,
    );
  }
  if (!steam.ok) {
    return json(
      { error: `A Steam respondeu com erro (${steam.status}).` },
      502,
    );
  }

  // Conquistas: a Steam devolve a lista inteira de conquistas desbloqueadas
  // de cada jogo (centenas de KB numa biblioteca grande). O app só precisa
  // da contagem, então resumimos aqui para `unlocked_count`.
  if (method === "IPlayerService/GetTopAchievementsForGames/v1") {
    const data = await steam.json();
    const games = (data?.response?.games ?? []).map((game: {
      appid: number;
      total_achievements?: number;
      achievements?: unknown[];
    }) => ({
      appid: game.appid,
      total_achievements: game.total_achievements ?? 0,
      unlocked_count: game.achievements?.length ?? 0,
    }));
    return json({ response: { games } });
  }

  // Demais métodos: repassa o JSON original da Steam, agora com CORS liberado.
  return new Response(await steam.text(), {
    status: 200,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
});
