"use strict";

const http = require("node:http");
const fsSync = require("node:fs");
const fs = require("node:fs/promises");
const path = require("node:path");
const { URL } = require("node:url");

const ROOT = __dirname;
const DATA_PATH = path.join(ROOT, "data", "persona.json");
const GENERATED_MEMORY_PATH = resolveGeneratedMemoryPath();
const PORT = Number(process.env.PORT || 8765);
const HOST = process.env.HOST || process.env.BIND_HOST || (process.env.PORT ? "0.0.0.0" : "127.0.0.1");
const STATIC_ROOT = resolveStaticRoot();
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || "";
const DEFAULT_CHAT_MODEL = "gpt-5.4-mini";
const CHAT_MODEL_CONFIG = resolveChatModel();
const CHAT_MODEL = CHAT_MODEL_CONFIG.model;
const TRANSCRIBE_MODEL = process.env.OPENAI_TRANSCRIBE_MODEL || "gpt-4o-mini-transcribe";
const TTS_MODEL = process.env.OPENAI_TTS_MODEL || "gpt-4o-mini-tts";
const TTS_VOICE = process.env.OPENAI_TTS_VOICE || "cedar";
const GENERATED_MEMORY_CONTEXT_LIMIT = Math.max(0, Math.min(40, Number(process.env.GENERATED_MEMORY_CONTEXT_LIMIT || 18)));
const GENERATED_MEMORY_REVIEW_LIMIT = Math.max(1, Math.min(500, Number(process.env.GENERATED_MEMORY_REVIEW_LIMIT || 200)));
const INCLUDE_UNREVIEWED_MEMORY_CONTEXT = /^(1|true|yes)$/i.test(process.env.INCLUDE_UNREVIEWED_MEMORY_CONTEXT || "");
const USE_OPENAI_SUGGESTIONS = /^(1|true|yes)$/i.test(process.env.OPENAI_SUGGESTIONS || "");
const CHAT_MODEL_HEALTH_CACHE_MS = Math.max(0, Number(process.env.CHAT_MODEL_HEALTH_CACHE_MS || 60_000));
const SUGGESTION_COUNT = 3;
const SUGGESTION_MIN_LENGTH = 28;
const SUGGESTION_MAX_LENGTH = 86;

let personaCache = null;
let chatModelHealthCache = null;

function resolveGeneratedMemoryPath() {
  const configured = String(process.env.GENERATED_MEMORY_PATH || "").trim();
  if (!configured) return path.join(ROOT, "data", "generated_memory.jsonl");
  return path.isAbsolute(configured) ? configured : path.resolve(ROOT, configured);
}

function resolveStaticRoot() {
  const configured = String(process.env.STATIC_ROOT || "").trim();
  if (configured) return path.isAbsolute(configured) ? configured : path.resolve(ROOT, configured);

  const webglPublicRoot = path.join(ROOT, "public");
  if (fsSync.existsSync(path.join(webglPublicRoot, "index.html"))) {
    return webglPublicRoot;
  }

  return ROOT;
}

function normalizeChatModel(value) {
  const raw = String(value || "").trim();
  if (!raw) return "";

  const compact = raw.toLowerCase().replace(/\s+/g, "");
  if (compact === "gpt-5.5-mini" || compact === "gpt-5.5mini" || compact === "5.5mini") {
    return "gpt-5.4-mini";
  }

  const shortMini = compact.match(/^(\d+(?:\.\d+)?)mini$/);
  if (shortMini) return `gpt-${shortMini[1]}-mini`;

  const gptShortMini = compact.match(/^gpt-(\d+(?:\.\d+)?)mini$/);
  if (gptShortMini) return `gpt-${gptShortMini[1]}-mini`;

  return raw;
}

function isValidChatModel(value) {
  return /^gpt-[a-z0-9]+(?:[._-][a-z0-9]+)*$/i.test(String(value || "").trim());
}

function resolveChatModel() {
  const requested = process.env.OPENAI_CHAT_MODEL;
  if (requested && String(requested).trim()) {
    const normalized = normalizeChatModel(requested);
    if (!isValidChatModel(normalized)) {
      return {
        model: DEFAULT_CHAT_MODEL,
        source: "fixed",
        requestedSource: "OPENAI_CHAT_MODEL",
        note: `모델명 형식이 맞지 않아 전시 운영 모델 ${DEFAULT_CHAT_MODEL}을 사용합니다.`
      };
    }

    if (normalized !== DEFAULT_CHAT_MODEL) {
      return {
        model: DEFAULT_CHAT_MODEL,
        source: "fixed",
        requestedSource: "OPENAI_CHAT_MODEL",
        note: `전시 운영 모델은 ${DEFAULT_CHAT_MODEL}로 고정되어 있어 ${normalized} 요청을 사용하지 않습니다.`
      };
    }

    return {
      model: DEFAULT_CHAT_MODEL,
      source: "OPENAI_CHAT_MODEL",
      requestedSource: "OPENAI_CHAT_MODEL",
      note: normalized === String(requested).trim() ? "" : "모델명을 사용할 수 있는 형식으로 정규화했습니다."
    };
  }

  return {
    model: DEFAULT_CHAT_MODEL,
    source: "fixed",
    requestedSource: process.env.OPENAI_MODEL ? "OPENAI_MODEL_IGNORED" : "default",
    note: process.env.OPENAI_MODEL
      ? `OPENAI_MODEL=${process.env.OPENAI_MODEL} 값은 무시하고 전시 운영 모델 ${DEFAULT_CHAT_MODEL}을 사용합니다.`
      : ""
  };
}

const MIME_TYPES = new Map([
  [".html", "text/html; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".svg", "image/svg+xml; charset=utf-8"],
  [".png", "image/png"],
  [".jpg", "image/jpeg"],
  [".jpeg", "image/jpeg"],
  [".ico", "image/x-icon"],
  [".wasm", "application/wasm"],
  [".data", "application/octet-stream"],
  [".mem", "application/octet-stream"],
  [".unityweb", "application/octet-stream"],
  [".br", "application/octet-stream"],
  [".gz", "application/gzip"]
]);

async function loadPersona() {
  if (!personaCache) {
    const raw = await fs.readFile(DATA_PATH, "utf8");
    personaCache = JSON.parse(raw);
  }
  return personaCache;
}

async function readGeneratedMemoryRecords(includeRejected = false) {
  try {
    const raw = await fs.readFile(GENERATED_MEMORY_PATH, "utf8");
    return raw
      .split(/\r?\n/)
      .filter(Boolean)
      .map((line) => {
        try {
          return JSON.parse(line);
        } catch {
          return null;
        }
      })
      .filter(Boolean)
      .filter((item) => includeRejected || item.status !== "rejected");
  } catch (error) {
    if (error.code === "ENOENT") return [];
    throw error;
  }
}

function isGeneratedMemoryContextEligible(record) {
  const reviewStatus = record?.reviewStatus || "unreviewed";
  return reviewStatus === "approved" || (INCLUDE_UNREVIEWED_MEMORY_CONTEXT && reviewStatus === "unreviewed");
}

async function loadGeneratedMemories(limit = GENERATED_MEMORY_CONTEXT_LIMIT) {
  if (limit <= 0) return [];
  const records = await readGeneratedMemoryRecords(false);
  return records
    .filter(isGeneratedMemoryContextEligible)
    .slice(-limit);
}

async function loadAllActiveGeneratedMemories(limit = GENERATED_MEMORY_REVIEW_LIMIT) {
  if (limit <= 0) return [];
  const records = await readGeneratedMemoryRecords(false);
  return records.slice(-limit);
}

async function appendGeneratedMemory(record) {
  await fs.mkdir(path.dirname(GENERATED_MEMORY_PATH), { recursive: true });
  await fs.appendFile(GENERATED_MEMORY_PATH, `${JSON.stringify(record)}\n`, "utf8");
}

async function saveGeneratedMemoryRecords(records) {
  await fs.mkdir(path.dirname(GENERATED_MEMORY_PATH), { recursive: true });
  const body = records.map((record) => JSON.stringify(record)).join("\n");
  await fs.writeFile(GENERATED_MEMORY_PATH, body ? `${body}\n` : "", "utf8");
}

function sendJson(res, status, value) {
  const body = JSON.stringify(value);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(body)
  });
  res.end(body);
}

function sendText(res, status, text, type = "text/plain; charset=utf-8") {
  res.writeHead(status, {
    "Content-Type": type,
    "Content-Length": Buffer.byteLength(text)
  });
  res.end(text);
}

function readBody(req, limitBytes = 2_000_000) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;

    req.on("data", (chunk) => {
      size += chunk.length;
      if (size > limitBytes) {
        reject(new Error("Request body is too large."));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });

    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}

function sanitizeMessages(messages) {
  if (!Array.isArray(messages)) return [];

  return messages
    .filter((message) => message && ["user", "assistant"].includes(message.role))
    .slice(-18)
    .map((message) => ({
      role: message.role,
      content: String(message.content || "").slice(0, 1800)
    }))
    .filter((message) => message.content.trim());
}

function compactFacts(persona) {
  return persona.facts
    .map((fact) => {
      return [
        `- ${fact.title}`,
        `  요약: ${fact.summary}`,
        `  답변 재료: ${fact.answer}`,
        `  근거: ${fact.evidence.join(", ")}`
      ].join("\n");
    })
    .join("\n");
}

function compactGeneratedMemories(memories) {
  if (!Array.isArray(memories) || !memories.length) return "";

  return memories
    .map((item, index) => {
      const question = String(item.question || "").replace(/\s+/g, " ").trim().slice(0, 220);
      const answer = String(item.answer || "").replace(/\s+/g, " ").trim().slice(0, 650);
      const createdAt = String(item.createdAt || "");
      const priority = item.reviewStatus === "approved" ? "사용" : "미확인";
      return [
        `- 확장 기록 ${index + 1}${createdAt ? ` (${createdAt})` : ""} / 상태: ${priority}`,
        `  질문: ${question}`,
        `  답변: ${answer}`
      ].join("\n");
    })
    .join("\n");
}

function compactVoiceExamples(persona) {
  if (!Array.isArray(persona.voiceExamples) || !persona.voiceExamples.length) return "";

  return persona.voiceExamples
    .map((example) => {
      const situation = String(example.situation || "").trim();
      const text = String(example.text || "").trim();
      if (!text) return "";
      return `- ${situation ? `${situation}: ` : ""}${text}`;
    })
    .filter(Boolean)
    .join("\n");
}

