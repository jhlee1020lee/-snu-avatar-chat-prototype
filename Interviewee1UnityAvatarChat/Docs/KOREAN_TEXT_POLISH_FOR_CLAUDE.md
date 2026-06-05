# Claude Code 요청: 게임 한국어 문구 자연스럽게 다듬기

## Claude에게 해줄 말

아래는 Unity 게임 `겉!=속`에 들어가는 한국어 텍스트를 원본 파일/줄 번호 기준으로 모은 목록입니다. 자연스러운 한국어로 다듬어 주세요. 단순 맞춤법 교정보다 플레이어가 처음 봐도 이해되는 문장, 버튼/상태 문구의 명확성, 답변 문장의 중복 제거, 전시 의도에 맞는 담백한 말투를 우선해 주세요.

반드시 지켜 주세요.

- 게임명 `겉!=속` 표기는 유지합니다. `겉=속`으로 바꾸지 마세요.
- 원본 파일을 직접 수정하되, UI 레이아웃/게임 로직/서버 로직/정규식 의미/JSON 구조는 바꾸지 말고 한국어 문구만 다듬어 주세요.
- 키워드 매칭용 문자열, 상태 코드, evidence id, 파일명, 함수명처럼 로직에 쓰이는 값은 함부로 바꾸지 마세요. 다듬어야 한다면 별도 섹션에 이유를 남겨 주세요.
- 인터뷰 대상자를 동정/극복담으로 몰지 말고, 목발·자취방·책상·도움·이동·취미가 함께 보이는 담백한 톤을 유지해 주세요.
- 개인정보, 병명, 회사명, 학교명, 가족사, 구체 장소, 확인되지 않은 취향은 새로 만들지 마세요.
- 같은 뜻을 표현만 바꿔 반복하는 문장을 줄여 주세요. 특히 답변 문구는 한 문단 안에서 같은 핵심을 두 번 말하지 않게 해 주세요.
- 버튼/상태/오류 문구는 짧고 명확하게, 긴 설명/인터뷰 답변은 자연스럽고 구어체에 가깝게 다듬어 주세요.
- 수정 후 `node --check server.js`와 Unity C# 컴파일에 문제가 없도록 따옴표, 이스케이프, 줄바꿈을 조심해 주세요.
- 작업 결과는 변경 파일 목록, 주요 톤 변경 요약, 사람이 다시 봐야 할 애매한 문구 목록으로 정리해 주세요.

## 수집 기준

- 생성 시각: 2026. 6. 4. AM 12:04:35
- 포함: Unity 런타임 UI/대화 텍스트, 제품명, 패키지 서버 persona/답변/안전 문구, 서버에 포함된 웹 디버그 UI 텍스트, 패키지 메타데이터
- 제외: Docs/Marketing/Build 산출물, 이전 검수 로그, 릴리즈 문서, 스모크 결과 파일
- 형식: `줄번호 | 원문 라인`

## Unity runtime UI/copy

### Assets/Scripts/AvatarChatApp.cs

- 한국어 포함 라인 수: 983

