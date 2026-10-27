// CritHit — Edge Function "psn"
//
// Proxy para a API da PlayStation Network (a mesma usada pelo app oficial
// da PlayStation; a Sony não tem API pública). Existe por três motivos:
//   1. A PSN não libera CORS, então o Flutter Web não consegue chamá-la.
//   2. O acesso exige o token NPSSO de uma conta PSN, que vale tanto quanto
//      a senha dela. Ele fica guardado aqui como secret (PSN_NPSSO) e nunca
//      vai parar dentro do app/APK.
//   3. A troca NPSSO → access token é feita uma vez e reaproveitada entre
//      chamadas enquanto a instância da função estiver quente.
//
// O app manda: { "action": "trophyTitles", "params": { "accountId": "..." } }
// e recebe o JSON que a Sony devolveu. Só 3 ações são aceitas (lista fechada).
//
// Deploy:  supabase functions deploy psn
// Secret:  supabase secrets set PSN_NPSSO=<token de 64 caracteres>

const AUTH_BASE = "https://ca.account.sony.com/api/authz/v3/oauth";
// Credenciais públicas do app oficial da PlayStation (as mesmas usadas pelas
// bibliotecas da comunidade, como psn-api e PSNAWP).
const CLIENT_ID = "09515159-7237-4370-9b40-3806e67c0891";
const BASIC_AUTH =
  "Basic MDk1MTUxNTktNzIzNy00MzcwLTliNDAtMzgwNmU2N2MwODkxOnVjUGprYTV0bnRCMktxc1A=";
const REDIRECT_URI = "com.scee.psxandroid.scecompcall://redirect";
const SCOPE = "psn:mobile.v2.core psn:clientapp";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type ErrorKind = "notFound" | "private" | "auth" | "other";

class PsnError extends Error {
  constructor(
    public status: number,
    message: string,
    public kind: ErrorKind = "other",
  ) {
    super(message);
  }
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

// ------------------------------------------------------------ autenticação

let cachedToken: { value: string; expiresAt: number } | null = null;

async function accessToken(): Promise<string> {
  if (cachedToken && Date.now() < cachedToken.expiresAt) {
    return cachedToken.value;
  }
  const npsso = Deno.env.get("PSN_NPSSO");
  if (!npsso) {
    throw new PsnError(
      500,
      "O token da PSN não está configurado no servidor.",
      "auth",
    );
  }

  // 1. NPSSO -> código de autorização (vem no Location do redirect 302).
  const authorize = new URL(`${AUTH_BASE}/authorize`);
  authorize.search = new URLSearchParams({
    access_type: "offline",
    client_id: CLIENT_ID,
    redirect_uri: REDIRECT_URI,
    response_type: "code",
    scope: SCOPE,
  }).toString();
  const redirect = await fetch(authorize, {
    headers: { Cookie: `npsso=${npsso}` },
    redirect: "manual",
  });
  const code = (redirect.headers.get("location") ?? "").match(
    /[?&]code=([^&]+)/,
  )?.[1];
  if (!code) {
    throw new PsnError(
      502,
      "O token da PSN do servidor expirou. É preciso gerar um NPSSO novo.",
      "auth",
    );
  }

  // 2. Código -> access token (dura cerca de 1 hora).
  const tokenResponse = await fetch(`${AUTH_BASE}/token`, {
    method: "POST",
    headers: {
      Authorization: BASIC_AUTH,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      code,
      redirect_uri: REDIRECT_URI,
      grant_type: "authorization_code",
      token_format: "jwt",
    }),
  });
  const token = await tokenResponse.json().catch(() => ({}));
  if (!token?.access_token) {
    throw new PsnError(502, "Não consegui autenticar na PSN.", "auth");
  }
  cachedToken = {
    value: token.access_token,
    expiresAt: Date.now() + ((token.expires_in ?? 3600) - 60) * 1000,
  };
  return cachedToken.value;
}

// ------------------------------------------------------------------ ações