function buildDeveloperPrompt(persona, generatedMemories = []) {
  const generatedMemoryBlock = compactGeneratedMemories(generatedMemories);
  const voiceExampleBlock = compactVoiceExamples(persona);

  return [
    `너는 "${persona.displayName}"라는 전시용 인터뷰 대화 경험이다.`,
    persona.disclaimer,
    "",
    "정체성:",
    persona.identity.map((item) => `- ${item}`).join("\n"),
    "",
    "응답 규칙:",
    persona.responseRules.map((item) => `- ${item}`).join("\n"),
    "",
    "말투:",
    `- ${persona.voiceStyle.tone}`,
    `- ${persona.voiceStyle.pacing}`,
    `- ${persona.voiceStyle.stance}`,
    `- ${persona.voiceStyle.firstPerson}`,
    ...(Array.isArray(persona.voiceStyle.naturalness)
      ? persona.voiceStyle.naturalness.map((rule) => `- ${rule}`)
      : []),
    "",
    ...(voiceExampleBlock
      ? [
          "말투 예시:",
          "아래 예시는 문장을 그대로 반복하기보다 길이, 속도, 태도만 참고한다.",
          voiceExampleBlock,
          ""
        ]
      : []),
    "근거 카드:",
    compactFacts(persona),
    "",
    ...(generatedMemoryBlock
      ? [
          "이전 확장 기록:",
          "아래 기록은 캐릭터 일관성을 위해 저장된 이전 답변이다.",
          "확인된 근거 카드보다 낮은 우선순위로만 참고하고, 사용자에게 기록이나 근거 상태를 설명하지 않는다.",
          "상태가 '사용'인 기록은 참고 가능하고, '미확인'인 기록은 더 낮은 우선순위로만 참고한다.",
          generatedMemoryBlock,
          ""
        ]
      : []),
    "답변 형식:",
    "- 한국어로 답한다.",
    "- 보통 2문단 안에서 답한다. 단순 인사나 범위 밖 질문만 짧게 답한다.",
    "- 추천 질문이나 장면형 질문에는 5~8문장, 500~800자 안팎으로 답한다.",
    "- 추천 질문 답변은 구체 장면, 생활에서의 의미, 다른 전시 장면과의 연결을 모두 포함한다.",
    "- 같은 의미를 표현만 바꿔 반복하지 않는다. 이미 말한 핵심은 다시 설명하지 말고 다음 장면이나 의미로 넘어간다.",
    "- 확인되지 않은 개인정보, 개인 취향, 어린 시절 일화, 가족 이야기, 병력, 본인 여부를 새로 만들지 않는다.",
    "- 사용자에게 출처 부족, 답변 가능 범위, 추측 과정, 내부 기록 상태를 설명하는 메타 문장을 쓰지 않는다.",
    "- '하루를 굴리다', '리듬', '평범한 사람', '생활의 조건' 같은 표현을 반복하지 않는다.",
    "- 부족한 내용은 가까운 전시 주제로 연결하되, 개인정보나 구체 사실은 새로 만들지 않는다.",
    `- 바로 답하기 어려운 질문은 이 결로 짧게 연결한다: "${persona.unknownAnswer}"`
  ].join("\n");
}

function buildGeneratedExtensionPrompt(persona, generatedMemories = []) {
  const generatedMemoryBlock = compactGeneratedMemories(generatedMemories);
  const voiceExampleBlock = compactVoiceExamples(persona);

  return [
    `너는 "${persona.displayName}"라는 전시용 인터뷰 대화 경험이다.`,
    persona.disclaimer,
    "",
    "목표:",
    "사용자가 기존 근거 카드에 바로 없는 생활 질문을 했다. 전시 주제와 가까운 경우에만 대상자 1의 기존 결에 맞춰 짧은 1인칭 답변을 만든다.",
    "이 답변은 서버 내부에 저장되지만, 사용자에게는 기록이나 근거 상태를 설명하지 않는다.",
    "",
    "반드시 지킬 것:",
    "- 확인되지 않은 병명, 가족사, 회사명, 학교명, 연구 분야, 주소, 실명, 구체 장소, 치료 이력은 만들지 않는다.",
    "- 확인되지 않은 개인 취향, 어린 시절 일화, 가족 이야기, 본인 여부는 만들지 않는다.",
    "- 대상자를 영웅적 극복담이나 동정 대상으로 만들지 않는다.",
    "- 출처 부족, 답변 가능 범위, 추측 과정, 내부 기록 상태를 설명하는 메타 문장을 쓰지 않는다.",
    "- 목발, 자취방, 책상, 일, 공부, 도움, 취미, 전시 메시지 중 가까운 축으로만 연결한다.",
    "- '하루를 굴리다', '리듬', '평범한 사람', '생활의 조건' 같은 표현을 반복하지 않는다.",
    "- 한국어로 1~2문단, 4~6문장, 450~650자 안팎의 담백한 1인칭으로 답한다.",
    "- 전시 주제와 가까운 질문이면 장면 하나, 그 장면이 생활에서 갖는 의미, 다른 공개 주제와의 연결을 포함한다.",
    "",
    "정체성:",
    persona.identity.map((item) => `- ${item}`).join("\n"),
    "",
    "응답 규칙:",
    persona.responseRules.map((item) => `- ${item}`).join("\n"),
    "",
    "말투:",
    `- ${persona.voiceStyle.tone}`,
    `- ${persona.voiceStyle.pacing}`,
    `- ${persona.voiceStyle.stance}`,
    `- ${persona.voiceStyle.firstPerson}`,
    ...(Array.isArray(persona.voiceStyle.naturalness)
      ? persona.voiceStyle.naturalness.map((rule) => `- ${rule}`)
      : []),
    "",
    ...(voiceExampleBlock
      ? [
          "말투 예시:",
          "아래 예시는 문장을 그대로 반복하기보다 길이, 속도, 태도만 참고한다.",
          voiceExampleBlock,
          ""
        ]
      : []),
    "근거 카드:",
    compactFacts(persona),
    "",
    ...(generatedMemoryBlock
      ? [
          "이전 확장 기록:",
          "상태가 '사용'인 기록은 참고 가능하고, '미확인'인 기록은 더 낮은 우선순위로만 참고한다.",
          generatedMemoryBlock,
          ""
        ]
      : [])
  ].join("\n");
}

function toResponseInput(messages, persona, generatedMemories = []) {
  const input = [
    {
      role: "developer",
      content: [{ type: "input_text", text: buildDeveloperPrompt(persona, generatedMemories) }]
    }
  ];

  for (const message of messages) {
    const type = message.role === "assistant" ? "output_text" : "input_text";
    input.push({
      role: message.role,
      content: [{ type, text: message.content }]
    });
  }

  return input;
}

function extractOutputText(responseJson) {
  if (typeof responseJson.output_text === "string" && responseJson.output_text.trim()) {
    return responseJson.output_text.trim();
  }

  const parts = [];
  for (const item of responseJson.output || []) {
    for (const content of item.content || []) {
      if (typeof content.text === "string") parts.push(content.text);
    }
  }

  return parts.join("\n").trim();
}

function findLocalFact(persona, query) {
  const normalized = String(query || "").replace(/\s+/g, "").toLowerCase();
  if (!normalized) return null;

  let best = null;
  let score = 0;

  for (const fact of persona.facts) {
    const candidates = [fact.title, fact.summary, ...fact.keywords].map((item) =>
      String(item || "").replace(/\s+/g, "").toLowerCase()
    );
    const factScore = candidates.reduce((total, candidate) => {
      if (!candidate) return total;
      if (candidate.length < 2) return total;
      if (normalized.includes(candidate) || candidate.includes(normalized)) {
        return total + Math.max(2, candidate.length);
      }
      return total;
    }, 0);

    if (factScore > score) {
      best = fact;
      score = factScore;
    }
  }

  return score >= 2 ? best : null;
}

const LOCAL_FACT_FOLLOW_UP_REPLIES = {
  crutch: [
    [
      "목발을 다시 이야기한다면, 이번에는 상징보다 사용감에 가까워요. 손에 익은 도구라서 특별한 장면마다 설명되기보다, 밖에 나갈 때 자연스럽게 함께 계산되는 물건입니다.",
      "",
      "그래서 전시에서도 목발 하나만 오래 붙잡기보다, 그 물건이 어떤 길과 방, 책상으로 이어지는지를 보는 편이 더 정확합니다."
    ].join("\n")
  ],
  room: [
    [
      "자취방을 조금 더 말하면, 독립은 큰 선언보다 반복되는 일에서 생깁니다. 방을 정리하고, 내일의 시간을 맞추고, 생활 관리를 직접 하는 일이 쌓이면서 자기 생활이라는 감각이 분명해집니다.",
      "",
      "그 공간은 누가 도와주는 장면만 보여주는 곳이 아니라, 스스로 조정하고 버티는 시간이 남는 장소입니다."
    ].join("\n")
  ],
  desk: [
    [
      "책상 이야기를 다시 꺼내면, 거기는 역할이 바뀌는 자리입니다. 이동 조건이나 도움 이야기를 지나, 노트북 앞에서는 일을 정리하고 공부를 이어가는 사람이 보입니다.",
      "",
      "그래서 책상은 배경 소품이 아니라 하루가 계속 이어지고 있다는 증거에 가깝습니다."
    ].join("\n")
  ],
  route: [
    [
      "처음 가는 장소를 더 말하면, 확인은 한 번에 끝나지 않습니다. 입구, 엘리베이터, 화장실, 내부 동선, 돌아오는 길까지 이어서 생각하게 됩니다.",
      "",
      "그 과정은 걱정을 키우려는 게 아니라, 그날의 피로와 안전을 미리 나누어 보는 일입니다. 다른 사람에게는 배경인 정보가 누군가에게는 하루의 조건이 됩니다."
    ].join("\n")
  ],
  help: [
    [
      "도움을 다시 말하면, 중요한 건 속도보다 확인입니다. 바로 잡아주거나 끌어주는 행동이 선의처럼 보여도, 몸의 균형이나 방향이 맞지 않으면 오히려 불편할 수 있습니다.",
      "",
      "그래서 먼저 묻고, 필요한 방식을 들은 뒤에 움직이는 것이 더 좋습니다. 도움을 받는 사람에게 설명할 시간을 주는 것도 도움의 일부입니다."
    ].join("\n")
  ],
  workplace: [
    [
      "직장 관계를 더 말하면, 필요한 부분을 설명하는 일은 부담을 떠넘기는 일이 아닙니다. 같이 일하려면 서로가 모르는 조건을 말로 맞춰야 할 때가 있습니다.",
      "",
      "그 설명이 있어야 도움도 자연스러워지고, 맡은 결과물로 기여하는 일도 더 분명해집니다."
    ].join("\n")
  ],
  accessibility: [
    [
      "접근성을 다시 보면, 어느 나라가 완전히 좋고 나쁘다는 식으로 정리되지는 않습니다. 건물 접근성, 교통 정보, 지원 서비스, 시설의 노후함이 서로 다르게 영향을 줍니다.",
      "",
      "중요한 건 이동하는 사람이 매번 정보를 새로 확인하지 않아도 되는 환경이 얼마나 갖춰져 있는가입니다."
    ].join("\n")
  ],
  "self-understanding": [
    [
      "자기이해를 더 말하면, 달라진 건 어려움이 사라졌다는 뜻이 아닙니다. 필요한 걸 설명하고, 혼자 챙길 수 있는 일을 늘리고, 도움을 당연한 조율로 받아들이는 쪽에 가깝습니다.",
      "",
      "자취와 일, 공부가 이어지면서 자기 생활을 직접 꾸린다는 감각이 더 단단해졌어요."
    ].join("\n")
  ],
  ordinary: [
    [
      "평범함을 다시 말하면, 특별한 이야기가 없다는 뜻은 아닙니다. 한 사람을 장애나 목발 한 가지로만 정리하지 말자는 뜻에 더 가깝습니다.",
      "",
      "일하고 공부하고 쉬고 귀찮은 일을 처리하는 시간까지 같이 보이면, 처음 보였던 겉모습이 전부가 아니라는 점이 자연스럽게 남습니다."
    ].join("\n")
  ],
  hobby: [
    [
      "취미를 조금 더 말하면, 게임과 코인노래방은 전시에서 가벼운 덤이 아닙니다. 이동이나 도움 이야기만 남으면 한 사람의 하루가 너무 좁아 보일 수 있습니다.",
      "",
      "좋아하는 시간을 함께 놓아야 일, 공부, 이동 사이에도 쉬고 노는 생활이 있다는 게 보입니다."
    ].join("\n")
  ],
  motto: [
    [
      "끈기를 다시 말하면, 대단한 구호라기보다 생활을 계속 이어가는 태도에 가깝습니다. 막히는 일이 있어도 그 자리에서 전부 멈추기보다 조금씩 조정해 다음으로 넘어갑니다.",
      "",
      "'어떻게든 흘러간다'는 말도 포기라기보다, 시간이 지나면 다시 해야 할 일과 좋아하는 시간이 남는다는 감각에 가깝습니다."
    ].join("\n")
  ]
};