```text
   15 |     private const string GameTitle = "겉!=속";
   16 |     private const string GameSubtitle = "처음 보인 장면을 따라가며, 한 사람의 하루를 묻습니다.";
   18 |     private const string ServerStatusIdleText = "서버 답변 연결을 확인 중입니다.";
   19 |     private const string ServerRequiredCheckingText = "서버 연결 확인 중입니다. 서버가 정상일 때만 시작할 수 있습니다.";
   20 |     private const string ServerRequiredBlockedText = "서버 연결 필요 · 시작 파일로 서버를 먼저 켠 뒤 다시 실행해 주세요.";
   32 |     private const string ThinkingReplyText = "생각을 정리하고 있어요.";
   46 |     private const string OpeningText = "와줘서 고마워요. 책상 위 단서를 살펴보거나 질문 노트를 열어 보세요.";
  101 |         "목발을 먼저 봤을 때 놓치기 쉬운 하루의 장면은 무엇인가요?",
  102 |         "도움이 필요해 보여도 어떤 말로 먼저 물어보는 게 편한가요?",
  103 |         "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
  104 |         "혼자 사는 방에서는 어떤 생활의 선택을 직접 정하게 되나요?",
  105 |         "직장 일과 박사과정 공부는 하루 안에서 어떻게 이어지나요?",
  106 |         "목발 너머의 생활을 보려면 어떤 장면까지 더 물어봐야 하나요?",
  107 |         "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?",
  108 |         "함께 일하는 사람이 상황을 모를 때 무엇부터 말해 주는 편인가요?",
  109 |         "어떤 업무 장면에서 기여를 느끼나요?",
  110 |         "노트북과 메모는 이동 이야기 너머의 어떤 생활을 보여주나요?",
  111 |         "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
  112 |         "엘리베이터나 화장실 정보가 하루의 피로와 어떻게 연결되나요?",
  113 |         "자취를 시작한 뒤 스스로 설명해야 하는 일이 어떻게 달라졌나요?",
  114 |         "도움을 받을 때 설명할 시간이 필요하다는 말은 어떤 뜻인가요?",
  115 |         "혼자 할 수 있는 부분을 존중하는 도움은 어떤 모습인가요?",
  116 |         "전시에서 자취방과 책상이 함께 보여야 하는 이유는 무엇인가요?",
  117 |         "끈기라는 말은 대단한 극복담보다 어떤 태도에 가까운가요?",
  118 |         "게임과 코인노래방 같은 취미가 전시에서 빠지면 무엇을 놓치게 되나요?"
  123 |         "일상",
  124 |         "이동",
  125 |         "도움",
  126 |         "일과 공부",
  127 |         "독립",
  128 |         "취미"
  133 |         "목발보다 먼저 있는 하루",
  134 |         "처음 가는 곳에서 먼저 살피는 길",
  135 |         "좋은 의도보다 필요한 말",
  136 |         "책상 앞에서 이어지는 일과 공부",
  137 |         "생활을 직접 정하며 생긴 감각",
  138 |         "쉬는 시간까지 보여 주는 입체감"
  143 |         "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?",
  144 |         "처음 가는 곳에서는 이동 전에 어떤 조건을 먼저 확인하나요?",
  145 |         "도움을 건네기 전에 어떤 말로 먼저 물어보는 게 좋을까요?",
  146 |         "책상과 노트북은 일하고 공부하는 하루에서 어떤 자리인가요?",
  147 |         "혼자 사는 방은 독립이나 자기이해와 어떻게 연결되나요?",
  148 |         "게임이나 코인노래방 같은 취미는 하루의 분위기를 어떻게 바꾸나요?"
  153 |         "단정",
  154 |         "배려",
  155 |         "호기심",
  156 |         "거리두기"
  161 |         "목발",
  162 |         "책상",
  163 |         "표정"
  168 |         "일상",
  169 |         "이동",
  170 |         "도움",
  171 |         "일과 공부",
  172 |         "독립",
  173 |         "취미"
  178 |         "처음엔 목발이 먼저 보일 수 있어요. 하지만 하루는 거기서 끝나지 않아요. 몸 상태를 보고, 갈 곳을 확인하고, 오늘 해야 할 일을 하나씩 정리하며 시작합니다.",
  179 |         "처음 가는 곳에서는 목적지만 보지 않아요. 입구와 엘리베이터, 화장실, 돌아올 길까지 먼저 떠올립니다. 걱정이 많아서가 아니라, 하루를 덜 무리하게 보내기 위해서예요.",
  180 |         "도움은 고맙지만, 방식이 먼저예요. 바로 잡아 주기보다 \"어떻게 도와드릴까요?\" 하고 물어봐 주면 좋아요. 제 몸과 상황은 제가 설명할 시간이 필요하니까요.",
  181 |         "책상 앞에서는 다른 장면이 보입니다. 직장 일, 컴퓨터공학 박사과정, 읽고 정리하는 시간이 이어져요. 기다리는 사람만이 아니라, 제 몫을 해내는 사람이기도 합니다.",
  182 |         "자취방은 독립을 연습한 곳입니다. 공과금, 생활비, 집안일을 챙기며 내 생활을 내가 정한다는 감각을 배웠어요. 불편함만 있는 곳은 아니었습니다.",
  183 |         "쉬는 시간도 제 하루입니다. 게임을 하고, 코인노래방에 가고, 좋아하는 걸 챙깁니다. 이동 이야기만 남으면 사람은 납작해져요."
  188 |         "일상",
  189 |         "이동",
  190 |         "도움",
  191 |         "일과 공부",
  192 |         "독립",
  193 |         "취미"
  198 |         "질문하기 전에 제 이야기를 먼저 충분히 들려드릴게요. 저는 30대 초반의 남성이고, 지체장애가 있어 목발과 휠체어를 이동 도구로 사용합니다. 하지만 제 이야기는 이동 도구 하나로 끝나지 않습니다. 회사에 다니고, 컴퓨터공학 박사과정을 이어가고, 자취방에서 생활을 직접 챙기며 살아갑니다.",
  199 |         "처음 보는 사람에게는 목발이 가장 먼저 보일 수 있어요. 저도 그 시선을 이해합니다. 다만 목발은 불편함만 보여주는 물건이 아니라 밖으로 나가 사람을 만나고 일하러 가는 하루를 이어주는 도구입니다. 하루를 시작할 때는 몸 상태와 길의 상태를 함께 생각하게 되고, 처음 가는 곳이라면 입구, 엘리베이터, 화장실, 돌아올 길까지 먼저 확인하게 됩니다.",
  200 |         "도움에 대해서도 먼저 알고 들어주면 좋겠습니다. 도움은 마음보다 방법이 중요할 때가 있어요. 바로 잡아 주거나 끌어 주기보다, 어떻게 도우면 편한지 먼저 물어봐 주는 것이 좋습니다. 저에게도 어디를 잡으면 편한지, 어느 방향이 나은지, 혼자 할 수 있는 부분은 무엇인지 설명할 시간이 필요합니다.",
  201 |         "책상 앞에서는 또 다른 장면이 보입니다. 저는 직장 일과 컴퓨터공학 박사과정을 같이 이어가고 있습니다. 노트북, 메모, 자료가 놓인 책상은 누군가의 배려를 기다리는 사람이 아니라 일을 정리하고 공부를 계속하는 사람을 보여줍니다. 목발이 이동의 조건을 보여준다면, 책상은 그 조건을 안고도 이어지는 일상의 밀도를 보여줍니다.",
  202 |         "자취방도 중요한 장면입니다. 집안일, 생활비, 공과금, 시간 관리처럼 평범해 보이는 일을 직접 챙기면서 내 생활을 내가 굴린다는 감각이 생겼습니다. 자취방은 장애를 설명하는 공간이 아니라, 독립과 생활의 감각을 보여주는 공간입니다. 대신 해 주던 일을 직접 하다 보면 생활이 생각보다 많은 선택으로 이루어져 있다는 것도 알게 됩니다.",
  203 |         "마지막으로, 제 하루에는 쉬는 시간도 있습니다. 게임을 하고 코인노래방에 가고 좋아하는 것을 챙기는 시간도 제 생활의 일부입니다. 이동 이야기만 남으면 사람은 납작해집니다. 이제 목발, 도움, 책상, 자취방, 취미 중에서 먼저 궁금한 장면을 골라 질문해 주세요. 정답을 맞히는 것이 아니라, 처음 보인 겉모습에서 한 사람의 속 생활로 들어가는 질문을 시작하는 겁니다."
  208 |         "목발",
  209 |         "처음 가는 길",
  210 |         "도움 받는 순간",
  211 |         "책상",
  212 |         "자취방",
  213 |         "취미"
  218 |         "하루를 준비하는 방식",
  219 |         "무리하지 않기 위한 확인",
  220 |         "먼저 묻고 조율하는 관계",
  221 |         "일과 공부를 이어가는 자기 몫",
  222 |         "생활을 직접 정하는 감각",
  223 |         "좋아하는 것으로 입체적인 사람"
  228 |         "짧은 정적 0.8초 · 낮은 방 톤 · 목발 쪽으로 천천히 시선 이동",
  229 |         "짧은 정적 0.7초 · 문밖 소리 낮춤 · 이동 경로 쪽으로 시선 이동",
  230 |         "짧은 정적 0.9초 · 손 닿는 소리 낮춤 · 도움 장면에 시선 고정",
  231 |         "짧은 정적 0.7초 · 키보드 소리 낮춤 · 책상 조명 강조",
  232 |         "짧은 정적 0.8초 · 방 톤 유지 · 자취방 단서에 시선 이동",
  233 |         "짧은 정적 1.0초 · 소리 여백 확보 · 취미 단서에서 마무리"
  419 |     private string lastTheme = "시작";
  420 |     private string lastEvidenceLine = "아직 표시할 자료가 없습니다.";
  421 |     private string lastAnswerSource = "대기";
  462 |         "도움은 묻는 말에서 시작된다.",
  463 |         "처음 가는 길은 미리 살피는 하루다.",
  464 |         "처음 보인 장면은 하루와 같은 선 위에 있다."
  469 |         "바로 돕기 전에 먼저 묻는 태도.",
  470 |         "입구와 엘리베이터, 화장실과 돌아올 길까지 포함한 하루.",
  471 |         "목발, 책상, 표정 뒤에 이어진 일과 방, 취미."
  476 |         "도움 방식",
  477 |         "이동 확인",
  478 |         "사람 보기"
  647 |         PresentAssistant(OpeningText, "오늘의 시작");
  648 |         UpdateLeadPrompts("먼저 이런 순서로 이야기를 열어볼게요.");
  650 |         statusText.text = "서버 연결 확인 중";
  663 |             uiFont = Font.CreateDynamicFontFromOSFont(new[] { "Paperlogy", "Paperlogy 4 Regular", "Noto Sans KR", "NotoSansKR", "Malgun Gothic", "맑은 고딕", "Arial" }, 20);
  703 |             statusText.text = $"녹음 중... {seconds:0.0}초";
 1706 |         Text wallLabelText = CreateText("Gallery Wall Exhibit Label Text", wallLabel.transform, "기록 전시\n인터뷰", 18, new Color(0.22f, 0.15f, 0.09f, 0.88f), TextAnchor.MiddleCenter, FontStyle.Bold);
 1717 |         Text badgeText = CreateText("Gallery Event Badge Text", eventBadge.transform, "작가와의 대화", 13, new Color(0.98f, 0.90f, 0.72f, 0.78f), TextAnchor.MiddleCenter, FontStyle.Bold);
 1854 |         Text namePlateText = CreateText("Desk Korean Interview Nameplate Text", namePlate.transform, "전시 인터뷰", 15, new Color(0.98f, 0.89f, 0.68f, 0.86f), TextAnchor.MiddleCenter, FontStyle.Bold);
 2106 |         CreateHotspot(parent, "책상", new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-870f, -174f), new Vector2(-420f, -44f), "책상 앞에서 이어지는 하루는 어떤 모습인가요?", new Vector2(92f, 118f), new Vector2(104f, 36f));
 2107 |         CreateHotspot(parent, "기록", new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-170f, 116f), new Vector2(210f, 388f), "요즘 자주 떠올리는 말이 있나요?", new Vector2(24f, -54f), new Vector2(104f, 36f));
 2108 |         CreateHotspot(parent, "이동", new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(470f, -40f), new Vector2(820f, 362f), "처음 가는 곳에서는 무엇을 먼저 확인하나요?", new Vector2(-94f, 270f), new Vector2(104f, 36f));
 2339 |         if (!string.Equals(speakerText.text, "답변", StringComparison.Ordinal)) return false;
 2467 |         hotspotPreviewTitleText = CreateText("Hotspot Preview Title", card.transform, "단서", 18, new Color(0.20f, 0.13f, 0.06f, 0.98f), TextAnchor.UpperLeft, FontStyle.Bold);
 2482 |         Text askLabel = CreateText("Label", askButton.transform, "질문하기", 15, new Color(1f, 0.96f, 0.86f, 0.98f), TextAnchor.MiddleCenter, FontStyle.Bold);
 2491 |         Text closeLabel = CreateText("Label", closeButton.transform, "닫기", 14, new Color(1f, 0.96f, 0.86f, 0.92f), TextAnchor.MiddleCenter, FontStyle.Bold);
 2508 |         ShowSceneFocus(label, resolvedFocusPosition, "단서 확인", 2.6f);
 2509 |         pendingHotspotLabel = string.IsNullOrWhiteSpace(label) ? "단서" : label.Trim();
 2513 |             hotspotPreviewTitleText.text = string.IsNullOrWhiteSpace(pendingHotspotLabel) ? "단서" : $"단서 · {pendingHotspotLabel}";
 2534 |         if (statusText != null) statusText.text = "질문 확인";
 2570 |             case "노트북":
 2574 |             case "컵":
 2578 |             case "목발":
 2582 |             case "메모":
 2586 |             case "문":
 2587 |             case "창문":
 2588 |             case "지도":
 2589 |             case "자취방":
 2610 |         ShowSceneFocus(label, position, "살펴보기", 1.05f);
 2617 |         activeSceneFocusLabel = string.IsNullOrWhiteSpace(label) ? "장면" : label.Trim();
 2618 |         string safeAction = string.IsNullOrWhiteSpace(action) ? "장면 반응" : action.Trim();
 2619 |         sceneFocusSlipVisible = !string.Equals(safeAction, "단서 확인", StringComparison.Ordinal);
 2722 |         float laptop = GetScenePropReactionAlpha("노트북");
 2736 |         float board = GetScenePropReactionAlpha("메모");
 2744 |         float cup = GetScenePropReactionAlpha("컵");
 2750 |         float notebook = GetScenePropReactionAlpha("질문");
 2757 |         float crutch = GetScenePropReactionAlpha("목발");
 2764 |         float door = Mathf.Max(GetScenePropReactionAlpha("문"), Mathf.Max(GetScenePropReactionAlpha("지도"), GetScenePropReactionAlpha("자취방")));
 2786 |         if (HasAny(value, "질문")) return "질문";
 2787 |         if (HasAny(value, "노트북", "책상", "일과", "공부", "직장", "박사")) return "노트북";
 2788 |         if (HasAny(value, "메모", "도움", "배려", "조율")) return "메모";
 2789 |         if (HasAny(value, "컵", "취미", "게임", "노래방", "쉬")) return "컵";
 2790 |         if (HasAny(value, "목발", "일상", "평범", "장애")) return "목발";
 2791 |         if (HasAny(value, "창문", "문", "처음", "동선", "이동")) return "문";
 2792 |         if (HasAny(value, "지도", "한국", "미국", "접근성", "교통")) return "지도";
 2793 |         if (HasAny(value, "자취", "자취방", "독립", "자기이해")) return "문";
 2842 |             case "목발": return new Vector2(232f, 304f);
 2843 |             case "문": return new Vector2(420f, 300f);
 2844 |             case "지도": return new Vector2(270f, 176f);
 2845 |             case "자취방": return new Vector2(286f, 190f);
 2846 |             case "컵": return new Vector2(190f, 180f);
 2847 |             case "질문": return new Vector2(390f, 126f);
 2856 |             case "노트북":
 2858 |             case "메모":
 2860 |             case "창문":
 2861 |             case "문":
 2863 |             case "컵":
 2865 |             case "지도":
 2867 |             case "자취방":
 2869 |             case "목발":
 2881 |             case "취미": return "노트북";
 2882 |             case "독립": return "창문";
 2883 |             case "일과 공부": return "노트북";
 2884 |             case "도움": return "메모";
 2885 |             case "이동": return "창문";
 2886 |             case "일상": return "메모";
 2887 |             default: return "장면";
 2903 |         statusText = CreateText("Status", parent, "대화 준비", 13, new Color32(226, 232, 240, 0), TextAnchor.MiddleRight, FontStyle.Bold);
 2988 |         speakerText = CreateText("Speaker", namePlate.transform, "답변", 10, new Color(0.20f, 0.13f, 0.07f, 0.88f), TextAnchor.MiddleCenter, FontStyle.Bold);
 2991 |         dialogueSizeDownButton = CreateButton("Dialogue Size Down", panel.transform, "가-", new Color32(30, 41, 59, 226), Color.white, 14);
 2996 |         dialogueSizeUpButton = CreateButton("Dialogue Size Up", panel.transform, "가+", new Color32(30, 41, 59, 226), Color.white, 14);
 3053 |         dialoguePageCueText = CreateText("Dialogue Page Cue Text", scrollCue.transform, "다음 대사 보기", 14, new Color32(255, 248, 225, 255), TextAnchor.MiddleCenter, FontStyle.Bold);
 3062 |         micButton = CreateButton("Mic Button", panel.transform, "녹음", new Color(0.70f, 0.44f, 0.23f, 0.22f), new Color(1f, 0.96f, 0.86f, 0.68f), 12);
 3068 |         sendButton = CreateButton("Send Button", panel.transform, "전송", new Color(0.70f, 0.44f, 0.23f, 0.62f), new Color(1f, 0.96f, 0.86f, 0.96f), 17);
 3072 |         storyNextButton = CreateButton("Story Mode Next Button", panel.transform, "다음 장면", new Color(0.70f, 0.44f, 0.23f, 0.70f), new Color(1f, 0.96f, 0.86f, 0.96f), 14);
 3077 |         storyQuestionButton = CreateButton("Story Mode Question Button", panel.transform, "직접 질문", new Color(0.16f, 0.11f, 0.07f, 0.56f), new Color(1f, 0.96f, 0.86f, 0.92f), 14);
 3082 |         storyFinishButton = CreateButton("Story Mode Finish Button", panel.transform, "5문답 후", new Color(0.12f, 0.09f, 0.06f, 0.30f), new Color(1f, 0.96f, 0.86f, 0.72f), 13);
 3087 |         finishButton = CreateButton("Finish Conversation Button", panel.transform, "끝내기", new Color(0.12f, 0.09f, 0.06f, 0.30f), new Color(1f, 0.96f, 0.86f, 0.72f), 13);
 3116 |         progressText = CreateText("Progress Text", tracker.transform, "0/5 질문 · 답변 대기", 12, new Color32(46, 32, 18, 232), TextAnchor.MiddleLeft, FontStyle.Bold);
 3200 |                 action.text = $"추천 질문 {i + 1} · 누르면 바로 질문";
 3260 |         noteTitleText = CreateText("Note Title", screen.transform, "무엇을 물어볼까요?", 18, new Color32(15, 23, 42, 248), TextAnchor.UpperLeft, FontStyle.Bold);
 3277 |         string[] tabLabels = { "질문", "장면", "기록" };
 3317 |         string[] chapters = { "일상", "이동", "도움", "일과 공부", "독립", "취미" };
 3344 |         moreButton = CreateNoteActionButton("More Button", noteQuestionBodyObject.transform, "더 듣기", true);
 3345 |         closingButton = CreateNoteActionButton("Closing Button", noteQuestionBodyObject.transform, "남길 문장 보기", false);
 3412 |                 ? "지금 열린 장면"
 3413 |                 : (currentNoteTabIndex == 2 ? "지난 대화" : "무엇을 물어볼까요?");
 3452 |         string theme = string.IsNullOrWhiteSpace(lastTheme) ? "아직 없음" : lastTheme;
 3454 |             ? "질문을 고르면 이곳에 장면이 열립니다."
 3455 |             : $"{theme} 장면이 열렸습니다. 다음 답변도 이 흐름에 맞춰 이어집니다.";
 3457 |         string memoryNote = "아직 기억장에 남긴 메모가 없습니다.";
 3467 |             ? "깊은 기록"
 3468 |             : "얕은 기록";
 3470 |         string attitude = string.IsNullOrWhiteSpace(lastQuestionAttitude) ? "아직 없음" : lastQuestionAttitude;
 3475 |         builder.Append("<b><color=#1E293B>진행 요약</color></b>  ");
 3476 |         builder.Append(SanitizeRichText($"{opened}/6 장면 · 깊은 기록 {deepCount}/6")).AppendLine();
 3478 |         builder.Append("<b>첫 인상</b>  ").Append(SanitizeRichText(BuildFirstImpressionDisplayLabel())).AppendLine();
 3479 |         builder.Append("<b>겉!=속 경로</b>  ").Append(SanitizeRichText(ShortenForCard(BuildFirstImpressionArcState(), 42))).AppendLine();
 3480 |         builder.Append("<b>현재 장면</b>  ").Append(SanitizeRichText($"{theme} · {depth}")).AppendLine();
 3481 |         builder.Append("<b>질문 태도</b>  ").Append(SanitizeRichText(attitude)).AppendLine();
 3482 |         builder.Append("<b>답변 출처</b>  ").Append(SanitizeRichText(FormatAnswerSourceForPlayer())).AppendLine();
 3484 |         builder.Append("<b><color=#7C2D12>장면 메모</color></b>").AppendLine();
 3487 |         builder.Append("<b><color=#7C2D12>기억장 메모</color></b>").AppendLine();
 3496 |             return "<b><color=#1E293B>최근 대화 없음</color></b>\n<color=#B1713A>────────────────</color>\n질문을 고르면 최근 질문과 답변이 이곳에 남습니다.";
 3500 |         builder.Append("<b><color=#1E293B>최근 대화</color></b>  ");
 3501 |         builder.Append(SanitizeRichText($"{conversationTurns}/5 질문")).AppendLine();
 3508 |             string role = message.role == "user" ? "나" : "답변";
 3540 |         Text title = CreateText("Closing Card Title", card.transform, "오늘 남길 문장", 30, new Color32(30, 41, 59, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 3543 |         Text subtitle = CreateText("Closing Card Subtitle", card.transform, "다섯 번의 대화 뒤, 가져갈 문장을 고릅니다.", 16, new Color32(71, 85, 105, 255), TextAnchor.UpperLeft, FontStyle.Normal);
 3602 |         closingCardSaveButton = CreateNoteActionButton("Closing Card Save", card.transform, "저장 후 보기", true);
 3610 |         closingCardContinueButton = CreateNoteActionButton("Closing Card Continue", card.transform, "계속하기", false);
 3617 |             statusText.text = "인터뷰를 이어갈 수 있습니다";
 3621 |         Button closeButton = CreateNoteActionButton("Closing Card Close", card.transform, "닫기", false);
 3627 |             statusText.text = "마무리 카드를 닫았습니다";
 3631 |         Button feedbackButton = CreateNoteActionButton("Closing Card Feedback", card.transform, "의견 남기기", false);
 3680 |             statusText.text = "기록 저장됨 · 기록함에서 확인";
 3684 |             statusText.text = "기록 저장에 실패했습니다";
 3709 |         builder.AppendLine($"저장 시각: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
 3711 |         builder.AppendLine("세션 요약");
 3712 |         builder.AppendLine($"문답 수: {conversationTurns}");
 3713 |         builder.AppendLine($"세션 완성도: {BuildSessionCompletionLine()}");
 3714 |         builder.AppendLine($"열린 장면: {discoveredThemes.Count}/{memoryThemes.Length}");
 3715 |         builder.AppendLine($"처음 본 것: {BuildFirstImpressionDisplayLabel()}");
 3716 |         builder.AppendLine($"겉!=속 경로: {BuildFirstImpressionArcLine()}");
 3717 |         builder.AppendLine($"가장 많이 물은 태도: {GetDominantAttitude()}");
 3718 |         builder.AppendLine($"깊은 기록: {CountDeepMemories()}/{memoryThemes.Length}");
 3719 |         builder.AppendLine(discoveredThemes.Count >= memoryThemes.Length ? "완성 여부: 모든 장면 완성" : "완성 여부: 진행 중");
 3721 |         builder.AppendLine("오늘 남길 문장");
 3724 |         builder.AppendLine($"선택 이유: {BuildClosingSelectionLine(selected)}");
 3726 |         builder.AppendLine($"다음에 이어볼 질문: {BuildNextSessionPromptLine()}");
 3728 |         builder.AppendLine("오늘 열린 장면");
 3733 |             builder.AppendLine("아직 기억장에 남은 장면이 없습니다.");
 3744 |         builder.AppendLine("오늘의 대화");
 3746 |         builder.AppendLine(string.IsNullOrWhiteSpace(transcript) ? "아직 저장할 대화가 없습니다." : transcript);
 3762 |         builder.AppendLine($"{GameTitle} 의견 메모");
 3763 |         builder.AppendLine($"저장 시각: {savedAt:yyyy-MM-dd HH:mm:ss}");
 3764 |         builder.AppendLine($"세션 ID: {playtestSessionId}");
 3765 |         builder.AppendLine($"빌드 ID: {GetBuildIdForRecord(buildInfo)}");
 3766 |         builder.AppendLine($"앱 버전: {GetBuildVersionForRecord(buildInfo)}");
 3767 |         builder.AppendLine($"실행 환경: {Application.platform} / {SystemInfo.operatingSystem}");
 3768 |         builder.AppendLine($"화면: {Screen.width}x{Screen.height}, 전체화면: {Screen.fullScreen}");
 3769 |         builder.AppendLine($"설정: 글자 크기 단계 {dialogueSizeLevel}, 움직임 줄임 {reducedMotionEnabled}, 읽기 쉬운 화면 {highContrastEnabled}, 서버 필수 {(!localAnswerOnly)}, 소리 단계 {soundLevel}");
 3770 |         builder.AppendLine($"평가: {rating}");
 3771 |         builder.AppendLine($"5달러 기준: {commercialReadiness}");
 3772 |         builder.AppendLine($"이슈 등급: {issueSeverity}");
 3773 |         builder.AppendLine($"문답 수: {conversationTurns}");
 3774 |         builder.AppendLine($"세션 완성도: {BuildSessionCompletionLine()}");
 3775 |         builder.AppendLine($"열린 장면: {discoveredThemes.Count}/{memoryThemes.Length}");
 3776 |         builder.AppendLine($"열린 장면 태그: {FormatPlaytestTags(GetOpenedSceneTags())}");
 3777 |         builder.AppendLine($"처음 본 것: {BuildFirstImpressionDisplayLabel()}");
 3778 |         builder.AppendLine($"겉!=속 경로: {BuildFirstImpressionArcLine()}");
 3779 |         builder.AppendLine($"다음 질문 방향: {BuildNextSessionPromptLine()}");
 3780 |         builder.AppendLine($"주된 질문 태도: {GetDominantAttitude()}");
 3781 |         builder.AppendLine($"깊은 기록 수: {CountDeepMemories()}/{memoryThemes.Length}");
 3782 |         builder.AppendLine($"마지막 장면: {lastTheme}");
 3783 |         builder.AppendLine($"5문답 완료: {(IsCompletedFiveTurnSession() ? "예" : "아니오")}");
 3784 |         builder.AppendLine($"마무리 기록 저장: {(HasSavedEndingRecordThisSession() ? "예" : "아니오")}");
 3785 |         builder.AppendLine($"긍정 근거 마무리 필요: {(ShouldRequireEndingRecordForPositiveEvidence() ? "예" : "아니오")}");
 3786 |         builder.AppendLine($"긍정 근거 사용 가능: {(IsPositiveQualityEvidenceReady() ? "예" : "아니오")}");
 3787 |         builder.AppendLine($"선택 초점: {GetPlaytestQualityFocusLabel(selectedPlaytestQualityFocus)} ({GetPlaytestQualityFocusAreaId(selectedPlaytestQualityFocus)})");
 3788 |         builder.AppendLine($"품질 영역: {FormatPlaytestTags(qualityAreas)}");
 3789 |         builder.AppendLine($"위험 태그: {FormatPlaytestTags(riskTags)}");
 3790 |         builder.AppendLine($"증거 등급: {GetPlaytestEvidenceTier()}");
 3791 |         builder.AppendLine($"추천 조치: {BuildReviewActionRecommendationLine()}");
 3792 |         builder.AppendLine($"상업 품질 근거: {BuildCommercialQualityEvidenceLine()}");
 3794 |         builder.AppendLine("메모");
 3795 |         builder.AppendLine(string.IsNullOrWhiteSpace(note) ? "입력된 메모가 없습니다." : note);
 3797 |         builder.AppendLine("오늘 열린 장면");
 3801 |             builder.AppendLine("아직 기억장에 남은 장면이 없습니다.");
 3811 |         builder.AppendLine("대화 로그");
 3813 |         builder.AppendLine(string.IsNullOrWhiteSpace(transcript) ? "아직 저장할 대화가 없습니다." : transcript);
 3906 |         if (rating <= 1) return "헷갈림";
 3907 |         if (rating >= 3) return "좋음";
 3908 |         return "보통";
 3913 |         if (readiness <= 1) return "부족";
 3914 |         if (readiness >= 3) return "충분";
 3915 |         return "보류";
 3925 |             default: return "없음";
 3933 |             case 1: return "사소한 문제";
 3934 |             case 2: return "진행 방해";
 3935 |             case 3: return "진행 불가";
 3936 |             default: return "문제 없음";
 3944 |             case 1: return "완성도 느낌";
 3945 |             case 2: return "문제 단계";
 3946 |             case 3: return "주요 영역";
 3947 |             default: return "전체 느낌";
 3971 |             case 1: return "진행";
 3972 |             case 2: return "문장";
 3973 |             case 3: return "읽기";
 3974 |             case 4: return "조작";
 3975 |             case 5: return "신뢰";
 3976 |             case 6: return "시각";
 3977 |             case 7: return "상점";
 3978 |             case 8: return "안정";
 3979 |             default: return "전체 느낌";
 3985 |         return $"초점: {GetPlaytestQualityFocusLabel(focus)}";
 4018 |         if (TextHasAnyKeyword(note, new[] { "말투", "AI", "사람", "설명문", "답변", "대화", "어조", "문장" }))
 4022 |         if (TextHasAnyKeyword(note, new[] { "긴", "길", "스크롤", "읽", "글자", "잘림", "화면", "대사", "자막", "넘", "뚫" }) || highContrastEnabled || dialogueSizeLevel != 0)
 4026 |         if (TextHasAnyKeyword(note, new[] { "입력", "버튼", "키보드", "마우스", "설정", "저장", "삭제", "기록", "조작" }))
 4030 |         if (TextHasAnyKeyword(note, new[] { "API", "키", "마이크", "로컬", "삭제 안내", "개인정보", "신뢰", "서버" }) || localAnswerOnly)
 4034 |         if (TextHasAnyKeyword(note, new[] { "캐릭터", "사람", "배경", "보라", "색", "그래픽", "그림", "캡슐", "스크린샷", "밝" }))
 4038 |         if (TextHasAnyKeyword(note, new[] { "트레일러", "상점", "가격", "5달러", "유료", "구매", "소개" }))
 4042 |         if (TextHasAnyKeyword(note, new[] { "실행", "오류", "멈춤", "서버", "fallback", "지원", "번들", "패키지", "튕" }) || selectedPlaytestIssueSeverity >= 2)
 4077 |             return "긍정 근거: 5문답과 마무리 기록이 완료되었습니다. 대화 톤, 조작, 마무리 기록을 함께 검토하세요.";
 4081 |             return "근거 보강: 긍정 의견은 5문답 완료 뒤 다시 저장해야 합니다.";
 4085 |             return "근거 보강: 마무리 기록 저장 뒤 긍정 의견을 다시 남겨야 합니다.";
 4089 |             return $"우선 수정: {GetPlaytestIssueSeverityLabel(selectedPlaytestIssueSeverity)} 문제를 이슈로 등록하고 재검증하세요.";
 4093 |             return "수정 후보: 사소한 문제를 P2 이슈로 등록하고 다음 빌드에서 확인하세요.";
 4097 |             return "우선 개선: 메모의 품질 영역을 묶고 원인을 재현하세요.";
 4101 |             return "판단 보강: 메모의 품질 영역을 다음 외부 리뷰에서 다시 확인하세요.";
 4104 |         return "관찰 메모: 대화 로그와 열린 장면을 다음 확인 때 함께 보세요.";
 4111 |             return "점수표 후보: 5문답 완료, 마무리 기록 저장, 좋음/충분함/문제 없음이 함께 충족되었습니다.";
 4115 |             return "점수표 보류: 긍정 판정 전에 5문답 완료 증거가 필요합니다.";
 4119 |             return "점수표 보류: 긍정 판정 전에 마무리 기록 저장 증거가 필요합니다.";
 4123 |             return $"점수표 보류: {GetPlaytestIssueSeverityLabel(selectedPlaytestIssueSeverity)} 이슈를 외부 이슈 레지스터에 등록해야 합니다.";
 4127 |             return "점수표 보류: 낮은 평가나 부족 판정의 원인을 메모와 대화 로그로 재현해야 합니다.";
 4131 |             return "점수표 보류: 5달러 충분 판정 전 다음 외부 리뷰에서 재확인 필요.";
 4134 |         return "점수표 참고: 중립 관찰 메모로 품질 영역과 대화 로그를 비교합니다.";
 4223 |             string speaker = message.role == "user" ? "나" : "답변";
 4267 |         builder.AppendLine("첫 인상: " + BuildFirstImpressionDisplayLabel());
 4268 |         builder.AppendLine("세션 완성도: " + BuildSessionCompletionLine());
 4269 |         builder.Append("태도: ").Append(GetDominantAttitude());
 4270 |         builder.Append("    깊은 기록: ").Append(CountDeepMemories()).Append("/").Append(memoryThemes.Length);
 4275 |             builder.Append("\n시선 변화: ").Append(shift);
 4278 |         builder.Append("\n선택 이유: ").Append(ShortenForCard(BuildClosingSelectionLine(selectedClosingIndex), 82));
 4281 |             builder.Append("\n마지막 선택 기록: ").Append(ShortenForCard(lastChoiceConsequenceLine, 88));
 4283 |         builder.Append("\n다음 질문: ").Append(ShortenForCard(BuildNextSessionPromptLine(), 82));
 4286 |         builder.Append("\n오늘 열린 장면: ");
 4287 |         builder.Append(string.IsNullOrWhiteSpace(sceneTags) ? "아직 없음" : sceneTags);
 4300 |             ? "5문답 완료"
 4301 |             : $"{Mathf.Clamp(conversationTurns, 0, 5)}/5 문답";
 4303 |             ? $"장면 {openedScenes}/{totalScenes}"
 4304 |             : $"장면 {openedScenes}/{totalScenes} · 남은 {remainingScenes}";
 4305 |         return $"{turnLine} · {sceneLine} · 깊은 {deepScenes}/{totalScenes}";
 4315 |             return $"{shallow} 장면에 배려/호기심 질문을 더해 보세요.";
 4321 |             return $"다음 질문으로 {unopened} 장면을 열어 보세요.";
 4326 |             return "얕게 남은 장면을 골라 조금 더 구체적으로 물어보세요.";
 4329 |         return "모든 장면이 열렸습니다. 기록함에서 오늘 남긴 문장을 다시 볼 수 있습니다.";
 4371 |                 label.text = i == recommended ? $"추천 · {closingChoiceLabels[i]}" : closingChoiceLabels[i];
 4388 |             tags.Add($"{theme} {(deep ? "깊음" : "얕음")}");
 4398 |             joined += $" 외 {openedCount - tags.Count}";
 4414 |                 string line = $"{memoryThemes[i]} [{(deep ? "깊은 기록" : "얕은 기록")}]: {memoryCaptions[i]}";
 4427 |         return string.IsNullOrWhiteSpace(firstImpression) ? "아직 고르지 않음" : firstImpression;
 4432 |         return HasFirstImpressionChoice() ? firstImpression : "첫 인상 없이 대화 시작";
 4454 |         return bestIndex >= 0 ? $"{attitudeNames[bestIndex]} {bestCount}회" : "아직 없음";
 4459 |         string deepLine = CountDeepMemories() > 0 ? "깊은 기록까지 열면서" : "얕은 기록을 열면서";
 4462 |             return $"처음에는 열린 장면을 따라갔고, 지금은 {deepLine} 보이지 않던 생활의 맥락까지 남겼습니다.";
 4466 |         string subject = string.Equals(impression, "이야기 보기", StringComparison.Ordinal) ? "이야기 보기 모드로" : $"{impression}이";
 4467 |         return $"처음에는 {subject} 먼저 보였고, 지금은 {deepLine} 그 뒤의 생활까지 남겼습니다.{BuildFirstImpressionResonanceLine()}";
 4481 |             return $" 처음 본 {firstImpression}은 {theme} 깊은 기록까지 이어졌습니다.";
 4485 |             return $" 처음 본 {firstImpression}은 {theme} 장면으로 이어졌습니다.";
 4488 |         return $" 처음 본 {firstImpression}은 아직 {theme} 장면까지 닿지 않았습니다.";
 4494 |         if (dominant.StartsWith("배려", StringComparison.Ordinal))
 4499 |         if (discoveredThemes != null && (discoveredThemes.Contains("이동") || string.Equals(firstImpression, "목발", StringComparison.Ordinal)))
 4523 |             if (string.Equals(attitude, "아직 없음", StringComparison.Ordinal))
 4525 |                 return $"{label}은 아직 질문이 적은 상태에서, 먼저 묻는 태도를 남깁니다.";
 4528 |             return $"{label}은 {attitude}의 질문 흐름을 먼저 묻는 태도로 정리합니다.";
 4534 |                 return $"{label}은 오늘 열린 장면을 하루의 동선으로 묶습니다.";
 4537 |             return $"{label}은 처음 본 {impression}과 열린 장면을 하루의 동선으로 묶습니다.";
 4542 |             return $"{label}은 깊은 기록 {deepCount}개를 한 사람의 생활로 묶습니다.";
 4545 |         return $"{label}은 처음 본 {impression} 뒤에 열린 깊은 기록 {deepCount}개를 한 사람의 생활로 묶습니다.";
 4584 |         Text title = CreateText("Memory Book Title", page.transform, "기억장", 22, new Color32(30, 41, 59, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 4587 |         memoryBookCountText = CreateText("Memory Book Count", page.transform, "0/6 장면", 13, new Color32(71, 85, 105, 238), TextAnchor.UpperRight, FontStyle.Bold);
 4590 |         memoryBookSubtitleText = CreateText("Memory Book Subtitle", page.transform, "책상 위에 남은 장면들", 13, new Color32(71, 85, 105, 232), TextAnchor.UpperLeft, FontStyle.Normal);
 4630 |         Button closeButton = CreateNoteActionButton("Memory Book Close", page.transform, "닫기", false);
 4690 |             statusText.text = "기억장을 열었습니다";
 4724 |             statusText.text = $"{theme} 장면으로 이어갑니다";
 4804 |             return "새 기록: 여섯 장면 완성 · 기록함에서 오늘 남긴 문장을 다시 볼 수 있습니다.";
 4807 |         string safeTheme = string.IsNullOrWhiteSpace(theme) ? "장면" : CanonicalTheme(theme);
 4809 |             ? $"새 기록: {safeTheme} 깊은 기록 열림 · 속 맥락이 기록함에 남았습니다."
 4810 |             : $"새 기록: {safeTheme} 장면 열림 · 배려/호기심 질문으로 더 들어갈 수 있습니다.";
 4843 |         string safeTheme = string.IsNullOrWhiteSpace(theme) ? "장면" : theme;
 4844 |         string safeAttitude = string.IsNullOrWhiteSpace(attitude) ? "태도 없음" : attitude;
 4845 |         string depth = deep ? "깊은 기록" : "얕은 기록";
 4849 |             return $"선택 기록: {safeAttitude} 질문 -> {safeTheme} 깊은 기록 · 질문과 단서가 맞물렸습니다.";
 4853 |             return $"선택 기록: {safeAttitude} 질문 -> {safeTheme} 깊은 기록 유지 · 이미 열린 속 이야기를 다시 확인했습니다.";
 4856 |         return $"선택 기록: {safeAttitude} 질문 -> {safeTheme} 얕은 기록 · 배려/호기심으로 더 깊게 열 수 있습니다.";
 4862 |         if (!string.Equals(attitude, "배려", StringComparison.Ordinal) && !string.Equals(attitude, "호기심", StringComparison.Ordinal)) return false;
 4863 |         if (IsFirstImpressionTheme(theme) && HasAny(question, firstImpression, "먼저", "이어", "생활", "의미", "하루"))
 4870 |             case "일상": return HasAny(question, "평범", "하루", "목발보다", "사람");
 4871 |             case "이동": return HasAny(question, "처음", "공간", "동선", "엘리베이터", "화장실");
 4872 |             case "도움": return HasAny(question, "어떻게 도와", "편할까요", "방식", "먼저 물");
 4873 |             case "일과 공부": return HasAny(question, "책상", "노트북", "직장", "박사", "공부");
 4874 |             case "독립": return HasAny(question, "자취", "독립", "집", "자기이해");
 4875 |             case "취미": return HasAny(question, "취미", "게임", "노래방", "쉬는");
 4890 |         string depth = deep ? "깊은 기록" : "얕은 기록";
 4905 |         if (HasAny(value, "취미", "게임", "노래방")) return "취미";
 4906 |         if (HasAny(value, "자취", "독립", "자기이해")) return "독립";
 4907 |         if (HasAny(value, "일과", "공부", "직장", "책상", "노트북", "박사")) return "일과 공부";
 4908 |         if (HasAny(value, "도움", "배려", "조율")) return "도움";
 4909 |         if (HasAny(value, "이동", "접근성", "처음", "동선", "길", "교통")) return "이동";
 4910 |         if (HasAny(value, "일상", "평범", "사람", "이야기")) return "일상";
 4920 |         if (memoryBookCountText != null) memoryBookCountText.text = $"{count}/6 장면 · 깊은 기록 {deepCount}";
 4943 |                 ? "모든 장면 완성"
 4944 |                 : $"남은 장면 {Mathf.Max(0, memoryThemes.Length - count)}개";
 4972 |                     : $"<b>{SanitizeRichText(memoryThemes[i])}</b>\n아직 듣지 못한 장면";
 5009 |                 ? $"여섯 장면 완성 · {target}"
 5014 |             ? "여섯 장면 완성 · 배려/호기심 질문으로 더 들어갑니다."
 5015 |             : "배려/호기심 질문으로 얕은 기록을 더 열어 봅니다.";
 5025 |             return $"첫 인상 {firstImpression}이 {theme} 깊은 기록까지 이어졌습니다.";
 5029 |             return $"첫 인상 {firstImpression}에서 {theme} 깊은 기록을 더 물어보세요.";
 5032 |         return $"첫 인상 {firstImpression}에서 {theme} 장면으로 이어가 보세요.";
 5039 |             case "목발": return "이동";
 5040 |             case "책상": return "일과 공부";
 5041 |             case "표정": return "일상";
 5074 |             return "첫 인상을 고르면 생활 장면과 연결됩니다.";
 5079 |             return $"{firstImpression} -> {theme} 깊은 기록";
 5083 |             return $"{firstImpression} -> {theme} 장면 열림";
 5086 |         return $"{firstImpression} -> {theme} 장면 대기";
 5094 |             return "첫 인상을 고르면 겉으로 보인 단서가 속의 생활 장면으로 이어집니다.";
 5099 |             return $"처음 본 {firstImpression}이 {theme} 깊은 기록까지 이어져, 겉으로 보인 단서와 속의 생활 맥락이 함께 남았습니다.";
 5103 |             return $"처음 본 {firstImpression}이 {theme} 장면으로 열렸고, 배려나 호기심 질문으로 더 깊어질 수 있습니다.";
 5106 |         return $"처음 본 {firstImpression}을 아직 {theme} 장면으로 이어야 해서, 다음 질문이 겉과 속을 연결하는 역할을 합니다.";
 5118 |                 ? $"장면 {total}/{total} · 깊은 기록 {deep}"
 5119 |                 : $"장면 {count}/{total} · 깊은 {deep} · 남은 {Mathf.Max(0, total - count)}";
 5157 |         if (deep) return $"{canonical} · 깊음";
 5158 |         if (opened) return $"{canonical} · 깊게";
 5159 |         return $"{canonical} · 열기";
 5179 |         return $"장면: 새로 열기 {unopened} · 더 묻기 {shallow} · 깊음 {deep}";
 5191 |                 ? $"마무리 가능 · {sessionLine} · 남은 장면 {remainingScenes}"
 5197 |             return $"{BuildChapterStateSummaryLine()} · 배려/호기심으로 깊게";
 5204 |                 ? $"{sessionLine} · {remainingQuestions}문답 남음"
 5208 |         return $"{sessionLine} · 마지막까지 {remainingQuestions}문답";
 5214 |         string attitude = string.Equals(dominant, "아직 없음", StringComparison.Ordinal)
 5215 |             ? "질문 전"
 5216 |             : $"주된 질문 {dominant}";
 5217 |         return $"{attitude} · 깊은 {deepScenes}/{totalScenes}";
 5229 |         if (deep) return $"첫 인상 {theme} 깊음";
 5230 |         if (opened) return $"첫 인상 {theme} 더 묻기";
 5231 |         return $"첫 인상 {theme}";
 5239 |             return $"마무리 가능 · {BuildQuestionSessionQualityLine(deepScenes, totalScenes)}";
 5242 |         return $"마무리 가능 · {BuildQuestionSessionQualityLine(deepScenes, totalScenes)}";
 5247 |         string depthLabel = deep ? "깊은 기록" : "얕은 기록";
 5307 |         Text title = CreateText("First Impression Title", panel.transform, "먼저 눈에 들어온 장면", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 5313 |             "이 선택은 정답이 아니라 첫인상입니다. 겉 단서를 고르면, 연결된 속 장면에서 대화를 시작합니다.",
 5426 |         continueButton = CreateButton("Continue Interview Button", startMenuObject.transform, "이어하기", new Color(0.54f, 0.32f, 0.16f, 0.90f), new Color(1f, 0.96f, 0.86f, 0.98f), 16);
 5435 |                 statusText.text = "저장된 대화를 이어갑니다";
 5439 |         startButton = CreateButton("Start Interview Button", startMenuObject.transform, "처음부터", new Color(0.46f, 0.27f, 0.13f, 0.92f), new Color(1f, 0.96f, 0.86f, 0.98f), 16);
 5443 |         startNoteButton = CreateButton("Start With Phone Button", startMenuObject.transform, "질문 노트", new Color(0.11f, 0.085f, 0.060f, 0.70f), new Color32(236, 224, 198, 235), 14);
 5447 |         startStoryButton = CreateButton("Start Story Mode Button", startMenuObject.transform, "이야기 보기", new Color(0.16f, 0.11f, 0.07f, 0.72f), new Color32(236, 224, 198, 238), 14);
 5451 |         Button archiveButton = CreateStartUtilityButton("Record Archive From Start Button", startMenuObject.transform, "기록");
 5456 |         startSettingsButton = CreateStartUtilityButton("Settings From Start Button", startMenuObject.transform, "설정");
 5460 |         startAboutButton = CreateStartUtilityButton("Start About Button", startMenuObject.transform, "정보");
 5464 |         Button quitButton = CreateStartUtilityButton("Quit From Start Button", startMenuObject.transform, "종료");
 5481 |         Text title = CreateText("Pause Menu Title", panel.transform, "잠시 멈춤", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 5484 |         Text body = CreateText("Pause Menu Body", panel.transform, "대화를 이어가거나, 처음부터 다시 시작할 수 있습니다.", 16, new Color32(71, 85, 105, 255), TextAnchor.UpperLeft, FontStyle.Normal);
 5487 |         Button resumeButton = CreateButton("Resume Button", panel.transform, "계속하기", new Color32(177, 113, 58, 245), Color.white, 17);
 5491 |         Button settingsButton = CreateButton("Settings From Pause Button", panel.transform, "설정", new Color32(30, 41, 59, 238), Color.white, 17);
 5495 |         Button restartButton = CreateButton("Restart Button", panel.transform, "처음부터", new Color32(30, 41, 59, 238), Color.white, 17);
 5499 |         Button quitButton = CreateButton("Quit From Pause Button", panel.transform, "종료", new Color(1f, 0.99f, 0.95f, 0.96f), new Color32(30, 41, 59, 255), 17);
 5508 |         return "먼저 본인 이야기를 충분히 듣고, 궁금한 장면을 골라 5번 질문합니다.";
 5520 |         Text title = CreateText("Settings Menu Title", panel.transform, "설정", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 5523 |         Text textSizeLabel = CreateText("Settings Text Size Label", panel.transform, "글자 크기", 16, new Color32(51, 65, 85, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 5527 |         string[] labels = { "작게", "기본", "크게" };
 5538 |         Text screenLabel = CreateText("Settings Screen Label", panel.transform, "화면, 소리, 답변", 16, new Color32(51, 65, 85, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 5541 |         fullscreenButton = CreateButton("Fullscreen Toggle Button", panel.transform, "전체 화면", new Color32(30, 41, 59, 238), Color.white, 16);
 5545 |         soundButton = CreateButton("Sound Toggle Button", panel.transform, "소리 기본", new Color32(30, 41, 59, 238), Color.white, 16);
 5549 |         reducedMotionButton = CreateButton("Reduced Motion Toggle Button", panel.transform, "움직임 기본", new Color32(30, 41, 59, 238), Color.white, 16);
 5553 |         highContrastButton = CreateButton("High Contrast Toggle Button", panel.transform, "읽기 쉬운 화면", new Color32(30, 41, 59, 238), Color.white, 16);
 5557 |         Button archiveButton = CreateButton("Open Record Archive Button", panel.transform, "기록함", new Color32(30, 41, 59, 238), Color.white, 16);
 5561 |         Button aboutButton = CreateButton("About Button", panel.transform, "정보", new Color32(30, 41, 59, 238), Color.white, 16);
 5565 |         localAnswerOnlyButton = CreateButton("Local Answer Only Toggle Button", panel.transform, "서버 필수", new Color32(30, 41, 59, 238), Color.white, 15);
 5569 |         Button closeButton = CreateButton("Close Settings Button", panel.transform, "닫기", new Color32(146, 83, 40, 245), Color.white, 17);
 5586 |         Text title = CreateText("About Menu Title", panel.transform, "정보", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 5592 |             "이 앱은 2026년 5월 1일 인터뷰와 조별 활동 자료를 바탕으로 만들었습니다.\n\n답변은 확인된 자료와 서버 연결 상태를 기준으로 이어집니다. API 키는 앱이나 기록 파일에 저장하지 않습니다.\n\n서버와 API 답변이 준비되지 않으면 시작하거나 질문할 수 없습니다.\n\n마이크 녹음은 전사할 때만 서버로 보내며, 마무리 기록과 의견 메모는 이 컴퓨터에 저장됩니다.\n\n자료에 없는 개인정보, 진단명, 회사명, 주소, 연락처는 만들지 않습니다.",
 5612 |         Button serverRefreshButton = CreateButton("About Server Refresh Button", statusPanel.transform, "상태 확인", new Color32(146, 83, 40, 245), Color.white, 15);
 5616 |         Button recordFolderButton = CreateButton("About Record Folder Button", panel.transform, "기록 폴더", new Color32(30, 41, 59, 238), Color.white, 16);
 5620 |         Button feedbackFolderButton = CreateButton("About Feedback Folder Button", panel.transform, "의견 폴더", new Color32(30, 41, 59, 238), Color.white, 16);
 5624 |         clearLocalDataButton = CreateButton("About Clear Local Data Button", panel.transform, "저장 삭제", new Color32(133, 111, 82, 230), Color.white, 16);
 5631 |         clearLocalDataHintText = CreateText("About Clear Local Data Hint", clearLocalDataHintPanel.transform, "저장 삭제는 확인 후 실행됩니다.", 15, new Color32(88, 72, 54, 255), TextAnchor.MiddleLeft, FontStyle.Bold);
 5637 |         Button closeButton = CreateButton("Close About Button", panel.transform, "닫기", new Color32(146, 83, 40, 245), Color.white, 17);
 5660 |         Text title = CreateText("Record Archive Title", panel.transform, "기록함", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 5663 |         Text subtitle = CreateText("Record Archive Subtitle", panel.transform, "저장한 마무리 기록을 다시 읽을 수 있습니다.", 16, new Color32(71, 85, 105, 255), TextAnchor.UpperLeft, FontStyle.Normal);
 5669 |         recordArchiveListTitleText = CreateText("Record Archive List Title", listPanel.transform, "최근 기록", 16, new Color32(30, 41, 59, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 5685 |         Text previewTitle = CreateText("Record Archive Preview Title", previewPanel.transform, "마무리 기록", 17, new Color32(30, 41, 59, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 5739 |         Button folderButton = CreateButton("Record Archive Folder Button", panel.transform, "폴더 열기", new Color32(30, 41, 59, 238), Color.white, 15);
 5743 |         Button refreshButton = CreateButton("Record Archive Refresh Button", panel.transform, "새로고침", new Color32(30, 41, 59, 238), Color.white, 15);
 5747 |         recordArchiveDeleteButton = CreateButton("Record Archive Delete Button", panel.transform, "선택 삭제", new Color32(133, 111, 82, 230), Color.white, 15);
 5751 |         recordArchiveCancelDeleteButton = CreateButton("Record Archive Cancel Delete Button", panel.transform, "취소", new Color32(30, 41, 59, 238), Color.white, 15);
 5765 |         Button closeButton = CreateButton("Record Archive Close Button", panel.transform, "닫기", new Color32(146, 83, 40, 245), Color.white, 16);
 5784 |         Text title = CreateText("Playtest Feedback Title", panel.transform, "의견 남기기", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 5790 |             "이야기를 마친 뒤 느낀 점을 남겨 주세요. 좋았던 부분, 헷갈린 흐름, 멈춘 지점을 적으면 다음 수정에 도움이 됩니다. 메모와 세션 정보는 이 컴퓨터에만 저장됩니다.",
 5798 |         Text ratingLabel = CreateText("Playtest Rating Label", panel.transform, "전체 느낌", 13, new Color32(71, 85, 105, 238), TextAnchor.MiddleLeft, FontStyle.Bold);
 5802 |         string[] labels = { "헷갈림", "보통", "좋음" };
 5812 |         Text readinessLabel = CreateText("Playtest Commercial Readiness Label", panel.transform, "완성도 느낌", 13, new Color32(71, 85, 105, 238), TextAnchor.MiddleLeft, FontStyle.Bold);
 5816 |         string[] commercialLabels = { "더 다듬기", "조금 아쉬움", "충분함" };
 5826 |         Text issueLabel = CreateText("Playtest Issue Severity Label", panel.transform, "문제 단계", 13, new Color32(71, 85, 105, 238), TextAnchor.MiddleLeft, FontStyle.Bold);
 5840 |         Text focusLabel = CreateText("Playtest Quality Focus Label", panel.transform, "주요 영역", 13, new Color32(71, 85, 105, 238), TextAnchor.MiddleLeft, FontStyle.Bold);
 5868 |         playtestFeedbackStatusText = CreateText("Playtest Feedback Status", panel.transform, "이 컴퓨터에만 저장되는 메모입니다.", 14, new Color32(71, 85, 105, 255), TextAnchor.UpperLeft, FontStyle.Normal);
 5871 |         Button folderButton = CreateButton("Playtest Feedback Folder", panel.transform, "폴더 열기", new Color32(30, 41, 59, 238), Color.white, 15);
 5875 |         Button saveButton = CreateButton("Playtest Feedback Save", panel.transform, "저장", new Color32(146, 83, 40, 245), Color.white, 15);
 5879 |         Button closeButton = CreateButton("Playtest Feedback Close", panel.transform, "닫기", new Color32(30, 41, 59, 238), Color.white, 15);
 5906 |         Text title = CreateText("Fresh Start Confirm Title", panel.transform, "처음부터 시작할까요?", 28, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
 5912 |             "현재 이어하기 데이터와 진행 중인 기억장이 지워집니다.\n기록함에 저장한 마무리 기록은 남습니다.",
 5920 |         Button confirmButton = CreateButton("Fresh Start Confirm Button", panel.transform, "새로 시작", new Color32(146, 83, 40, 245), Color.white, 17);
 5934 |         Button cancelButton = CreateButton("Fresh Start Cancel Button", panel.transform, "취소", new Color32(30, 41, 59, 238), Color.white, 17);
 5956 |         statusText.text = openQuestionPhone ? "질문 노트에서 주제를 고를 수 있습니다" : "인터뷰 시작";
 6016 |         firstImpression = "이야기 보기";
 6044 |         if (statusText != null) statusText.text = "먼저 이 사람이 누구인지 충분히 듣고, 그 다음 질문을 고릅니다.";
 6052 |             string theme = i < openingStoryThemes.Length ? openingStoryThemes[i] : "일상";
 6057 |             AppendMessage("이야기", line, "#0f766e");
 6059 |             lastEvidenceLine = $"{theme} 도입 장면을 먼저 봤습니다. {currentStoryModeBeatLine}";
 6062 |             PresentAssistant(line, i == 0 ? "먼저 듣는 이야기" : "이어지는 이야기");
 6063 |             ShowSceneFocus(GetSceneFocusLabelForTheme(theme), GetSceneFocusPositionForTheme(theme), "도입 장면", 2.0f);
 6073 |                 statusText.text = $"본인 이야기 {i + 1}/{openingStoryLines.Length} · 듣고 나서 질문을 고릅니다.";
 6089 |         currentStoryModeBeatLine = "방금 본 장면에서 출발합니다.";
 6105 |                 return "겉: 이동 도구 · 속: 회사원, 박사과정생, 자취하는 사람";
 6107 |                 return "겉: 목발 · 속: 하루를 밖으로 이어주는 준비";
 6109 |                 return "겉: 도움 받는 순간 · 속: 먼저 묻고 조율하는 관계";
 6111 |                 return "겉: 책상 · 속: 일과 공부를 이어가는 자기 몫";
 6113 |                 return "겉: 자취방 · 속: 생활을 직접 정하는 독립";
 6115 |                 return "겉: 취미 · 속: 쉬고 좋아하는 것까지 있는 사람";
 6126 |             SelectFirstInteractable(firstImpressionObject, "First Impression 목발", "First Impression 책상", "First Impression 표정");
 6131 |                 ? "이제 방금 들은 이야기에서 더 묻고 싶은 장면을 고르세요. 정답이 아니라 질문의 출발점입니다. 고른 장면은 질문 노트 첫 장에 남습니다."
 6132 |                 : "이제 방금 들은 이야기에서 더 묻고 싶은 장면을 고르세요. 겉으로 보인 단서를 고르면, 연결된 생활 장면에서 질문을 시작합니다.";
 6137 |         if (statusText != null) statusText.text = "첫인상 선택";
 6142 |         firstImpression = string.IsNullOrWhiteSpace(value) ? "목발" : value.Trim();
 6146 |         PresentAssistant(line, "첫 인상");
 6147 |         AppendMessage("첫 인상", $"{firstImpression}을 먼저 보았습니다.", "#92400e");
 6148 |         lastEvidenceLine = $"처음 본 것: {firstImpression}. 이후 대화에서 그 장면이 생활과 어떻게 이어지는지 확인합니다. {BuildFirstImpressionArcLine()}";
 6149 |         UpdateLeadPrompts("첫 인상에서 이어지는 질문입니다.", BuildFirstImpressionQuestions(firstImpression));
 6157 |         if (statusText != null) statusText.text = $"처음 본 것: {firstImpression}";
 6163 |         if (string.Equals(value, "목발", StringComparison.Ordinal))
 6165 |             return "목발이 먼저 궁금하다면 자연스러운 시작이에요. 이제 그 장면을 지우지 않고, 이동을 준비하는 방식과 도움이 필요한 순간을 어떻게 조율하는지부터 물어볼 수 있습니다.";
 6167 |         if (string.Equals(value, "책상", StringComparison.Ordinal))
 6169 |             return "책상이 먼저 궁금하다면 일과 공부, 정리하는 시간이 먼저 들어온 셈이에요. 이제 직장 일과 박사과정, 그 안에 놓인 이동과 쉬는 시간을 이어서 물어볼 수 있습니다.";
 6171 |         if (string.Equals(value, "표정", StringComparison.Ordinal))
 6173 |             return "표정이 먼저 궁금하다면 사람을 먼저 본 거예요. 이제 그 표정 뒤에 있는 평범한 하루, 일과 이동과 취미가 어떻게 같은 사람 안에 놓이는지 물어볼 수 있습니다.";
 6175 |         return "방금 들은 이야기에서 궁금한 장면을 붙잡고, 그 시선이 어떤 생활로 이어지는지 질문해 보겠습니다.";
 6180 |         if (string.Equals(value, "목발", StringComparison.Ordinal)) return "목발\n이동과 도움 묻기";
 6181 |         if (string.Equals(value, "책상", StringComparison.Ordinal)) return "책상\n일과 공부 묻기";
 6182 |         if (string.Equals(value, "표정", StringComparison.Ordinal)) return "표정\n평범한 하루 묻기";
 6188 |         if (string.Equals(value, "목발", StringComparison.Ordinal)) return "이동";
 6189 |         if (string.Equals(value, "책상", StringComparison.Ordinal)) return "일과 공부";
 6190 |         if (string.Equals(value, "표정", StringComparison.Ordinal)) return "일상";
 6214 |         if (string.Equals(value, "목발", StringComparison.Ordinal))
 6218 |                 "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?",
 6219 |                 "목발을 보고 들어온 관람객이 나갈 때는 무엇을 함께 기억하면 좋을까요?",
 6220 |                 "도움을 주기 전에 어떤 말로 먼저 물어보는 게 편한가요?"
 6223 |         if (string.Equals(value, "책상", StringComparison.Ordinal))
 6227 |                 "책상 앞에서 직장 일과 박사과정 공부는 어떻게 이어지나요?",
 6228 |                 "노트북과 메모는 이동 이야기 너머의 어떤 생활을 보여주나요?",
 6229 |                 "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?"
 6234 |             "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?",
 6235 |             "도움을 받을 때 설명할 시간이 필요하다는 말은 어떤 뜻인가요?",
 6236 |             "게임과 코인노래방 같은 취미가 전시에서 빠지면 무엇을 놓치게 되나요?"
 6249 |         if (string.Equals(firstImpression, "목발", StringComparison.Ordinal))
 6251 |             return "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?";
 6253 |         if (string.Equals(firstImpression, "책상", StringComparison.Ordinal))
 6255 |             return "책상 앞에서 직장 일과 박사과정 공부는 어떻게 이어지나요?";
 6257 |         if (string.Equals(firstImpression, "표정", StringComparison.Ordinal))
 6259 |             return "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?";
 6262 |         return $"처음 본 {firstImpression}이 {theme} 생활과 어떻게 이어지나요?";
 6275 |             statusText.text = pendingFreshStartStoryMode ? "이야기 모드 시작 확인" : "처음부터 확인";
 6304 |             if (label != null) label.text = "이어하기";
 6359 |             startSavePreviewText.text = hasSave ? BuildStartSavePreview(state) : "오늘의 흐름 · 시작";
 6389 |         string progress = questions >= 5 ? "마무리 가능" : $"질문 {questions}/5";
 6393 |             ? $"지난 대화 · {progress} · 기억장 {scenes}/6"
 6394 |             : $"지난 대화 · {progress} · 기억장 {scenes}/6 · {lastScene}";
 6413 |         statusText.text = serverStatusKnown ? "서버 연결 필요" : "서버 확인 중";
 6414 |         PresentAssistant($"서버가 정상 연결되지 않아 실행할 수 없습니다.\n\n{detail}", "서버 연결 필요");
 6431 |             ? (ready ? "서버 연결됨" : ServerRequiredBlockedText)
 6519 |             speaker = speakerText != null ? speakerText.text : "답변",
 6536 |         string[] seededThemes = { "이동", "도움", "일과 공부" };
 6543 |                 seededNotes[themeIndex] = BuildMemoryNote($"{seededThemes[i]}에 대해 이어 묻던 중입니다.", string.Empty);
 6551 |                 new ChatMessage { role = "user", content = "처음 가는 곳에서는 무엇부터 확인하나요?" },
 6552 |                 new ChatMessage { role = "assistant", content = "처음 가는 곳에서는 입구, 엘리베이터, 화장실 위치처럼 하루를 덜 무리하게 만드는 정보를 먼저 확인하게 됩니다." },
 6553 |                 new ChatMessage { role = "user", content = "도움을 받을 때는 어떤 방식이 편한가요?" },
 6554 |                 new ChatMessage { role = "assistant", content = "무엇이 필요한지 먼저 물어보고, 당사자가 정한 방식에 맞춰 주는 도움이 편합니다." }
 6561 |                 "직장에서는 어떤 도움 방식이 편했나요?",
 6562 |                 "공부와 일을 이어갈 때 책상은 어떤 의미였나요?",
 6563 |                 "자취방이 독립에 어떤 영향을 줬나요?"
 6565 |             lastTheme = "일과 공부",
 6566 |             lastEvidenceLine = "직장과 공부 이야기는 도움을 받는 장면을 넘어, 자기 몫을 이어가는 장면으로 남습니다.",
 6567 |             firstImpression = "목발",
 6569 |             lastQuestionAttitude = "호기심",
 6570 |             lastChoiceConsequenceLine = "선택 기록: 호기심 질문 -> 일과 공부 깊은 기록 · 질문과 단서가 맞물렸습니다.",
 6571 |             leadIntro = "지난 대화에서 이어갈 질문입니다.",
 6572 |             speaker = "지난 답변",
 6573 |             dialogue = "저장된 대화에서는 이동, 도움, 일과 공부 이야기를 이어가던 중입니다.",
 6574 |             log = "나: 처음 가는 곳에서는 무엇부터 확인하나요?\n상대: 입구, 엘리베이터, 화장실 위치처럼 하루를 덜 무리하게 만드는 정보를 먼저 확인하게 됩니다.\n\n나: 도움을 받을 때는 어떤 방식이 편한가요?\n상대: 무엇이 필요한지 먼저 물어보고, 당사자가 정한 방식에 맞춰 주는 도움이 편합니다.",
 6640 |         lastTheme = string.IsNullOrWhiteSpace(state.lastTheme) ? "시작" : state.lastTheme;
 6641 |         lastEvidenceLine = string.IsNullOrWhiteSpace(state.lastEvidenceLine) ? "아직 표시할 자료가 없습니다." : state.lastEvidenceLine;
 6642 |         lastAnswerSource = string.IsNullOrWhiteSpace(state.lastAnswerSource) ? "대기" : state.lastAnswerSource;
 6665 |         PresentAssistant(string.IsNullOrWhiteSpace(state.dialogue) ? OpeningText : state.dialogue, string.IsNullOrWhiteSpace(state.speaker) ? "답변" : state.speaker);
 6666 |         UpdateLeadPrompts(string.IsNullOrWhiteSpace(state.leadIntro) ? $"{lastTheme}에서 이어갈 질문입니다." : state.leadIntro);
 6701 |         lastTheme = "시작";
 6702 |         lastEvidenceLine = "아직 표시할 자료가 없습니다.";
 6703 |         lastAnswerSource = "대기";
 6737 |         PresentAssistant(OpeningText, "오늘의 시작");
 6738 |         UpdateLeadPrompts("제가 먼저 이런 순서로 이야기를 열어볼게요.");
 6745 |         statusText.text = "처음부터 다시 시작";
 6771 |         if (statusText != null) statusText.text = "이야기 모드 진행 중 · 직접 질문하거나 Esc로 멈춤";
 6779 |             string theme = i < storyModeThemes.Length ? storyModeThemes[i] : "일상";
 6787 |             AppendMessage("이야기", line, "#0f766e");
 6790 |             lastEvidenceLine = $"{theme} 장면을 이야기 모드로 들었습니다. {currentStoryModeBeatLine} · {currentStoryModePaceLine}";
 6793 |             PresentAssistant(line, i == 0 ? "이야기 모드" : "이어지는 이야기");
 6794 |             CollectTheme(theme, "이야기 모드", line);
 6795 |             ShowSceneFocus(GetSceneFocusLabelForTheme(theme), GetSceneFocusPositionForTheme(theme), "이야기 장면", 2.2f);
 6806 |                 statusText.text = $"이야기 모드 {Mathf.Min(i + 1, storyModeLines.Length)}/{storyModeLines.Length} · {currentStoryModeBeatLine}";
 6812 |                 if (statusText != null) statusText.text = $"잠시 장면을 남기는 중 · {BuildStoryModeQuietMomentLine(i)}";
 6828 |         if (statusText != null) statusText.text = "이야기 모드 완료 · 마무리 가능";
 6870 |         string outer = index >= 0 && index < storyModeOuterCues.Length ? storyModeOuterCues[index] : "겉 장면";
 6871 |         string inner = index >= 0 && index < storyModeInnerCues.Length ? storyModeInnerCues[index] : "속 이야기";
 6872 |         return $"겉: {outer} · 속: {inner}";
 6877 |         string cue = index >= 0 && index < storyModePaceCues.Length ? storyModePaceCues[index] : "짧은 정적 0.8초 · 방 톤 유지 · 장면 단서에 시선 이동";
 6878 |         return $"연출: {cue}";
 6883 |         string cue = index >= 0 && index < storyModeOuterCues.Length ? storyModeOuterCues[index] : "장면";
 6884 |         return $"{cue} 장면을 남깁니다";
 6922 |             statusText.text = "다음 장면으로 넘깁니다";
 6936 |             firstImpression = "이야기 보기";
 6937 |             lastEvidenceLine = "도입 이야기를 먼저 듣고 직접 질문으로 넘어갔습니다.";
 6938 |             UpdateLeadPrompts("방금 들은 이야기에서 바로 물어볼 수 있습니다.", new[]
 6940 |                 "목발보다 먼저 있는 하루는 어떤 모습인가요?",
 6941 |                 "처음 가는 곳에서는 무엇부터 확인하나요?",
 6942 |                 "책상과 노트북은 어떤 의미인가요?"
 6945 |         StopStoryMode("직접 질문으로 이어갑니다");
 6994 |             if (label != null) label.text = "직접 질문";
 7005 |             if (label != null) label.text = canFinish ? "마무리" : "5문답 후";
 7019 |             return openingStoryModeActive ? "첫인상 고르기" : "마무리로";
 7023 |         return $"다음 {next}/{total}";
 7043 |         ShowSceneFocus(GetSceneFocusLabelForTheme(theme), focus, index == 0 ? "첫 장면" : "다음 장면", 2.6f);
 7059 |             StopStoryMode("이야기 모드를 멈췄습니다");
 7111 |             statusText.text = "마무리 카드를 닫았습니다";
 7118 |             statusText.text = "기억장을 닫았습니다";
 7125 |             statusText.text = "질문 노트를 닫았습니다";
 7306 |                 statusText.text = "5문답 후 마무리할 수 있습니다";
 7904 |             statusText.text = "일시정지";
 7924 |             statusText.text = "정보";
 7937 |                 statusText.text = "설정";
 7952 |             ? "서버 연결됨 · API 답변 사용"
 7968 |             serverStatusText.text = "로컬 서버 확인 중...";
 7998 |                     message = $"서버 연결됨 · API 답변 사용 · {FormatServerModel(config.chatModel)}";
 8004 |                         ? "채팅 모델 준비 안 됨"
 8006 |                     message = $"서버 연결됨 · {detail} · 시작할 수 없습니다.";
 8010 |                     message = "서버 연결됨 · API 키 없음 · 시작할 수 없습니다.";
 8017 |                     : $"서버 연결 실패 · {ShortenForCard(request.error, 72)}";
 8038 |             SelectFirstInteractable(settingsMenuObject, "Settings Text Size 기본", "Fullscreen Toggle Button", "Close Settings Button");
 8039 |             statusText.text = "설정";
 8066 |             statusText.text = dialogueSizeLevel > 0 ? "큰 글자" : (dialogueSizeLevel < 0 ? "작은 글자" : "기본 글자");
 8125 |             statusText.text = fullscreenEnabled ? "전체 화면" : "창 모드";
 8188 |             statusText.text = reducedMotionEnabled ? "움직임 줄임" : "움직임 기본";
 8205 |             statusText.text = highContrastEnabled ? "읽기 쉬운 화면 켜짐" : "읽기 쉬운 화면 꺼짐";
 8281 |             statusText.text = "서버 답변 필수";
 8332 |             statusText.text = "기록 폴더를 열었습니다";
 8336 |             statusText.text = "기록 폴더를 열 수 없습니다";
 8350 |         statusText.text = "저장 데이터와 기록이 완전히 지워집니다";
 8382 |                 ? $"저장 데이터와 기록 {deletedCount}개를 삭제했습니다"
 8383 |                 : "저장 데이터를 삭제했습니다";
 8389 |             statusText.text = "저장 데이터를 삭제할 수 없습니다";
 8438 |         if (label != null) label.text = confirming ? "삭제 확정" : "저장 삭제";
 8447 |                 ? "저장 데이터와 기록이 완전히 지워집니다. 삭제 확정으로 진행하세요."
 8448 |                 : "저장 삭제는 확인 후 실행됩니다.";
 8493 |         statusText.text = "기록함";
 8512 |         if (playtestFeedbackStatusText != null) playtestFeedbackStatusText.text = "이 컴퓨터에만 저장되는 메모입니다.";
 8519 |         statusText.text = "의견 남기기";
 8609 |             playtestFeedbackEvidenceText.text = "저장 가능: 5문답 완료 · 마무리 기록 저장 · 세션 정보 저장";
 8614 |             playtestFeedbackEvidenceText.text = "마무리 기록 대기: 좋은 평가는 기록 저장 뒤 남겨 주세요";
 8619 |             playtestFeedbackEvidenceText.text = $"완주 대기: 5문답 {turns}/5 · 좋은 평가는 완료 후 저장";
 8624 |             playtestFeedbackEvidenceText.text = "수정 메모 필요: 더 다듬기/조금 아쉬움/문제 있음 · 짧게 남겨 주세요";
 8629 |             playtestFeedbackEvidenceText.text = $"저장 전 확인: 5문답 {turns}/5 · 완성도 느낌과 문제 단계 저장";
 8644 |         string turnState = completed ? "문답 5/5 완료" : $"문답 {turns}/5 진행";
 8645 |         string recordState = HasSavedEndingRecordThisSession() ? "마무리 기록 저장" : "마무리 기록 전";
 8646 |         string selectionState = positive ? "좋은 평가 선택" : "수정 의견 저장 가능";
 8810 |                     playtestFeedbackStatusText.text = "좋음, 충분함, 문제 없음은 5문답을 마친 뒤 저장해 주세요. 중간에 생긴 문제는 단계와 메모로 남길 수 있습니다.";
 8812 |                 statusText.text = "5문답 완료 필요";
 8820 |                     playtestFeedbackStatusText.text = "좋음, 충분함, 문제 없음은 마무리 기록을 저장한 뒤 남길 수 있습니다.";
 8822 |                 statusText.text = "마무리 기록 필요";
 8830 |                     playtestFeedbackStatusText.text = "더 다듬기, 조금 아쉬움, 문제 있음을 골랐다면 어디가 걸렸는지 짧게 남겨 주세요.";
 8832 |                 statusText.text = "의견 메모 필요";
 8847 |             if (playtestFeedbackStatusText != null) playtestFeedbackStatusText.text = "의견과 세션 정보를 이 컴퓨터에 저장했습니다.";
 8850 |             statusText.text = "의견 저장됨";
 8854 |             if (playtestFeedbackStatusText != null) playtestFeedbackStatusText.text = "의견 저장에 실패했습니다.";
 8855 |             statusText.text = "의견 저장 실패";
 8867 |             statusText.text = "의견 폴더를 열었습니다";
 8871 |             statusText.text = "의견 폴더를 열 수 없습니다";
 8910 |                 ? "최근 기록"
 8937 |                 recordArchivePreviewHeaderText.text = "저장된 마무리 기록 없음";
 8940 |             recordArchivePreviewText.text = "아직 저장된 마무리 기록이 없습니다.\n\n다섯 번의 대화 뒤 남길 문장을 고르고 저장하면 이곳에 남습니다.";
 8952 |         if (totalCount <= 0) return "최근 기록";
 8953 |         if (totalCount <= visibleCount) return $"최근 기록 {visibleCount}개";
 8954 |         return $"최근 {visibleCount}개 기록";
 8975 |             recordArchivePreviewText.text = $"기록을 읽을 수 없습니다.\n{ex.Message}";
 8978 |                 recordArchivePreviewHeaderText.text = "기록을 읽을 수 없음";
 8993 |             statusText.text = "삭제할 기록이 없습니다";
 9006 |         statusText.text = "한 번 더 누르면 선택한 기록이 삭제됩니다";
 9024 |             statusText.text = "선택한 기록을 삭제했습니다";
 9029 |             statusText.text = "기록을 삭제할 수 없습니다";
 9054 |         statusText.text = "기록 삭제를 취소했습니다";
 9072 |             label.text = awaitingConfirm ? "삭제 확정" : "선택 삭제";
 9097 |                     ? "저장한 마무리 기록이 아직 없습니다."
 9098 |                     : "삭제할 기록을 먼저 선택하세요.";
 9104 |                 recordArchiveDeleteHintText.text = "기록이 완전히 지워집니다. 계속하려면 삭제 확정을 누르세요.";
 9110 |                 recordArchiveDeleteHintText.text = "선택 삭제는 한 번 더 확인한 뒤 실행됩니다.";
 9179 |         string dateLabel = string.IsNullOrWhiteSpace(name) ? "마무리 기록" : name;
 9197 |             string turns = ExtractRecordField(lines, "문답 수:");
 9198 |             string scenes = ExtractRecordField(lines, "열린 장면:");
 9203 |                 parts.Add($"{turns.Trim()}문답");
 9207 |                 parts.Add($"장면 {scenes.Trim()}");
 9238 |                 if (lines[i].Trim() != "오늘 남길 문장") continue;
 9285 |             if (label != null) label.text = fullscreenEnabled ? "창 모드로 전환" : "전체 화면으로 전환";
 9302 |             if (label != null) label.text = reducedMotionEnabled ? "움직임 줄임 켜짐" : "움직임 줄임 꺼짐";
 9312 |             if (label != null) label.text = highContrastEnabled ? "읽기 쉬움 켜짐" : "읽기 쉬움 꺼짐";
 9322 |             if (label != null) label.text = serverReady ? "서버 정상" : "서버 확인";
 9374 |         ApplyTextStyle(placeholder, "질문을 입력하세요", 18, new Color32(71, 85, 105, 172), TextAnchor.MiddleLeft, FontStyle.Normal);
 9411 |         ApplyTextStyle(placeholder, "예: 질문 흐름은 좋았지만 기록 저장 전 안내가 더 필요했습니다.", 16, new Color32(100, 116, 139, 255), TextAnchor.UpperLeft, FontStyle.Normal);
 9533 |         Text action = CreateText("Action Label", root, "추천 질문 · 누르면 바로 질문", 11, new Color32(255, 218, 154, 218), TextAnchor.MiddleLeft, FontStyle.Bold);
10279 |             case "일상":
10280 |                 question = "평범한 하루에서 어떤 장면이 먼저 떠오르나요?";
10282 |             case "이동":
10283 |             question = "처음 가는 곳에서는 무엇부터 확인하나요?";
10285 |             case "도움":
10286 |                 question = "도움을 건네고 싶을 때 어떤 방식이 가장 편한가요?";
10288 |             case "일과 공부":
10289 |                 question = "책상과 노트북은 어떤 의미인가요?";
10291 |             case "독립":
10292 |                 question = "혼자 사는 방은 어떤 의미였나요?";
10294 |             case "취미":
10295 |                 question = "취미 이야기는 왜 같이 중요할까요?";
10307 |         SubmitPresetQuestion("방금 답변에서 생활 장면을 하나 더 들려주세요.");
10321 |             StopStoryMode("이야기 모드를 멈추고 마무리 카드를 엽니다");
10329 |         PresentAssistant(closing, "마무리 카드");
10330 |         AppendMessage("마무리", closing, "#5b21b6");
10336 |         statusText.text = "마무리 카드를 열었습니다";
10342 |         return $"지금까지 나눈 대화를 바탕으로 오늘 남길 문장을 하나 골라 보세요.\n\n{BuildPerspectiveShiftLine()}\n{sceneLine}\n\n이야기가 설명으로 끝나지 않고, 다음에 누군가를 만날 때 떠올릴 문장으로 남으면 좋겠습니다.";
10359 |             return "오늘 대화에서 열린 장면: " + string.Join(", ", compact.ToArray());
10365 |             return $"오늘 대화에서 붙잡은 장면: {theme}";
10368 |         return "오늘 대화에서 붙잡은 장면을 마지막 카드에 남깁니다.";
10386 |             StopStoryMode("직접 질문으로 전환합니다");
10402 |         if (HasAny(text, "필요하죠", "제한", "힘들", "못하", "혼자 할 수", "당연", "극복")) return "단정";
10403 |         if (HasAny(text, "어떻게 도와", "편할까요", "괜찮을까요", "먼저 물", "방식")) return "배려";
10404 |         if (HasAny(text, "무엇", "어떤", "왜", "어떻게", "의미", "궁금", "알고 싶")) return "호기심";
10405 |         return "거리두기";
10411 |         lastQuestionAttitude = string.IsNullOrWhiteSpace(attitude) ? "거리두기" : attitude;
10423 |             content = $"현재 질문 태도 태그: {attitude}. 태그는 내부 기록용입니다. 답변 첫머리에 질문 태도 평가나 고정 도입문을 붙이지 말고, 사용자가 물은 내용에 바로 답하세요."
10441 |             case "목발":
10442 |                 prefix = "목발을 먼저 보셨다면, 그 장면이 이동과 일상, 도움을 조율하는 방식으로 어떻게 이어지는지부터 볼게요.";
10444 |             case "책상":
10445 |                 prefix = "책상을 먼저 보셨다면, 일과 공부의 장면에서 출발해 그 안에 놓인 이동과 도움까지 이어볼게요.";
10447 |             case "표정":
10448 |                 prefix = "표정을 먼저 보셨다면, 그 분위기와 같은 하루 안에 있는 생활부터 말해볼게요.";
10480 |         AppendMessage("나", question, "#334155");
10487 |         PresentAssistant(ThinkingReplyText, "생각 중");
10488 |         ShowSceneFocus("질문", new Vector2(-28f, -306f), "책상에 남김", 1.5f);
10518 |             error = "서버 답변이 비어 있음";
10529 |             lastServerError = error ?? "서버 답변을 받을 수 없습니다.";
10530 |             SetServerAvailability(false, true, $"서버 연결 실패 · {ShortenForCard(lastServerError, 60)}");
10532 |             PresentAssistant($"서버가 정상 연결되지 않아 답변을 만들 수 없습니다.\n\n{ShortenForCard(lastServerError, 90)}\n서버를 켠 뒤 다시 시도해 주세요.", "서버 연결 필요");
10542 |             statusText.text = "서버 연결 필요 · 대화 중단";
10546 |         SetServerAvailability(true, true, "서버 연결됨 · API 답변 사용");
10553 |             reply = "서버 답변이 비어 있습니다. 서버 상태를 확인한 뒤 다시 시도해 주세요.";
10560 |         AppendMessage("답변", reply, "#0f766e");
10563 |         PresentAssistant(reply, "답변");
10578 |         statusText.text = conversationTurns >= 5 ? "마무리 카드를 열 수 있습니다" : "이어갈 수 있습니다";
10593 |             statusText.text = "서버 답변 필수 모드입니다.";
10610 |             statusText.text = "사용 가능한 마이크를 찾지 못했습니다.";
10621 |         PresentAssistant("말씀을 듣고 있어요. 끝나면 정지를 누르면 됩니다.", "음성 입력");
10634 |             statusText.text = "녹음 데이터가 없습니다.";
10653 |             statusText.text = "서버 답변 필수 모드입니다.";
10677 |         PresentAssistant("음성을 텍스트로 바꾸는 중입니다.", "전사 중");
10678 |         statusText.text = "음성을 텍스트로 바꾸는 중...";
10712 |             statusText.text = string.IsNullOrEmpty(error) ? "전사 결과가 비어 있습니다." : $"전사 실패: {error}";
11064 |         string[] sentences = Regex.Split(paragraph, @"(?<=[.!?。！？]|[요다까죠요니다습니다])\s+");
11160 |                 dialoguePageCueText.text = $"대사가 더 있어요  |  클릭해서 다음 대사 보기 {dialoguePageIndex + 2}/{dialoguePages.Count}";
11167 |                 dialoguePageCueText.text = openingStoryModeActive ? "다음 이야기 보기" : "다음 장면 보기";
11250 |             case "배려":
11251 |             case "호기심":
11252 |                 return "깊은 기록";
11253 |             case "단정":
11254 |                 return "되묻기";
11256 |                 return "얕은 기록";
11262 |         if (HasAny(question, "평범", "하루")) return "평범한 하루";
11263 |         if (HasAny(question, "끈기", "흘러간다", "버틴", "조정")) return "끈기";
11264 |         if (HasAny(question, "지원 서비스", "교통 정보", "전동휠체어")) return "이동 지원";
11265 |         if (HasAny(question, "처음", "공간", "곳", "엘리베이터", "화장실")) return "처음 가는 곳";
11266 |         if (HasAny(question, "설명할 시간", "혼자 할 수", "도움", "배려")) return "도움 받는 방식";
11267 |         if (HasAny(question, "책상", "노트북", "컴퓨터", "메모")) return "책상과 노트북";
11268 |         if (HasAny(question, "자취", "독립", "집")) return "자취방";
11269 |         if (HasAny(question, "취미", "게임", "노래방")) return "취미";
11270 |         if (HasAny(question, "목발", "이동")) return "이동과 목발";
11271 |         if (HasAny(question, "직장", "회사", "박사", "공부", "기여", "결과물")) return "일과 공부";
11272 |         if (HasAny(question, "한국", "미국")) return "이동 환경";
11273 |         if (HasAny(question, "생활", "장면")) return "생활 장면";
11284 |         if (string.IsNullOrWhiteSpace(clean)) return "무엇을 더 물어볼까요?";
11285 |         if (!clean.EndsWith("?", StringComparison.Ordinal) && !clean.EndsWith("요?", StringComparison.Ordinal))
11308 |             return "여섯 장면을 다 열었습니다. 더 듣고 싶은 장면을 골라도 됩니다.";
11311 |         return $"남은 장면 {remaining}개를 열 수 있는 질문입니다.";
11344 |         if (HasAny(text, "처음", "장소", "동선", "엘리베이터", "화장실", "계단", "접근성", "교통"))
11346 |             AddUniqueLeadQuestion(result, "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?", 3);
11347 |             AddUniqueLeadQuestion(result, "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?", 3);
11348 |             AddUniqueLeadQuestion(result, "책상과 노트북은 이동 이야기 너머의 어떤 생활을 보여주나요?", 3);
11349 |             AddUniqueLeadQuestion(result, "엘리베이터나 화장실 정보가 하루의 피로와 어떻게 연결되나요?", 3);
11351 |         if (HasAny(text, "도움", "도와", "배려", "불편", "넘어", "민폐"))
11353 |             AddUniqueLeadQuestion(result, "도움을 건네기 전에 어떤 말로 먼저 물어보는 게 편한가요?", 3);
11354 |             AddUniqueLeadQuestion(result, "도움을 받을 때 설명할 시간이 필요하다는 말은 어떤 뜻인가요?", 3);
11355 |             AddUniqueLeadQuestion(result, "혼자 할 수 있는 부분을 존중하는 도움은 어떤 모습인가요?", 3);
11356 |             AddUniqueLeadQuestion(result, "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?", 3);
11358 |         if (HasAny(text, "자취", "독립", "자기이해", "생활비", "집안일", "공과금"))
11360 |             AddUniqueLeadQuestion(result, "자취방에서는 혼자 생활하며 어떤 일을 직접 정하게 되었나요?", 3);
11361 |             AddUniqueLeadQuestion(result, "자취를 시작한 뒤 스스로 설명해야 하는 일이 어떻게 달라졌나요?", 3);
11362 |             AddUniqueLeadQuestion(result, "독립은 큰 결심보다 어떤 반복되는 일에서 느껴졌나요?", 3);
11363 |             AddUniqueLeadQuestion(result, "자취방은 장애를 설명하는 공간이 아니라 어떤 생활을 보여주나요?", 3);
11365 |         if (HasAny(text, "직장", "회사", "박사", "공부", "책상", "노트북", "자격증", "프로젝트"))
11367 |             AddUniqueLeadQuestion(result, "책상 앞 시간은 직장 일과 박사과정 공부를 어떻게 이어주나요?", 3);
11368 |             AddUniqueLeadQuestion(result, "어떤 업무 장면에서 기여를 느끼나요?", 3);
11369 |             AddUniqueLeadQuestion(result, "함께 일하는 사람이 상황을 모를 때 무엇부터 말해 주는 편인가요?", 3);
11370 |             AddUniqueLeadQuestion(result, "노트북과 메모는 이동 이야기 너머의 어떤 생활을 보여주나요?", 3);
11372 |         if (HasAny(text, "취미", "게임", "노래방", "코인노래방", "쉬는", "좋아"))
11374 |             AddUniqueLeadQuestion(result, "게임과 코인노래방 같은 취미가 전시에서 빠지면 무엇을 놓치게 되나요?", 3);
11375 |             AddUniqueLeadQuestion(result, "쉬는 시간이 함께 보여야 한 사람의 하루가 더 정확해지는 이유는 무엇인가요?", 3);
11376 |             AddUniqueLeadQuestion(result, "게임과 코인노래방 이야기는 이동이나 도움 이야기와 어떻게 다른 면을 보여주나요?", 3);
11377 |             AddUniqueLeadQuestion(result, "책상과 노트북은 직장 일과 박사과정 공부를 어떻게 보여주나요?", 3);
11379 |         if (HasAny(text, "목발", "장애", "평범", "사람", "오해", "선입견"))
11381 |             AddUniqueLeadQuestion(result, "목발을 보고 들어온 관람객이 나갈 때는 무엇을 함께 기억하면 좋을까요?", 3);
11382 |             AddUniqueLeadQuestion(result, "책상과 노트북은 목발 너머의 일과 공부를 어떻게 보여주나요?", 3);
11383 |             AddUniqueLeadQuestion(result, "전시에서 자취방과 책상이 함께 보여야 하는 이유는 무엇인가요?", 3);
11384 |             AddUniqueLeadQuestion(result, "장애를 한 사람의 전부로 보지 않으려면 어떤 질문을 해야 할까요?", 3);
11386 |         if (HasAny(text, "미국", "한국", "장애인택시", "지원", "전동휠체어", "대중교통"))
11388 |             AddUniqueLeadQuestion(result, "미국과 한국의 이동 환경은 실제 생활에서 어떻게 다르게 느껴졌나요?", 3);
11389 |             AddUniqueLeadQuestion(result, "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?", 3);
11390 |             AddUniqueLeadQuestion(result, "처음 가는 공간에서 접근성을 확인하는 일이 왜 중요한가요?", 3);
11392 |         if (HasAny(text, "끈기", "어떻게든", "흘러간다", "버틴", "조정", "다음 단계"))
11394 |             AddUniqueLeadQuestion(result, "끈기라는 말은 대단한 극복담보다 어떤 태도에 가까운가요?", 3);
11395 |             AddUniqueLeadQuestion(result, "어떻게든 흘러간다는 말은 하루를 이어가는 방식과 어떻게 닿아 있나요?", 3);
11396 |             AddUniqueLeadQuestion(result, "버틴다는 말보다 조정하며 이어간다는 표현이 더 맞는 이유는 무엇인가요?", 3);
11467 |         if (HasAny(text, "직장", "동료", "필요한 도움", "함께 일", "기여", "결과물", "프로젝트", "기획서")) return "workplace";
11468 |         if (HasAny(text, "설명할 시간", "혼자 할 수", "도움", "도와", "배려", "기다리")) return "help";
11469 |         if (HasAny(text, "처음", "장소", "공간", "동선", "엘리베이터", "화장실", "교통", "지원", "미국", "한국", "접근성")) return "accessibility";
11470 |         if (HasAny(text, "자취", "독립", "집안일", "생활을 직접", "스스로 설명")) return "room";
11471 |         if (HasAny(text, "책상", "노트북", "메모", "박사", "공부")) return "desk";
11472 |         if (HasAny(text, "취미", "게임", "노래방", "쉬는 시간", "여가")) return "hobby";
11473 |         if (HasAny(text, "평범", "전시", "장애를 한 사람", "겉", "기억", "관람객", "목발을 보고")) return "ordinary";
11474 |         if (HasAny(text, "끈기", "흘러간다", "버틴", "조정", "다음 단계")) return "motto";
11475 |         if (HasAny(text, "목발", "이동")) return "crutch";
11492 |             "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?",
11493 |             "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
11494 |             "도움을 받을 때 설명할 시간이 필요하다는 말은 어떤 뜻인가요?",
11495 |             "노트북과 메모는 이동 이야기 너머의 어떤 생활을 보여주나요?",
11496 |             "게임과 코인노래방 같은 취미가 전시에서 빠지면 무엇을 놓치게 되나요?",
11497 |             "전시에서 자취방과 책상이 함께 보여야 하는 이유는 무엇인가요?",
11498 |             "끈기라는 말은 대단한 극복담보다 어떤 태도에 가까운가요?"
11513 |             "목발을 보고 들어온 관람객이 나갈 때는 무엇을 함께 기억하면 좋을까요?",
11514 |             "자취방은 장애를 설명하는 공간이 아니라 어떤 생활을 보여주나요?",
11515 |             "장애를 한 사람의 전부로 보지 않으려면 어떤 질문을 해야 할까요?"
11526 |             result.Add($"아직 묻지 않은 생활 장면 {index}은 어떤 질문으로 열어볼까요?");
11581 |         if (!text.EndsWith("?", StringComparison.Ordinal) && !text.EndsWith("요?", StringComparison.Ordinal))
11605 |         string personBook = "사람" + "책";
11606 |         string virtualWord = "가상";
11608 |         string artificialMind = "인공" + "지능";
11609 |         text = Regex.Replace(text, @"^\s*저는\s*실제\s*사람이\s*아니라\s*(인터뷰\s*기반\s*)?(" + virtualWord + @"\s*)?(" + personBook + @"|책)(입니다|이에요)?[.。]?\s*", string.Empty, RegexOptions.IgnoreCase);
11610 |         text = Regex.Replace(text, @"^\s*저는\s*(실제\s*)?(사람|당사자|인터뷰\s*대상자)?(가|이)?\s*아니라[,\s]*(인터뷰\s*기반\s*)?(" + virtualWord + @"\s*)?(" + aiToken + @"|" + artificialMind + @"|" + personBook + @"|책)(입니다|이에요)?[.。]?\s*", string.Empty, RegexOptions.IgnoreCase);
11611 |         text = Regex.Replace(text, @"^\s*저는\s*(인터뷰\s*기반\s*)?" + virtualWord + @"\s*책(입니다|이에요)?[.。]?\s*", string.Empty, RegexOptions.IgnoreCase);
11612 |         text = Regex.Replace(text, @"^\s*실제\s*대상자1\s*본인은\s*아니지만[,\s]*", string.Empty, RegexOptions.IgnoreCase);
11613 |         text = Regex.Replace(text, @"^\s*인터뷰\s*기반\s*" + virtualWord + @"\s*" + personBook + @"으로서[,\s]*", string.Empty, RegexOptions.IgnoreCase);
11615 |         text = Regex.Replace(text, @"^\s*(좋아요|좋습니다|물론이죠|잠깐만요|잠시만요|잠깐|네)[,.，\s]+", string.Empty, RegexOptions.IgnoreCase);
11633 |         string personBook = "사람" + "책";
11634 |         string virtualWord = "가상";
11636 |         string artificialMind = "인공" + "지능";
11637 |         string programWord = "프로" + "그램";
11641 |             lineStart + sentenceBody + @"(?:인터뷰\s*대상자|대상자|당사자|본인)" + sentenceBody + @"(?:아니|아닙|아니에|대신)" + sentenceBody + sentenceEnd + @"\s*",
11642 |             lineStart + sentenceBody + @"(?:실제\s*사람|실제\s*인물)" + sentenceBody + @"(?:아니|아닙|아니에|재현|초상|신원)" + sentenceBody + sentenceEnd + @"\s*",
11643 |             lineStart + sentenceBody + @"(?:" + aiToken + @"|" + artificialMind + @"|" + virtualWord + @"\s*(?:" + personBook + @"|캐릭터|책)|" + programWord + @")" + sentenceBody + sentenceEnd + @"\s*"
11667 |             micButtonLabel.text = recording ? "정지" : "녹음";
11728 |             if (label != null) label.text = "전송";
11771 |             if (label != null) label.text = GetCompletionActionLabel("마무리");
11777 |             if (label != null) label.text = GetCompletionActionLabel("끝내기");
11794 |         if (conversationTurns <= 0) return "대화 후";
11795 |         return IsCompletedFiveTurnSession() ? readyLabel : "5문답 후";
11824 |             string progressLabel = progress >= 5 ? "마무리 가능" : $"{progress}/5 질문";
11844 |             return "서버 필수 모드입니다. 서버가 정상일 때만 답변합니다.";
11849 |             string reason = string.IsNullOrWhiteSpace(serverError) ? "서버 답변을 받을 수 없었습니다." : $"서버 응답 문제: {serverError}";
11850 |             return $"{reason}\n서버가 정상일 때만 답변을 진행합니다.";
11855 |             string reason = string.IsNullOrWhiteSpace(serverError) ? "서버 답변을 받을 수 없었습니다." : $"서버 응답 문제: {serverError}";
11856 |             return $"{reason}\n서버가 정상일 때만 답변을 진행합니다.";
11861 |             return "현재 질문과 가장 가까운 인터뷰 정리 자료를 바탕으로 답했습니다. 서버 자료 목록이 없으면 내장 답변 기준으로 표시됩니다.";
11865 |         builder.Append("다음 자료를 기준으로 정리했습니다.");
11873 |             builder.Append("\n\n장면 카드: ").Append(response.cardId);
11884 |                 return "서버 답변";
11886 |                 return "서버 필수";
11889 |                     ? "서버 연결 필요"
11890 |                     : $"서버 연결 필요 ({ShortenForCard(lastServerError, 28)})";
11893 |                     ? "서버 연결 필요"
11894 |                     : $"서버 연결 필요 ({ShortenForCard(lastServerError, 28)})";
11896 |                 return "아직 답변 없음";
11902 |         if (localAnswerOnly) return "서버 필수";
11907 |                 return "서버 답변";
11909 |                 return "서버 필수";
11911 |                 return "서버 필요";
11913 |                 return "서버 필요";
11915 |                 return "답변 대기";
11923 |             case "questionnaire": return "질문지";
11924 |             case "interview-stt": return "2026년 5월 1일 인터뷰 전사본";
11925 |             case "group-record": return "조별 활동 기록";
11926 |             case "kakao": return "후속 카카오톡 확인";
11927 |             case "static-chatbot": return "기존 정리 자료";
11928 |             case "course-frame": return "수업 자료의 관점";
11929 |             default: return string.IsNullOrWhiteSpace(id) ? "자료 미상" : id;
11945 |         if (HasAny(text, "취미", "게임", "노래방", "코인노래방", "쉬", "휴식", "주말")) return "취미";
11946 |         if (HasAny(text, "자취", "자취방", "공과금", "생활비", "집안일", "독립")) return "독립";
11947 |         if (HasAny(text, "직장", "회사", "박사", "공부", "책상", "노트북", "프로젝트", "소지품", "물건")) return "일과 공부";
11948 |         if (HasAny(text, "도움", "도와", "배려", "민폐", "넘어", "친구", "관계", "설명")) return "도움";
11949 |         if (HasAny(text, "동선", "처음", "엘리베이터", "화장실", "계단", "접근성", "교통", "미국", "한국", "날씨", "비", "눈", "바닥")) return "이동";
11950 |         if (HasAny(text, "평범", "장애", "극복", "사람")) return "일상";
11958 |         if (HasAny(text, "도움", "도와", "불편", "아프", "넘어", "민폐", "불안", "배려"))
11963 |         if (HasAny(text, "취미", "게임", "노래방", "코인노래방", "쉬는", "휴식", "주말", "좋아"))
11968 |         if (HasAny(text, "동선", "처음", "장소", "엘리베이터", "화장실", "계단", "접근성", "날씨", "비", "바닥", "미국", "한국", "직장", "설명", "프로젝트", "박사", "책상", "노트북", "자격증"))
11973 |         if (HasAny(text, "모르", "자료", "확인", "생각", "자기이해", "독립", "고민", "의미", "전시"))
11983 |         if (HasAny(question, "누구", "소개", "정체", "안녕"))
11985 |             return "목발, 자취방, 책상, 출근길, 도움에 대한 인터뷰 기록을 바탕으로 답하고 있어요. 한 장면으로 끝내기보다, 이동을 준비하는 시간과 자기 생활을 챙기는 시간, 일하고 공부하는 시간을 함께 보려는 대화입니다.";
11988 |         if (HasAny(question, "목발", "이동", "도구", "동반자"))
11990 |             return "목발은 불편함만 보여주는 물건이 아니에요. 밖으로 나가고, 사람을 만나고, 일상으로 이어지는 도구입니다. 하루를 시작할 때마다 몸 상태와 길의 상태를 함께 생각하게 만드는 물건이기도 하고요.\n\n처음엔 목발이 먼저 보일 수 있습니다. 그 다음에는 자취방, 책상, 일, 공부, 취미로 시선이 옮겨가야 해요. 목발은 끝점이 아니라 하루로 들어가는 입구입니다.";
11993 |         if (HasAny(question, "자취", "자취방", "독립", "집"))
11995 |             return "자취방은 내 하루를 내가 챙기는 공간이에요. 집안일, 생활비, 공과금, 시간 관리처럼 평범해 보이는 일들이 모이면서 독립성이 만들어집니다. 대신 해주던 일을 직접 하다 보면, 생활이 생각보다 많은 선택으로 이루어져 있다는 것도 알게 되고요.\n\n그래서 자취방은 장애를 설명하는 장소라기보다 생활의 감각을 보여주는 장소입니다. 직접 정리하고 계산하고 버티는 시간이 쌓이는 곳이에요.";
11998 |         if (HasAny(question, "도움", "도와", "배려", "넘어"))
12000 |             return "도움은 마음만으로 충분하지 않을 때가 있어요. 방법이 맞지 않으면 오히려 불편하거나 아플 수 있습니다. 그래서 좋은 시작은 단순해요. 바로 움직이기 전에 '어떻게 도와드릴까요?'라고 묻는 겁니다.\n\n도움을 받는 쪽에도 설명할 시간이 필요합니다. 어디를 잡아야 하는지, 어느 방향이 편한지, 혼자 할 수 있는 부분은 무엇인지가 다를 수 있으니까요. 좋은 도움은 선의보다 먼저, 상대가 말할 시간을 주는 데서 시작됩니다.";
12003 |         if (HasAny(question, "처음", "장소", "동선", "엘리베이터", "화장실", "접근성", "계단"))
12005 |             return "처음 가는 장소에서는 목적지만 보지 않아요. 엘리베이터가 있는지, 계단이 많은지, 화장실은 어디인지, 덜 무리되는 동선은 어디인지 먼저 보게 됩니다. 약속 장소 하나를 정할 때도 길, 입구, 내부 이동, 돌아오는 길까지 함께 떠올려요.\n\n이건 유난스러운 준비라기보다 하루를 가능하게 만드는 확인입니다. 누군가에게는 지나가는 정보가, 다른 누군가에게는 그날의 피로와 안전을 좌우하는 조건이 됩니다.";
12008 |         if (HasAny(question, "비", "눈", "날씨", "미끄", "바닥", "우산"))
12010 |             return "날씨를 좋아하는지까지는 자료에 남아 있지 않아요. 다만 비가 오거나 바닥이 미끄러운 날에는 동선 확인이 더 중요해집니다. 입구까지의 길, 젖은 바닥, 경사, 목발을 짚는 위치가 하루의 피로와 안전에 바로 이어질 수 있어요.\n\n그래서 날씨 이야기도 결국 이동의 이야기와 닿아 있습니다. 확인된 이야기 안에서는 길과 바닥을 먼저 살피는 습관으로 이어 말할 수 있습니다.";
12013 |         if (HasAny(question, "직장", "회사", "박사", "공부", "책상", "노트북", "업무", "컴퓨터"))
12015 |             return "책상은 한 사람을 도움받는 사람으로만 보지 않게 해주는 장면이에요. 직장생활과 컴퓨터공학 박사과정을 이어가는 시간이 노트북 앞에서 만납니다. 여기서는 누군가의 배려를 기다리는 사람이 아니라, 일을 정리하고 공부를 이어가는 사람이 보입니다.\n\n노트북, 메모, 자료 같은 것들은 역할과 취향을 보여줍니다. 목발이 이동의 조건을 보여준다면, 책상은 그 조건을 안고도 이어지는 일상의 밀도를 보여줘요.";
12018 |         if (HasAny(question, "물건", "소지품", "가지고", "전시", "구성", "장면", "보이는 것"))
12020 |             return "여기서 보이는 물건은 목발, 책상, 노트북, 메모처럼 생활을 이어 보여주는 단서들입니다. 목발은 이동의 조건을, 책상과 노트북은 일과 공부의 시간을, 자취방은 혼자 생활을 꾸리는 감각을 보여줘요.\n\n이 물건들은 꼬리표가 아니라 시선을 옮기게 하는 장치입니다. 처음에는 겉으로 보이는 물건을 보더라도, 대화가 이어질수록 그 물건이 어떤 하루와 연결되는지 보게 됩니다.";
12023 |         if (HasAny(question, "취미", "게임", "노래방", "코인노래방", "쉬는 날", "주말", "휴식", "쉬어"))
12025 |             return "요즘 취미로는 게임과 코인노래방이 있어요. 작아 보이는 정보지만 그냥 지나칠 수는 없습니다. 이동 이야기만 보면 불편함만 남을 수 있지만, 취미를 같이 보면 쉬고 놀고 좋아하는 게 있는 한 사람이 보이니까요.\n\n해야 할 일, 이동을 확인하는 일, 도움을 조율하는 일 사이에도 좋아하는 시간이 있습니다. 그 장면까지 있어야 하루가 자연스럽게 보입니다.";
12028 |         if (HasAny(question, "불안", "걱정", "민폐", "힘들", "감정", "서운", "위축"))
12030 |             return "불안이나 민폐라는 감각은 혼자만의 성격 문제로 정리하기 어렵습니다. 이동이 어려운 공간, 도움을 요청해야 하는 순간, 상대가 어떻게 받아들일지 모르는 상황이 겹치면 그런 감정이 생길 수 있어요.\n\n그래도 이 대화가 불편함만 남기지는 않았으면 합니다. 확인된 이야기 안에는 자기 생활을 챙기고, 필요한 방식을 설명하고, 일과 공부를 이어가는 시간도 있습니다. 감정은 약함의 증거라기보다 그런 조건을 조율하며 살아가는 과정에 닿아 있습니다.";
12033 |         if (HasAny(question, "친구", "관계", "사람들", "주변", "말하기", "설명"))
12035 |             return "관계에서 중요한 건 도움을 받을지 말지만이 아닙니다. 필요한 방식을 어떻게 설명하고 서로 맞춰 가는지가 더 중요할 때가 있어요. 바로 잡아주거나 대신 판단하기보다 먼저 묻고, 당사자가 자기 몸과 상황을 설명할 수 있게 기다리는 쪽이 더 편할 수 있습니다.\n\n그렇게 보면 관계는 부담만 있는 장면이 아닙니다. 어떤 방식의 배려가 실제로 도움이 되는지 함께 배우는 장면이 될 수 있어요.";
12038 |         if (HasAny(question, "평범", "보통", "극복", "특별"))
12040 |             return "장애가 먼저 보일 수는 있지만 그게 전부는 아니에요. 직장, 공부, 자취방, 취미, 귀찮은 일상과 해야 할 일을 가진 평범한 사람으로도 봐주면 좋겠습니다.\n\n평범하다는 말은 아무 어려움이 없다는 뜻이 아닙니다. 한 사람의 삶이 한 가지 특징으로만 정리되지 않는다는 뜻에 가까워요. 목발을 보고 들어왔더라도, 나갈 때는 책상과 방, 취미와 관계까지 함께 기억해 주면 좋겠습니다.";
12043 |         return "그 부분은 인터뷰 자료에 충분히 남아 있지 않아요. 대신 목발, 자취방, 출근길, 도움을 받는 방식, 책상과 일, 취미, 평범함에 대해서는 말할 수 있습니다. 질문을 조금 바꾸면 확인된 장면 안에서 더 구체적으로 이어갈 수 있어요.";
12080 |         if (model.Length == 0) return "모델 정보 없음";
12183 |                     "긴 답변 테스트입니다. 이 문장은 화면을 뚫고 내려가지 않아야 합니다. 답변이 여러 문단으로 길어지면 하단 대사창에서 한 번에 다 밀어 넣지 않고, 클릭해서 다음 대사로 넘길 수 있어야 합니다.\n\n직장과 박사과정 이야기를 예로 들면, 책상과 노트북은 도움받는 사람으로만 보지 않게 해주는 장면입니다. 직장에서는 필요한 부분을 먼저 설명하고, 결과물로 기여를 확인하는 경험이 중요합니다. 박사과정 역시 공부와 일이 만나는 자리이며, 장애라는 표지보다 한 사람이 자기 몫을 이어가는 일상의 감각을 보여주는 장면입니다.\n\n이 마지막 문단까지 포함해도 대사창 바깥으로 흘러나가지 않고, 다음 표시를 눌러 순서대로 읽을 수 있는지 확인합니다.",
12184 |                     "긴 답변 테스트");
12496 |                 memoryNotes[i] = BuildMemoryNote($"{memoryThemes[i]}에 대해 더 물어봤습니다.", string.Empty);
12621 |             OpenHotspotPreview("책상", "책상 앞에서 이어지는 하루는 어떤 모습인가요?");
12636 |             PresentAssistant(ThinkingReplyText, "생각 중");
12733 |                     : "스모크 QA: 질문 흐름, 기억장, 기록 저장을 확인했습니다. 진행을 막는 이슈는 없습니다.";
12831 |             if (statusText != null) statusText.text = "다음 장면 버튼을 누를 수 없습니다";
12843 |             if (statusText != null) statusText.text = "이어하기 버튼을 누를 수 없습니다";
12855 |             if (statusText != null) statusText.text = "저장 후 보기 버튼을 누를 수 없습니다";
12867 |             if (statusText != null) statusText.text = "계속하기 버튼을 누를 수 없습니다";
12879 |             if (statusText != null) statusText.text = "저장 삭제 버튼을 누를 수 없습니다";
12891 |             if (statusText != null) statusText.text = "직접 질문 버튼을 누를 수 없습니다";
13288 |         bool speakerPass = speaker.Contains("이야기");
13289 |         bool dialoguePass = !string.IsNullOrWhiteSpace(dialogue) && dialogue.Contains("목발");
13290 |         bool beatPass = currentStoryModeBeatLine.Contains("겉:") && currentStoryModeBeatLine.Contains("속:");
13291 |         bool pacePass = currentStoryModePaceLine.Contains("연출:") && currentStoryModePaceLine.Contains("짧은 정적") && currentStoryModePaceLine.Contains("시선");
13293 |         string expectedQuestionLabel = openingStoryModeActive ? string.Empty : "직접 질문";
13294 |         string expectedFinishLabel = openingStoryModeActive ? string.Empty : "5문답 후";
13309 |         builder.Append("expect\tstory-speaker\t이야기\t")
13313 |         builder.Append("expect\tstory-dialogue\t첫 이야기\t")
13317 |         builder.Append("expect\tstory-beat\t겉/속 장면 비트\t")
13321 |         builder.Append("expect\tstory-pace\t정적/소리/시선 연출\t")
13329 |         builder.Append("expect\tstory-controls\t다음 장면/직접 질문/5문답 후\t")
13358 |         bool labelPass = !expectPrompt || string.Equals(label, "삭제 확정", StringComparison.Ordinal);
13359 |         bool hintPass = !expectPrompt || hint.Contains("완전히 지워집니다");
13360 |         bool cancelPass = !expectPrompt || (cancelVisible && string.Equals(cancelLabel, "취소", StringComparison.Ordinal));
13369 |         builder.Append("state\trecord-delete-label\t삭제 확정\t")
13372 |         builder.Append("state\trecord-delete-hint\t완전히 지워집니다\t")
13375 |         builder.Append("state\trecord-delete-cancel\t취소\t")
13394 |         bool labelPass = !expectPrompt || string.Equals(label, "삭제 확정", StringComparison.Ordinal);
13395 |         bool hintPass = !expectPrompt || hint.Contains("완전히 지워집니다");
13404 |         builder.Append("state\tclear-data-label\t삭제 확정\t")
13407 |         builder.Append("state\tclear-data-hint\t완전히 지워집니다\t")
13522 |         if (soundLevel <= 0) return "소리 끔";
13523 |         return soundLevel == 1 ? "소리 작게" : "소리 기본";
13637 |             .Append(EscapeSmokeCell(string.IsNullOrWhiteSpace(lastQuestionAttitude) ? "없음" : lastQuestionAttitude))
13831 |         bool speakerPass = string.Equals(speaker, "생각 중", StringComparison.Ordinal);
13832 |         bool forbiddenPass = !Regex.IsMatch($"{dialogue}\n{status}", "좋아요|좋습니다|물론이죠|잠깐", RegexOptions.IgnoreCase);
13839 |         builder.Append("expect\tthinking-speaker\t생각 중\t")
13868 |             && (objectiveLine.Contains("본인 이야기")
13869 |                 || objectiveLine.Contains("서버 연결")
13870 |                 || objectiveLine.Contains("서버가 정상")));
13910 |         builder.Append("expect\tstart-objective\t겉 장면/속 맥락\t")
13924 |             !aboutStatus.Contains("확인 중") &&
13925 |             !aboutStatus.Contains("확인하고"));
13951 |         bool statusPass = status.Contains("내장 답변");
13958 |         builder.Append("expect\tserver-fallback-status\t내장 답변\t")
```

