# 왜 아직 구려 보이는가

작성일: 2026-05-25

## 지금 가장 큰 원인

현재 화면이 구려 보이는 핵심은 기능이 부족해서가 아니라, 기본 화면에 앱/디버그 UI 신호가 너무 많이 보였기 때문이다.

- 상단 상태 문구가 `로컬 답변만 사용`, `대화 준비됨`처럼 관리 화면처럼 보였음.
- 하단 입력줄이 `직접 묻기 + 전사 꺼짐 + 전송` 구조라 게임 대화창보다 웹 채팅 폼처럼 보였음.
- 대화창 안의 `가-`, `가+` 버튼이 접근성 기능이라도, 기본 화면에서는 개발용 조작 버튼처럼 보였음.
- `기억장 0/6` 같은 문구는 기능명은 정확하지만, 전시 장면에서는 시스템 카운터처럼 느껴졌음.

## 이번에 줄인 것

- 상단 상태 문구는 내부 상태 기록용으로만 남기고 기본 화면에서는 보이지 않게 함.
- `기억장 0/6`을 `장면 0/6`으로 바꿔 시스템 기능명 느낌을 줄임.
- 기본 대화창의 `가-`, `가+` 버튼은 숨김. 글자 크기 조절은 설정창에 남아 있음.
- 로컬 답변 모드에서는 `전사 꺼짐` 마이크 버튼이 보이지 않게 함.
- 하단 입력줄은 `물어볼 말을 적어 주세요`와 `묻기`로 바꿈.
- 첫 대사를 짧게 줄여 설명문 느낌을 줄임.
- 자유 질문 입력칸은 기본 화면에서 숨기고, `직접 묻기`를 누를 때만 열리게 함.
- 질문 제출 후 자유 입력칸은 다시 접히게 함.
- 아바타 PNG import를 읽기 가능, 무압축, mipmap 없음으로 바꿔 가장자리 정리 코드가 실제로 돌게 함.
- 상단 `질문 노트`는 접힌 종이 탭 형태로 바꿈.
- 상단 `장면 0/6`은 어두운 책갈피 형태로 바꿈.
- `직접 묻기`는 펜이 붙은 작은 메모 탭 형태로 바꿈.
- 하단 대화창을 검은 사각 패널에서 어두운 받침판, 따뜻한 종이 캡션, 황동 이름표, 모서리 브라켓이 있는 전시 명찰형 프레임으로 바꿈.
- 대사 텍스트를 흰색에서 종이 위의 짙은 잉크색으로 바꿈.
- 대화창 프레임을 바꾸면서 줄어든 읽기 영역을 다시 120px 높이로 맞춤.
- 선택지 3개를 어두운 버튼 카드에서 책상 위 종이 단서 쪽지 형태로 바꿈.
- 선택지 뒤의 검은 도크를 약한 받침선/레일 정도로 줄임.
- 아바타 뒤에 부드러운 배경 그림자, 아래쪽에 접촉 그림자를 추가해 배경 위에 PNG만 얹은 느낌을 줄임.
- 아바타 호흡 애니메이션에 맞춰 그림자도 아주 작게 반응하게 해 캐릭터와 공간이 따로 노는 느낌을 줄임.
- 질문 노트 내부의 기본 둥근 사각형 탭/주제 버튼을 인덱스 플래그와 작은 메모 쪽지 형태로 바꿈.
- 질문 노트의 스마트폰 하드웨어 디테일이 비어 보이지 않도록 카메라 영역과 홈 인디케이터를 은은하게 보이게 함.
- `방금 답변 더 듣기`, `마무리` 버튼도 기본 버튼 대신 노트 하단 액션 라벨처럼 보이게 바꿈.
- 기억장 페이지에 바인딩 링, 책등, 페이지 가이드 라인, 황동 레일을 추가해 큰 모달 패널 느낌을 줄임.
- 기억장 6개 장면 카드를 테이프, 인덱스 탭, 핀, 줄무늬가 있는 스크랩북 카드처럼 바꿈.
- 기억장 하단 완료 배지와 닫기 버튼도 질문 노트와 같은 라벨/소품 톤에 맞춤.
- 마무리 카드의 인용문 영역을 별도 종이 조각처럼 분리하고 테이프/줄무늬/스파인 디테일을 추가함.
- 마무리 카드 선택지를 기본 버튼에서 작은 선택 태그로 바꿈.
- 마무리 카드의 저장/계속/닫기/의견 버튼을 질문 노트와 같은 하단 라벨 버튼 톤으로 맞춤.
- 마무리 요약 패널을 초록 앱 카드에서 메모 쪽지 톤으로 바꾸고 클립 디테일을 추가함.
- 대화 캡션, 질문 노트, 단서 미리보기, 기억장, 마무리 카드의 주요 종이 패널에 절차적 종이결/작은 얼룩 질감 스프라이트를 적용해 너무 매끈한 코드 도형 느낌을 줄임.
- 하단 대화창의 검은 받침판이 너무 크고 비어 보여 앱 패널처럼 보이던 문제를 줄이기 위해 패널 높이와 색을 낮추고, 종이 캡션 면적을 키움.
- 선택지 뒤에 화면 전체를 가로지르던 반투명 트레이와 하단 시네마 쉐이드를 제거해 배경과 캐릭터가 HUD 띠에 눌려 보이는 문제를 줄임.
- 배경 위의 큰 금색 원형 핫스팟을 작은 황동 핀 형태로 줄이고 펄스 강도를 낮춰 모바일 튜토리얼 버튼처럼 보이는 문제를 줄임.
- 캐릭터 하단에 전경 책상 오클루전, 접촉 그림자, 책상 윗선 레이어를 추가해 캐릭터가 배경 위에 단순히 붙어 있는 합성감을 줄임.
- 질문 카드에 긴 질문 문장을 그대로 노출하던 방식을 줄이고, 화면에는 `평범한 하루`, `처음 가는 공간`, `도움 받는 방식` 같은 짧은 카드 제목만 보이게 함. 실제 클릭 시 제출되는 질문 내용은 유지함.
- 짧아진 질문 제목에 맞춰 카드 폭과 간격을 줄여, 빈 UI 막대처럼 보이던 느낌을 줄이고 책상 위 작은 단서 쪽지처럼 보이게 함.
- 배경 위 핫스팟 핀의 기본 알파, 크기, 펄스 강도를 더 낮춰 주황색 튜토리얼 점처럼 보이던 문제를 줄임. 클릭 영역과 단서 미리보기 기능은 유지함.
- 기본 대화 화면의 상단 왼쪽 제목/밑줄 HUD를 제거함. 제목은 시작 화면에 이미 있으므로, 플레이 중에는 배경과 인물에 시선이 남도록 함.
- 하단 대화창의 어두운 받침판과 그림자 불투명도를 낮추고, `0/5 질문` 진행 HUD를 기본 화면에서 숨김. 대화창이 앱 패널보다 책상 위 종이 캡션처럼 보이도록 함.
- 우상단 `장면 0/6`, `질문 노트` 버튼을 `장면`, `질문`의 작은 반투명 종이 탭으로 줄임. 장면 카운터는 기억장/질문 노트 내부에만 남겨 기본 화면의 관리 UI 느낌을 줄임.
- 아바타 PNG 컷아웃 가장자리에 1차 알파 페더와 따뜻한 색 보정을 넣어 머리/어깨 외곽의 스티커감을 줄임.
- 아바타 크기와 그림자 강도를 살짝 낮춰 배경 대비가 너무 세게 튀는 문제를 줄임.
- 하단 대화판의 폭/높이/불투명도를 줄이고 질문 쪽지를 대화판 윗선에 붙여, 화면 중앙에 떠 있는 UI 카드 느낌을 줄임.
- 기본 질문 쪽지 3개의 번호와 강한 주황 원형 마커를 제거하고 크기/알파를 낮춤. 캐릭터 손 위에 떠 있는 모바일 튜토리얼 버튼처럼 보이던 문제를 줄임.
- 배경 전체의 따뜻한 워시를 줄여 화면이 한 가지 베이지 톤으로 뭉개지는 느낌을 완화함.
- 하단 대화판의 어두운 받침판, 그림자, 모서리 장식, 이름표, 직접 묻기 탭의 알파와 크기를 더 낮춤. 앱 하단 패널보다 얇은 종이 캡션처럼 보이도록 함.
- 첫 대사를 더 짧게 줄여 설명문/튜토리얼 문장처럼 보이는 문제를 줄임.
- 질문 노트의 검은 스마트폰 노치, 카메라 점, 홈 인디케이터, 진한 외곽 그림자를 낮추고 전체를 살짝 기울인 종이 메모장처럼 조정함.
- 질문 노트 하단 액션 버튼과 진행 배지도 낮은 알파로 바꿔 앱 버튼처럼 튀는 문제를 줄임.
- 시작 화면의 큰 검은 하단 밴드와 흰 대형 랜딩 페이지 텍스트를 밝은 종이 패널/짙은 잉크 텍스트로 바꿈.
- 시작 화면 버튼 묶음을 본 화면의 종이/황동 톤으로 맞추고, 아바타 크기/색/그림자도 본 화면과 같은 통합감으로 조정함.
- 시작 화면 종이 패널을 화면 전체 하단 폭에서 왼쪽 책상 위 작은 카드 폭으로 줄임. 우측 하단에 흩어져 있던 기능 버튼도 같은 카드 안으로 모아 첫 화면의 앱 메뉴 느낌을 줄임.
- 시작 카드 안의 버튼 밀도를 다시 낮춤. `기록`, `설정`, `정보`, `종료`는 작은 링크형 종이 라벨로 낮추고, 저장 파일이 없을 때 보이던 `이어하기 없음` 비활성 버튼은 숨겨 메뉴판 느낌을 줄임.
- 기본 대화 캡션의 폭/높이와 어두운 받침판 불투명도를 더 낮춰 화면 아래가 큰 앱 패널처럼 보이는 문제를 줄임.
- 시작 화면에도 본 화면과 같은 전경 책상 오클루전/접촉 그림자 레이어를 적용해, 아바타가 배경 위에 붙은 스티커처럼 보이는 문제를 줄임.
- 배경 전체의 따뜻한 워시를 더 낮추고 좌우에 어두운 깊이 레이어, 중앙에 약한 초점 조명을 추가함. 방 전체가 같은 베이지 밝기로 떠서 초점이 약한 문제를 줄임.
- 시작 카드 아래에 얕은 그림자를 추가해, 반투명 종이 카드가 배경 위에 평면으로 붙어 보이는 문제를 줄임.
- 전경 책상 레이어의 긴 사각 하이라이트/그림자선을 부드러운 타원형 빛/그림자로 바꿈. 화면을 가로지르는 UI 구분선처럼 보이던 문제를 줄임.
- 시작 카드의 종이 불투명도와 그림자를 올리고, 대화 캡션 종이 아래에도 얕은 드롭 섀도를 추가함. 반투명 박스가 아니라 책상 위 종이 조각처럼 보이도록 함.
- 기본 질문 선택지 3개가 같은 높이/폭의 버튼 줄처럼 보이던 문제를 줄이기 위해, 각 쪽지의 위치, 폭, 높이, 회전값을 다르게 배치하고 별도 부드러운 그림자를 추가함.
- 질문 선택지 쪽지의 종이 불투명도, 테이프 각도, 접힌 모서리 디테일을 조정해 웹 버튼보다 책상 위 단서 쪽지처럼 보이게 함.
- 제목은 `겉!=속`인데 장면 안에는 이동/목발의 흔적이 거의 없어 일반 공부방처럼 보이던 문제를 줄이기 위해, 오른쪽 의자 옆에 은은한 목발 실루엣 소품을 추가함.
- 목발 소품에 별도 클릭 단서를 연결해 `목발은 일상에서 어떤 의미가 있나요?` 질문으로 이어지게 함. 단, 기본 화면에서는 설명 텍스트 없이 장면 소품으로만 보이게 함.
- 기본 질문 쪽지가 정적인 버튼처럼 굳어 보이는 문제를 줄이기 위해, 각 쪽지에 아주 작은 독립 흔들림과 hover 시 살짝 떠오르는 반응을 추가함.
- `움직임 줄임` 설정이 켜져 있거나 질문 노트가 열려 있을 때는 질문 쪽지 움직임을 원래 위치/각도/크기로 되돌리게 함.

## 아직 남은 문제

- 캐릭터와 배경 자체가 한 장 이미지 기반이라, AAA/VN 상업작처럼 깊이감 있는 연출은 아직 약함.
- 아바타 머리 외곽은 많이 부드러워졌지만, 원본 PNG 자체가 완전한 레이어드 일러스트가 아니라서 확대하면 컷아웃 흔적이 남음.
- 질문 노트, 기억장, 마무리 카드가 모두 코드로 그린 UI라 손맛은 정리됐지만 브랜드 아트/전용 프레임 느낌은 부족함.
- 코드로 만든 종이/책갈피/펜 오브젝트라 이전보다는 낫지만, 실제 아트 에셋만큼 자연스럽지는 않다.
- 대화창도 전시 명찰형으로 바꿨지만, 여전히 코드 도형 기반이라 실제 작화된 UI 프레임만큼 고급스럽지는 않다.
- 선택지도 짧은 종이 단서 제목처럼 바꾸고 뒤의 HUD 트레이는 걷어냈지만, 아직 완전한 소품 일러스트가 아니라 UI 도형 조합이다.
- 질문 쪽지는 덜 튀게 만들었지만, 작아진 만큼 클릭 가능한 항목이라는 신호는 전보다 약하다. 이후에는 hover/선택 상태에서만 약하게 강조하는 방식이 더 좋다.
- 하단 대화판은 많이 가벼워졌지만, 여전히 코드 도형으로 만든 종이라 실제 작화된 대화창 UI만큼 고급스럽지는 않다.
- 질문 노트는 스마트폰보다 종이 메모장에 가까워졌지만, 여전히 코드로 만든 패널이라 실제 소품 사진/일러스트만큼 자연스럽지는 않다.
- 시작 화면도 검은 랜딩 페이지 느낌은 줄었지만, 아직 전용 타이틀 아트나 실제 인쇄물 에셋이 아니라 코드 생성 종이 패널이다. 현재 구조에서는 상업 게임 첫 화면이라기보다 전시용 인터랙티브 키오스크에 가까운 톤이다.
- 이번에 장면 대비와 그림자를 보강했지만, 배경과 아바타가 각각 완성된 별도 PNG인 구조는 그대로라 조명 방향/붓터치/렌즈감이 완전히 일치하지는 않는다.
- 목발 실루엣은 장면 주제성을 보강하지만, 아직 코드 도형으로 만든 임시 소품이다. 전시용으로 더 고급스럽게 보이려면 실제 목발/지팡이 전경 에셋이나 배경 재작화가 필요하다.
- 질문 쪽지에 미세한 움직임을 넣었지만, 근본적으로는 코드 UI 오브젝트다. 실제 종이가 책상 위에 놓인 느낌은 전용 이미지 에셋이 있어야 더 자연스럽다.
- 화면을 가르던 긴 선은 줄였지만, 전경 책상 레이어도 코드로 만든 반투명 도형이라 실제 책상 오브젝트 레이어만큼 자연스럽지는 않다.
- 질문 선택지는 버튼 줄 느낌은 줄었지만, 아직 실제 촬영/작화된 종이 에셋이 아니라 코드 도형 쪽지다. 클릭 가능한 소품과 실제 소품 사이의 경계가 남아 있다.
- 시작 카드가 작아진 대신 오른쪽 배경 여백이 많아졌다. 이후에는 컵/노트/목발 같은 전용 전경 소품을 배치하면 더 자연스럽다.
- 그림자와 전경 책상 레이어가 들어가도 캐릭터와 배경을 분리한 원본 아트 레이어가 아니기 때문에, 실제 책상 전경/의자/조명에 맞춘 전용 합성만큼 자연스럽지는 않다.
- 질문 노트 내부는 소품 톤에 더 가까워졌지만, 여전히 실제 휴대폰/노트 이미지를 쓴 것이 아니라 UI 도형을 조합한 것이다.
- 기억장도 스크랩북 톤에 가까워졌지만, 실제 촬영 종이나 손으로 그린 카드 에셋은 아직 없다.
- 마무리 카드도 소품 톤과 질감을 넣었지만, 전용 인쇄물 아트가 아니라 코드에서 생성한 절차적 질감이라는 한계는 남아 있다.