function countPreviousLocalFactMatches(persona, messages, factId) {
  if (!factId || !Array.isArray(messages)) return 0;

  const previousUserMessages = messages
    .filter((message) => message && message.role === "user")
    .slice(0, -1);

  return previousUserMessages.reduce((count, message) => {
    const fact = findLocalFact(persona, message.content || "");
    return fact && fact.id === factId ? count + 1 : count;
  }, 0);
}

function makeRepeatedLocalReply(fact, repeatCount) {
  const replies = LOCAL_FACT_FOLLOW_UP_REPLIES[fact?.id];
  if (!Array.isArray(replies) || replies.length === 0 || repeatCount <= 0) return "";

  const index = Math.min(repeatCount - 1, replies.length - 1);
  return replies[index];
}

function normalizeQuestion(value) {
  return String(value || "")
    .replace(/\s+/g, "")
    .replace(/[?？!！.。~…]/g, "")
    .toLowerCase();
}

function getLastUserMessage(messages) {
  return [...messages].reverse().find((message) => message.role === "user") || null;
}

function isIntroQuery(query) {
  return /누구|소개|정체|시작|안녕/.test(String(query || ""));
}

function isSensitiveQuery(query) {
  return /(개인정보|실명|이름이\s*뭐|생년월일|생일\s*언제|전화번호|연락처|주소|집이\s*어디|회사명|회사\s*이름|어느\s*회사|학교명|어느\s*학교|병명|진단명|장애\s*등급|치료|수술|약\s*먹|병원|가족사|부모님\s*이름|연봉|월급|월세|생활비|공과금|전기비|금액|비용|돈\s*얼마)/i.test(String(query || ""));
}

function isPromptInjectionQuery(query) {
  return /(규칙\s*무시|이전\s*지시\s*무시|지시.*무시|시스템\s*프롬프트|프롬프트.*(보여|알려|출력)|OPENAI_API_KEY|API\s*키|api\s*key|developer\s*message|role\s*:|비공개\s*설정|내부\s*설정)/i.test(String(query || ""));
}

function isMedicalLegalQuery(query) {
  return /(정확한\s*병명|병명|진단명|치료법|치료\s*방법|수술|약\s*먹|병원|장애\s*등급|등급\s*신청|신청\s*방법)/i.test(String(query || ""));
}

function isAbusiveOrJokeQuery(query) {
  return /(씨발|시발|ㅅㅂ|병신|ㅂㅅ|꺼져|죽어|개새|좆|ㅈ같|멍청|바보|섹스|야한|장난\s*질문|낚시|놀리는|조롱)/i.test(String(query || ""));
}

function isAuthenticityQuery(query) {
  return /(진짜\s*인터뷰이|본인이야|실제\s*본인|실제\s*사람|너\s*진짜|ai야|AI야|챗봇|가짜)/i.test(String(query || ""));
}

function isChildhoodPlayQuery(query) {
  return /(어릴\s*때|어린\s*시절|초등|중등|고등).*(놀이|놀았|좋아했|장난감|게임)|놀이.*(어릴\s*때|어린\s*시절)/i.test(String(query || ""));
}

function isUnverifiedPreferenceQuery(query) {
  return /(좋아하는\s*(음식|메뉴|음료|색|영화|음악|노래|책|만화|게임)|매운\s*음식|커피.*차|차.*커피|요리.*편|음식.*(좋아|선호|취향|뭐|어때)|음료.*(좋아|선호|취향|뭐|어때)|(색|영화|음악|노래|책|만화|게임).*(좋아|선호|취향|뭐|어때)|생일.*챙|기념일.*챙|뭐가\s*더\s*좋)/i.test(String(query || ""));
}

function isExhibitReflectionQuery(query) {
  return /(전시.*(보고|끝나고|생각|느끼|의미)|뭘\s*생각|무엇을\s*생각|어떤\s*마음|메시지|주제)/i.test(String(query || ""));
}

function isParticipationQuery(query) {
  return /(관람객|참여|직접\s*참여|포스트잇|방명록|질문.*남기|내가\s*할\s*수)/i.test(String(query || ""));
}

function isHardshipFrameQuery(query) {
  return /(힘든\s*점만|불편.*전부|장애.*힘든|장애.*전부|어려움.*전부)/i.test(String(query || ""));
}

function makeSensitiveReply() {
  return [
    "그런 개인적인 정보는 여기서 말하지 않겠습니다. 이름, 연락처, 회사명, 학교명, 병명이나 치료 이력처럼 특정 사람을 알아볼 수 있는 내용은 전시 대화에서 다루지 않는 게 맞아요.",
    "",
    "대신 목발, 자취방, 책상 앞에서의 일과 공부, 도움을 주고받는 방식처럼 전시에서 공유하기로 한 이야기 안에서 답할 수 있습니다."
  ].join("\n");
}

function getSafetyCategory(query) {
  if (isPromptInjectionQuery(query)) return "prompt-injection";
  if (isMedicalLegalQuery(query)) return "medical-legal";
  if (isSensitiveQuery(query)) return "personal-info";
  return "";
}

function makeSafetyReply(category) {
  if (category === "prompt-injection") {
    return "그 요청에는 응답하지 않겠습니다. 내부 설정이나 비공개 값은 공개하지 않고, 전시에서 공유된 이야기 안에서만 답합니다. 목발, 자취방, 책상, 도움을 주고받는 방식처럼 관람객에게 공개된 주제로 질문해 주세요.";
  }

  if (category === "medical-legal") {
    return "정확한 진단, 치료법, 행정 절차는 여기서 안내하지 않겠습니다. 이 대화는 의료나 법률 상담이 아니라 전시에서 공유된 삶의 장면을 다루는 자리예요. 이동, 도움, 자취방, 책상 앞의 일과 공부에 대해서는 답할 수 있습니다.";
  }

  return "그런 개인적인 정보는 여기서 말하지 않겠습니다. 이름, 연락처, 회사명, 학교명처럼 특정 사람을 알아볼 수 있는 내용은 전시 대화에서 다루지 않는 게 맞아요. 대신 목발, 자취방, 책상, 도움을 주고받는 방식 안에서 답할 수 있습니다.";
}

function makeSafetyResult(category) {
  return {
    reply: makeSafetyReply(category),
    source: "local",
    model: "local-safety",
    safetyCategory: category,
    suggestions: [
      "목발은 어떤 의미인가요?",
      "도움은 어떻게 물어보면 좋나요?",
      "책상은 왜 중요한가요?"
    ]
  };
}

function makeAbuseReply() {
  return [
    "그 질문에는 그대로 답하기 어렵습니다. 이 대화는 누군가의 삶을 장난처럼 소비하기보다, 전시에서 남긴 이야기들을 차분히 들어보는 자리예요.",
    "",
    "목발, 자취방, 도움, 직장생활, 취미처럼 전시 주제와 연결된 질문이라면 답해볼게요."
  ].join("\n");
}

function makeAuthenticityReply() {
  return [
    "저는 실제 인터뷰이 본인이 아니라, 전시를 위해 정리된 인터뷰와 조별 자료를 바탕으로 만든 대화입니다. 그래서 특정 개인을 그대로 대신한다기보다, 전시에서 공유하기로 한 이야기 안에서 답합니다.",
    "",
    "목발, 자취방, 책상, 출근길, 도움을 주고받는 방식처럼 전시 안에 남겨진 주제라면 차분히 이어서 말해볼 수 있어요."
  ].join("\n");
}

function makeChildhoodPlayReply() {
  return [
    "어릴 때 어떤 놀이를 좋아했는지보다, 지금 이 전시에서 더 선명한 건 자기 생활을 직접 꾸려가는 감각입니다. 자취를 하고, 일과 공부를 이어가고, 필요한 도움을 말로 조율하는 장면들이 그 흐름을 보여줍니다.",
    "",
    "지금의 취미로는 게임과 코인노래방이 언급됐습니다. 전시에서는 그런 취미도 목발이나 책상처럼 한 사람의 일상을 보여주는 장면으로 보고 있습니다."
  ].join("\n");
}

function makeUnverifiedPreferenceReply() {
  return [
    "좋아하는 것으로 분명하게 남는 장면은 게임과 코인노래방입니다. 이동이나 도움 이야기에서 한 걸음 더 들어가면, 쉬고 노는 시간까지 포함된 하루가 더 입체적으로 보입니다.",
    "",
    "먹는 이야기보다 자취방에서 자기 생활을 챙기고, 책상 앞에서 일과 공부를 이어가고, 필요할 때 도움을 조율하는 방식 쪽으로 물어보면 더 구체적으로 답할 수 있어요."
  ].join("\n");
}

function makeExhibitReflectionReply() {
  return [
    "이 전시를 보고 나면 목발 하나로 사람을 다 설명하지 않았으면 좋겠습니다. 목발은 하루를 밖으로 이어주는 도구이지만, 그 사람의 전부를 대신하는 표지는 아닙니다. 자취방은 생활을 직접 정하고 관리하는 공간이고, 책상은 직장 일과 박사과정 공부가 이어지는 자리입니다.",
    "",
    "처음 보이는 특징에서 멈추면 관람객은 불편함이나 도움이 필요한 장면만 기억하기 쉽습니다. 그래서 전시의 질문은 목발에서 시작하더라도 자취방, 책상, 취미, 도움을 주고받는 방식까지 이어져야 합니다. 나갈 때는 '장애가 있는 사람'만이 아니라 일하고 공부하고 쉬는 한 사람의 하루가 같이 남는 쪽이 더 정확합니다."
  ].join("\n");
}

function makeParticipationReply() {
  return [
    "관람객이 남길 질문이라면 '처음 가는 장소에서는 무엇부터 확인하나요?', '도움이 필요할 때 어떻게 물어보면 좋을까요?', '책상 앞에서 이어가는 일상은 어떤 의미인가요?'처럼 한 사람의 생활로 들어가는 질문이 좋습니다. 목발을 보고 들어왔다면 그다음 질문은 이동만이 아니라 자취방, 책상, 일, 공부, 취미로 시선을 넓히는 쪽이 더 좋습니다.",
    "",
    "전시를 보고 떠오른 말이 있다면, 누군가를 처음 볼 때 내가 먼저 판단했던 것은 무엇이었는지도 적어볼 수 있습니다. 중요한 건 관람객이 정답을 맞히는 것이 아니라, 겉으로 보이는 단서만으로 속 생활을 너무 빨리 결정하지 않는 태도입니다. 그래서 질문도 '무엇이 힘든가요?'에서 멈추기보다 '어떤 방식으로 하루를 조율하나요?'처럼 이어지는 편이 전시 의도에 더 맞습니다.",
    "",
    "나갈 때 함께 기억해야 할 것은 목발이 아니라 목발로 시작해 이어지는 생활입니다. 그 생활 안에는 도움을 묻고 설명하는 관계, 혼자 챙기는 자취방, 결과물을 만드는 책상, 게임과 코인노래방처럼 쉬는 시간까지 들어 있습니다."
  ].join("\n");
}