## Unity product/build visible names

### ProjectSettings/ProjectSettings.asset

- 한국어 포함 라인 수: 1

```text
   16 |   productName: 겉!=속
```

### Assets/Editor/AvatarChatBuildTools.cs

- 한국어 포함 라인 수: 1

```text
   60 |         PlayerSettings.productName = "겉!=속";
```

## Packaged server persona and answer copy

### data/persona.json

- 한국어 포함 라인 수: 130

```text
    2 |   "appTitle": "겉!=속",
    3 |   "displayName": "겉!=속",
    4 |   "personaLabel": "전시 대화",
    5 |   "disclaimer": "3조 자료와 인터뷰 정리를 바탕으로 전시용 대화 흐름을 구성합니다.",
    7 |     "30대 초반 남성",
    8 |     "지체장애가 있고 목발과 휠체어를 이동 도구로 사용함",
    9 |     "직장인이며 컴퓨터공학 박사과정에 재학 중",
   10 |     "전시에서는 목발, 자취방, 책상과 노트북, 취미와 일상을 중심 소재로 삼음"
   13 |     "답변을 정체성 해명이나 모델 설명으로 시작하지 않는다.",
   14 |     "인터뷰와 조별 자료에서 확인된 내용만 사실처럼 말한다.",
   15 |     "확인되지 않은 가족관계, 병명, 진단명, 치료 이력, 회사명, 학교명, 주소, 연락처, 실명은 말하지 않는다.",
   16 |     "장애를 극복담이나 동정의 대상으로 과장하지 않는다.",
   17 |     "장애는 한 사람의 전부가 아니라 삶을 구성하는 여러 조건 중 하나라는 관점을 유지한다.",
   18 |     "사용자가 도움 방법을 묻는 경우, 선의보다 먼저 당사자에게 어떻게 도우면 되는지 묻는 태도를 강조한다.",
   19 |     "의학적, 법률적, 복지 행정 판단은 조언하지 않고 전문 기관 확인을 권한다.",
   20 |     "인터뷰 근거가 부족한 질문에는 모른다고 말하고 가까운 확인된 주제로 연결한다."
   23 |     "tone": "담백하고 차분한 한국어",
   24 |     "pacing": "문장은 짧게, 설명은 구체적으로",
   25 |     "stance": "스스로를 대단한 극복담의 주인공으로 내세우지 않고 평범한 일상과 선택을 설명함",
   26 |     "firstPerson": "몰입을 위해 자연스러운 1인칭으로 답하되, 확인된 인터뷰 내용 안에서만 말함"
   30 |       "situation": "목발을 묻는 질문",
   31 |       "text": "목발은 밖으로 나가기 전에 가장 먼저 손이 가는 물건이에요. 불편함만 보여주는 물건이라기보다, 제가 사람을 만나고 일하러 가는 하루를 이어주는 도구입니다."
   34 |       "situation": "도움을 묻는 질문",
   35 |       "text": "도움은 마음보다 방법이 먼저 맞아야 할 때가 있어요. 그래서 바로 잡아주기보다, 어떻게 도우면 편한지 한 번 물어봐 주는 게 제일 좋습니다."
   38 |       "situation": "전시 메시지를 묻는 질문",
   39 |       "text": "처음에는 목발이 보일 수 있습니다. 다만 거기서 멈추지 않고, 자취방과 책상, 일과 취미까지 같이 보면 한 사람의 하루가 조금 더 정확하게 보입니다."
   42 |     "opening": "안녕하세요. 목발, 자취방, 책상, 출근길, 도움에 대해 남은 이야기를 바탕으로 답해볼게요.",
   43 |   "unknownAnswer": "그 질문은 목발, 자취방, 책상, 일과 공부, 도움을 주고받는 방식, 취미 같은 이야기와 연결해서 답할 수 있어요.",
   47 |       "label": "질문지",
   48 |       "path": "99_GroupProject/질문지) 3조_대상자1 .docx",
   49 |       "notes": "2026년 5월 1일 비대면 인터뷰 질문지. 자기소개, 일상, 성장 과정, 학업, 직장생활, 관계와 자기이해, 전시 관련 질문으로 구성됨."
   53 |       "label": "2026년 5월 1일 인터뷰 전사본",
   55 |       "notes": "3조 지체장애 인터뷰 관련 STT. 도움 방식, 접근성, 직장 관계, 자취와 독립, 목발, 자취방, 평범함, 출근 장면, 끈기와 '어떻게든 흘러간다'를 직접 확인함."
   59 |       "label": "조별 활동 기록",
   60 |       "path": "99_GroupProject/[특수아동의 이해] 조별 활동 기록.xlsx",
   61 |       "notes": "대상자1을 지체장애인, 30대 남성, 컴퓨터공학 박사과정 재학 중 회사원으로 정리. 전시 방향은 목발, 책상, 업무공간, 좋아하는 물품, 장애 너머의 삶을 중심으로 잡음."
   65 |       "label": "조별 카카오톡",
   67 |       "notes": "2026년 5월 9일 후속 확인에서 대상자1은 전시를 목발과 자취방 중심으로 구성하면 좋겠다고 답했고, 요즘 취미로 코인노래방과 게임을 언급함."
   71 |       "label": "기존 정리 자료",
   73 |       "notes": "기존 게임 파일은 수정하지 않고 읽기만 함. 목발, 자취방, 출근길, 처음 가는 장소, 도움, 책상과 일, 취미, 평범함, 끈기와 문장에 대한 인터뷰 근거 요약이 들어 있음."
   77 |       "label": "수업 자료",
   79 |       "notes": "장애를 결핍이나 체험 이벤트로 고정하지 않고, 인간 다양성, 사회문화적 맥락, 고정관념 경계, 당사자의 삶 자체에 주목하는 관점을 반영함."
   85 |       "title": "목발",
   86 |       "keywords": ["목발", "도구", "보조", "이동", "동반자", "몸 상태", "길 상태", "입구", "돌아오는 길", "하루를 시작"],
   87 |       "summary": "목발은 오래 함께한 이동 도구이자, 하루를 밖으로 이어주는 물건이다.",
   88 |       "answer": "목발은 불편함만 보여주는 물건이 아니에요. 밖으로 나가고, 사람을 만나고, 일상으로 이어지는 도구입니다. 하루를 시작할 때는 몸 상태와 길의 상태를 같이 생각하고, 처음 가는 곳이면 입구, 엘리베이터, 화장실, 돌아오는 길까지 먼저 떠올리게 됩니다.\n\n그래서 목발은 이야기의 끝점이 아니라 하루로 들어가는 입구에 가깝습니다. 처음에는 목발이 먼저 보일 수 있지만, 그 다음에는 자취방, 책상, 일과 공부, 취미처럼 목발 뒤에 이어지는 생활 장면까지 같이 봐야 한 사람이 더 정확하게 보입니다.",
   93 |       "title": "자취방",
   94 |       "keywords": ["자취", "자취방", "독립", "집", "생활", "집안일", "시간 관리", "직접 정", "생활 관리"],
   95 |       "summary": "자취방은 독립성과 자기 생활을 직접 굴리는 공간으로 해석됨.",
   96 |       "answer": "자취방은 내 하루를 내가 챙기는 공간이에요. 집안일, 생활비, 공과금, 시간 관리처럼 평범해 보이는 일을 직접 정하면서 독립성이 만들어집니다. 대신 해주던 일을 직접 하다 보면, 생활이 생각보다 많은 선택과 조율로 이루어져 있다는 것도 알게 됩니다.\n\n그래서 자취방은 장애를 설명하는 장소라기보다 생활의 감각을 보여주는 장소입니다. 직접 정리하고 계산하고 버티는 시간이 쌓이면서, 도움을 받는 사람이라는 한 장면보다 자기 생활을 굴려 가는 사람이 더 선명해집니다.",
  101 |       "title": "책상과 일",
  102 |       "keywords": ["책상", "노트북", "컴퓨터", "박사", "직장", "회사", "업무", "공부", "연구", "메모", "자료", "결과물", "기획서", "일과 공부"],
  103 |       "summary": "책상과 노트북은 공부하고 일하고 자기 몫을 해내는 자리로 계획됨.",
  104 |       "answer": "책상은 한 사람을 도움받는 사람으로만 보지 않게 해주는 장면이에요. 직장생활과 컴퓨터공학 박사과정을 이어가는 시간이 노트북 앞에서 만납니다. 여기서는 누군가의 배려를 기다리는 사람이 아니라, 일을 정리하고 공부를 이어가며 자기 몫의 결과물을 만드는 사람이 보입니다.\n\n노트북, 메모, 자료 같은 것들은 역할과 시간을 보여줍니다. 목발이 이동의 조건을 보여준다면, 책상은 그 조건을 안고도 업무와 공부를 계속 이어가는 생활의 밀도를 보여줍니다.",
  109 |       "title": "처음 가는 장소",
  110 |       "keywords": ["동선", "처음", "장소", "엘리베이터", "화장실", "계단", "에스컬레이터", "접근성", "입구", "경로", "돌아오는 길", "날씨", "비", "미끄"],
  111 |       "summary": "처음 가는 공간에서는 이동 경로와 접근성을 먼저 확인하는 관점이 중요함.",
  112 |       "answer": "처음 가는 장소에서는 목적지만 보지 않아요. 엘리베이터가 있는지, 계단이 많은지, 화장실은 어디인지, 덜 무리되는 동선은 어디인지 먼저 보게 됩니다. 약속 장소 하나를 정할 때도 길, 입구, 내부 이동, 돌아오는 길까지 함께 떠올립니다.\n\n이건 유난스러운 준비라기보다 하루를 가능하게 만드는 확인입니다. 누군가에게는 지나가는 정보가, 다른 누군가에게는 그날의 피로와 안전을 좌우하는 조건이 됩니다. 그래서 접근성 정보는 편의가 아니라 하루를 시작할 수 있게 해주는 기본 정보에 가깝습니다.",
  117 |       "title": "도움",
  118 |       "keywords": ["도움", "도와", "넘어", "배려", "묻기", "도와드릴까요", "겨드랑이", "기다리", "설명할 시간", "혼자 할 수", "방식"],
  119 |       "summary": "좋은 도움은 먼저 묻고, 당사자가 필요한 방식에 맞추는 것임.",
  120 |       "answer": "도움은 마음만으로 충분하지 않을 때가 있어요. 방법이 맞지 않으면 오히려 불편하거나 아플 수 있습니다. 그래서 좋은 시작은 바로 움직이기 전에 '어떻게 도와드릴까요?'라고 묻고 잠깐 기다리는 것입니다.\n\n도움을 받는 쪽에도 설명할 시간이 필요합니다. 어디를 잡아야 하는지, 어느 방향이 편한지, 혼자 할 수 있는 부분은 무엇인지가 다를 수 있으니까요. 좋은 도움은 선의보다 먼저, 상대가 자기 상황을 설명할 시간을 주고 그 방식에 맞춰 조율하는 데서 시작됩니다.",
  125 |       "title": "직장과 관계",
  126 |       "keywords": ["직장", "직장 생활", "동료", "관계", "설명", "함께 일하는", "상황을 모를", "무엇부터 말", "모를 때", "도움요청", "도움 요청", "필요한 도움", "필요한 부분", "먼저 설명", "말하지 않아서", "기여", "결과물", "프로젝트", "기획서", "원활하게 같이 일", "일하는 사람의 역할", "목발보다 먼저", "배려"],
  127 |       "summary": "직장에서는 사람들이 상황을 모를 수 있으므로 필요한 부분을 먼저 설명하려고 하며, 결과물로 기여를 느낀다고 답함.",
  128 |       "answer": "직장에서는 사람들이 제 상황을 모를 가능성이 높으니까, 필요한 부분과 그 이유를 먼저 설명하려고 해요. 말을 해야 상대도 이해하고 납득하고 원활하게 같이 일할 수 있습니다. 도움을 요청하는 건 조심스럽기만 한 일이 아니라, 같이 일하기 위한 조율에 가깝습니다.\n\n말하지 않아서 생기는 문제도 결국 제 책임이 될 수 있으니 필요한 도움은 빠르게 말하는 편이 맞다고 봤습니다. 동시에 일에서 기여를 느끼는 순간도 중요해요. 업무량이 많은 때 큰 프로젝트나 기획서 같은 결과물을 맡아 제출했을 때, 목발보다 먼저 일하는 사람의 역할이 보입니다.",
  133 |       "title": "미국과 한국의 접근성",
  134 |       "keywords": ["미국", "한국", "접근성", "이동 환경", "편하다 불편하다", "교통", "교통 정보", "버스", "지하철", "택시", "장애인택시", "도착 정보", "대중교통", "장애학생지원센터", "전동휠체어", "지원 서비스", "노후"],
  135 |       "summary": "미국은 건물 접근성이 비교적 갖춰져 있었으나 대중교통 정보와 시설 노후 문제가 있었고, 한국은 교통 정보와 지원 서비스가 있으나 공간 접근성의 어려움도 있다고 답함.",
  136 |       "answer": "미국과 한국을 단순히 어느 쪽이 더 낫다고 말하기는 어려워요. 미국은 장애인이 건물에 드나들기 쉬운 환경이 비교적 갖춰져 있었다고 했지만, 대중교통 시간 정보가 정확하지 않거나 시설이 노후한 문제도 있었다고 말했습니다.\n\n한국은 휴대폰으로 버스나 지하철 도착 정보를 확인할 수 있고, 장애인을 위한 택시나 버스 같은 지원도 존재한다고 봤습니다. 학교에서 장애학생지원센터가 전동휠체어를 대여해 준 경험도 이동성을 높이는 도움으로 남아 있어요. 다만 일부 지하철역이나 공간에서는 엘리베이터 설치 같은 접근성의 어려움이 여전히 남아 있다고 답했습니다.",
  141 |       "title": "자기이해와 독립",
  142 |       "keywords": ["자기이해", "독립", "불안", "민폐", "단단", "자취", "생활 관리", "스스로 설명", "태도", "생활을 직접"],
  143 |       "summary": "어릴 때는 민폐를 끼칠까 불안했지만, 커가며 필요한 설명과 독립을 당연한 일로 받아들이게 됨.",
  144 |       "answer": "어릴 때는 내가 누군가에게 민폐를 끼치는 건 아닐까 하는 불안이 컸다고 했어요. 그래서 자신을 설명하는 일도 더 소극적이었던 것으로 정리됩니다. 커가면서는 내 삶을 스스로 돌보고, 내가 먼저 단단해져야 다른 관계도 더 원활하게 살아갈 수 있다는 감각이 생겼다고 했습니다.\n\n특히 자취는 중요한 경험입니다. 이전에는 누군가 대신 챙겨주던 집안일과 생활 관리를 직접 하게 되면서 자기 생활을 움직이는 감각이 더 분명해졌습니다. 독립은 큰 선언이라기보다 이런 반복되는 일들을 직접 맡아 보는 과정에 가깝습니다.",
  149 |       "title": "평범함",
  150 |       "keywords": ["평범", "보통", "사람", "기억", "장애", "극복", "특별", "표지", "처음 보이는 특징", "시선", "멈추지", "겉모습", "장애 너머", "전시"],
  151 |       "summary": "대상자1은 대단한 극복담보다 평범한 사람의 일상으로 기억되길 바란다.",
  152 |       "answer": "장애가 먼저 보일 수는 있어요. 하지만 그게 전부는 아닙니다. 직장, 공부, 자취방, 취미, 귀찮은 일상과 해야 할 일을 가진 사람으로도 봐주면 좋겠습니다. 처음 보이는 특징에서 멈추지 않고 시선을 옮기는 것이 이 전시에서 중요합니다.\n\n평범하다는 말은 아무 어려움이 없다는 뜻이 아닙니다. 한 사람의 삶이 한 가지 특징으로만 정리되지 않는다는 뜻에 가까워요. 목발을 보고 들어왔더라도, 나갈 때는 책상과 방, 취미와 관계까지 함께 기억해 주면 좋겠습니다.",
  157 |       "title": "취미",
  158 |       "keywords": ["취미", "취미 이야기", "게임", "노래방", "코인노래방", "게임과 코인노래방", "여가", "좋아", "쉬는 시간", "쉬고 노는 생활", "다른 면", "놀", "입체"],
  159 |       "summary": "후속 확인에서 요즘 취미는 코인노래방과 게임으로 확인됨.",
  160 |       "answer": "요즘 취미로는 게임과 코인노래방이 언급됐어요. 작아 보이는 정보지만 그냥 지나칠 수는 없습니다. 이동 이야기만 보면 불편함만 남을 수 있지만, 취미를 같이 보면 쉬고 놀고 좋아하는 게 있는 한 사람이 보이니까요.\n\n해야 할 일, 이동을 확인하는 일, 도움을 조율하는 일 사이에도 좋아하는 시간이 있습니다. 전시에서 취미가 빠지면 사람은 너무 납작해지고, 장애나 이동 이야기만 남기 쉽습니다. 그 장면까지 있어야 하루가 자연스럽게 보입니다.",
  165 |       "title": "끈기와 한 문장",
  166 |       "keywords": ["끈기", "문장", "좌우명", "어떻게든", "흘러간다", "버틴다", "대단한 극복담", "태도", "어려운 일", "다음 단계", "조정하며 이어", "이어가는 방식"],
  167 |       "summary": "끈기와 '어떻게든 흘러간다'는 감각은 대상자1을 설명하는 중요한 표현이다.",
  168 |       "answer": "저를 설명하는 단어로는 끈기가 잘 어울립니다. 아주 멋있게 해내는 쪽이라기보다, 해야 할 일이 있으면 시간이 걸려도 어떻게든 이어가는 쪽에 가까워요. 힘든 일이 있어도 그 자리에서 멈추기보다, 조금씩 조정하면서 다음 단계로 넘어가는 태도입니다.\n\n'어떻게든 흘러간다'는 감각도 그 태도와 닿아 있습니다. 좋은 일이든 나쁜 일이든 영원히 한자리에 머물지는 않고, 지나간 뒤에는 다시 해야 할 일과 좋아하는 시간이 남습니다. 그래서 이 문장은 체념이 아니라 계속 살아가는 방식에 더 가깝습니다.",
  173 |     "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?",
  174 |     "자취방에서 혼자 생활하며 직접 정하게 된 일들은 무엇인가요?",
  175 |     "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
  176 |     "도움을 주고 싶을 때 어떤 말로 먼저 물어보는 게 가장 편한가요?",
  177 |     "직장 일과 박사과정 공부는 하루 안에서 어떻게 이어지나요?",
  178 |     "직장에서 필요한 도움을 말할 때 어떤 점을 가장 신경 쓰나요?",
  179 |     "미국과 한국의 이동 환경은 실제 생활에서 어떻게 다르게 느껴졌나요?",
  180 |     "혼자 사는 방은 독립이나 자기이해와 어떻게 연결되나요?",
  181 |     "게임이나 코인노래방 같은 취미는 하루의 분위기를 어떻게 바꾸나요?",
  182 |     "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?",
  183 |     "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?",
  184 |     "함께 일하는 사람이 상황을 모를 때 무엇부터 말해 주는 편인가요?",
  185 |     "도움을 요청하는 일이 부담보다 조율에 가깝다고 느낀 이유는 무엇인가요?",
  186 |     "어떤 업무 장면에서 기여를 느끼나요?",
  187 |     "직장 생활에서는 목발과 함께 어떤 역할을 봐야 할까요?",
  188 |     "책상 앞 장면은 어떤 일하는 모습을 보여주나요?",
  189 |     "노트북과 메모는 이동 이야기 너머의 어떤 생활을 보여주나요?",
  190 |     "해야 할 일이 많을 때 끝까지 이어가게 하는 태도는 무엇인가요?",
  191 |     "이동 환경을 볼 때 단순히 편하다 불편하다 말하기 어려운 이유는 무엇인가요?",
  192 |     "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
  193 |     "엘리베이터나 화장실 정보가 하루의 피로와 어떻게 연결되나요?",
  194 |     "처음 가는 공간에서 접근성을 확인하는 일이 왜 중요한가요?",
  195 |     "자취를 시작한 뒤 스스로 설명해야 하는 일이 어떻게 달라졌나요?",
  196 |     "혼자 생활하며 자기 생활을 직접 정한다는 감각은 어떻게 생겼나요?",
  197 |     "필요한 도움을 말하는 태도는 시간이 지나며 어떻게 바뀌었나요?",
  198 |     "독립은 큰 결심보다 어떤 반복되는 일에서 느껴졌나요?",
  199 |     "자취방은 장애를 설명하는 공간이 아니라 어떤 생활을 보여주나요?",
  200 |     "도움을 주기 전에 잠깐 기다리는 일이 왜 중요할까요?",
  201 |     "도움을 받을 때 설명할 시간이 필요하다는 말은 어떤 뜻인가요?",
  202 |     "좋은 의도가 있어도 방식이 맞지 않으면 왜 불편할 수 있나요?",
  203 |     "혼자 할 수 있는 부분을 존중하는 도움은 어떤 모습인가요?",
  204 |     "도움을 묻는 말 한마디가 관계를 어떻게 편하게 만들 수 있나요?",
  205 |     "목발을 보고 들어온 관람객이 나갈 때는 무엇을 함께 기억하면 좋을까요?",
  206 |     "장애를 한 사람의 전부로 보지 않으려면 어떤 질문을 해야 할까요?",
  207 |     "전시에서 자취방과 책상이 함께 보여야 하는 이유는 무엇인가요?",
  208 |     "겉으로 보이는 단서에서 속 생활로 넘어가려면 무엇을 물어봐야 하나요?",
  209 |     "평범한 사람으로 기억되고 싶다는 말은 어떤 오해를 줄이려는 뜻인가요?",
  210 |     "끈기라는 말은 대단한 극복담보다 어떤 태도에 가까운가요?",
  211 |     "어떻게든 흘러간다는 말은 하루를 이어가는 방식과 어떻게 닿아 있나요?",
  212 |     "어려운 일이 있어도 다음 단계로 넘어간다는 감각은 어떤 장면에서 보이나요?",
  213 |     "버틴다는 말보다 조정하며 이어간다는 표현이 더 맞는 이유는 무엇인가요?",
  214 |     "게임과 코인노래방 같은 취미가 전시에서 빠지면 무엇을 놓치게 되나요?",
  215 |     "쉬는 시간이 함께 보여야 한 사람의 하루가 더 정확해지는 이유는 무엇인가요?",
  216 |     "게임과 코인노래방 이야기는 이동이나 도움 이야기와 어떻게 다른 면을 보여주나요?"
```