## 다음 개선 우선순위

1. 코드로 만든 종이/책갈피/펜/대화창 프레임을 실제 전용 이미지 에셋으로 교체하기.
2. 캐릭터 원본을 배경 조명에 맞는 전용 컷아웃/레이어드 아트로 다시 만들기.
3. 캐릭터를 정적인 PNG 교체가 아니라 미세 표정/시선/호흡 레이어로 움직이게 만들기.
4. 실제 종이, 테이프, 금속 클립, 버튼 프레임을 전용 이미지 에셋으로 교체해 코드 도형 느낌을 더 줄이기.

## 이번 검증

빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-scene-clue-slips-build.log
```

스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-clue-slips-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-clue-slips-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-clue-slips-long.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-clue-slips-state.tsv
```

결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 질문 노트 화면 실행 ExitCode 0
- 긴 답변 스크롤 실행 ExitCode 0
- 아바타 비율/크기 검증 PASS
- 대화 뷰포트 높이 120px 확인
- 아바타 읽기 권한 경고 사라짐

추가 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-avatar-integration-build.log
```

추가 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-integration-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-integration-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-integration-long.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-integration-state.tsv
```

추가 결과:

- Unity 빌드 ExitCode 0
- 시작 화면 실행 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 긴 답변 스크롤 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 아바타 비율/크기 검증 PASS

마무리 카드 소품화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-closing-keepsake-build.log
```

마무리 카드 소품화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-closing-keepsake-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-closing-keepsake-empty.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-closing-keepsake-filled.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-closing-keepsake-long.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-closing-keepsake-state.tsv
```

마무리 카드 소품화 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 빈 마무리 카드 화면 실행 ExitCode 0
- 기억장이 채워진 마무리 카드 화면 실행 ExitCode 0
- 긴 답변 스크롤 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 아바타 비율/크기 검증 PASS

기억장 스크랩북화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-memory-scrapbook-build.log
```

기억장 스크랩북화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-scrapbook-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-scrapbook-empty.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-scrapbook-filled.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-scrapbook-long.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-scrapbook-state.tsv
```

기억장 스크랩북화 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 빈 기억장 화면 실행 ExitCode 0
- 채워진 기억장 화면 실행 ExitCode 0
- 긴 답변 스크롤 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 아바타 비율/크기 검증 PASS

질문 노트 소품화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-notebook-props-build.log
```

질문 노트 소품화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-notebook-props-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-notebook-props-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-notebook-props-evidence.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-notebook-props-long.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-notebook-props-state.tsv
```

질문 노트 소품화 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 질문 노트 화면 실행 ExitCode 0
- 질문 노트 장면 탭 화면 실행 ExitCode 0
- 긴 답변 스크롤 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 아바타 비율/크기 검증 PASS

종이 질감 보강 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-paper-texture-build.log
```

종이 질감 보강 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-paper-texture-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-paper-texture-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-paper-texture-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-paper-texture-memory.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-paper-texture-closing.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-paper-texture-state.tsv
```

종이 질감 보강 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 질문 노트 화면 실행 ExitCode 0
- 단서 미리보기 화면 실행 ExitCode 0
- 기억장 화면 실행 ExitCode 0
- 마무리 카드 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 캡처 5장 모두 1920x1080 생성 확인
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

하단 대화창/선택지/HUD 정리 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-hotspot-pins-build.log
```

하단 대화창/선택지/HUD 정리 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-pins-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-pins-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-pins-state.tsv
```

하단 대화창/선택지/HUD 정리 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 단서 미리보기 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본/단서 미리보기 캡처 2장 모두 1920x1080 생성 확인
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

전경 책상 레이어 보강 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-foreground-desk-build.log
```

전경 책상 레이어 보강 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-foreground-desk-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-foreground-desk-state.tsv
```

전경 책상 레이어 보강 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본 캡처 1920x1080 생성 확인
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

질문 카드 제목화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-lead-card-titles-fix-build.log
```

질문 카드 제목화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-lead-card-titles-fix-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-lead-card-titles-fix-state.tsv
```

질문 카드 제목화 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본 캡처 1920x1080 생성 확인
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

질문 카드 컴팩트화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-lead-card-compact-build.log
```

질문 카드 컴팩트화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-lead-card-compact-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-lead-card-compact-state.tsv
```

질문 카드 컴팩트화 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본 캡처 1920x1080 생성 확인
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

핫스팟 핀 저채도화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-hotspot-subtle2-build.log
```

핫스팟 핀 저채도화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-subtle2-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-subtle2-preview.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-subtle2-state.tsv
```

핫스팟 핀 저채도화 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 핫스팟 미리보기 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본/핫스팟 미리보기 캡처 2장 모두 1920x1080 생성 확인
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

상단 제목 HUD 제거 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-title-hidden-final-build.log
```

상단 제목 HUD 제거 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-title-hidden-final-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-title-hidden-final-state.tsv
```

상단 제목 HUD 제거 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본 캡처 1920x1080 생성 확인
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

대화창 종이 캡션화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-dialogue-paper-final-build.log
```

대화창 종이 캡션화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-paper-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-paper-state.tsv
```

대화창 종이 캡션화 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본 캡처 1920x1080 생성 확인
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

우상단 소품 탭 축소 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-top-tabs-final2-build.log
```

우상단 소품 탭 축소 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-tabs-final2-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-tabs-final2-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-tabs-final2-state.tsv
```

우상단 소품 탭 축소 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 질문 노트 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본/질문 노트 캡처 2장 모두 1920x1080 생성 확인
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

아바타/대화판 통합감 개선 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-integration-soften-build.log
```

아바타/대화판 통합감 개선 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-integration-soften-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-integration-soften-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-integration-soften-state.tsv
```

아바타/대화판 통합감 개선 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 질문 노트 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본/질문 노트 캡처 2장 모두 1920x1080 생성 확인
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

질문 쪽지 저채도화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-question-slips-subtle-build.log
```

질문 쪽지 저채도화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-slips-subtle-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-slips-subtle-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-slips-subtle-state.tsv
```

질문 쪽지 저채도화 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 질문 노트 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본/질문 노트 캡처 2장 모두 1920x1080 생성 확인
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

하단 종이 캡션 경량화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-dialogue-caption-thin2-build.log
```

하단 종이 캡션 경량화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-caption-thin2-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-caption-thin2-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-caption-thin2-state.tsv
```

하단 종이 캡션 경량화 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 질문 노트 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본/질문 노트 캡처 2장 모두 1920x1080 생성 확인
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

질문 노트 종이화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-note-paper-build.log
```

질문 노트 종이화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-paper-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-paper-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-paper-state.tsv
```

질문 노트 종이화 결과:

- Unity 빌드 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 질문 노트 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 기본/질문 노트 캡처 2장 모두 1920x1080 생성 확인
- 질문 노트 열림 검증 PASS
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

시작 화면 종이화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-start-paper-build.log
```

시작 화면 종이화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-paper-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-paper-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-paper-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-paper-start-state.tsv
```

시작 화면 종이화 결과:

- Unity 빌드 ExitCode 0
- 시작 화면 실행 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 시작/기본 캡처 2장 모두 1920x1080 생성 확인
- 시작 화면 열림 검증 PASS
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

시작 화면 카드 축소 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-start-card2-build.log
```

시작 화면 카드 축소 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-card2-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-card2-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-card2-state.tsv
```

시작 화면 카드 축소 결과:

- Unity 빌드 ExitCode 0
- 시작 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 시작 화면 캡처 1920x1080 생성 확인
- 시작 화면 열림 검증 PASS
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

시작 화면/대화 캡션 밀도 정리 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-refine-nosave-build.log
```

시작 화면/대화 캡션 밀도 정리 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-refine-nosave-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-refine-nosave-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-refine-nosave-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-refine-nosave-state.tsv
```

시작 화면/대화 캡션 밀도 정리 결과:

- Unity 빌드 ExitCode 0
- 시작 화면 실행 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 시작/기본 캡처 2장 모두 1920x1080 생성 확인
- 시작 화면 열림 검증 PASS
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

장면 깊이/초점 정리 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-depth-build.log
```

장면 깊이/초점 정리 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-depth-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-depth-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-depth-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-depth-state.tsv
```

장면 깊이/초점 정리 결과:

- Unity 빌드 ExitCode 0
- 시작 화면 실행 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 시작/기본 캡처 2장 모두 1920x1080 생성 확인
- 시작 화면 열림 검증 PASS
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

전경 책상/종이 그림자 정리 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-soft-desk-build.log
```

전경 책상/종이 그림자 정리 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-soft-desk-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-soft-desk-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-soft-desk-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-soft-desk-state.tsv
```

전경 책상/종이 그림자 정리 결과:

- Unity 빌드 ExitCode 0
- 시작 화면 실행 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 시작/기본 캡처 2장 모두 1920x1080 생성 확인
- 시작 화면 열림 검증 PASS
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

질문 선택지 쪽지화 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-clue-slips-build.log
```

질문 선택지 쪽지화 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-clue-slips-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-clue-slips-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-clue-slips-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-clue-slips-state.tsv
```

질문 선택지 쪽지화 결과:

- Unity 빌드 ExitCode 0
- 시작 화면 실행 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 시작/기본 캡처 2장 모두 1920x1080 생성 확인
- 시작 화면 열림 검증 PASS
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

목발 소품/주제성 보강 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-mobility-prop2-build.log
```

목발 소품/주제성 보강 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-mobility-prop2-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-mobility-prop2-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-mobility-prop2-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-mobility-prop2-state.tsv
```

목발 소품/주제성 보강 결과:

- Unity 빌드 ExitCode 0
- 시작 화면 실행 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 시작/기본 캡처 2장 모두 1920x1080 생성 확인
- 시작 화면 열림 검증 PASS
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

질문 쪽지 미세 움직임 빌드:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-slip-motion-build.log
```

질문 쪽지 미세 움직임 스모크 산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-slip-motion-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-slip-motion-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-slip-motion-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-slip-motion-state.tsv
```

질문 쪽지 미세 움직임 결과:

- Unity 빌드 ExitCode 0
- 시작 화면 실행 ExitCode 0
- 기본 화면 실행 ExitCode 0
- 상태 검증 실행 ExitCode 0
- 시작/기본 캡처 2장 모두 1920x1080 생성 확인
- 시작 화면 열림 검증 PASS
- 관련 오류/경고 로그 없음
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS

## 2026-05-26 추가 패스: UI 박스감과 소품 합성감 완화

이전 캡처에서 여전히 싸 보였던 직접 원인:

- 하단 대화창 바깥 프레임이 화면 전체 UI 바처럼 읽혔다.
- 오른쪽 목발 소품이 장면 안 물건보다 반투명 선 그래픽처럼 떠 보였다.
- 상단 `장면`/`질문` 탭이 배경보다 앞에 떠 있는 앱 버튼처럼 보였다.

이번 조정:

- 하단 대화 패널 폭을 줄이고, 바깥 프레임/모서리 장식/브라스 라인의 알파를 낮춰 책상 위 종이 쪽으로 보이게 조정했다.
- 목발 소품의 선/하이라이트/고무팁/그림자 알파를 더 낮춰 배경 속 희미한 단서로 물렸다.
- 상단 `장면`/`질문` 탭의 종이/장식/글자 알파를 낮춰 화면 오른쪽 상단에서 덜 튀게 했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-paper-prop-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-paper-prop-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-paper-prop-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-paper-prop-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-paper-prop-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/기본 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 하단 대사창 장식 밀도 축소

이전 캡처에서 남은 주요 문제:

- 하단 대사창이 장면 속 메모라기보다 장식이 많은 UI 카드처럼 보였다.
- 네 모서리 장식, 강한 이름표, 여러 줄 ruled paper, 버튼 베벨이 겹쳐 저가 웹앱 같은 인상을 만들었다.
- 시작 화면을 정리한 뒤에는 본 화면의 하단 패널이 가장 먼저 튀는 요소가 됐다.

이번 조정:

- 하단 대사 패널의 폭과 높이를 조금 줄이고, 그림자와 배경 알파를 낮췄다.
- 종이 줄 수를 4개에서 2개로 줄이고 줄 알파도 절반 수준으로 낮췄다.
- 플라크 모서리 장식을 제거하고, 황동 레일/이름표/좌측 spine의 알파를 낮췄다.
- 전체 `CreateButton`의 위쪽 하이라이트와 아래쪽 음영을 낮춰 플라스틱 버튼 느낌을 줄였다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-dialogue-trim-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-trim-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-trim-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-trim-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-trim-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/메인 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음
- 이전 메인 캡처 대비 하단 대사창 영역 픽셀 변화 확인:
  - 넓은 하단 영역: 변경 픽셀 약 61.00%
  - 중앙 하단 영역: 변경 픽셀 약 85.04%

## 2026-05-26 추가 패스: 우상단 HUD 탭 약화

이전 캡처에서 남은 주요 문제:

- 본 화면 우상단의 `장면`, `질문` 탭이 계속 떠 있어 장면보다 앱 HUD처럼 읽혔다.
- 탭의 텍스트, 반투명 종이, 하단 음영이 작지만 계속 시선을 끌었다.
- 하단 대사창을 줄인 뒤에는 우상단 버튼군이 다음으로 UI 느낌을 만드는 요소가 됐다.

이번 조정:

- `장면`, `질문` 탭의 폭과 높이를 줄였다.
- 탭 배경, spine/strip, stitch, folded corner, tail 장식의 알파를 낮췄다.
- 탭 내부 ruled line 수를 줄이고 알파를 낮췄다.
- 오브젝트형 버튼 공통 하단 음영을 낮춰 작은 UI들이 플라스틱 버튼처럼 보이지 않게 했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-hud-tabs-muted-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hud-tabs-muted-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hud-tabs-muted-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hud-tabs-muted-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hud-tabs-muted-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/메인 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음
- 이전 메인 캡처 대비 우상단 HUD 영역 픽셀 변화 확인:
  - 변경 픽셀 약 14.92%

## 2026-05-26 추가 패스: 질문 노트 스마트폰 메타포 제거

이전 캡처에서 남은 주요 문제:

- `질문`을 열었을 때 패널이 노트 기능인데도 스마트폰처럼 보였다.
- `Dynamic Island`, 상태바, 홈 인디케이터 같은 형태가 전시/인터뷰 톤과 맞지 않았다.
- 스마트폰 UI는 실제 인물의 방/책상 장면보다 앱 조작감을 먼저 떠올리게 해 저가감이 커졌다.

이번 조정:

- 질문 패널의 이름과 시각 언어를 `Phone`에서 얇은 질문 노트/종이 카드 쪽으로 바꿨다.
- 패널 그림자, 외곽 보드, 종이 알파를 낮추고 크기를 조금 줄였다.
- 스마트폰 notch/status/home indicator 요소를 테이프와 종이 섬유 느낌으로 바꿨다.
- 빈 상태바 텍스트와 아이콘 텍스트는 숨겼다.
- ruled line 수를 9개에서 5개로 줄이고 알파를 낮췄다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-question-note-paper-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-note-paper-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-note-paper-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-note-paper-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-note-paper-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-note-paper-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-note-paper-open-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/메인/질문 노트 열린 상태 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 질문 노트 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음
- 이전 질문 노트 캡처 대비 우측 패널 영역 픽셀 변화 확인:
  - 변경 픽셀 약 51.49%

## 2026-05-26 추가 패스: 기억장 큰 모달 느낌 축소