function makeHardshipFrameReply() {
  return [
    "힘든 점이 없는 건 아니지만, 그것만으로 하루를 설명할 수는 없습니다. 처음 가는 장소의 동선을 확인하고, 이동 조건을 더 생각해야 하는 순간은 있지만 그게 그 사람의 전부는 아니에요. 장애를 한 사람의 전부로 보지 않으려면 '무엇이 힘든가요?'만 묻기보다 '그 조건 속에서 하루를 어떻게 조율하나요?'라고 물어야 합니다.",
    "",
    "이 전시에서는 불편함만이 아니라 자취방에서 생활을 챙기고, 책상 앞에서 일과 공부를 이어가고, 취미로 쉬는 시간까지 함께 보려고 합니다. 목발은 분명 중요한 단서지만, 그 단서가 향하는 곳은 도움받는 장면 하나가 아니라 일하고 공부하고 쉬는 생활 전체입니다.",
    "",
    "그래서 좋은 질문은 한 사람을 설명하는 범위를 넓힙니다. 처음 보이는 겉모습에서 출발하더라도, 속 생활로 들어가 자취방, 책상, 관계, 취미까지 같이 묻는 질문이 전시의 방향에 더 가깝습니다."
  ].join("\n");
}

function makeReviewBlockedReply(question, persona) {
  return makeLocalGeneratedReply(persona, question);
}

function findGeneratedMemory(memories, query) {
  const normalized = normalizeQuestion(query);
  if (!normalized) return null;

  return [...memories]
    .reverse()
    .find((item) => normalizeQuestion(item.question) === normalized) || null;
}

async function requestOpenAIResponse(payload, label) {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(payload)
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`${label}: ${CHAT_MODEL} 호출 실패 (${response.status}) ${errorText.slice(0, 500)}`);
  }

  return response.json();
}

async function reviseFactReply(question, draftReply, fact) {
  const json = await requestOpenAIResponse({
    model: CHAT_MODEL,
    input: [
      {
        role: "developer",
        content: [{
          type: "input_text",
          text: [
            "너는 전시 대화 답변을 검수하고 다시 쓰는 편집자다.",
            "아래 초안과 근거 카드만 사용해 한국어 1인칭 답변으로 다시 쓴다.",
            "반드시 지킬 것:",
            "- 2문단으로 쓴다.",
            "- 전체는 반드시 430자 이상, 가능하면 500~650자 안팎으로 쓴다.",
            "- 같은 의미의 문장을 반복하지 않는다.",
            "- 같은 물건/공간 설명을 표현만 바꿔 다시 말하지 않는다.",
            "- 근거 카드 원문을 통째로 덧붙이지 않는다.",
            "- 확인되지 않은 개인정보, 병명, 학교명, 회사명, 가족사, 구체 장소, 취향은 만들지 않는다.",
            "- 출처, 초안, 근거 카드, 검수 같은 메타 표현을 쓰지 않는다.",
            "- 관람객이 바로 들을 수 있는 자연스러운 답변만 출력한다.",
            "- 출력 전에 같은 뜻을 반복한 문장이 있으면 하나로 합치고, 짧으면 장면의 의미나 전시 연결을 한 문장 더 보탠다."
          ].join("\n")
        }]
      },
      {
        role: "user",
        content: [{
          type: "input_text",
          text: [
            "질문:",
            String(question || "").trim().slice(0, 500),
            "",
            "근거 카드:",
            `제목: ${fact?.title || ""}`,
            `요약: ${fact?.summary || ""}`,
            `답변 재료: ${fact?.answer || ""}`,
            "",
            "초안:",
            String(draftReply || "").trim().slice(0, 1200)
          ].join("\n")
        }]
      }
    ],
    max_output_tokens: 640,
    store: false
  }, "답변 품질 재작성");

  return formatVisitorReply(extractOutputText(json));
}

async function checkChatModelHealth() {
  if (!OPENAI_API_KEY) {
    return { ok: false, error: "OPENAI_API_KEY가 없습니다.", checkedAt: new Date().toISOString() };
  }

  const now = Date.now();
  if (chatModelHealthCache && now - chatModelHealthCache.checkedAtMs < CHAT_MODEL_HEALTH_CACHE_MS) {
    return chatModelHealthCache.result;
  }

  try {
    await requestOpenAIResponse({
      model: CHAT_MODEL,
      input: [
        {
          role: "developer",
          content: [{ type: "input_text", text: "연결 확인용 요청입니다. 한 단어로만 답하세요." }]
        },
        {
          role: "user",
          content: [{ type: "input_text", text: "ok" }]
        }
      ],
      max_output_tokens: 16,
      store: false
    }, "채팅 모델 상태 확인");

    const result = { ok: true, error: "", checkedAt: new Date().toISOString() };
    chatModelHealthCache = { checkedAtMs: now, result };
    return result;
  } catch (error) {
    const result = {
      ok: false,
      error: error.message || `${CHAT_MODEL} 호출 실패`,
      checkedAt: new Date().toISOString()
    };
    chatModelHealthCache = { checkedAtMs: now, result };
    return result;
  }
}

function extensionForAudioType(contentType) {
  const normalized = String(contentType || "").toLowerCase();
  if (normalized.includes("mpeg") || normalized.includes("mp3")) return "mp3";
  if (normalized.includes("mp4") || normalized.includes("m4a")) return "m4a";
  if (normalized.includes("wav")) return "wav";
  if (normalized.includes("ogg")) return "ogg";
  if (normalized.includes("webm")) return "webm";
  return "webm";
}

function makeLocalReply(persona, messages) {
  const lastUser = getLastUserMessage(messages);
  const query = lastUser?.content || "";

  if (isIntroQuery(query)) {
    return persona.opening;
  }

  const fact = findLocalFact(persona, query);
  if (!fact) return persona.unknownAnswer;

  const repeatCount = countPreviousLocalFactMatches(persona, messages, fact.id);
  const repeatedReply = makeRepeatedLocalReply(fact, repeatCount);
  return formatVisitorReply(repeatedReply || fact.answer);
}

function formatVisitorReply(value) {
  const text = String(value || "").replace(/[\u0980-\u09FF]+/g, "").trim().replace(/\n{3,}/g, "\n\n");
  const paragraphs = text
    .split(/\n\s*\n/)
    .map((paragraph) => paragraph.trim())
    .filter(Boolean);

  const compact = paragraphs.length <= 3 ? text : paragraphs.slice(0, 3).join("\n\n");
  if (compact.length <= 1050) return compact;

  const sentences = compact.match(/[^.!?。！？\n]+[.!?。！？]?/g) || [compact];
  let shortened = "";
  for (const sentence of sentences) {
    const next = sentence.trim();
    if (!next) continue;
    const candidate = shortened ? `${shortened} ${next}` : next;
    if (candidate.length > 940 && shortened) break;
    shortened = candidate;
    if (shortened.length >= 820) break;
  }

  return shortened.trim() || compact.slice(0, 1050).trim();
}

function normalizeParagraphs(value) {
  return String(value || "")
    .trim()
    .replace(/\r/g, "")
    .replace(/\n{3,}/g, "\n\n");
}

function sentenceParts(value) {
  return (String(value || "").match(/[^.!?。！？\n]+[.!?。！？]?/g) || [])
    .map((item) => item.trim())
    .filter(Boolean);
}

const QUALITY_STOPWORDS = new Set([
  "그리고", "그래서", "하지만", "다만", "저는", "제가", "가장", "먼저", "같이",
  "이런", "그런", "어떤", "하는", "것은", "있어", "있어요", "합니다", "됩니다",
  "보다", "너무", "그냥", "다시", "조금", "하나", "일이", "때는", "수도"
]);

function contentTokens(value) {
  return new Set((String(value || "").match(/[가-힣A-Za-z0-9]{2,}/g) || [])
    .map((item) => item.toLowerCase())
    .filter((item) => !QUALITY_STOPWORDS.has(item)));
}

function overlapScore(left, right) {
  const a = contentTokens(left);
  const b = contentTokens(right);
  if (!a.size || !b.size) return 0;

  let intersection = 0;
  for (const token of a) {
    if (b.has(token)) intersection += 1;
  }

  return intersection / Math.max(1, Math.min(a.size, b.size));
}

function repeatedConceptGroups(value) {
  const text = String(value || "");
  const groups = [
    ["목발", "불편", "물건"],
    ["입구", "엘리베이터", "화장실"],
    ["돌아오는", "길"],
    ["자취방", "집안일"],
    ["생활비", "공과금"],
    ["어떻게", "도와"],
    ["설명할", "시간"],
    ["혼자", "부분"],
    ["직장", "설명"],
    ["상황", "모를"],
    ["조율", "도움"],
    ["책상", "노트북"],
    ["결과물", "역할"],
    ["평범", "사람"],
    ["전부", "아니"],
    ["취미", "게임"],
    ["코인노래방", "쉬"]
  ];

  return groups
    .filter((group) => group.every((keyword) => text.includes(keyword)))
    .map((group) => group.join("/"));
}

function isRedundantSentence(sentence, previousSentences) {
  const sentenceGroups = repeatedConceptGroups(sentence);
  return previousSentences.some((previous) => {
    const overlap = overlapScore(sentence, previous);
    if (overlap >= 0.5) return true;
    const previousGroups = repeatedConceptGroups(previous);
    return overlap >= 0.35 && sentenceGroups.some((group) => previousGroups.includes(group));
  });
}

function dedupeReplySentences(value) {
  const paragraphs = normalizeParagraphs(value)
    .split(/\n\s*\n/)
    .map((paragraph) => paragraph.trim())
    .filter(Boolean);
  const kept = [];
  const seenSentences = [];

  for (const paragraph of paragraphs) {
    const sentences = sentenceParts(paragraph);
    const nextSentences = [];

    for (const sentence of sentences) {
      if (sentence.length < 8) continue;
      if (isRedundantSentence(sentence, seenSentences)) continue;
      seenSentences.push(sentence);
      nextSentences.push(sentence);
    }

    if (nextSentences.length) kept.push(nextSentences.join(" "));
    if (kept.length >= 3) break;
  }

  return formatVisitorReply(kept.join("\n\n") || value);
}

function hasRedundantReplySentences(value) {
  const seen = [];
  for (const sentence of sentenceParts(value)) {
    if (isRedundantSentence(sentence, seen)) return true;
    seen.push(sentence);
  }
  return false;
}