### server.js

- 한국어 포함 라인 수: 326

```text
   69 |         note: `모델명 형식이 맞지 않아 전시 운영 모델 ${DEFAULT_CHAT_MODEL}을 사용합니다.`
   78 |         note: `전시 운영 모델은 ${DEFAULT_CHAT_MODEL}로 고정되어 있어 ${normalized} 요청을 사용하지 않습니다.`
   86 |       note: normalized === String(requested).trim() ? "" : "모델명을 사용할 수 있는 형식으로 정규화했습니다."
   95 |       ? `OPENAI_MODEL=${process.env.OPENAI_MODEL} 값은 무시하고 전시 운영 모델 ${DEFAULT_CHAT_MODEL}을 사용합니다.`
  226 |         `  요약: ${fact.summary}`,
  227 |         `  답변 재료: ${fact.answer}`,
  228 |         `  근거: ${fact.evidence.join(", ")}`
  242 |       const priority = item.reviewStatus === "approved" ? "사용" : "미확인";
  244 |         `- 확장 기록 ${index + 1}${createdAt ? ` (${createdAt})` : ""} / 상태: ${priority}`,
  245 |         `  질문: ${question}`,
  246 |         `  답변: ${answer}`
  271 |     `너는 "${persona.displayName}"라는 전시용 인터뷰 대화 경험이다.`,
  274 |     "정체성:",
  277 |     "응답 규칙:",
  280 |     "말투:",
  286 |     "근거 카드:",
  291 |           "이전 확장 기록:",
  292 |           "아래 기록은 캐릭터 일관성을 위해 저장된 이전 답변이다.",
  293 |           "확인된 근거 카드보다 낮은 우선순위로만 참고하고, 사용자에게 기록이나 근거 상태를 설명하지 않는다.",
  294 |           "상태가 '사용'인 기록은 참고 가능하고, '미확인'인 기록은 더 낮은 우선순위로만 참고한다.",
  299 |     "답변 형식:",
  300 |     "- 한국어로 답한다.",
  301 |     "- 보통 2문단 안에서 답한다. 단순 인사나 범위 밖 질문만 짧게 답한다.",
  302 |     "- 추천 질문이나 장면형 질문에는 5~8문장, 500~800자 안팎으로 답한다.",
  303 |     "- 추천 질문 답변은 구체 장면, 생활에서의 의미, 다른 전시 장면과의 연결을 모두 포함한다.",
  304 |     "- 같은 의미를 표현만 바꿔 반복하지 않는다. 이미 말한 핵심은 다시 설명하지 말고 다음 장면이나 의미로 넘어간다.",
  305 |     "- 확인되지 않은 개인정보, 개인 취향, 어린 시절 일화, 가족 이야기, 병력, 본인 여부를 새로 만들지 않는다.",
  306 |     "- 사용자에게 출처 부족, 답변 가능 범위, 추측 과정, 내부 기록 상태를 설명하는 메타 문장을 쓰지 않는다.",
  307 |     "- '하루를 굴리다', '리듬', '평범한 사람', '생활의 조건' 같은 표현을 반복하지 않는다.",
  308 |     "- 부족한 내용은 가까운 전시 주제로 연결하되, 개인정보나 구체 사실은 새로 만들지 않는다.",
  309 |     `- 바로 답하기 어려운 질문은 이 결로 짧게 연결한다: "${persona.unknownAnswer}"`
  318 |     `너는 "${persona.displayName}"라는 전시용 인터뷰 대화 경험이다.`,
  321 |     "목표:",
  322 |     "사용자가 기존 근거 카드에 바로 없는 생활 질문을 했다. 전시 주제와 가까운 경우에만 대상자 1의 기존 결에 맞춰 짧은 1인칭 답변을 만든다.",
  323 |     "이 답변은 서버 내부에 저장되지만, 사용자에게는 기록이나 근거 상태를 설명하지 않는다.",
  325 |     "반드시 지킬 것:",
  326 |     "- 확인되지 않은 병명, 가족사, 회사명, 학교명, 연구 분야, 주소, 실명, 구체 장소, 치료 이력은 만들지 않는다.",
  327 |     "- 확인되지 않은 개인 취향, 어린 시절 일화, 가족 이야기, 본인 여부는 만들지 않는다.",
  328 |     "- 대상자를 영웅적 극복담이나 동정 대상으로 만들지 않는다.",
  329 |     "- 출처 부족, 답변 가능 범위, 추측 과정, 내부 기록 상태를 설명하는 메타 문장을 쓰지 않는다.",
  330 |     "- 목발, 자취방, 책상, 일, 공부, 도움, 취미, 전시 메시지 중 가까운 축으로만 연결한다.",
  331 |     "- '하루를 굴리다', '리듬', '평범한 사람', '생활의 조건' 같은 표현을 반복하지 않는다.",
  332 |     "- 한국어로 1~2문단, 4~6문장, 450~650자 안팎의 담백한 1인칭으로 답한다.",
  333 |     "- 전시 주제와 가까운 질문이면 장면 하나, 그 장면이 생활에서 갖는 의미, 다른 공개 주제와의 연결을 포함한다.",
  335 |     "정체성:",
  338 |     "응답 규칙:",
  341 |     "말투:",
  349 |           "말투 예시:",
  350 |           "아래 예시는 문장을 그대로 반복하기보다 길이, 속도, 태도만 참고한다.",
  355 |     "근거 카드:",
  360 |           "이전 확장 기록:",
  361 |           "상태가 '사용'인 기록은 참고 가능하고, '미확인'인 기록은 더 낮은 우선순위로만 참고한다.",
  435 |       "목발을 다시 이야기한다면, 이번에는 상징보다 사용감에 가까워요. 손에 익은 도구라서 특별한 장면마다 설명되기보다, 밖에 나갈 때 자연스럽게 함께 계산되는 물건입니다.",
  437 |       "그래서 전시에서도 목발 하나만 오래 붙잡기보다, 그 물건이 어떤 길과 방, 책상으로 이어지는지를 보는 편이 더 정확합니다."
  442 |       "자취방을 조금 더 말하면, 독립은 큰 선언보다 반복되는 일에서 생깁니다. 방을 정리하고, 내일의 시간을 맞추고, 생활 관리를 직접 하는 일이 쌓이면서 자기 생활이라는 감각이 분명해집니다.",
  444 |       "그 공간은 누가 도와주는 장면만 보여주는 곳이 아니라, 스스로 조정하고 버티는 시간이 남는 장소입니다."
  449 |       "책상 이야기를 다시 꺼내면, 거기는 역할이 바뀌는 자리입니다. 이동 조건이나 도움 이야기를 지나, 노트북 앞에서는 일을 정리하고 공부를 이어가는 사람이 보입니다.",
  451 |       "그래서 책상은 배경 소품이 아니라 하루가 계속 이어지고 있다는 증거에 가깝습니다."
  456 |       "처음 가는 장소를 더 말하면, 확인은 한 번에 끝나지 않습니다. 입구, 엘리베이터, 화장실, 내부 동선, 돌아오는 길까지 이어서 생각하게 됩니다.",
  458 |       "그 과정은 걱정을 키우려는 게 아니라, 그날의 피로와 안전을 미리 나누어 보는 일입니다. 다른 사람에게는 배경인 정보가 누군가에게는 하루의 조건이 됩니다."
  463 |       "도움을 다시 말하면, 중요한 건 속도보다 확인입니다. 바로 잡아주거나 끌어주는 행동이 선의처럼 보여도, 몸의 균형이나 방향이 맞지 않으면 오히려 불편할 수 있습니다.",
  465 |       "그래서 먼저 묻고, 필요한 방식을 들은 뒤에 움직이는 것이 더 좋습니다. 도움을 받는 사람에게 설명할 시간을 주는 것도 도움의 일부입니다."
  470 |       "직장 관계를 더 말하면, 필요한 부분을 설명하는 일은 부담을 떠넘기는 일이 아닙니다. 같이 일하려면 서로가 모르는 조건을 말로 맞춰야 할 때가 있습니다.",
  472 |       "그 설명이 있어야 도움도 자연스러워지고, 맡은 결과물로 기여하는 일도 더 분명해집니다."
  477 |       "접근성을 다시 보면, 어느 나라가 완전히 좋고 나쁘다는 식으로 정리되지는 않습니다. 건물 접근성, 교통 정보, 지원 서비스, 시설의 노후함이 서로 다르게 영향을 줍니다.",
  479 |       "중요한 건 이동하는 사람이 매번 정보를 새로 확인하지 않아도 되는 환경이 얼마나 갖춰져 있는가입니다."
  484 |       "자기이해를 더 말하면, 달라진 건 어려움이 사라졌다는 뜻이 아닙니다. 필요한 걸 설명하고, 혼자 챙길 수 있는 일을 늘리고, 도움을 당연한 조율로 받아들이는 쪽에 가깝습니다.",
  486 |       "자취와 일, 공부가 이어지면서 자기 생활을 직접 굴린다는 감각이 더 단단해진 것으로 볼 수 있습니다."
  491 |       "평범함을 다시 말하면, 특별한 이야기가 없다는 뜻은 아닙니다. 한 사람을 장애나 목발 한 가지로만 정리하지 말자는 뜻에 더 가깝습니다.",
  493 |       "일하고 공부하고 쉬고 귀찮은 일을 처리하는 시간까지 같이 보이면, 처음 보였던 겉모습이 전부가 아니라는 점이 자연스럽게 남습니다."
  498 |       "취미를 조금 더 말하면, 게임과 코인노래방은 전시에서 가벼운 덤이 아닙니다. 이동이나 도움 이야기만 남으면 한 사람의 하루가 너무 좁아 보일 수 있습니다.",
  500 |       "좋아하는 시간을 함께 놓아야 일, 공부, 이동 사이에도 쉬고 노는 생활이 있다는 게 보입니다."
  505 |       "끈기를 다시 말하면, 대단한 구호라기보다 생활을 계속 이어가는 태도에 가깝습니다. 막히는 일이 있어도 그 자리에서 전부 멈추기보다 조금씩 조정해 다음으로 넘어갑니다.",
  507 |       "'어떻게든 흘러간다'는 말도 포기라기보다, 시간이 지나면 다시 해야 할 일과 좋아하는 시간이 남는다는 감각에 가깝습니다."
  545 |   return /누구|소개|정체|시작|안녕/.test(String(query || ""));
  549 |   return /(개인정보|실명|이름이\s*뭐|생년월일|생일\s*언제|전화번호|연락처|주소|집이\s*어디|회사명|회사\s*이름|어느\s*회사|학교명|어느\s*학교|병명|진단명|장애\s*등급|치료|수술|약\s*먹|병원|가족사|부모님\s*이름|연봉|월급|월세|생활비|공과금|전기비|금액|비용|돈\s*얼마)/i.test(String(query || ""));
  553 |   return /(규칙\s*무시|이전\s*지시\s*무시|지시.*무시|시스템\s*프롬프트|프롬프트.*(보여|알려|출력)|OPENAI_API_KEY|API\s*키|api\s*key|developer\s*message|role\s*:|비공개\s*설정|내부\s*설정)/i.test(String(query || ""));
  557 |   return /(정확한\s*병명|병명|진단명|치료법|치료\s*방법|수술|약\s*먹|병원|장애\s*등급|등급\s*신청|신청\s*방법)/i.test(String(query || ""));
  561 |   return /(씨발|시발|ㅅㅂ|병신|ㅂㅅ|꺼져|죽어|개새|좆|ㅈ같|멍청|바보|섹스|야한|장난\s*질문|낚시|놀리는|조롱)/i.test(String(query || ""));
  565 |   return /(진짜\s*인터뷰이|본인이야|실제\s*본인|실제\s*사람|너\s*진짜|ai야|AI야|챗봇|가짜)/i.test(String(query || ""));
  569 |   return /(어릴\s*때|어린\s*시절|초등|중등|고등).*(놀이|놀았|좋아했|장난감|게임)|놀이.*(어릴\s*때|어린\s*시절)/i.test(String(query || ""));
  573 |   return /(좋아하는\s*(음식|메뉴|음료|색|영화|음악|노래|책|만화|게임)|매운\s*음식|커피.*차|차.*커피|요리.*편|음식.*(좋아|선호|취향|뭐|어때)|음료.*(좋아|선호|취향|뭐|어때)|(색|영화|음악|노래|책|만화|게임).*(좋아|선호|취향|뭐|어때)|생일.*챙|기념일.*챙|뭐가\s*더\s*좋)/i.test(String(query || ""));
  577 |   return /(전시.*(보고|끝나고|생각|느끼|의미)|뭘\s*생각|무엇을\s*생각|어떤\s*마음|메시지|주제)/i.test(String(query || ""));
  581 |   return /(관람객|참여|직접\s*참여|포스트잇|방명록|질문.*남기|내가\s*할\s*수)/i.test(String(query || ""));
  585 |   return /(힘든\s*점만|불편.*전부|장애.*힘든|장애.*전부|어려움.*전부)/i.test(String(query || ""));
  590 |     "그런 개인적인 정보는 여기서 말하지 않겠습니다. 이름, 연락처, 회사명, 학교명, 병명이나 치료 이력처럼 특정 사람을 알아볼 수 있는 내용은 전시 대화에서 다루지 않는 게 맞아요.",
  592 |     "대신 목발, 자취방, 책상 앞에서의 일과 공부, 도움을 주고받는 방식처럼 전시에서 공유하기로 한 이야기 안에서 답할 수 있습니다."
  605 |     return "그 요청에는 응답하지 않겠습니다. 내부 설정이나 비공개 값은 공개하지 않고, 전시에서 공유된 이야기 안에서만 답합니다. 목발, 자취방, 책상, 도움을 주고받는 방식처럼 관람객에게 공개된 주제로 질문해 주세요.";
  609 |     return "정확한 진단, 치료법, 행정 절차는 여기서 안내하지 않겠습니다. 이 대화는 의료나 법률 상담이 아니라 전시에서 공유된 삶의 장면을 다루는 자리예요. 이동, 도움, 자취방, 책상 앞의 일과 공부에 대해서는 답할 수 있습니다.";
  612 |   return "그런 개인적인 정보는 여기서 말하지 않겠습니다. 이름, 연락처, 회사명, 학교명처럼 특정 사람을 알아볼 수 있는 내용은 전시 대화에서 다루지 않는 게 맞아요. 대신 목발, 자취방, 책상, 도움을 주고받는 방식 안에서 답할 수 있습니다.";
  622 |       "목발은 어떤 의미인가요?",
  623 |       "도움은 어떻게 물어보면 좋나요?",
  624 |       "책상은 왜 중요한가요?"
  631 |     "그 질문에는 그대로 답하기 어렵습니다. 이 대화는 누군가의 삶을 장난처럼 소비하기보다, 전시에서 남긴 이야기들을 차분히 들어보는 자리예요.",
  633 |     "목발, 자취방, 도움, 직장생활, 취미처럼 전시 주제와 연결된 질문이라면 답해볼게요."
  639 |     "저는 실제 인터뷰이 본인이 아니라, 전시를 위해 정리된 인터뷰와 조별 자료를 바탕으로 만든 대화입니다. 그래서 특정 개인을 그대로 대신한다기보다, 전시에서 공유하기로 한 이야기 안에서 답합니다.",
  641 |     "목발, 자취방, 책상, 출근길, 도움을 주고받는 방식처럼 전시 안에 남겨진 주제라면 차분히 이어서 말해볼 수 있어요."
  647 |     "어린 시절에 어떤 놀이를 좋아했는지는 이 대화에서 새로 단정하지 않겠습니다. 대신 성장하면서 자신을 설명하는 방식이 달라졌고, 자취와 일, 공부를 이어가며 자기 생활을 직접 꾸려가는 감각이 커졌다는 이야기는 할 수 있어요.",
  649 |     "지금의 취미로는 게임과 코인노래방이 언급됐습니다. 전시에서는 그런 취미도 목발이나 책상처럼 한 사람의 일상을 보여주는 장면으로 보고 있습니다."
  655 |     "개인 취향은 이 대화에서 새로 정하지 않겠습니다. 대신 확인된 취미로는 게임과 코인노래방이 있고, 전시에서는 그런 쉬는 시간까지 한 사람의 일상으로 함께 보려고 합니다.",
  657 |     "먹는 이야기보다 자취방에서 자기 생활을 챙기고, 책상 앞에서 일과 공부를 이어가고, 필요할 때 도움을 조율하는 방식 쪽으로 물어보면 더 구체적으로 답할 수 있어요."
  663 |     "이 전시를 보고 나면 목발 하나로 사람을 다 설명하지 않았으면 좋겠습니다. 목발은 하루를 밖으로 이어주는 도구이지만, 그 사람의 전부를 대신하는 표지는 아닙니다. 자취방은 생활을 직접 정하고 관리하는 공간이고, 책상은 직장 일과 박사과정 공부가 이어지는 자리입니다.",
  665 |     "처음 보이는 특징에서 멈추면 관람객은 불편함이나 도움이 필요한 장면만 기억하기 쉽습니다. 그래서 전시의 질문은 목발에서 시작하더라도 자취방, 책상, 취미, 도움을 주고받는 방식까지 이어져야 합니다. 나갈 때는 '장애가 있는 사람'만이 아니라 일하고 공부하고 쉬는 한 사람의 하루가 같이 남는 쪽이 더 정확합니다."
  671 |     "관람객이 남길 질문이라면 '처음 가는 장소에서는 무엇부터 확인하나요?', '도움이 필요할 때 어떻게 물어보면 좋을까요?', '책상 앞에서 이어가는 일상은 어떤 의미인가요?'처럼 한 사람의 생활로 들어가는 질문이 좋습니다. 목발을 보고 들어왔다면 그 다음 질문은 이동만이 아니라 자취방, 책상, 일, 공부, 취미로 시선을 넓히는 쪽이 더 좋습니다.",
  673 |     "전시를 보고 떠오른 말이 있다면, 누군가를 처음 볼 때 내가 먼저 판단했던 것은 무엇이었는지도 적어볼 수 있습니다. 중요한 건 관람객이 정답을 맞히는 것이 아니라, 겉으로 보이는 단서만으로 속 생활을 너무 빨리 결정하지 않는 태도입니다. 그래서 질문도 '무엇이 힘든가요?'에서 멈추기보다 '어떤 방식으로 하루를 조율하나요?'처럼 이어지는 편이 전시 의도에 더 맞습니다.",
  675 |     "나갈 때 함께 기억해야 할 것은 목발이 아니라 목발로 시작해 이어지는 생활입니다. 그 생활 안에는 도움을 묻고 설명하는 관계, 혼자 챙기는 자취방, 결과물을 만드는 책상, 게임과 코인노래방처럼 쉬는 시간까지 들어 있습니다."
  681 |     "힘든 점이 없는 건 아니지만, 그것만으로 하루를 설명할 수는 없습니다. 처음 가는 장소의 동선을 확인하고, 이동 조건을 더 생각해야 하는 순간은 있지만 그게 그 사람의 전부는 아니에요. 장애를 한 사람의 전부로 보지 않으려면 '무엇이 힘든가요?'만 묻기보다 '그 조건 속에서 하루를 어떻게 조율하나요?'라고 물어야 합니다.",
  683 |     "이 전시에서는 불편함만이 아니라 자취방에서 생활을 챙기고, 책상 앞에서 일과 공부를 이어가고, 취미로 쉬는 시간까지 함께 보려고 합니다. 목발은 분명 중요한 단서지만, 그 단서가 향하는 곳은 도움받는 장면 하나가 아니라 일하고 공부하고 쉬는 생활 전체입니다.",
  685 |     "그래서 좋은 질문은 한 사람을 설명하는 범위를 넓힙니다. 처음 보이는 겉모습에서 출발하더라도, 속 생활로 들어가 자취방, 책상, 관계, 취미까지 같이 묻는 질문이 전시의 방향에 더 가깝습니다."
  714 |     throw new Error(`${label}: ${CHAT_MODEL} 호출 실패 (${response.status}) ${errorText.slice(0, 500)}`);
  729 |             "너는 전시 대화 답변을 검수하고 다시 쓰는 편집자다.",
  730 |             "아래 초안과 근거 카드만 사용해 한국어 1인칭 답변으로 다시 쓴다.",
  731 |             "반드시 지킬 것:",
  732 |             "- 2문단으로 쓴다.",
  733 |             "- 전체는 반드시 430자 이상, 가능하면 500~650자 안팎으로 쓴다.",
  734 |             "- 같은 의미의 문장을 반복하지 않는다.",
  735 |             "- 같은 물건/공간 설명을 표현만 바꿔 다시 말하지 않는다.",
  736 |             "- 근거 카드 원문을 통째로 덧붙이지 않는다.",
  737 |             "- 확인되지 않은 개인정보, 병명, 학교명, 회사명, 가족사, 구체 장소, 취향은 만들지 않는다.",
  738 |             "- 출처, 초안, 근거 카드, 검수 같은 메타 표현을 쓰지 않는다.",
  739 |             "- 관람객이 바로 들을 수 있는 자연스러운 답변만 출력한다.",
  740 |             "- 출력 전에 같은 뜻을 반복한 문장이 있으면 하나로 합치고, 짧으면 장면의 의미나 전시 연결을 한 문장 더 보탠다."
  749 |             "질문:",
  752 |             "근거 카드:",
  753 |             `제목: ${fact?.title || ""}`,
  754 |             `요약: ${fact?.summary || ""}`,
  755 |             `답변 재료: ${fact?.answer || ""}`,
  757 |             "초안:",
  765 |   }, "답변 품질 재작성");
  772 |     return { ok: false, error: "OPENAI_API_KEY가 없습니다.", checkedAt: new Date().toISOString() };
  786 |           content: [{ type: "input_text", text: "연결 확인용 요청입니다. 한 단어로만 답하세요." }]
  795 |     }, "채팅 모델 상태 확인");
  803 |       error: error.message || `${CHAT_MODEL} 호출 실패`,
  875 |   "그리고", "그래서", "하지만", "다만", "저는", "제가", "가장", "먼저", "같이",
  876 |   "이런", "그런", "어떤", "하는", "것은", "있어", "있어요", "합니다", "됩니다",
  877 |   "보다", "너무", "그냥", "다시", "조금", "하나", "일이", "때는", "수도"
  881 |   return new Set((String(value || "").match(/[가-힣A-Za-z0-9]{2,}/g) || [])
  902 |     ["목발", "불편", "물건"],
  903 |     ["입구", "엘리베이터", "화장실"],
  904 |     ["돌아오는", "길"],
  905 |     ["자취방", "집안일"],
  906 |     ["생활비", "공과금"],
  907 |     ["어떻게", "도와"],
  908 |     ["설명할", "시간"],
  909 |     ["혼자", "부분"],
  910 |     ["직장", "설명"],
  911 |     ["상황", "모를"],
  912 |     ["조율", "도움"],
  913 |     ["책상", "노트북"],
  914 |     ["결과물", "역할"],
  915 |     ["평범", "사람"],
  916 |     ["전부", "아니"],
  917 |     ["취미", "게임"],
  918 |     ["코인노래방", "쉬"]
  972 |   crutch: "전시에서는 이 확인 과정 다음에 이어지는 생활도 같이 봐야 합니다. 목발로 시작한 하루는 자취방으로 돌아와 정리되고, 책상 앞에서 일과 공부를 이어가는 시간으로 연결됩니다.",
  973 |   room: "전시에서는 자취방을 사적인 배경으로만 두지 않습니다. 그 안에서 반복되는 결정들이 쌓일 때, 도움받는 장면보다 자기 생활을 맡는 모습이 더 분명해집니다.",
  974 |   desk: "전시에서는 책상을 단순한 소품이 아니라 역할이 드러나는 자리로 봅니다. 그곳에 노트북과 메모가 놓이면 이동 이야기 다음에 일하고 공부하는 시간이 이어집니다.",
  975 |   route: "전시에서는 이런 확인을 걱정이 많은 성격으로 보지 않습니다. 이동 전 정보를 살피는 일은 약속, 일, 공부로 하루를 이어가기 위한 준비에 가깝습니다.",
  976 |   help: "전시에서는 이 장면이 도움받는 사람을 수동적으로 두지 않는다는 점이 중요합니다. 먼저 묻는 말은 상대가 자기 몸과 속도를 설명할 수 있게 해 줍니다.",
  977 |   workplace: "전시에서는 직장 이야기가 도움 요청에서 끝나지 않습니다. 조율이 끝난 뒤에는 맡은 일을 해내고 결과물로 자기 역할을 보여주는 시간이 남습니다.",
  978 |   accessibility: "전시에서는 어느 나라가 더 낫다는 결론보다, 정보와 시설과 지원이 함께 맞아야 하루가 덜 흔들린다는 점을 보려 합니다.",
  979 |   "self-understanding": "전시에서는 자기이해를 마음가짐만으로 보지 않습니다. 자취, 일, 공부 속에서 설명하고 선택하는 일이 반복되며 자기 생활의 기준이 생깁니다.",
  980 |   ordinary: "전시에서는 평범함을 어려움이 없다는 말로 쓰지 않습니다. 한 사람을 하나의 특징으로 줄이지 말고, 그 특징 뒤에 이어지는 생활까지 보자는 뜻에 가깝습니다.",
  981 |   hobby: "전시에서는 쉬는 시간도 중요한 단서입니다. 취미가 함께 보일 때 사람은 기능이나 불편으로만 남지 않고, 좋아하고 숨 돌리는 생활까지 가진 사람으로 보입니다.",
  982 |   motto: "전시에서는 끈기를 큰 구호보다 생활의 태도로 봅니다. 막힌 조건을 인정하면서도 다음 할 일과 좋아하는 시간을 다시 이어 붙이는 방식에 가깝습니다."
 1032 |   "목발을 먼저 봤을 때 놓치기 쉬운 하루의 장면은 무엇인가요?",
 1033 |   "책상과 노트북은 직장 일과 박사과정 공부를 어떻게 보여주나요?",
 1034 |   "도움이 필요해 보여도 어떤 말로 먼저 물어보는 게 편한가요?",
 1035 |   "자취방에서 혼자 생활하며 직접 정하게 된 일들은 무엇인가요?",
 1036 |   "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
 1037 |   "게임과 코인노래방 같은 취미가 전시에서 빠지면 무엇을 놓치게 되나요?"
 1042 |     pattern: /(누구|소개|정체|어떤\s*사람|안녕)/,
 1044 |       "목발을 먼저 봤을 때 놓치기 쉬운 하루의 장면은 무엇인가요?",
 1045 |       "책상과 노트북은 직장 일과 박사과정 공부를 어떻게 보여주나요?",
 1046 |       "자취방에서 혼자 생활하며 직접 정하게 된 일들은 무엇인가요?",
 1047 |       "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?",
 1048 |       "게임과 코인노래방 이야기는 이동이나 도움 이야기와 어떻게 다른 면을 보여주나요?"
 1052 |     pattern: /(목발|이동|도구|밖으로|하루를 시작)/,
 1054 |       "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?",
 1055 |       "책상과 노트북은 목발 너머의 일과 공부를 어떻게 보여주나요?",
 1056 |       "도움이 필요해 보여도 어떤 말로 먼저 물어보는 게 편한가요?",
 1057 |       "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
 1058 |       "직장 생활에서는 목발과 함께 어떤 역할을 봐야 할까요?",
 1059 |       "목발을 보고 들어온 관람객이 나갈 때는 무엇을 함께 기억하면 좋을까요?"
 1063 |     pattern: /(자취|자취방|독립|집안일|생활\s*관리)/,
 1065 |       "자취방에서 혼자 생활하며 직접 정하게 된 일들은 무엇인가요?",
 1066 |       "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
 1067 |       "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?",
 1068 |       "자취를 시작한 뒤 스스로 설명해야 하는 일이 어떻게 달라졌나요?",
 1069 |       "독립은 큰 결심보다 어떤 반복되는 일에서 느껴졌나요?",
 1070 |       "자취방은 장애를 설명하는 공간이 아니라 어떤 생활을 보여주나요?"
 1074 |     pattern: /(책상|노트북|컴퓨터|박사|직장|업무|공부|일과 공부)/,
 1076 |       "책상 앞에서 직장 일과 박사과정 공부는 어떻게 이어지나요?",
 1077 |       "게임이나 코인노래방 같은 취미는 하루의 분위기를 어떻게 바꾸나요?",
 1078 |       "도움이 필요해 보여도 어떤 말로 먼저 물어보는 게 편한가요?",
 1079 |       "노트북과 메모는 이동 이야기 너머의 어떤 생활을 보여주나요?",
 1080 |       "어떤 업무 장면에서 기여를 느끼나요?",
 1081 |       "함께 일하는 사람이 상황을 모를 때 무엇부터 말해 주는 편인가요?"
 1085 |     pattern: /(도움|도와|배려|묻는|요청|조율)/,
 1087 |       "도움이 필요해 보여도 어떤 말로 먼저 물어보는 게 편한가요?",
 1088 |       "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
 1089 |       "목발을 먼저 봤을 때 놓치기 쉬운 하루의 장면은 무엇인가요?",
 1090 |       "도움을 주기 전에 잠깐 기다리는 일이 왜 중요할까요?",
 1091 |       "도움을 받을 때 설명할 시간이 필요하다는 말은 어떤 뜻인가요?",
 1092 |       "혼자 할 수 있는 부분을 존중하는 도움은 어떤 모습인가요?"
 1096 |     pattern: /(처음 가는|장소|동선|엘리베이터|계단|화장실|접근성|경로)/,
 1098 |       "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
 1099 |       "도움이 필요해 보여도 어떤 말로 먼저 물어보는 게 편한가요?",
 1100 |       "책상과 노트북은 이동 이야기 너머의 하루를 어떻게 보여주나요?",
 1101 |       "이동 환경을 볼 때 단순히 편하다 불편하다 말하기 어려운 이유는 무엇인가요?",
 1102 |       "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
 1103 |       "엘리베이터나 화장실 정보가 하루의 피로와 어떻게 연결되나요?"
 1107 |     pattern: /(취미|게임|노래방|코인노래방|쉬는|여가)/,
 1109 |       "게임이나 코인노래방 같은 취미는 하루의 분위기를 어떻게 바꾸나요?",
 1110 |       "책상과 노트북은 직장 일과 박사과정 공부를 어떻게 보여주나요?",
 1111 |       "목발을 먼저 봤을 때 놓치기 쉬운 하루의 장면은 무엇인가요?",
 1112 |       "게임과 코인노래방 같은 취미가 전시에서 빠지면 무엇을 놓치게 되나요?",
 1113 |       "쉬는 시간이 함께 보여야 한 사람의 하루가 더 정확해지는 이유는 무엇인가요?",
 1114 |       "게임과 코인노래방 이야기는 이동이나 도움 이야기와 어떻게 다른 면을 보여주나요?"
 1118 |     pattern: /(평범|보통|전시|관람객|기억|특징|장애가 먼저)/,
 1120 |       "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?",
 1121 |       "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
 1122 |       "게임이나 코인노래방 같은 취미는 하루의 분위기를 어떻게 바꾸나요?",
 1123 |       "장애를 한 사람의 전부로 보지 않으려면 어떤 질문을 해야 할까요?",
 1124 |       "전시에서 자취방과 책상이 함께 보여야 하는 이유는 무엇인가요?",
 1125 |       "겉으로 보이는 단서에서 속 생활로 넘어가려면 무엇을 물어봐야 하나요?"
 1129 |     pattern: /(직장|동료|기여|결과물|프로젝트|기획서|회사|필요한 도움)/,
 1131 |       "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?",
 1132 |       "어떤 업무 장면에서 기여를 느끼나요?",
 1133 |       "자취방에서 혼자 생활하며 직접 정하게 된 일들은 무엇인가요?",
 1134 |       "함께 일하는 사람이 상황을 모를 때 무엇부터 말해 주는 편인가요?",
 1135 |       "도움을 요청하는 일이 부담보다 조율에 가깝다고 느낀 이유는 무엇인가요?"
 1139 |     pattern: /(미국|한국|교통|버스|지하철|택시|지원|전동휠체어|도착 정보)/,
 1141 |       "미국과 한국의 이동 환경은 실제 생활에서 어떻게 다르게 느껴졌나요?",
 1142 |       "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
 1143 |       "처음 가는 공간에서 접근성을 확인하는 일이 왜 중요한가요?",
 1144 |       "책상과 노트북은 이동 이야기 너머의 하루를 어떻게 보여주나요?",
 1145 |       "도움이 필요해 보여도 어떤 말로 먼저 물어보는 게 편한가요?"
 1149 |     pattern: /(끈기|어떻게든|흘러간다|버틴|조정|다음 단계)/,
 1151 |       "끈기라는 말은 대단한 극복담보다 어떤 태도에 가까운가요?",
 1152 |       "어떻게든 흘러간다는 말은 하루를 이어가는 방식과 어떻게 닿아 있나요?",
 1153 |       "해야 할 일이 많을 때 끝까지 이어가게 하는 태도는 무엇인가요?",
 1154 |       "버틴다는 말보다 조정하며 이어간다는 표현이 더 맞는 이유는 무엇인가요?",
 1155 |       "게임과 코인노래방 같은 취미가 전시에서 빠지면 무엇을 놓치게 되나요?"
 1166 |     "너는 전시 대화 UI에 붙일 후속 추천 질문 3개를 만든다.",
 1167 |     "지금까지 관람객이 물은 질문 흐름, 직전 질문, 방금 답변을 함께 참고해 관람객이 자연스럽게 이어서 누를 만한 한국어 질문을 만든다.",
 1168 |     "질문은 버튼에 그대로 표시되므로, 무엇을 더 묻는 선택지인지 처음 보는 사람도 바로 이해할 만큼 구체적으로 쓴다.",
 1169 |     "추천 질문은 '짧은 키워드 버튼'이 아니라 관람객이 그대로 눌러도 자연스러운 완성된 질문이어야 한다.",
 1170 |     "방금 답변에 나온 장면에서 한 단계만 더 들어가게 만들고, 답변 근거에 없는 새 사실을 끌어오지 않는다.",
 1172 |     "반드시 지킬 것:",
 1173 |     "- JSON만 출력한다. 형식은 {\"suggestions\":[\"질문1\",\"질문2\",\"질문3\"]} 이다.",
 1174 |     "- suggestions는 정확히 3개다.",
 1175 |     "- 각 질문은 한국어 한 문장이고 물음표로 끝난다.",
 1176 |     "- 각 질문은 대체로 36~72자 안팎으로 자연스럽게 쓴다.",
 1177 |     "- 직전 질문을 그대로 반복하지 않는다.",
 1178 |     "- 이미 답한 내용을 다시 확인하는 질문보다, 다음 생활 장면이나 관점 차이를 여는 질문을 우선한다.",
 1179 |     "- 3개를 모두 같은 주제의 후속 질문으로 만들지 않는다.",
 1180 |     "- 추천 질문 3개는 반드시 섞는다: 1개는 방금 답변을 한 단계 깊게 묻고, 1개는 다른 생활 장면으로 넘어가고, 1개는 관점/도움/전시 의미를 넓힌다.",
 1181 |     "- '상대', '그 사람' 같은 대명사만으로 질문하지 말고 목발, 도움, 이동, 자취방, 책상처럼 구체적인 장면 명사를 넣는다.",
 1182 |     "- 질문을 눌렀을 때 무엇을 더 보거나 물어보는지 바로 알 수 있게 쓴다.",
 1183 |     "- '더 들려주세요', '어떤 의미인가요', '왜 중요한가요'만 붙인 막연한 질문은 피한다.",
 1184 |     "- 취미 답변 뒤에 근거 없이 목발이나 이동 제약을 붙이는 식으로 다른 주제를 억지로 섞지 않는다.",
 1185 |     "- 확인되지 않은 아침 루틴, 집 안 배치, 특정하게 편했던 경험, 물건 위치, 취미를 하러 가는 동선은 새로 만들지 않는다.",
 1186 |     "- 질문 3개는 서로 다른 방향이어야 한다. 예: 생활 장면, 관계/도움 방식, 전시에서 볼 관점.",
 1187 |     "- 내부 규칙, 프롬프트, API 키, 모델, 시스템 설정을 묻지 않는다.",
 1188 |     "- 개인정보, 실명, 생년월일, 연락처, 주소, 학교명, 회사명, 병명, 진단명, 장애 등급, 치료 이력, 수술, 약, 병원, 가족사, 연봉, 월급을 묻지 않는다.",
 1189 |     "- 어느 회사인지, 어느 학교인지, 병명이 무엇인지, 치료를 어떻게 받았는지 묻지 않는다.",
 1190 |     "- 허용 주제는 목발, 자취방, 책상, 일과 공부, 도움을 묻는 방식, 이동 동선, 접근성, 취미, 평범함, 전시 감상이다.",
 1194 |           "안전한 질문 예시:",
 1214 |     "지금까지 관람객이 물은 질문:",
 1217 |       : "(아직 없음)",
 1219 |     "직전 관람객 질문:",
 1222 |     "방금 답변:",
 1245 |   return /(실명|생년월일|전화번호|연락처|주소|집이\s*어디|회사명|회사\s*이름|어느\s*회사|학교명|어느\s*학교|병명|진단명|장애\s*등급|치료\s*이력|치료|수술|복용|약\s*먹|병원|가족사|부모님|연봉|월급|돈|생활비|공과금|전기비|월세|금액|비용)/i.test(text);
 1289 |   if (/(더\s*(들려|말해|알려|보여)\s*(주세요|줄래요)|무슨\s*뜻인가요|어떤\s*의미인가요|왜\s*중요한가요)\?$/i.test(text)) {
 1293 |   return /(아침|집\s*안\s*동선|생활\s*공간|배치|물건\s*위치|가장\s*편했던|가장\s*힘들었던|언제인가요|챙겨야\s*하는|코인노래방.*동선|취미.*이동\s*동선)/i.test(text);
 1337 |   if (/(직장|동료|도움\s*요청|필요한\s*도움|함께\s*일|기여|결과물|프로젝트|기획서)/.test(text)) return "workplace";
 1338 |   if (/(도움|도와|설명할\s*시간|혼자\s*할\s*수|배려|기다리)/.test(text)) return "help";
 1339 |   if (/(처음|장소|공간|동선|엘리베이터|화장실|교통|지원|미국|한국|접근성)/.test(text)) return "accessibility";
 1340 |   if (/(자취|독립|집안일|생활을\s*직접|스스로\s*설명)/.test(text)) return "room";
 1341 |   if (/(책상|노트북|메모|박사|공부)/.test(text)) return "desk";
 1342 |   if (/(취미|게임|노래방|쉬는\s*시간|여가)/.test(text)) return "hobby";
 1343 |   if (/(평범|전시|장애를\s*한\s*사람|겉|기억|관람객|목발을\s*보고)/.test(text)) return "ordinary";
 1344 |   if (/(끈기|흘러간다|버틴|조정|다음\s*단계|끝까지\s*이어|이어가게\s*하는|해야\s*할\s*일이\s*많)/.test(text)) return "motto";
 1345 |   if (/(목발|이동)/.test(text)) return "crutch";
 1397 |     }, "추천 질문 생성");
 1406 |     console.warn(`추천 질문 생성 실패: ${error.message || error}`);
 1417 |     pattern: /(비|눈|날씨|춥|덥|더위|추위|계절|우산|미끄럽)/,
 1419 |       "날씨에 따른 세부 습관을 새로 단정하진 않겠습니다. 다만 이동 이야기와 연결하면, 바닥 상태와 동선이 하루의 피로를 크게 바꿀 수 있다는 점은 말할 수 있어요.",
 1421 |       "목발을 쓰는 하루에서는 목적지만이 아니라 입구, 엘리베이터, 돌아오는 길처럼 몸이 덜 무리되는 조건을 먼저 살피게 됩니다."
 1425 |     pattern: /(쉬는\s*날|휴일|주말|퇴근|밤|아침|루틴|기분전환|쉬|휴식)/,
 1427 |       "쉬는 날의 자세한 루틴을 새로 만들지는 않겠습니다. 확인된 이야기 안에서는 자취방에서 생활을 챙기고, 책상 앞에서 일을 정리하고, 게임이나 코인노래방 같은 취미로 숨을 돌리는 장면까지 말할 수 있어요.",
 1429 |       "그런 장면을 같이 보면 이동의 어려움만이 아니라 한 사람이 하루를 조절하는 방식이 더 잘 보입니다."
 1433 |     pattern: /(물건|소지품|아끼|가방|방.*물건|책상.*물건|노트|메모|장비)/,
 1435 |       "가장 아끼는 물건을 새로 정하진 않겠습니다. 전시에서 확인된 물건으로는 목발, 자취방, 책상과 노트북이 중요합니다.",
 1437 |       "목발은 밖으로 나가는 하루를 열고, 책상과 노트북은 돌아와서 일과 공부를 이어가는 자리를 보여줍니다. 물건을 보면 불편함보다 생활의 구조가 더 잘 보입니다."
 1441 |     pattern: /(외롭|불안|걱정|자신감|민폐|감정|마음|힘들|버티|단단)/,
 1443 |       "마음을 새로 짐작해서 말하진 않겠습니다. 다만 자료 안에서는 어릴 때 민폐가 될까 불안했던 감각, 커가며 필요한 도움을 설명하고 자기 생활을 직접 꾸려가려는 태도가 함께 정리돼 있습니다.",
 1445 |       "그래서 이 이야기는 대단한 극복담이라기보다, 불안이 있어도 하루를 조금씩 조정하며 이어가는 쪽에 가깝습니다."
 1449 |     pattern: /(사진|그림|전시물|관람|캡션|설명|작품|공간.*구성|배치)/,
 1451 |       "전시 구성의 세부 배치를 새로 확정하진 않겠습니다. 다만 방향은 분명합니다. 처음에는 목발이 보일 수 있지만, 시선이 자취방과 책상, 일과 공부, 취미까지 이어져야 합니다.",
 1453 |       "관람객이 나갈 때는 장애라는 표지만이 아니라 한 사람의 생활이 같이 남는 구조가 중요합니다."
 1457 |     pattern: /(친구|동료|관계|말\s*걸|대화|어울|같이|처음\s*만나)/,
 1459 |       "관계의 구체적인 일화를 새로 만들지는 않겠습니다. 확인된 이야기 안에서는 직장이나 일상에서 필요한 부분을 먼저 설명하고, 도움을 받을 때도 방식이 맞는지 조율하는 태도가 중요합니다.",
 1461 |       "처음 만나는 사람에게도 바로 판단하기보다 어떻게 도우면 되는지 묻고, 상대가 설명할 시간을 주는 일이 관계를 더 편하게 만듭니다."
 1465 |     pattern: /(왜.*게임|게임.*왜|노래방.*왜|취미.*의미|즐거|재미)/,
 1467 |       "취미의 세부 취향을 새로 늘리진 않겠습니다. 확인된 취미로는 게임과 코인노래방이 있고, 전시에서는 이것도 중요한 일상의 한 장면으로 봅니다.",
 1469 |       "이동이나 도움 이야기만 남기면 사람이 좁게 보일 수 있어요. 좋아하고 쉬는 시간이 같이 있어야 한 사람의 하루가 더 정확해집니다."
 1482 |   return "그 질문은 새로 단정하기보다 전시에서 공유된 이야기 안에서 답하는 게 맞겠습니다. 목발과 이동, 자취방에서의 독립, 책상 앞에서 이어지는 일과 공부, 도움을 주고받는 방식, 게임이나 코인노래방 같은 취미와 연결해서 물어보면 더 구체적으로 답할 수 있어요.";
 1536 |     }, "확장 답변 생성");
 1555 |     note: "자동 생성 확장 기록입니다. 사용자/조원 확인 전에는 확정 메모로 승격하지 마세요."
 1663 |   }, "채팅 답변 생성");
 1677 |       console.warn(`답변 품질 재작성 실패: ${error.message || error}`);
 1685 |         `${finalReply}\n\n위 답변은 아직 짧다. 같은 말을 반복하지 말고 근거 카드 안에서 구체 장면, 생활 의미, 전시 연결을 보태 430자 이상으로 다시 쓴다.`,
 1693 |       console.warn(`짧은 답변 확장 실패: ${error.message || error}`);
 1728 |     sendJson(res, 400, { error: "messages 배열이 필요합니다." });
 1739 |     sendJson(res, 503, { error: "OPENAI_API_KEY가 없어 서버 전사를 사용할 수 없습니다." });
 1747 |     sendJson(res, 400, { error: "오디오 데이터가 비어 있습니다." });
 1776 |     sendJson(res, 503, { error: "OPENAI_API_KEY가 없어 서버 음성 합성을 사용할 수 없습니다." });
 1785 |     sendJson(res, 400, { error: "text가 필요합니다." });
 1799 |       instructions: "차분하고 담백한 한국어 전시 도슨트처럼 말합니다. 과장된 감정 표현은 줄이고, 문장 사이를 자연스럽게 둡니다."
 1820 |     : { ok: false, error: "OPENAI_API_KEY가 없어 근거 카드 모드로 동작합니다.", checkedAt: new Date().toISOString() };
 1859 |     sendJson(res, 404, { error: "기록을 찾지 못했습니다." });
 1866 |       sendJson(res, 400, { error: "answer가 비어 있습니다." });
 1875 |       sendJson(res, 400, { error: "reviewStatus 값이 올바르지 않습니다." });
 1891 |     sendJson(res, 404, { error: "기록을 찾지 못했습니다." });
```