이전 캡처에서 남은 주요 문제:

- `장면`을 열었을 때 기억장이 방 장면 위에 뜬 큰 앱 모달처럼 보였다.
- dim, 큰 그림자, 둥근 큰 페이지, 진한 바인더 링/라인이 겹쳐 기능창 느낌이 강했다.
- 기억장 카드는 내용보다 장식이 많아, 실제 인터뷰 장면보다 UI 팝업이 먼저 보였다.

이번 조정:

- 기억장 overlay dim과 그림자 알파를 낮췄다.
- 페이지 크기와 radius를 줄이고, 종이 알파를 낮춰 책상 위 종이 묶음처럼 보이게 했다.
- spine, binding ring, page rule, brass rail의 수와 알파를 낮췄다.
- 제목/카운터/설명 문구의 크기와 대비를 낮췄다.
- 기억 카드 크기와 장식 밀도를 줄이고, tape/tab/pin/rule 알파를 낮췄다.
- 완료 배지와 닫기 버튼도 새 페이지 크기에 맞춰 더 낮은 대비로 조정했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-memory-book-paper-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-book-paper-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-book-paper-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-book-paper-filled.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-book-paper-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-book-paper-open-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-book-paper-filled-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 메인/기억장 열림/기억장 채움 상태 캡처 생성 확인
- 기억장 열림 검증 PASS
- 기억장 채움 상태 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음
- 이전 기억장 캡처 대비 중앙 모달 영역 픽셀 변화 확인:
  - 넓은 중앙 영역: 변경 픽셀 약 91.97%
  - 내부 페이지 영역: 변경 픽셀 약 92.68%

## 2026-05-26 추가 패스: 아바타 잉크선과 직접 묻기 버튼 완화

이전 캡처에서 남은 주요 문제:

- 큰 UI 패널을 줄인 뒤에는 아바타의 검은 외곽선과 머리/옷 선이 배경보다 너무 선명하게 남았다.
- 인물이 방 안에 앉아 있다기보다 배경 위에 붙은 일러스트 컷아웃처럼 보이는 구간이 있었다.
- 하단 오른쪽 `직접 묻기` 버튼은 작지만 진한 갈색 앱 버튼처럼 계속 눈에 걸렸다.

이번 조정:

- 아바타 텍스처 처리에 `SoftenAvatarInkLines`를 추가해 매우 어두운 선을 따뜻한 어두운 갈색 쪽으로 살짝 올렸다.
- 기존 팔레트 harmonize의 dark lift를 강화하고, 내부 블러의 dark ink blend를 높였다.
- 컷아웃 edge의 알파 상한과 배경색 blend를 조정해 외곽 스티커 느낌을 줄였다.
- 메인/시작 아바타의 표시 알파를 조금 낮추고 scene wash 알파를 높였다.
- 하단 `직접 묻기`를 더 작은 `묻기` 탭으로 줄이고, 펜/배경/텍스트 알파를 낮췄다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-avatar-ink-button-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-ink-button-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-ink-button-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-ink-button-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-ink-button-memory.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-ink-button-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-ink-button-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-ink-button-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-ink-button-memory-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/메인/질문 노트/기억장 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 질문 노트 열림 검증 PASS
- 기억장 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음
- 이전 메인 캡처 대비 아바타 영역 픽셀 변화 확인:
  - 아바타 머리/몸 영역: 변경 픽셀 약 35.03%

## 2026-05-26 추가 패스: 직접 입력창 종이 톤으로 통일

이전 캡처에서 남은 주요 문제:

- 하단 `직접 묻기` 버튼은 생성 시 줄였지만, 런타임 레이아웃 갱신에서 다시 긴 문구로 되돌아갔다.
- 직접 입력을 열면 검은 입력창과 검은 `녹음` 버튼이 나타나, 전시/종이 UI 톤에서 갑자기 앱 UI로 돌아갔다.
- 기본 상태보다 직접 입력 상태가 더 싸 보이는 역전이 생겼다.

이번 조정:

- `UpdateQuestionInputLayout()`에서 닫힌 상태 문구를 `직접 묻기`가 아니라 `쓰기`로 유지하게 했다.
- 입력 중 버튼 문구는 `묻기`로 유지하고, 버튼 크기/알파가 다시 커지지 않도록 런타임 위치를 맞췄다.
- 질문 입력창 배경을 검은 박스에서 반투명 종이 패널로 바꿨다.
- 입력 텍스트/placeholder를 흰색 계열에서 어두운 종이 글자색으로 바꿨다.
- `녹음` 버튼도 검은 버튼에서 낮은 알파의 갈색 탭으로 바꿨다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-input-paper-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-paper-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-paper-input.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-paper-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-paper-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-paper-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-paper-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-paper-memory-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 메인/직접 입력/질문 노트 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 질문 노트 열림 검증 PASS
- 기억장 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음
- 이전 직접 입력 캡처 대비 하단 입력 영역 픽셀 변화 확인:
  - 변경 픽셀 약 20.42%

## 2026-05-26 추가 패스: 아바타 톤/가장자리 후처리

이전 캡처에서 남은 주요 문제:

- 아바타가 배경보다 선명하고 검은 외곽선이 강해서, 같은 방에 있는 사람보다 따로 붙인 일러스트처럼 보였다.
- 투명 배경으로 잘린 가장자리의 알파가 충분히 부드럽지 않아 머리카락과 어깨 라인이 특히 튀었다.

이번 조정:

- 런타임 아바타 텍스처 생성 단계에서 전체 팔레트의 채도와 대비를 살짝 낮추고 따뜻한 실내 조명 쪽으로 섞었다.
- 어두운 픽셀은 조금 들어 올리고 밝은 픽셀은 약하게 눌러 배경과의 톤 차이를 줄였다.
- 투명 경계 주변 픽셀의 feather와 최대 알파 제한을 강화했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-avatar-tone-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-tone-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-tone-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-tone-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-tone-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/기본 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 떠 있는 질문 쪽지 제거와 책상 단서화

이전 캡처에서 남은 주요 문제:

- 메인 화면의 세 질문 쪽지가 실제 책상 위 물건보다 UI 카드처럼 떠 보여 합성감을 키웠다.
- 질문 쪽지, 하단 대사창, 직접 묻기 버튼이 한 화면에 같이 보이면서 앱 위젯 느낌이 강했다.
- 아바타 하단과 책상 상판의 경계가 여전히 딱 잘린 이미지처럼 읽혔다.

이번 조정:

- 메인 화면의 떠 있는 lead 질문 쪽지는 숨기고, 질문은 `질문 노트`, 직접 입력, 책상 위 오브젝트 단서 핀으로 받도록 정리했다.
- 시작 대사도 "책상 위 단서"와 "질문 노트" 중심으로 바꿔 현재 조작 방식과 맞췄다.
- 오브젝트 hotspot 핀은 아주 작은 황동 핀/링으로 강화해 완전히 숨은 클릭 영역이 아니라 장면 속 단서처럼 보이게 했다.
- 아바타를 10px 낮추고 책상 전경 wash/contact/blend 알파를 올려 몸통 하단이 책상에 더 묻히게 했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-desk-clues-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-desk-clues-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-desk-clues-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-desk-clues-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-desk-clues-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/메인 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 장면 공통 질감과 아바타 내부 소프트닝

이전 캡처에서 남은 주요 문제:

- UI 쪽지는 줄었지만, 배경과 아바타가 서로 다른 생성물처럼 보이는 화풍 차이는 계속 남았다.
- 아바타의 내부 선과 머리/옷 경계가 배경보다 너무 또렷해서 중심 인물이 앞으로 떠 보였다.
- 단순히 그레인을 강하게 얹으면 밝은 벽이 지저분해져 오히려 더 싸 보일 위험이 있었다.

이번 조정:

- UI보다 아래, 배경/아바타/책상 위에만 적용되는 `Scene Shared Grain` 오버레이를 추가했다.
- 그레인 알파를 한 번 낮춰 밝은 벽에서 점이 튀지 않도록 조정했다.
- `Avatar Lens Haze`와 `Scene Lower Warmth`로 인물 주변과 책상 하단에 같은 따뜻한 공기층을 얹었다.
- 아바타 표시용 텍스처 생성 단계에 `SoftenAvatarInterior`를 추가해 내부 선명도와 검은 선의 튐을 약하게 줄였다.
- 원본 PNG 파일은 교체하지 않고 런타임 표시용 텍스처만 후처리했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-avatar-soft-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-soft-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-soft-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-soft-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-soft-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/메인 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 아바타 스케일/깊이 재조정

이전 캡처에서 남은 주요 문제:

- 아바타가 화면 중앙을 너무 크게 차지해 방 장면보다 캐릭터 PNG가 먼저 보였다.
- 원근이 완전히 맞지 않는 상태에서 인물이 클수록 합성감이 커졌다.
- 책상 뒤에 앉은 사람이라기보다 책상 위에 붙은 큰 스티커처럼 읽히는 구간이 남았다.

이번 조정:

- 아바타 표시 크기를 `884x600`에서 `820x556`으로 줄였다.
- 아바타 중심을 조금 낮춰, 상체 하단은 비슷한 책상 라인에 남기고 머리/어깨만 덜 튀게 했다.
- 시작 화면의 아바타와 그림자도 같은 크기/위치로 맞췄다.
- 그림자 크기와 알파를 줄여 캐릭터가 앞에 떠 있는 느낌을 완화했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-avatar-scale-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-scale-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-scale-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-scale-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-scale-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/메인 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 시작 화면 메뉴판 요소 제거

이전 캡처에서 남은 주요 문제:

- 시작 카드 안에 `기록/설정/정보/종료` 링크와 흐름 칩이 같이 보여 앱 설정 패널처럼 읽혔다.
- 첫 화면의 기능 안내가 많아져, 방 장면과 인터뷰 분위기보다 메뉴 조작이 먼저 보였다.
- 작은 텍스트/작은 버튼이 많을수록 저가 웹앱 같은 인상이 강해졌다.

이번 조정:

- 시작 카드의 `기록/설정/정보/종료` 유틸리티 링크를 숨겼다.
- 흐름 칩과 목표 문장을 숨기고, 제목/짧은 설명/시작 버튼만 남겼다.
- 시작 카드 높이와 폭을 줄이고, 버튼 위치를 새 카드 크기에 맞춰 다시 배치했다.
- 저장된 대화가 없을 때는 `처음부터`와 `질문 노트` 두 선택지만 보이게 했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-start-minimal-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-minimal-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-minimal-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-minimal-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-minimal-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/메인 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 시작 화면 메뉴판 느낌 축소

이전 시작 화면에서 남은 문제:

- 왼쪽 시작 카드가 너무 커서 장면보다 앱 메뉴가 먼저 보였다.
- 흐름 칩, 안내 문구, 설정/정보/종료 링크가 한 카드 안에 촘촘히 들어가 메뉴판처럼 읽혔다.
- 시작 화면 dim이 강해서 실제 방 장면의 몰입감이 약해졌다.

이번 조정:

- 시작 화면 dim 알파를 낮춰 방 장면이 더 보이게 했다.
- 시작 카드의 폭/높이와 그림자를 줄이고 종이 알파를 낮췄다.
- 제목, 설명, 목표 문구를 짧게 줄이고 카드 내부 여백을 다시 잡았다.
- 흐름 칩과 버튼 크기/위치를 줄여, 시작 조작이 장면을 덮는 UI가 아니라 책상 위 작은 메모처럼 보이게 했다.
- 저장 이어하기가 있을 때와 없을 때의 버튼 재배치도 새 카드 크기에 맞췄다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-start-note-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-note-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-note-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-note-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-note-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/기본 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 아바타와 책상 경계 합성감 완화

이전 캡처에서 남은 주요 문제:

- 캐릭터 하단이 책상 뒤에 앉아 있는 것보다 PNG가 배경 위에 얹힌 것처럼 보였다.
- 아바타 선명도와 색온도가 배경보다 앞에 떠서 화풍 차이가 더 크게 보였다.
- 시작 화면에서도 같은 아바타/책상 경계 문제가 반복됐다.

이번 조정:

- 아바타 sprite와 같은 알파 형태의 따뜻한 scene wash 레이어를 한 장 더 얹어, 배경 조명에 조금 더 묻히도록 했다.
- 아바타 애니메이션/표정 변경 시 scene wash sprite와 위치/scale도 같이 따라가도록 했다.
- 책상 전경 레이어에 `Foreground Avatar Desk Blend`를 추가해 몸통 하단과 책상 상판 경계를 더 부드럽게 덮었다.
- 시작 화면 아바타에도 같은 scene wash를 적용했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-avatar-blend-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-blend-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-blend-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-blend-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-blend-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/기본 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 책상 단서 핀과 미리보기 카드 저채도화

이전 캡처에서 남은 주요 문제:

- 장면 위 작은 금색 핫스팟들이 여전히 게임 튜토리얼용 클릭 표시처럼 읽혔다.
- 핫스팟 미리보기 카드가 중앙에 뜰 때 그림자와 버튼 대비가 강해서, 배경 속 단서보다 앱 모달처럼 보였다.
- 검은 hover 라벨은 전체 종이/방 톤에서 갑자기 UI 레이어가 튀어나오는 느낌을 만들었다.

이번 조정:

- 핫스팟 기본 원, 황동 핀, 링, 펄스의 알파와 크기를 더 낮춰 배경 소품 위의 희미한 단서처럼 보이게 했다.
- 핫스팟 펄스 애니메이션의 스케일 변화와 알파 변화를 줄여 움직이는 튜토리얼 버튼 느낌을 낮췄다.
- hover 라벨을 검은 툴팁에서 반투명 종이 라벨로 바꿨다.
- 핫스팟 미리보기의 그림자, 카드 불투명도, accent, 버튼 대비를 낮춰 장면 위에 얹힌 작은 확인 쪽지처럼 보이게 했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-hotspot-clues-soft-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-clues-soft-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-clues-soft-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-clues-soft-preview.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-clues-soft-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-clues-soft-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hotspot-clues-soft-preview-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/메인/핫스팟 미리보기 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 핫스팟 미리보기 실행 및 상태 출력 확인
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 아바타 화풍/깊이 합성감 완화

이전 캡처에서 남은 주요 문제:

- 배경은 부드러운 실내 일러스트인데 인물은 선과 명암이 또렷한 캐릭터 PNG라 중심부가 붙여 넣은 것처럼 보였다.
- 특히 머리카락, 얼굴 윤곽, 손/소매 쪽의 검은 선이 배경보다 선명해서 화풍 차이가 커졌다.
- 책상 뒤에 앉아 있는 깊이보다 아바타가 화면 위에 떠 있는 느낌이 아직 남았다.

이번 조정:

- 원본 아바타 PNG는 교체하지 않고, 런타임 표시용 텍스처 후처리만 조정했다.
- 아바타 팔레트의 따뜻한 톤 보정과 어두운 잉크선 리프트를 강화했다.
- 내부 픽셀 소프트닝을 조금 키워 머리/옷/손의 선명한 경계를 덜 튀게 했다.
- 아바타 하단부에는 책상색/따뜻한 공기층을 더 섞는 depth atmosphere 처리를 추가해 하체와 손이 책상 쪽에 묻히게 했다.
- 아바타 표시 알파, scene wash, 책상 전경 가림, 접촉 그림자를 조정해 배경과 같은 조명 아래 놓인 느낌을 강화했다.
- 시작 화면 아바타에도 같은 톤/알파 조정을 적용했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-avatar-depth-soft-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-depth-soft-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-depth-soft-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-depth-soft-preview.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-depth-soft-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-depth-soft-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-depth-soft-preview-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 시작/메인/핫스팟 미리보기 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 핫스팟 미리보기 실행 및 상태 출력 확인
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 하단 대사창 HUD 느낌 축소

이전 캡처에서 남은 주요 문제:

- 하단 대사창이 가로로 너무 길게 깔려 장면 속 종이보다 게임 HUD 박스처럼 보였다.
- 이름표, 종이 줄, 스크롤 표시가 모두 같은 직사각 UI 안에 모여 있어서 평면적인 앱 레이어 느낌이 남았다.
- 대사창 폭을 줄이면 스크롤 화살표와 글자가 겹칠 위험이 있었다.

이번 조정:

- 대사창을 화면 전체 폭 기준이 아니라 책상 중앙의 고정 폭 노트처럼 줄였다.
- 종이/그림자/이름표/줄 장식 알파를 낮춰 과한 프레임 느낌을 줄였다.
- 본문 기본 글자 크기를 낮추고 줄간격을 조정해 작은 노트 폭에서도 읽히게 했다.
- 스크롤바와 스크롤 화살표를 본문 오른쪽 별도 여백으로 빼서 글자와 겹치지 않게 했다.
- 스크롤바 트랙/손잡이 색을 낮춰 기능은 유지하되 UI 막대처럼 튀는 느낌을 줄였다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-dialogue-notebook-final-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-notebook-final-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-notebook-final-input.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-notebook-final-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-notebook-final-start-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 메인/직접 입력 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 질문 노트 앱 패널 느낌 축소

이전 캡처에서 남은 주요 문제:

- 오른쪽 질문 노트가 길고 진한 세로 앱 패널처럼 보여, 장면 속 메모장보다 설정창에 가까웠다.
- 탭과 챕터 버튼의 대비가 강하고 모양이 균일해서 소품보다는 UI 메뉴처럼 읽혔다.
- 패널이 크고 밝아 책장/조명 영역을 덮으면서 화면 전체가 다시 인터페이스 중심으로 보였다.

이번 조정:

- 질문 노트의 전체 폭/높이와 그림자 알파를 줄였다.
- 바깥 종이, 내부 종이, 바인딩, 줄, 테이프의 불투명도를 낮춰 배경에 더 묻히게 했다.
- 탭 간격과 버튼 높이를 줄이고 텍스트 크기/알파를 낮췄다.
- 챕터 버튼의 종이/클립/펀치/줄 장식을 낮은 대비로 바꿔 작은 메모 조각처럼 보이게 했다.
- 하단 액션 버튼도 낮은 알파로 조정해 비활성 앱 버튼처럼 튀는 느낌을 줄였다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-note-paper-slim-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-paper-slim-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-paper-slim-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-paper-slim-memory.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-paper-slim-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-paper-slim-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-paper-slim-start-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 질문 노트/메인/기억장 캡처 생성 확인
- 질문 노트 열림 검증 PASS
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

## 2026-05-26 추가 패스: 기억장 중앙 대시보드 느낌 제거

이전 캡처에서 남은 주요 문제:

- 기억장이 화면 중앙의 큰 반투명 관리창처럼 떠서, 전시용 소품보다 앱 대시보드에 가까웠다.
- 3열 카드 그리드와 큰 진행 배지가 기능창처럼 보였고, 아바타를 정면으로 덮으면서 장면 몰입을 깼다.
- 투명도를 낮춘 뒤에는 배경과 글자가 섞여 읽기 어렵고, 아바타가 창 뒤에 비쳐 더 임시 UI처럼 보였다.

이번 조정:

- 기억장을 화면 중앙에서 오른쪽 책장/램프 쪽으로 옮겨, 장면 안에 놓인 스크랩북처럼 읽히게 했다.
- 3열 그리드를 2열 3행 앨범 배치로 바꾸고, 전체 크기를 줄여 아바타를 덜 가리게 했다.
- 종이 불투명도는 다시 올려 글자 가독성을 회복하고, 전체 오버레이는 낮춰 화면 전체가 회색으로 덮이지 않게 했다.
- 카드, 테이프, 바인딩, 진행 배지, 닫기 버튼을 더 작은 저대비 요소로 조정했다.
- 긴 문구를 줄이고 카드 안 문장을 짧게 잘라 작은 앨범 카드 안에서 글자가 뭉개지지 않게 했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-memory-side-album-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-side-album-memory.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-side-album-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-side-album-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-side-album-memory-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-side-album-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-memory-side-album-start-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 기억장/메인/질문 노트 캡처 생성 확인
- 기억장 열림 검증 PASS
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

남은 판단:

- 기억장의 중앙 대시보드 느낌은 줄었지만, 전체 화면의 저가감 원인은 아직 완전히 해결되지 않았다.
- 가장 큰 잔여 원인은 아바타와 배경의 재질 차이, 그리고 오른쪽 질문 노트/상단 탭이 여전히 명확한 UI 레이어로 읽히는 점이다.

## 2026-05-26 추가 패스: 아바타와 배경 재질 차이 완화

이전 캡처에서 남은 주요 문제:

- 배경은 부드러운 조명과 필름 입자감이 있는 반면, 아바타는 선과 명암이 더 또렷해 별도의 PNG를 얹은 느낌이 남았다.
- 아바타를 투명하게 섞은 이전 방식은 배경과는 섞였지만, 몸통 쪽이 유령처럼 비치는 인상을 만들 수 있었다.
- 검은 외곽선과 머리카락/재킷의 대비가 배경보다 강해서 시선이 부자연스럽게 아바타 컷아웃 경계에 걸렸다.

이번 조정:

- 아바타 텍스처 생성 단계에서 채도와 대비를 더 낮추고, 따뜻한 방 조명 쪽으로 팔레트를 눌렀다.
- 검은 선을 더 부드러운 갈색/회색 계열로 섞고, 내부 픽셀 블렌딩을 강화해 일러스트 경계를 줄였다.
- 아바타 텍스처에 작은 deterministic grain을 더해 배경의 공유 입자감과 맞췄다.
- 왼쪽 창문광, 오른쪽 램프, 하단 책상 빛을 반영하는 약한 색 보정을 추가했다.
- 기본 아바타 불투명도를 올리고 씬 워시 알파를 낮춰, 배경에 섞이되 너무 비쳐 보이지 않게 조정했다.
- 시작 화면 아바타도 같은 색/투명도 규칙으로 맞췄다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-avatar-room-texture-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-texture-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-texture-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-texture-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-texture-memory.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-texture-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-texture-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-texture-memory-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 메인/시작/질문 노트/기억장 캡처 생성 확인
- 시작 화면 열림 검증 PASS
- 기억장 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

남은 판단:

- 아바타 컷아웃의 선명도와 유령처럼 비치는 느낌은 줄었다.
- 다음으로 눈에 남는 저가감은 오른쪽 질문 노트와 상단 `장면`/`질문` 탭이 여전히 게임 UI 레이어처럼 보이는 점이다.

## 2026-05-26 추가 패스: 질문 노트와 상단 탭 UI 레이어감 축소

이전 캡처에서 남은 주요 문제:

- 상단 `장면`/`질문` 탭이 화면 위에 떠 있는 게임 메뉴처럼 보여 장면 몰입을 깼다.
- 질문 노트 내부 탭과 챕터 버튼의 대비가 강해, 종이 노트보다 모바일 앱 메뉴처럼 읽혔다.
- 질문 노트가 반투명 유리 패널처럼 보여 배경과 겹치면서도 실제 소품처럼 보이지 않았다.

이번 조정:

- 상단 `장면`/`질문` 탭의 크기, 배경 알파, 장식선, 텍스트 알파를 낮춰 화면 위 메뉴 느낌을 줄였다.
- 질문 노트 바깥/안쪽 종이 불투명도는 올리고, 그림자와 갈색 보드 알파는 낮춰 유리창보다 종이 소품처럼 보이게 했다.
- 노트 내부 탭의 진한 선택 색을 없애고, 낮은 대비의 종이 인덱스처럼 조정했다.
- 챕터 버튼과 하단 액션 버튼의 배경 대비를 낮추고 텍스트만 읽히는 수준으로 다시 보정했다.
- `닫기` 표기를 `접기`로 바꿔 앱 모달을 닫는 느낌보다 노트를 접는 느낌에 가깝게 했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-note-diegetic-tabs-legible-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-diegetic-tabs-legible-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-diegetic-tabs-legible-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-diegetic-tabs-legible-memory.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-diegetic-tabs-legible-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-diegetic-tabs-legible-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-diegetic-tabs-legible-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-diegetic-tabs-legible-start-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 질문 노트/메인/기억장/시작 화면 캡처 생성 확인
- 질문 노트 열림 검증 PASS
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

남은 판단:

- 상단 탭과 질문 노트의 앱 메뉴 느낌은 줄었다.
- 다음으로 남은 저가감은 하단 대사창이 여전히 "게임 자막 UI"로 보이는 점과, 전체 장면에 실제 인터랙션 피드백이 부족해 정적인 배경 위에 패널을 얹은 느낌이 남는 점이다.

## 2026-05-26 추가 패스: 하단 대사창 자막 HUD 느낌 축소

이전 캡처에서 남은 주요 문제:

- 하단 대사창이 화면 아래를 길게 가로지르는 형태라, 책상 위 종이보다 게임 자막 박스처럼 보였다.
- 긴 답변용 스크롤 화살표와 `쓰기` 버튼이 오른쪽에 붙어 있어 기능 HUD처럼 읽혔다.
- 질문 노트와 상단 탭을 낮춘 뒤에도, 대사창이 가장 선명한 UI 레이어로 남아 있었다.

이번 조정:

- 하단 대사창의 전체 폭과 높이를 줄여 책상 위 작은 메모지처럼 보이게 했다.
- 대사창 패널을 아주 약하게 회전시켜 화면에 붙은 직사각 UI보다 놓인 종이처럼 읽히게 했다.
- 종이 그림자, 줄무늬, 이름표, 장식선, 스크롤 화살표의 대비를 낮췄다.
- 기본 대사 글자 크기를 한 단계 낮추고, 좁아진 메모지 안에서는 긴 답변이 스크롤되도록 유지했다.
- 직접 입력 필드와 `쓰기`/`묻기` 버튼의 위치와 색을 새 대사창 폭에 맞게 조정했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-dialogue-desk-note-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-desk-note-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-desk-note-input.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-desk-note-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-desk-note-memory.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-desk-note-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-desk-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-desk-note-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-desk-note-start-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 메인/직접 입력/질문 노트/기억장/시작 화면 캡처 생성 확인
- 질문 노트 열림 검증 PASS
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

남은 판단:

- 기본 장면의 하단 자막 HUD 느낌은 줄었다.
- 직접 입력을 열었을 때는 입력창과 `녹음`/`묻기` 버튼이 아직 폼 UI처럼 보인다.
- 다음 저가감 원인은 정적인 배경 위에 UI를 얹은 느낌이다. 책상 단서 hover/클릭 반응, 열린 장면 표시, 답변 전환 피드백을 더 장면 안쪽으로 넣어야 한다.

## 2026-05-26 추가 패스: 직접 입력 폼 UI 느낌 축소

이전 캡처에서 남은 주요 문제:

- 직접 입력을 열면 흰 직사각 입력창과 `녹음`/`묻기` 버튼이 나타나 웹 폼처럼 보였다.
- 하단 대사창은 메모지처럼 줄였지만, 입력 모드에서는 별도 폼 레이어가 다시 튀어나오는 느낌이 있었다.
- 입력창을 너무 흐리게 줄이면 사용자가 어디에 써야 하는지 놓칠 위험이 있었다.

이번 조정:

- 입력창 배경을 흰 박스에서 낮은 알파의 필기 영역으로 바꿨다.
- 입력 영역 안에 얇은 필기줄과 왼쪽 섬유 표시를 넣어 메모지 위에 쓰는 느낌을 냈다.
- placeholder 문구를 짧게 바꾸고, 배경보다 텍스트/필기줄 가독성만 조금 올렸다.
- `녹음`/`묻기` 버튼의 크기와 대비를 줄여 별도 폼 버튼처럼 튀지 않게 했다.
- 기본 대사 화면과 긴 답변 스크롤 동작은 유지했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-ui-input-writing-line-legible-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-writing-line-legible-input.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-writing-line-legible-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-writing-line-legible-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-writing-line-legible-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-writing-line-legible-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-writing-line-legible-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-input-writing-line-legible-start-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 직접 입력/메인/질문 노트/시작 화면 캡처 생성 확인
- 질문 노트 열림 검증 PASS
- 시작 화면 열림 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 관련 오류/경고 로그 없음

남은 판단:

- 직접 입력 모드의 폼 느낌은 줄었다.
- 다음으로 남은 저가감은 정적인 배경 위에 UI를 얹은 느낌이다. 책상 단서가 실제로 반응하고, 답변 전환이 장면 안쪽 변화로 느껴지도록 소품 반응/강조/상태 피드백을 추가해야 한다.

## 2026-05-26 추가 패스: 단서 클릭과 답변 전환을 장면 안쪽으로 연결

이전 캡처에서 남은 주요 문제:

- 배경 오브젝트는 예쁘지만, 실제 반응은 대부분 카드와 하단 대사창에서만 일어났다.
- 단서를 눌러도 장면 속 물건이 반응한다기보다 UI 패널이 뜨는 느낌이 강했다.
- 답변이 기억장에 저장되는 흐름도 장면 변화보다 토스트/문구로만 전달됐다.

이번 조정:

- 단서 hover/클릭 시 해당 오브젝트 위치에 낮은 알파의 따뜻한 포커스와 작은 종이 라벨이 나타나도록 했다.
- 핫스팟 미리보기 카드를 중앙 대형 팝업에서 클릭한 오브젝트 근처의 작은 종이 카드로 옮겼다.
- 질문 제출 직후에는 책상 쪽에 "질문 남김", 답변 완료 후에는 주제에 맞는 오브젝트에 "답변 남김" 피드백이 남도록 했다.
- smoke 상태 검사에 `hotspot` 패널 키를 추가해서 핫스팟 미리보기 open/closed를 직접 검증할 수 있게 했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-scene-feedback-position-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-feedback-position-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-feedback-position-answer.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-feedback-position-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-feedback-position-hotspot-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 핫스팟/답변/질문 노트 캡처 생성 확인

남은 판단:

- "정적인 배경 위에 UI만 얹은 느낌"은 줄었다.
- 그래도 아직 실제 오브젝트 애니메이션이 아니라 UI 기반 하이라이트라서, 상용 게임처럼 느끼려면 다음 단계에서 노트북 화면 점등, 컵/노트/게시판 같은 소품별 미세 변화가 필요하다.

## 2026-05-26 추가 패스: 실제 소품 반응 추가

이전 캡처에서 남은 주요 문제:

- 단서 클릭과 답변 전환이 장면 안으로 들어오긴 했지만, 여전히 하이라이트/라벨 중심이었다.
- 노트북, 컵, 게시판, 노트 같은 소품 자체는 별도 상태가 없어 정지 배경처럼 보였다.
- 취미 답변에서 컵 피드백 위치가 실제 컵보다 위쪽으로 잡혀 있었다.

이번 조정:

- 노트북 답변 시 노트북 화면에 낮은 알파의 화면광과 코드/문장 라인이 켜지도록 했다.
- 메모/도움 주제는 게시판 메모지가 흔들리고 줄이 보이도록 했다.
- 취미/휴식 주제는 컵 위로 옅은 김이 올라오도록 했다.
- 질문 제출 시 책상 노트에 필기 라인이 잠깐 남도록 했다.
- 목발/일상 주제는 목발 광택이 움직이도록 했다.
- 문/지도/자취방 주제는 입구 쪽 따뜻한 빛 반응으로 연결했다.
- 컵 핫스팟과 컵 답변 피드백 좌표를 실제 컵 위치에 맞게 낮췄다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-reactive-props-cupfix-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-reactive-props-cupfix-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-reactive-props-cupfix-answer-cup.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-reactive-props-cupfix-note.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-reactive-props-cupfix-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-reactive-props-cupfix-long-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 노트북 답변/컵 답변/질문 노트 캡처 생성 확인

남은 판단:

- 이제 배경이 완전 정지 그림처럼 보이는 문제는 더 줄었다.
- 그래도 아직 소품 변화가 코드로 얹은 2D 오버레이라, 다음 단계에서 더 좋아지려면 배경 원본에 맞춘 픽셀 정렬/마스크 또는 소품별 전용 스프라이트가 필요하다.

## 2026-05-26 추가 패스: 답변 피드백을 라벨보다 소품 반응 중심으로 정리

이전 캡처에서 남은 주요 문제:

- 답변 직후 `노트북 · 답변 남김`, `컵 · 답변 남김` 같은 종이 라벨이 떠서 장면 반응보다 상태 UI처럼 보였다.
- 새 장면 알림이 큰 갈색 토스트로 떠서 화면 오른쪽 위가 앱 알림처럼 느껴졌다.
- 소품 반응은 생겼지만 라벨/토스트가 더 눈에 띄어 실제 장면 변화가 묻혔다.

이번 조정:

- 답변 완료 시 `ShowSceneFocus(..., "답변 남김")` 호출을 제거했다.
- 답변 완료 후에는 `TriggerScenePropReaction`만 호출해 노트북 화면, 컵 김, 게시판 메모, 목발 광택 같은 소품 반응만 남게 했다.
- 기억장 알림을 큰 갈색 박스에서 작은 종이 북마크 스타일로 바꿨다.
- 기억장 알림 문구를 한 줄로 줄이고, 팝 애니메이션도 낮췄다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-prop-only-feedback-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-prop-only-feedback-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-prop-only-feedback-answer-cup.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-prop-only-feedback-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-prop-only-feedback-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-prop-only-feedback-long-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 노트북 답변/컵 답변/핫스팟 캡처 생성 확인

남은 판단:

- 답변 전환이 이전보다 덜 UI 알림처럼 보인다.
- 아직 전체 화면의 마지막 저가감은 생성형 배경과 코드 오버레이가 완전히 같은 원근/재질로 붙지 않는 데서 온다. 다음 단계는 소품 반응의 마스크/원근/투명도를 더 배경에 맞추거나, 주요 소품을 별도 아트 레이어로 다시 만드는 것이다.

## 2026-05-26 추가 패스: 소품 반응 원근 보정

이전 캡처에서 남은 주요 문제:

- 노트북 반응이 앞쪽 노트북 뚜껑 위에 떠서, 실제 화면에 붙은 빛이 아니라 합성 오버레이처럼 보였다.
- 노트북 핫스팟 미리보기 카드가 얼굴 중앙을 덮어 장면 몰입을 깨뜨렸다.
- 소품 반응 자체는 좋아졌지만, 좌표가 배경의 실제 소품과 어긋나면 오히려 싸 보였다.

이번 조정:

- 노트북 반응 레이어를 앞쪽 뚜껑에서 뒤쪽 검은 모니터 화면으로 옮겼다.
- 노트북 화면광 알파와 크기를 낮춰 배경 재질에 더 섞이게 했다.
- 노트북 핫스팟 좌표도 뒤쪽 모니터 기준으로 옮겼다.
- 뒤쪽 모니터처럼 위쪽에 있는 단서는 미리보기 카드가 얼굴 위가 아니라 왼쪽 창/모니터 근처에 뜨도록 배치 규칙을 추가했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-perspective-props-cardfix-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-perspective-props-cardfix-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-perspective-props-cardfix-answer-cup.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-perspective-props-cardfix-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-perspective-props-cardfix-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-perspective-props-cardfix-long-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 노트북 답변/컵 답변/핫스팟 캡처 생성 확인

남은 판단:

- 노트북 반응은 이전보다 배경 소품에 더 붙어 보인다.
- 아직 완성형으로 보이려면 UI 카드 자체를 더 줄이거나, 단서 확인도 별도 카드가 아니라 장면 속 노트/모니터 표면에 직접 표시하는 방식까지 가야 한다.

## 2026-05-26 추가 패스: 단서 확인 카드 소품화

이전 캡처에서 남은 주요 문제:

- 핫스팟을 누르면 큰 질문 확인 카드가 별도 UI처럼 떠서 장면을 다시 앱 화면처럼 만들었다.
- 클릭 피드백으로 `노트북 · 단서 확인` 라벨과 질문 카드가 동시에 보여 중복 상태 표시처럼 보였다.
- 노트북 단서는 실제 모니터 위에 있는 장면인데, 질문 확인은 화면 위 카드라 재질과 원근이 분리되어 보였다.

이번 조정:

- 핫스팟 질문 확인 패널을 큰 카드에서 작은 종이 조각 크기로 줄였다.
- 단서 확인 클릭 시에는 장면 포커스의 종이 라벨을 숨기고, 은은한 글로우와 소품 반응만 남겼다.
- 노트북 단서는 뒤쪽 모니터 표면에 붙은 듯한 위치와 크기로 배치했다.
- 컵, 목발, 메모, 지도/자취방 계열 단서도 각 소품 근처에 작은 종이 조각으로 붙도록 위치 규칙을 나눴다.
- `묻기`와 `닫기` 버튼을 작고 낮은 알파의 태그처럼 바꿔 버튼이 화면의 주인공처럼 보이지 않게 했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-scene-embedded-hotspot-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-embedded-hotspot-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-embedded-hotspot-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-embedded-hotspot-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-embedded-hotspot-answer-cup.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-embedded-hotspot-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 노트북 답변/컵 답변/핫스팟 캡처 생성 확인

남은 판단:

- 핫스팟 확인은 이전보다 화면 위 UI 카드가 아니라 장면에 붙은 질문 조각에 가까워졌다.
- 그래도 전체가 완전히 고급스러워지려면, 다음 단계는 코드로 그린 UI 레이어를 더 줄이고 실제 전시 소품처럼 보이는 핵심 아트 레이어를 따로 잡는 것이다. 특히 책상 위 종이, 노트북 화면, 기억장 쪽은 별도 이미지/스프라이트로 만드는 편이 코드 패널을 계속 다듬는 것보다 효율이 좋다.

## 2026-05-26 추가 패스: 하단 대사창 기록지화

이전 캡처에서 남은 주요 문제:

- 하단 답변 영역이 긴 반투명 UI 박스로 보여서, 배경 위에 앱 자막이 얹힌 느낌이 강했다.
- 텍스트 대비가 낮고 종이 질감보다 투명 패널 느낌이 먼저 보여 전시 소품처럼 느껴지지 않았다.
- 핫스팟 카드와 답변 카드가 모두 UI 패널 계열로 보여, 장면과 인터페이스가 분리되어 보였다.

이번 조정:

- 하단 답변 영역을 더 좁고 높은 책상 위 기록지 형태로 바꿨다.
- 종이 알파를 높이고 텍스트 대비를 올려 읽기 어려운 반투명 박스 느낌을 줄였다.
- 기본 글자 크기를 한 단계 낮추고 viewport 높이를 늘려 일반 답변 첫 화면에서 줄이 잘리는 문제를 보정했다.
- 사각 그림자를 부드러운 타원 그림자로 바꿔 종이 뒤에 큰 UI 박스가 깔린 느낌을 줄였다.
- 종이 테이프, 규칙선, 좌측 spine을 강화해 대사창이 화면 시스템 UI가 아니라 책상 위 기록지처럼 보이게 했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity_desk_paper_dialogue_shadow_build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_paper_dialogue_shadow_answer_laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_paper_dialogue_shadow_hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_paper_dialogue_shadow_hotspot_state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_paper_dialogue_shadow_long_state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 답변/핫스팟 캡처 생성 및 시각 확인

남은 판단:

- 하단 대사창은 이전보다 앱 자막 느낌이 줄고 책상 위 기록지에 가까워졌다.
- 아직 화면 전체의 저가감은 아바타 컷아웃, 생성 배경, 코드 UI가 서로 다른 제작 방식으로 보이는 데서 남는다. 다음 큰 개선은 아바타/책상 접촉부를 더 자연스럽게 만들거나, 핵심 UI 종이류를 별도 이미지 아트로 만들어 통일하는 것이다.

## 2026-05-26 추가 패스: 아바타 방 조명 블렌딩

이전 캡처에서 남은 주요 문제:

- 아바타가 배경 공간에 앉아 있다기보다, 배경 위에 오려 붙인 인물처럼 보였다.
- 특히 머리와 어깨 외곽선이 선명하고, 하반신과 책상 접촉부가 배경 조명과 덜 섞였다.
- 검은 선과 채도가 배경보다 또렷해 애니메이션 캐릭터 스티커 같은 느낌이 남았다.

이번 조정:

- 아바타 텍스처 후처리에서 검은 선을 더 따뜻한 갈색 계열로 누르고, 전체 채도와 대비를 낮췄다.
- 하반신 쪽에는 책상 조명 색과 안개 블렌딩을 더 강하게 적용해 접촉부가 덜 떠 보이게 했다.
- 가장자리 알파와 따뜻한 edge blend를 조금 강화해 오려낸 경계가 덜 딱딱하게 보이도록 했다.
- 아바타 뒤에 같은 실루엣의 아주 약한 방 그림자를 추가했다. 1차 적용 후 그림자가 잔상처럼 보여 알파와 오프셋을 다시 낮췄다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-room-blend-subtle-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-blend-subtle-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-blend-subtle-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-blend-subtle-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-blend-subtle-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 답변/핫스팟 캡처 생성 및 시각 확인

남은 판단:

- 아바타 하반신과 책상 접촉부는 이전보다 덜 떠 보인다.
- 그래도 완전히 고급스럽게 만들려면 코드 보정만으로는 한계가 있다. 가장 큰 남은 원인은 배경과 아바타가 애초에 같은 장면으로 그려진 원본이 아니라 별도 레이어 합성이라는 점이다. 다음 단계는 아바타 자체를 배경 조명에 맞춰 다시 생성하거나, 의자/책상 일부가 아바타 앞을 자연스럽게 가리는 전용 전경 마스크를 만드는 것이다.

## 2026-05-26 추가 패스: 전경 책상 마스크와 hover 라벨 제거

이전 캡처에서 남은 주요 문제:

- 아바타 하단이 여전히 책상 뒤에 앉아 있다기보다 반투명하게 얹힌 느낌이 남았다.
- 답변 캡처 중 커서가 컵 영역에 걸리면 `컵` hover 라벨이 흰 막대처럼 떠서, 작은 UI 잔여물이 화면을 싸 보이게 했다.
- 핫스팟 라벨은 정보량에 비해 시각적 비용이 커서 전시 장면보다 UI가 먼저 보였다.

이번 조정:

- `CreateForegroundDeskLayer`에 책상색 전경 occluder와 접촉 feather를 추가했다.
- 아바타 하단을 완전히 가리지 않고 책상 조명/접촉 그림자에 묻히도록 부드러운 타원 레이어로 처리했다.
- 핫스팟 hover 라벨은 표시하지 않도록 바꾸고, 단서 반응은 핀/글로우/클릭 확인 종이만 남겼다.
- 질문 시작과 핫스팟 preview 열림 시 기존 hover 라벨을 강제로 닫는 안전장치를 추가했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-foreground-occlusion-nohover-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-foreground-occlusion-nohover-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-foreground-occlusion-nohover-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-foreground-occlusion-nohover-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-foreground-occlusion-nohover-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 답변 캡처에서 컵 hover 라벨 제거 확인

남은 판단:

- 작은 UI 잔여물 하나가 사라지면서 화면이 덜 앱처럼 보인다.
- 이제 남은 큰 개선은 코드 레이어 추가보다 원본 비주얼 통합이다. 배경과 인물을 하나의 장면으로 다시 만들거나, 전경 가림 오브젝트를 실제 이미지 마스크로 만드는 쪽이 다음 효율이 높다.

## 2026-05-26 추가 패스: 기억장 토스트 제거

이전 캡처에서 남은 주요 문제:

- 답변 직후 오른쪽 위에 `기억장 · ...` 흰 종이 토스트가 떠서 앱 알림처럼 보였다.
- 작은 박스 하나지만 장면 몰입을 깨고, 배경 속 전시 소품보다 UI 레이어가 먼저 눈에 들어왔다.
- 이미 기억장 버튼 pulse와 내부 진행 상태가 있어서 별도 화면 토스트는 시각 비용에 비해 이득이 작았다.

이번 조정:

- 기억장 unlock/completion 시 화면 토스트 오브젝트를 띄우지 않도록 바꿨다.
- 소리, 상태 텍스트, 기억장 버튼 pulse는 유지했다.
- 답변 캡처에서 오른쪽 위 흰 토스트 박스가 사라진 것을 확인했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-no-memory-toast-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-no-memory-toast-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-no-memory-toast-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-no-memory-toast-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-no-memory-toast-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 답변 캡처에서 기억장 토스트 제거 확인

남은 판단:

- 오른쪽 위 알림 박스가 사라지면서 화면이 조금 더 장면 중심으로 정리됐다.
- 이제 남는 저가감은 주로 원본 이미지와 UI/인물 레이어가 서로 다른 제작 방식처럼 보이는 문제다. 추가 개선은 개별 UI 토스트를 없애는 것보다, 아바타와 배경을 같은 아트 방향으로 다시 맞추는 쪽이 더 크다.

## 2026-05-27 추가 패스: 아바타 실체감과 종이 UI 톤 정리

이전 캡처에서 남은 주요 문제:

- 아바타가 너무 반투명해서 방 안에 앉은 사람보다 배경 위에 얹힌 유령 같은 합성물로 보였다.
- 책상 전경 occlusion이 하단을 묻어주기는 했지만, 넓은 안개처럼 보여서 몸 전체의 실체감을 같이 낮췄다.
- 하단 대화 종이와 단서 preview 카드가 여전히 밝은 팝업 UI처럼 튀었다.
- 스크롤바와 작은 버튼 면이 실제 전시 소품보다 앱 위젯처럼 보였다.

이번 조정:

- 아바타 본체 alpha를 높이고, 장면 wash alpha를 낮춰 인물의 밀도를 되살렸다.
- 아바타 뒤/접촉 그림자는 강화하고, 책상색 전경 occlusion은 약하게 조정했다.
- 하단 대화 종이는 더 탁한 종이색과 낮은 그림자로 바꿔 흰 UI 박스 느낌을 줄였다.
- 단서 preview 카드의 종이 alpha, 테이프, accent, 버튼 면을 낮추고, `묻기`/`닫기` 텍스트 버튼을 작은 기호 탭으로 줄였다.
- 대화 스크롤바의 track/handle alpha를 낮춰 긴 답변 기능은 유지하면서 화면 잡음을 줄였다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-solid-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-solid-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-solid-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-solid-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-solid-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 보호 대상 폴더 수정 시간 변화 없음

남은 판단:

- 인물은 이전보다 덜 떠 보이고, 밝은 UI 박스의 존재감도 줄었다.
- 그래도 완성이라고 보기 어려운 이유는 배경/아바타/텍스트 종이가 아직 각각 다른 레이어로 조립된 느낌이 남기 때문이다. 다음 효율 좋은 작업은 코드로 덮는 효과를 더 늘리는 것보다, 아바타 원본을 배경 조명과 같은 방향으로 다시 만들거나 전경 책상/의자 마스크를 실제 이미지 자산으로 분리하는 것이다.

## 2026-05-27 추가 패스: 아바타 책상 접촉면 재정렬

이전 캡처에서 남은 주요 문제:

- 아바타 원본에는 나무 책상 띠가 포함되어 있는데, 기존 코드는 이 영역을 전부 투명 처리했다.
- 그 결과 하단부가 배경 책상 위에 자연스럽게 닿기보다 잘린 판처럼 보였다.
- idle 자세에서는 손 위치가 배경 노트/책상 표면과 어긋나, 책상 아래에서 손이 비치는 듯한 느낌이 있었다.

이번 조정:

- 아바타 원본의 책상 띠를 완전히 제거하지 않고, 배경 책상색에 맞춘 약한 반투명 나무결 접촉면으로 변환했다.
- 해당 띠는 하단과 좌우를 페이드해 직사각형 패치처럼 보이지 않게 했다.
- 하단부의 desk/haze blend와 전경 책상 occlusion 강도를 다시 조정해 손과 몸통 하단이 덜 떠 보이게 했다.
- 아바타와 관련 그림자 레이어를 약 28px 위로 올려, 손과 책상 표면의 위치 관계를 맞췄다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-raised-desk-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-raised-desk-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-raised-desk-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-raised-desk-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-raised-desk-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 보호 대상 폴더 수정 시간 변화 없음

남은 판단:

- 아바타가 책상 밑에서 떠오르는 느낌은 줄었고, 손과 책상 표면의 위치 관계가 이전보다 낫다.
- 하지만 원본 배경은 반실사 방 이미지이고 아바타는 일러스트 컷아웃이므로, 마지막 저가감은 아직 남는다. 이 단계 이후의 큰 개선은 코드 보정이 아니라 같은 조명/구도로 다시 만든 아바타 자산이나 실제 전경 책상 마스크 자산이 필요하다.

## 2026-05-27 추가 패스: 실제 배경 픽셀 기반 책상 전경 마스크

이전 캡처에서 남은 주요 문제:

- 코드로 만든 타원형 책상 가림은 색과 질감이 배경과 완전히 같지 않아 합성 티가 남았다.
- 아바타 하단을 가리는 레이어가 실제 노트/펜/책상 표면이 아니라 반투명 안개처럼 보여, 책상 앞뒤 관계가 약했다.
- 아바타 원본의 책상 띠를 약하게 되살리는 방식은 방향은 맞았지만, 배경 노트와 손 위치가 겹칠 때 어색함이 남았다.

이번 조정:

- 배경 PNG import 설정의 `isReadable`을 켜서 런타임에서 배경 픽셀을 샘플링할 수 있게 했다.
- `GetBackgroundDeskForegroundSprite()`를 추가해 배경 이미지에서 책상 하단 영역만 투명 마스크 스프라이트로 재생성했다.
- 해당 전경 마스크를 아바타 위, 대화/UI 아래에 배치했다.
- 이제 책상, 노트, 펜이 코드 색상 타원이 아니라 실제 배경 픽셀로 아바타 하단을 가린다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-background-desk-mask-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-background-desk-mask-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-background-desk-mask-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-background-desk-mask-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-background-desk-mask-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 보호 대상 폴더 수정 시간 변화 없음

남은 판단:

- 책상 앞뒤 관계는 이전보다 가장 확실하게 정리됐다.
- 다만 아바타 자체는 여전히 배경과 다른 생성 스타일이다. 지금 이후의 핵심 개선은 UI 코드가 아니라 아바타 원본을 같은 방 조명/구도/질감으로 다시 만드는 것이다.

## 2026-05-27 추가 패스: 아바타 선화 약화와 상단 탭 텍스트 제거

이전 캡처에서 남은 주요 문제:

- 책상 전경 마스크로 앞뒤 관계는 좋아졌지만, 아바타의 검은 선화와 높은 일러스트 대비가 반실사 배경과 계속 충돌했다.
- 오른쪽 위의 작은 `장면`, `질문` 탭 텍스트가 거의 기능 설명처럼 보여 화면을 앱 UI 쪽으로 끌고 갔다.
- 상단 텍스트는 작아서 정보 전달에는 약한데, 시각적 잡음으로는 남아 있었다.

이번 조정:

- 아바타 팔레트 보정 강도를 높이고, 어두운 선을 더 따뜻한 중간톤으로 끌어올렸다.
- 아바타 내부 smoothing과 grain을 늘려 배경의 부드러운 질감에 더 가깝게 맞췄다.
- 기본 화면에서는 상단 `장면`, `질문` 탭 텍스트를 비워 두도록 바꿨다.
- 질문 노트가 열린 상태에서만 닫기 표식 `×`가 보이도록 조정했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-painterly-topbar-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-painterly-topbar-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-painterly-topbar-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-painterly-topbar-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-painterly-topbar-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 보호 대상 폴더 수정 시간 변화 없음

남은 판단:

- 상단 UI 잡음은 줄었고, 아바타 선화는 이전보다 덜 튄다.
- 대신 아바타 존재감이 약해질 위험이 있어, 이후 개선은 단순히 더 흐리게 만드는 방향보다 새 아바타 자산 제작 또는 현재 아바타의 조명/명암 재제작이 필요하다.

## 2026-05-27 추가 패스: 아바타 투명 기록판 프레이밍

이전 캡처에서 남은 주요 문제:

- 아바타를 실제 방 안에 앉은 인물처럼 끝까지 읽히게 만들기에는 배경과 아바타 원본의 제작 스타일이 달랐다.
- 아무 프레임 없이 배경 위에 아바타가 놓이면, 의도된 전시 장치보다 합성 실패처럼 보일 수 있었다.
- 프레임을 너무 강하게 만들면 다시 앱 카드처럼 보일 위험이 있었다.

이번 조정:

- 아바타 뒤에 매우 약한 `Avatar Projection Glass` backplate를 추가했다.
- 유리판 느낌의 옅은 edge, top glint, diagonal reflection을 넣어 아바타가 장면 속 면담 기록/투명 화면처럼 읽히게 했다.
- 알파를 낮게 유지해 UI 카드가 아니라 방 안의 전시 장치처럼 보이도록 조정했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-projection-frame-balanced-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-projection-frame-balanced-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-projection-frame-balanced-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-projection-frame-balanced-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-projection-frame-balanced-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 보호 대상 폴더 수정 시간 변화 없음

남은 판단:

- 아바타의 합성 티를 “의도된 기록 화면” 쪽으로 돌리는 데는 도움이 된다.
- 다만 본질적으로는 새 아바타 자산 또는 아바타 원본의 조명/질감 재제작이 최종 해결책이다.

## 2026-05-27 추가 패스: 아바타 상단 경계선 제거

이전 캡처에서 남은 주요 문제:

- 화면 중앙, 아바타 머리 위쪽을 가로지르는 1px 수평선이 계속 보였다.
- 처음에는 투명 기록판 프레임/유리 효과가 원인처럼 보였지만, 프레임 호출 제거 후에도 선이 남았다.
- 아바타를 임시로 투명 처리한 디버그 캡처에서는 선이 사라져, 실제 원인은 배경이 아니라 아바타 이미지 경계/중복 보정 레이어 쪽으로 확인됐다.

이번 조정:

- `CreateAvatarProjectionFrame(parent)` 호출을 제거했다.
- 화면 경계선을 만들 가능성이 있던 아바타 중복 보정 레이어의 알파를 0으로 낮췄다.
- 아바타 텍스처 후처리에서 기존 alpha 0 픽셀도 transparent로 분류하고, 외곽 8px를 완전 투명으로 정리했다.
- 아바타 스프라이트를 `SpriteMeshType.Tight`로 만들고 UI Image도 `useSpriteMesh`를 켰다.
- Unity UI 사각 경계에서 남는 1px 흔적은 해당 구간의 배경 픽셀을 샘플링한 10px 페더 스트립으로 자연스럽게 덮었다.
- `Avatar Lens Haze`, `Scene Center Focus Lift`처럼 선처럼 읽힐 수 있는 얇은 분위기 오버레이는 제거했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-boundary-strip-feather-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-boundary-strip-feather-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-boundary-strip-final-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-boundary-strip-final-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-boundary-strip-final-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-boundary-strip-final-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 가로선 위치(y≈295) 행 이상치 제거: 이전 최고 score 약 101.47, 최종 상위 이상치에서 y=295 사라짐
- 보호 대상 폴더 수정 시간 변화 없음

남은 판단:

- 싸 보이는 원인 중 하나는 아바타 자체만이 아니라, 아바타를 둘러싼 1px 경계/중복 보정/프레임 흔적이었다.
- 이번 패스로 합성 실패처럼 보이던 선은 제거됐다.
- 그러나 아바타와 반실사 배경의 제작 스타일 차이는 여전히 남아 있어, 최종 수준을 더 올리려면 같은 조명/시점으로 만든 아바타 원본이 필요하다.

## 2026-05-27 추가 패스: 아바타 방 조명 적용 누락 수정

이전 캡처에서 남은 주요 문제:

- 선은 제거됐지만 아바타가 여전히 방 안 인물보다 어둡고 채도가 낮은 종이 컷아웃처럼 보였다.
- 코드에는 아바타 팔레트/질감/조명 보정 함수가 있었지만, `_room` 아바타 리소스 메타가 `isReadable: 0`이라 런타임에서 후처리 대부분이 적용되지 않았다.
- 그래서 코드상으로는 조정한 것처럼 보여도 실제 캡처 지표가 거의 움직이지 않았다.

이번 조정:

- `avatar_*_room.png.meta` 6개를 `isReadable: 1`, `alphaIsTransparency: 1`로 맞췄다.
- 아바타 텍스처 후처리에 `ApplyAvatarAmbientRelight`를 추가해 방의 따뜻한 조명, 왼쪽 키라이트, 책상 반사광을 약하게 입혔다.
- 기존 room texture 패스의 채도/대비/조명 값을 재조정했다.
- 처음에는 relight 강도가 과해서 대비가 너무 낮아졌고, 이후 균형값으로 낮춰 밝기는 올리되 과한 washout은 줄였다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-room-readable-balanced-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-room-readable-balanced-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-readable-balanced-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-readable-balanced-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-readable-balanced-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-room-readable-balanced-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 아바타 차이 영역 평균 밝기: 100.2 -> 130.9
- 아바타 차이 영역 평균 채도: 0.155 -> 0.197
- 기존 가로선 구간 이상치가 다시 커지지 않음
- 보호 대상 폴더 수정 시간 변화 없음

남은 판단:

- 이번 패스로 “너무 어둡고 죽은 아바타가 배경 위에 붙은 느낌”은 줄었다.
- 다만 후처리로는 원본 제작 스타일 차이를 완전히 지울 수 없다. 최종 품질을 더 끌어올리려면 현재 리소스를 계속 만지는 것보다, 배경과 같은 조명/시점/렌더링 질감으로 아바타 원본을 다시 만드는 편이 낫다.

## 2026-05-27 추가 패스: 하단 대사창 카드감 축소

이전 캡처에서 남은 주요 문제:

- 아바타 조명은 맞아졌지만, 하단 대사창이 장면보다 훨씬 밝은 종이 카드처럼 떠 있었다.
- 종이 줄, 테이프, 스파인, 명패, 황동 라인 장식이 반복되어 전시 기록물보다 UI 스킨처럼 보였다.
- 화면의 주인공이어야 할 방/아바타보다 하단 UI가 더 먼저 읽혔다.

이번 조정:

- 하단 대사창의 밝은 종이판을 어두운 전시 캡션판에 가까운 색으로 바꿨다.
- 대사 텍스트는 어두운 글자에서 밝은 글자로 바꿔 가독성을 유지했다.
- 테이프, 종이 줄, 스파인, 황동 라인, 명패 배경의 알파를 0으로 낮춰 반복 장식을 제거했다.
- 핫스팟 미리보기 카드도 밝기와 장식을 조금 낮췄다.
- 스크롤 큐는 어두운 캡션판 위에서 보이도록 색을 다시 맞췄다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-dialogue-dark-caption-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-dialogue-dark-caption-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-dark-caption-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-dark-caption-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-dark-caption-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-dark-caption-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 closed 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 스크롤 큐 visible 검증 PASS
- 아바타 비율/크기 검증 PASS
- 하단 대사 영역 평균 밝기: 180.7 -> 145.7
- 대사 핵심 영역 평균 밝기: 192.3 -> 165.7
- 장식 축소 후 edge-diff가 크게 늘지 않아 잔선/잡음 증가 없음
- 보호 대상 폴더 수정 시간 변화 없음

남은 판단:

- 이번 패스로 밝은 UI 카드가 장면을 눌러 보이던 문제는 줄었다.
- 현재 남은 싸구려 느낌의 큰 원인은 코드 UI보다 리소스 제작 스타일이다. 방 배경, 아바타, 오브젝트가 같은 촬영/렌더링 조건에서 만들어진 자산이 아니기 때문에 후처리만으로 완전한 일체감은 한계가 있다.

## 2026-05-27 추가 패스: 시작 화면 랜딩 카드감 축소

이전 캡처에서 남은 주요 문제:

- 실제 대화 화면의 하단 UI는 정리됐지만, 첫 화면은 아직 밝은 종이 밴드와 큰 텍스트/버튼 묶음이 먼저 보여 랜딩 페이지처럼 읽혔다.
- 시작 화면 아바타는 메인 화면에서 맞춘 `useSpriteMesh`, relight 색감, 중복 wash 제거 기준과 다르게 보정되어 있었다.
- 첫 화면의 밝은 밴드가 배경/아바타보다 더 강하게 보이면서 전시 장면의 몰입을 깨고 있었다.

이번 조정:

- 시작 화면 아바타도 메인 화면과 같은 색/메시 설정으로 맞췄다.
- 시작 화면의 중복 아바타 wash 알파를 0으로 낮췄다.
- 밝은 시작 밴드를 어두운 반투명 캡션판 톤으로 바꿨다.
- 제목/부제/버튼 텍스트는 밝은 색으로 바꿔 어두운 밴드 위 가독성을 유지했다.
- 시작 버튼과 질문 노트 버튼의 색을 더 낮은 채도의 전시 UI 톤으로 맞췄다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-start-menu-dark-band-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-start-menu-dark-band-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-menu-dark-band-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-menu-dark-band-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-menu-dark-band-start-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-menu-dark-band-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-start-menu-dark-band-long-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 시작 화면 open 검증 PASS
- 핫스팟 closed 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 시작 밴드 평균 밝기: 189.5 -> 67.1
- 시작 화면 전체 평균 밝기: 124.5 -> 114.3
- 보호 대상 폴더 수정 시간 변화 없음

남은 판단:

- 첫 화면이 밝은 안내 카드처럼 튀는 문제는 줄었다.
- 현재 남은 품질 한계는 전체 자산의 공통 제작 조건이다. UI를 계속 덜어내고 조명을 맞춰도, 배경/아바타/소품의 렌더링 소스가 서로 다르면 완전한 일체감은 제한된다.

## 2026-05-27 추가 패스: 질문 노트 패널의 밝은 종이 UI감 축소

이전 캡처에서 남은 주요 문제:

- 기본 화면의 떠 있는 질문 칩은 `ShowFloatingLeadSlips = false`로 실제 표시되지 않았다. 따라서 밝은 버튼처럼 보이는 원인은 그 칩이 아니라, 사용자가 여는 오른쪽 질문 노트 패널 쪽이었다.
- 열린 질문 노트는 외곽/본문/탭/챕터 버튼이 밝은 종이 색이라, 어두운 대화 캡션과 분리되어 별도의 앱 패널처럼 보였다.
- 특히 노트 본문 영역 평균 밝기가 195.6으로, 메인 대화 밴드보다 훨씬 밝았다.

이번 조정:

- 질문 노트 외곽과 본문을 밝은 종이판에서 어두운 반투명 전시 캡션 톤으로 바꿨다.
- 노트 제목, 진행 표시, 안내 문장, 탭 텍스트, 챕터 버튼 텍스트는 밝은 색으로 바꿔 가독성을 유지했다.
- 탭/챕터 버튼/증거 카드/기록 카드의 밝은 종이 배경을 같은 어두운 톤으로 맞췄다.
- 질문 노트의 줄무늬, 테이프, 장식선은 낮은 알파의 황동색 보조선 정도로 줄였다.
- 현재 숨겨져 있는 floating lead slip도, 나중에 다시 켜졌을 때 밝은 포스트잇처럼 튀지 않도록 어두운 캡션 탭 스타일로 낮춰 두었다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-note-panel-muted-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-note-panel-muted-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-before-note-panel-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-panel-muted-main-visible.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-panel-muted-open-visible.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-panel-muted-answer-laptop-visible.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-panel-muted-hotspot-visible.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-panel-muted-main-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-panel-muted-open-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-panel-muted-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-panel-muted-long-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-note-panel-muted-start-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 메인 화면 start closed 검증 PASS
- 질문 노트 open 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 질문 노트 오른쪽 패널 평균 밝기: 178.5 -> 87.0
- 질문 노트 본문 평균 밝기: 195.6 -> 67.2
- 전체 화면 평균 밝기: 137.4 -> 127.2
- 보호 대상 폴더 중 `PixelRPG`, `TextAdventure`, `MobilityJourneyUnity`, `MobilityJourneyUnity_RESTORED_20260526_검증용` 수정 시간 변화 없음