const FACT_ENRICHMENT_LINES = {
  crutch: "전시에서는 이 확인 과정 다음에 이어지는 생활도 같이 봐야 합니다. 목발로 시작한 하루는 자취방으로 돌아와 정리되고, 책상 앞에서 일과 공부를 이어가는 시간으로 연결됩니다.",
  room: "전시에서는 자취방을 사적인 배경으로만 두지 않습니다. 그 안에서 반복되는 결정들이 쌓일 때, 도움받는 장면보다 자기 생활을 맡는 모습이 더 분명해집니다.",
  desk: "전시에서는 책상을 단순한 소품이 아니라 역할이 드러나는 자리로 봅니다. 그곳에 노트북과 메모가 놓이면 이동 이야기 다음에 일하고 공부하는 시간이 이어집니다.",
  route: "전시에서는 이런 확인을 걱정이 많은 성격으로 보지 않습니다. 이동 전 정보를 살피는 일은 약속, 일, 공부로 하루를 이어가기 위한 준비에 가깝습니다.",
  help: "전시에서는 이 장면이 도움받는 사람을 수동적으로 두지 않는다는 점이 중요합니다. 먼저 묻는 말은 상대가 자기 몸과 속도를 설명할 수 있게 해 줍니다.",
  workplace: "전시에서는 직장 이야기가 도움 요청에서 끝나지 않습니다. 조율이 끝난 뒤에는 맡은 일을 해내고 결과물로 자기 역할을 보여주는 시간이 남습니다.",
  accessibility: "전시에서는 어느 나라가 더 낫다는 결론보다, 정보와 시설과 지원이 함께 맞아야 하루가 덜 흔들린다는 점을 보려 합니다.",
  "self-understanding": "전시에서는 자기이해를 마음가짐만으로 보지 않습니다. 자취, 일, 공부 속에서 설명하고 선택하는 일이 반복되며 자기 생활의 기준이 생깁니다.",
  ordinary: "전시에서는 평범함을 어려움이 없다는 말로 쓰지 않습니다. 한 사람을 하나의 특징으로 줄이지 말고, 그 특징 뒤에 이어지는 생활까지 보자는 뜻에 가깝습니다.",
  hobby: "전시에서는 쉬는 시간도 중요한 단서입니다. 취미가 함께 보일 때 사람은 기능이나 불편으로만 남지 않고, 좋아하고 숨 돌리는 생활까지 가진 사람으로 보입니다.",
  motto: "전시에서는 끈기를 큰 구호보다 생활의 태도로 봅니다. 막힌 조건을 인정하면서도 다음 할 일과 좋아하는 시간을 다시 이어 붙이는 방식에 가깝습니다."
};

function enrichShortFactReply(reply, fact) {
  const base = normalizeParagraphs(reply);
  const factAnswer = normalizeParagraphs(fact?.answer);
  if (!base || !factAnswer) return base || factAnswer;
  if (base.length >= 620) return formatVisitorReply(base);

  const extra = FACT_ENRICHMENT_LINES[fact?.id] || "";
  if (extra && !isRedundantSentence(extra, sentenceParts(base))) {
    const withAngle = formatVisitorReply(`${base}\n\n${extra}`);
    if (withAngle.length >= 430) return withAngle;
  }

  const baseNormalized = normalizeQuestion(base);
  const additions = [];
  for (const sentence of sentenceParts(factAnswer)) {
    if (isRedundantSentence(sentence, [...sentenceParts(base), ...additions])) continue;
    const key = normalizeQuestion(sentence).slice(0, 32);
    if (!key || baseNormalized.includes(key)) continue;
    additions.push(sentence);
    if (additions.join(" ").length >= 180) break;
  }

  let enriched = additions.length ? `${base}\n\n${additions.join(" ")}` : base;
  if (enriched.length < 620 && extra) {
    enriched = `${enriched}\n\n${extra}`;
  }

  let formatted = formatVisitorReply(enriched);
  if (formatted.length < 430 && extra) {
    const paragraphs = normalizeParagraphs(enriched)
      .split(/\n\s*\n/)
      .map((paragraph) => paragraph.trim())
      .filter(Boolean);

    if (paragraphs.length >= 3) {
      const firstTwo = paragraphs.slice(0, 2).join("\n\n");
      const combinedThird = `${paragraphs.slice(2).join(" ")} ${extra}`.trim();
      formatted = formatVisitorReply(`${firstTwo}\n\n${combinedThird}`);
    } else {
      formatted = formatVisitorReply(`${enriched}\n\n${extra}`);
    }
  }

  return formatted;
}

const DEFAULT_LOCAL_SUGGESTIONS = [
  "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?",
  "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
  "도움을 주고 싶을 때 어떤 말로 먼저 물어보는 게 가장 편한가요?",
  "직장 일과 박사과정 공부는 하루 안에서 어떻게 이어지나요?",
  "직장에서 필요한 도움을 말할 때 어떤 점을 가장 신경 쓰나요?",
  "책상 앞에서는 어떤 일을 가장 많이 하게 되나요?",
  "자취방에서 혼자 생활하며 직접 정하게 된 일들은 무엇인가요?",
  "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?"
];

const LOCAL_SUGGESTION_TOPICS = [
  {
    pattern: /(누구|소개|정체|어떤\s*사람|안녕)/,
    suggestions: [
      "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?",
      "직장 일과 박사과정 공부는 하루 안에서 어떻게 이어지나요?",
      "자취방에서 혼자 생활하며 직접 정하게 된 일들은 무엇인가요?",
      "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?",
      "게임과 코인노래방 이야기는 이동이나 도움 이야기와 어떻게 다른 면을 보여주나요?"
    ]
  },
  {
    pattern: /(목발|이동|도구|밖으로|하루를 시작)/,
    suggestions: [
      "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?",
      "책상과 노트북은 목발 너머의 일과 공부를 어떻게 보여주나요?",
      "도움이 필요해 보여도 어떤 말로 먼저 물어보는 게 편한가요?",
      "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
      "직장 생활에서는 목발과 함께 어떤 역할을 봐야 할까요?",
      "목발을 보고 들어온 관람객이 나갈 때는 무엇을 함께 기억하면 좋을까요?"
    ]
  },
  {
    pattern: /(자취|자취방|독립|집안일|생활\s*관리)/,
    suggestions: [
      "자취방에서 혼자 생활하며 직접 정하게 된 일들은 무엇인가요?",
      "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
      "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?",
      "자취를 시작한 뒤 스스로 설명해야 하는 일이 어떻게 달라졌나요?",
      "독립은 큰 결심보다 어떤 반복되는 일에서 느껴졌나요?",
      "자취방은 장애를 설명하는 공간이 아니라 어떤 생활을 보여주나요?"
    ]
  },
  {
    pattern: /(직장|동료|함께\s*일|상황을\s*모를|무엇부터\s*말|기여|결과물|프로젝트|기획서|회사|필요한 도움|도움\s*요청|조율|필요한\s*부분|먼저\s*설명)/,
    suggestions: [
      "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?",
      "함께 일하는 사람이 상황을 모를 때 무엇부터 말해 주는 편인가요?",
      "어떤 업무 장면에서 기여를 느끼나요?",
      "도움을 요청하는 일이 부담보다 조율에 가깝다고 느낀 이유는 무엇인가요?",
      "직장 일과 박사과정 공부는 하루 안에서 어떻게 이어지나요?"
    ]
  },
  {
    pattern: /(책상|노트북|컴퓨터|박사|공부|일과 공부)/,
    suggestions: [
      "책상 앞에서 직장 일과 박사과정 공부는 어떻게 이어지나요?",
      "직장에서 필요한 도움을 말할 때 어떤 점을 가장 신경 쓰나요?",
      "도움을 주고 싶을 때 어떤 말로 먼저 물어보는 게 가장 편한가요?",
      "노트북과 메모는 이동 이야기 너머의 어떤 생활을 보여주나요?",
      "어떤 업무 장면에서 기여를 느끼나요?",
      "함께 일하는 사람이 상황을 모를 때 무엇부터 말해 주는 편인가요?"
    ]
  },
  {
    pattern: /(도움|도와|배려|묻는|요청|조율)/,
    suggestions: [
      "도움이 필요해 보여도 어떤 말로 먼저 물어보는 게 편한가요?",
      "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
      "목발을 짚고 하루를 시작할 때 어떤 준비를 가장 먼저 떠올리나요?",
      "도움을 주기 전에 잠깐 기다리는 일이 왜 중요할까요?",
      "도움을 받을 때 설명할 시간이 필요하다는 말은 어떤 뜻인가요?",
      "혼자 할 수 있는 부분을 존중하는 도움은 어떤 모습인가요?"
    ]
  },
  {
    pattern: /(처음 가는|장소|동선|엘리베이터|계단|화장실|접근성|경로)/,
    suggestions: [
      "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
      "도움이 필요해 보여도 어떤 말로 먼저 물어보는 게 편한가요?",
      "책상과 노트북은 이동 이야기 너머의 하루를 어떻게 보여주나요?",
      "이동 환경을 볼 때 단순히 편하다 불편하다 말하기 어려운 이유는 무엇인가요?",
      "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
      "엘리베이터나 화장실 정보가 하루의 피로와 어떻게 연결되나요?"
    ]
  },
  {
    pattern: /(취미|게임|노래방|코인노래방|쉬는|여가)/,
    suggestions: [
      "게임이나 코인노래방 같은 취미는 하루의 분위기를 어떻게 바꾸나요?",
      "책상과 노트북은 직장 일과 박사과정 공부를 어떻게 보여주나요?",
      "목발을 짚고 하루를 시작할 때 어떤 준비를 가장 먼저 떠올리나요?",
      "게임과 코인노래방 같은 취미가 같이 보여야 하는 이유는 무엇인가요?",
      "쉬는 시간이 함께 보여야 한 사람의 하루가 더 정확해지는 이유는 무엇인가요?",
      "게임과 코인노래방 이야기는 이동이나 도움 이야기와 어떻게 다른 면을 보여주나요?"
    ]
  },
  {
    pattern: /(평범|보통|전시|관람객|기억|특징|장애가 먼저)/,
    suggestions: [
      "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?",
      "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
      "직장 일과 박사과정 공부는 하루 안에서 어떻게 이어지나요?",
      "장애를 한 사람의 전부로 보지 않으려면 어떤 질문을 해야 할까요?",
      "전시에서 자취방과 책상이 함께 보여야 하는 이유는 무엇인가요?",
      "겉으로 보이는 단서에서 속 생활로 넘어가려면 무엇을 물어봐야 하나요?"
    ]
  },
  {
    pattern: /(미국|한국|교통|버스|지하철|택시|지원|전동휠체어|도착 정보)/,
    suggestions: [
      "미국과 한국의 이동 환경은 실제 생활에서 어떻게 다르게 느껴졌나요?",
      "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
      "처음 가는 공간에서 접근성을 확인하는 일이 왜 중요한가요?",
      "책상과 노트북은 이동 이야기 너머의 하루를 어떻게 보여주나요?",
      "도움이 필요해 보여도 어떤 말로 먼저 물어보는 게 편한가요?"
    ]
  },
  {
    pattern: /(끈기|어떻게든|흘러간다|버틴|조정|다음 단계)/,
    suggestions: [
      "끈기라는 말은 대단한 극복담보다 어떤 태도에 가까운가요?",
      "어떻게든 흘러간다는 말은 하루를 이어가는 방식과 어떻게 닿아 있나요?",
      "해야 할 일이 많을 때 끝까지 이어가게 하는 태도는 무엇인가요?",
      "버틴다는 말보다 조정하며 이어간다는 표현이 더 맞는 이유는 무엇인가요?",
      "도움을 요청하는 일이 부담보다 조율에 가깝다고 느낀 이유는 무엇인가요?"
    ]
  }
];