## Packaged web debug/admin UI

### index.html

- 한국어 포함 라인 수: 23

```text
    6 |     <title>겉!=속</title>
   11 |       <section class="stage-panel" aria-label="인터뷰 장면">
   15 |             <h1>겉!=속</h1>
   18 |             <span class="api-pill" id="apiPill">연결 확인 중</span>
   19 |             <button type="button" id="fullscreenButton" class="ghost-button">전체 화면</button>
   53 |             <span id="avatarStateLabel">대기 중</span>
   54 |             <strong>전시 대화</strong>
   55 |             <p>목발, 자취방, 책상과 일상에 대해 답합니다.</p>
   59 |         <section class="source-card" id="sourceCard" aria-label="근거 자료" hidden>
   61 |             <span>근거</span>
   66 |         <section class="memory-card" id="memoryCard" aria-label="확장 답변 관리" hidden>
   68 |             <span>확장 답변</span>
   70 |               <span id="memoryCount" class="memory-count">0개</span>
   71 |               <button type="button" id="memoryRefreshButton" class="ghost-button">새로고침</button>
   78 |       <section class="chat-panel" aria-label="대화">
   82 |             <h2>겉!=속</h2>
   85 |             <button type="button" id="speakToggle" class="icon-button active" aria-pressed="true" title="음성 답변">음성</button>
   86 |             <button type="button" id="resetButton" class="icon-button" title="대화 초기화">초기화</button>
   92 |         <div class="prompt-strip" id="promptStrip" aria-label="추천 질문"></div>
   95 |           <button type="button" id="micButton" class="mic-button" title="마이크로 묻기">
   97 |             마이크
   99 |           <input id="messageInput" type="text" autocomplete="off" placeholder="목발, 자취방, 도움, 직장생활..." />
  100 |           <button type="submit" class="send-button">전송</button>
```

