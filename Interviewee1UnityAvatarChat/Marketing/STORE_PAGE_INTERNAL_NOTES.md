# 겉!=속 상점 페이지 내부 운영 메모

## Steam 그래픽 자산

`Marketing/SteamAssets`에 Steam 상점용 캡슐 초안이 정리되어 있습니다.

- `header_capsule_920x430.png`
- `small_capsule_462x174.png`
- `main_capsule_1232x706.png`
- `vertical_capsule_748x896.png`
- `page_background_1438x810.png`
- `library_capsule_600x900.png`
- `library_hero_3840x1240.png`
- `library_header_920x430.png`
- `library_logo_1280x720.png`
- `shortcut_icon_256x256.png`
- `professional_keyart_1920x1080.png`
- `source_keyart_1920x1080.png`

현재 캡슐은 생성형 키아트 후보를 정리한 `professional_keyart_1920x1080.png` 기반 초안입니다. `source_keyart_1920x1080.png`는 실제 빌드 기반 비교용으로 보관합니다. 최종 제출 전에는 외부 아트 리뷰와 영어 제목 병기 여부를 다시 결정합니다.

상점 스크린샷은 `Build/release-smoke`에서 검증된 최신 캡처를 `Tools/PromoteSteamScreenshots.ps1`로 승격한 11장 세트입니다. `Screenshots/SCREENSHOT_MANIFEST.tsv`에 각 컷의 원본 파일과 해시를 남깁니다.

## 트레일러 구성안

`Marketing/Trailer/trailer_animatic_60s.mp4`에 스크린샷 기반 60초 애니매틱이 있다. `Marketing/Trailer/trailer_build_capture_60s.mp4`에는 현재 빌드가 직접 캡처한 화면 기반 60초 후보가 있다. 빌드 캡처 후보는 샷별 미세 카메라 움직임, 조작 위치 표시, 낮은 실내 앰비언스 오디오를 포함한다. 최종본은 이 컷 순서를 라이브 게임 녹화로 대체한다.

- 0-5초: 조용한 방, 책상 맞은편 캐릭터, 타이틀.
- 5-15초: 질문폰과 사물 단서 확인 흐름 제시.
- 15-30초: 답변, 긴 대사창 스크롤, 기억장 장면 해금.
- 30-45초: 여섯 장면 기억장, 완성 알림, 마무리 카드.
- 45-52초: 기록함에서 오늘의 대화와 남길 문장을 다시 읽는 장면.
- 52-56초: 설정 화면과 저장 데이터 삭제 안내로 품질과 신뢰 요소를 짧게 보여줌.
- 56-60초: 제목과 한 줄 소개로 마무리.

## 가격 포지셔닝 메모

5달러 이상 가격을 설득하려면 짧은 체험형 앱이 아니라, 완성도 높은 대화 세션과 기록물, 재방문 가능한 기억장, 연결 상태와 관계없이 이어지는 기본 텍스트 대화, 개인정보 관리 기능을 전면에 보여줘야 한다. 현재 상점 페이지에서는 `짧지만 정돈된 대화 경험`, `기록으로 남는 세션`, `인터뷰 자료 기반`을 핵심 가치로 밀어야 한다.