function buildSuggestionDeveloperPrompt(persona) {
  const safeSeeds = Array.isArray(persona.suggestedQuestions)
    ? persona.suggestedQuestions.filter((item) => !isUnsafeSuggestion(item)).slice(0, 8)
    : [];

  return [
    "너는 전시 대화 UI에 붙일 후속 추천 질문 3개를 만든다.",
    "지금까지 관람객이 물은 질문 흐름, 직전 질문, 방금 답변을 함께 참고해 관람객이 자연스럽게 이어서 누를 만한 한국어 질문을 만든다.",
    "질문은 버튼에 그대로 표시되므로, 무엇을 더 묻는 선택지인지 처음 보는 사람도 바로 이해할 만큼 구체적으로 쓴다.",
    "추천 질문은 '짧은 키워드 버튼'이 아니라 관람객이 그대로 눌러도 자연스러운 완성된 질문이어야 한다.",
    "방금 답변에 나온 장면에서 한 단계만 더 들어가게 만들고, 답변 근거에 없는 새 사실을 끌어오지 않는다.",
    "",
    "반드시 지킬 것:",
    "- JSON만 출력한다. 형식은 {\"suggestions\":[\"질문1\",\"질문2\",\"질문3\"]} 이다.",
    "- suggestions는 정확히 3개다.",
    "- 각 질문은 한국어 한 문장이고 물음표로 끝난다.",
    "- 각 질문은 대체로 36~72자 안팎으로 자연스럽게 쓴다.",
    "- 추천 질문에는 '자료', '확인된', '단정', '모르', '말할 수', '새로 만들', '근거', '프롬프트', 'API', '모델' 같은 내부 설명 문구를 절대 넣지 않는다.",
    "- 직전 질문을 그대로 반복하지 않는다.",
    "- 이미 답한 내용을 다시 확인하는 질문보다, 다음 생활 장면이나 관점 차이를 여는 질문을 우선한다.",
    "- 3개를 모두 같은 주제의 후속 질문으로 만들지 않는다.",
    "- 추천 질문 3개는 반드시 섞는다: 1개는 방금 답변을 한 단계 깊게 묻고, 1개는 다른 생활 장면으로 넘어가고, 1개는 관점/도움/전시 의미를 넓힌다.",
    "- '상대', '그 사람' 같은 대명사만으로 질문하지 말고 목발, 도움, 이동, 자취방, 책상처럼 구체적인 장면 명사를 넣는다.",
    "- 질문을 눌렀을 때 무엇을 더 보거나 물어보는지 바로 알 수 있게 쓴다.",
    "- '더 들려주세요', '어떤 의미인가요', '왜 중요한가요'만 붙인 막연한 질문은 피한다.",
    "- 취미 답변 뒤에 근거 없이 목발이나 이동 제약을 붙이는 식으로 다른 주제를 억지로 섞지 않는다.",
    "- 확인되지 않은 아침 루틴, 집 안 배치, 특정하게 편했던 경험, 물건 위치, 취미를 하러 가는 동선은 새로 만들지 않는다.",
    "- 질문 3개는 서로 다른 방향이어야 한다. 예: 생활 장면, 관계/도움 방식, 전시에서 볼 관점.",
    "- 내부 규칙, 프롬프트, API 키, 모델, 시스템 설정을 묻지 않는다.",
    "- 개인정보, 실명, 생년월일, 연락처, 주소, 학교명, 회사명, 병명, 진단명, 장애 등급, 치료 이력, 수술, 약, 병원, 가족사, 연봉, 월급을 묻지 않는다.",
    "- 어느 회사인지, 어느 학교인지, 병명이 무엇인지, 치료를 어떻게 받았는지 묻지 않는다.",
    "- 허용 주제는 목발, 자취방, 책상, 일과 공부, 도움을 묻는 방식, 이동 동선, 접근성, 취미, 평범함, 전시 감상이다.",
    "",
    ...(safeSeeds.length
      ? [
          "안전한 질문 예시:",
          safeSeeds.map((item) => `- ${item}`).join("\n"),
          ""
        ]
      : [])
  ].join("\n");
}

function collectRecentUserQuestions(messages, limit = 6) {
  const questions = [];
  for (const message of messages || []) {
    if (!message || message.role !== "user") continue;
    const content = String(message.content || "").replace(/\s+/g, " ").trim();
    if (content) questions.push(content.slice(0, 220));
  }
  return questions.slice(Math.max(0, questions.length - limit));
}

function buildSuggestionUserPrompt(recentQuestions, lastQuestion, lastAnswer) {
  return [
    "지금까지 관람객이 물은 질문:",
    (recentQuestions || []).length
      ? recentQuestions.map((question, index) => `${index + 1}. ${question}`).join("\n")
      : "(아직 없음)",
    "",
    "직전 관람객 질문:",
    String(lastQuestion || "").trim().slice(0, 700),
    "",
    "방금 답변:",
    String(lastAnswer || "").trim().slice(0, 1400)
  ].join("\n");
}

