# 릴리즈 스모크 증거 QA

- 생성 시각: 2026-06-03 01:18:36 +09:00
- 현재 buildId: geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971
- 정규 TSV: 55
- 실패: 55
- 통과: 29

이 검증은 릴리즈 스모크 폴더에 남아 있는 예전 임시 TSV가 아니라, RunReleaseSmoke.ps1 전체 실행이 생성하는 정규 TSV만 현재 빌드 증거로 인정한다.

| 영역 | 항목 | 상태 | 근거 |
| --- | --- | --- | --- |
| 공통 증거 | story-mode.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | story-mode-shortcuts.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | story-mode-next-button.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | story-mode-direct-question-button.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | story-mode-direct-question.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | story-mode-direct-question-gamepad.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | avatar-layout.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | thinking-copy.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | server-status.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | answer-source-progress.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | memory-card-question.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | memory-book-shortcuts.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | memory-reward-toast.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | dialogue-reading-focus.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | data-policy-delete-prompt.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | data-policy-delete-button.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | accessibility-settings.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | sound-default.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | sound-small.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | sound-off.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | shortcut-settings-open.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | gamepad-shortcut-question.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | gamepad-shortcut-cancel.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | gamepad-shortcut-memory.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | gamepad-shortcut-records.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | gamepad-shortcut-settings.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | gamepad-shortcut-note-tab-next.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | gamepad-shortcut-lead-next.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | gamepad-shortcut-text-up.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | gamepad-shortcut-primary-question.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | gamepad-shortcut-selected-question.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | panel-shortcut-archive-blocks-question.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | panel-shortcut-settings-blocks-question.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | panel-shortcut-question-blocks-memory.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | panel-shortcut-memory-blocks-settings.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | panel-shortcut-archive-self-closes.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | start-utility-visible.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | start-continue-button.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | start-info-access.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | long-dialogue-layout.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | foreground-clutter-hotspot.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | foreground-clutter-memory.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | closing-card-shortcuts.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | closing-card-save-button.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | closing-card-continue-button.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | five-turn-playthrough.tsv | 실패 | state/game-title actual '겉=속!' != '겉!=속'; state/product-name actual '겉=속!' != '겉!=속'; state/build-id actual 'geot-sok-1.0-c6c35cfa-d98ee945-1784e572' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | first-impression-crutch-deep-arc.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | first-impression-desk-deep-arc.tsv | 실패 | state/build-id actual 'geot-not-equal-sok-1.0-7d196c86-d98ee945-3c7dc9b2' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | first-impression-face-deep-arc.tsv | 실패 | state/game-title actual '겉=속!' != '겉!=속'; state/product-name actual '겉=속!' != '겉!=속'; state/build-id actual 'geot-sok-1.0-c6c35cfa-d98ee945-1784e572' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | playtest-feedback-shortcuts.tsv | 실패 | state/game-title actual '겉=속!' != '겉!=속'; state/product-name actual '겉=속!' != '겉!=속'; state/build-id actual 'geot-sok-1.0-c6c35cfa-d98ee945-1784e572' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | playtest-feedback-require-note.tsv | 실패 | state/game-title actual '겉=속!' != '겉!=속'; state/product-name actual '겉=속!' != '겉!=속'; state/build-id actual 'geot-sok-1.0-c6c35cfa-d98ee945-1784e572' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | playtest-feedback-require-complete-session.tsv | 실패 | state/game-title actual '겉=속!' != '겉!=속'; state/product-name actual '겉=속!' != '겉!=속'; state/build-id actual 'geot-sok-1.0-c6c35cfa-d98ee945-1784e572' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | playtest-feedback-require-ending-record.tsv | 실패 | state/game-title actual '겉=속!' != '겉!=속'; state/product-name actual '겉=속!' != '겉!=속'; state/build-id actual 'geot-sok-1.0-c6c35cfa-d98ee945-1784e572' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | record-delete-confirm.tsv | 실패 | state/game-title actual '겉=속!' != '겉!=속'; state/product-name actual '겉=속!' != '겉!=속'; state/build-id actual 'geot-sok-1.0-c6c35cfa-d98ee945-1784e572' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 공통 증거 | record-archive-shortcuts.tsv | 실패 | state/game-title actual '겉=속!' != '겉!=속'; state/product-name actual '겉=속!' != '겉!=속'; state/build-id actual 'geot-sok-1.0-c6c35cfa-d98ee945-1784e572' != 'geot-not-equal-sok-1.0-11c7d144-2457467c-6654f971' |
| 첫 화면 | 첫 30초 목표 문구 | 통과 | start-utility-visible.tsv 필수 상태 통과 |
| 첫 화면 | 첫 인상 겉/속 연결 | 통과 | start-utility-visible.tsv 필수 상태 통과 |
| 첫 화면 | 이어하기 버튼 복귀 | 통과 | start-continue-button.tsv 필수 상태 통과 |
| 핵심 루프 | 장면 버튼 상태 안내 | 통과 | start-utility-visible.tsv 필수 상태 통과 |
| 핵심 루프 | 빈 태도 마무리 문장 | 통과 | start-utility-visible.tsv 필수 상태 통과 |
| 핵심 루프 | 5턴 플레이스루 | 통과 | five-turn-playthrough.tsv 필수 상태 통과 |
| 핵심 루프 | 마무리 카드 단축키 | 통과 | closing-card-shortcuts.tsv 필수 상태 통과 |
| 핵심 루프 | 마무리 저장 버튼 | 통과 | closing-card-save-button.tsv 필수 상태 통과 |
| 핵심 루프 | 마무리 계속 버튼 | 통과 | closing-card-continue-button.tsv 필수 상태 통과 |
| 핵심 루프 | 목발 첫인상 깊은 기록 | 통과 | first-impression-crutch-deep-arc.tsv 필수 상태 통과 |
| 핵심 루프 | 책상 첫인상 깊은 기록 | 통과 | first-impression-desk-deep-arc.tsv 필수 상태 통과 |
| 핵심 루프 | 표정 첫인상 깊은 기록 | 통과 | first-impression-face-deep-arc.tsv 필수 상태 통과 |
| 피드백 | 부정/수정 의견 메모 요구 | 통과 | playtest-feedback-require-note.tsv 필수 상태 통과 |
| 피드백 | 긍정 평가 5문답 요구 | 통과 | playtest-feedback-require-complete-session.tsv 필수 상태 통과 |
| 피드백 | 긍정 평가 마무리 기록 요구 | 통과 | playtest-feedback-require-ending-record.tsv 필수 상태 통과 |
| 접근성 | 설정 토글 | 통과 | accessibility-settings.tsv 필수 상태 통과 |
| 읽기 | 대화 읽기 집중 모드 | 통과 | dialogue-reading-focus.tsv 필수 상태 통과 |
| 개인정보 | 저장 삭제 버튼 확정 | 통과 | data-policy-delete-button.tsv 필수 상태 통과 |
| 기록 | 삭제 확인 2단계 | 통과 | record-delete-confirm.tsv 필수 상태 통과 |
| 기억 카드 | 카드에서 질문 진입 | 통과 | memory-card-question.tsv 필수 상태 통과 |
| 보상 | 장면 보상 토스트 | 통과 | memory-reward-toast.tsv 필수 상태 통과 |
| 서버/근거 | 서버 상태 표시 | 통과 | server-status.tsv 필수 상태 통과 |
| 서버/근거 | 내장 답변 출처 표시 | 통과 | answer-source-progress.tsv 필수 상태 통과 |
| 스토리 | 이야기 모드 진입 | 통과 | story-mode.tsv 필수 상태 통과 |
| 스토리 | 이야기 모드 단축키 | 통과 | story-mode-shortcuts.tsv 필수 상태 통과 |
| 스토리 | 이야기 모드 다음 버튼 전환 | 통과 | story-mode-next-button.tsv 필수 상태 통과 |
| 스토리 | 이야기 모드 버튼 직접 질문 전환 | 통과 | story-mode-direct-question-button.tsv 필수 상태 통과 |
| 스토리 | 이야기 모드 직접 질문 전환 | 통과 | story-mode-direct-question.tsv 필수 상태 통과 |
| 스토리 | 이야기 모드 패드 직접 질문 전환 | 통과 | story-mode-direct-question-gamepad.tsv 필수 상태 통과 |