검증 메모:

- Unity standalone 캡처는 GUI 창을 숨긴 상태(`Start-Process -WindowStyle Hidden`)로 실행하면 검은 화면이 찍힌다.
- 따라서 state 검증은 숨김 실행을 써도 되지만, 실제 화면 캡처는 숨김 없이 `Start-Process -Wait`로 실행해야 한다.

남은 판단:

- 오른쪽 질문 노트가 밝은 종이 UI로 튀는 문제는 크게 줄었다.
- 여전히 남는 싸구려 느낌은 개별 UI 카드보다 자산의 공통 제작 조건 문제에 가깝다. 배경, 아바타, 소품, UI가 모두 같은 조명/재질/렌즈 조건으로 보이도록 추가로 맞춰야 한다.

## 2026-05-27 추가 패스: 장면 공통 컬러그레이드와 아바타 tint 조정

이전 캡처에서 남은 주요 문제:

- UI 카드류는 많이 눌렀지만, 아바타가 배경보다 조금 더 밝고 깨끗하게 떠 있었다.
- 배경에는 `Scene Warm Wash`, depth layer, grain이 적용되어 있었지만, 아바타/소품까지 한 번에 묶는 공통 lens grade는 약했다.
- 주인공은 밝아야 하지만, 얼굴/상체가 같은 방 조명에 들어온 느낌보다 별도 스프라이트처럼 읽히는 것이 남은 구림의 원인으로 보였다.

이번 조정:

- 메인 아바타와 시작 화면 아바타 tint를 `1.000/0.974/0.925`에서 `0.970/0.934/0.858`로 낮춰 과하게 깨끗한 하이라이트를 줄였다.
- `CreateSceneUnifyingOverlay`에 `Scene Shared Amber Grade`를 추가해 배경, 아바타, 소품이 같은 따뜻한 카메라 톤을 지나가도록 했다.
- `GetSceneVignetteSprite()`를 추가하고 `Scene Shared Lens Vignette`를 적용했다. 화면 중앙은 거의 유지하고, 상단/하단/모서리만 아주 낮은 알파로 묶는다.
- 기존 grain은 유지해 새 grade 위에서 전체 장면의 표면 질감을 공유하게 했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-scene-grade-vignette-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-scene-grade-vignette-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-grade-vignette-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-grade-vignette-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-grade-vignette-note-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-grade-vignette-hotspot-d3d11.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-grade-vignette-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-grade-vignette-main-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-grade-vignette-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-grade-vignette-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-grade-vignette-long-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-scene-grade-vignette-start-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 메인 화면 start closed 검증 PASS
- 질문 노트 open 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 아바타 중심 평균 밝기: 148.8 -> 146.5
- 아바타 얼굴/상체 평균 밝기: 172.9 -> 169.5
- 배경 왼쪽 벽 평균 밝기: 132.4 -> 131.3
- 전체 화면 평균 밝기: 134.2 -> 131.7
- 전체 diff 평균은 약 3-4 수준이라 장면을 과하게 어둡게 덮는 변화는 아님
- 보호 대상 폴더 중 `PixelRPG`, `TextAdventure`, `MobilityJourneyUnity`, `MobilityJourneyUnity_RESTORED_20260526_검증용` 수정 시간 변화 없음

검증 메모:

- D3D12에서 핫스팟 screenshot smoke가 캡처 파일을 만든 뒤 종료 코드 `-1073741819`를 반환하는 경우가 있었다. Player.log에는 앱 예외가 없고 정상 shutdown 로그만 남았다.
- 같은 smoke를 `-force-d3d11`로 실행하면 ExitCode 0으로 통과했다. 이후 핫스팟 state/capture 검증은 `-force-d3d11` 기준으로 기록했다.

남은 판단:

- 아바타가 배경과 별도 레이어처럼 뜨는 정도는 조금 줄었다.
- 다만 완전한 고급감은 여전히 원본 자산의 문제에 묶여 있다. 배경과 아바타가 같은 생성/렌더링 조건에서 만들어진 게 아니라서, 코드 레벨의 tint/vignette만으로는 한계가 있다.

## 2026-05-27 추가 패스: 갈색 일변도 완화를 위한 노트북 cool accent

이전 캡처에서 남은 주요 문제:

- 최신 메인 화면 hue 분포가 사실상 빨강/주황/갈색 계열에 몰려 있었다.
- 따뜻한 전시 톤은 맞지만, 보색이나 실사용 광원이 거의 없어 전체가 한 가지 필터를 씌운 화면처럼 읽혔다.
- 무작위 파란 장식은 어색하므로, 장면 안에서 설명되는 차가운 색은 노트북 화면/실내 반사광으로 제한하는 편이 맞다.

이번 조정:

- `Reactive Laptop Cool Bounce`를 추가해 노트북 주변에 약한 청록색 대기광을 만들었다.
- 노트북 화면과 화면 라인을 완전히 꺼진 상태가 아니라 아주 낮은 알파로 유지했다.
- `Scene Left Window Cool Fill`을 추가해 왼쪽 장면에 약한 cool fill을 넣었다. 장식용 도형이 아니라 실내광/노트북광의 색 균형 보정 역할이다.
- 첫 시도는 너무 약해서 hue 분포가 거의 바뀌지 않았고, 두 번째 조정에서 알파를 조금 올렸다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-cool-fill-balanced-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-cool-fill-balanced-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-cool-fill-balanced-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-cool-fill-balanced-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-cool-fill-balanced-note-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-cool-fill-balanced-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-cool-fill-balanced-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-cool-fill-balanced-main-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-cool-fill-balanced-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-cool-fill-balanced-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-cool-fill-balanced-long-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-cool-fill-balanced-start-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 메인 화면 start closed 검증 PASS
- 질문 노트 open 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 노트북 영역 평균 밝기: 86.7 -> 89.0
- 노트북 영역 평균 색상: `(109.3, 87.8, 63.0)` -> `(107.5, 90.7, 68.9)`
- 왼쪽 장면 평균 채도: 0.321 -> 0.305
- 전체 화면 평균 밝기: 131.7 -> 131.7
- hue 분포는 아직 따뜻한 계열 중심이지만, 빨강/주황 편중이 소폭 완화됨
- 보호 대상 폴더 중 `PixelRPG`, `TextAdventure`, `MobilityJourneyUnity`, `MobilityJourneyUnity_RESTORED_20260526_검증용` 수정 시간 변화 없음

남은 판단:

- 갈색 필터처럼 보이는 문제는 조금 완화됐지만, 아직 전체 팔레트는 따뜻한 계열 중심이다.
- 다음에 더 밀어붙인다면 단순 색보정보다 원본 배경/아바타/소품을 같은 art direction으로 다시 뽑는 쪽이 효과가 크다.

## 2026-05-27 추가 패스: 오른쪽 상단 빈 종이 탭을 낮은 알파 아이콘 버튼으로 정리

이전 캡처에서 남은 주요 문제:

- 오른쪽 위의 질문 노트/기록 버튼이 텍스트 없는 종이 탭처럼 보였다.
- 기능 버튼인데도 빈 장식 카드처럼 떠 있어, 화면이 완성된 게임 UI라기보다 임시 UI를 얹은 것처럼 읽힐 수 있었다.
- `right_note_button`/`button_pair` 영역 edge가 주변 장면보다 높아 작은 UI 조각이 눈에 걸렸다.

이번 조정:

- 질문 노트 버튼과 기록 버튼 크기를 40x20 종이 탭에서 30x28 아이콘 버튼으로 조정했다.
- 첫 아이콘화 시도에서는 작은 선이 많아 edge가 오히려 증가했다.
- 이후 배경/아이콘/라인 알파를 낮추고 책갈피/노트 아이콘을 단순화했다.
- 열린 질문 노트 상태의 닫기 `×` 표시는 유지했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-top-controls-subtle-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-top-controls-subtle-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-controls-subtle-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-controls-subtle-note-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-controls-subtle-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-controls-subtle-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-controls-subtle-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-controls-subtle-main-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-controls-subtle-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-controls-subtle-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-controls-subtle-long-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-top-controls-subtle-start-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 메인 화면 start closed 검증 PASS
- 질문 노트 open 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 오른쪽 버튼 쌍 edge: 12.4 -> 11.7
- 오른쪽 노트 버튼 영역 edge: 9.8 -> 9.2
- 첫 아이콘화 시도는 edge가 13.7까지 올라갔고, 최종 subtle 조정으로 다시 낮춤
- 보호 대상 폴더 중 `PixelRPG`, `TextAdventure`, `MobilityJourneyUnity`, `MobilityJourneyUnity_RESTORED_20260526_검증용` 수정 시간 변화 없음

남은 판단:

- 오른쪽 상단의 임시 UI 조각 느낌은 줄었다.
- 다만 수치상 변화가 작고, 전체 품질을 결정하는 가장 큰 축은 여전히 원본 자산의 통일성이다.

## 2026-05-27 추가 패스: 기본 대화 상태의 `쓰기` 버튼 숨김

이전 캡처에서 남은 주요 문제:

- 직접 입력창은 기본 상태에서 닫혀 있는데, 하단 대화 패널에는 `쓰기` 버튼이 계속 남아 있었다.
- 질문 노트와 핫스팟이 기본 입력 경로인 현재 구성에서는, 이 버튼이 별도 앱 UI처럼 보이며 프로토타입 느낌을 만든다.
- 직접 입력 기능은 유지해야 하므로 버튼을 삭제하지 않고, 직접 입력 모드가 열렸을 때만 보이도록 바꾸는 것이 맞다.

이번 조정:

- `UpdateQuestionInputLayout()`에서 `sendButton.gameObject.SetActive(directInputOpen)`을 적용했다.
- 기본 상태에서는 하단 대화 패널의 `쓰기` 버튼이 보이지 않는다.
- 직접 입력 모드가 열리면 입력창과 함께 `묻기` 버튼이 보인다.
- 버튼 라벨도 상태에 따라 `쓰기`/`묻기`로 바뀌지 않고, 보이는 상태에서는 항상 `묻기`로 고정했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-hide-idle-write-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-hide-idle-write-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hide-idle-write-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hide-idle-write-input-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hide-idle-write-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hide-idle-write-note-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hide-idle-write-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hide-idle-write-main-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hide-idle-write-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hide-idle-write-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hide-idle-write-long-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-hide-idle-write-start-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 메인 화면 start closed 검증 PASS
- 질문 노트 open 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 직접 입력 open 캡처 생성 완료
- 기본 화면과 직접 입력 open 화면의 diff bbox가 하단 대화 패널 쪽에 잡힘
- 보호 대상 폴더 중 `PixelRPG`, `TextAdventure`, `MobilityJourneyUnity`, `MobilityJourneyUnity_RESTORED_20260526_검증용` 수정 시간 변화 없음

남은 판단:

- 기본 상태에서 보이는 불필요한 조작 버튼 하나를 줄였다.
- 개별 UI 잔여물은 계속 줄고 있지만, 전체 완성도는 여전히 자산 통일성과 화면 구도에 더 크게 좌우된다.

## 2026-05-27 추가 패스: 하단 대화창 회전 제거

이전 캡처에서 남은 주요 문제:

- 하단 대화 패널은 색과 밝기는 전시 캡션 쪽으로 정리됐지만, 패널 전체가 아직 `-1.65도` 기울어져 있었다.
- 이 기울기는 종이 조각을 붙인 듯한 스크랩북 느낌을 만들고, 화면 하단 UI를 안정적인 자막/캡션이 아니라 임시 프로토타입 요소처럼 보이게 했다.
- 기능 구조를 바꾸기보다, 대화창의 시각적 기준선을 먼저 수평으로 맞추는 것이 더 안전하다.

이번 조정:

- `Dialogue Plaque Shadow`의 `localRotation`을 `Quaternion.identity`로 변경했다.
- `Dialogue Exhibit Plaque`의 `localRotation`을 `Quaternion.identity`로 변경했다.
- 대화 내용, 스크롤, 직접 입력, 질문 노트, 핫스팟 동작은 그대로 유지했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-dialogue-plaque-level-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-dialogue-plaque-level-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-plaque-level-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-plaque-level-input-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-plaque-level-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-plaque-level-note-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-plaque-level-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-plaque-level-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-plaque-level-main-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-plaque-level-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-plaque-level-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-plaque-level-long-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-dialogue-plaque-level-start-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 메인 화면 start closed 검증 PASS
- 질문 노트 open 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 새 캡처 크기: 1920x1080
- 이전 메인 캡처와 새 메인 캡처의 diff bbox: `646,866-1272,994`
- `lower_scene_no_ui` 밝기/채도/edge 변화 없음: `172.1/0.389/5.1 -> 172.1/0.389/5.1`
- `desk_foreground` 밝기/채도/edge 변화 없음: `147.5/0.383/4.8 -> 147.5/0.383/4.8`
- 보호 대상 폴더 중 `PixelRPG`, `TextAdventure`, `MobilityJourneyUnity`, `MobilityJourneyUnity_RESTORED_20260526_검증용` 수정 시간 변화 없음

남은 판단:

- 하단 대화창의 임시 종이 조각 느낌은 줄었다.
- 이번 변화는 배경이나 전경 책상 레이어를 흔들지 않고, 대화 UI의 안정감만 개선했다.
- 여전히 크게 구려 보인다면 다음 원인은 UI 회전보다 원본 장면 자산의 자잘한 물체 밀도, 아바타/배경 렌더 질감 불일치, 그리고 전시용 앱이라기보다 웹 프로토타입처럼 보이는 오른쪽 정보 구조일 가능성이 더 크다.

## 2026-05-27 추가 패스: 오른쪽 질문 보드 폭과 기준선 정리

이전 캡처에서 남은 주요 문제:

- 질문 노트가 좁고 세로로 긴 형태라 전시용 질문 보드보다 휴대폰 앱 창처럼 보였다.
- 본체가 `-1.1도` 기울어져 있어, 하단 대화창에서 제거한 스크랩북식 임시 UI 느낌이 오른쪽 패널에 남아 있었다.
- 탭 3개가 고정 폭으로 왼쪽에 몰려 있어, 열린 패널 내부가 작은 버튼 조각들의 묶음처럼 보였다.

이번 조정:

- `Question Note Board`의 폭과 높이를 늘려 질문 선택 보드처럼 읽히게 했다.
- `Question Note Board`의 `localRotation`을 `Quaternion.identity`로 변경했다.
- 상단 탭 3개를 패널 폭에 맞춰 3등분 배치했다.
- 질문/핫스팟/대화 기능은 그대로 유지했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-question-board-wider-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-question-board-wider-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-board-wider-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-board-wider-input-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-board-wider-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-board-wider-note-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-board-wider-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-board-wider-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-board-wider-main-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-board-wider-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-board-wider-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-board-wider-long-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-question-board-wider-start-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 메인 화면 start closed 검증 PASS
- 질문 노트 open 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 새 캡처 크기: 1920x1080
- 이전 note-open 캡처와 새 note-open 캡처의 diff bbox: `1512,178-1868,756`
- 변화는 오른쪽 질문 보드 영역에 집중됨
- `note_tabs_upper` edge: `8.1 -> 3.8`
- `note_inner_buttons` edge: `6.3 -> 3.4`
- `main_dialogue_area` 밝기/채도/edge 변화 없음: `127.7/0.444/6.2 -> 127.7/0.444/6.2`
- `avatar_face_area` 밝기/채도/edge 변화 없음: `166.2/0.400/6.7 -> 166.2/0.400/6.7`
- 보호 대상 폴더 중 `PixelRPG`, `TextAdventure`, `MobilityJourneyUnity`, `MobilityJourneyUnity_RESTORED_20260526_검증용` 수정 시간 변화 없음