const ONLINE_ID = /^[A-Za-z][A-Za-z0-9_-]{2,15}$/;
const ACCOUNT_ID = /^\d{1,25}$/;

function actionUrl(action: string, params: Record<string, unknown>): URL {
  const offset = String(Number(params.offset ?? 0) || 0);
  switch (action) {
    case "profile": {
      const onlineId = String(params.onlineId ?? "");
      if (!ONLINE_ID.test(onlineId)) {
        throw new PsnError(400, "ID online da PSN inválido.", "notFound");
      }
      const url = new URL(
        `https://us-prof.np.community.playstation.net/userProfile/v1/users/${onlineId}/profile2`,
      );
      url.searchParams.set(
        "fields",
        "onlineId,accountId,avatarUrls,plus,trophySummary(@default,level,progress,earnedTrophies)",
      );
      return url;
    }
    case "trophyTitles":
    case "playedGames": {
      const accountId = String(params.accountId ?? "");
      if (!ACCOUNT_ID.test(accountId)) {
        throw new PsnError(400, "Conta da PSN inválida.");
      }
      if (action === "trophyTitles") {
        const url = new URL(
          `https://m.np.playstation.com/api/trophy/v1/users/${accountId}/trophyTitles`,
        );
        url.searchParams.set("limit", "800");
        url.searchParams.set("offset", offset);
        return url;
      }
      const url = new URL(
        `https://m.np.playstation.com/api/gamelist/v2/users/${accountId}/titles`,
      );
      url.searchParams.set("categories", "ps4_game,ps5_native_game");
      url.searchParams.set("limit", "200");
      url.searchParams.set("offset", offset);
      return url;
    }
  }
  throw new PsnError(400, "Ação da PSN não permitida.");
}

/// Traduz o erro da Sony ({"error": {"code", "message"}}) para o app.
function translate(status: number, body: unknown): PsnError {
  const message = String(
    (body as { error?: { message?: string } })?.error?.message ?? "",
  ).toLowerCase();
  if (status === 404 || message.includes("not found")) {
    return new PsnError(
      404,
      "Não achei nenhuma conta da PSN com esse ID online.",
      "notFound",
    );
  }
  if (
    status === 403 || message.includes("access control") ||
    message.includes("forbidden") || message.includes("privacy")
  ) {
    return new PsnError(
      403,
      "A privacidade dessa conta da PSN não deixa ver os jogos.",
      "private",
    );
  }
  if (status === 429) {
    return new PsnError(
      429,
      "A PSN pediu pra gente ir com calma. Tenta de novo em 1 minuto.",
    );
  }
  return new PsnError(502, `A PSN respondeu com erro (${status}).`);
}

async function callPsn(url: URL, retry = true): Promise<unknown> {
  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${await accessToken()}`,
      // Nomes em inglês, para casar com o catálogo do CritHit.
      "Accept-Language": "en-US",
    },
    signal: AbortSignal.timeout(15000),
  });
  if (response.status === 401 && retry) {
    // Token velho na instância quente: renova uma vez e tenta de novo.
    cachedToken = null;
    return callPsn(url, false);
  }
  const body = await response.json().catch(() => null);
  if (!response.ok || (body as { error?: unknown })?.error) {
    throw translate(response.status, body);
  }
  return body;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return json({ error: "Use POST." }, 405);
  }

  let action: unknown;
  let params: Record<string, unknown> = {};
  try {
    const body = await req.json();
    action = body?.action;
    params = body?.params ?? {};
  } catch {
    return json({ error: "Corpo da requisição inválido." }, 400);
  }

  try {
    if (typeof action !== "string") {
      throw new PsnError(400, "Ação da PSN não permitida.");
    }
    return json(await callPsn(actionUrl(action, params)));
  } catch (error) {
    if (error instanceof PsnError) {
      return json({ error: error.message, kind: error.kind }, error.status);
    }
    return json({ error: "Não consegui falar com a PSN agora." }, 502);
  }
});
