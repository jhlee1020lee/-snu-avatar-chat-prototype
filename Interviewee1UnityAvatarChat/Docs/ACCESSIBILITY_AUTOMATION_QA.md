# 접근성 자동 QA

- 생성 시각: 2026-06-03 11:37:23 +09:00
- 스모크 캡처: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Build\release-smoke
- 소스: C:\codex\snu_etl_downloader_portable\downloads\2026_Spring\understanding_exceptional_children\99_GroupProject\Interviewee1UnityAvatarChat\Assets\Scripts\AvatarChatApp.cs
- 자동 통과: 77
- 자동 실패: 0
- 보류: 1

이 자동 QA는 키보드 단축키 코드와 접근성 관련 스모크 캡처를 확인한다. 실제 스크린리더, Windows 고대비, 화면 확대, 보조 입력 장치 테스트를 대체하지 않는다.

| 영역 | 항목 | 상태 | 근거 |
| --- | --- | --- | --- |
| 키보드/설정 코드 | Enter 직접 입력 전송 | 통과 | 패턴 확인: KeyCode\.Return\|KeyCode\.KeypadEnter |
| 키보드/설정 코드 | Shift+Enter 줄바꿈 유지 | 통과 | 패턴 확인: KeyCode\.LeftShift\|KeyCode\.RightShift |
| 키보드/설정 코드 | Esc 닫기/일시정지 | 통과 | 패턴 확인: KeyCode\.Escape |
| 키보드/설정 코드 | 추천 질문 1번 | 통과 | 패턴 확인: KeyCode\.Alpha1\|KeyCode\.Keypad1 |
| 키보드/설정 코드 | 추천 질문 2번 | 통과 | 패턴 확인: KeyCode\.Alpha2\|KeyCode\.Keypad2 |
| 키보드/설정 코드 | 추천 질문 3번 | 통과 | 패턴 확인: KeyCode\.Alpha3\|KeyCode\.Keypad3 |
| 키보드/설정 코드 | 질문폰 열린 상태 숫자 탭 선택 | 통과 | 패턴 확인: SelectNoteTabShortcut |
| 키보드/설정 코드 | 질문폰 좌우 탭 이동 | 통과 | 패턴 확인: KeyCode\.LeftArrow\|KeyCode\.RightArrow |
| 키보드/설정 코드 | 질문폰 단축키 | 통과 | 패턴 확인: KeyCode\.Q |
| 키보드/설정 코드 | 기억장 단축키 | 통과 | 패턴 확인: KeyCode\.M |
| 키보드/설정 코드 | 기억장 카드 질문 조작 | 통과 | 패턴 확인: SubmitMemoryCardQuestion\|memory-card-action\|memoryCardButtons |
| 키보드/설정 코드 | 기억장 키보드/패드 카드 선택 | 통과 | 패턴 확인: HandleMemoryBookShortcuts\|selected-memory-card-index\|memory-book-shortcut-action |
| 키보드/설정 코드 | 기록함 단축키 | 통과 | 패턴 확인: KeyCode\.R |
| 키보드/설정 코드 | 기록함 키보드/패드 슬롯 삭제 | 통과 | 패턴 확인: HandleRecordArchiveShortcuts\|selected-record-archive-index\|record-archive-shortcut-action |
| 키보드/설정 코드 | 설정 단축키 | 통과 | 패턴 확인: KeyCode\.S |
| 키보드/설정 코드 | 정보 단축키 | 통과 | 패턴 확인: KeyCode\.I |
| 키보드/설정 코드 | 전체 화면 단축키 | 통과 | 패턴 확인: KeyCode\.F |
| 키보드/설정 코드 | 글자 확대 단축키 | 통과 | 패턴 확인: KeyCode\.Equals\|KeyCode\.Plus\|KeyCode\.KeypadPlus |
| 키보드/설정 코드 | 글자 축소 단축키 | 통과 | 패턴 확인: KeyCode\.Minus\|KeyCode\.Underscore\|KeyCode\.KeypadMinus |
| 키보드/설정 코드 | 설정 단축키 상태 감사 | 통과 | 패턴 확인: RunShortcutAction\("settings"\)\|KeyCode\.S |
| 키보드/설정 코드 | 읽기 영역 키보드 넘김 | 통과 | 패턴 확인: TryAdvanceDialoguePage\|KeyCode\.PageDown\|KeyCode\.DownArrow |
| 키보드/설정 코드 | 기록함 방향키 스크롤 | 통과 | 패턴 확인: KeyCode\.UpArrow\|KeyCode\.DownArrow |
| 키보드/설정 코드 | 읽기 영역 처음/끝 이동 | 통과 | 패턴 확인: KeyCode\.Home\|KeyCode\.End |
| 키보드/설정 코드 | 활성 읽기 영역 선택 | 통과 | 패턴 확인: GetActiveKeyboardScrollRect |
| 키보드/설정 코드 | 열린 패널 단축키 충돌 방지 | 통과 | 패턴 확인: HandleOpenPanelShortcutToggles\|HasModalShortcutBlocker |
| 키보드/설정 코드 | 패널 진입 선택 포커스 | 통과 | 패턴 확인: (?s)SelectFirstInteractable.*SetSelectedGameObject |
| 키보드/설정 코드 | 패널 닫힘 선택 포커스 해제 | 통과 | 패턴 확인: (?s)ClearSelectionIfInside.*currentSelectedGameObject.*SetSelectedGameObject |
| 키보드/설정 코드 | 파괴적 확인 기본 취소 포커스 | 통과 | 패턴 확인: (?s)Fresh Start Cancel Button.*Fresh Start Confirm Button |
| 키보드/설정 코드 | 게임패드 기본 조작 | 통과 | 패턴 확인: HandleGamepadShortcuts\|JoystickButton0 |
| 키보드/설정 코드 | 게임패드 핵심 질문 진행 | 통과 | 패턴 확인: TrySubmitLeadShortcut\|primary-question |
| 키보드/설정 코드 | 게임패드 추천 질문 선택 | 통과 | 패턴 확인: CycleSelectedLead\|selected-lead-index |
| 키보드/설정 코드 | 게임패드 취소/닫기 | 통과 | 패턴 확인: JoystickButton1\|IsCancelKeyDown |
| 키보드/설정 코드 | 게임패드 패널 열기 | 통과 | 패턴 확인: JoystickButton2\|JoystickButton3\|JoystickButton6\|JoystickButton7 |
| 키보드/설정 코드 | 마무리 카드 키보드/패드 조작 | 통과 | 패턴 확인: HandleClosingCardShortcuts\|selected-closing-index\|closing-shortcut-action |
| 키보드/설정 코드 | 게임패드 상태 감사 확장 | 통과 | 패턴 확인: note-tab\|dialogue-size-level\|Run-GamepadShortcutGuard |
| 키보드/설정 코드 | 런타임 단축키 상태 감사 | 통과 | 패턴 확인: RunSmokeKeyPress\|WriteSmokeStateReport |
| 키보드/설정 코드 | 긴 대사 페이지 넘김 | 통과 | 패턴 확인: BuildDialoguePages\|TryAdvanceDialoguePage\|AdvanceDialoguePageOrStory |
| 키보드/설정 코드 | 긴 대사 레이아웃 상태 감사 | 통과 | 패턴 확인: --smoke-expect-dialogue-scrollable\|AppendSmokeDialogueLayout |
| 키보드/설정 코드 | 캐릭터 비율 상태 감사 | 통과 | 패턴 확인: --smoke-expect-avatar-natural\|AppendSmokeAvatarLayout |
| 키보드/설정 코드 | 생각 중 문구 상태 감사 | 통과 | 패턴 확인: --smoke-expect-thinking-copy\|AppendSmokeThinkingCopy |
| 키보드/설정 코드 | 기록함 스크롤 갱신 | 통과 | 패턴 확인: RefreshRecordArchiveScroll |
| 키보드/설정 코드 | 질문폰 탭 전환 | 통과 | 패턴 확인: ShowNoteTab |
| 키보드/설정 코드 | 질문폰 근거 탭 | 통과 | 패턴 확인: BuildEvidenceNoteText |
| 키보드/설정 코드 | 질문폰 지난 말 탭 | 통과 | 패턴 확인: BuildHistoryNoteText |
| 키보드/설정 코드 | 질문폰 진행 길잡이 | 통과 | 패턴 확인: Question Phone Session Guide\|BuildQuestionPhoneGuideText\|question-guide |
| 키보드/설정 코드 | 이야기 모드 진행 버튼 | 통과 | 패턴 확인: Story Mode Next Button\|RequestStoryModeAdvance\|story-controls |
| 키보드/설정 코드 | 이야기 모드 키보드/패드 조작 | 통과 | 패턴 확인: HandleStoryModeShortcuts\|KeyCode\.Space\|JoystickButton0\|story-shortcut-action |
| 키보드/설정 코드 | 기록 삭제 취소 버튼 | 통과 | 패턴 확인: Record Archive Cancel Delete Button\|CancelPendingRecordDelete\|record-delete-cancel |
| 키보드/설정 코드 | 정보 화면 서버 상태 감사 | 통과 | 패턴 확인: ServerStatusIdleText\|about-server-status\|server-status\.tsv |
| 키보드/설정 코드 | 정보 화면 의견 폴더 버튼 | 통과 | 패턴 확인: About Feedback Folder Button\|OpenPlaytestFeedbackFolder\|FeedbackNotes |
| 키보드/설정 코드 | 움직임 줄임 저장 | 통과 | 패턴 확인: SetReducedMotionEnabled\|ReducedMotionKey |
| 키보드/설정 코드 | 로컬 답변 전용 저장 | 통과 | 패턴 확인: SetLocalAnswerOnlyEnabled\|LocalAnswerOnlyKey |
| 키보드/설정 코드 | 로컬 답변 서버 우회 | 통과 | 패턴 확인: usedLocalAnswerOnly\|서버 전송 없이 |
| 키보드/설정 코드 | 로컬 답변 마이크 전사 차단 | 통과 | 패턴 확인: 마이크 전사는 꺼져 |
| 키보드/설정 코드 | 글자 크기 저장 | 통과 | 패턴 확인: SetDialogueSizeLevel\|DialogueSizeKey |
| 키보드/설정 코드 | 5문답 풀루프 스모크 | 통과 | 패턴 확인: --smoke-submit-questions\|SmokeSubmitQuestionSequence |
| 키보드/설정 코드 | 5문답 전 마무리 잠금 | 통과 | 패턴 확인: IsCompletedFiveTurnSession\(\)\|finish-button |
| 키보드/설정 코드 | 5문답 전 마무리 안내 라벨 | 통과 | 패턴 확인: GetCompletionActionLabel\|5문답 후\|finish-button-label |
| 키보드/설정 코드 | 의견 낮은 평가 메모 요구 | 통과 | 패턴 확인: ShouldRequirePlaytestFeedbackNote\|더 다듬기, 조금 아쉬움, 문제 있음 |
| 키보드/설정 코드 | 의견 긍정 평가 5문답 요구 | 통과 | 패턴 확인: ShouldRequireCompletedPlaytestSession\|좋음, 충분함, 문제 없음 |
| 키보드/설정 코드 | 의견 긍정 평가 마무리 기록 요구 | 통과 | 패턴 확인: ShouldRequireEndingRecordForPositiveEvidence\|마무리 기록을 저장한 뒤\|endingRecordSavedThisSession |
| 키보드/설정 코드 | 의견창 플레이어 표현 | 통과 | 패턴 확인: commercialLabels\s*=\s*\{\s*"더 다듬기",\s*"조금 아쉬움",\s*"충분함"\s*\} |
| 키보드/설정 코드 | 의견 문제 단계 설명 라벨 | 통과 | 패턴 확인: 사소한 문제\|진행 방해\|진행 불가 |
| 키보드/설정 코드 | 의견창 키보드/패드 평가 조작 | 통과 | 패턴 확인: HandlePlaytestFeedbackShortcuts\|feedback-shortcut-action\|GetPlaytestFeedbackGroupLabel |
| 키보드/설정 코드 | 의견 구조화 품질 영역 | 통과 | 패턴 확인: qualityFocusArea\|GetPlaytestQualityAreas\|feedback-quality-focus |
| 키보드/설정 코드 | 의견 위험 태그와 증거 등급 | 통과 | 패턴 확인: riskTags\|evidenceTier\|feedback-evidence-tier |
| 키보드/설정 코드 | 의견 점수표 마무리 기록 반영 | 통과 | 패턴 확인: ending-record-needed\|ending-record-missing\|마무리 기록 없음 |
| 키보드/설정 코드 | 의견 마무리 기록 런타임 스모크 | 통과 | 패턴 확인: playtest-feedback-require-ending-record\.tsv\|ending-record-needed\|마무리 기록을 저장한 뒤 |
| 키보드/설정 코드 | 기록함 목록 세션 메타데이터 | 통과 | 패턴 확인: ExtractRecordMetaLabel\|record-archive-first-label\|문답.*장면 |
| 키보드/설정 코드 | 기록함 미리보기 본문 크기 | 통과 | 패턴 확인: RecordArchivePreviewBodyFontSize\s*=\s*18 |
| 키보드/설정 코드 | 기록함 미리보기 잉크 대비 | 통과 | 패턴 확인: RecordArchivePreviewBodyColor\s*=\s*new Color32\(24,\s*32,\s*46,\s*255\) |
| 키보드/설정 코드 | 기록함 미리보기 줄간격 | 통과 | 패턴 확인: RecordArchivePreviewBodyLineSpacing\s*=\s*1\.16f |
| 키보드/설정 코드 | 첫 화면 정보 버튼 | 통과 | 패턴 확인: startAboutButton\|Start About Button\|start-about-visible |
| 키보드/설정 코드 | 첫 화면 설정 버튼 | 통과 | 패턴 확인: startSettingsButton\|Settings From Start Button\|start-settings-visible |
| 키보드/설정 코드 | 첫 화면 유지 스모크 | 통과 | 패턴 확인: --smoke-keep-start |
| 키보드/설정 코드 | 소리 설정 런타임 감사 | 통과 | 패턴 확인: --smoke-sound-level\|AppendSmokeAudioState\|audio-settings |
| 키보드/설정 코드 | 답변 읽기 집중 상태 감사 | 통과 | 패턴 확인: --smoke-expect-dialogue-reading-focus\|AppendSmokeDialogueReadingFocus\|dialogue-reading-followup-dock |
| 런타임 상태 QA | Unity 런타임 스모크 증거 | 보류 | StaticOnly 모드: Unity 창을 띄우지 않기 위해 캡처/TSV 런타임 검증을 건너뜀 |