남은 판단:

- 오른쪽 질문 패널의 휴대폰 앱 창 느낌과 빽빽한 작은 버튼감은 줄었다.
- UI 조각 정리는 대부분 진행됐고, 남는 어색함은 이제 화면 위젯보다 원본 일러스트 자산의 스타일 통일성, 배경 소품 밀도, 아바타와 배경의 렌더 질감 차이 쪽일 가능성이 크다.

## 2026-05-27 추가 패스: 아바타 존재감과 배경 질감 통일

이전 캡처에서 남은 주요 문제:

- 아바타가 장면 안의 사람이라기보다 반투명한 회색 컷아웃처럼 보였다.
- 아바타 처리에서 채도/대비와 어두운 선을 너무 많이 눌렀고, 하체 쪽 책상/안개 블렌드와 전경 책상 오버레이가 강했다.
- 배경은 실사 렌더처럼 세부 묘사가 많고, 아바타는 2D 일러스트라 서로 다른 자산을 겹친 느낌이 남았다.

이번 조정:

- 아바타 팔레트 보정 강도를 줄여 원본 색과 어두운 선을 조금 더 살렸다.
- 아바타 내부 블러, 하체 안개, 책상색 블렌드, 하체 알파 페이드를 줄였다.
- 전경 책상 오버레이 중 `Foreground Avatar Desk Blend`, `Foreground Avatar Desk Occluder`, `Foreground Avatar Contact Feather`의 알파를 낮췄다.
- 배경 원본 파일은 건드리지 않고, 화면 표시용 배경 텍스처만 런타임에서 한 번 생성/캐싱하도록 했다.
- 표시용 배경에는 약한 3x3 소프트닝, 채도/대비 감소, 따뜻한 룸 그레이드를 적용해 실사감을 약간 낮췄다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-presence-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-presence-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-bg-harmony-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-bg-harmony-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-bg-harmony-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-bg-harmony-input-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-bg-harmony-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-bg-harmony-note-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-bg-harmony-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-bg-harmony-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-bg-harmony-main-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-bg-harmony-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-bg-harmony-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-bg-harmony-long-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-avatar-bg-harmony-start-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 메인 화면 start closed 검증 PASS
- 질문 노트 open 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 새 캡처 크기: 1920x1080
- 아바타 존재감 패스 diff bbox: `616,318-1054,752`
- 배경 질감 통일 패스 diff bbox: `0,0-1918,870`
- `avatar_jacket` edge: `5.3 -> 5.7 -> 5.3`
- `avatar_jacket` 밝기: `125.8 -> 118.8 -> 119.4`
- `adjacent_background` 채도/edge: `0.440/7.2 -> 0.440/7.2 -> 0.356/6.5`
- `bookshelf_detail` 채도/edge: `0.426/5.9 -> 0.426/5.9 -> 0.343/5.2`
- `dialogue_panel` 밝기/채도/edge 유지: `127.7/0.444/6.2 -> 127.6/0.442/6.2`
- 보호 대상 폴더 중 `PixelRPG`, `TextAdventure`, `MobilityJourneyUnity`, `MobilityJourneyUnity_RESTORED_20260526_검증용` 수정 시간 변화 없음

남은 판단:

- 아바타가 이전보다 덜 회색 스티커처럼 보이고, 배경의 실사적 세부감도 줄었다.
- 그래도 아바타/배경 원본 스타일이 완전히 같은 자산은 아니기 때문에, 끝까지 어색함을 없애려면 같은 프롬프트/같은 렌더 스타일로 아바타와 배경을 재생성하는 쪽이 더 근본적이다.

## 2026-05-27 추가 패스: 책상 전경 마스크 transition 정리

이전 캡처에서 남은 주요 문제:

- 화면 중간의 얇은 수평 seam을 배경 텍스처 후처리로 직접 지우려는 시도는 실패했다.
- 텍스처 좌표를 잘못 잡은 첫 시도는 영향이 거의 없었고, 좌표를 맞춘 두 번째 시도는 책장/벽에 넓은 가로 번짐을 만들어 더 나빠졌다.
- 따라서 seam 보정 코드는 제거했다. 이 문제는 표시 텍스처에서 억지로 문지르기보다, 원본 배경 자산을 새로 만드는 쪽이 맞다.
- 대신 실제로 아바타를 흐리게 만드는 주범은 `GetBackgroundDeskForegroundSprite()`의 넓은 책상 전경 transition이었다.

이번 조정:

- 실패한 `BlendBackgroundHorizontalSeam()` 호출과 함수는 제거했다.
- 책상 전경 마스크의 transition 폭을 `tableTop + 0.070f`에서 `tableTop + 0.040f`로 좁혔다.
- 마스크의 밝은 워시를 `0.095f`에서 `0.060f`로 줄였다.
- 하단 glow를 `0.030f`에서 `0.016f`로 줄였다.
- 책상은 여전히 아바타 앞에 오지만, 하체/팔 주변의 넓은 노란 반투명 안개는 약해지도록 조정했다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-bg-seam-soften-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-bg-seam-soften-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-bg-seam-soften2-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-bg-seam-soften2-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-occlusion-light-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-avatar-occlusion-light-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity_desk_mask_crisp_pass1_build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity_desk_mask_crisp_build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_mask_crisp_main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_mask_crisp_input_open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_mask_crisp_answer_laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_mask_crisp_note_open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_mask_crisp_hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_mask_crisp_start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_mask_crisp_main_state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_mask_crisp_note_state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_mask_crisp_hotspot_state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_mask_crisp_long_state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui_desk_mask_crisp_start_state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 메인 화면 start closed 검증 PASS
- 질문 노트 open 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 새 캡처 크기: 1920x1080
- 실패했던 수평 seam 보정으로 생긴 넓은 가로 번짐은 최종 캡처에 남기지 않음
- `desk_avatar_transition` 밝기/채도/edge: `123.9/0.364/4.5 -> 121.8/0.366/4.7`
- `avatar_lower_fade` 밝기/채도/edge: `144.5/0.386/4.4 -> 141.8/0.393/4.6`
- `foreground_desk` 밝기/채도/edge: `154.2/0.407/6.5 -> 151.3/0.424/6.7`
- `bookshelf_detail` 밝기/채도/edge 변화 없음: `108.3/0.343/5.2 -> 108.3/0.343/5.2`
- 보호 대상 폴더 중 `PixelRPG`, `TextAdventure`, `MobilityJourneyUnity`, `MobilityJourneyUnity_RESTORED_20260526_검증용` 수정 시간 변화 없음

남은 판단:

- 책상 경계의 노란 반투명 안개는 조금 줄었다.
- 얇은 수평 seam은 원본 배경 자산에 가까운 문제라, 코드 후처리로 억지 제거하면 더 큰 번짐을 만든다.
- 다음 근본 개선은 배경을 새로 생성하거나, 아바타와 배경을 같은 스타일로 다시 뽑는 것이다.

## 2026-05-27 추가 패스: stylized 배경 자산 직접 적용

목표:

- 런타임 후처리로 배경을 계속 문지르는 방식은 한계가 있었다.
- 특히 수평 seam 보정처럼 텍스처를 직접 섞는 시도는 장면 전체에 가로 번짐을 만들 수 있었다.
- 그래서 원본 배경을 직접 덮어쓰지 않고, 별도 stylized 배경 자산을 추가해서 앱이 우선 사용하도록 바꿨다.

변경:

- `Assets/Resources/Scene/interview_room_background_stylized.png` 추가
- `Assets/Resources/Scene/interview_room_background_stylized.png.meta` 추가
- `LoadBackgroundTexture()`가 stylized 배경을 먼저 로드하고, 없으면 `interview_room_background_v2`, `interview_room_background` 순서로 fallback
- stylized 배경은 이미 한 번 보정된 파일이므로 `CreateBackgroundDisplayTexture()`를 다시 통과하지 않게 처리
- 원본 배경 파일은 삭제하거나 덮어쓰지 않았다.

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-stylized-bg-direct-pass1-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-stylized-bg-direct-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-stylized-bg-direct-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-stylized-bg-direct-input-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-stylized-bg-direct-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-stylized-bg-direct-note-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-stylized-bg-direct-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-stylized-bg-direct-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-stylized-bg-direct-main-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-stylized-bg-direct-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-stylized-bg-direct-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-stylized-bg-direct-long-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-stylized-bg-direct-start-state.tsv
```

검증 결과:

- Unity 빌드 2회 ExitCode 0
- 필터 기준 관련 오류/경고 로그 없음
- 빌드 로그에 `Assets/Resources/Scene/interview_room_background_stylized.png` 포함 확인
- 메인 화면 start closed 검증 PASS
- 질문 노트 open 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 최신 캡처 크기: 1920x1080
- 보호 대상 폴더 중 `PixelRPG`, `TextAdventure`, `MobilityJourneyUnity`, `MobilityJourneyUnity_RESTORED_20260526_검증용` 수정 시간 변화 없음

최신 비교:

```text
desk-mask-crisp    avatar_face             161.2 / 0.300 / 1.9
stylized-bg-direct avatar_face             161.2 / 0.290 / 1.9
desk-mask-crisp    avatar_jacket           132.5 / 0.280 / 1.7
stylized-bg-direct avatar_jacket           132.5 / 0.280 / 1.7
desk-mask-crisp    adjacent_background     142.1 / 0.350 / 2.2
stylized-bg-direct adjacent_background     142.0 / 0.330 / 2.3
desk-mask-crisp    bookshelf_detail        109.5 / 0.340 / 1.8
stylized-bg-direct bookshelf_detail        108.2 / 0.330 / 1.8
desk-mask-crisp    foreground_desk         163.7 / 0.400 / 1.8
stylized-bg-direct foreground_desk         163.3 / 0.340 / 1.5
desk-mask-crisp    dialogue_panel          124.9 / 0.470 / 2.8
stylized-bg-direct dialogue_panel          124.5 / 0.380 / 2.7
```

숫자는 `brightness / saturation / edge` 순서다.

현재 판단:

- stylized 배경 적용으로 배경과 책상의 채도는 줄었다.
- 하지만 아바타 얼굴/재킷의 edge와 밝기는 거의 그대로라서, 아바타 자체가 배경과 같은 조명/렌더링 스타일로 바뀐 것은 아니다.
- 그래서 전체 화면은 조금 더 통일됐지만, 여전히 아바타가 배경 위에 붙은 별도 레이어처럼 보일 수 있다.
- 이 단계 이후의 근본 해결은 코드 미세조정보다 자산 재생성이다. 같은 스타일 프롬프트로 배경과 아바타를 다시 만들거나, 현재 배경을 버리고 아바타 중심의 더 단순한 2D 전시 배경으로 갈아타는 쪽이 맞다.

## 2026-05-27 추가 패스: flat 2D 배경으로 실사/일러스트 충돌 제거

목표:

- 이전 화면의 핵심 문제는 반실사 배경 위에 일러스트 아바타가 붙은 것처럼 보이는 스타일 충돌이었다.
- 배경 후처리만으로는 이 충돌을 없앨 수 없었다.
- 그래서 새 배경을 복잡한 반실사 방이 아니라, 아바타와 같은 2D 전시/상담 공간으로 단순화했다.

변경:

- `Assets/Resources/Scene/interview_room_background_flat2d.png` 추가
- `Assets/Resources/Scene/interview_room_background_flat2d.png.meta` 추가
- `LoadBackgroundTexture()`가 flat2d 배경을 최우선으로 사용
- flat2d/stylized처럼 이미 보정된 배경은 `CreateBackgroundDisplayTexture()`를 다시 통과하지 않도록 정리
- flat2d 배경에 맞춰 전체 warm wash, depth ellipse, foreground desk haze, amber grade 강도를 낮춤
- 아바타 후처리의 과한 desaturation/blur/haze를 줄여 얼굴과 재킷이 덜 뭉개지게 조정
- flat2d에서 foreground desk pixel mask를 완전히 끄는 실험도 했지만, 아바타 원본의 작은 책상 띠가 드러나 더 나빠져서 최종 상태에는 남기지 않음

산출물:

```powershell
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-flat2d-bg-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-flat2d-bg-crisp-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-flat2d-bg-nomask-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-flat2d-bg-avatarcrisp-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\unity-flat2d-bg-avatarcrisp-final-build.log
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-flat2d-bg-avatarcrisp-final-main.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-flat2d-bg-avatarcrisp-final-input-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-flat2d-bg-avatarcrisp-final-answer-laptop.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-flat2d-bg-avatarcrisp-final-note-open.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-flat2d-bg-avatarcrisp-final-hotspot.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-flat2d-bg-avatarcrisp-final-start.png
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-flat2d-bg-avatarcrisp-final-main-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-flat2d-bg-avatarcrisp-final-note-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-flat2d-bg-avatarcrisp-final-hotspot-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-flat2d-bg-avatarcrisp-final-long-state.tsv
.\99_GroupProject\Interviewee1UnityAvatarChat\Build\ui-flat2d-bg-avatarcrisp-final-start-state.tsv
```

검증 결과:

- Unity 빌드 ExitCode 0
- 최종 빌드 로그에 `Assets/Resources/Scene/interview_room_background_flat2d.png` 포함 확인
- 필터 기준 관련 오류/경고 로그 없음
- 메인 화면 start closed 검증 PASS
- 질문 노트 open 검증 PASS
- 핫스팟 미리보기 open 검증 PASS
- 시작 화면 open 검증 PASS
- 긴 답변 스크롤/텍스트 fit 검증 PASS
- 아바타 비율/크기 검증 PASS
- 최종 캡처 크기: 1920x1080
- 보호 대상 폴더 중 `PixelRPG`, `TextAdventure`, `MobilityJourneyUnity`, `MobilityJourneyUnity_RESTORED_20260526_검증용` 수정 시간 변화 없음

최신 비교:

```text
stylized-bg-direct avatar_face             161.2 / 0.290 / 1.9
flat2d-final       avatar_face             162.4 / 0.230 / 2.4
stylized-bg-direct avatar_jacket           132.5 / 0.280 / 1.7
flat2d-final       avatar_jacket           130.1 / 0.170 / 1.8
stylized-bg-direct adjacent_background     142.0 / 0.330 / 2.3
flat2d-final       adjacent_background     193.9 / 0.180 / 0.9
stylized-bg-direct bookshelf_detail        108.2 / 0.330 / 1.8
flat2d-final       bookshelf_detail        160.3 / 0.260 / 1.1
stylized-bg-direct foreground_desk         163.3 / 0.340 / 1.5
flat2d-final       foreground_desk         173.6 / 0.360 / 1.2
stylized-bg-direct dialogue_panel          124.5 / 0.380 / 2.7
flat2d-final       dialogue_panel          117.4 / 0.460 / 2.3
```

숫자는 `brightness / saturation / edge` 순서다.

현재 판단:

- 배경이 더 단순해져서 반실사 방과 일러스트 아바타가 충돌하던 문제는 크게 줄었다.
- 아바타도 이전보다 edge가 올라가 덜 뭉개진다.
- 다만 flat2d 배경은 의도적으로 단순하기 때문에, "고급 일러스트"라기보다 "전시용 프로토타입을 깔끔하게 정리한 화면"에 가깝다.
- 완성도를 더 끌어올리려면 다음 단계는 런타임 보정이 아니라 같은 스타일의 배경/아바타를 한 번에 다시 제작하는 것이다.

