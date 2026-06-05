(function () {
  const elements = {
    apiPill: document.getElementById("apiPill"),
    avatarStage: document.getElementById("avatarStage"),
    avatarStateLabel: document.getElementById("avatarStateLabel"),
    chatLog: document.getElementById("chatLog"),
    composer: document.getElementById("composer"),
    messageInput: document.getElementById("messageInput"),
    micButton: document.getElementById("micButton"),
    speakToggle: document.getElementById("speakToggle"),
    resetButton: document.getElementById("resetButton"),
    fullscreenButton: document.getElementById("fullscreenButton"),
    promptStrip: document.getElementById("promptStrip"),
    sourceCard: document.getElementById("sourceCard"),
    sourceList: document.getElementById("sourceList"),
    memoryCard: document.getElementById("memoryCard"),
    memoryList: document.getElementById("memoryList"),
    memoryCount: document.getElementById("memoryCount"),
    memoryRefreshButton: document.getElementById("memoryRefreshButton")
  };

  const state = {
    persona: null,
    config: null,
    isStaffMode: new URLSearchParams(window.location.search).get("staff") === "1",
    messages: [],
    memories: [],
    mediaRecorder: null,
    audioChunks: [],
    speakEnabled: true,
    audio: null
  };

  const reviewStatusLabels = {
    unreviewed: "미확인",
    approved: "사용",
    needs_review: "수정 필요"
  };

  function setAvatarState(value, label) {
    elements.avatarStage.dataset.state = value;
    elements.avatarStateLabel.textContent = label;
  }

  function addMessage(role, title, text) {
    const node = document.createElement("article");
    node.className = `message ${role}`;

    if (title) {
      const heading = document.createElement("strong");
      heading.textContent = title;
      node.appendChild(heading);
    }

    const body = document.createElement("div");
    body.textContent = text;
    node.appendChild(body);

    elements.chatLog.appendChild(node);
    elements.chatLog.scrollTop = elements.chatLog.scrollHeight;
  }

  function setBusy(isBusy) {
    elements.messageInput.disabled = isBusy;
    elements.composer.querySelector(".send-button").disabled = isBusy;
    elements.micButton.disabled = isBusy && !state.mediaRecorder;
  }

  async function fetchJson(url, options) {
    const response = await fetch(url, options);
    const text = await response.text();
    let payload = {};

    try {
      payload = text ? JSON.parse(text) : {};
    } catch (error) {
      payload = { error: text };
    }

    if (!response.ok) {
      throw new Error(payload.error || `요청 실패: ${response.status}`);
    }

    return payload;
  }

  function renderSources() {
    elements.sourceList.innerHTML = "";
    for (const source of state.persona.sourceSummary) {
      const item = document.createElement("article");
      item.className = "source-item";

      const title = document.createElement("strong");
      title.textContent = source.label;
      item.appendChild(title);

      const note = document.createElement("p");
      note.textContent = source.notes;
      item.appendChild(note);

      elements.sourceList.appendChild(item);
    }
  }

  function renderPrompts() {
    elements.promptStrip.innerHTML = "";
    for (const prompt of state.persona.suggestedQuestions) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "prompt-button";
      button.textContent = prompt;
      button.addEventListener("click", () => sendUserMessage(prompt));
      elements.promptStrip.appendChild(button);
    }
  }

  function renderGeneratedMemories() {
    elements.memoryList.innerHTML = "";
    elements.memoryCount.textContent = `${state.memories.length}개`;

    if (!state.memories.length) {
      const empty = document.createElement("p");
      empty.className = "memory-empty";
      empty.textContent = "아직 생성된 확장 답변이 없습니다.";
      elements.memoryList.appendChild(empty);
      return;
    }

    for (const memory of [...state.memories].reverse()) {
      const item = document.createElement("article");
      item.className = "memory-item";
      item.dataset.status = memory.reviewStatus || "unreviewed";

      const header = document.createElement("div");
      header.className = "memory-item-header";

      const question = document.createElement("strong");
      question.textContent = memory.question || "질문 없음";
      header.appendChild(question);

      const badge = document.createElement("span");
      badge.className = "memory-status";
      badge.textContent = reviewStatusLabels[memory.reviewStatus] || "미확인";
      header.appendChild(badge);
      item.appendChild(header);

      const answer = document.createElement("textarea");
      answer.value = memory.answer || "";
      answer.rows = 5;
      answer.setAttribute("aria-label", `${memory.question || "질문"} 답변`);
      item.appendChild(answer);

      const footer = document.createElement("div");
      footer.className = "memory-item-actions";

      for (const [status, label] of Object.entries(reviewStatusLabels)) {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "memory-status-button";
        button.textContent = label;
        button.classList.toggle("active", memory.reviewStatus === status);
        button.addEventListener("click", () => updateGeneratedMemory(memory.id, { reviewStatus: status }));
        footer.appendChild(button);
      }

      const saveButton = document.createElement("button");
      saveButton.type = "button";
      saveButton.className = "memory-save-button";
      saveButton.textContent = "저장";
      saveButton.addEventListener("click", () => updateGeneratedMemory(memory.id, { answer: answer.value }));
      footer.appendChild(saveButton);

      const deleteButton = document.createElement("button");
      deleteButton.type = "button";
      deleteButton.className = "memory-delete-button";
      deleteButton.textContent = "삭제";
      deleteButton.addEventListener("click", () => deleteGeneratedMemory(memory));
      footer.appendChild(deleteButton);

      item.appendChild(footer);
      elements.memoryList.appendChild(item);
    }
  }

  async function loadGeneratedMemories() {
    if (!state.isStaffMode) return;
    const result = await fetchJson("/api/generated-memory");
    state.memories = Array.isArray(result.memories) ? result.memories : [];
    renderGeneratedMemories();
  }

  async function updateGeneratedMemory(id, patch) {
    if (!id) return;
    const result = await fetchJson(`/api/generated-memory/${encodeURIComponent(id)}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(patch)
    });

    const index = state.memories.findIndex((memory) => memory.id === id);
    if (index >= 0) state.memories[index] = result.memory;
    renderGeneratedMemories();
  }

  async function deleteGeneratedMemory(memory) {
    if (!memory?.id) return;
    const ok = window.confirm(`"${memory.question}" 답변을 삭제할까요?`);
    if (!ok) return;

    await fetchJson(`/api/generated-memory/${encodeURIComponent(memory.id)}`, {
      method: "DELETE"
    });
    state.memories = state.memories.filter((item) => item.id !== memory.id);
    renderGeneratedMemories();
  }

  function updateApiPill() {
    if (state.config.apiAvailable && state.config.chatModelReady === false) {
      elements.apiPill.textContent = `API 오류 · ${state.config.chatModel}`;
      elements.apiPill.className = "api-pill error";
    } else if (state.config.apiAvailable) {
      elements.apiPill.textContent = `API 연결됨 · ${state.config.chatModel}`;
      elements.apiPill.className = "api-pill ready";
    } else {
      elements.apiPill.textContent = "근거 카드 모드";
      elements.apiPill.className = "api-pill local";
    }
  }

  function resetConversation(options) {
    const shouldFocus = options?.focus !== false;

    if (state.audio) {
      state.audio.pause();
      state.audio = null;
    }
    window.speechSynthesis?.cancel?.();

    state.messages = [
      {
        role: "assistant",
        content: state.persona.opening
      }
    ];

    elements.chatLog.innerHTML = "";
    addMessage("assistant", state.persona.displayName, state.persona.opening);
    setAvatarState("idle", "대기 중");
    elements.messageInput.value = "";
    if (shouldFocus) elements.messageInput.focus();
  }

  async function speak(text) {
    if (!state.speakEnabled || !text) return;

    setAvatarState("speaking", "말하는 중");

    try {
      if (state.config.apiAvailable) {
        const response = await fetch("/api/speech", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ text })
        });

        if (!response.ok) throw new Error("서버 음성 합성 실패");

        const blob = await response.blob();
        const url = URL.createObjectURL(blob);
        state.audio = new Audio(url);
        state.audio.addEventListener("ended", () => {
          URL.revokeObjectURL(url);
          setAvatarState("idle", "대기 중");
        });
        state.audio.addEventListener("error", () => setAvatarState("idle", "대기 중"));
        await state.audio.play();
        return;
      }

      if ("speechSynthesis" in window) {
        const utterance = new SpeechSynthesisUtterance(text);
        utterance.lang = "ko-KR";
        utterance.rate = 0.96;
        utterance.onend = () => setAvatarState("idle", "대기 중");
        utterance.onerror = () => setAvatarState("idle", "대기 중");
        window.speechSynthesis.speak(utterance);
        return;
      }
    } catch (error) {
      addMessage("system", "음성", "음성 출력은 실패했지만 텍스트 응답은 사용할 수 있습니다.");
    }

    setAvatarState("idle", "대기 중");
  }

  async function requestReply() {
    setBusy(true);
    setAvatarState("thinking", "생각 중");

    try {
      const result = await fetchJson("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ messages: state.messages })
      });

      const reply = result.reply || state.persona.unknownAnswer;
      state.messages.push({ role: "assistant", content: reply });
      addMessage("assistant", state.persona.displayName, reply);
      if (result.generated) await loadGeneratedMemories();
      await speak(reply);
    } catch (error) {
      setAvatarState("idle", "대기 중");
      addMessage("system", "오류", error.message || "응답을 가져오지 못했습니다.");
    } finally {
      setBusy(false);
      if (elements.avatarStage.dataset.state !== "speaking") setAvatarState("idle", "대기 중");
      elements.messageInput.focus();
    }
  }

  async function sendUserMessage(text) {
    const value = String(text || "").trim();
    if (!value) return;

    state.messages.push({ role: "user", content: value });
    addMessage("user", "질문", value);
    elements.messageInput.value = "";
    await requestReply();
  }

  async function stopRecording() {
    const recorder = state.mediaRecorder;
    if (!recorder) return;
    recorder.stop();
  }

  async function transcribeBlob(blob) {
    if (!state.config.apiAvailable) {
      throw new Error("마이크 전사는 OPENAI_API_KEY가 설정된 서버 실행이 필요합니다.");
    }

    const response = await fetch("/api/transcribe", {
      method: "POST",
      headers: { "Content-Type": blob.type || "audio/webm" },
      body: blob
    });

    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(payload.error || "전사 실패");
    return String(payload.text || "").trim();
  }

  async function startRecording() {
    if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === "undefined") {
      addMessage("system", "마이크", "이 브라우저에서는 마이크 녹음을 사용할 수 없습니다.");
      return;
    }

    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    const recorder = new MediaRecorder(stream, { mimeType: "audio/webm" });
    state.audioChunks = [];
    state.mediaRecorder = recorder;

    recorder.addEventListener("dataavailable", (event) => {
      if (event.data.size > 0) state.audioChunks.push(event.data);
    });

    recorder.addEventListener("stop", async () => {
      stream.getTracks().forEach((track) => track.stop());
      elements.micButton.classList.remove("recording");
      elements.micButton.innerHTML = '<span class="mic-dot"></span>마이크';
      state.mediaRecorder = null;
      setAvatarState("thinking", "전사 중");

      try {
        const blob = new Blob(state.audioChunks, { type: "audio/webm" });
        const text = await transcribeBlob(blob);
        if (text) {
          await sendUserMessage(text);
        } else {
          addMessage("system", "마이크", "녹음에서 문장을 찾지 못했습니다.");
        }
      } catch (error) {
        addMessage("system", "마이크", error.message || "마이크 입력을 처리하지 못했습니다.");
      } finally {
        if (elements.avatarStage.dataset.state !== "speaking") setAvatarState("idle", "대기 중");
      }
    });

    recorder.start();
    elements.micButton.classList.add("recording");
    elements.micButton.innerHTML = '<span class="mic-dot"></span>멈춤';
    setAvatarState("listening", "듣는 중");

    window.setTimeout(() => {
      if (state.mediaRecorder?.state === "recording") stopRecording();
    }, 22000);
  }

  function bindEvents() {
    elements.composer.addEventListener("submit", (event) => {
      event.preventDefault();
      sendUserMessage(elements.messageInput.value);
    });

    elements.micButton.addEventListener("click", () => {
      if (state.mediaRecorder?.state === "recording") {
        stopRecording();
      } else {
        startRecording().catch((error) => {
          setAvatarState("idle", "대기 중");
          addMessage("system", "마이크", error.message || "마이크 권한을 얻지 못했습니다.");
        });
      }
    });

    elements.speakToggle.addEventListener("click", () => {
      state.speakEnabled = !state.speakEnabled;
      elements.speakToggle.classList.toggle("active", state.speakEnabled);
      elements.speakToggle.setAttribute("aria-pressed", String(state.speakEnabled));
      if (!state.speakEnabled) {
        state.audio?.pause();
        window.speechSynthesis?.cancel?.();
        setAvatarState("idle", "대기 중");
      }
    });

    elements.resetButton.addEventListener("click", () => resetConversation({ focus: true }));
    if (state.isStaffMode) {
      elements.memoryRefreshButton.addEventListener("click", () => {
        loadGeneratedMemories().catch((error) => {
          addMessage("system", "확장 답변", error.message || "목록을 불러오지 못했습니다.");
        });
      });
    }

    elements.fullscreenButton.addEventListener("click", () => {
      if (document.fullscreenElement) {
        document.exitFullscreen?.();
      } else {
        document.documentElement.requestFullscreen?.();
      }
    });
  }

  async function init() {
    const [persona, config] = await Promise.all([
      fetchJson("/data/persona.json"),
      fetchJson("/api/config")
    ]);

    state.persona = persona;
    state.config = config;
    document.body.dataset.staffMode = state.isStaffMode ? "true" : "false";
    elements.sourceCard.hidden = !state.isStaffMode;
    elements.memoryCard.hidden = !state.isStaffMode;
    updateApiPill();
    renderSources();
    renderPrompts();
    if (state.isStaffMode) await loadGeneratedMemories();
    bindEvents();
    resetConversation({ focus: false });

    if (state.config.apiAvailable && state.config.chatModelReady === false) {
      addMessage("system", "API 오류", state.config.chatModelError || `${state.config.chatModel} 호출에 실패했습니다.`);
    }
  }

  init().catch((error) => {
    addMessage("system", "초기화", error.message || "앱을 시작하지 못했습니다.");
  });
})();