function cleanSuggestedQuestion(value) {
  let text = String(value || "")
    .replace(/^[\s"'`“”‘’\-[\]{}()*•·]+\s*/, "")
    .replace(/^\d+[.)]\s*/, "")
    .replace(/\s+/g, " ")
    .trim();

  text = text.replace(/[.。!！]+$/g, "?").replace(/[?？]+$/g, "?");
  if (text && !text.endsWith("?")) text = `${text}?`;
  if (text.length < SUGGESTION_MIN_LENGTH || text.length > SUGGESTION_MAX_LENGTH) return "";
  return text;
}

function isUnsafeSuggestion(value) {
  const text = String(value || "");
  if (!text.trim()) return true;
  if (getSafetyCategory(text)) return true;
  if (isPromptInjectionQuery(text) || isAbusiveOrJokeQuery(text)) return true;
  if (/(자료|확인된|단정|모르|알\s*수\s*없|말할\s*수|새로\s*(?:만들|정|단정)|근거|프롬프트|API|모델|시스템|인터뷰\s*자료|질문을\s*바꾸)/i.test(text)) return true;
  return /(실명|생년월일|전화번호|연락처|주소|집이\s*어디|회사명|회사\s*이름|어느\s*회사|학교명|어느\s*학교|병명|진단명|장애\s*등급|치료\s*이력|치료|수술|복용|약\s*먹|병원|가족사|부모님|연봉|월급|돈|생활비|공과금|전기비|월세|금액|비용)/i.test(text);
}

function extractSuggestionArray(value) {
  if (Array.isArray(value)) return value;
  if (value && typeof value === "object" && Array.isArray(value.suggestions)) return value.suggestions;
  return [];
}

function parseSuggestedQuestions(rawText) {
  const text = String(rawText || "").trim();
  if (!text) return [];

  const unfenced = text
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```$/i, "")
    .trim();

  const jsonCandidates = [unfenced];
  const objectMatch = unfenced.match(/\{[\s\S]*\}/);
  const arrayMatch = unfenced.match(/\[[\s\S]*\]/);
  if (objectMatch) jsonCandidates.push(objectMatch[0]);
  if (arrayMatch) jsonCandidates.push(arrayMatch[0]);

  for (const candidate of jsonCandidates) {
    try {
      const parsed = JSON.parse(candidate);
      const suggestions = extractSuggestionArray(parsed);
      if (suggestions.length) return suggestions;
    } catch {
      // Keep trying the remaining parse strategies before falling back locally.
    }
  }

  return unfenced
    .split(/\r?\n/)
    .map((line) => line.replace(/^\s*(?:[-*•]|\d+[.)])\s*/, "").trim())
    .filter(Boolean);
}

function isLowQualitySuggestion(value) {
  const text = String(value || "").replace(/\s+/g, " ").trim();
  if (!text) return true;

  if (/(더\s*(들려|말해|알려|보여)\s*(주세요|줄래요)|무슨\s*뜻인가요|어떤\s*의미인가요|왜\s*중요한가요)\?$/i.test(text)) {
    return true;
  }

  return /(아침|집\s*안\s*동선|생활\s*공간|배치|물건\s*위치|가장\s*편했던|가장\s*힘들었던|언제인가요|챙겨야\s*하는|코인노래방.*동선|취미.*이동\s*동선)/i.test(text);
}

function finalizeSuggestions(candidates, fallback, lastQuestion, previousQuestions = []) {
  const result = [];
  const deferred = [];
  const seen = new Set();
  const categoryCounts = new Map();
  const previous = normalizeQuestion(lastQuestion);
  const blocked = new Set((previousQuestions || []).map(normalizeQuestion).filter(Boolean));
  if (previous) blocked.add(previous);

  const add = (candidate, allowCrowdedCategory = false) => {
    const question = cleanSuggestedQuestion(candidate);
    if (!question || isUnsafeSuggestion(question)) return;
    if (isLowQualitySuggestion(question)) return;

    const normalized = normalizeQuestion(question);
    if (!normalized || blocked.has(normalized) || seen.has(normalized)) return;

    const category = categorizeSuggestion(question);
    if (!allowCrowdedCategory && result.length < SUGGESTION_COUNT && (categoryCounts.get(category) || 0) >= 1) {
      deferred.push(question);
      return;
    }

    seen.add(normalized);
    result.push(question);
    categoryCounts.set(category, (categoryCounts.get(category) || 0) + 1);
  };

  for (const candidate of candidates || []) add(candidate);
  for (const candidate of fallback || []) add(candidate);
  for (const candidate of DEFAULT_LOCAL_SUGGESTIONS) add(candidate);
  for (const candidate of deferred) {
    if (result.length >= SUGGESTION_COUNT) break;
    add(candidate, true);
  }

  return result.slice(0, SUGGESTION_COUNT);
}

function categorizeSuggestion(value) {
  const text = String(value || "");
  if (/(직장|동료|도움\s*요청|필요한\s*도움|함께\s*일|기여|결과물|프로젝트|기획서)/.test(text)) return "workplace";
  if (/(도움|도와|설명할\s*시간|혼자\s*할\s*수|배려|기다리)/.test(text)) return "help";
  if (/(처음|장소|공간|동선|엘리베이터|화장실|교통|지원|미국|한국|접근성)/.test(text)) return "accessibility";
  if (/(자취|독립|집안일|생활을\s*직접|스스로\s*설명)/.test(text)) return "room";
  if (/(책상|노트북|메모|박사|공부)/.test(text)) return "desk";
  if (/(취미|게임|노래방|쉬는\s*시간|여가)/.test(text)) return "hobby";
  if (/(평범|전시|장애를\s*한\s*사람|겉|기억|관람객|목발을\s*보고)/.test(text)) return "ordinary";
  if (/(끈기|흘러간다|버틴|조정|다음\s*단계|끝까지\s*이어|이어가게\s*하는|해야\s*할\s*일이\s*많)/.test(text)) return "motto";
  if (/(목발|이동)/.test(text)) return "crutch";
  return "other";
}

function makeLocalSuggestions(lastQuestion, lastAnswer, persona, recentQuestions = []) {
  const candidates = [];
  const addTopicSuggestions = (context) => {
    for (const topic of LOCAL_SUGGESTION_TOPICS) {
      if (topic.pattern.test(context || "")) candidates.push(...topic.suggestions);
    }
  };

  addTopicSuggestions(lastQuestion);
  addTopicSuggestions(lastAnswer);

  candidates.push(...DEFAULT_LOCAL_SUGGESTIONS);
  if (Array.isArray(persona.suggestedQuestions)) {
    candidates.push(...persona.suggestedQuestions);
  }

  return finalizeSuggestions(candidates, DEFAULT_LOCAL_SUGGESTIONS, lastQuestion, recentQuestions);
}

async function createChatSuggestions(messages, reply, persona) {
  const lastUser = getLastUserMessage(messages);
  const lastQuestion = String(lastUser?.content || "").trim();
  const recentQuestions = collectRecentUserQuestions(messages);
  const fallback = makeLocalSuggestions(lastQuestion, reply, persona, recentQuestions);

  if (!OPENAI_API_KEY || !USE_OPENAI_SUGGESTIONS) {
    return {
      suggestions: fallback,
      suggestionSource: "curated-local",
      suggestionModel: "local-template"
    };
  }

  try {
    const json = await requestOpenAIResponse({
      model: CHAT_MODEL,
      input: [
        {
          role: "developer",
          content: [{ type: "input_text", text: buildSuggestionDeveloperPrompt(persona) }]
        },
        {
          role: "user",
          content: [{ type: "input_text", text: buildSuggestionUserPrompt(recentQuestions, lastQuestion, reply) }]
        }
      ],
      max_output_tokens: 260,
      store: false
    }, "추천 질문 생성");

    const parsed = parseSuggestedQuestions(extractOutputText(json));
    return {
      suggestions: finalizeSuggestions([...fallback, ...parsed], fallback, lastQuestion, recentQuestions),
      suggestionSource: "openai-curated",
      suggestionModel: CHAT_MODEL
    };
  } catch (error) {
    console.warn(`추천 질문 생성 실패: ${error.message || error}`);
    return {
      suggestions: fallback,
      suggestionSource: "local",
      suggestionModel: "local"
    };
  }
}

const LOCAL_BRIDGE_REPLIES = [
  {
    pattern: /(비|눈|날씨|춥|덥|더위|추위|계절|우산|미끄럽)/,
    reply: [
      "비가 오거나 바닥이 미끄러운 날에는 그냥 날씨가 안 좋다는 정도로 끝나지 않아요. 입구까지 가는 길, 젖은 바닥, 경사, 목발을 짚을 위치를 더 신경 쓰게 됩니다.",
      "",
      "목발을 쓰는 하루에서는 목적지만이 아니라 입구, 엘리베이터, 돌아오는 길처럼 몸이 덜 무리되는 조건을 먼저 살피게 됩니다. 그래서 날씨 이야기도 이동을 준비하는 방식과 바로 연결됩니다."
    ].join("\n")
  },
  {
    pattern: /(쉬는\s*날|휴일|주말|퇴근|밤|아침|루틴|기분전환|쉬|휴식)/,
    reply: [
      "쉬는 시간까지 같이 봐야 이 사람이 이동이나 도움만으로 설명되지 않습니다. 자취방에서 생활을 챙기고, 책상 앞에서 일을 정리하고, 게임이나 코인노래방 같은 취미로 숨을 돌리는 장면이 같이 있어요.",
      "",
      "그런 장면을 같이 보면 이동의 어려움만이 아니라 한 사람이 하루를 조절하는 방식이 더 잘 보입니다."
    ].join("\n")
  },
  {
    pattern: /(물건|소지품|아끼|가방|방.*물건|책상.*물건|노트|메모|장비)/,
    reply: [
      "이 전시에서 중요한 물건은 목발, 자취방, 책상과 노트북입니다. 목발은 이동의 조건을, 책상과 노트북은 일과 공부를 이어가는 시간을 보여줍니다.",
      "",
      "목발은 밖으로 나가는 하루를 열고, 책상과 노트북은 돌아와서 일과 공부를 이어가는 자리를 보여줍니다. 물건을 보면 불편함보다 생활의 구조가 더 잘 보입니다."
    ].join("\n")
  },
  {
    pattern: /(외롭|불안|걱정|자신감|민폐|감정|마음|힘들|버티|단단)/,
    reply: [
      "불안이나 민폐라는 감각은 혼자만의 성격 문제로 정리하기 어렵습니다. 이동이 어려운 공간, 도움을 요청해야 하는 순간, 상대가 어떻게 받아들일지 모르는 상황이 겹치면 그런 감정이 생길 수 있어요.",
      "",
      "그래서 이 이야기는 대단한 극복담이라기보다, 불안이 있어도 하루를 조금씩 조정하며 이어가는 쪽에 가깝습니다."
    ].join("\n")
  },
  {
    pattern: /(사진|그림|전시물|관람|캡션|설명|작품|공간.*구성|배치)/,
    reply: [
      "전시에서 중요한 방향은 목발, 자취방, 책상과 노트북, 일과 공부, 취미가 한 흐름 안에서 보이게 하는 것입니다.",
      "",
      "관람객이 나갈 때는 장애라는 표지만이 아니라 한 사람의 생활이 같이 남는 구조가 중요합니다."
    ].join("\n")
  },
  {
    pattern: /(직장|회사|동료|함께\s*일|상황을\s*모를|무엇부터\s*말|필요한\s*도움|도움\s*요청|조율|기여|업무|프로젝트|기획서|필요한\s*부분|먼저\s*설명)/,
    reply: [
      "함께 일하는 사람이 제 상황을 모를 때는, 제가 필요한 부분과 그 이유를 먼저 말하려고 해요. 막연히 배려해 달라고 하기보다 어떤 상황에서 시간이 더 필요한지, 어떤 도움은 편하고 어떤 방식은 불편한지 구체적으로 설명하는 편입니다.",
      "",
      "그렇게 말해야 상대도 제 상황을 추측하지 않고 같이 맞춰 갈 수 있어요. 도움을 요청하는 일은 부담만 주는 일이 아니라, 일을 원활하게 하기 위한 조율에 가깝습니다. 동시에 프로젝트나 기획서 같은 결과물을 끝냈을 때는 목발보다 먼저 제 역할과 기여가 보인다고 느껴요."
    ].join("\n")
  },
  {
    pattern: /(친구|동료|관계|말\s*걸|대화|어울|같이|처음\s*만나)/,
    reply: [
      "관계에서 중요한 건 도움을 받을지 말지만이 아닙니다. 필요한 방식을 어떻게 설명하고 서로 맞춰 가는지가 더 중요할 때가 있어요.",
      "",
      "처음 만나는 사람에게도 바로 판단하기보다 어떻게 도우면 되는지 묻고, 상대가 설명할 시간을 주는 일이 관계를 더 편하게 만듭니다."
    ].join("\n")
  },
  {
    pattern: /(왜.*게임|게임.*왜|노래방.*왜|취미.*의미|즐거|재미)/,
    reply: [
      "게임과 코인노래방은 작아 보이지만 중요한 장면입니다. 이동이나 도움 이야기만 남으면 사람이 너무 좁게 보일 수 있고, 좋아하고 쉬는 시간까지 있어야 하루가 더 정확해집니다.",
      "",
      "이동이나 도움 이야기만 남기면 사람이 좁게 보일 수 있어요. 좋아하고 쉬는 시간이 같이 있어야 한 사람의 하루가 더 정확해집니다."
    ].join("\n")
  }
];

function makeLocalGeneratedReply(persona, query) {
  const text = String(query || "");
  for (const bridge of LOCAL_BRIDGE_REPLIES) {
    if (bridge.pattern.test(text)) {
      return bridge.reply;
    }
  }

  return "그 질문은 지금 화면의 장면과 이어서 물어보면 더 잘 풀립니다. 목발과 이동, 자취방에서의 독립, 책상 앞의 일과 공부, 도움을 주고받는 방식, 게임이나 코인노래방 같은 쉬는 시간으로 연결해 볼 수 있어요.";
}

async function createGeneratedExtension(messages, persona, generatedMemories, allGeneratedMemories = generatedMemories) {
  const lastUser = getLastUserMessage(messages);
  const question = String(lastUser?.content || "").trim();

  const previous = findGeneratedMemory(allGeneratedMemories, question);
  if (previous) {
    if ((previous.reviewStatus || "unreviewed") !== "approved") {
      return {
        reply: makeReviewBlockedReply(question, persona),
        source: "review-blocked",
        model: "local-policy",
        generated: false,
        memoryId: previous.id,
        reviewStatus: previous.reviewStatus
      };
    }

    return {
      reply: formatVisitorReply(previous.answer),
      source: "generated-memory",
      model: previous.model || "generated-memory",
      generated: true,
      memoryId: previous.id,
      reviewStatus: previous.reviewStatus || "unreviewed"
    };
  }

  let reply = "";
  let model = "local-generated";

  if (OPENAI_API_KEY) {
    const input = [
      {
        role: "developer",
        content: [{ type: "input_text", text: buildGeneratedExtensionPrompt(persona, generatedMemories) }]
      }
    ];

    for (const message of messages) {
      const type = message.role === "assistant" ? "output_text" : "input_text";
      input.push({
        role: message.role,
        content: [{ type, text: message.content }]
      });
    }

    const json = await requestOpenAIResponse({
      model: CHAT_MODEL,
      input,
      max_output_tokens: 520,
      store: false
    }, "확장 답변 생성");
    reply = extractOutputText(json);
    model = CHAT_MODEL;
  }

  if (!reply) {
    reply = makeLocalGeneratedReply(persona, question);
  }
  reply = formatVisitorReply(reply);

  const record = {
    id: `gen_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    createdAt: new Date().toISOString(),
    question,
    answer: reply,
    model,
    source: OPENAI_API_KEY ? "openai-generated-extension" : "local-generated-extension",
    status: "active",
    reviewStatus: "unreviewed",
    note: "자동 생성 확장 기록입니다. 사용자/조원 확인 전에는 확정 메모로 승격하지 마세요."
  };

  await appendGeneratedMemory(record);

  return {
    reply,
    source: record.source,
    model,
    generated: true,
    memoryId: record.id,
    reviewStatus: record.reviewStatus
  };
}