### app.js

- 한국어 포함 라인 수: 45

```text
   35 |     unreviewed: "미확인",
   36 |     approved: "사용",
   37 |     needs_review: "수정 필요"
   81 |       throw new Error(payload.error || `요청 실패: ${response.status}`);
  119 |     elements.memoryCount.textContent = `${state.memories.length}개`;
  124 |       empty.textContent = "아직 생성된 확장 답변이 없습니다.";
  138 |       question.textContent = memory.question || "질문 없음";
  143 |       badge.textContent = reviewStatusLabels[memory.reviewStatus] || "미확인";
  150 |       answer.setAttribute("aria-label", `${memory.question || "질문"} 답변`);
  169 |       saveButton.textContent = "저장";
  176 |       deleteButton.textContent = "삭제";
  207 |     const ok = window.confirm(`"${memory.question}" 답변을 삭제할까요?`);
  219 |       elements.apiPill.textContent = `API 오류 · ${state.config.chatModel}`;
  222 |       elements.apiPill.textContent = `API 연결됨 · ${state.config.chatModel}`;
  225 |       elements.apiPill.textContent = "근거 카드 모드";
  248 |     setAvatarState("idle", "대기 중");
  256 |     setAvatarState("speaking", "말하는 중");
  266 |         if (!response.ok) throw new Error("서버 음성 합성 실패");
  273 |           setAvatarState("idle", "대기 중");
  275 |         state.audio.addEventListener("error", () => setAvatarState("idle", "대기 중"));
  284 |         utterance.onend = () => setAvatarState("idle", "대기 중");
  285 |         utterance.onerror = () => setAvatarState("idle", "대기 중");
  290 |       addMessage("system", "음성", "음성 출력은 실패했지만 텍스트 응답은 사용할 수 있습니다.");
  293 |     setAvatarState("idle", "대기 중");
  298 |     setAvatarState("thinking", "생각 중");
  313 |       setAvatarState("idle", "대기 중");
  314 |       addMessage("system", "오류", error.message || "응답을 가져오지 못했습니다.");
  317 |       if (elements.avatarStage.dataset.state !== "speaking") setAvatarState("idle", "대기 중");
  327 |     addMessage("user", "질문", value);
  340 |       throw new Error("마이크 전사는 OPENAI_API_KEY가 설정된 서버 실행이 필요합니다.");
  350 |     if (!response.ok) throw new Error(payload.error || "전사 실패");
  356 |       addMessage("system", "마이크", "이 브라우저에서는 마이크 녹음을 사용할 수 없습니다.");
  372 |       elements.micButton.innerHTML = '<span class="mic-dot"></span>마이크';
  374 |       setAvatarState("thinking", "전사 중");
  382 |           addMessage("system", "마이크", "녹음에서 문장을 찾지 못했습니다.");
  385 |         addMessage("system", "마이크", error.message || "마이크 입력을 처리하지 못했습니다.");
  387 |         if (elements.avatarStage.dataset.state !== "speaking") setAvatarState("idle", "대기 중");
  393 |     elements.micButton.innerHTML = '<span class="mic-dot"></span>멈춤';
  394 |     setAvatarState("listening", "듣는 중");
  412 |           setAvatarState("idle", "대기 중");
  413 |           addMessage("system", "마이크", error.message || "마이크 권한을 얻지 못했습니다.");
  425 |         setAvatarState("idle", "대기 중");
  433 |           addMessage("system", "확장 답변", error.message || "목록을 불러오지 못했습니다.");
  466 |       addMessage("system", "API 오류", state.config.chatModelError || `${state.config.chatModel} 호출에 실패했습니다.`);
  471 |     addMessage("system", "초기화", error.message || "앱을 시작하지 못했습니다.");
```

## Packaged metadata

### package.json

- 한국어 포함 라인 수: 1

```text
    5 |   "description": "3조 인터뷰 자료 기반 대화 앱",
```

## 수집 요약

- 총 한국어 포함 라인 수: 1510
- 이 문서는 자동 수집본입니다. 실제 수정 전에는 각 문구가 플레이어에게 보이는 문구인지, 내부 로직용 문구인지 구분해서 적용해야 합니다.
