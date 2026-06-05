# Steam Released Game UI Benchmark

작성일: 2026-05-25

대상: `Interviewee1UnityAvatarChat`

## 조사 기준

Steam에 실제 출시된 게임 중에서 `대화`, `인터뷰/기록 탐색`, `휴대폰/자료 UI`, `선택형 내러티브`가 강한 작품을 우선으로 봤다. 이번 앱은 전시장에서 짧게 만지는 사람책 인터뷰이므로, 복잡한 게임 루프보다 첫 화면의 장면성, 질문 선택, 지난 대화 확인, 답변 읽기 편의성을 기준으로 삼았다.

## 조사한 출시작

| 게임 | Steam URL | 가져온 UI 관찰점 |
| --- | --- | --- |
| Coffee Talk | https://store.steampowered.com/app/914800/Coffee_Talk/ | 캐릭터, 배경, 하단 대화창이 한 장면처럼 묶인다. 질문보다 사람과 분위기가 먼저 보인다. |
| VA-11 Hall-A | https://store.steampowered.com/app/447530/VA11_HallA_Cyberpunk_Bartender_Action/ | 반복 선택과 대화가 장면 안의 도구처럼 작동한다. 기능 버튼이 세계관 밖으로 튀지 않는다. |
| Eliza | https://store.steampowered.com/app/716500/Eliza/ | AI 대화 소재를 차분한 상담/세션 UI로 처리한다. 시스템 설명보다 대화 상태가 중요하다. |
| A Normal Lost Phone | https://store.steampowered.com/app/523210/A_Normal_Lost_Phone/ | 휴대폰 UI 자체가 인물 이해의 입구가 된다. 개인 기록을 보는 듯한 밀도가 있다. |
| SIMULACRA | https://store.steampowered.com/app/712730/SIMULACRA/ | 실제 기기처럼 보이는 앱 탐색이 몰입을 만든다. 보조 정보는 별도 기기 안에 넣는 편이 자연스럽다. |
| Emily is Away Too | https://store.steampowered.com/app/523780/Emily_is_Away_Too/ | 채팅 UI의 리듬과 짧은 선택지가 대화 속도를 만든다. 긴 설명보다 즉각적인 응답이 중요하다. |
| Orwell: Keeping an Eye On You | https://store.steampowered.com/app/491950/Orwell_Keeping_an_Eye_On_You/ | 조사/자료 패널은 강력하지만 너무 앞에 나오면 사람보다 시스템이 먼저 보인다. |
| Her Story | https://store.steampowered.com/app/368370/Her_Story/ | 인터뷰 기록 탐색은 매력적이지만, 전시용 앱에서는 보조 패널로 낮춰야 한다. |
| Telling Lies | https://store.steampowered.com/app/762830/Telling_Lies/ | 지난 기록을 다시 찾아보는 구조가 대화의 신뢰감을 만든다. |
| Kind Words | https://store.steampowered.com/app/1070710/Kind_Words_lo_fi_chill_beats_to_write_to/ | 짧고 부담 없는 글쓰기 UI가 감정적으로 안전한 분위기를 만든다. |
| Roadwarden | https://store.steampowered.com/app/1155970/Roadwarden/ | 긴 텍스트를 읽히게 하려면 스크롤 영역과 선택 영역의 위계가 분명해야 한다. |
| Citizen Sleeper | https://store.steampowered.com/app/1578650/Citizen_Sleeper/ | 상태와 진행이 화면 가장자리 HUD로 정리된다. 중심 장면을 방해하지 않는 정보 배치가 좋다. |
| I Was a Teenage Exocolonist | https://store.steampowered.com/app/1148760/I_Was_a_Teenage_Exocolonist/ | 기억/선택/관계가 카드처럼 시각화된다. 주제별 색 구분을 과하지 않게 쓸 수 있다. |
| The Red Strings Club | https://store.steampowered.com/app/589780/The_Red_Strings_Club/ | 대화, 사물, 선택이 같은 장면 안에서 오간다. 책상 위 물건을 질문 진입점으로 쓰는 방향과 맞다. |

## 이번 UI에 반영한 방향

1. `Coffee Talk`, `VA-11 Hall-A`, `The Red Strings Club`에서 가져온 방향: 하단 대화창을 더 명확한 비주얼노벨 대화 밴드로 정리하고, 질문 선택지를 장면 위의 작은 카드처럼 띄웠다.
2. `A Normal Lost Phone`, `SIMULACRA`, `Emily is Away Too`에서 가져온 방향: 질문 노트를 개인 기록용 보조 UI로 유지하되, 가짜 스마트폰 장식은 줄이고 관람자가 보는 탭 이름을 `질문 / 장면 / 기록`으로 바꿨다.
3. `Orwell`, `Her Story`, `Telling Lies`에서 가져온 방향: 자료 확인은 중요하지만 사람책 전시에서는 전면에 나오면 차갑다. 그래서 `근거`라는 표현을 빼고, 현재 열린 `장면`과 `기록`으로 낮췄다.
4. `Roadwarden`, `Citizen Sleeper`, `I Was a Teenage Exocolonist`에서 가져온 방향: 긴 답변, 진행 상태, 주제 구분을 한 화면에 넣되 중심 장면을 가리지 않도록 가장자리 HUD와 하단 밴드로 정리했다.
5. `Kind Words`에서 가져온 방향: 입력창과 버튼은 기능 설명보다 짧고 부담 없는 말 걸기 도구처럼 남겼다.

## 코드 변경 요약

- `Assets/Scripts/AvatarChatApp.cs`
  - 상단 타이틀을 `겉!=속 · 사람책`으로 변경.
  - 장면 분위기용 상하 시네마틱 셰이드와 선택지 도크 추가.
  - 하단 대화창을 더 큰 반투명 밴드와 그림자, 강조선으로 재구성.
  - 질문 카드 위치를 하단 대화창 위 도크에 맞춰 재배치.
  - 질문 노트 탭을 `질문 / 근거 / 지난 말`에서 `질문 / 장면 / 기록`으로 변경.
  - 관람자 화면에 보이는 `근거` 표현을 `장면`, `기록`, `자료` 톤으로 변경.

## 건드리지 않은 것

- `PixelRPG` 관련 폴더와 파일은 수정하지 않았다.
- `TextAdventure` 관련 폴더와 파일은 수정하지 않았다.
- 실행 런처의 `-force-d3d11` 안정화는 유지했다.

## 확인할 점

- 빌드 후 `질문 노트`를 열었을 때 탭 문구가 `질문 / 장면 / 기록`으로 보이는지 확인.
- 하단 대화창과 질문 카드가 겹치지 않는지 1920x1080 기준으로 확인.
- 전시장 화면에서 좌측 세션 레일이 사람을 가리지 않는지 확인.