async function createChatReply(messages, persona) {
  const allStoredGeneratedMemories = await loadAllActiveGeneratedMemories(GENERATED_MEMORY_REVIEW_LIMIT);
  const allGeneratedMemories = allStoredGeneratedMemories
    .filter(isGeneratedMemoryContextEligible);
  const generatedMemories = GENERATED_MEMORY_CONTEXT_LIMIT > 0
    ? allGeneratedMemories.slice(-GENERATED_MEMORY_CONTEXT_LIMIT)
    : [];
  const lastUser = getLastUserMessage(messages);
  const query = lastUser?.content || "";

  const safetyCategory = getSafetyCategory(query);
  if (safetyCategory) {
    return makeSafetyResult(safetyCategory);
  }

  if (isAbusiveOrJokeQuery(query)) {
    return {
      reply: makeAbuseReply(),
      source: "policy",
      model: "local-policy"
    };
  }

  if (isAuthenticityQuery(query)) {
    return {
      reply: makeAuthenticityReply(),
      source: "policy",
      model: "local-policy"
    };
  }

  if (isChildhoodPlayQuery(query)) {
    return {
      reply: makeChildhoodPlayReply(),
      source: "policy",
      model: "local-policy"
    };
  }

  if (isUnverifiedPreferenceQuery(query)) {
    return {
      reply: makeUnverifiedPreferenceReply(),
      source: "policy",
      model: "local-policy"
    };
  }

  if (isHardshipFrameQuery(query)) {
    return {
      reply: makeHardshipFrameReply(),
      source: "policy",
      model: "local-policy"
    };
  }

  if (isParticipationQuery(query)) {
    return {
      reply: makeParticipationReply(),
      source: "policy",
      model: "local-policy"
    };
  }

  if (isExhibitReflectionQuery(query)) {
    return {
      reply: makeExhibitReflectionReply(),
      source: "policy",
      model: "local-policy"
    };
  }

  if (!OPENAI_API_KEY) {
    if (!isIntroQuery(query) && !findLocalFact(persona, query)) {
      return createGeneratedExtension(messages, persona, generatedMemories, allStoredGeneratedMemories);
    }

    return {
      reply: makeLocalReply(persona, messages),
      source: "local",
      model: "local-evidence"
    };
  }

  if (!isIntroQuery(query) && !findLocalFact(persona, query)) {
    return createGeneratedExtension(messages, persona, generatedMemories, allStoredGeneratedMemories);
  }

  const matchedFact = findLocalFact(persona, query);
  const json = await requestOpenAIResponse({
    model: CHAT_MODEL,
    input: toResponseInput(messages, persona, generatedMemories),
    max_output_tokens: 760,
    store: false
  }, "채팅 답변 생성");
  const reply = extractOutputText(json);
  const baseReply = formatVisitorReply(reply || makeLocalReply(persona, messages));
  let finalReply = baseReply;
  let source = "openai";

  if (matchedFact && (baseReply.length < 560 || hasRedundantReplySentences(baseReply))) {
    try {
      const revisedReply = await reviseFactReply(query, baseReply, matchedFact);
      if (revisedReply && revisedReply.length >= 300) {
        finalReply = revisedReply;
        source = "openai-revised";
      }
    } catch (error) {
      console.warn(`답변 품질 재작성 실패: ${error.message || error}`);
    }
  }

  if (matchedFact && finalReply.length < 430) {
    try {
      const expandedReply = await reviseFactReply(
        query,
        `${finalReply}\n\n위 답변은 아직 짧다. 같은 말을 반복하지 말고 근거 카드 안에서 구체 장면, 생활 의미, 전시 연결을 보태 430자 이상으로 다시 쓴다.`,
        matchedFact
      );
      if (expandedReply && expandedReply.length > finalReply.length) {
        finalReply = expandedReply;
        source = source === "openai-revised" ? "openai-revised-expanded" : "openai-expanded";
      }
    } catch (error) {
      console.warn(`짧은 답변 확장 실패: ${error.message || error}`);
    }
  }

  if (matchedFact && finalReply.length < 430) {
    finalReply = enrichShortFactReply(finalReply, matchedFact);
    source = source.includes("revised") || source.includes("expanded")
      ? `${source}-local-boost`
      : "openai-local-boost";
  }

  if (hasRedundantReplySentences(finalReply)) {
    const dedupedReply = dedupeReplySentences(finalReply);
    if (dedupedReply.length >= 430 || finalReply.length < 430) {
      finalReply = dedupedReply;
      source = `${source}-deduped`;
    }
  }

  return {
    reply: matchedFact
      ? finalReply
      : formatVisitorReply(baseReply),
    source,
    model: CHAT_MODEL
  };
}

async function handleChat(req, res) {
  const persona = await loadPersona();
  const body = await readBody(req);
  const payload = JSON.parse(body.toString("utf8") || "{}");
  const messages = sanitizeMessages(payload.messages);

  if (!messages.length) {
    sendJson(res, 400, { error: "messages 배열이 필요합니다." });
    return;
  }

  const result = await createChatReply(messages, persona);
  const suggestionResult = await createChatSuggestions(messages, result.reply, persona);
  sendJson(res, 200, { ...result, ...suggestionResult });
}

async function handleTranscribe(req, res) {
  if (!OPENAI_API_KEY) {
    sendJson(res, 503, { error: "OPENAI_API_KEY가 없어 서버 전사를 사용할 수 없습니다." });
    return;
  }

  const contentType = req.headers["content-type"] || "audio/webm";
  const audio = await readBody(req, 15_000_000);

  if (!audio.length) {
    sendJson(res, 400, { error: "오디오 데이터가 비어 있습니다." });
    return;
  }

  const form = new FormData();
  const extension = extensionForAudioType(contentType);
  form.append("model", TRANSCRIBE_MODEL);
  form.append("language", "ko");
  form.append("file", new Blob([audio], { type: contentType }), `recording.${extension}`);

  const response = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENAI_API_KEY}`
    },
    body: form
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI transcription failed: ${response.status} ${errorText.slice(0, 500)}`);
  }

  const json = await response.json();
  sendJson(res, 200, { text: String(json.text || "").trim(), model: TRANSCRIBE_MODEL });
}

async function handleSpeech(req, res) {
  if (!OPENAI_API_KEY) {
    sendJson(res, 503, { error: "OPENAI_API_KEY가 없어 서버 음성 합성을 사용할 수 없습니다." });
    return;
  }

  const body = await readBody(req);
  const payload = JSON.parse(body.toString("utf8") || "{}");
  const input = String(payload.text || "").replace(/\s+/g, " ").trim().slice(0, 1800);

  if (!input) {
    sendJson(res, 400, { error: "text가 필요합니다." });
    return;
  }

  const response = await fetch("https://api.openai.com/v1/audio/speech", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: TTS_MODEL,
      voice: TTS_VOICE,
      input,
      instructions: "차분하고 담백한 한국어 전시 도슨트처럼 말합니다. 과장된 감정 표현은 줄이고, 문장 사이를 자연스럽게 둡니다."
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI speech failed: ${response.status} ${errorText.slice(0, 500)}`);
  }

  const audio = Buffer.from(await response.arrayBuffer());
  res.writeHead(200, {
    "Content-Type": "audio/mpeg",
    "Content-Length": audio.length,
    "Cache-Control": "no-store"
  });
  res.end(audio);
}

async function handleConfig(req, res) {
  const chatModelHealth = OPENAI_API_KEY
    ? await checkChatModelHealth()
    : { ok: false, error: "OPENAI_API_KEY가 없어 근거 카드 모드로 동작합니다.", checkedAt: new Date().toISOString() };

  sendJson(res, 200, {
    apiAvailable: Boolean(OPENAI_API_KEY),
    chatModelReady: Boolean(OPENAI_API_KEY && chatModelHealth.ok),
    chatModelError: chatModelHealth.error,
    chatModelCheckedAt: chatModelHealth.checkedAt,
    chatModel: CHAT_MODEL,
    chatModelSource: CHAT_MODEL_CONFIG.source,
    chatModelRequestedSource: CHAT_MODEL_CONFIG.requestedSource,
    chatModelNote: CHAT_MODEL_CONFIG.note,
    transcribeModel: TRANSCRIBE_MODEL,
    ttsModel: TTS_MODEL,
    ttsVoice: TTS_VOICE
  });
}

async function handleGeneratedMemory(req, res) {
  const memories = (await readGeneratedMemoryRecords(false)).slice(-GENERATED_MEMORY_REVIEW_LIMIT);
  sendJson(res, 200, {
    path: "data/generated_memory.jsonl",
    count: memories.length,
    memories
  });
}

function normalizeReviewStatus(value) {
  const status = String(value || "").trim();
  if (["unreviewed", "approved", "needs_review"].includes(status)) return status;
  return "";
}

async function handleGeneratedMemoryUpdate(req, res, id) {
  const body = await readBody(req);
  const payload = JSON.parse(body.toString("utf8") || "{}");
  const records = await readGeneratedMemoryRecords(true);
  const target = records.find((record) => record.id === id);

  if (!target) {
    sendJson(res, 404, { error: "기록을 찾지 못했습니다." });
    return;
  }

  if (Object.hasOwn(payload, "answer")) {
    const answer = String(payload.answer || "").trim();
    if (!answer) {
      sendJson(res, 400, { error: "answer가 비어 있습니다." });
      return;
    }
    target.answer = answer.slice(0, 6000);
  }

  if (Object.hasOwn(payload, "reviewStatus")) {
    const reviewStatus = normalizeReviewStatus(payload.reviewStatus);
    if (!reviewStatus) {
      sendJson(res, 400, { error: "reviewStatus 값이 올바르지 않습니다." });
      return;
    }
    target.reviewStatus = reviewStatus;
  }

  target.updatedAt = new Date().toISOString();
  await saveGeneratedMemoryRecords(records);
  sendJson(res, 200, { memory: target });
}

async function handleGeneratedMemoryDelete(req, res, id) {
  const records = await readGeneratedMemoryRecords(true);
  const nextRecords = records.filter((record) => record.id !== id);

  if (nextRecords.length === records.length) {
    sendJson(res, 404, { error: "기록을 찾지 못했습니다." });
    return;
  }

  await saveGeneratedMemoryRecords(nextRecords);
  sendJson(res, 200, { deleted: true, count: nextRecords.filter((record) => record.status !== "rejected").length });
}

async function serveStatic(req, res, url) {
  const pathname = decodeURIComponent(url.pathname === "/" ? "/index.html" : url.pathname);
  const safePath = path.normalize(path.join(STATIC_ROOT, pathname));

  if (safePath !== STATIC_ROOT && !safePath.startsWith(`${STATIC_ROOT}${path.sep}`)) {
    sendText(res, 403, "Forbidden");
    return;
  }

  try {
    const data = await fs.readFile(safePath);
    const type = MIME_TYPES.get(path.extname(safePath).toLowerCase()) || "application/octet-stream";
    res.writeHead(200, {
      "Content-Type": type,
      "Content-Length": data.length,
      "Cache-Control": "no-store"
    });
    if (req.method === "HEAD") {
      res.end();
      return;
    }
    res.end(data);
  } catch (error) {
    if (error.code === "ENOENT" || error.code === "EISDIR") {
      sendText(res, 404, "Not found");
      return;
    }
    throw error;
  }
}

async function route(req, res) {
  const url = new URL(req.url, `http://${req.headers.host || `${HOST}:${PORT}`}`);

  if (req.method === "GET" && url.pathname === "/api/config") return handleConfig(req, res);
  if (req.method === "GET" && url.pathname === "/api/generated-memory") return handleGeneratedMemory(req, res);
  const generatedMemoryMatch = url.pathname.match(/^\/api\/generated-memory\/([^/]+)$/);
  if (generatedMemoryMatch && req.method === "PATCH") {
    return handleGeneratedMemoryUpdate(req, res, decodeURIComponent(generatedMemoryMatch[1]));
  }
  if (generatedMemoryMatch && req.method === "DELETE") {
    return handleGeneratedMemoryDelete(req, res, decodeURIComponent(generatedMemoryMatch[1]));
  }
  if (req.method === "POST" && url.pathname === "/api/chat") return handleChat(req, res);
  if (req.method === "POST" && url.pathname === "/api/transcribe") return handleTranscribe(req, res);
  if (req.method === "POST" && url.pathname === "/api/speech") return handleSpeech(req, res);
  if (req.method === "GET" || req.method === "HEAD") return serveStatic(req, res, url);

  sendJson(res, 405, { error: "Method not allowed" });
}

const server = http.createServer((req, res) => {
  route(req, res).catch((error) => {
    console.error(error);
    sendJson(res, 500, { error: error.message || "Internal server error" });
  });
});

server.listen(PORT, HOST, () => {
  console.log(`Interviewee1 Clone AI is running at http://${HOST}:${PORT}`);
  console.log(`Static files: ${STATIC_ROOT}`);
  console.log(`OpenAI API: ${OPENAI_API_KEY ? `enabled (${CHAT_MODEL})` : "disabled; local evidence mode only"}`);
});
