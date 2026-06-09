using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.Networking;
using UnityEngine.UI;

public sealed class AvatarChatApp : MonoBehaviour
{
    private const string GameTitle = "겉!=속";
    private const string StartMenuDisplayTitle = "겉!=속";
    private const string GameSubtitle = "처음 보이는 겉모습이 그 사람의 전부는 아니라는 뜻입니다.";
    private const string LocalServerBaseUrl = "http://127.0.0.1:8765";
    private const string ServerStatusIdleText = "서버 답변 연결을 확인 중입니다.";
    private const string ServerRequiredCheckingText = "서버 연결 확인 중입니다. 서버가 정상일 때만 시작할 수 있습니다.";
    private const string ServerRequiredBlockedText = "서버 연결 필요 · 시작 파일로 서버를 먼저 켠 뒤 다시 실행해 주세요.";
    private const int TargetWidth = 1920;
    private const int TargetHeight = 1080;
    private const int RequiredQuestionCount = 5;
    private static readonly bool EnableSessionResume = false;
    private const int MicFrequency = 16000;
    private const int MaxRecordingSeconds = 15;
    private const int RecordArchiveSlotCount = 6;
    private const int RecordArchivePreviewHeaderFontSize = 14;
    private const int RecordArchivePreviewBodyFontSize = 18;
    private const float RecordArchivePreviewBodyLineSpacing = 1.16f;
    private const float KeyboardLineScrollStep = 0.09f;
    private const float KeyboardPageScrollStep = 0.34f;
    private const float AvatarHorizontalScale = 1.00f;
    private const string ThinkingReplyText = "생각을 정리하고 있어요.";

    private static string ServerBaseUrl
    {
        get
        {
#if UNITY_WEBGL && !UNITY_EDITOR
            if (Uri.TryCreate(Application.absoluteURL, UriKind.Absolute, out Uri uri))
            {
                return $"{uri.Scheme}://{uri.Authority}";
            }
#endif
            return LocalServerBaseUrl;
        }
    }
    private static readonly Color ModalOverlayColor = new Color(0.96f, 0.92f, 0.80f, 0.20f);
    private static readonly Color FocusModalOverlayColor = new Color(0.96f, 0.92f, 0.80f, 0.26f);
    private static readonly Color ModalShadowColor = new Color(0f, 0f, 0f, 0.14f);
    private static readonly Color32 RecordArchivePreviewHeaderColor = new Color32(18, 28, 42, 255);
    private static readonly Color32 RecordArchivePreviewBodyColor = new Color32(24, 32, 46, 255);
    private static readonly Color32 RecordArchivePreviewMutedColor = new Color32(48, 58, 72, 255);
    private const string SaveKey = "Interviewee1AvatarChat.Save.v1";
    private const string TextSizeKey = "Interviewee1AvatarChat.DialogueSize";
    private const string FullscreenKey = "Interviewee1AvatarChat.Fullscreen";
    private const string DisplayDefaultsVersionKey = "Interviewee1AvatarChat.DisplayDefaultsVersion";
    private const int CurrentDisplayDefaultsVersion = 2;
    private const string SoundLevelKey = "Interviewee1AvatarChat.SoundLevel";
    private const string ReducedMotionKey = "Interviewee1AvatarChat.ReducedMotion";
    private const string HighContrastKey = "Interviewee1AvatarChat.HighContrast";
    private const string LocalAnswerOnlyKey = "Interviewee1AvatarChat.LocalAnswerOnly";
    private const string OpeningText = "와줘서 고마워요. 책상 위 단서를 살펴보거나 질문 노트를 열어 보세요.";
    private const int DialoguePageSoftCharLimit = 320;
    private const float StoryModeLineDelaySeconds = 20.0f;
    private static readonly bool ShowFloatingLeadSlips = true;
    private static readonly bool UseIntegratedSceneArtwork = false;

    private readonly List<ChatMessage> history = new List<ChatMessage>();
    private readonly StringBuilder logBuilder = new StringBuilder();
    private readonly Dictionary<ExpressionState, Sprite> avatarSprites = new Dictionary<ExpressionState, Sprite>();
    private readonly Dictionary<ExpressionState, Sprite> avatarHandSprites = new Dictionary<ExpressionState, Sprite>();
    private readonly Dictionary<string, Sprite> generatedSprites = new Dictionary<string, Sprite>();
    private readonly System.Random leadQuestionRandom = new System.Random(Guid.NewGuid().GetHashCode());
    private readonly List<RectTransform> hotspotPulseRects = new List<RectTransform>();
    private readonly List<Image> hotspotPulseImages = new List<Image>();
    private readonly List<GameObject> hotspotRootObjects = new List<GameObject>();
    private readonly List<GameObject> hotspotLabelObjects = new List<GameObject>();
    private Sprite cachedBackgroundSprite;
    private RectTransform sceneFocusRect;
    private RectTransform sceneFocusGlowRect;
    private Image sceneFocusImage;
    private RectTransform sceneFocusSlipRect;
    private Image sceneFocusSlipImage;
    private Image sceneFocusTapeImage;
    private Text sceneFocusText;
    private Vector2 sceneFocusBasePosition;
    private float sceneFocusUntil;
    private float sceneFocusDuration;
    private bool sceneFocusSlipVisible = true;
    private string activeSceneFocusLabel = string.Empty;
    private readonly Dictionary<string, float> scenePropReactionUntil = new Dictionary<string, float>();
    private RectTransform reactiveLaptopGlowRect;
    private Image reactiveLaptopGlowImage;
    private RectTransform reactiveLaptopScreenRect;
    private Image reactiveLaptopScreenImage;
    private Image[] reactiveLaptopLineImages;
    private RectTransform reactiveBoardNoteRect;
    private Image reactiveBoardNoteImage;
    private Image[] reactiveBoardLineImages;
    private RectTransform reactiveCupSteamRectA;
    private RectTransform reactiveCupSteamRectB;
    private Image reactiveCupSteamImageA;
    private Image reactiveCupSteamImageB;
    private RectTransform reactiveNotebookInkRect;
    private Image[] reactiveNotebookInkImages;
    private RectTransform reactiveCrutchGlintRect;
    private Image reactiveCrutchGlintImage;
    private RectTransform reactiveDoorLightRect;
    private Image reactiveDoorLightImage;
    private readonly HashSet<string> discoveredThemes = new HashSet<string>();
    private string[] memoryNotes;
    private bool[] deepMemoryUnlocked;
    private int chatEntryCount;
    private readonly string playtestSessionId = "pt-" + DateTime.Now.ToString("yyyyMMdd-HHmmss") + "-" + Guid.NewGuid().ToString("N").Substring(0, 8);

    private readonly string[] leadQuestions =
    {
        "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?",
        "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
        "도움을 주고 싶을 때 어떤 말로 먼저 물어보는 게 가장 편한가요?",
        "직장 일과 박사과정 공부는 하루 안에서 어떻게 이어지나요?",
        "직장에서 필요한 도움을 말할 때 어떤 점을 가장 신경 쓰나요?",
        "책상 앞에서는 어떤 일을 가장 많이 하게 되나요?",
        "자취방에서 혼자 생활하며 직접 정하게 된 일들은 무엇인가요?",
        "미국과 한국의 이동 환경은 실제 생활에서 어떻게 다르게 느껴졌나요?",
        "혼자 사는 방은 독립이나 자기이해와 어떻게 연결되나요?",
        "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?",
        "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?",
        "함께 일하는 사람이 상황을 모를 때 무엇부터 말해 주는 편인가요?",
        "도움을 요청하는 일이 부담보다 조율에 가깝다고 느낀 이유는 무엇인가요?",
        "어떤 업무 장면에서 기여를 느끼나요?",
        "노트북과 메모는 하루에서 어떤 역할을 하나요?",
        "해야 할 일이 많을 때 끝까지 이어가게 하는 태도는 무엇인가요?",
        "이동 환경을 볼 때 단순히 편하다 불편하다 말하기 어려운 이유는 무엇인가요?",
        "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
        "엘리베이터나 화장실 정보가 하루의 피로와 어떻게 연결되나요?",
        "자취를 시작한 뒤 스스로 설명해야 하는 일이 어떻게 달라졌나요?",
        "게임이나 코인노래방 같은 취미는 하루의 분위기를 어떻게 바꾸나요?",
        "게임이나 코인노래방은 쉬는 시간의 분위기를 어떻게 바꾸나요?",
        "끈기나 어떻게든 흘러간다는 말은 어떤 생활 태도와 닿아 있나요?"
    };

    private readonly string[] memoryThemes =
    {
        "일상",
        "이동",
        "도움",
        "일과 공부",
        "독립",
        "취미"
    };

    private readonly string[] memoryCaptions =
    {
        "목발보다 먼저 있는 하루",
        "처음 가는 곳에서 먼저 살피는 길",
        "좋은 의도보다 필요한 말",
        "책상 앞에서 이어지는 일과 공부",
        "생활을 직접 정하며 생긴 감각",
        "쉬는 시간까지 보여 주는 입체감"
    };

    private readonly string[] themeLeadQuestions =
    {
        "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?",
        "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
        "도움을 주고 싶을 때 어떤 말로 먼저 물어보는 게 가장 편한가요?",
        "직장 일과 박사과정 공부는 하루 안에서 어떻게 이어지나요?",
        "자취방에서 혼자 생활하며 직접 정하게 된 일들은 무엇인가요?",
        "게임이나 코인노래방 같은 취미는 하루의 분위기를 어떻게 바꾸나요?"
    };

    private string[] GetCategoryQuestionBank(string theme)
    {
        switch (CanonicalTheme(theme))
        {
            case "일상":
                return new[]
                {
                    "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?",
                    "회사에 가고 공부하고 집에 돌아오는 하루는 어떤 순서로 이어지나요?",
                    "해야 할 일이 많을 때 끝까지 이어가게 하는 태도는 무엇인가요?",
                    "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?",
                    "끈기나 어떻게든 흘러간다는 말은 어떤 생활 태도와 닿아 있나요?",
                    "목발을 쓰는 날에도 하루에서 가장 평범하게 반복되는 일은 무엇인가요?",
                    "좋아하는 시간과 해야 하는 시간이 하루 안에서 어떻게 섞이나요?",
                    "처음 보는 사람이 가장 먼저 물어봐 주면 좋겠는 생활 질문은 무엇인가요?"
                };
            case "이동":
                return new[]
                {
                    "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?",
                    "입구와 엘리베이터, 화장실 정보는 하루의 피로와 어떻게 연결되나요?",
                    "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
                    "비가 오거나 바닥이 미끄러운 날에는 무엇을 더 신경 쓰게 되나요?",
                    "목발은 하루를 밖으로 이어 주는 도구라는 말은 어떤 뜻인가요?",
                    "처음 가는 공간에서 접근성을 확인하는 일이 왜 중요한가요?",
                    "이동 계획을 세울 때 가장 먼저 확인하는 정보는 무엇인가요?",
                    "미국과 한국의 이동 환경은 실제 생활에서 어떻게 다르게 느껴졌나요?"
                };
            case "도움":
                return new[]
                {
                    "도움을 주고 싶을 때 어떤 말로 먼저 물어보는 게 가장 편한가요?",
                    "바로 잡아 주기보다 설명할 시간을 주는 일이 왜 중요한가요?",
                    "혼자 할 수 있는 부분을 존중하는 도움은 어떤 모습인가요?",
                    "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?",
                    "좋은 의도와 실제로 편한 도움 사이에는 어떤 차이가 있나요?",
                    "도움을 요청하는 일이 부담보다 조율에 가깝다고 느낀 이유는 무엇인가요?",
                    "기다려 주는 태도가 도움의 일부가 될 때는 언제인가요?",
                    "어디를 잡아야 하는지 직접 설명할 시간이 필요한 이유는 무엇인가요?"
                };
            case "일과 공부":
                return new[]
                {
                    "책상 앞에서는 어떤 일을 가장 많이 하게 되나요?",
                    "직장 일과 컴퓨터공학 박사과정 공부는 하루 안에서 어떻게 이어지나요?",
                    "노트북과 메모는 하루에서 어떤 역할을 하나요?",
                    "어떤 업무 장면에서 자기 몫이나 기여를 느끼나요?",
                    "직장에서 필요한 도움을 말할 때 어떤 점을 가장 신경 쓰나요?",
                    "프로젝트를 마쳤을 때 느끼는 성취는 하루를 어떻게 다르게 보이게 하나요?",
                    "공부와 일을 병행하는 생활에서 가장 꾸준히 챙기는 리듬은 무엇인가요?",
                    "함께 일하는 사람이 상황을 모를 때 무엇부터 말해 주는 편인가요?"
                };
            case "독립":
                return new[]
                {
                    "혼자 사는 방은 독립이나 자기이해와 어떻게 연결되나요?",
                    "자취방에서 혼자 생활하며 직접 정하게 된 일들은 무엇인가요?",
                    "집안일, 생활비, 공과금 같은 일이 생활 감각을 어떻게 바꾸었나요?",
                    "자취를 시작한 뒤 스스로 설명해야 하는 일이 어떻게 달라졌나요?",
                    "자취방에서 하루를 챙길 때 가장 자주 신경 쓰는 일은 무엇인가요?",
                    "생활을 직접 정한다는 감각은 어떤 작은 선택에서 생기나요?",
                    "혼자 사는 공간에서 하루를 맞춰 가는 방식은 어떻게 달라졌나요?",
                    "독립은 큰 결심보다 어떤 반복되는 일에서 느껴졌나요?"
                };
            case "취미":
                return new[]
                {
                    "게임이나 코인노래방 같은 취미는 하루의 분위기를 어떻게 바꾸나요?",
                    "게임이나 코인노래방은 쉬는 시간의 분위기를 어떻게 바꾸나요?",
                    "쉬는 날에는 어떤 방식으로 긴장을 푸는 편인가요?",
                    "좋아하는 것을 챙기는 시간은 하루에서 어떤 역할을 하나요?",
                    "취미 이야기가 이동이나 도움 이야기와 다르게 느껴지는 이유는 무엇인가요?",
                    "게임을 하는 시간은 하루의 긴장을 어떻게 바꿔 주나요?",
                    "코인노래방 같은 여가가 자기답게 쉬는 시간으로 남는 이유는 무엇인가요?",
                    "해야 할 일 사이에 좋아하는 시간을 남겨 두는 일이 왜 중요한가요?"
                };
            default:
                return new string[0];
        }
    }

    private readonly string[] attitudeNames =
    {
        "단정",
        "배려",
        "호기심",
        "거리두기"
    };

    private readonly string[] firstImpressionOptions =
    {
        "목발",
        "책상",
        "표정"
    };

    private readonly string[] storyModeThemes =
    {
        "일상",
        "이동",
        "도움",
        "일과 공부",
        "독립",
        "취미"
    };

    private readonly string[] storyModeLines =
    {
        "하루를 시작할 때는 몸 상태와 이동할 길을 먼저 떠올립니다. 어디로 가는지, 얼마나 걸리는지, 오늘 해야 할 일이 무엇인지 하나씩 챙기면서 밖으로 나갈 준비를 해요.",
        "처음 가는 곳을 떠올릴 때 저는 목적지만 보지 않아요. 입구, 엘리베이터, 화장실, 돌아올 길까지 미리 그려 봅니다. 불안해서가 아니라, 하루를 너무 지치지 않게 보내고 싶어서예요.",
        "도움은 마음만큼이나 방식이 중요해요. 갑자기 붙잡기보다 먼저 물어봐 주시면, 제가 제 몸과 상황을 제 말로 설명할 수 있어요. 그 잠깐의 시간이 존중받는 느낌을 줍니다.",
        "책상 앞에서는 해야 할 일이 꽤 많아요. 회사 일도 정리하고, 컴퓨터공학 박사과정 공부도 이어 갑니다. 목발을 짚고 이동하는 시간만큼이나, 노트북 앞에서 제 몫을 해내는 시간도 제 하루에 크게 들어와 있어요.",
        "자취방에서는 작은 선택들이 모여 하루가 됩니다. 공과금, 집안일, 시간 관리 같은 평범한 일을 직접 챙기다 보니, 내 생활을 내가 정한다는 감각이 생겼어요.",
        "쉬는 시간도 분명한 제 이야기예요. 게임을 하고, 코인노래방에 가고, 좋아하는 걸 챙깁니다. 이동 이야기만 남으면 제 하루가 너무 단조롭게만 보이니까요."
    };

    private readonly string[] openingStoryThemes =
    {
        "일상",
        "이동",
        "도움",
        "일과 공부",
        "독립",
        "취미"
    };

    private readonly string[] openingStoryLines =
    {
        "질문을 시작하기 전에, 제 하루 이야기를 잠깐만 들려드릴게요. 저는 30대 초반 남성이고, 지체장애가 있어서 목발과 휠체어로 이동합니다. 회사에 가고, 공부를 하고, 집에 돌아와 제 생활을 챙기면서 지내요.",
        "목발은 제가 밖으로 나가 사람을 만나고 일하러 갈 때 쓰는 이동 도구예요. 처음 가는 곳이라면 입구와 엘리베이터, 화장실, 돌아올 길까지 미리 머릿속에 그려 둡니다.",
        "도움에 대해서는 이런 부탁을 드리고 싶어요. 돕고 싶은 마음은 정말 고맙지만, 그 마음만으로는 충분하지 않을 때가 있거든요. 바로 붙잡거나 끌어 주기보다 어떻게 하면 편한지 먼저 물어봐 주시면, 제가 제 몸과 상황을 제 말로 설명할 수 있어요. 그래야 혼자 할 수 있는 일과 도움이 필요한 일이 분명해집니다.",
        "책상 앞에서는 하루가 다시 일과 공부 쪽으로 넘어갑니다. 직장 일, 컴퓨터공학 박사과정, 노트북과 메모, 읽고 정리하는 시간이 차례로 이어져요. 밖으로 나갈 때는 이동을 많이 계산하지만, 돌아와서는 해야 할 일을 붙잡고 제 속도로 다시 정리합니다.",
        "자취방도 저를 보여 주는 중요한 공간이에요. 집안일, 생활비, 공과금, 시간 관리처럼 사소해 보이는 일을 직접 챙기다 보니, 내 생활을 내가 꾸려 간다는 감각이 생겼어요. 그래서 이 방은 제 장애를 설명하는 곳이라기보다, 제가 직접 고르고 맞춰 가며 사는 곳에 가깝습니다.",
        "마지막으로, 제 하루에도 쉬어 가는 시간이 있어요. 게임을 하고, 코인노래방에 가고, 좋아하는 걸 챙기는 시간도 분명한 제 일상이에요. 이동 이야기만 남으면 사람이 너무 단순하게만 보이거든요. 이제 목발, 도움, 책상, 자취방, 취미 중에서 먼저 궁금한 걸 골라 질문해 주세요."
    };

    private readonly string[] storyModeOuterCues =
    {
        "목발",
        "처음 가는 길",
        "도움 받는 순간",
        "책상",
        "자취방",
        "취미"
    };

    private readonly string[] storyModeInnerCues =
    {
        "하루를 손에 쥐는 시작",
        "덜 닳기 위한 확인",
        "내 말로 설명할 시간",
        "조건 안에서도 이어지는 자기 몫",
        "생활을 직접 정하는 감각",
        "좋아하는 것까지 포함한 하루"
    };

    private readonly string[] storyModePaceCues =
    {
        "짧은 정적 0.8초 · 낮은 방 톤 · 목발 쪽으로 천천히 시선 이동",
        "짧은 정적 0.7초 · 문밖 소리 낮춤 · 이동 경로 쪽으로 시선 이동",
        "짧은 정적 0.9초 · 손 닿는 소리 낮춤 · 도움 장면에 시선 고정",
        "짧은 정적 0.7초 · 키보드 소리 낮춤 · 책상 조명 강조",
        "짧은 정적 0.8초 · 방 톤 유지 · 자취방 단서에 시선 이동",
        "짧은 정적 1.0초 · 소리 여백 확보 · 취미 단서에서 마무리"
    };

    private Font uiFont;
    private Font uiSemiBoldFont;
    private Font uiBoldFont;
    private Image avatarImage;
    private RectTransform avatarRect;
    private Image avatarSilhouetteShadowImage;
    private RectTransform avatarSilhouetteShadowRect;
    private Image avatarSceneWashImage;
    private RectTransform avatarSceneWashRect;
    private Image avatarBackShadowImage;
    private RectTransform avatarBackShadowRect;
    private Image avatarContactShadowImage;
    private RectTransform avatarContactShadowRect;
    private Image avatarHandsImage;
    private RectTransform avatarHandsRect;
    private RectTransform avatarHandsContactShadowRect;
    private RectTransform dialogueContentRect;
    private RectTransform dialogueViewportRect;
    private RectTransform chatContentRect;
    private RectTransform chatViewportRect;
    private Text dialogueText;
    private Text speakerText;
    private Text chatLogText;
    private GameObject dialogueScrollCueObject;
    private Text dialoguePageCueText;
    private Button dialoguePageButton;
    private Text statusText;
    private Text leadText;
    private Image startMenuFlowPanel;
    private Text startSavePreviewText;
    private Text startObjectiveText;
    private Text noteTitleText;
    private Text noteEvidenceText;
    private Text noteHistoryText;
    private Text questionPhoneProgressText;
    private Text questionPhoneGuideText;
    private Text micButtonLabel;
    private InputField inputField;
    private Button sendButton;
    private Button micButton;
    private Button finishButton;
    private Button storyNextButton;
    private Button storyQuestionButton;
    private Button storyFinishButton;
    private Button noteToggleButton;
    private Button memoryBookButton;
    private Button continueButton;
    private Button startButton;
    private Button startNoteButton;
    private Button startStoryButton;
    private Button startSettingsButton;
    private Button startAboutButton;
    private Button dialogueSizeDownButton;
    private Button dialogueSizeUpButton;
    private Button[] settingsTextSizeButtons;
    private Button fullscreenButton;
    private Button soundButton;
    private Button reducedMotionButton;
    private Button highContrastButton;
    private Button localAnswerOnlyButton;
    private Button[] firstImpressionButtons;
    private Button[] leadButtons;
    private Button leadThemeButton;
    private Button leadRefreshButton;
    private GameObject[] leadShadows;
    private RectTransform[] leadRects;
    private RectTransform[] leadShadowRects;
    private Vector2[] leadBasePositions;
    private Vector2[] leadShadowBasePositions;
    private float[] leadBaseRotations;
    private bool[] leadHoverStates;
    private Button[] chapterButtons;
    private Button[] noteTabButtons;
    private Button moreButton;
    private Button closingButton;
    private Button completionMoreButton;
    private Button completionFinishButton;
    private Button closingCardSaveButton;
    private Button closingCardContinueButton;
    private Button closingCardCloseButton;
    private Button[] closingSensitiveQuestionButtons;
    private readonly List<Image> progressDots = new List<Image>();
    private Text progressText;
    private Scrollbar dialogueScrollbar;
    private ScrollRect dialogueScrollRect;
    private ScrollRect scrollRect;
    private ScrollRect noteHistoryScrollRect;
    private RectTransform noteHistoryContentRect;
    private RectTransform noteHistoryViewportRect;
    private GameObject questionNoteObject;
    private GameObject questionNoteShadowObject;
    private GameObject noteQuestionContent;
    private GameObject noteQuestionBodyObject;
    private GameObject noteEvidenceContentObject;
    private GameObject noteHistoryContentObject;
    private GameObject completionChoiceObject;
    private GameObject hotspotPreviewObject;
    private GameObject closingCardObject;
    private GameObject closingSensitiveQuestionObject;
    private GameObject firstImpressionObject;
    private Text closingCardQuoteText;
    private Text closingCardCaptionText;
    private Text closingCardSummaryText;
    private RectTransform closingCreditsTextRect;
    private Text firstImpressionPromptText;
    private Text hotspotPreviewTitleText;
    private Text hotspotPreviewQuestionText;
    private Button[] closingCardChoiceButtons;
    private GameObject startMenuObject;
    private GameObject pauseMenuObject;
    private GameObject settingsMenuObject;
    private GameObject aboutMenuObject;
    private GameObject memoryBookObject;
    private GameObject recordArchiveObject;
    private GameObject playtestFeedbackObject;
    private GameObject restartConfirmObject;
    private GameObject memoryUnlockToastObject;
    private CanvasGroup memoryUnlockToastGroup;
    private RectTransform memoryUnlockToastRect;
    private RectTransform recordArchiveContentRect;
    private RectTransform recordArchiveViewportRect;
    private Image[] memoryCardImages;
    private Image[] memoryCardIllustrationImages;
    private Image memoryCompletionBadgeImage;
    private Image recordArchiveDeleteHintPanel;
    private Image clearLocalDataHintPanel;
    private Button[] memoryCardButtons;
    private Image highContrastDimImage;
    private Text[] memoryCardTexts;
    private Image[] leadIllustrationImages;
    private Image[] chapterIllustrationImages;
    private Image closingCardIllustrationImage;
    private Text memoryBookCountText;
    private Text memoryBookSubtitleText;
    private Text memoryCompletionBadgeText;
    private Text memoryUnlockToastText;
    private string lastRewardLine = string.Empty;
    private Text recordArchiveListTitleText;
    private Text recordArchivePreviewHeaderText;
    private Text recordArchivePreviewText;
    private Text recordArchiveDeleteHintText;
    private Text clearLocalDataHintText;
    private Text playtestFeedbackEvidenceText;
    private Text playtestFeedbackReadinessText;
    private Text playtestFeedbackStatusText;
    private Text serverStatusText;
    private InputField playtestFeedbackInput;
    private InputField closingMessageInput;
    private Text closingMessageValidationText;
    private Button recordArchiveDeleteButton;
    private Button recordArchiveCancelDeleteButton;
    private Button clearLocalDataButton;
    private Button[] playtestRatingButtons;
    private Button[] playtestCommercialReadinessButtons;
    private Button[] playtestIssueSeverityButtons;
    private Button playtestQualityFocusButton;
    private Button[] recordArchiveButtons;
    private ScrollRect recordArchiveScrollRect;

    private Vector2 avatarBasePosition;
    private ExpressionState currentExpression = ExpressionState.Idle;
    private float expressionChangedAt;
    private int leadOffset;
    private int leadThemeCycleIndex;
    private int selectedLeadIndex;
    private int conversationTurns;
    private float closingCreditsStartedAt;
    private int dialogueSizeLevel;
    private int selectedClosingIndex;
    private int selectedMemoryCardIndex;
    private int selectedRecordArchiveIndex;
    private int selectedPlaytestRating = 2;
    private int selectedPlaytestCommercialReadiness = 2;
    private int selectedPlaytestIssueSeverity;
    private int selectedPlaytestFeedbackGroup;
    private int selectedPlaytestQualityFocus;
    private int currentNoteTabIndex;
    private int soundLevel;
    private bool fullscreenEnabled;
    private bool reducedMotionEnabled;
    private bool highContrastEnabled;
    private bool localAnswerOnly;
    private bool serverReady;
    private bool serverStatusKnown;
    private bool busy;
    private bool recording;
    private bool directInputOpen;
    private bool questionNoteOpen;
    private KeyCode? smokeKeyDownOverride;
    private bool memoryCompletionCelebrated;
    private bool pendingFreshStartWithPhone;
    private bool pendingFreshStartStoryMode;
    private bool pendingFirstImpressionOpenQuestionPhone;
    private bool openingStoryModeActive;
    private bool pendingOpeningStoryQuestionPhone;
    private bool storyModeActive;
    private bool storyModeAdvanceRequested;
    private bool pendingClosingSensitiveQuestion;
    private bool pendingCompletionChoiceAfterDialogue;
    private bool closingSensitiveQuestionAnswered;
    private int lastSubmitFrame = -1;
    private int storyModeIndex;
    private string[] currentLeadQuestions;
    private readonly List<string> dialoguePages = new List<string>();
    private int dialoguePageIndex;
    private string currentDialogueFullText = string.Empty;
    private string lastTheme = "시작";
    private string lastEvidenceLine = "아직 표시할 자료가 없습니다.";
    private string lastAnswerSource = "대기";
    private string lastServerError = string.Empty;
    private string serverRequiredMessage = ServerRequiredCheckingText;
    private string firstImpression = string.Empty;
    private int[] attitudeCounts;
    private string lastQuestionAttitude = string.Empty;
    private string pendingHotspotQuestion;
    private string pendingHotspotLabel;
    private string lastStoryModeShortcutAction = "none";
    private string currentStoryModeBeatLine = string.Empty;
    private string currentStoryModePaceLine = string.Empty;
    private string activeQuestionCategory = string.Empty;
    private int activeCategoryQuestionCount;
    private string lastChoiceConsequenceLine = string.Empty;
    private string lastMemoryCardAction = "none";
    private string lastMemoryBookShortcutAction = "none";
    private string lastClosingCardShortcutAction = "none";
    private string lastRecordArchiveShortcutAction = "none";
    private string lastPlaytestFeedbackShortcutAction = "none";
    private string lastStartMenuAction = "none";
    private string lastClearLocalDataAction = "none";
    private string micDevice;
    private string[] recordArchivePaths;
    private string lastSavedEndingRecordPath;
    private string lastSavedIntervieweeMessagePath;
    private string closingMessageToInterviewee = string.Empty;
    private string selectedClosingSensitiveQuestion = string.Empty;
    private string selectedClosingSensitiveAnswer = string.Empty;
    private string pendingDeleteRecordPath;
    private Coroutine storyModeCoroutine;
    private AudioClip recordingClip;
    private AudioSource sfxSource;
    private AudioSource ambienceSource;
    private AudioClip buttonClickClip;
    private AudioClip pageTurnClip;
    private AudioClip questionSelectClip;
    private AudioClip answerReadyClip;
    private AudioClip memoryUnlockClip;
    private AudioClip confirmClip;
    private AudioClip resultCardClip;
    private AudioClip categoryTransitionClip;
    private AudioClip errorClip;
    private AudioClip recordingStartClip;
    private AudioClip recordingStopClip;
    private AudioClip roomToneClip;
    private float memoryUnlockToastUntil;
    private float memoryUnlockToastDuration;
    private float memoryUnlockPulseUntil;
    private float pendingDeleteRecordUntil;
    private float pendingClearLocalDataUntil;
    private Coroutine serverStatusCoroutine;

    private readonly string[] closingQuotes =
    {
        "도움은 묻는 말에서 시작된다.",
        "처음 가는 길은 미리 살피는 하루다.",
        "처음 보인 장면은 하루와 같은 선 위에 있다."
    };

    private readonly string[] closingCaptions =
    {
        "바로 돕기 전에 먼저 묻는 태도.",
        "입구와 엘리베이터, 화장실과 돌아올 길까지 포함한 하루.",
        "목발, 책상, 표정 뒤에 이어진 일과 방, 취미."
    };

    private readonly string[] closingChoiceLabels =
    {
        "도움 방식",
        "이동 확인",
        "사람 보기"
    };

    private readonly string[] closingSensitiveQuestions =
    {
        "제가 실수로 도움을 앞세웠다면 어떤 태도가 더 편했을까요?",
        "불편해 보인다는 생각만으로 말을 걸 때 무엇이 부담이 될 수 있나요?",
        "장애에 대해 물을 때, 상대를 위해 먼저 지켜야 할 선은 무엇일까요?",
        "칭찬처럼 들려도 부담이 될 수 있는 말은 어떤 말일까요?",
        "도와주고 싶은 마음과 간섭은 어디서 갈라질까요?",
        "처음 본 인상만으로 보면 어떤 모습이 쉽게 빠질까요?"
    };

    private readonly string[] closingSensitiveAnswers =
    {
        "가장 편한 건 바로 손을 대기보다 먼저 물어봐 주는 태도예요. 예를 들면 '도움이 필요하시면 어떻게 도와드리면 될까요?'처럼 선택권을 제 쪽에 남겨 두는 말이 좋습니다.\n\n도움이 필요한 순간에도 사람마다 몸의 균형, 잡히면 편한 위치, 혼자 할 수 있는 범위가 다릅니다. 그래서 잠깐 기다려 주면 제가 제 상황을 설명할 수 있고, 그때 도움은 선의가 아니라 서로 맞춘 행동이 됩니다.",
        "불편해 보인다는 생각만으로 말을 걸면, 그 사람이 가진 다른 생활이 지워질 수 있어요. 걷는 모습이나 도구만 보고 '힘들겠다', '도와줘야겠다'로 시작하면 대화의 첫 자리가 이미 불편함으로 정해지거든요.\n\n정말 말을 걸고 싶다면 단정 대신 확인이 낫습니다. '괜찮으세요?'보다도 상황에 따라 '필요한 게 있으면 말씀해 주세요'처럼 물러설 수 있는 여지를 남겨 주면, 상대가 자기 속도와 방식으로 답할 수 있습니다.",
        "먼저 지켜야 할 선은 대답하지 않을 자유예요. 장애에 대한 질문은 당사자의 몸과 생활을 묻는 일이기 때문에, 질문하는 사람이 궁금하다고 해서 항상 답해야 하는 주제는 아닙니다.\n\n그래서 질문은 허락을 구하는 말에서 시작하는 편이 좋아요. '물어봐도 괜찮을까요?'라고 묻고, 상대가 짧게 답하거나 넘기면 거기서 멈추는 태도가 필요합니다. 그 선이 있어야 대화가 부담이 아니라 관계가 됩니다.",
        "칭찬처럼 들려도 부담이 되는 말은 그 사람의 평범한 일을 전부 극복담으로 만드는 말이에요. '대단하다', '나라면 못 했을 것 같다' 같은 말은 의도는 좋을 수 있지만, 듣는 사람에게는 매일의 생활이 계속 특별한 고생으로만 보인다는 느낌을 줄 수 있습니다.\n\n칭찬하고 싶다면 장애보다 그 사람이 실제로 한 일에 초점을 두는 편이 자연스럽습니다. '기획서를 끝까지 맡은 게 인상적이었다', '공부와 일을 이어가는 방식이 좋았다'처럼 구체적인 행동을 봐 주면 부담이 훨씬 줄어듭니다.",
        "도움과 간섭은 상대가 선택할 수 있느냐에서 갈라지는 경우가 많아요. 물어보고 기다린 뒤에 상대가 말한 방식대로 움직이면 도움에 가깝고, 묻지 않은 채 붙잡거나 대신 판단하면 간섭이 되기 쉽습니다.\n\n도와주고 싶은 마음 자체가 나쁜 건 아닙니다. 다만 좋은 마음일수록 속도를 늦춰야 해요. 상대가 거절해도 괜찮고, 다른 방식을 말해도 받아들일 수 있을 때 그 도움은 관계를 편하게 만듭니다.",
        "처음 본 인상만으로 보면 일하고 공부하는 모습, 자취방에서 생활을 직접 챙기는 모습, 좋아하는 취미와 쉬는 시간이 쉽게 빠집니다. 목발이나 이동의 어려움은 중요한 단서지만, 그 단서 하나가 한 사람의 전부가 되면 이야기가 너무 좁아져요.\n\n그래서 질문은 겉에서 속으로 넘어가야 합니다. '무엇이 불편하세요?'에서 멈추기보다 '하루를 어떻게 준비하세요?', '일과 공부는 어떻게 이어지나요?', '쉴 때는 무엇을 좋아하세요?'처럼 생활 전체를 묻는 질문이 더 정확합니다."
    };

    private enum ExpressionState
    {
        Idle,
        Listening,
        Thinking,
        Speaking,
        Explaining,
        Empathetic
    }

    [Serializable]
    private sealed class ChatMessage
    {
        public string role;
        public string content;
    }

    [Serializable]
    private sealed class ChatRequest
    {
        public ChatMessage[] messages;
    }

    [Serializable]
    private sealed class ChatResponse
    {
        public string reply;
        public string source;
        public string model;
        public string theme;
        public string cardId;
        public string[] suggestions;
        public string[] evidence;
        public bool endingAvailable;
        public string error;
    }

    [Serializable]
    private sealed class TranscribeResponse
    {
        public string text;
        public string model;
        public string error;
    }

    [Serializable]
    private sealed class ServerConfigResponse
    {
        public bool apiAvailable;
        public bool chatModelReady;
        public string chatModelError;
        public string chatModel;
        public string transcribeModel;
        public string ttsModel;
        public string ttsVoice;
    }

    [Serializable]
    private sealed class SaveState
    {
        public ChatMessage[] history;
        public string[] discoveredThemes;
        public string[] memoryNotes;
        public bool[] deepMemoryUnlocked;
        public string[] currentLeadQuestions;
        public string lastTheme;
        public string lastEvidenceLine;
        public string lastAnswerSource;
        public string lastServerError;
        public string firstImpression;
        public int[] attitudeCounts;
        public string lastQuestionAttitude;
        public string activeQuestionCategory;
        public int activeCategoryQuestionCount;
        public string lastChoiceConsequenceLine;
        public string leadIntro;
        public string speaker;
        public string dialogue;
        public string log;
        public int conversationTurns;
        public int chatEntryCount;
        public int expression;
        public int dialogueSizeLevel;
        public int selectedClosingIndex;
        public bool closingSensitiveQuestionAnswered;
        public string selectedClosingSensitiveQuestion;
        public string selectedClosingSensitiveAnswer;
        public string closingMessageToInterviewee;
    }

    [Serializable]
    private sealed class BuildInfoSummary
    {
        public string productName;
        public string displayName;
        public string version;
        public string buildId;
        public string generatedAt;
        public string platform;
    }

    [Serializable]
    private sealed class PlaytestFeedbackManifest
    {
        public string schemaVersion;
        public string sessionId;
        public string savedAt;
        public string rating;
        public string commercialReadiness;
        public string issueSeverity;
        public int conversationTurns;
        public string sessionCompletionLine;
        public int openedMemoryCount;
        public int memoryThemeCount;
        public string[] openedThemes;
        public string[] openedSceneTags;
        public string lastTheme;
        public string dominantAttitude;
        public int deepMemoryCount;
        public string firstImpression;
        public string firstImpressionTheme;
        public bool firstImpressionThemeOpened;
        public bool firstImpressionThemeDeep;
        public string firstImpressionArc;
        public string buildId;
        public string appVersion;
        public string productName;
        public string runtimePlatform;
        public string operatingSystem;
        public string screen;
        public bool fullscreen;
        public int dialogueSizeLevel;
        public bool reducedMotionEnabled;
        public bool highContrastEnabled;
        public bool localAnswerOnly;
        public int soundLevel;
        public bool completedFiveTurnSession;
        public bool positiveEvidenceRequiresCompletedSession;
        public bool positiveEvidenceRequiresEndingRecord;
        public bool endingRecordSavedThisSession;
        public bool qualityEvidenceReady;
        public string qualityFocusArea;
        public string[] qualityAreas;
        public string[] riskTags;
        public string evidenceTier;
        public string reviewActionRecommendation;
        public string commercialQualityEvidenceLine;
    }

    private void Awake()
    {
        Application.targetFrameRate = 60;
        LoadUiFonts();
        dialogueSizeLevel = Mathf.Clamp(PlayerPrefs.GetInt(TextSizeKey, 0), -1, 1);
        if (PlayerPrefs.GetInt(DisplayDefaultsVersionKey, 0) < CurrentDisplayDefaultsVersion)
        {
            PlayerPrefs.SetInt(FullscreenKey, 1);
            PlayerPrefs.SetInt(DisplayDefaultsVersionKey, CurrentDisplayDefaultsVersion);
            PlayerPrefs.Save();
        }
        fullscreenEnabled = PlayerPrefs.GetInt(FullscreenKey, 1) == 1;
        soundLevel = Mathf.Clamp(PlayerPrefs.GetInt(SoundLevelKey, 2), 0, 2);
        reducedMotionEnabled = PlayerPrefs.GetInt(ReducedMotionKey, 0) == 1;
        highContrastEnabled = PlayerPrefs.GetInt(HighContrastKey, 0) == 1;
        localAnswerOnly = false;
        PlayerPrefs.SetInt(LocalAnswerOnlyKey, 0);
        ApplyDisplayResolution();

        CreateAudioSystem();
        LoadSprites();
        memoryNotes = new string[memoryThemes.Length];
        deepMemoryUnlocked = new bool[memoryThemes.Length];
        attitudeCounts = new int[attitudeNames.Length];
        BuildInterface();
        SetExpression(ExpressionState.Idle);
        currentLeadQuestions = BuildLeadQuestionSet(null);
        SetServerAvailability(false, false, ServerRequiredCheckingText);

        PresentAssistant(OpeningText, "오늘의 시작");
        UpdateLeadPrompts("먼저 이런 순서로 이야기를 열어볼게요.");
        UpdateActionButtons();
        statusText.text = "서버 연결 확인 중";
        RefreshServerStatus();
        MaybeStartSmokeCapture();
    }

    private void LoadUiFonts()
    {
        uiFont = Resources.Load<Font>("Fonts/Paperlogy-4Regular");
        uiSemiBoldFont = Resources.Load<Font>("Fonts/Paperlogy-6SemiBold");
        uiBoldFont = Resources.Load<Font>("Fonts/Paperlogy-7Bold");

        if (uiFont == null)
        {
            uiFont = Font.CreateDynamicFontFromOSFont(new[] { "Paperlogy", "Paperlogy 4 Regular", "Noto Sans KR", "NotoSansKR", "Malgun Gothic", "맑은 고딕", "Arial" }, 20);
        }
        if (uiSemiBoldFont == null) uiSemiBoldFont = uiFont;
        if (uiBoldFont == null) uiBoldFont = uiSemiBoldFont != null ? uiSemiBoldFont : uiFont;
    }

    private Font GetUiFontForStyle(FontStyle style)
    {
        if (style == FontStyle.Bold || style == FontStyle.BoldAndItalic)
        {
            return uiBoldFont != null ? uiBoldFont : uiFont;
        }

        return uiFont;
    }

    private string GetUiFontReport()
    {
        string regular = uiFont != null ? uiFont.name : "missing";
        string semibold = uiSemiBoldFont != null ? uiSemiBoldFont.name : "missing";
        string bold = uiBoldFont != null ? uiBoldFont.name : "missing";
        return $"{regular} / {semibold} / {bold}";
    }

    private void Update()
    {
        UpdateForegroundSceneChromeVisibility();
        AnimateAvatar();
        AnimateHotspots();
        AnimateSceneFocus();
        AnimateReactiveSceneProps();
        AnimateLeadQuestionSlips();
        AnimateMemoryUnlockToast();
        AnimateClosingCredits();
        UpdateRecordDeletePromptTimeout();
        UpdateClearLocalDataPromptTimeout();

        if (recording && recordingClip != null)
        {
            int position = Microphone.GetPosition(micDevice);
            float seconds = Mathf.Max(0f, position / (float)MicFrequency);
            statusText.text = $"녹음 중... {seconds:0.0}초";
        }

        if (inputField != null && inputField.isFocused && IsSubmitKeyDown())
        {
            SubmitCurrentInput();
        }

        if (IsCancelKeyDown())
        {
            HandleEscape();
            return;
        }

        HandleKeyboardShortcuts();
    }

    private void LoadSprites()
    {
        avatarSprites[ExpressionState.Idle] = LoadSprite("idle");
        avatarSprites[ExpressionState.Listening] = LoadSprite("listening");
        avatarSprites[ExpressionState.Thinking] = LoadSprite("thinking");
        avatarSprites[ExpressionState.Speaking] = LoadSprite("speaking");
        avatarSprites[ExpressionState.Explaining] = LoadSprite("explaining");
        avatarSprites[ExpressionState.Empathetic] = LoadSprite("empathetic");

        avatarHandSprites[ExpressionState.Idle] = LoadHandSprite("idle");
        avatarHandSprites[ExpressionState.Listening] = LoadHandSprite("listening");
        avatarHandSprites[ExpressionState.Thinking] = LoadHandSprite("thinking");
        avatarHandSprites[ExpressionState.Speaking] = LoadHandSprite("speaking");
        avatarHandSprites[ExpressionState.Explaining] = LoadHandSprite("explaining");
        avatarHandSprites[ExpressionState.Empathetic] = LoadHandSprite("empathetic");
    }

    private void CreateAudioSystem()
    {
        GameObject audioObject = new GameObject("Interview Audio");
        audioObject.transform.SetParent(transform, false);

        sfxSource = audioObject.AddComponent<AudioSource>();
        sfxSource.playOnAwake = false;
        sfxSource.loop = false;

        ambienceSource = audioObject.AddComponent<AudioSource>();
        ambienceSource.playOnAwake = false;
        ambienceSource.loop = true;

        buttonClickClip = CreateSoftToneClip("Soft Button Click", new[] { 460f, 620f }, 0.055f, 0.080f, 0.006f);
        pageTurnClip = CreatePageTurnClip();
        questionSelectClip = CreateSoftToneClip("Question Select", new[] { 392f, 523f }, 0.100f, 0.080f, 0.006f);
        answerReadyClip = CreateSoftToneClip("Answer Ready", new[] { 330f, 440f }, 0.140f, 0.075f, 0.004f);
        memoryUnlockClip = CreateSoftToneClip("Memory Unlock", new[] { 523f, 659f, 784f }, 0.320f, 0.105f, 0.006f);
        confirmClip = CreateSoftToneClip("Confirm", new[] { 440f, 587f }, 0.180f, 0.090f, 0.004f);
        resultCardClip = CreateSoftToneClip("Result Card Chord", new[] { 330f, 440f, 523f }, 0.420f, 0.090f, 0.005f);
        categoryTransitionClip = CreateSoftToneClip("Category Transition", new[] { 294f, 392f, 494f }, 0.260f, 0.085f, 0.006f);
        errorClip = CreateSoftToneClip("Soft Error", new[] { 196f, 174f }, 0.160f, 0.070f, 0.003f);
        recordingStartClip = CreateSoftToneClip("Recording Start", new[] { 622f, 740f }, 0.100f, 0.080f, 0.003f);
        recordingStopClip = CreateSoftToneClip("Recording Stop", new[] { 740f, 622f }, 0.120f, 0.070f, 0.003f);
        roomToneClip = CreateLofiBgmClip();

        ambienceSource.clip = roomToneClip;
        ApplySoundSettings(false);
    }

    private static AudioClip CreateSoftToneClip(string name, float[] frequencies, float duration, float gain, float noiseGain)
    {
        const int sampleRate = 44100;
        int samples = Mathf.Max(1, Mathf.CeilToInt(sampleRate * duration));
        float[] data = new float[samples];
        uint seed = 2463534242u;

        for (int i = 0; i < samples; i++)
        {
            float t = i / (float)sampleRate;
            float attack = Mathf.Clamp01(t / 0.018f);
            float release = Mathf.Clamp01((duration - t) / 0.110f);
            float envelope = Mathf.Sin(attack * Mathf.PI * 0.5f) * release * release;
            float sample = 0f;

            for (int j = 0; j < frequencies.Length; j++)
            {
                float stagger = Mathf.Clamp01((t - j * 0.032f) / 0.045f);
                float frequency = frequencies[j] * (1f + Mathf.Sin(2f * Mathf.PI * 0.7f * t + j) * 0.0018f);
                sample += Mathf.Sin(2f * Mathf.PI * frequency * t) * stagger;
                sample += Mathf.Sin(2f * Mathf.PI * frequency * 2f * t) * 0.18f * stagger;
            }

            float noise = NextSignedNoise(ref seed) * noiseGain;
            data[i] = SoftLimit((sample * gain / Mathf.Max(1, frequencies.Length) + noise) * envelope);
        }

        AudioClip clip = AudioClip.Create(name, samples, 1, sampleRate, false);
        clip.SetData(data, 0);
        return clip;
    }

    private static AudioClip CreatePageTurnClip()
    {
        const int sampleRate = 44100;
        const float duration = 0.180f;
        int samples = Mathf.CeilToInt(sampleRate * duration);
        float[] data = new float[samples];
        uint seed = 362436069u;
        float filtered = 0f;

        for (int i = 0; i < samples; i++)
        {
            float t = i / (float)sampleRate;
            float envelope = Mathf.Clamp01(t / 0.020f) * Mathf.Clamp01((duration - t) / 0.090f);
            float sweep = Mathf.Sin(2f * Mathf.PI * Mathf.Lerp(340f, 620f, Mathf.Clamp01(t / duration)) * t) * 0.018f;
            filtered = Mathf.Lerp(filtered, NextSignedNoise(ref seed), 0.18f);
            data[i] = SoftLimit((filtered * 0.070f + sweep) * envelope);
        }

        AudioClip clip = AudioClip.Create("Soft Paper Turn", samples, 1, sampleRate, false);
        clip.SetData(data, 0);
        return clip;
    }

    private static AudioClip CreateToneClip(string name, float[] frequencies, float duration, float gain)
    {
        const int sampleRate = 44100;
        int samples = Mathf.Max(1, Mathf.CeilToInt(sampleRate * duration));
        float[] data = new float[samples];

        for (int i = 0; i < samples; i++)
        {
            float t = i / (float)sampleRate;
            float attack = Mathf.Clamp01(t / 0.012f);
            float release = Mathf.Clamp01((duration - t) / 0.075f);
            float envelope = Mathf.Sin(attack * Mathf.PI * 0.5f) * release;
            float sample = 0f;

            for (int j = 0; j < frequencies.Length; j++)
            {
                float stagger = Mathf.Clamp01((t - j * 0.038f) / 0.030f);
                sample += Mathf.Sin(2f * Mathf.PI * frequencies[j] * t) * stagger;
            }

            data[i] = sample * gain * envelope / Mathf.Max(1, frequencies.Length);
        }

        AudioClip clip = AudioClip.Create(name, samples, 1, sampleRate, false);
        clip.SetData(data, 0);
        return clip;
    }

    private static AudioClip CreateLofiBgmClip()
    {
        const int sampleRate = 22050;
        const float bpm = 64f;
        const float beat = 60f / bpm;
        const int beatCount = 48;
        const float duration = beat * beatCount;
        int samples = Mathf.CeilToInt(sampleRate * duration);
        float[] data = new float[samples];
        uint seed = 2463534242u;
        float noiseState = 0f;
        float[] roots = { 261.63f, 220.00f, 174.61f, 196.00f };
        float[][] chords =
        {
            new[] { 261.63f, 329.63f, 392.00f, 493.88f },
            new[] { 220.00f, 261.63f, 329.63f, 392.00f },
            new[] { 174.61f, 220.00f, 261.63f, 329.63f },
            new[] { 196.00f, 246.94f, 293.66f, 392.00f }
        };

        for (int i = 0; i < samples; i++)
        {
            float t = i / (float)sampleRate;
            float beatPosition = t / beat;
            int beatIndex = Mathf.FloorToInt(beatPosition);
            float beatPhase = beatPosition - beatIndex;
            int barIndex = (beatIndex / 4) % chords.Length;
            int beatInBar = beatIndex % 4;

            float sample = 0f;

            float chordPhase = (beatPosition / 2f) - Mathf.Floor(beatPosition / 2f);
            float chordEnvelope = Mathf.Exp(-chordPhase * 3.8f) * (0.72f + 0.16f * Mathf.Sin(2f * Mathf.PI * 0.05f * t));
            float[] chord = chords[barIndex];
            for (int j = 0; j < chord.Length; j++)
            {
                float frequency = chord[j] * 0.5f;
                float vibrato = 1f + Mathf.Sin(2f * Mathf.PI * (0.12f + j * 0.03f) * t) * 0.003f;
                sample += Mathf.Sin(2f * Mathf.PI * frequency * vibrato * t) * 0.014f * chordEnvelope;
                sample += TriangleWave(frequency * 2f * vibrato, t) * 0.004f * chordEnvelope;
            }

            float root = roots[barIndex] * 0.25f;
            float bassEnvelope = Mathf.Exp(-beatPhase * 6.5f);
            if (beatInBar == 0 || beatInBar == 2)
            {
                sample += Mathf.Sin(2f * Mathf.PI * root * t) * 0.018f * bassEnvelope;
            }

            float kickEnvelope = Mathf.Exp(-beatPhase * 18f);
            if (beatInBar == 0 || beatInBar == 2)
            {
                float kickFreq = Mathf.Lerp(82f, 48f, Mathf.Clamp01(beatPhase * 8f));
                sample += Mathf.Sin(2f * Mathf.PI * kickFreq * t) * 0.018f * kickEnvelope;
            }

            if (beatInBar == 1 || beatInBar == 3)
            {
                float snareEnvelope = Mathf.Exp(-beatPhase * 22f);
                noiseState = Mathf.Lerp(noiseState, NextSignedNoise(ref seed), 0.35f);
                sample += noiseState * 0.007f * snareEnvelope;
            }

            float eighthPhase = (beatPosition * 2f) - Mathf.Floor(beatPosition * 2f);
            float hatEnvelope = Mathf.Exp(-eighthPhase * 24f);
            noiseState = Mathf.Lerp(noiseState, NextSignedNoise(ref seed), 0.22f);
            sample += noiseState * 0.0025f * hatEnvelope;

            float vinyl = NextSignedNoise(ref seed) * 0.0020f + Mathf.Sin(2f * Mathf.PI * 0.22f * t) * 0.0018f;
            float fadeIn = Mathf.Clamp01(t / 0.08f);
            float fadeOut = Mathf.Clamp01((duration - t) / 0.08f);
            data[i] = SoftLimit((sample + vinyl) * Mathf.Min(fadeIn, fadeOut));
        }

        AudioClip clip = AudioClip.Create("Quiet Lofi Room Loop", samples, 1, sampleRate, false);
        clip.SetData(data, 0);
        return clip;
    }

    private static float TriangleWave(float frequency, float t)
    {
        float phase = frequency * t - Mathf.Floor(frequency * t);
        return 4f * Mathf.Abs(phase - 0.5f) - 1f;
    }

    private static float NextSignedNoise(ref uint seed)
    {
        seed ^= seed << 13;
        seed ^= seed >> 17;
        seed ^= seed << 5;
        return ((seed & 0xffff) / 32768f) - 1f;
    }

    private static float SoftLimit(float value)
    {
        return Mathf.Clamp(value, -0.85f, 0.85f);
    }

    private Sprite LoadSprite(string name)
    {
        Texture2D texture = LoadAvatarTexture(name);
        if (texture == null)
        {
            Debug.LogWarning($"Missing avatar texture: Avatar/avatar_{name}");
            return null;
        }

        Texture2D displayTexture = CreateAvatarTexture(texture);
        return Sprite.Create(displayTexture, new Rect(0, 0, displayTexture.width, displayTexture.height), new Vector2(0.5f, 0.5f), 100f, 0, SpriteMeshType.Tight);
    }

    private Sprite LoadHandSprite(string name)
    {
        Texture2D texture = LoadAvatarTexture(name);
        if (texture == null)
        {
            return null;
        }

        Texture2D displayTexture = CreateAvatarHandsTexture(texture);
        return Sprite.Create(displayTexture, new Rect(0, 0, displayTexture.width, displayTexture.height), new Vector2(0.5f, 0.5f), 100f, 0, SpriteMeshType.FullRect);
    }

    private Texture2D LoadAvatarTexture(string name)
    {
        Texture2D texture = Resources.Load<Texture2D>($"Avatar/avatar_{name}_integrated_v1");
        if (texture == null)
        {
            texture = Resources.Load<Texture2D>($"Avatar/avatar_{name}_redesign_v1");
        }
        if (texture == null)
        {
            texture = Resources.Load<Texture2D>($"Avatar/avatar_{name}_room_hd");
        }
        if (texture == null)
        {
            texture = Resources.Load<Texture2D>($"Avatar/avatar_{name}_room");
        }
        if (texture == null)
        {
            texture = Resources.Load<Texture2D>($"Avatar/avatar_{name}");
        }

        return texture;
    }

    private Texture2D CreateAvatarTexture(Texture2D source)
    {
        Color32[] pixels;
        try
        {
            pixels = source.GetPixels32();
        }
        catch (Exception ex)
        {
            Debug.LogWarning($"Avatar texture must be readable for chroma cleanup: {source.name}. {ex.Message}");
            return source;
        }

        int width = source.width;
        int height = source.height;
        bool[] transparent = new bool[pixels.Length];

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                int i = y * width + x;
                if (pixels[i].a == 0 || IsMagentaKey(pixels[i]))
                {
                    transparent[i] = true;
                    pixels[i] = new Color32(0, 0, 0, 0);
                }
                else if (IsAvatarSourceTableBand(pixels[i], x, y, width, height))
                {
                    transparent[i] = true;
                    pixels[i] = new Color32(0, 0, 0, 0);
                }
            }
        }

        for (int pass = 0; pass < 10; pass++)
        {
            bool[] nextTransparent = (bool[])transparent.Clone();
            for (int y = 1; y < height - 1; y++)
            {
                for (int x = 1; x < width - 1; x++)
                {
                    int index = y * width + x;
                    if (transparent[index] || !IsPurpleFringe(pixels[index])) continue;

                    bool nearTransparent =
                        transparent[index - 1] || transparent[index + 1] ||
                        transparent[index - width] || transparent[index + width] ||
                        transparent[index - width - 1] || transparent[index - width + 1] ||
                        transparent[index + width - 1] || transparent[index + width + 1];

                    if (nearTransparent)
                    {
                        nextTransparent[index] = true;
                        pixels[index] = new Color32(0, 0, 0, 0);
                    }
                }
            }
            transparent = nextTransparent;
        }

        for (int i = 0; i < pixels.Length; i++)
        {
            if (pixels[i].a > 0 && IsPurpleFringe(pixels[i]))
            {
                byte neutral = (byte)Mathf.Clamp(pixels[i].g + 12, 0, 82);
                pixels[i].r = (byte)Mathf.Min(pixels[i].r, neutral);
                pixels[i].b = (byte)Mathf.Min(pixels[i].b, neutral + 8);
            }
        }

        HarmonizeAvatarPalette(pixels);
        StrengthenAvatarInkLines(pixels);
        ApplyAvatarCrispContrast(pixels);
        ApplyAvatarRoomTexture(pixels, transparent, width, height);
        ApplyAvatarAmbientRelight(pixels, transparent, width, height);
        SoftenAvatarCutoutEdge(pixels, transparent, width, height);
        ClearAvatarTextureBorder(pixels, transparent, width, height, 8);

        Texture2D cleaned = new Texture2D(width, height, TextureFormat.RGBA32, false);
        cleaned.name = $"{source.name}_clean";
        cleaned.filterMode = FilterMode.Bilinear;
        cleaned.wrapMode = TextureWrapMode.Clamp;
        cleaned.SetPixels32(pixels);
        cleaned.Apply(false, true);
        return cleaned;
    }

    private Texture2D CreateAvatarHandsTexture(Texture2D source)
    {
        Color32[] pixels;
        try
        {
            pixels = source.GetPixels32();
        }
        catch (Exception ex)
        {
            Debug.LogWarning($"Avatar texture must be readable for hand overlay cleanup: {source.name}. {ex.Message}");
            return source;
        }

        int width = source.width;
        int height = source.height;
        bool[] transparent = new bool[pixels.Length];

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                int i = y * width + x;
                if (pixels[i].a == 0 || IsMagentaKey(pixels[i]) || IsAvatarSourceTableBand(pixels[i], x, y, width, height))
                {
                    transparent[i] = true;
                    pixels[i] = new Color32(0, 0, 0, 0);
                    continue;
                }

                float handMask = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.018f, 0.22f, GetAvatarHandsMask(x, y, width, height)));
                if (handMask <= 0.012f)
                {
                    transparent[i] = true;
                    pixels[i] = new Color32(0, 0, 0, 0);
                    continue;
                }

                pixels[i].a = (byte)Mathf.Clamp(Mathf.RoundToInt(pixels[i].a * Mathf.Clamp01(handMask)), 0, 255);
            }
        }

        for (int pass = 0; pass < 7; pass++)
        {
            bool[] nextTransparent = (bool[])transparent.Clone();
            for (int y = 1; y < height - 1; y++)
            {
                for (int x = 1; x < width - 1; x++)
                {
                    int index = y * width + x;
                    if (transparent[index] || !IsPurpleFringe(pixels[index])) continue;

                    bool nearTransparent =
                        transparent[index - 1] || transparent[index + 1] ||
                        transparent[index - width] || transparent[index + width] ||
                        transparent[index - width - 1] || transparent[index - width + 1] ||
                        transparent[index + width - 1] || transparent[index + width + 1];

                    if (nearTransparent)
                    {
                        nextTransparent[index] = true;
                        pixels[index] = new Color32(0, 0, 0, 0);
                    }
                }
            }
            transparent = nextTransparent;
        }

        HarmonizeAvatarPalette(pixels);
        StrengthenAvatarInkLines(pixels);
        ApplyAvatarCrispContrast(pixels);
        ApplyAvatarRoomTexture(pixels, transparent, width, height);
        ApplyAvatarAmbientRelight(pixels, transparent, width, height);
        SoftenAvatarCutoutEdge(pixels, transparent, width, height);
        ClearAvatarTextureBorder(pixels, transparent, width, height, 8);

        Texture2D cleaned = new Texture2D(width, height, TextureFormat.RGBA32, false);
        cleaned.name = $"{source.name}_hands_clean";
        cleaned.filterMode = FilterMode.Bilinear;
        cleaned.wrapMode = TextureWrapMode.Clamp;
        cleaned.SetPixels32(pixels);
        cleaned.Apply(false, true);
        return cleaned;
    }

    private static float GetAvatarHandsMask(int x, int y, int width, int height)
    {
        float x01 = width <= 1 ? 0.5f : x / (width - 1f);
        float y01 = height <= 1 ? 0f : y / (height - 1f);

        float hands = EllipseMask(x01, y01, 0.500f, 0.142f, 0.155f, 0.070f);
        float leftForearm = EllipseMask(x01, y01, 0.274f, 0.150f, 0.214f, 0.076f);
        float rightForearm = EllipseMask(x01, y01, 0.726f, 0.150f, 0.214f, 0.076f);
        float sleeves = Mathf.Max(leftForearm, rightForearm);
        float handArea = Mathf.Max(hands, sleeves);
        float torsoKeepout = EllipseMask(x01, y01, 0.500f, 0.228f, 0.132f, 0.088f);

        float lowerLimiter = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.070f, 0.105f, y01));
        float upperLimiter = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.260f, 0.212f, y01));
        return Mathf.Clamp01(handArea * lowerLimiter * upperLimiter * (1f - torsoKeepout));
    }

    private static void ClearAvatarTextureBorder(Color32[] pixels, bool[] transparent, int width, int height, int margin)
    {
        int safeMargin = Mathf.Clamp(margin, 0, Mathf.Min(width, height) / 2);
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                if (x >= safeMargin && x < width - safeMargin && y >= safeMargin && y < height - safeMargin) continue;
                int index = y * width + x;
                transparent[index] = true;
                pixels[index] = new Color32(0, 0, 0, 0);
            }
        }
    }

    private static void HarmonizeAvatarPalette(Color32[] pixels)
    {
        for (int i = 0; i < pixels.Length; i++)
        {
            Color32 pixel = pixels[i];
            if (pixel.a == 0) continue;

            float luma = pixel.r * 0.299f + pixel.g * 0.587f + pixel.b * 0.114f;
            float warmR = Mathf.Clamp(luma * 1.03f + 9f, 0f, 255f);
            float warmG = Mathf.Clamp(luma * 0.98f + 7f, 0f, 255f);
            float warmB = Mathf.Clamp(luma * 0.88f + 4f, 0f, 255f);

            float r = Mathf.Lerp(pixel.r, warmR, 0.10f);
            float g = Mathf.Lerp(pixel.g, warmG, 0.10f);
            float b = Mathf.Lerp(pixel.b, warmB, 0.10f);

            float darkLift = Mathf.InverseLerp(96f, 20f, luma);
            if (darkLift > 0f)
            {
                float amount = darkLift * 0.18f;
                r = Mathf.Lerp(r, 124f, amount);
                g = Mathf.Lerp(g, 102f, amount);
                b = Mathf.Lerp(b, 76f, amount);
            }

            float highlightDamp = Mathf.InverseLerp(174f, 244f, luma);
            if (highlightDamp > 0f)
            {
                float amount = highlightDamp * 0.06f;
                r = Mathf.Lerp(r, 238f, amount);
                g = Mathf.Lerp(g, 219f, amount);
                b = Mathf.Lerp(b, 190f, amount);
            }

            pixel.r = (byte)Mathf.Clamp(Mathf.RoundToInt(r), 0, 255);
            pixel.g = (byte)Mathf.Clamp(Mathf.RoundToInt(g), 0, 255);
            pixel.b = (byte)Mathf.Clamp(Mathf.RoundToInt(b), 0, 255);
            pixels[i] = pixel;
        }
    }

    private static void StrengthenAvatarInkLines(Color32[] pixels)
    {
        for (int i = 0; i < pixels.Length; i++)
        {
            Color32 pixel = pixels[i];
            if (pixel.a == 0) continue;

            float luma = pixel.r * 0.299f + pixel.g * 0.587f + pixel.b * 0.114f;
            float ink = Mathf.InverseLerp(118f, 24f, luma);
            if (ink <= 0f) continue;

            float amount = ink * 0.22f;
            float r = Mathf.Lerp(pixel.r, Mathf.Max(0f, pixel.r * 0.62f), amount);
            float g = Mathf.Lerp(pixel.g, Mathf.Max(0f, pixel.g * 0.62f), amount);
            float b = Mathf.Lerp(pixel.b, Mathf.Max(0f, pixel.b * 0.62f), amount);

            pixel.r = (byte)Mathf.Clamp(Mathf.RoundToInt(r), 0, 255);
            pixel.g = (byte)Mathf.Clamp(Mathf.RoundToInt(g), 0, 255);
            pixel.b = (byte)Mathf.Clamp(Mathf.RoundToInt(b), 0, 255);
            pixels[i] = pixel;
        }
    }

    private static void ApplyAvatarCrispContrast(Color32[] pixels)
    {
        for (int i = 0; i < pixels.Length; i++)
        {
            Color32 pixel = pixels[i];
            if (pixel.a == 0) continue;

            float luma = pixel.r * 0.299f + pixel.g * 0.587f + pixel.b * 0.114f;
            const float contrast = 1.08f;
            const float saturation = 1.07f;

            float r = 128f + (pixel.r - 128f) * contrast;
            float g = 128f + (pixel.g - 128f) * contrast;
            float b = 128f + (pixel.b - 128f) * contrast;

            r = luma + (r - luma) * saturation;
            g = luma + (g - luma) * saturation;
            b = luma + (b - luma) * saturation;

            pixel.r = (byte)Mathf.Clamp(Mathf.RoundToInt(r), 0, 255);
            pixel.g = (byte)Mathf.Clamp(Mathf.RoundToInt(g), 0, 255);
            pixel.b = (byte)Mathf.Clamp(Mathf.RoundToInt(b), 0, 255);
            pixels[i] = pixel;
        }
    }

    private static void SoftenAvatarInterior(Color32[] pixels, bool[] transparent, int width, int height)
    {
        Color32[] source = (Color32[])pixels.Clone();
        for (int y = 1; y < height - 1; y++)
        {
            for (int x = 1; x < width - 1; x++)
            {
                int index = y * width + x;
                if (transparent[index] || source[index].a < 96) continue;

                int r = 0;
                int g = 0;
                int b = 0;
                int count = 0;
                for (int dy = -1; dy <= 1; dy++)
                {
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int sampleIndex = (y + dy) * width + (x + dx);
                        if (transparent[sampleIndex] || source[sampleIndex].a < 96) continue;

                        Color32 sample = source[sampleIndex];
                        r += sample.r;
                        g += sample.g;
                        b += sample.b;
                        count++;
                    }
                }

                if (count <= 1) continue;

                Color32 pixel = source[index];
                float luma = pixel.r * 0.299f + pixel.g * 0.587f + pixel.b * 0.114f;
                float darkInk = Mathf.InverseLerp(112f, 24f, luma);
                float blend = 0.06f + darkInk * 0.05f;
                pixels[index] = new Color32(
                    (byte)Mathf.Clamp(Mathf.RoundToInt(Mathf.Lerp(pixel.r, r / (float)count, blend)), 0, 255),
                    (byte)Mathf.Clamp(Mathf.RoundToInt(Mathf.Lerp(pixel.g, g / (float)count, blend)), 0, 255),
                    (byte)Mathf.Clamp(Mathf.RoundToInt(Mathf.Lerp(pixel.b, b / (float)count, blend)), 0, 255),
                    pixel.a);
            }
        }
    }

    private static void ApplyAvatarDepthAtmosphere(Color32[] pixels, bool[] transparent, int width, int height)
    {
        float maxY = Mathf.Max(1f, height - 1f);
        for (int y = 0; y < height; y++)
        {
            float fromBottom = 1f - y / maxY;
            float lowerBody = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.24f, 0.94f, fromBottom));
            if (lowerBody <= 0f) continue;

            float deskBlend = lowerBody * 0.024f;
            float hazeBlend = lowerBody * 0.004f;
            for (int x = 0; x < width; x++)
            {
                int index = y * width + x;
                if (transparent[index] || pixels[index].a == 0) continue;

                Color32 pixel = pixels[index];
                float r = Mathf.Lerp(pixel.r, 205f, deskBlend);
                float g = Mathf.Lerp(pixel.g, 164f, deskBlend);
                float b = Mathf.Lerp(pixel.b, 116f, deskBlend);

                r = Mathf.Lerp(r, 235f, hazeBlend);
                g = Mathf.Lerp(g, 206f, hazeBlend);
                b = Mathf.Lerp(b, 166f, hazeBlend);

                pixel.r = (byte)Mathf.Clamp(Mathf.RoundToInt(r), 0, 255);
                pixel.g = (byte)Mathf.Clamp(Mathf.RoundToInt(g), 0, 255);
                pixel.b = (byte)Mathf.Clamp(Mathf.RoundToInt(b), 0, 255);
                pixels[index] = pixel;
            }
        }
    }

    private static void ApplyAvatarRoomTexture(Color32[] pixels, bool[] transparent, int width, int height)
    {
        float maxX = Mathf.Max(1f, width - 1f);
        float maxY = Mathf.Max(1f, height - 1f);
        for (int y = 0; y < height; y++)
        {
            float y01 = y / maxY;
            float lowerWarmth = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.02f, 0.45f, y01));
            for (int x = 0; x < width; x++)
            {
                int index = y * width + x;
                if (transparent[index] || pixels[index].a == 0) continue;

                Color32 pixel = pixels[index];
                float x01 = x / maxX;
                float luma = pixel.r * 0.299f + pixel.g * 0.587f + pixel.b * 0.114f;
                float saturation = 1.02f;
                float contrast = 1.03f;

                float r = 128f + (luma + (pixel.r - luma) * saturation - 128f) * contrast;
                float g = 128f + (luma + (pixel.g - luma) * saturation - 128f) * contrast;
                float b = 128f + (luma + (pixel.b - luma) * saturation - 128f) * contrast;

                float windowGlow = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.70f, 0.08f, x01)) * 0.010f;
                float lampWarmth = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.30f, 0.94f, x01)) * 0.008f;
                float deskWarmth = lowerWarmth * 0.008f;

                r = Mathf.Lerp(r, 240f, windowGlow);
                g = Mathf.Lerp(g, 220f, windowGlow);
                b = Mathf.Lerp(b, 190f, windowGlow);

                r = Mathf.Lerp(r, 236f, lampWarmth + deskWarmth);
                g = Mathf.Lerp(g, 196f, lampWarmth + deskWarmth);
                b = Mathf.Lerp(b, 146f, lampWarmth + deskWarmth);

                uint hash = unchecked((uint)(x * 374761393) + (uint)(y * 668265263));
                hash = unchecked((hash ^ (hash >> 13)) * 1274126177u);
                float grain = ((hash & 255u) / 255f - 0.5f) * 1.0f;

                pixel.r = (byte)Mathf.Clamp(Mathf.RoundToInt(r + grain), 0, 255);
                pixel.g = (byte)Mathf.Clamp(Mathf.RoundToInt(g + grain * 0.82f), 0, 255);
                pixel.b = (byte)Mathf.Clamp(Mathf.RoundToInt(b + grain * 0.62f), 0, 255);
                pixels[index] = pixel;
            }
        }
    }

    private static void ApplyAvatarAmbientRelight(Color32[] pixels, bool[] transparent, int width, int height)
    {
        float maxX = Mathf.Max(1f, width - 1f);
        float maxY = Mathf.Max(1f, height - 1f);
        for (int y = 0; y < height; y++)
        {
            float y01 = y / maxY;
            float upperPresence = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.30f, 0.76f, y01)) *
                Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.98f, 0.58f, y01));
            float deskBounce = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.04f, 0.38f, y01)) * 0.003f;

            for (int x = 0; x < width; x++)
            {
                int index = y * width + x;
                if (transparent[index] || pixels[index].a == 0) continue;

                Color32 pixel = pixels[index];
                float x01 = x / maxX;
                float luma = pixel.r * 0.299f + pixel.g * 0.587f + pixel.b * 0.114f;

                float leftKey = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.78f, 0.10f, x01)) * 0.010f;
                float faceLift = upperPresence * 0.009f;
                float roomLift = 0.004f + deskBounce;
                float lift = roomLift + leftKey + faceLift;

                float r = Mathf.Lerp(pixel.r, 236f, lift);
                float g = Mathf.Lerp(pixel.g, 206f, lift);
                float b = Mathf.Lerp(pixel.b, 168f, lift);

                float colorRecovery = 1.02f + upperPresence * 0.02f;
                r = luma + (r - luma) * colorRecovery;
                g = luma + (g - luma) * colorRecovery;
                b = luma + (b - luma) * colorRecovery;

                pixel.r = (byte)Mathf.Clamp(Mathf.RoundToInt(r), 0, 255);
                pixel.g = (byte)Mathf.Clamp(Mathf.RoundToInt(g), 0, 255);
                pixel.b = (byte)Mathf.Clamp(Mathf.RoundToInt(b), 0, 255);
                pixels[index] = pixel;
            }
        }
    }

    private static void SoftenAvatarCutoutEdge(Color32[] pixels, bool[] transparent, int width, int height)
    {
        Color32[] softened = (Color32[])pixels.Clone();
        for (int y = 1; y < height - 1; y++)
        {
            for (int x = 1; x < width - 1; x++)
            {
                int index = y * width + x;
                if (pixels[index].a == 0) continue;

                int transparentNeighbors = 0;
                if (transparent[index - 1]) transparentNeighbors++;
                if (transparent[index + 1]) transparentNeighbors++;
                if (transparent[index - width]) transparentNeighbors++;
                if (transparent[index + width]) transparentNeighbors++;
                if (transparent[index - width - 1]) transparentNeighbors++;
                if (transparent[index - width + 1]) transparentNeighbors++;
                if (transparent[index + width - 1]) transparentNeighbors++;
                if (transparent[index + width + 1]) transparentNeighbors++;
                if (transparentNeighbors == 0) continue;

                float blend = transparentNeighbors >= 3 ? 0.10f : 0.05f;
                byte maxAlpha = transparentNeighbors >= 3 ? (byte)232 : (byte)244;
                Color32 pixel = softened[index];
                pixel.a = (byte)Mathf.Min(pixel.a, maxAlpha);
                pixel.r = (byte)Mathf.RoundToInt(Mathf.Lerp(pixel.r, 232f, blend));
                pixel.g = (byte)Mathf.RoundToInt(Mathf.Lerp(pixel.g, 206f, blend));
                pixel.b = (byte)Mathf.RoundToInt(Mathf.Lerp(pixel.b, 168f, blend));
                softened[index] = pixel;
            }
        }

        Array.Copy(softened, pixels, pixels.Length);
    }

    private static bool IsMagentaKey(Color32 pixel)
    {
        return pixel.r > 95 && pixel.b > 95 && pixel.g < 126 && pixel.r - pixel.g > 38 && pixel.b - pixel.g > 42;
    }

    private static bool IsPurpleFringe(Color32 pixel)
    {
        return pixel.r > 28 && pixel.b > 32 && pixel.g < 118 && pixel.r > pixel.g + 8 && pixel.b > pixel.g + 12 && Mathf.Abs(pixel.r - pixel.b) < 118;
    }

    private static bool IsAvatarSourceTableBand(Color32 pixel, int x, int y, int width, int height)
    {
        if (pixel.a == 0) return false;

        float y01 = height <= 1 ? 0f : y / (height - 1f);
        if (y01 > 0.12f) return false;

        bool likelySourceWood =
            pixel.r > 150 &&
            pixel.g > 110 &&
            pixel.b < 160 &&
            pixel.r > pixel.g + 8 &&
            pixel.g > pixel.b + 24;

        return likelySourceWood;
    }

    private static Color32 BlendAvatarSourceTableBand(Color32 pixel, int x, int y, int width, int height)
    {
        float bandHeight = Mathf.Max(1f, height * 0.16f);
        float y01 = Mathf.Clamp01(y / bandHeight);
        float x01 = width <= 1 ? 0.5f : Mathf.Clamp01(x / (width - 1f));
        float bottomFade = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.02f, 0.30f, y01));
        float leftFade = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.00f, 0.14f, x01));
        float rightFade = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(1.00f, 0.86f, x01));
        float alpha = 0.18f * bottomFade * Mathf.Min(leftFade, rightFade);

        float r = Mathf.Lerp(pixel.r, 226f, 0.48f);
        float g = Mathf.Lerp(pixel.g, 176f, 0.48f);
        float b = Mathf.Lerp(pixel.b, 108f, 0.48f);

        uint hash = unchecked((uint)(x * 374761393) + (uint)(y * 668265263));
        hash = unchecked((hash ^ (hash >> 13)) * 1274126177u);
        float grain = ((hash & 255u) / 255f - 0.5f) * 4.5f;

        return new Color32(
            (byte)Mathf.Clamp(Mathf.RoundToInt(r + grain), 0, 255),
            (byte)Mathf.Clamp(Mathf.RoundToInt(g + grain * 0.82f), 0, 255),
            (byte)Mathf.Clamp(Mathf.RoundToInt(b + grain * 0.62f), 0, 255),
            (byte)Mathf.Clamp(Mathf.RoundToInt(pixel.a * alpha), 0, 255));
    }

    private Sprite LoadBackgroundSprite()
    {
        if (cachedBackgroundSprite != null)
        {
            return cachedBackgroundSprite;
        }

        Texture2D texture = LoadBackgroundTexture();
        if (texture == null)
        {
            Debug.LogWarning("Missing background texture: Scene/interview_room_background_fresh_v1");
            return null;
        }

        bool preprocessedBackground = texture.name.IndexOf("realistic", StringComparison.OrdinalIgnoreCase) >= 0 ||
            texture.name.IndexOf("flat2d", StringComparison.OrdinalIgnoreCase) >= 0 ||
            texture.name.IndexOf("stylized", StringComparison.OrdinalIgnoreCase) >= 0 ||
            texture.name.IndexOf("redesign", StringComparison.OrdinalIgnoreCase) >= 0 ||
            texture.name.IndexOf("fresh", StringComparison.OrdinalIgnoreCase) >= 0;
        Texture2D displayTexture = preprocessedBackground
            ? texture
            : CreateBackgroundDisplayTexture(texture);
        cachedBackgroundSprite = Sprite.Create(displayTexture, new Rect(0, 0, displayTexture.width, displayTexture.height), new Vector2(0.5f, 0.5f), 100f);
        return cachedBackgroundSprite;
    }

    private Texture2D LoadBackgroundTexture()
    {
        return Resources.Load<Texture2D>("Scene/interview_room_background_fresh_v1");
    }

    private Sprite LoadIllustrationSprite(string resourceName)
    {
        if (string.IsNullOrWhiteSpace(resourceName)) return null;

        string key = "illustration:" + resourceName;
        if (generatedSprites.TryGetValue(key, out Sprite cached)) return cached;

        Texture2D texture = Resources.Load<Texture2D>($"Illustrations/{resourceName}");
        if (texture == null && resourceName.StartsWith("generated-", StringComparison.Ordinal))
        {
            texture = CreateGeneratedIllustrationTexture(resourceName);
        }
        if (texture == null) return null;

        Sprite sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100f);
        generatedSprites[key] = sprite;
        return sprite;
    }

    private static Vector2Int GetWindowedResolutionForDisplay()
    {
        int displayWidth = Mathf.Max(1, Display.main.systemWidth);
        int displayHeight = Mathf.Max(1, Display.main.systemHeight);
        if (displayWidth <= 1 || displayHeight <= 1)
        {
            displayWidth = Mathf.Max(1, Screen.currentResolution.width);
            displayHeight = Mathf.Max(1, Screen.currentResolution.height);
        }

        int width = Mathf.Min(TargetWidth, Mathf.FloorToInt(displayWidth * 0.92f));
        int height = Mathf.RoundToInt(width * 9f / 16f);
        int maxHeight = Mathf.FloorToInt(displayHeight * 0.88f);
        if (height > maxHeight)
        {
            height = maxHeight;
            width = Mathf.RoundToInt(height * 16f / 9f);
        }

        width = Mathf.Clamp(width, 960, TargetWidth);
        height = Mathf.Clamp(height, 540, TargetHeight);
        return new Vector2Int(width, height);
    }

    private void ApplyDisplayResolution()
    {
        if (fullscreenEnabled)
        {
            Screen.SetResolution(TargetWidth, TargetHeight, true);
            return;
        }

        Vector2Int size = GetWindowedResolutionForDisplay();
        Screen.SetResolution(size.x, size.y, false);
    }

    private Texture2D CreateGeneratedIllustrationTexture(string resourceName)
    {
        const int width = 320;
        const int height = 200;
        Texture2D texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
        texture.wrapMode = TextureWrapMode.Clamp;
        texture.filterMode = FilterMode.Bilinear;

        Color32[] colors = GetGeneratedIllustrationPalette(resourceName);
        FillTexture(texture, colors[0]);
        DrawCircle(texture, 268, 152, 54, colors[1]);
        DrawCircle(texture, 50, 42, 34, colors[2]);
        DrawRect(texture, 0, 0, width, 28, new Color32(46, 38, 32, 42));
        DrawRect(texture, 24, 34, 272, 5, new Color32(255, 255, 255, 58));

        switch (resourceName)
        {
            case "generated-ordinary-day":
                DrawRect(texture, 42, 68, 72, 66, colors[3]);
                DrawRect(texture, 54, 118, 48, 26, colors[4]);
                DrawCircle(texture, 178, 103, 24, colors[4]);
                DrawRect(texture, 165, 52, 26, 52, colors[3]);
                DrawRect(texture, 204, 70, 42, 10, colors[2]);
                break;
            case "generated-first-impression":
                DrawCircle(texture, 76, 104, 32, colors[4]);
                DrawCircle(texture, 76, 104, 18, colors[0]);
                DrawRect(texture, 134, 92, 138, 14, colors[3]);
                DrawRect(texture, 134, 66, 96, 10, colors[2]);
                DrawRect(texture, 134, 124, 112, 10, colors[4]);
                break;
            case "generated-crutch-path":
                DrawRect(texture, 58, 46, 13, 106, colors[3]);
                DrawRect(texture, 76, 50, 10, 98, colors[3]);
                DrawRect(texture, 46, 136, 54, 8, colors[3]);
                DrawRect(texture, 128, 74, 142, 12, colors[4]);
                DrawRect(texture, 154, 112, 92, 10, colors[2]);
                break;
            case "generated-access-map":
                DrawRect(texture, 44, 50, 204, 112, new Color32(255, 250, 232, 210));
                DrawRect(texture, 64, 72, 60, 12, colors[3]);
                DrawRect(texture, 122, 72, 12, 62, colors[3]);
                DrawRect(texture, 132, 122, 82, 12, colors[3]);
                DrawCircle(texture, 228, 132, 16, colors[4]);
                DrawCircle(texture, 66, 74, 13, colors[2]);
                break;
            case "generated-help-question":
                DrawCircle(texture, 88, 112, 24, colors[3]);
                DrawCircle(texture, 205, 112, 24, colors[4]);
                DrawRect(texture, 110, 92, 78, 12, colors[2]);
                DrawRect(texture, 132, 122, 54, 8, colors[2]);
                DrawCircle(texture, 146, 112, 10, new Color32(255, 246, 214, 230));
                break;
            case "generated-boundary":
                DrawRect(texture, 86, 48, 10, 112, colors[3]);
                DrawRect(texture, 154, 48, 10, 112, colors[3]);
                DrawRect(texture, 222, 48, 10, 112, colors[3]);
                DrawCircle(texture, 120, 104, 18, colors[4]);
                DrawCircle(texture, 188, 104, 18, colors[2]);
                break;
            case "generated-desk-study":
                DrawRect(texture, 66, 72, 142, 70, colors[3]);
                DrawRect(texture, 82, 88, 110, 38, new Color32(42, 58, 72, 230));
                DrawRect(texture, 48, 46, 190, 16, colors[4]);
                DrawRect(texture, 226, 64, 24, 76, colors[2]);
                DrawRect(texture, 232, 72, 12, 60, new Color32(255, 250, 222, 170));
                break;
            case "generated-work-project":
                DrawRect(texture, 52, 58, 86, 96, new Color32(255, 250, 232, 225));
                DrawRect(texture, 68, 126, 54, 8, colors[3]);
                DrawRect(texture, 68, 106, 44, 8, colors[2]);
                DrawRect(texture, 158, 68, 98, 66, colors[4]);
                DrawCircle(texture, 246, 72, 12, colors[2]);
                break;
            case "generated-room-independence":
                DrawRect(texture, 54, 52, 86, 92, colors[3]);
                DrawRect(texture, 70, 78, 54, 40, new Color32(255, 248, 230, 210));
                DrawRect(texture, 176, 48, 74, 86, colors[4]);
                DrawCircle(texture, 214, 120, 8, colors[2]);
                break;
            case "generated-hobby-game":
                DrawRect(texture, 62, 74, 110, 58, colors[3]);
                DrawCircle(texture, 86, 102, 12, colors[4]);
                DrawRect(texture, 118, 98, 28, 8, colors[4]);
                DrawRect(texture, 208, 58, 12, 78, colors[2]);
                DrawCircle(texture, 226, 132, 18, colors[4]);
                break;
            case "generated-music-rest":
                DrawCircle(texture, 88, 102, 32, colors[3]);
                DrawRect(texture, 116, 70, 16, 86, colors[3]);
                DrawCircle(texture, 198, 112, 22, colors[4]);
                DrawRect(texture, 216, 112, 42, 8, colors[4]);
                DrawCircle(texture, 256, 112, 10, colors[2]);
                break;
            case "generated-motto-steps":
                DrawRect(texture, 52, 50, 50, 16, colors[3]);
                DrawRect(texture, 102, 70, 58, 16, colors[4]);
                DrawRect(texture, 160, 92, 64, 16, colors[2]);
                DrawRect(texture, 224, 116, 50, 16, colors[3]);
                DrawCircle(texture, 238, 148, 16, colors[4]);
                break;
            case "generated-transit-compare":
                DrawCircle(texture, 78, 78, 22, colors[3]);
                DrawCircle(texture, 78, 134, 22, colors[4]);
                DrawRect(texture, 120, 74, 124, 10, colors[3]);
                DrawRect(texture, 120, 130, 124, 10, colors[4]);
                DrawRect(texture, 250, 62, 18, 92, colors[2]);
                break;
            default:
                DrawRect(texture, 68, 64, 82, 84, colors[3]);
                DrawCircle(texture, 206, 108, 34, colors[4]);
                DrawRect(texture, 176, 100, 84, 10, colors[2]);
                break;
        }

        DrawRect(texture, 18, 170, 284, 3, new Color32(255, 255, 255, 52));
        texture.Apply(false, true);
        texture.name = resourceName;
        return texture;
    }

    private static Color32[] GetGeneratedIllustrationPalette(string key)
    {
        int hash = Mathf.Abs((key ?? string.Empty).GetHashCode());
        Color32[][] palettes =
        {
            new[] { new Color32(250, 235, 204, 255), new Color32(231, 162, 88, 168), new Color32(118, 158, 139, 150), new Color32(146, 94, 55, 225), new Color32(42, 77, 95, 220) },
            new[] { new Color32(232, 242, 238, 255), new Color32(108, 163, 150, 150), new Color32(220, 178, 104, 168), new Color32(38, 86, 98, 225), new Color32(172, 102, 70, 220) },
            new[] { new Color32(240, 232, 222, 255), new Color32(190, 136, 92, 160), new Color32(91, 124, 160, 145), new Color32(111, 76, 58, 225), new Color32(36, 92, 128, 220) },
            new[] { new Color32(236, 239, 223, 255), new Color32(135, 167, 101, 150), new Color32(210, 128, 96, 148), new Color32(79, 106, 63, 225), new Color32(138, 76, 66, 220) }
        };
        return palettes[hash % palettes.Length];
    }

    private static void FillTexture(Texture2D texture, Color32 color)
    {
        Color32[] pixels = new Color32[texture.width * texture.height];
        for (int i = 0; i < pixels.Length; i++)
        {
            pixels[i] = color;
        }
        texture.SetPixels32(pixels);
    }

    private static void DrawRect(Texture2D texture, int x, int y, int width, int height, Color32 color)
    {
        int minX = Mathf.Clamp(x, 0, texture.width);
        int maxX = Mathf.Clamp(x + width, 0, texture.width);
        int minY = Mathf.Clamp(y, 0, texture.height);
        int maxY = Mathf.Clamp(y + height, 0, texture.height);
        for (int py = minY; py < maxY; py++)
        {
            for (int px = minX; px < maxX; px++)
            {
                texture.SetPixel(px, py, color);
            }
        }
    }

    private static void DrawCircle(Texture2D texture, int cx, int cy, int radius, Color32 color)
    {
        int r2 = radius * radius;
        int minX = Mathf.Clamp(cx - radius, 0, texture.width - 1);
        int maxX = Mathf.Clamp(cx + radius, 0, texture.width - 1);
        int minY = Mathf.Clamp(cy - radius, 0, texture.height - 1);
        int maxY = Mathf.Clamp(cy + radius, 0, texture.height - 1);
        for (int y = minY; y <= maxY; y++)
        {
            for (int x = minX; x <= maxX; x++)
            {
                int dx = x - cx;
                int dy = y - cy;
                if (dx * dx + dy * dy <= r2)
                {
                    texture.SetPixel(x, y, color);
                }
            }
        }
    }

    private string GetIllustrationResourceForTheme(string theme)
    {
        switch (CanonicalTheme(theme))
        {
            case "이동":
                return "ai-card-mobility-map";
            case "도움":
                return "ai-card-help-hands";
            case "일과 공부":
                return "ai-card-study-laptop";
            case "독립":
                return "ai-card-independent-room";
            case "취미":
                return "ai-card-hobby-rest";
            case "일상":
                return "ai-card-ordinary-day";
            default:
                return "result-card-outer-to-inner";
        }
    }

    private string GetIllustrationResourceForQuestion(string question)
    {
        string text = question ?? string.Empty;
        if (HasAny(text, "좋은 의도", "간섭", "선은", "불편", "칭찬처럼", "예민", "대답하지 않을 자유")) return "ai-card-boundary-table";
        if (HasAny(text, "도움", "배려", "어떻게 도와", "먼저 물", "방식", "설명할 시간", "기다려")) return "ai-card-help-hands";
        if (HasAny(text, "프로젝트", "기획서", "기여", "업무", "함께 일")) return "ai-card-study-laptop";
        if (HasAny(text, "책상", "노트북", "컴퓨터", "메모", "직장", "박사", "공부")) return "ai-card-study-laptop";
        if (HasAny(text, "자취", "독립", "집", "방", "공과금", "생활비")) return "ai-card-independent-room";
        if (HasAny(text, "노래방", "음악", "코인노래방", "취미", "게임", "쉬는", "여가", "좋아하는")) return "ai-card-hobby-rest";
        if (HasAny(text, "한국", "미국", "대중교통", "장애인택시", "처음", "공간", "곳", "엘리베이터", "화장실", "교통", "접근성", "입구")) return "ai-card-mobility-map";
        if (HasAny(text, "목발", "이동", "비가", "미끄러운")) return "ai-card-mobility-map";
        if (HasAny(text, "끈기", "흘러간다", "버틴", "조정", "다음 단계")) return "ai-card-ordinary-day";
        if (HasAny(text, "겉", "처음 본", "인상", "전부", "놓치기", "선입견", "평범", "하루", "생활", "장면", "관람객")) return "ai-card-ordinary-day";
        return "ai-card-boundary-table";
    }

    private string GetIllustrationResourceForFirstImpression(string option)
    {
        switch ((option ?? string.Empty).Trim())
        {
            case "목발":
                return "ai-card-mobility-map";
            case "책상":
                return "ai-card-study-laptop";
            case "표정":
                return "ai-card-ordinary-day";
            default:
                return "ai-card-ordinary-day";
        }
    }

    private Image CreateIllustrationImage(string name, Transform parent, string resourceName, Color tint)
    {
        Sprite sprite = LoadIllustrationSprite(resourceName);
        if (sprite == null) return null;

        Image image = CreatePanel(name, parent, tint);
        image.sprite = sprite;
        image.preserveAspect = true;
        image.raycastTarget = false;
        return image;
    }

    private Texture2D CreateBackgroundDisplayTexture(Texture2D source)
    {
        Color32[] sourcePixels;
        try
        {
            sourcePixels = source.GetPixels32();
        }
        catch (Exception ex)
        {
            Debug.LogWarning($"Background texture must be readable for display harmonization: {source.name}. {ex.Message}");
            return source;
        }

        int width = source.width;
        int height = source.height;
        Color32[] output = new Color32[sourcePixels.Length];
        float maxX = Mathf.Max(1f, width - 1f);
        float maxY = Mathf.Max(1f, height - 1f);

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                int index = y * width + x;
                Color32 pixel = sourcePixels[index];

                int rSum = 0;
                int gSum = 0;
                int bSum = 0;
                int count = 0;
                for (int dy = -1; dy <= 1; dy++)
                {
                    int sy = Mathf.Clamp(y + dy, 0, height - 1);
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int sx = Mathf.Clamp(x + dx, 0, width - 1);
                        Color32 sample = sourcePixels[sy * width + sx];
                        rSum += sample.r;
                        gSum += sample.g;
                        bSum += sample.b;
                        count++;
                    }
                }

                float r = Mathf.Lerp(pixel.r, rSum / (float)count, 0.16f);
                float g = Mathf.Lerp(pixel.g, gSum / (float)count, 0.16f);
                float b = Mathf.Lerp(pixel.b, bSum / (float)count, 0.16f);
                float luma = r * 0.299f + g * 0.587f + b * 0.114f;

                float saturation = 0.84f;
                float contrast = 0.94f;
                r = 128f + (luma + (r - luma) * saturation - 128f) * contrast;
                g = 128f + (luma + (g - luma) * saturation - 128f) * contrast;
                b = 128f + (luma + (b - luma) * saturation - 128f) * contrast;

                float x01 = x / maxX;
                float y01 = y / maxY;
                float lampSide = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.48f, 1.0f, x01)) * 0.018f;
                float deskSide = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.00f, 0.38f, y01)) * 0.018f;
                float warmBlend = 0.016f + lampSide + deskSide;
                r = Mathf.Lerp(r, 236f, warmBlend);
                g = Mathf.Lerp(g, 205f, warmBlend);
                b = Mathf.Lerp(b, 168f, warmBlend);

                output[index] = new Color32(
                    (byte)Mathf.Clamp(Mathf.RoundToInt(r), 0, 255),
                    (byte)Mathf.Clamp(Mathf.RoundToInt(g), 0, 255),
                    (byte)Mathf.Clamp(Mathf.RoundToInt(b), 0, 255),
                    pixel.a);
            }
        }

        Texture2D cleaned = new Texture2D(width, height, TextureFormat.RGBA32, false);
        cleaned.name = $"{source.name}_display";
        cleaned.filterMode = FilterMode.Bilinear;
        cleaned.wrapMode = TextureWrapMode.Clamp;
        cleaned.SetPixels32(output);
        cleaned.Apply(false, true);
        return cleaned;
    }

    private void BuildInterface()
    {
        if (FindAnyObjectByType<EventSystem>() == null)
        {
            new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
        }

        GameObject canvasObject = new GameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
        Canvas canvas = canvasObject.GetComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;

        CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(TargetWidth, TargetHeight);
        scaler.matchWidthOrHeight = 0.5f;

        Transform backgroundBackLayer = CreateFullScreenLayer(canvasObject.transform, "Background Back Layer");
        Image background = CreatePanel("Illustrated Study Room Backplate", backgroundBackLayer, new Color32(18, 23, 34, 255));
        Stretch(background.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        background.sprite = LoadBackgroundSprite();
        background.color = Color.white;
        background.preserveAspect = false;
        background.raycastTarget = false;

        Image sceneWash = CreatePanel("Scene Warm Wash", canvasObject.transform, new Color(1f, 0.97f, 0.90f, 0.070f));
        Stretch(sceneWash.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        sceneWash.raycastTarget = false;

        CreateSceneDepthLayers(canvasObject.transform);
        CreateAtmosphereFrame(canvasObject.transform);
        CreateSceneHotspots(canvasObject.transform);
        CreateSceneInteractionFeedback(canvasObject.transform);

        Transform characterLayer = CreateFullScreenLayer(canvasObject.transform, "Character Layer");
        if (UseIntegratedSceneArtwork)
        {
            CreateIntegratedSceneAvatarProxy(characterLayer);
        }
        else
        {
            CreateAvatar(characterLayer);
            CreateForegroundDeskLayer(canvasObject.transform);
            CreateAvatarHandsOverlay(canvasObject.transform);
        }
        CreateSceneUnifyingOverlay(canvasObject.transform);
        CreateSceneEdgeSafetyMatte(canvasObject.transform);
        CreateHighContrastBackdrop(canvasObject.transform);
        CreateTopBar(canvasObject.transform);
        CreateDialoguePanel(canvasObject.transform);
        CreateFlowPanel(canvasObject.transform);
        CreateHotspotPreview(canvasObject.transform);
        CreateMemoryUnlockToast(canvasObject.transform);
        CreateClosingSensitiveQuestionOverlay(canvasObject.transform);
        CreateClosingCardOverlay(canvasObject.transform);
        CreateCompletionChoiceOverlay(canvasObject.transform);
        CreateMemoryBookOverlay(canvasObject.transform);
        CreateFirstImpressionOverlay(canvasObject.transform);
        CreateStartMenuOverlay(canvasObject.transform);
        CreatePauseMenuOverlay(canvasObject.transform);
        CreateSettingsMenuOverlay(canvasObject.transform);
        CreateAboutMenuOverlay(canvasObject.transform);
        CreateRecordArchiveOverlay(canvasObject.transform);
        CreatePlaytestFeedbackOverlay(canvasObject.transform);
        CreateRestartConfirmOverlay(canvasObject.transform);
        ApplyHighContrastMode(false);
    }

    private void CreateHighContrastBackdrop(Transform parent)
    {
        highContrastDimImage = CreatePanel("Readability Contrast Backdrop", parent, new Color(0.02f, 0.025f, 0.030f, 0f));
        highContrastDimImage.raycastTarget = false;
        Stretch(highContrastDimImage.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
    }

    private Transform CreateFullScreenLayer(Transform parent, string name)
    {
        GameObject layerObject = new GameObject(name, typeof(RectTransform));
        layerObject.transform.SetParent(parent, false);
        RectTransform rect = layerObject.GetComponent<RectTransform>();
        Stretch(rect, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        return layerObject.transform;
    }

    private void CreateAtmosphereFrame(Transform parent)
    {
        Image topShade = CreatePanel("Cinematic Top Shade", parent, new Color(0.015f, 0.020f, 0.026f, 0.16f));
        Stretch(topShade.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), Vector2.zero, new Vector2(0f, -116f));
        topShade.raycastTarget = false;

        Image lowerShade = CreatePanel("Cinematic Lower Shade", parent, new Color(0.010f, 0.014f, 0.018f, 0f));
        Stretch(lowerShade.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), Vector2.zero, Vector2.zero);
        lowerShade.raycastTarget = false;

    }

    private void CreateSceneEdgeSafetyMatte(Transform parent)
    {
        Color edgeColor = new Color(0.86f, 0.76f, 0.58f, 0.32f);

        Image top = CreatePanel("Scene Edge Safety Top", parent, edgeColor);
        top.raycastTarget = false;
        Stretch(top.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), Vector2.zero, new Vector2(0f, -18f));

        Image bottom = CreatePanel("Scene Edge Safety Bottom", parent, edgeColor);
        bottom.raycastTarget = false;
        Stretch(bottom.rectTransform, Vector2.zero, new Vector2(1f, 0f), Vector2.zero, new Vector2(0f, 18f));

        Image left = CreatePanel("Scene Edge Safety Left", parent, edgeColor);
        left.raycastTarget = false;
        Stretch(left.rectTransform, Vector2.zero, new Vector2(0f, 1f), Vector2.zero, new Vector2(18f, 0f));

        Image right = CreatePanel("Scene Edge Safety Right", parent, edgeColor);
        right.raycastTarget = false;
        Stretch(right.rectTransform, new Vector2(1f, 0f), Vector2.one, new Vector2(-18f, 0f), Vector2.zero);
    }

    private void CreateSceneDepthLayers(Transform parent)
    {
        Image leftDepth = CreatePanel("Scene Left Depth", parent, new Color(0.020f, 0.030f, 0.045f, 0.080f));
        leftDepth.sprite = GetSoftEllipseSprite();
        leftDepth.raycastTarget = false;
        Stretch(leftDepth.rectTransform, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(-540f, -410f), new Vector2(520f, 470f));

        Image rightDepth = CreatePanel("Scene Right Depth", parent, new Color(0.035f, 0.030f, 0.024f, 0.050f));
        rightDepth.sprite = GetSoftEllipseSprite();
        rightDepth.raycastTarget = false;
        Stretch(rightDepth.rectTransform, new Vector2(1f, 0.5f), new Vector2(1f, 0.5f), new Vector2(-520f, -440f), new Vector2(540f, 470f));

        Image leftCoolFill = CreatePanel("Scene Left Window Cool Fill", parent, new Color(0.18f, 0.36f, 0.48f, 0.025f));
        leftCoolFill.sprite = GetSoftEllipseSprite();
        leftCoolFill.raycastTarget = false;
        Stretch(leftCoolFill.rectTransform, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(-260f, -340f), new Vector2(860f, 360f));

    }

    private void CreateMoodPill(Transform parent, string label, Vector2 offsetMin, Vector2 offsetMax, Color color)
    {
        Image pill = CreateRoundedPanel($"Mood Pill {label}", parent, color, 16);
        pill.raycastTarget = false;
        Stretch(pill.rectTransform, new Vector2(0f, 1f), new Vector2(0f, 1f), offsetMin, offsetMax);

        Text text = CreateText($"Mood Pill Text {label}", pill.transform, label, 13, new Color32(248, 250, 252, 230), TextAnchor.MiddleCenter, FontStyle.Bold);
        text.raycastTarget = false;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(8f, 0f), new Vector2(-8f, 0f));
    }

    private void CreateIntegratedSceneAvatarProxy(Transform parent)
    {
        GameObject avatarObject = new GameObject("Integrated Scene Avatar Proxy", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
        avatarObject.transform.SetParent(parent, false);
        avatarImage = avatarObject.GetComponent<Image>();
        avatarImage.preserveAspect = true;
        avatarImage.useSpriteMesh = true;
        avatarImage.raycastTarget = false;
        avatarImage.color = new Color(1f, 1f, 1f, 0f);
        if (avatarSprites.TryGetValue(ExpressionState.Idle, out Sprite idleSprite))
        {
            avatarImage.sprite = idleSprite;
        }

        avatarRect = avatarImage.rectTransform;
        avatarRect.anchorMin = new Vector2(0.5f, 0.5f);
        avatarRect.anchorMax = new Vector2(0.5f, 0.5f);
        avatarRect.pivot = new Vector2(0.5f, 0.5f);
        avatarRect.sizeDelta = new Vector2(720f, 600f);
        avatarRect.anchoredPosition = new Vector2(-328f, -12f);
        avatarRect.localScale = AvatarScale(1f);
        avatarBasePosition = avatarRect.anchoredPosition;

        avatarBackShadowImage = null;
        avatarContactShadowImage = null;
        avatarSilhouetteShadowImage = null;
        avatarSceneWashImage = null;
        avatarHandsImage = null;
        avatarHandsRect = null;
        avatarHandsContactShadowRect = null;
    }

    private void CreateExhibitionContextLayer(Transform parent)
    {
        Image wallLabel = CreatePaperPanel("Gallery Wall Exhibit Label", parent, new Color(0.985f, 0.952f, 0.858f, 0.82f), 5, 13);
        wallLabel.raycastTarget = false;
        Stretch(wallLabel.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-74f, 292f), new Vector2(164f, 368f));

        Image labelPin = CreateRoundedPanel("Gallery Wall Label Pin", wallLabel.transform, new Color(0.48f, 0.30f, 0.15f, 0.42f), 4);
        labelPin.raycastTarget = false;
        Stretch(labelPin.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(-16f, -10f), new Vector2(16f, -4f));

        Text wallLabelText = CreateText("Gallery Wall Exhibit Label Text", wallLabel.transform, "기록 전시\n인터뷰", 18, new Color(0.22f, 0.15f, 0.09f, 0.88f), TextAnchor.MiddleCenter, FontStyle.Bold);
        wallLabelText.lineSpacing = 0.92f;
        wallLabelText.resizeTextForBestFit = true;
        wallLabelText.resizeTextMinSize = 13;
        wallLabelText.resizeTextMaxSize = 18;
        Stretch(wallLabelText.rectTransform, Vector2.zero, Vector2.one, new Vector2(16f, 8f), new Vector2(-16f, -8f));

        Image eventBadge = CreateRoundedPanel("Gallery Event Badge", parent, new Color(0.060f, 0.046f, 0.034f, 0.58f), 5);
        eventBadge.raycastTarget = false;
        Stretch(eventBadge.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(430f, 188f), new Vector2(604f, 236f));

        Text badgeText = CreateText("Gallery Event Badge Text", eventBadge.transform, "작가와의 대화", 13, new Color(0.98f, 0.90f, 0.72f, 0.78f), TextAnchor.MiddleCenter, FontStyle.Bold);
        badgeText.resizeTextForBestFit = true;
        badgeText.resizeTextMinSize = 10;
        badgeText.resizeTextMaxSize = 13;
        Stretch(badgeText.rectTransform, Vector2.zero, Vector2.one, new Vector2(10f, 3f), new Vector2(-10f, -3f));
    }

    private void CreateAvatar(Transform parent)
    {
        avatarBackShadowImage = CreateAvatarSoftLayer(parent, "Avatar Backdrop Shadow", new Color(0.018f, 0.014f, 0.010f, 0.150f), new Vector2(610f, 500f), new Vector2(-330f, -42f), -2.0f);
        avatarBackShadowRect = avatarBackShadowImage.rectTransform;

        avatarContactShadowImage = CreateAvatarSoftLayer(parent, "Avatar Contact Shadow", new Color(0.012f, 0.010f, 0.008f, 0.105f), new Vector2(350f, 42f), new Vector2(-328f, -180f), -1.2f);
        avatarContactShadowRect = avatarContactShadowImage.rectTransform;

        GameObject silhouetteObject = new GameObject("Avatar Silhouette Room Shadow", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
        silhouetteObject.transform.SetParent(parent, false);
        avatarSilhouetteShadowImage = silhouetteObject.GetComponent<Image>();
        avatarSilhouetteShadowImage.preserveAspect = true;
        avatarSilhouetteShadowImage.useSpriteMesh = true;
        avatarSilhouetteShadowImage.raycastTarget = false;
        avatarSilhouetteShadowImage.color = new Color(0.038f, 0.028f, 0.020f, 0f);

        avatarSilhouetteShadowRect = avatarSilhouetteShadowImage.rectTransform;
        avatarSilhouetteShadowRect.anchorMin = new Vector2(0.5f, 0.5f);
        avatarSilhouetteShadowRect.anchorMax = new Vector2(0.5f, 0.5f);
        avatarSilhouetteShadowRect.pivot = new Vector2(0.5f, 0.5f);
        avatarSilhouetteShadowRect.sizeDelta = new Vector2(720f, 600f);
        avatarSilhouetteShadowRect.anchoredPosition = new Vector2(-322f, -20f);
        avatarSilhouetteShadowRect.localScale = AvatarScale(1.010f);

        GameObject avatarObject = new GameObject("Seated Character", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
        avatarObject.transform.SetParent(parent, false);
        avatarImage = avatarObject.GetComponent<Image>();
        avatarImage.preserveAspect = true;
        avatarImage.useSpriteMesh = true;
        avatarImage.raycastTarget = false;
        avatarImage.color = Color.white;

        avatarRect = avatarImage.rectTransform;
        avatarRect.anchorMin = new Vector2(0.5f, 0.5f);
        avatarRect.anchorMax = new Vector2(0.5f, 0.5f);
        avatarRect.pivot = new Vector2(0.5f, 0.5f);
        avatarRect.sizeDelta = new Vector2(720f, 600f);
        avatarRect.anchoredPosition = new Vector2(-328f, -12f);
        avatarRect.localScale = AvatarScale(1f);
        avatarBasePosition = avatarRect.anchoredPosition;

        avatarSceneWashImage = CreatePanel("Avatar Scene Wash", parent, new Color(0.96f, 0.82f, 0.60f, 0f));
        avatarSceneWashImage.preserveAspect = true;
        avatarSceneWashImage.useSpriteMesh = true;
        avatarSceneWashImage.raycastTarget = false;
        avatarSceneWashRect = avatarSceneWashImage.rectTransform;
        avatarSceneWashRect.anchorMin = avatarRect.anchorMin;
        avatarSceneWashRect.anchorMax = avatarRect.anchorMax;
        avatarSceneWashRect.pivot = avatarRect.pivot;
        avatarSceneWashRect.sizeDelta = avatarRect.sizeDelta;
        avatarSceneWashRect.anchoredPosition = avatarRect.anchoredPosition;
        avatarSceneWashRect.localScale = avatarRect.localScale;
        UpdateAvatarIntegrationLayers(0f, 1f);
    }

    private void CreateForegroundDeskLayer(Transform parent)
    {
        Transform foregroundLayer = CreateFullScreenLayer(parent, "Desk Foreground Occlusion Layer");

        Image desk = CreatePanel("Desk Foreground Occluder", foregroundLayer, Color.white);
        desk.sprite = GetBackgroundDeskForegroundSprite();
        desk.raycastTarget = false;
        desk.preserveAspect = false;
        Stretch(desk.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image lowerBlend = CreatePanel("Desk Foreground Lower Blend", foregroundLayer, new Color(0.070f, 0.052f, 0.036f, 0.34f));
        lowerBlend.raycastTarget = false;
        Stretch(lowerBlend.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(0f, 0f), new Vector2(0f, 74f));
    }

    private void CreateAvatarHandsOverlay(Transform parent)
    {
        Transform handsLayer = CreateFullScreenLayer(parent, "Avatar Hands On Desk Layer");

        Image contactShadow = CreatePanel("Hands Desk Contact Shadow", handsLayer, new Color(0.018f, 0.012f, 0.007f, 0.175f));
        contactShadow.sprite = GetSoftEllipseSprite();
        contactShadow.raycastTarget = false;
        avatarHandsContactShadowRect = contactShadow.rectTransform;
        avatarHandsContactShadowRect.anchorMin = new Vector2(0.5f, 0.5f);
        avatarHandsContactShadowRect.anchorMax = new Vector2(0.5f, 0.5f);
        avatarHandsContactShadowRect.pivot = new Vector2(0.5f, 0.5f);
        avatarHandsContactShadowRect.sizeDelta = new Vector2(390f, 50f);
        avatarHandsContactShadowRect.anchoredPosition = avatarBasePosition + new Vector2(4f, -148f);
        avatarHandsContactShadowRect.localRotation = Quaternion.Euler(0f, 0f, -0.6f);

        GameObject handsObject = new GameObject("Avatar Hands Resting On Desk", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
        handsObject.transform.SetParent(handsLayer, false);
        avatarHandsImage = handsObject.GetComponent<Image>();
        avatarHandsImage.preserveAspect = true;
        avatarHandsImage.useSpriteMesh = false;
        avatarHandsImage.raycastTarget = false;
        avatarHandsImage.color = Color.white;
        if (avatarHandSprites.TryGetValue(ExpressionState.Idle, out Sprite sprite))
        {
            avatarHandsImage.sprite = sprite;
        }

        avatarHandsRect = avatarHandsImage.rectTransform;
        avatarHandsRect.anchorMin = new Vector2(0.5f, 0.5f);
        avatarHandsRect.anchorMax = new Vector2(0.5f, 0.5f);
        avatarHandsRect.pivot = new Vector2(0.5f, 0.5f);
        avatarHandsRect.sizeDelta = avatarRect != null ? avatarRect.sizeDelta : new Vector2(720f, 600f);
        avatarHandsRect.anchoredPosition = avatarBasePosition + new Vector2(0f, 86f);
        avatarHandsRect.localScale = avatarRect != null ? avatarRect.localScale : AvatarScale(1f);
    }

    private void CreateForegroundInterviewProps(Transform parent)
    {
        Transform propLayer = CreateFullScreenLayer(parent, "Foreground Interview Props Layer");

        Image microphoneBase = CreatePanel("Interview Microphone Base", propLayer, new Color(0.034f, 0.030f, 0.026f, 0.54f));
        microphoneBase.sprite = GetSoftEllipseSprite();
        microphoneBase.raycastTarget = false;
        Stretch(microphoneBase.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(156f, -168f), new Vector2(272f, -130f));

        Image microphoneStem = CreateRoundedPanel("Interview Microphone Stem", propLayer, new Color(0.050f, 0.046f, 0.042f, 0.58f), 3);
        microphoneStem.raycastTarget = false;
        Stretch(microphoneStem.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(214f, -136f), new Vector2(227f, -70f));
        microphoneStem.rectTransform.localRotation = Quaternion.Euler(0f, 0f, -9f);

        Image microphoneHead = CreateRoundedPanel("Interview Microphone Head", propLayer, new Color(0.028f, 0.027f, 0.025f, 0.68f), 9);
        microphoneHead.raycastTarget = false;
        Stretch(microphoneHead.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(206f, -88f), new Vector2(258f, -54f));
        microphoneHead.rectTransform.localRotation = Quaternion.Euler(0f, 0f, -9f);

        Image namePlate = CreateRoundedPanel("Desk Korean Interview Nameplate", propLayer, new Color(0.075f, 0.052f, 0.034f, 0.78f), 5);
        namePlate.raycastTarget = false;
        Stretch(namePlate.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-504f, -176f), new Vector2(-274f, -126f));

        Text namePlateText = CreateText("Desk Korean Interview Nameplate Text", namePlate.transform, "전시 인터뷰", 15, new Color(0.98f, 0.89f, 0.68f, 0.86f), TextAnchor.MiddleCenter, FontStyle.Bold);
        namePlateText.resizeTextForBestFit = true;
        namePlateText.resizeTextMinSize = 11;
        namePlateText.resizeTextMaxSize = 15;
        Stretch(namePlateText.rectTransform, Vector2.zero, Vector2.one, new Vector2(12f, 3f), new Vector2(-12f, -3f));
    }

    private void CreateAvatarBoundaryBlend(Transform parent)
    {
        Sprite stripSprite = GetAvatarBoundaryBlendSprite();
        if (stripSprite == null) return;

        Image strip = CreatePanel("Avatar Boundary Blend Strip", parent, Color.white);
        strip.sprite = stripSprite;
        strip.raycastTarget = false;
        Stretch(strip.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(512f, 780f), new Vector2(1176f, 790f));
    }

    private void CreateAvatarProjectionFrame(Transform parent)
    {
        Image backShadow = CreatePanel("Avatar Projection Backplate Shadow", parent, new Color(0.018f, 0.014f, 0.010f, 0.074f));
        backShadow.sprite = GetSoftEllipseSprite();
        backShadow.raycastTarget = false;
        RectTransform shadowRect = backShadow.rectTransform;
        shadowRect.anchorMin = new Vector2(0.5f, 0.5f);
        shadowRect.anchorMax = new Vector2(0.5f, 0.5f);
        shadowRect.pivot = new Vector2(0.5f, 0.5f);
        shadowRect.sizeDelta = new Vector2(650f, 520f);
        shadowRect.anchoredPosition = new Vector2(-118f, -50f);
        shadowRect.localRotation = Quaternion.Euler(0f, 0f, -0.6f);

        Image glass = CreateRoundedPanel("Avatar Projection Glass", parent, new Color(0.72f, 0.64f, 0.50f, 0f), 14);
        glass.raycastTarget = false;
        RectTransform glassRect = glass.rectTransform;
        glassRect.anchorMin = new Vector2(0.5f, 0.5f);
        glassRect.anchorMax = new Vector2(0.5f, 0.5f);
        glassRect.pivot = new Vector2(0.5f, 0.5f);
        glassRect.sizeDelta = new Vector2(592f, 548f);
        glassRect.anchoredPosition = new Vector2(-118f, -42f);
        glassRect.localRotation = Quaternion.Euler(0f, 0f, -0.35f);

        Image leftEdge = CreateRoundedPanel("Avatar Projection Left Edge", glass.transform, new Color(1.00f, 0.87f, 0.62f, 0.054f), 2);
        leftEdge.raycastTarget = false;
        Stretch(leftEdge.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(18f, 26f), new Vector2(20f, -28f));

        Image rightEdge = CreateRoundedPanel("Avatar Projection Right Edge", glass.transform, new Color(0.18f, 0.13f, 0.08f, 0.046f), 2);
        rightEdge.raycastTarget = false;
        Stretch(rightEdge.rectTransform, Vector2.one, Vector2.one, new Vector2(-24f, -500f), new Vector2(-22f, -42f));

        Image topGlint = CreateRoundedPanel("Avatar Projection Top Glint", glass.transform, new Color(1.00f, 0.88f, 0.62f, 0f), 2);
        topGlint.raycastTarget = false;
        Stretch(topGlint.rectTransform, new Vector2(0f, 1f), Vector2.one, new Vector2(38f, -34f), new Vector2(-62f, -32f));

        Image diagonalReflection = CreateRoundedPanel("Avatar Projection Diagonal Reflection", glass.transform, new Color(1.00f, 0.90f, 0.70f, 0f), 4);
        diagonalReflection.raycastTarget = false;
        Stretch(diagonalReflection.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(74f, -156f), new Vector2(-72f, -149f));
        diagonalReflection.rectTransform.localRotation = Quaternion.Euler(0f, 0f, -6.0f);
    }

    private void CreateLowerTableEdgeLayer(Transform parent)
    {
        Image tableBase = CreatePanel("Low Table Edge Base", parent, new Color(0.070f, 0.052f, 0.036f, 0.74f));
        tableBase.raycastTarget = false;
        Stretch(tableBase.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(0f, 0f), new Vector2(0f, 76f));

        Image tableTopLine = CreatePanel("Low Table Edge Top Line", parent, new Color(0.92f, 0.72f, 0.46f, 0.18f));
        tableTopLine.raycastTarget = false;
        Stretch(tableTopLine.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(0f, 74f), new Vector2(0f, 78f));
    }

    private void CreateReactiveSceneProps(Transform parent)
    {
        reactiveLaptopGlowImage = CreatePanel("Reactive Laptop Cool Bounce", parent, new Color(0.18f, 0.48f, 0.66f, 0.060f));
        reactiveLaptopGlowImage.sprite = GetSoftEllipseSprite();
        reactiveLaptopGlowImage.raycastTarget = false;
        reactiveLaptopGlowRect = reactiveLaptopGlowImage.rectTransform;
        reactiveLaptopGlowRect.anchorMin = new Vector2(0.5f, 0.5f);
        reactiveLaptopGlowRect.anchorMax = new Vector2(0.5f, 0.5f);
        reactiveLaptopGlowRect.pivot = new Vector2(0.5f, 0.5f);
        reactiveLaptopGlowRect.sizeDelta = new Vector2(300f, 170f);
        reactiveLaptopGlowRect.anchoredPosition = new Vector2(-420f, 54f);
        reactiveLaptopGlowRect.localRotation = Quaternion.Euler(0f, 0f, -2.0f);

        reactiveLaptopScreenImage = CreateRoundedPanel("Reactive Laptop Screen", parent, new Color(0.30f, 0.70f, 0.88f, 0.052f), 8);
        reactiveLaptopScreenImage.raycastTarget = false;
        reactiveLaptopScreenRect = reactiveLaptopScreenImage.rectTransform;
        reactiveLaptopScreenRect.anchorMin = new Vector2(0.5f, 0.5f);
        reactiveLaptopScreenRect.anchorMax = new Vector2(0.5f, 0.5f);
        reactiveLaptopScreenRect.pivot = new Vector2(0.5f, 0.5f);
        reactiveLaptopScreenRect.sizeDelta = new Vector2(158f, 84f);
        reactiveLaptopScreenRect.anchoredPosition = new Vector2(-426f, 58f);
        reactiveLaptopScreenRect.localRotation = Quaternion.Euler(0f, 0f, 0.4f);
        reactiveLaptopLineImages = CreateReactiveLines("Reactive Laptop Line", reactiveLaptopScreenImage.transform, 4, new Vector2(-52f, 20f), 18f, 88f, new Color(0.80f, 0.96f, 1f, 0f));

        reactiveBoardNoteImage = CreatePaperPanel("Reactive Board Note", parent, new Color(1.00f, 0.95f, 0.74f, 0f), 4, 1);
        reactiveBoardNoteImage.raycastTarget = false;
        reactiveBoardNoteRect = reactiveBoardNoteImage.rectTransform;
        reactiveBoardNoteRect.anchorMin = new Vector2(0.5f, 0.5f);
        reactiveBoardNoteRect.anchorMax = new Vector2(0.5f, 0.5f);
        reactiveBoardNoteRect.pivot = new Vector2(0.5f, 0.5f);
        reactiveBoardNoteRect.sizeDelta = new Vector2(82f, 56f);
        reactiveBoardNoteRect.anchoredPosition = new Vector2(254f, 164f);
        reactiveBoardNoteRect.localRotation = Quaternion.Euler(0f, 0f, -3.4f);
        reactiveBoardLineImages = CreateReactiveLines("Reactive Board Note Line", reactiveBoardNoteImage.transform, 3, new Vector2(-24f, 12f), 14f, 44f, new Color(0.47f, 0.36f, 0.22f, 0f));

        reactiveCupSteamImageA = CreatePanel("Reactive Cup Steam A", parent, new Color(1f, 0.95f, 0.82f, 0f));
        reactiveCupSteamImageA.sprite = GetSoftEllipseSprite();
        reactiveCupSteamImageA.raycastTarget = false;
        reactiveCupSteamRectA = reactiveCupSteamImageA.rectTransform;
        reactiveCupSteamRectA.anchorMin = new Vector2(0.5f, 0.5f);
        reactiveCupSteamRectA.anchorMax = new Vector2(0.5f, 0.5f);
        reactiveCupSteamRectA.sizeDelta = new Vector2(42f, 128f);
        reactiveCupSteamRectA.anchoredPosition = new Vector2(356f, -236f);
        reactiveCupSteamRectA.localRotation = Quaternion.Euler(0f, 0f, -8f);

        reactiveCupSteamImageB = CreatePanel("Reactive Cup Steam B", parent, new Color(1f, 0.95f, 0.82f, 0f));
        reactiveCupSteamImageB.sprite = GetSoftEllipseSprite();
        reactiveCupSteamImageB.raycastTarget = false;
        reactiveCupSteamRectB = reactiveCupSteamImageB.rectTransform;
        reactiveCupSteamRectB.anchorMin = new Vector2(0.5f, 0.5f);
        reactiveCupSteamRectB.anchorMax = new Vector2(0.5f, 0.5f);
        reactiveCupSteamRectB.sizeDelta = new Vector2(34f, 104f);
        reactiveCupSteamRectB.anchoredPosition = new Vector2(392f, -230f);
        reactiveCupSteamRectB.localRotation = Quaternion.Euler(0f, 0f, 9f);

        GameObject notebookRoot = new GameObject("Reactive Notebook Ink", typeof(RectTransform));
        notebookRoot.transform.SetParent(parent, false);
        reactiveNotebookInkRect = notebookRoot.GetComponent<RectTransform>();
        reactiveNotebookInkRect.anchorMin = new Vector2(0.5f, 0.5f);
        reactiveNotebookInkRect.anchorMax = new Vector2(0.5f, 0.5f);
        reactiveNotebookInkRect.pivot = new Vector2(0.5f, 0.5f);
        reactiveNotebookInkRect.sizeDelta = new Vector2(270f, 92f);
        reactiveNotebookInkRect.anchoredPosition = new Vector2(-86f, -356f);
        reactiveNotebookInkRect.localRotation = Quaternion.Euler(0f, 0f, -7.2f);
        reactiveNotebookInkImages = CreateReactiveLines("Reactive Notebook Ink Line", notebookRoot.transform, 4, new Vector2(-106f, 28f), 20f, 178f, new Color(0.18f, 0.16f, 0.14f, 0f));

        reactiveCrutchGlintImage = CreateRoundedPanel("Reactive Crutch Glint", parent, new Color(1.00f, 0.86f, 0.58f, 0f), 2);
        reactiveCrutchGlintImage.raycastTarget = false;
        reactiveCrutchGlintRect = reactiveCrutchGlintImage.rectTransform;
        reactiveCrutchGlintRect.anchorMin = new Vector2(0.5f, 0f);
        reactiveCrutchGlintRect.anchorMax = new Vector2(0.5f, 0f);
        reactiveCrutchGlintRect.pivot = new Vector2(0.5f, 0.5f);
        reactiveCrutchGlintRect.sizeDelta = new Vector2(5f, 230f);
        reactiveCrutchGlintRect.anchoredPosition = new Vector2(610f, 312f);
        reactiveCrutchGlintRect.localRotation = Quaternion.Euler(0f, 0f, -8f);

        reactiveDoorLightImage = CreatePanel("Reactive Door Light", parent, new Color(1.0f, 0.78f, 0.38f, 0f));
        reactiveDoorLightImage.sprite = GetSoftEllipseSprite();
        reactiveDoorLightImage.raycastTarget = false;
        reactiveDoorLightRect = reactiveDoorLightImage.rectTransform;
        reactiveDoorLightRect.anchorMin = new Vector2(0.5f, 0.5f);
        reactiveDoorLightRect.anchorMax = new Vector2(0.5f, 0.5f);
        reactiveDoorLightRect.sizeDelta = new Vector2(172f, 316f);
        reactiveDoorLightRect.anchoredPosition = new Vector2(-858f, 64f);
        reactiveDoorLightRect.localRotation = Quaternion.Euler(0f, 0f, -2f);
    }

    private Image[] CreateReactiveLines(string name, Transform parent, int count, Vector2 firstPosition, float spacingY, float width, Color color)
    {
        Image[] lines = new Image[count];
        for (int i = 0; i < count; i++)
        {
            Image line = CreateRoundedPanel($"{name} {i + 1}", parent, color, 2);
            line.raycastTarget = false;
            RectTransform rect = line.rectTransform;
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0f, 0.5f);
            rect.sizeDelta = new Vector2(width - i * 12f, 3f);
            rect.anchoredPosition = firstPosition + new Vector2(0f, -spacingY * i);
            rect.localRotation = Quaternion.Euler(0f, 0f, i % 2 == 0 ? -1.4f : 1.1f);
            lines[i] = line;
        }
        return lines;
    }

    private void CreateSceneUnifyingOverlay(Transform parent)
    {
        Image sharedAmber = CreatePanel("Scene Shared Amber Grade", parent, new Color(0.92f, 0.70f, 0.46f, 0.010f));
        sharedAmber.raycastTarget = false;
        Stretch(sharedAmber.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image lowerWarmth = CreatePanel("Scene Lower Warmth", parent, new Color(0.960f, 0.710f, 0.420f, 0.012f));
        lowerWarmth.sprite = GetSoftEllipseSprite();
        lowerWarmth.raycastTarget = false;
        Stretch(lowerWarmth.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(-80f, 54f), new Vector2(80f, 500f));

        Image vignette = CreatePanel("Scene Shared Lens Vignette", parent, Color.white);
        vignette.sprite = GetSceneVignetteSprite();
        vignette.raycastTarget = false;
        Stretch(vignette.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image grain = CreatePanel("Scene Shared Grain", parent, Color.white);
        grain.sprite = GetSceneGrainSprite();
        grain.raycastTarget = false;
        Stretch(grain.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
    }

    private void CreateMobilityStoryProp(Transform parent)
    {
        Image floorShadow = CreatePanel("Mobility Crutch Floor Shadow", parent, new Color(0.020f, 0.016f, 0.012f, 0.024f));
        floorShadow.sprite = GetSoftEllipseSprite();
        floorShadow.raycastTarget = false;
        Stretch(floorShadow.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(470f, 176f), new Vector2(700f, 226f));

        Color shaft = new Color(0.15f, 0.11f, 0.075f, 0.075f);
        Color highlight = new Color(0.96f, 0.84f, 0.62f, 0.018f);
        Color rubber = new Color(0.030f, 0.025f, 0.020f, 0.060f);
        Color brass = new Color(0.55f, 0.36f, 0.20f, 0.055f);

        CreateSceneSegment("Mobility Crutch Back Shaft", parent, new Color(0.12f, 0.095f, 0.075f, 0.048f), new Vector2(638f, 336f), new Vector2(5f, 286f), -8.0f, 4);
        CreateSceneSegment("Mobility Crutch Shaft", parent, shaft, new Vector2(606f, 322f), new Vector2(6f, 318f), -8.0f, 4);
        CreateSceneSegment("Mobility Crutch Shaft Highlight", parent, highlight, new Vector2(603f, 326f), new Vector2(2f, 278f), -8.0f, 2);
        CreateSceneSegment("Mobility Crutch Grip", parent, brass, new Vector2(576f, 430f), new Vector2(72f, 7f), -8.0f, 4);
        CreateSceneSegment("Mobility Crutch Cuff", parent, shaft, new Vector2(574f, 504f), new Vector2(80f, 14f), -8.0f, 7);
        CreateSceneSegment("Mobility Crutch Cuff Cut", parent, new Color(0.96f, 0.86f, 0.68f, 0.10f), new Vector2(574f, 504f), new Vector2(46f, 4f), -8.0f, 3);
        CreateSceneSegment("Mobility Crutch Tip", parent, rubber, new Vector2(628f, 172f), new Vector2(42f, 9f), -8.0f, 5);
    }

    private Image CreateSceneSegment(string name, Transform parent, Color color, Vector2 position, Vector2 size, float rotation, int radius)
    {
        Image segment = CreateRoundedPanel(name, parent, color, radius);
        segment.raycastTarget = false;

        RectTransform rect = segment.rectTransform;
        rect.anchorMin = new Vector2(0.5f, 0f);
        rect.anchorMax = new Vector2(0.5f, 0f);
        rect.pivot = new Vector2(0.5f, 0.5f);
        rect.sizeDelta = size;
        rect.anchoredPosition = position;
        rect.localRotation = Quaternion.Euler(0f, 0f, rotation);
        return segment;
    }

    private Image CreateAvatarSoftLayer(Transform parent, string name, Color color, Vector2 size, Vector2 position, float rotation)
    {
        Image image = CreatePanel(name, parent, color);
        image.sprite = GetSoftEllipseSprite();
        image.raycastTarget = false;

        RectTransform rect = image.rectTransform;
        rect.anchorMin = new Vector2(0.5f, 0.5f);
        rect.anchorMax = new Vector2(0.5f, 0.5f);
        rect.pivot = new Vector2(0.5f, 0.5f);
        rect.sizeDelta = size;
        rect.anchoredPosition = position;
        rect.localRotation = Quaternion.Euler(0f, 0f, rotation);
        return image;
    }

    private void CreateSceneHotspots(Transform parent)
    {
        CreateHotspot(parent, "책상", new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-870f, -174f), new Vector2(-420f, -44f), "책상 앞에서 이어지는 하루는 어떤 모습인가요?", new Vector2(92f, 118f), new Vector2(104f, 36f));
        CreateHotspot(parent, "기록", new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-170f, 116f), new Vector2(210f, 388f), "요즘 자주 떠올리는 말이 있나요?", new Vector2(24f, -54f), new Vector2(104f, 36f));
        CreateHotspot(parent, "이동", new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(470f, -40f), new Vector2(820f, 362f), "처음 가는 곳에서는 무엇을 먼저 확인하나요?", new Vector2(-94f, 270f), new Vector2(104f, 36f));
    }

    private void CreateSceneInteractionFeedback(Transform parent)
    {
        GameObject root = new GameObject("Scene Interaction Feedback", typeof(RectTransform));
        root.transform.SetParent(parent, false);
        sceneFocusRect = root.GetComponent<RectTransform>();
        sceneFocusRect.anchorMin = new Vector2(0.5f, 0.5f);
        sceneFocusRect.anchorMax = new Vector2(0.5f, 0.5f);
        sceneFocusRect.sizeDelta = Vector2.zero;
        sceneFocusBasePosition = new Vector2(-690f, -88f);
        sceneFocusRect.anchoredPosition = sceneFocusBasePosition;

        sceneFocusImage = CreatePanel("Scene Focus Warm Glow", root.transform, new Color(1.00f, 0.76f, 0.34f, 0f));
        sceneFocusImage.sprite = GetSoftEllipseSprite();
        sceneFocusImage.raycastTarget = false;
        sceneFocusGlowRect = sceneFocusImage.rectTransform;
        sceneFocusGlowRect.anchorMin = new Vector2(0.5f, 0.5f);
        sceneFocusGlowRect.anchorMax = new Vector2(0.5f, 0.5f);
        sceneFocusGlowRect.sizeDelta = new Vector2(320f, 184f);
        sceneFocusGlowRect.anchoredPosition = Vector2.zero;

        sceneFocusSlipImage = CreatePaperPanel("Scene Focus Paper Slip", root.transform, new Color(0.98f, 0.94f, 0.82f, 0f), 5, 0);
        sceneFocusSlipImage.raycastTarget = false;
        sceneFocusSlipRect = sceneFocusSlipImage.rectTransform;
        sceneFocusSlipRect.anchorMin = new Vector2(0.5f, 0.5f);
        sceneFocusSlipRect.anchorMax = new Vector2(0.5f, 0.5f);
        sceneFocusSlipRect.sizeDelta = new Vector2(214f, 42f);
        sceneFocusSlipRect.anchoredPosition = new Vector2(20f, 78f);
        sceneFocusSlipRect.localRotation = Quaternion.Euler(0f, 0f, -2.2f);

        sceneFocusTapeImage = CreateRoundedPanel("Scene Focus Tape", sceneFocusSlipImage.transform, new Color(0.78f, 0.55f, 0.30f, 0f), 3);
        sceneFocusTapeImage.raycastTarget = false;
        Stretch(sceneFocusTapeImage.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(-28f, -7f), new Vector2(28f, -2f));

        sceneFocusText = CreateText("Scene Focus Text", sceneFocusSlipImage.transform, "", 11, new Color(0.28f, 0.21f, 0.13f, 0f), TextAnchor.MiddleCenter, FontStyle.Bold);
        sceneFocusText.raycastTarget = false;
        sceneFocusText.resizeTextForBestFit = true;
        sceneFocusText.resizeTextMinSize = 9;
        sceneFocusText.resizeTextMaxSize = 11;
        Stretch(sceneFocusText.rectTransform, Vector2.zero, Vector2.one, new Vector2(12f, 4f), new Vector2(-12f, -4f));
        sceneFocusRect.gameObject.SetActive(false);
    }

    private void CreateHotspot(Transform parent, string label, Vector2 anchorMin, Vector2 anchorMax, Vector2 offsetMin, Vector2 offsetMax, string question, Vector2? labelOffset = null, Vector2? labelSize = null)
    {
        GameObject root = new GameObject($"Hotspot {label}", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button), typeof(EventTrigger));
        root.transform.SetParent(parent, false);
        hotspotRootObjects.Add(root);
        Image image = root.GetComponent<Image>();
        image.sprite = GetRoundedSprite(8);
        image.type = Image.Type.Sliced;
        image.color = new Color(1.00f, 0.76f, 0.24f, 0.002f);

        Button button = root.GetComponent<Button>();
        ColorBlock colors = button.colors;
        colors.normalColor = image.color;
        colors.highlightedColor = new Color(1.00f, 0.84f, 0.36f, 0.10f);
        colors.pressedColor = new Color(0.86f, 0.48f, 0.14f, 0.18f);
        colors.disabledColor = new Color(0.18f, 0.22f, 0.25f, 0.08f);
        button.colors = colors;

        RectTransform rect = root.GetComponent<RectTransform>();
        Stretch(rect, anchorMin, anchorMax, offsetMin, offsetMax);

        Image objectGlow = CreateRoundedPanel("Hotspot Object Glow", root.transform, new Color(1.00f, 0.72f, 0.16f, 0.0f), 8);
        objectGlow.raycastTarget = false;
        Stretch(objectGlow.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image borderTop = CreatePanel("Hotspot Border Top", root.transform, new Color(1.00f, 0.82f, 0.22f, 0.0f));
        borderTop.raycastTarget = false;
        Stretch(borderTop.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, -3f), new Vector2(0f, 0f));

        Image borderBottom = CreatePanel("Hotspot Border Bottom", root.transform, new Color(1.00f, 0.82f, 0.22f, 0.0f));
        borderBottom.raycastTarget = false;
        Stretch(borderBottom.rectTransform, Vector2.zero, new Vector2(1f, 0f), new Vector2(0f, 0f), new Vector2(0f, 3f));

        Image borderLeft = CreatePanel("Hotspot Border Left", root.transform, new Color(1.00f, 0.82f, 0.22f, 0.0f));
        borderLeft.raycastTarget = false;
        Stretch(borderLeft.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(0f, 0f), new Vector2(3f, 0f));

        Image borderRight = CreatePanel("Hotspot Border Right", root.transform, new Color(1.00f, 0.82f, 0.22f, 0.0f));
        borderRight.raycastTarget = false;
        Stretch(borderRight.rectTransform, new Vector2(1f, 0f), Vector2.one, new Vector2(-3f, 0f), new Vector2(0f, 0f));

        GameObject pulseObject = new GameObject("Pulse", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
        pulseObject.transform.SetParent(root.transform, false);
        pulseObject.transform.SetAsFirstSibling();
        Image pulseImage = pulseObject.GetComponent<Image>();
        pulseImage.sprite = GetRoundedSprite(10);
        pulseImage.type = Image.Type.Sliced;
        pulseImage.color = new Color(1.00f, 0.78f, 0.28f, 0.0f);
        RectTransform pulseRect = pulseObject.GetComponent<RectTransform>();
        Stretch(pulseRect, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        hotspotPulseRects.Add(pulseRect);
        hotspotPulseImages.Add(pulseImage);

        Image pinRing = CreatePanel("Hotspot Pin Ring", root.transform, new Color(1.00f, 0.78f, 0.34f, 0.46f));
        pinRing.sprite = GetCircleSprite();
        pinRing.raycastTarget = false;
        Stretch(pinRing.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-10f, -10f), new Vector2(10f, 10f));

        Image pinHead = CreateRoundedPanel("Hotspot Brass Pin", root.transform, new Color(0.22f, 0.13f, 0.06f, 0.92f), 4);
        pinHead.raycastTarget = false;
        Stretch(pinHead.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-5f, -5f), new Vector2(5f, 5f));

        Image pinGlint = CreatePanel("Hotspot Pin Glint", pinHead.transform, new Color(1f, 0.96f, 0.78f, 0.55f));
        pinGlint.sprite = GetCircleSprite();
        pinGlint.raycastTarget = false;
        Stretch(pinGlint.rectTransform, new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(2.5f, -4.5f), new Vector2(4.5f, -2.5f));

        Image labelBubble = CreateRoundedPanel("Hotspot Label", parent, new Color(0.075f, 0.052f, 0.034f, 0.72f), 6);
        labelBubble.raycastTarget = false;
        RectTransform labelRect = labelBubble.rectTransform;
        labelRect.anchorMin = anchorMin;
        labelRect.anchorMax = anchorMax;
        Vector2 resolvedLabelOffset = labelOffset.HasValue ? labelOffset.Value : new Vector2(24f, 28f);
        Vector2 resolvedLabelSize = labelSize.HasValue ? labelSize.Value : new Vector2(160f, 44f);
        labelRect.offsetMin = offsetMin + resolvedLabelOffset;
        labelRect.offsetMax = labelRect.offsetMin + resolvedLabelSize;
        labelBubble.gameObject.SetActive(true);
        hotspotLabelObjects.Add(labelBubble.gameObject);

        Image labelTopEdge = CreateRoundedPanel("Hotspot Label Top Edge", labelBubble.transform, new Color(1f, 0.88f, 0.58f, 0.10f), 3);
        labelTopEdge.raycastTarget = false;
        Stretch(labelTopEdge.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(4f, -4f), new Vector2(-4f, -2f));

        Image labelLeftAccent = CreateRoundedPanel("Hotspot Label Accent", labelBubble.transform, new Color(0.90f, 0.62f, 0.28f, 0.34f), 2);
        labelLeftAccent.raycastTarget = false;
        Stretch(labelLeftAccent.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(8f, 7f), new Vector2(11f, -7f));

        Image labelPin = CreatePanel("Hotspot Label Pin", labelBubble.transform, new Color(1f, 0.84f, 0.42f, 0.26f));
        labelPin.sprite = GetCircleSprite();
        labelPin.raycastTarget = false;
        Stretch(labelPin.rectTransform, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(16f, -2f), new Vector2(20f, 2f));

        Text labelText = CreateText("Hotspot Label Text", labelBubble.transform, label, 16, new Color32(255, 236, 184, 238), TextAnchor.MiddleCenter, FontStyle.Bold);
        labelText.resizeTextForBestFit = true;
        labelText.resizeTextMinSize = 12;
        labelText.resizeTextMaxSize = 16;
        Stretch(labelText.rectTransform, Vector2.zero, Vector2.one, new Vector2(22f, 3f), new Vector2(-10f, -4f));

        Vector2 focusPosition = AnchorOffsetToCanvasCenter(anchorMin, anchorMax, offsetMin, offsetMax);
        EventTrigger trigger = root.GetComponent<EventTrigger>();
        AddPointerTrigger(trigger, EventTriggerType.PointerEnter, () =>
        {
            if (busy || !ShouldShowHotspotLabels())
            {
                return;
            }

            labelBubble.gameObject.SetActive(true);
            PreviewSceneFocus(label, focusPosition);
        });
        AddPointerTrigger(trigger, EventTriggerType.PointerExit, ShowHotspotLabels);
        button.onClick.AddListener(PlayButtonSound);
        button.onClick.AddListener(() => OpenHotspotPreview(label, question, focusPosition));
    }

    private void HideHotspotLabels()
    {
        for (int i = 0; i < hotspotLabelObjects.Count; i++)
        {
            if (hotspotLabelObjects[i] != null)
            {
                hotspotLabelObjects[i].SetActive(false);
            }
        }
    }

    private void ShowHotspotLabels()
    {
        UpdateForegroundSceneChromeVisibility();
        UpdateLeadSlipVisibility();

        if (!ShouldShowHotspotLabels())
        {
            HideHotspotLabels();
            return;
        }

        for (int i = 0; i < hotspotLabelObjects.Count; i++)
        {
            if (hotspotLabelObjects[i] != null)
            {
                hotspotLabelObjects[i].SetActive(true);
            }
        }
    }

    private bool ShouldShowHotspotLabels()
    {
        if (!ShouldShowSceneHotspots()) return false;
        return true;
    }

    private void UpdateForegroundSceneChromeVisibility()
    {
        bool showHotspots = ShouldShowSceneHotspots();
        for (int i = 0; i < hotspotRootObjects.Count; i++)
        {
            if (hotspotRootObjects[i] != null && hotspotRootObjects[i].activeSelf != showHotspots)
            {
                hotspotRootObjects[i].SetActive(showHotspots);
            }
        }

        if (!showHotspots)
        {
            HideHotspotLabels();
        }

        UpdateLeadSlipVisibility();
    }

    private bool ShouldShowSceneHotspots()
    {
        if (IsDialogueReadingFocusActive()) return false;
        if (busy || questionNoteOpen || IsHotspotPreviewOpen()) return false;
        if (IsActive(startMenuObject) || IsActive(pauseMenuObject) || IsActive(settingsMenuObject)) return false;
        if (IsActive(aboutMenuObject) || IsActive(memoryBookObject) || IsActive(recordArchiveObject)) return false;
        if (IsActive(playtestFeedbackObject) || IsActive(completionChoiceObject) || IsActive(closingCardObject) || IsActive(closingSensitiveQuestionObject) || IsActive(restartConfirmObject)) return false;
        if (IsActive(firstImpressionObject)) return false;
        return true;
    }

    private bool IsDialogueReadingFocusActive()
    {
        if (conversationTurns <= 0 || busy || storyModeActive) return false;
        if (speakerText == null || dialogueText == null) return false;
        if (!string.Equals(speakerText.text, "답변", StringComparison.Ordinal)) return false;

        string text = dialogueText.text ?? string.Empty;
        if (string.IsNullOrWhiteSpace(text)) return false;
        if (string.Equals(text, OpeningText, StringComparison.Ordinal)) return false;
        if (string.Equals(text, ThinkingReplyText, StringComparison.Ordinal)) return false;
        return true;
    }

    private void UpdateLeadSlipVisibility()
    {
        bool visible = ShouldShowLeadSlips();

        if (leadButtons != null)
        {
            foreach (Button button in leadButtons)
            {
                if (button != null) button.gameObject.SetActive(visible);
            }
        }

        if (leadShadows != null)
        {
            foreach (GameObject shadow in leadShadows)
            {
                if (shadow != null) shadow.SetActive(visible);
            }
        }

        if (leadThemeButton != null) leadThemeButton.gameObject.SetActive(visible);
        if (leadRefreshButton != null) leadRefreshButton.gameObject.SetActive(visible);
    }

    private bool ShouldShowLeadSlips()
    {
        if (!ShowFloatingLeadSlips || busy || storyModeActive) return false;
        if (IsCompletedFiveTurnSession()) return false;
        if (IsHotspotPreviewOpen()) return false;
        if (IsActive(startMenuObject) || IsActive(pauseMenuObject) || IsActive(settingsMenuObject)) return false;
        if (IsActive(aboutMenuObject) || IsActive(memoryBookObject) || IsActive(recordArchiveObject)) return false;
        if (IsActive(playtestFeedbackObject) || IsActive(completionChoiceObject) || IsActive(closingCardObject) || IsActive(closingSensitiveQuestionObject) || IsActive(restartConfirmObject)) return false;
        if (IsActive(firstImpressionObject)) return false;
        return true;
    }

    private static bool IsActive(GameObject target)
    {
        return target != null && target.activeSelf;
    }

    private static bool IsSelectableButton(Button button)
    {
        return button != null &&
            button.interactable &&
            button.gameObject.activeInHierarchy;
    }

    private static void SelectFirstInteractable(GameObject root, params string[] preferredNames)
    {
        if (root == null || !root.activeInHierarchy || EventSystem.current == null) return;

        Button[] buttons = root.GetComponentsInChildren<Button>(false);
        Button selected = null;

        if (preferredNames != null)
        {
            for (int i = 0; i < preferredNames.Length && selected == null; i++)
            {
                string preferred = preferredNames[i];
                if (string.IsNullOrWhiteSpace(preferred)) continue;

                for (int j = 0; j < buttons.Length; j++)
                {
                    Button candidate = buttons[j];
                    if (!IsSelectableButton(candidate)) continue;
                    string name = candidate.gameObject.name ?? string.Empty;
                    if (string.Equals(name, preferred, StringComparison.Ordinal) ||
                        name.StartsWith(preferred, StringComparison.Ordinal))
                    {
                        selected = candidate;
                        break;
                    }
                }
            }
        }

        if (selected == null)
        {
            for (int i = 0; i < buttons.Length; i++)
            {
                if (IsSelectableButton(buttons[i]))
                {
                    selected = buttons[i];
                    break;
                }
            }
        }

        if (selected != null)
        {
            EventSystem.current.SetSelectedGameObject(selected.gameObject);
        }
    }

    private static void ClearSelectionIfInside(GameObject root)
    {
        if (root == null || EventSystem.current == null || EventSystem.current.currentSelectedGameObject == null) return;

        Transform selected = EventSystem.current.currentSelectedGameObject.transform;
        if (selected == root.transform || selected.IsChildOf(root.transform))
        {
            EventSystem.current.SetSelectedGameObject(null);
        }
    }

    private void CreateHotspotPreview(Transform parent)
    {
        Image shadow = CreateRoundedPanel("Hotspot Preview Shadow", parent, new Color(0.030f, 0.022f, 0.014f, 0.22f), 9);
        hotspotPreviewObject = shadow.gameObject;
        Stretch(shadow.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-628f, 0f), new Vector2(-88f, 204f));

        Image card = CreatePaperPanel("Hotspot Preview Card", hotspotPreviewObject.transform, new Color(0.985f, 0.930f, 0.780f, 0.96f), 9, 1);
        Stretch(card.rectTransform, Vector2.zero, Vector2.one, new Vector2(7f, 7f), new Vector2(-7f, -8f));

        Image tape = CreateRoundedPanel("Hotspot Preview Tape", card.transform, new Color(0.88f, 0.76f, 0.52f, 0f), 3);
        tape.raycastTarget = false;
        Stretch(tape.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(-36f, -9f), new Vector2(36f, -4f));

        Image accent = CreateRoundedPanel("Hotspot Preview Accent", card.transform, new Color(0.46f, 0.30f, 0.17f, 0.42f), 2);
        accent.raycastTarget = false;
        Stretch(accent.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(18f, 20f), new Vector2(24f, -22f));

        hotspotPreviewTitleText = CreateText("Hotspot Preview Title", card.transform, "단서", 18, new Color(0.20f, 0.13f, 0.06f, 0.98f), TextAnchor.UpperLeft, FontStyle.Bold);
        hotspotPreviewTitleText.resizeTextForBestFit = true;
        hotspotPreviewTitleText.resizeTextMinSize = 15;
        hotspotPreviewTitleText.resizeTextMaxSize = 18;
        Stretch(hotspotPreviewTitleText.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(38f, -42f), new Vector2(-118f, -14f));

        hotspotPreviewQuestionText = CreateText("Hotspot Preview Question", card.transform, "", 20, new Color(0.08f, 0.055f, 0.035f, 0.98f), TextAnchor.UpperLeft, FontStyle.Bold);
        hotspotPreviewQuestionText.lineSpacing = 1.04f;
        hotspotPreviewQuestionText.resizeTextForBestFit = true;
        hotspotPreviewQuestionText.resizeTextMinSize = 15;
        hotspotPreviewQuestionText.resizeTextMaxSize = 20;
        Stretch(hotspotPreviewQuestionText.rectTransform, Vector2.zero, Vector2.one, new Vector2(38f, 48f), new Vector2(-38f, -58f));

        Button askButton = CreateObjectButtonRoot("Hotspot Preview Ask", card.transform, new Color(0.42f, 0.26f, 0.14f, 0.84f), new Color(1f, 0.96f, 0.86f, 0.98f), 6);
        Stretch(askButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-210f, 16f), new Vector2(-96f, 56f));
        Text askLabel = CreateText("Label", askButton.transform, "질문하기", 15, new Color(1f, 0.96f, 0.86f, 0.98f), TextAnchor.MiddleCenter, FontStyle.Bold);
        askLabel.resizeTextForBestFit = true;
        askLabel.resizeTextMinSize = 11;
        askLabel.resizeTextMaxSize = 15;
        Stretch(askLabel.rectTransform, Vector2.zero, Vector2.one, new Vector2(8f, 2f), new Vector2(-8f, -2f));
        askButton.onClick.AddListener(SubmitPendingHotspotQuestion);

        Button closeButton = CreateObjectButtonRoot("Hotspot Preview Close", card.transform, new Color(0.09f, 0.08f, 0.07f, 0.52f), new Color(1f, 0.96f, 0.86f, 0.92f), 6);
        Stretch(closeButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-86f, 16f), new Vector2(-24f, 56f));
        Text closeLabel = CreateText("Label", closeButton.transform, "닫기", 14, new Color(1f, 0.96f, 0.86f, 0.92f), TextAnchor.MiddleCenter, FontStyle.Bold);
        closeLabel.resizeTextForBestFit = true;
        closeLabel.resizeTextMinSize = 10;
        closeLabel.resizeTextMaxSize = 14;
        Stretch(closeLabel.rectTransform, Vector2.zero, Vector2.one, new Vector2(7f, 2f), new Vector2(-7f, -2f));
        closeButton.onClick.AddListener(CloseHotspotPreview);

        hotspotPreviewObject.SetActive(false);
    }

    private void OpenHotspotPreview(string label, string question, Vector2? focusPosition = null)
    {
        if (busy || string.IsNullOrWhiteSpace(question)) return;
        if (hotspotPreviewObject == null) return;

        Vector2 resolvedFocusPosition = focusPosition.HasValue ? focusPosition.Value : GetSceneFocusPositionForLabel(label);
        HideHotspotLabels();
        ShowSceneFocus(label, resolvedFocusPosition, "단서 확인", 2.6f);
        pendingHotspotLabel = string.IsNullOrWhiteSpace(label) ? "단서" : label.Trim();
        pendingHotspotQuestion = question.Trim();
        if (hotspotPreviewTitleText != null)
        {
            hotspotPreviewTitleText.text = string.IsNullOrWhiteSpace(pendingHotspotLabel) ? "단서" : $"단서 · {pendingHotspotLabel}";
        }
        if (hotspotPreviewQuestionText != null)
        {
            hotspotPreviewQuestionText.text = pendingHotspotQuestion;
        }

        if (questionNoteObject != null && questionNoteObject.activeSelf)
        {
            SetQuestionNoteOpen(false);
        }
        if (inputField != null)
        {
            inputField.DeactivateInputField();
        }

        hotspotPreviewObject.SetActive(true);
        PositionHotspotPreview(resolvedFocusPosition);
        hotspotPreviewObject.transform.SetAsLastSibling();
        SelectFirstInteractable(hotspotPreviewObject, "Hotspot Preview Ask", "Hotspot Preview Close");
        ShowHotspotLabels();
        if (statusText != null) statusText.text = "질문 확인";
    }

    private void SubmitPendingHotspotQuestion()
    {
        string question = pendingHotspotQuestion;
        CloseHotspotPreview();
        SubmitPresetQuestion(question);
    }

    private void CloseHotspotPreview()
    {
        pendingHotspotQuestion = string.Empty;
        pendingHotspotLabel = string.Empty;
        if (hotspotPreviewObject != null)
        {
            ClearSelectionIfInside(hotspotPreviewObject);
            hotspotPreviewObject.SetActive(false);
        }
        ShowHotspotLabels();
    }

    private void PositionHotspotPreview(Vector2 focusPosition)
    {
        if (hotspotPreviewObject == null) return;

        RectTransform rect = hotspotPreviewObject.GetComponent<RectTransform>();
        if (rect == null) return;

        string prop = CanonicalScenePropLabel(pendingHotspotLabel);
        Vector2 size = new Vector2(540f, 204f);
        Vector2 center;
        float rotation;

        switch (prop)
        {
            case "노트북":
                center = focusPosition + new Vector2(110f, 168f);
                rotation = 0.4f;
                break;
            case "컵":
                center = focusPosition + new Vector2(-270f, 142f);
                rotation = -1.0f;
                break;
            case "목발":
                center = focusPosition + new Vector2(-312f, 70f);
                rotation = 1.0f;
                break;
            case "메모":
                center = focusPosition + new Vector2(-174f, -132f);
                rotation = -1.0f;
                break;
            case "문":
            case "창문":
            case "지도":
            case "자취방":
                center = focusPosition + new Vector2(250f, 30f);
                rotation = 0.8f;
                break;
            default:
                center = focusPosition + new Vector2(-220f, 110f);
                rotation = Mathf.Clamp(-focusPosition.x / 720f, -1.4f, 1.4f);
                break;
        }

        center = ClampPreviewCenter(center, size);
        rect.anchorMin = new Vector2(0.5f, 0.5f);
        rect.anchorMax = new Vector2(0.5f, 0.5f);
        rect.sizeDelta = size;
        rect.anchoredPosition = center;
        rect.localRotation = Quaternion.Euler(0f, 0f, rotation);
    }

    private void PreviewSceneFocus(string label, Vector2 position)
    {
        if (busy) return;
        ShowSceneFocus(label, position, "살펴보기", 1.05f);
    }

    private void ShowSceneFocus(string label, Vector2 position, string action, float duration)
    {
        if (sceneFocusRect == null || sceneFocusImage == null) return;

        activeSceneFocusLabel = string.IsNullOrWhiteSpace(label) ? "장면" : label.Trim();
        string safeAction = string.IsNullOrWhiteSpace(action) ? "장면 반응" : action.Trim();
        sceneFocusSlipVisible = !string.Equals(safeAction, "단서 확인", StringComparison.Ordinal);
        sceneFocusBasePosition = ClampSceneFocusPosition(position);
        sceneFocusDuration = Mathf.Max(0.25f, duration);
        sceneFocusUntil = Time.unscaledTime + sceneFocusDuration;

        sceneFocusRect.gameObject.SetActive(true);
        sceneFocusRect.anchoredPosition = sceneFocusBasePosition;
        sceneFocusRect.localScale = Vector3.one;
        sceneFocusRect.localRotation = Quaternion.Euler(0f, 0f, Mathf.Clamp(-sceneFocusBasePosition.x / 250f, -3.5f, 3.5f));

        if (sceneFocusGlowRect != null)
        {
            sceneFocusGlowRect.sizeDelta = GetSceneFocusGlowSize(activeSceneFocusLabel);
        }

        if (sceneFocusSlipRect != null)
        {
            float slipX = sceneFocusBasePosition.x > 620f ? -48f : 20f;
            float slipY = sceneFocusBasePosition.y > 312f ? -78f : 78f;
            sceneFocusSlipRect.anchoredPosition = new Vector2(slipX, slipY);
        }

        if (sceneFocusText != null)
        {
            sceneFocusText.text = $"{activeSceneFocusLabel} · {safeAction}";
        }

        TriggerScenePropReaction(activeSceneFocusLabel, sceneFocusDuration + 0.45f);
        ApplySceneFocusAlpha(0.72f);
    }

    private void AnimateSceneFocus()
    {
        if (sceneFocusRect == null) return;

        float remaining = sceneFocusUntil - Time.unscaledTime;
        if (remaining <= 0f)
        {
            ApplySceneFocusAlpha(0f);
            return;
        }

        float age = Mathf.Max(0f, sceneFocusDuration - remaining);
        float appear = Mathf.Clamp01(age / 0.18f);
        float disappear = Mathf.Clamp01(remaining / 0.55f);
        float alpha = Mathf.SmoothStep(0f, 1f, Mathf.Min(appear, disappear));

        if (reducedMotionEnabled)
        {
            sceneFocusRect.anchoredPosition = sceneFocusBasePosition;
            sceneFocusRect.localScale = Vector3.one;
        }
        else
        {
            float wave = Mathf.Sin(Time.unscaledTime * 4.0f);
            sceneFocusRect.anchoredPosition = sceneFocusBasePosition + new Vector2(0f, wave * 3.5f * alpha);
            float scale = 1f + Mathf.Sin(Time.unscaledTime * 3.1f) * 0.010f * alpha;
            sceneFocusRect.localScale = new Vector3(scale, scale, 1f);
        }

        ApplySceneFocusAlpha(alpha);
    }

    private void ApplySceneFocusAlpha(float alpha)
    {
        if (sceneFocusRect == null) return;

        float clamped = Mathf.Clamp01(alpha);
        if (clamped <= 0.001f)
        {
            if (sceneFocusRect.gameObject.activeSelf) sceneFocusRect.gameObject.SetActive(false);
            return;
        }

        if (!sceneFocusRect.gameObject.activeSelf) sceneFocusRect.gameObject.SetActive(true);
        if (sceneFocusImage != null) sceneFocusImage.color = new Color(1.00f, 0.76f, 0.34f, 0.155f * clamped);
        float slipAlpha = sceneFocusSlipVisible ? clamped : 0f;
        if (sceneFocusSlipImage != null) sceneFocusSlipImage.color = new Color(0.98f, 0.94f, 0.82f, 0.74f * slipAlpha);
        if (sceneFocusTapeImage != null) sceneFocusTapeImage.color = new Color(0.78f, 0.55f, 0.30f, 0.28f * slipAlpha);
        if (sceneFocusText != null) sceneFocusText.color = new Color(0.28f, 0.21f, 0.13f, 0.92f * slipAlpha);
    }

    private void TriggerScenePropReaction(string label, float duration)
    {
        string prop = CanonicalScenePropLabel(label);
        if (string.IsNullOrWhiteSpace(prop)) return;

        float until = Time.unscaledTime + Mathf.Max(0.4f, duration);
        if (scenePropReactionUntil.TryGetValue(prop, out float existingUntil))
        {
            scenePropReactionUntil[prop] = Mathf.Max(existingUntil, until);
        }
        else
        {
            scenePropReactionUntil[prop] = until;
        }
    }

    private void AnimateReactiveSceneProps()
    {
        float wave = reducedMotionEnabled ? 0f : Mathf.Sin(Time.unscaledTime * 4.2f) * 0.5f + 0.5f;
        float drift = reducedMotionEnabled ? 0f : Mathf.Sin(Time.unscaledTime * 2.1f);

        float laptop = GetScenePropReactionAlpha("노트북");
        float laptopIdle = 0.052f;
        SetImageAlpha(reactiveLaptopGlowImage, new Color(0.18f, 0.48f, 0.66f), 0.060f + laptop * (0.064f + wave * 0.020f));
        SetImageAlpha(reactiveLaptopScreenImage, new Color(0.30f, 0.70f, 0.88f), laptopIdle + laptop * (0.090f + wave * 0.026f));
        SetImageArrayAlpha(reactiveLaptopLineImages, new Color(0.82f, 0.96f, 1f), 0.092f + laptop * 0.32f);
        if (reactiveLaptopGlowRect != null)
        {
            reactiveLaptopGlowRect.localScale = Vector3.one * (1f + laptop * wave * 0.020f);
        }
        if (reactiveLaptopScreenRect != null)
        {
            reactiveLaptopScreenRect.localScale = Vector3.one * (1f + laptop * wave * 0.012f);
        }

        float board = GetScenePropReactionAlpha("메모");
        SetImageAlpha(reactiveBoardNoteImage, new Color(1.00f, 0.95f, 0.74f), board * 0.68f);
        SetImageArrayAlpha(reactiveBoardLineImages, new Color(0.47f, 0.36f, 0.22f), board * 0.42f);
        if (reactiveBoardNoteRect != null)
        {
            reactiveBoardNoteRect.localRotation = Quaternion.Euler(0f, 0f, -3.4f + board * drift * 1.6f);
        }

        float cup = GetScenePropReactionAlpha("컵");
        SetImageAlpha(reactiveCupSteamImageA, new Color(1f, 0.95f, 0.82f), cup * (0.13f + wave * 0.035f));
        SetImageAlpha(reactiveCupSteamImageB, new Color(1f, 0.95f, 0.82f), cup * (0.10f + (1f - wave) * 0.030f));
        if (reactiveCupSteamRectA != null) reactiveCupSteamRectA.anchoredPosition = new Vector2(356f + drift * 4f * cup, -236f + wave * 12f * cup);
        if (reactiveCupSteamRectB != null) reactiveCupSteamRectB.anchoredPosition = new Vector2(392f - drift * 3f * cup, -230f + (1f - wave) * 10f * cup);

        float notebook = GetScenePropReactionAlpha("질문");
        SetImageArrayAlpha(reactiveNotebookInkImages, new Color(0.18f, 0.16f, 0.14f), notebook * 0.44f);
        if (reactiveNotebookInkRect != null)
        {
            reactiveNotebookInkRect.localScale = new Vector3(1f + notebook * 0.015f, 1f, 1f);
        }

        float crutch = GetScenePropReactionAlpha("목발");
        SetImageAlpha(reactiveCrutchGlintImage, new Color(1.00f, 0.86f, 0.58f), crutch * (0.28f + wave * 0.08f));
        if (reactiveCrutchGlintRect != null)
        {
            reactiveCrutchGlintRect.anchoredPosition = new Vector2(610f + drift * 5f * crutch, 312f + wave * 20f * crutch);
        }

        float door = Mathf.Max(GetScenePropReactionAlpha("문"), Mathf.Max(GetScenePropReactionAlpha("지도"), GetScenePropReactionAlpha("자취방")));
        SetImageAlpha(reactiveDoorLightImage, new Color(1.0f, 0.78f, 0.38f), door * (0.11f + wave * 0.035f));
        if (reactiveDoorLightRect != null)
        {
            reactiveDoorLightRect.localScale = Vector3.one * (1f + door * wave * 0.025f);
        }
    }

    private float GetScenePropReactionAlpha(string label)
    {
        string prop = CanonicalScenePropLabel(label);
        if (string.IsNullOrWhiteSpace(prop)) return 0f;
        if (!scenePropReactionUntil.TryGetValue(prop, out float until)) return 0f;

        float remaining = until - Time.unscaledTime;
        if (remaining <= 0f) return 0f;
        return Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(remaining / 0.55f));
    }

    private string CanonicalScenePropLabel(string label)
    {
        string value = label ?? string.Empty;
        if (HasAny(value, "질문")) return "질문";
        if (HasAny(value, "노트북", "책상", "일과", "공부", "직장", "박사")) return "노트북";
        if (HasAny(value, "메모", "도움", "배려", "조율")) return "메모";
        if (HasAny(value, "컵", "취미", "게임", "노래방", "쉬")) return "컵";
        if (HasAny(value, "목발", "일상", "평범", "장애")) return "목발";
        if (HasAny(value, "창문", "문", "처음", "동선", "이동")) return "문";
        if (HasAny(value, "지도", "한국", "미국", "접근성", "교통")) return "지도";
        if (HasAny(value, "자취", "자취방", "독립", "자기이해")) return "문";
        return string.Empty;
    }

    private static void SetImageAlpha(Image image, Color rgb, float alpha)
    {
        if (image == null) return;
        image.color = new Color(rgb.r, rgb.g, rgb.b, Mathf.Clamp01(alpha));
    }

    private static void SetImageArrayAlpha(Image[] images, Color rgb, float alpha)
    {
        if (images == null) return;
        float clamped = Mathf.Clamp01(alpha);
        for (int i = 0; i < images.Length; i++)
        {
            if (images[i] == null) continue;
            images[i].color = new Color(rgb.r, rgb.g, rgb.b, clamped);
        }
    }

    private static Vector2 AnchorOffsetToCanvasCenter(Vector2 anchorMin, Vector2 anchorMax, Vector2 offsetMin, Vector2 offsetMax)
    {
        Vector2 anchor = (anchorMin + anchorMax) * 0.5f;
        Vector2 offset = (offsetMin + offsetMax) * 0.5f;
        return new Vector2((anchor.x - 0.5f) * TargetWidth + offset.x, (anchor.y - 0.5f) * TargetHeight + offset.y);
    }

    private static Vector2 ClampSceneFocusPosition(Vector2 position)
    {
        return new Vector2(
            Mathf.Clamp(position.x, -TargetWidth * 0.5f + 150f, TargetWidth * 0.5f - 150f),
            Mathf.Clamp(position.y, -TargetHeight * 0.5f + 116f, TargetHeight * 0.5f - 116f));
    }

    private static Vector2 ClampPreviewCenter(Vector2 center, Vector2 size)
    {
        float halfWidth = size.x * 0.5f + 28f;
        float halfHeight = size.y * 0.5f + 28f;
        return new Vector2(
            Mathf.Clamp(center.x, -TargetWidth * 0.5f + halfWidth, TargetWidth * 0.5f - halfWidth),
            Mathf.Clamp(center.y, -TargetHeight * 0.5f + halfHeight, TargetHeight * 0.5f - halfHeight));
    }


    private static Vector2 GetSceneFocusGlowSize(string label)
    {
        switch (label)
        {
            case "목발": return new Vector2(232f, 304f);
            case "문": return new Vector2(420f, 300f);
            case "지도": return new Vector2(270f, 176f);
            case "자취방": return new Vector2(286f, 190f);
            case "컵": return new Vector2(190f, 180f);
            case "질문": return new Vector2(390f, 126f);
            default: return new Vector2(320f, 184f);
        }
    }

    private Vector2 GetSceneFocusPositionForLabel(string label)
    {
        switch (label)
        {
            case "노트북":
                return AnchorOffsetToCanvasCenter(new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-834f, -160f), new Vector2(-390f, 110f));
            case "메모":
                return AnchorOffsetToCanvasCenter(new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-100f, 135f), new Vector2(178f, 422f));
            case "창문":
            case "문":
                return AnchorOffsetToCanvasCenter(new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-942f, 132f), new Vector2(-390f, 466f));
            case "컵":
                return AnchorOffsetToCanvasCenter(new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(850f, -104f), new Vector2(925f, -12f));
            case "지도":
                return AnchorOffsetToCanvasCenter(new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(451f, 110f), new Vector2(555f, 228f));
            case "자취방":
                return AnchorOffsetToCanvasCenter(new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-942f, 132f), new Vector2(-390f, 466f));
            case "목발":
                return AnchorOffsetToCanvasCenter(new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(678f, -176f), new Vector2(820f, 222f));
            default:
                return new Vector2(-28f, -306f);
        }
    }

    private string GetSceneFocusLabelForTheme(string rawTheme)
    {
        string theme = CanonicalTheme(rawTheme);
        switch (theme)
        {
            case "취미": return "노트북";
            case "독립": return "창문";
            case "일과 공부": return "노트북";
            case "도움": return "메모";
            case "이동": return "창문";
            case "일상": return "메모";
            default: return "장면";
        }
    }

    private Vector2 GetSceneFocusPositionForTheme(string rawTheme)
    {
        return GetSceneFocusPositionForLabel(GetSceneFocusLabelForTheme(rawTheme));
    }

    private bool IsHotspotPreviewOpen()
    {
        return hotspotPreviewObject != null && hotspotPreviewObject.activeSelf;
    }

    private void CreateTopBar(Transform parent)
    {
        statusText = CreateText("Status", parent, "대화 준비", 13, new Color32(226, 232, 240, 0), TextAnchor.MiddleRight, FontStyle.Bold);
        Stretch(statusText.rectTransform, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-640f, -64f), new Vector2(-326f, -32f));
        statusText.raycastTarget = false;

        memoryBookButton = CreateBookmarkButton("Memory Book Toggle", parent, "");
        Stretch(memoryBookButton.GetComponent<RectTransform>(), new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-118f, -58f), new Vector2(-88f, -30f));
        memoryBookButton.onClick.AddListener(() => SetMemoryBookOpen(memoryBookObject == null || !memoryBookObject.activeSelf));
        memoryBookButton.gameObject.SetActive(false);
    }

    private void CreateMemoryUnlockToast(Transform parent)
    {
        Image toast = CreatePaperPanel("Memory Unlock Toast", parent, new Color(0.985f, 0.935f, 0.795f, 0.86f), 6, 11);
        memoryUnlockToastObject = toast.gameObject;
        memoryUnlockToastRect = toast.rectTransform;
        Stretch(memoryUnlockToastRect, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-350f, -114f), new Vector2(-92f, -74f));

        memoryUnlockToastGroup = memoryUnlockToastObject.AddComponent<CanvasGroup>();
        memoryUnlockToastGroup.alpha = 0f;
        memoryUnlockToastGroup.blocksRaycasts = false;
        memoryUnlockToastGroup.interactable = false;

        Image pin = CreateRoundedPanel("Memory Unlock Pin", toast.transform, new Color(0.68f, 0.43f, 0.22f, 0.22f), 3);
        pin.raycastTarget = false;
        Stretch(pin.rectTransform, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(12f, -10f), new Vector2(16f, 10f));

        memoryUnlockToastText = CreateText("Memory Unlock Toast Text", toast.transform, "", 11, new Color(0.28f, 0.21f, 0.13f, 0.86f), TextAnchor.MiddleLeft, FontStyle.Bold);
        memoryUnlockToastText.lineSpacing = 0.92f;
        memoryUnlockToastText.resizeTextForBestFit = true;
        memoryUnlockToastText.resizeTextMinSize = 9;
        memoryUnlockToastText.resizeTextMaxSize = 11;
        Stretch(memoryUnlockToastText.rectTransform, Vector2.zero, Vector2.one, new Vector2(24f, 3f), new Vector2(-12f, -3f));

        memoryUnlockToastObject.SetActive(false);
    }

    private void CreateDialoguePanel(Transform parent)
    {
        Image panelShadow = CreatePanel("Dialogue Plaque Shadow", parent, new Color(0.030f, 0.022f, 0.014f, 0.038f));
        panelShadow.sprite = GetSoftEllipseSprite();
        panelShadow.raycastTarget = false;
        Stretch(panelShadow.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(-780f, 24f), new Vector2(780f, 276f));
        panelShadow.rectTransform.localRotation = Quaternion.identity;

        Image panel = CreateRoundedPanel("Dialogue Exhibit Plaque", parent, new Color(1.000f, 0.962f, 0.875f, 0.90f), 9);
        Stretch(panel.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(-710f, 42f), new Vector2(710f, 336f));
        panel.rectTransform.localRotation = Quaternion.identity;

        Image paperDropShadow = CreateRoundedPanel("Dialogue Paper Drop Shadow", panel.transform, new Color(0.030f, 0.022f, 0.014f, 0.052f), 7);
        paperDropShadow.raycastTarget = false;
        Stretch(paperDropShadow.rectTransform, Vector2.zero, Vector2.one, new Vector2(20f, 22f), new Vector2(-18f, -22f));

        Image paper = CreatePaperPanel("Dialogue Caption Paper", panel.transform, new Color(1.000f, 0.985f, 0.940f, 0.96f), 7, 2);
        paper.raycastTarget = false;
        Stretch(paper.rectTransform, Vector2.zero, Vector2.one, new Vector2(16f, 24f), new Vector2(-18f, -18f));

        Image paperShade = CreateRoundedPanel("Dialogue Paper Lower Shade", paper.transform, new Color(0.76f, 0.50f, 0.24f, 0.040f), 7);
        paperShade.raycastTarget = false;
        Stretch(paperShade.rectTransform, Vector2.zero, new Vector2(1f, 0f), new Vector2(0f, 0f), new Vector2(0f, 28f));

        Image upperTape = CreateRoundedPanel("Dialogue Paper Tape", paper.transform, new Color(0.86f, 0.72f, 0.47f, 0f), 4);
        upperTape.raycastTarget = false;
        Stretch(upperTape.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(-46f, -9f), new Vector2(46f, -3f));

        for (int i = 0; i < 3; i++)
        {
            Image rule = CreatePanel($"Dialogue Paper Rule {i + 1}", paper.transform, new Color(0.50f, 0.42f, 0.28f, 0f));
            rule.raycastTarget = false;
            Stretch(rule.rectTransform, Vector2.zero, Vector2.one, new Vector2(38f, 26f + i * 26f), new Vector2(-30f, 27f + i * 26f));
        }

        Image leftSpine = CreateRoundedPanel("Dialogue Paper Spine", paper.transform, new Color(0.70f, 0.44f, 0.23f, 0f), 3);
        leftSpine.raycastTarget = false;
        Stretch(leftSpine.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(18f, 16f), new Vector2(22f, -16f));

        Image accentLine = CreateRoundedPanel("Dialogue Brass Rail", panel.transform, new Color(0.90f, 0.72f, 0.42f, 0f), 3);
        accentLine.raycastTarget = false;
        Stretch(accentLine.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(32f, -42f), new Vector2(-32f, -40f));

        Image namePlate = CreateRoundedPanel("Speaker Brass Nameplate", panel.transform, new Color(0.70f, 0.44f, 0.23f, 0.42f), 4);
        Stretch(namePlate.rectTransform, new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(34f, -34f), new Vector2(124f, -17f));

        Image namePlateHighlight = CreatePanel("Speaker Nameplate Highlight", namePlate.transform, new Color(1f, 0.90f, 0.62f, 0f));
        namePlateHighlight.raycastTarget = false;
        Stretch(namePlateHighlight.rectTransform, new Vector2(0f, 1f), Vector2.one, new Vector2(8f, -6f), new Vector2(-8f, -4f));

        speakerText = CreateText("Speaker", namePlate.transform, "답변", 10, new Color(0.20f, 0.13f, 0.07f, 0.88f), TextAnchor.MiddleCenter, FontStyle.Bold);
        Stretch(speakerText.rectTransform, Vector2.zero, Vector2.one, new Vector2(8f, 0f), new Vector2(-8f, 0f));

        dialogueSizeDownButton = CreateButton("Dialogue Size Down", panel.transform, "가-", new Color32(30, 41, 59, 226), Color.white, 14);
        Stretch(dialogueSizeDownButton.GetComponent<RectTransform>(), new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(244f, -52f), new Vector2(304f, -14f));
        dialogueSizeDownButton.onClick.AddListener(() => ChangeDialogueSize(-1));
        dialogueSizeDownButton.gameObject.SetActive(false);

        dialogueSizeUpButton = CreateButton("Dialogue Size Up", panel.transform, "가+", new Color32(30, 41, 59, 226), Color.white, 14);
        Stretch(dialogueSizeUpButton.GetComponent<RectTransform>(), new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(312f, -52f), new Vector2(372f, -14f));
        dialogueSizeUpButton.onClick.AddListener(() => ChangeDialogueSize(1));
        dialogueSizeUpButton.gameObject.SetActive(false);

        CreateProgressTracker(panel.transform);

        GameObject dialogueScrollObject = new GameObject("Dialogue Scroll", typeof(RectTransform), typeof(ScrollRect));
        dialogueScrollObject.transform.SetParent(panel.transform, false);
        dialogueScrollRect = dialogueScrollObject.GetComponent<ScrollRect>();
        RectTransform dialogueScrollRT = dialogueScrollObject.GetComponent<RectTransform>();
        Stretch(dialogueScrollRT, Vector2.zero, Vector2.one, new Vector2(56f, 82f), new Vector2(-76f, -28f));

        GameObject dialogueViewportObject = new GameObject("Dialogue Viewport", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Mask));
        dialogueViewportObject.transform.SetParent(dialogueScrollObject.transform, false);
        Image viewportImage = dialogueViewportObject.GetComponent<Image>();
        viewportImage.color = new Color(0f, 0f, 0f, 0.01f);
        dialogueViewportObject.GetComponent<Mask>().showMaskGraphic = false;
        dialoguePageButton = dialogueViewportObject.AddComponent<Button>();
        dialoguePageButton.targetGraphic = viewportImage;
        dialoguePageButton.onClick.AddListener(AdvanceDialoguePageOrStory);
        dialogueViewportRect = dialogueViewportObject.GetComponent<RectTransform>();
        Stretch(dialogueViewportRect, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        GameObject dialogueContentObject = new GameObject("Dialogue Content", typeof(RectTransform));
        dialogueContentObject.transform.SetParent(dialogueViewportObject.transform, false);
        dialogueContentRect = dialogueContentObject.GetComponent<RectTransform>();
        dialogueContentRect.anchorMin = new Vector2(0f, 1f);
        dialogueContentRect.anchorMax = new Vector2(1f, 1f);
        dialogueContentRect.pivot = new Vector2(0.5f, 1f);
        dialogueContentRect.offsetMin = Vector2.zero;
        dialogueContentRect.offsetMax = Vector2.zero;
        dialogueContentRect.sizeDelta = new Vector2(0f, 150f);

        dialogueText = CreateText("Dialogue", dialogueContentObject.transform, "", 20, new Color32(30, 41, 59, 246), TextAnchor.UpperLeft, FontStyle.Normal);
        dialogueText.lineSpacing = 1.10f;
        dialogueText.verticalOverflow = VerticalWrapMode.Overflow;
        Stretch(dialogueText.rectTransform, Vector2.zero, Vector2.one, new Vector2(4f, 18f), new Vector2(-10f, -18f));
        ApplyDialogueTextSize(false);

        dialogueScrollRect.viewport = dialogueViewportRect;
        dialogueScrollRect.content = dialogueContentRect;
        dialogueScrollRect.horizontal = false;
        dialogueScrollRect.vertical = false;
        dialogueScrollRect.movementType = ScrollRect.MovementType.Clamped;
        dialogueScrollRect.scrollSensitivity = 32f;

        dialogueScrollbar = CreateVerticalScrollbar("Dialogue Scrollbar", panel.transform);
        Stretch(dialogueScrollbar.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 1f), new Vector2(-62f, 82f), new Vector2(-59f, -32f));
        dialogueScrollRect.verticalScrollbar = null;
        dialogueScrollRect.verticalScrollbarVisibility = ScrollRect.ScrollbarVisibility.AutoHide;
        dialogueScrollbar.gameObject.SetActive(false);

        Image scrollCue = CreateRoundedPanel("Dialogue Scroll Cue", panel.transform, new Color(0.48f, 0.28f, 0.12f, 0.86f), 10);
        dialogueScrollCueObject = scrollCue.gameObject;
        scrollCue.raycastTarget = false;
        Stretch(scrollCue.rectTransform, new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-430f, 90f), new Vector2(-28f, 124f));
        dialoguePageCueText = CreateText("Dialogue Page Cue Text", scrollCue.transform, "다음 대사 보기", 14, new Color32(255, 248, 225, 255), TextAnchor.MiddleCenter, FontStyle.Bold);
        dialoguePageCueText.raycastTarget = false;
        Stretch(dialoguePageCueText.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, new Vector2(0f, 1f));
        dialogueScrollCueObject.SetActive(false);

        inputField = CreateInput(panel.transform);
        Stretch(inputField.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(30f, 14f), new Vector2(-148f, 64f));
        inputField.gameObject.SetActive(true);

        micButton = CreateButton("Mic Button", panel.transform, "녹음", new Color(0.70f, 0.44f, 0.23f, 0.22f), new Color(1f, 0.96f, 0.86f, 0.68f), 12);
        Stretch(micButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-236f, 18f), new Vector2(-142f, 60f));
        micButtonLabel = micButton.GetComponentInChildren<Text>();
        micButton.onClick.AddListener(ToggleRecording);
        micButton.gameObject.SetActive(false);

        sendButton = CreateButton("Send Button", panel.transform, "전송", new Color(0.70f, 0.44f, 0.23f, 0.62f), new Color(1f, 0.96f, 0.86f, 0.96f), 17);
        Stretch(sendButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-124f, 16f), new Vector2(-28f, 62f));
        sendButton.onClick.AddListener(SubmitCurrentInput);

        storyNextButton = CreateButton("Story Mode Next Button", panel.transform, "다음 장면", new Color(0.70f, 0.44f, 0.23f, 0.70f), new Color(1f, 0.96f, 0.86f, 0.96f), 14);
        Stretch(storyNextButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(30f, 16f), new Vector2(156f, 62f));
        storyNextButton.onClick.AddListener(RequestStoryModeAdvance);
        storyNextButton.gameObject.SetActive(false);

        storyQuestionButton = CreateButton("Story Mode Question Button", panel.transform, "직접 질문", new Color(0.16f, 0.11f, 0.07f, 0.56f), new Color(1f, 0.96f, 0.86f, 0.92f), 14);
        Stretch(storyQuestionButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(166f, 16f), new Vector2(292f, 62f));
        storyQuestionButton.onClick.AddListener(StopStoryModeForDirectQuestion);
        storyQuestionButton.gameObject.SetActive(false);

        storyFinishButton = CreateButton("Story Mode Finish Button", panel.transform, $"{RequiredQuestionCount}문답 후", new Color(0.12f, 0.09f, 0.06f, 0.30f), new Color(1f, 0.96f, 0.86f, 0.72f), 13);
        Stretch(storyFinishButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(302f, 16f), new Vector2(428f, 62f));
        storyFinishButton.onClick.AddListener(ShowClosingCard);
        storyFinishButton.gameObject.SetActive(false);

        finishButton = CreateButton("Finish Conversation Button", panel.transform, "끝내기", new Color(0.12f, 0.09f, 0.06f, 0.30f), new Color(1f, 0.96f, 0.86f, 0.72f), 13);
        Stretch(finishButton.GetComponent<RectTransform>(), new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-126f, -54f), new Vector2(-30f, -16f));
        finishButton.onClick.AddListener(ShowClosingCard);
        UpdateQuestionInputLayout();
    }

    private void AddPlaqueCorner(Transform parent, string name, Vector2 inset, bool left, bool top)
    {
        Vector2 anchor = new Vector2(left ? 0f : 1f, top ? 1f : 0f);
        Color color = new Color(0.90f, 0.72f, 0.42f, 0.050f);

        float horizontalStart = left ? inset.x : inset.x - 38f;
        float horizontalEnd = left ? inset.x + 38f : inset.x;
        Image horizontal = CreatePanel($"Plaque Corner {name} Horizontal", parent, color);
        horizontal.raycastTarget = false;
        Stretch(horizontal.rectTransform, anchor, anchor, new Vector2(horizontalStart, inset.y - 2f), new Vector2(horizontalEnd, inset.y + 2f));

        float verticalStart = top ? inset.y - 30f : inset.y;
        float verticalEnd = top ? inset.y : inset.y + 30f;
        Image vertical = CreatePanel($"Plaque Corner {name} Vertical", parent, color);
        vertical.raycastTarget = false;
        Stretch(vertical.rectTransform, anchor, anchor, new Vector2(inset.x - 2f, verticalStart), new Vector2(inset.x + 2f, verticalEnd));
    }

    private void CreateProgressTracker(Transform parent)
    {
        Image tracker = CreateRoundedPanel("Interview Progress", parent, new Color(0.96f, 0.90f, 0.72f, 0.42f), 9);
        Stretch(tracker.rectTransform, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-388f, -52f), new Vector2(-28f, -14f));

        progressText = CreateText("Progress Text", tracker.transform, $"0/{RequiredQuestionCount} 질문 · 답변 대기", 12, new Color32(46, 32, 18, 232), TextAnchor.MiddleLeft, FontStyle.Bold);
        progressText.resizeTextForBestFit = true;
        progressText.resizeTextMinSize = 10;
        progressText.resizeTextMaxSize = 12;
        Stretch(progressText.rectTransform, Vector2.zero, Vector2.one, new Vector2(18f, 0f), new Vector2(-192f, 0f));

        progressDots.Clear();
        for (int i = 0; i < 5; i++)
        {
            Image dot = CreatePanel($"Progress Dot {i + 1}", tracker.transform, new Color(0.70f, 0.44f, 0.23f, 0.24f));
            dot.sprite = GetCircleSprite();
            RectTransform rect = dot.rectTransform;
            Stretch(rect, new Vector2(1f, 0.5f), new Vector2(1f, 0.5f), new Vector2(-170f + i * 30f, -7f), new Vector2(-156f + i * 30f, 7f));
            progressDots.Add(dot);
        }

        UpdateProgressTracker();
    }

    private void CreateFlowPanel(Transform parent)
    {
        CreateLeadQuestionChips(parent);
        CreateQuestionNote(parent);
    }

    private void CreateLeadQuestionChips(Transform parent)
    {
        leadButtons = new Button[3];
        leadShadows = new GameObject[3];
        leadRects = new RectTransform[3];
        leadShadowRects = new RectTransform[3];
        leadBasePositions = new Vector2[3];
        leadShadowBasePositions = new Vector2[3];
        leadBaseRotations = new float[3];
        leadHoverStates = new bool[3];
        leadIllustrationImages = new Image[3];
        float[] xStarts = { -812f, -402f, 8f };
        float[] yStarts = { 326f, 340f, 326f };
        float[] widths = { 386f, 386f, 386f };
        float[] heights = { 96f, 96f, 96f };
        float[] rotations = { -0.6f, 0.0f, 0.5f };

        for (int i = 0; i < leadButtons.Length; i++)
        {
            int captured = i;
            Image shadow = CreatePanel($"Floating Question Shadow {i + 1}", parent, new Color(0.030f, 0.022f, 0.014f, 0.075f));
            shadow.sprite = GetSoftEllipseSprite();
            shadow.raycastTarget = false;
            Stretch(
                shadow.rectTransform,
                new Vector2(0.5f, 0f),
                new Vector2(0.5f, 0f),
                new Vector2(xStarts[i] + 5f, yStarts[i] - 6f),
                new Vector2(xStarts[i] + widths[i] + 7f, yStarts[i] + heights[i] - 8f));
            shadow.rectTransform.localRotation = Quaternion.Euler(0f, 0f, rotations[i]);
            leadShadows[i] = shadow.gameObject;
            leadShadowRects[i] = shadow.rectTransform;
            leadShadowBasePositions[i] = shadow.rectTransform.anchoredPosition;

            Button button = CreateSceneClueSlipButton($"Floating Question {i + 1}", parent, i);
            RectTransform rect = button.GetComponent<RectTransform>();
            Stretch(
                rect,
                new Vector2(0.5f, 0f),
                new Vector2(0.5f, 0f),
                new Vector2(xStarts[i], yStarts[i]),
                new Vector2(xStarts[i] + widths[i], yStarts[i] + heights[i]));
            rect.localRotation = Quaternion.Euler(0f, 0f, rotations[i]);
            leadRects[i] = rect;
            leadBasePositions[i] = rect.anchoredPosition;
            leadBaseRotations[i] = rotations[i];
            Text label = FindChildText(button.transform, "Label");
            if (label != null)
            {
                label.alignment = TextAnchor.MiddleLeft;
                label.fontSize = 16;
                label.resizeTextMinSize = 12;
                label.resizeTextMaxSize = 16;
                label.lineSpacing = 1.02f;
                Stretch(label.rectTransform, Vector2.zero, Vector2.one, new Vector2(146f, 10f), new Vector2(-14f, -31f));
            }

            Text action = FindChildText(button.transform, "Action Label");
            if (action != null)
            {
                action.text = $"추천 질문 {i + 1}";
                action.fontSize = 12;
                action.resizeTextMaxSize = 12;
                Stretch(action.rectTransform, Vector2.zero, Vector2.one, new Vector2(146f, 66f), new Vector2(-14f, -9f));
            }
            Image illustration = CreateIllustrationImage(
                $"Floating Question Illustration {i + 1}",
                button.transform,
                GetIllustrationResourceForQuestion(GetLeadQuestion(i)),
                new Color(1f, 1f, 1f, 0.86f));
            if (illustration != null)
            {
                illustration.transform.SetAsFirstSibling();
                Stretch(illustration.rectTransform, Vector2.zero, Vector2.one, new Vector2(14f, 9f), new Vector2(-244f, -9f));
                leadIllustrationImages[i] = illustration;
            }
            EventTrigger trigger = button.gameObject.AddComponent<EventTrigger>();
            AddPointerTrigger(trigger, EventTriggerType.PointerEnter, () => leadHoverStates[captured] = true);
            AddPointerTrigger(trigger, EventTriggerType.PointerExit, () => leadHoverStates[captured] = false);
            button.onClick.AddListener(() => SubmitPresetQuestion(GetLeadQuestion(captured)));
            leadButtons[i] = button;
        }

        CreateLeadQuestionControls(parent);
    }

    private void CreateLeadQuestionControls(Transform parent)
    {
        leadThemeButton = CreateButton(
            "Lead Other Theme Button",
            parent,
            "중요 질문 새로고침",
            new Color(0.20f, 0.28f, 0.24f, 0.78f),
            new Color(1f, 0.96f, 0.84f, 0.96f),
            14);
        Stretch(
            leadThemeButton.GetComponent<RectTransform>(),
            new Vector2(0.5f, 0f),
            new Vector2(0.5f, 0f),
            new Vector2(-812f, 442f),
            new Vector2(-590f, 478f));
        leadThemeButton.onClick.AddListener(RefreshVisibleLeadQuestions);

        leadRefreshButton = CreateButton(
            "Lead Refresh Button",
            parent,
            "질문 새로고침",
            new Color(0.34f, 0.22f, 0.13f, 0.78f),
            new Color(1f, 0.96f, 0.84f, 0.96f),
            14);
        Stretch(
            leadRefreshButton.GetComponent<RectTransform>(),
            new Vector2(0.5f, 0f),
            new Vector2(0.5f, 0f),
            new Vector2(-574f, 442f),
            new Vector2(-402f, 478f));
        leadRefreshButton.onClick.AddListener(RefreshVisibleLeadQuestions);
    }

    private void CreateQuestionNote(Transform parent)
    {
        noteToggleButton = CreateNotebookTabButton("Question Phone Toggle", parent, "");
        Stretch(noteToggleButton.GetComponent<RectTransform>(), new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-78f, -58f), new Vector2(-48f, -30f));
        noteToggleButton.onClick.AddListener(() => SetQuestionNoteOpen(!questionNoteOpen));

        Image phoneShadow = CreateRoundedPanel("Question Note Shadow", parent, new Color(0.030f, 0.022f, 0.014f, 0.040f), 10);
        questionNoteShadowObject = phoneShadow.gameObject;
        Stretch(phoneShadow.rectTransform, new Vector2(1f, 0f), new Vector2(1f, 1f), new Vector2(-526f, 352f), new Vector2(-42f, -90f));
        phoneShadow.raycastTarget = false;

        Image phoneBody = CreateRoundedPanel("Question Note Board", parent, new Color(0.58f, 0.38f, 0.20f, 0.30f), 8);
        questionNoteObject = phoneBody.gameObject;
        Stretch(phoneBody.rectTransform, new Vector2(1f, 0f), new Vector2(1f, 1f), new Vector2(-534f, 360f), new Vector2(-54f, -100f));
        phoneBody.rectTransform.localRotation = Quaternion.identity;

        Image metalEdge = CreatePaperPanel("Question Note Outer Paper", questionNoteObject.transform, new Color(0.965f, 0.905f, 0.780f, 0.94f), 8, 3);
        Stretch(metalEdge.rectTransform, Vector2.zero, Vector2.one, new Vector2(7f, 7f), new Vector2(-7f, -7f));

        Image sideButton = CreateRoundedPanel("Question Note Binding", questionNoteObject.transform, new Color(0.84f, 0.58f, 0.30f, 0.10f), 2);
        sideButton.raycastTarget = false;
        Stretch(sideButton.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 1f), new Vector2(20f, 24f), new Vector2(22f, -24f));

        Image screen = CreatePaperPanel("Question Note Paper", questionNoteObject.transform, new Color(1.000f, 0.985f, 0.930f, 0.99f), 7, 4);
        Stretch(screen.rectTransform, Vector2.zero, Vector2.one, new Vector2(28f, 20f), new Vector2(-18f, -20f));

        for (int i = 0; i < 5; i++)
        {
            Image line = CreatePanel($"Notebook Ruled Line {i + 1}", screen.transform, new Color(0.70f, 0.44f, 0.23f, 0.080f));
            line.raycastTarget = false;
            Stretch(line.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(20f, -80f - i * 30f), new Vector2(-20f, -79f - i * 30f));
        }

        Image notch = CreateRoundedPanel("Question Note Top Tape", screen.transform, new Color(0.70f, 0.44f, 0.23f, 0.16f), 4);
        notch.raycastTarget = false;
        Stretch(notch.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(-42f, -13f), new Vector2(42f, -9f));

        Image cameraDot = CreateRoundedPanel("Question Note Tape Mark", notch.transform, new Color(0.30f, 0.20f, 0.12f, 0.12f), 3);
        cameraDot.raycastTarget = false;
        Stretch(cameraDot.rectTransform, new Vector2(1f, 0.5f), new Vector2(1f, 0.5f), new Vector2(-16f, -1f), new Vector2(-12f, 1f));

        Text phoneStatus = CreateText("Phone Status", screen.transform, "", 11, new Color32(30, 41, 59, 218), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(phoneStatus.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(24f, -30f), new Vector2(-24f, -10f));
        phoneStatus.gameObject.SetActive(false);

        Text phoneIcons = CreateText("Phone Icons", screen.transform, "", 10, new Color32(30, 41, 59, 218), TextAnchor.UpperRight, FontStyle.Bold);
        Stretch(phoneIcons.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(24f, -30f), new Vector2(-24f, -10f));
        phoneIcons.gameObject.SetActive(false);

        noteTitleText = CreateText("Note Title", screen.transform, "무엇을 물어볼까요?", 23, new Color32(15, 23, 42, 248), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(noteTitleText.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(20f, -48f), new Vector2(-20f, -14f));

        noteQuestionContent = new GameObject("Question Content", typeof(RectTransform));
        noteQuestionContent.transform.SetParent(screen.transform, false);
        Stretch(noteQuestionContent.GetComponent<RectTransform>(), Vector2.zero, Vector2.one, new Vector2(20f, 40f), new Vector2(-20f, -54f));

        Image homeIndicator = CreateRoundedPanel("Question Note Bottom Fiber", screen.transform, new Color(0.70f, 0.44f, 0.23f, 0.13f), 5);
        homeIndicator.raycastTarget = false;
        Stretch(homeIndicator.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(-34f, 14f), new Vector2(34f, 17f));

        BuildQuestionNoteContent();
        SetQuestionNoteOpen(false);
    }

    private void BuildQuestionNoteContent()
    {
        noteTabButtons = Array.Empty<Button>();

        noteQuestionBodyObject = new GameObject("Question Tab Content", typeof(RectTransform));
        noteQuestionBodyObject.transform.SetParent(noteQuestionContent.transform, false);
        Stretch(noteQuestionBodyObject.GetComponent<RectTransform>(), Vector2.zero, Vector2.one, new Vector2(0f, 0f), new Vector2(0f, -48f));
        noteQuestionBodyObject.SetActive(false);

        noteEvidenceContentObject = new GameObject("Evidence Tab Content", typeof(RectTransform));
        noteEvidenceContentObject.transform.SetParent(noteQuestionContent.transform, false);
        Stretch(noteEvidenceContentObject.GetComponent<RectTransform>(), Vector2.zero, Vector2.one, new Vector2(0f, 0f), new Vector2(0f, -48f));
        noteEvidenceContentObject.SetActive(false);

        noteHistoryContentObject = new GameObject("History Tab Content", typeof(RectTransform));
        noteHistoryContentObject.transform.SetParent(noteQuestionContent.transform, false);
        Stretch(noteHistoryContentObject.GetComponent<RectTransform>(), Vector2.zero, Vector2.one, new Vector2(0f, 12f), new Vector2(0f, -8f));

        Image progressPill = CreateRoundedPanel("Question Phone Progress", noteQuestionBodyObject.transform, new Color(0.84f, 0.58f, 0.30f, 0.52f), 7);
        Stretch(progressPill.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, -38f), new Vector2(0f, -7f));

        questionPhoneProgressText = CreateText("Question Phone Progress Text", progressPill.transform, "", 15, new Color32(46, 32, 18, 246), TextAnchor.MiddleCenter, FontStyle.Bold);
        Stretch(questionPhoneProgressText.rectTransform, Vector2.zero, Vector2.one, new Vector2(10f, 0f), new Vector2(-10f, 0f));

        leadText = CreateText("Lead Text", noteQuestionBodyObject.transform, "", 16, new Color32(51, 65, 85, 250), TextAnchor.UpperLeft, FontStyle.Normal);
        leadText.lineSpacing = 1.08f;
        Stretch(leadText.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(2f, -74f), new Vector2(-2f, -44f));

        string[] chapters = { "일상", "이동", "도움", "일과 공부", "독립", "취미" };
        chapterButtons = new Button[chapters.Length];
        chapterIllustrationImages = new Image[chapters.Length];
        for (int i = 0; i < chapters.Length; i++)
        {
            int captured = i;
            Button button = CreateNotebookChapterButton($"Chapter {chapters[i]}", noteQuestionBodyObject.transform, chapters[i], i);
            Image illustration = CreateIllustrationImage(
                $"Chapter Illustration {chapters[i]}",
                button.transform,
                GetIllustrationResourceForTheme(chapters[i]),
                new Color(1f, 1f, 1f, 0.44f));
            if (illustration != null)
            {
                illustration.transform.SetAsFirstSibling();
                Stretch(illustration.rectTransform, Vector2.zero, Vector2.one, new Vector2(8f, 5f), new Vector2(-146f, -5f));
                chapterIllustrationImages[i] = illustration;
            }
            int row = i / 2;
            bool left = i % 2 == 0;
            Stretch(
                button.GetComponent<RectTransform>(),
                new Vector2(left ? 0f : 0.5f, 1f),
                new Vector2(left ? 0.5f : 1f, 1f),
                new Vector2(left ? 0f : 6f, -126f - row * 48f),
                new Vector2(left ? -6f : 0f, -88f - row * 48f));
            button.onClick.AddListener(() => SubmitChapterQuestion(chapters[captured]));
            chapterButtons[i] = button;
        }

        Image guidePill = CreateRoundedPanel("Question Phone Session Guide", noteQuestionBodyObject.transform, new Color(0.96f, 0.98f, 0.92f, 0.78f), 7);
        Stretch(guidePill.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(0f, 56f), new Vector2(0f, 92f));

        questionPhoneGuideText = CreateText("Question Phone Session Guide Text", guidePill.transform, "", 14, new Color32(51, 65, 85, 238), TextAnchor.MiddleCenter, FontStyle.Bold);
        questionPhoneGuideText.resizeTextForBestFit = true;
        questionPhoneGuideText.resizeTextMinSize = 11;
        questionPhoneGuideText.resizeTextMaxSize = 14;
        Stretch(questionPhoneGuideText.rectTransform, Vector2.zero, Vector2.one, new Vector2(10f, 0f), new Vector2(-10f, 0f));

        moreButton = CreateNoteActionButton("More Button", noteQuestionBodyObject.transform, "더 듣기", true);
        closingButton = CreateNoteActionButton("Closing Button", noteQuestionBodyObject.transform, "남길 문장 보기", false);
        Stretch(moreButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0.5f, 0f), new Vector2(0f, 10f), new Vector2(-6f, 48f));
        Stretch(closingButton.GetComponent<RectTransform>(), new Vector2(0.5f, 0f), new Vector2(1f, 0f), new Vector2(6f, 10f), new Vector2(0f, 48f));
        SetButtonColor(moreButton, new Color(0.70f, 0.44f, 0.23f, 0.52f), new Color(1f, 0.96f, 0.86f, 0.95f));
        SetButtonColor(closingButton, new Color(0.14f, 0.10f, 0.07f, 0.42f), new Color(1f, 0.96f, 0.86f, 0.90f));
        moreButton.onClick.AddListener(SubmitMore);
        closingButton.onClick.AddListener(ShowClosingCard);
        UpdateQuestionNoteActionButtonStyles();

        Image evidenceCard = CreatePaperPanel("Evidence Note Card", noteEvidenceContentObject.transform, new Color(0.955f, 0.980f, 0.920f, 0.88f), 8, 5);
        Stretch(evidenceCard.rectTransform, Vector2.zero, Vector2.one, new Vector2(0f, 12f), new Vector2(0f, -8f));
        noteEvidenceText = CreateText("Evidence Note Text", evidenceCard.transform, "", 13, new Color32(30, 41, 59, 244), TextAnchor.UpperLeft, FontStyle.Normal);
        noteEvidenceText.lineSpacing = 1.02f;
        noteEvidenceText.resizeTextForBestFit = true;
        noteEvidenceText.resizeTextMinSize = 10;
        noteEvidenceText.resizeTextMaxSize = 13;
        Stretch(noteEvidenceText.rectTransform, Vector2.zero, Vector2.one, new Vector2(18f, 14f), new Vector2(-18f, -14f));

        Image historyCard = CreatePaperPanel("History Note Card", noteHistoryContentObject.transform, new Color(0.955f, 0.980f, 0.920f, 0.88f), 8, 6);
        Stretch(historyCard.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        GameObject historyScrollObject = new GameObject("History Note Scroll", typeof(RectTransform), typeof(ScrollRect));
        historyScrollObject.transform.SetParent(historyCard.transform, false);
        noteHistoryScrollRect = historyScrollObject.GetComponent<ScrollRect>();
        Stretch(historyScrollObject.GetComponent<RectTransform>(), Vector2.zero, Vector2.one, new Vector2(18f, 16f), new Vector2(-26f, -16f));

        GameObject historyViewportObject = new GameObject("History Note Viewport", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Mask));
        historyViewportObject.transform.SetParent(historyScrollObject.transform, false);
        Image historyViewportImage = historyViewportObject.GetComponent<Image>();
        historyViewportImage.color = new Color(1f, 1f, 1f, 0.01f);
        historyViewportObject.GetComponent<Mask>().showMaskGraphic = false;
        noteHistoryViewportRect = historyViewportObject.GetComponent<RectTransform>();
        Stretch(noteHistoryViewportRect, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        GameObject historyContentObject = new GameObject("History Note Content", typeof(RectTransform));
        historyContentObject.transform.SetParent(historyViewportObject.transform, false);
        noteHistoryContentRect = historyContentObject.GetComponent<RectTransform>();
        noteHistoryContentRect.anchorMin = new Vector2(0f, 1f);
        noteHistoryContentRect.anchorMax = new Vector2(1f, 1f);
        noteHistoryContentRect.pivot = new Vector2(0.5f, 1f);
        noteHistoryContentRect.offsetMin = Vector2.zero;
        noteHistoryContentRect.offsetMax = Vector2.zero;
        noteHistoryContentRect.sizeDelta = new Vector2(0f, 360f);

        noteHistoryText = CreateText("History Note Text", historyContentObject.transform, "", 15, new Color32(30, 41, 59, 244), TextAnchor.UpperLeft, FontStyle.Normal);
        noteHistoryText.lineSpacing = 1.02f;
        noteHistoryText.resizeTextForBestFit = false;
        Stretch(noteHistoryText.rectTransform, Vector2.zero, Vector2.one, new Vector2(0f, 0f), new Vector2(-8f, -8f));

        noteHistoryScrollRect.viewport = noteHistoryViewportRect;
        noteHistoryScrollRect.content = noteHistoryContentRect;
        noteHistoryScrollRect.horizontal = false;
        noteHistoryScrollRect.vertical = true;
        noteHistoryScrollRect.movementType = ScrollRect.MovementType.Clamped;
        noteHistoryScrollRect.scrollSensitivity = 32f;

        UpdateQuestionPhoneProgress();
        ShowNoteTab(2);
    }

    private void SetQuestionNoteOpen(bool open)
    {
        if (open) CloseHotspotPreview();
        questionNoteOpen = open;
        if (questionNoteObject != null) questionNoteObject.SetActive(open);
        if (questionNoteShadowObject != null) questionNoteShadowObject.SetActive(open);
        if (noteToggleButton != null)
        {
            Text label = noteToggleButton.GetComponentInChildren<Text>();
            if (label != null) label.text = open ? "×" : "";
        }
        if (open)
        {
            UpdateNoteTabContent();
            PlayPageSound();
            SelectFirstInteractable(questionNoteObject, "History Note Card");
        }
        else
        {
            ClearSelectionIfInside(questionNoteObject);
        }

        ShowHotspotLabels();
        UpdateLeadSlipVisibility();
    }

    private void ShowNoteTab(int index)
    {
        currentNoteTabIndex = 2;
        if (noteQuestionContent != null) noteQuestionContent.SetActive(true);
        if (noteQuestionBodyObject != null) noteQuestionBodyObject.SetActive(false);
        if (noteEvidenceContentObject != null) noteEvidenceContentObject.SetActive(false);
        if (noteHistoryContentObject != null) noteHistoryContentObject.SetActive(true);

        if (noteTitleText != null)
        {
            noteTitleText.text = "지난 대화";
        }

        UpdateNoteTabStyles();
        UpdateNoteTabContent();
    }

    private void UpdateNoteTabStyles()
    {
        if (noteTabButtons == null) return;

        for (int i = 0; i < noteTabButtons.Length; i++)
        {
            Button tab = noteTabButtons[i];
            if (tab == null) continue;

            bool selected = i == currentNoteTabIndex;
            SetButtonColor(
                tab,
                selected ? new Color(0.70f, 0.44f, 0.23f, 0.66f) : new Color(1.00f, 0.98f, 0.90f, 0.90f),
                selected ? new Color32(255, 248, 232, 252) : new Color32(46, 32, 18, 238));
        }
    }

    private void UpdateNoteTabContent()
    {
        if (noteEvidenceText != null)
        {
            noteEvidenceText.text = BuildEvidenceNoteText();
        }

        if (noteHistoryText != null)
        {
            noteHistoryText.text = BuildHistoryNoteText();
            RefreshNoteHistoryScroll();
        }
    }

    private string BuildEvidenceNoteText()
    {
        string theme = string.IsNullOrWhiteSpace(lastTheme) ? "아직 없음" : lastTheme;
        string sceneLine = string.IsNullOrWhiteSpace(lastTheme)
            ? "질문을 고르면 이곳에 장면이 열립니다."
            : $"{theme} 장면이 열렸습니다. 다음 답변도 이 흐름에 맞춰 이어집니다.";

        string memoryNote = "아직 대화 기록에 남긴 메모가 없습니다.";
        EnsureMemoryNotes();
        string canonicalTheme = CanonicalTheme(theme);
        int themeIndex = Array.IndexOf(memoryThemes, canonicalTheme);
        if (themeIndex >= 0 && themeIndex < memoryNotes.Length && !string.IsNullOrWhiteSpace(memoryNotes[themeIndex]))
        {
            memoryNote = memoryNotes[themeIndex];
        }

        string attitude = string.IsNullOrWhiteSpace(lastQuestionAttitude) ? "아직 없음" : lastQuestionAttitude;

        StringBuilder builder = new StringBuilder();
        builder.Append("<b><color=#1E293B>진행 요약</color></b>  ");
        builder.Append(SanitizeRichText($"{Mathf.Clamp(conversationTurns, 0, RequiredQuestionCount)}/{RequiredQuestionCount} 질문")).AppendLine();
        builder.Append("<color=#B1713A>────────────────</color>").AppendLine();
        builder.Append("<b>질문 흐름</b>  ").Append(SanitizeRichText(ShortenForCard(BuildClosingQuestionFlowLine(5, 72), 84))).AppendLine();
        builder.Append("<b>질문 태도</b>  ").Append(SanitizeRichText(attitude)).AppendLine();
        builder.Append("<b>답변 출처</b>  ").Append(SanitizeRichText(FormatAnswerSourceForPlayer())).AppendLine();
        builder.AppendLine();
        builder.Append("<b><color=#7C2D12>최근 답변 메모</color></b>").AppendLine();
        builder.Append(SanitizeRichText(ShortenForCard(sceneLine, 118))).AppendLine();
        builder.AppendLine();
        builder.Append("<b><color=#7C2D12>대화 메모</color></b>").AppendLine();
        builder.Append(SanitizeRichText(ShortenForCard(memoryNote, 62)));
        return builder.ToString();
    }

    private string BuildHistoryNoteText()
    {
        if (history.Count == 0)
        {
            return "<b><color=#1E293B>최근 대화 없음</color></b>\n<color=#B1713A>────────────────</color>\n질문을 고르면 최근 질문과 답변이 이곳에 남습니다.";
        }

        StringBuilder builder = new StringBuilder();
        builder.Append("<b><color=#1E293B>최근 대화</color></b>  ");
        int totalQuestions = CountHistoryQuestions();
        builder.Append(SanitizeRichText($"전체 {totalQuestions}개 · 현재 {Mathf.Clamp(conversationTurns, 0, RequiredQuestionCount)}/{RequiredQuestionCount}")).AppendLine();
        builder.Append("<color=#B1713A>────────────────</color>").AppendLine();
        for (int i = 0; i < history.Count; i++)
        {
            ChatMessage message = history[i];
            if (message == null) continue;
            string role = message.role == "user" ? "나" : "답변";
            string content = (message.content ?? string.Empty).Replace("\r", string.Empty).Trim();
            string color = message.role == "user" ? "#7C2D12" : "#1E293B";
            builder.AppendLine();
            builder.Append("<b><color=").Append(color).Append(">");
            builder.Append(SanitizeRichText(role)).Append("</color></b>  ");
            builder.Append(SanitizeRichText(content));
        }

        return builder.ToString().TrimEnd();
    }

    private int CountHistoryQuestions()
    {
        int count = 0;
        for (int i = 0; i < history.Count; i++)
        {
            ChatMessage message = history[i];
            if (message != null && string.Equals(message.role, "user", StringComparison.Ordinal))
            {
                count++;
            }
        }

        return count;
    }

    private void RefreshNoteHistoryScroll()
    {
        if (noteHistoryText == null || noteHistoryContentRect == null || noteHistoryScrollRect == null) return;

        Canvas.ForceUpdateCanvases();
        float minHeight = noteHistoryViewportRect != null ? noteHistoryViewportRect.rect.height + 1f : 360f;
        float preferred = noteHistoryText.preferredHeight + 28f;
        noteHistoryContentRect.sizeDelta = new Vector2(0f, Mathf.Max(minHeight, preferred));
        Canvas.ForceUpdateCanvases();
        noteHistoryScrollRect.verticalNormalizedPosition = 1f;
    }

    private void CreateClosingSensitiveQuestionOverlay(Transform parent)
    {
        Image overlay = CreatePanel("Closing Sensitive Question Overlay", parent, ModalOverlayColor);
        closingSensitiveQuestionObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image panelShadow = CreateRoundedPanel("Closing Sensitive Question Shadow", closingSensitiveQuestionObject.transform, ModalShadowColor, 28);
        panelShadow.raycastTarget = false;
        Stretch(panelShadow.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-716f, -398f), new Vector2(724f, 378f));

        Image panel = CreatePaperPanel("Closing Sensitive Question Panel", closingSensitiveQuestionObject.transform, new Color(0.985f, 0.965f, 0.900f, 0.99f), 26, 8);
        Stretch(panel.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-730f, -380f), new Vector2(706f, 398f));

        Image accent = CreateRoundedPanel("Closing Sensitive Question Accent", panel.transform, new Color32(177, 113, 58, 225), 6);
        accent.raycastTarget = false;
        Stretch(accent.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -86f), new Vector2(-44f, -76f));

        Text title = CreateText("Closing Sensitive Question Title", panel.transform, "마지막으로 하나만 더", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(title.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -58f), new Vector2(-44f, -18f));

        Text subtitle = CreateText(
            "Closing Sensitive Question Subtitle",
            panel.transform,
            "말로 묻기 어려운 질문입니다. 가장 마음에 남는 장면 하나를 고르면 짧은 답을 듣고 마무리로 넘어갑니다.",
            16,
            new Color32(71, 85, 105, 255),
            TextAnchor.UpperLeft,
            FontStyle.Normal);
        subtitle.resizeTextForBestFit = true;
        subtitle.resizeTextMinSize = 13;
        subtitle.resizeTextMaxSize = 16;
        Stretch(subtitle.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -126f), new Vector2(-44f, -96f));

        int count = Mathf.Min(6, closingSensitiveQuestions.Length);
        closingSensitiveQuestionButtons = new Button[count];
        for (int i = 0; i < count; i++)
        {
            int captured = i;
            int row = i / 3;
            int col = i % 3;
            Button card = CreateClosingSensitiveQuestionCard(panel.transform, i, closingSensitiveQuestions[i]);
            Stretch(
                card.GetComponent<RectTransform>(),
                new Vector2(0f, 1f),
                new Vector2(0f, 1f),
                new Vector2(54f + col * 438f, -392f - row * 260f),
                new Vector2(448f + col * 438f, -148f - row * 260f));
            card.onClick.AddListener(() => AnswerClosingSensitiveQuestion(closingSensitiveQuestions[captured]));
            closingSensitiveQuestionButtons[i] = card;
        }

        closingSensitiveQuestionObject.SetActive(false);
    }

    private Button CreateClosingSensitiveQuestionCard(Transform parent, int index, string question)
    {
        GameObject root = new GameObject($"Closing Sensitive Question Card {index + 1}", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button));
        root.transform.SetParent(parent, false);

        Image background = root.GetComponent<Image>();
        background.sprite = GetPaperRoundedSprite(12, 60 + index);
        background.type = Image.Type.Sliced;
        background.color = new Color(1.000f, 0.990f, 0.950f, 0.98f);

        Button button = root.GetComponent<Button>();
        ColorBlock colors = button.colors;
        colors.normalColor = background.color;
        colors.highlightedColor = new Color(1.000f, 0.965f, 0.880f, 1f);
        colors.pressedColor = new Color(0.92f, 0.84f, 0.72f, 1f);
        colors.disabledColor = new Color(0.80f, 0.76f, 0.68f, 0.56f);
        button.colors = colors;
        button.onClick.AddListener(PlayButtonSound);

        Image illustration = CreateIllustrationImage(
            $"Closing Sensitive Question Illustration {index + 1}",
            root.transform,
            GetClosingSensitiveIllustrationResource(index, question),
            new Color(1f, 1f, 1f, 0.88f));
        if (illustration != null)
        {
            Stretch(illustration.rectTransform, Vector2.zero, Vector2.one, new Vector2(14f, 76f), new Vector2(-14f, -14f));
        }

        Image numberPill = CreateRoundedPanel("Closing Sensitive Question Number", root.transform, new Color32(177, 113, 58, 218), 10);
        numberPill.raycastTarget = false;
        Stretch(numberPill.rectTransform, new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(16f, -36f), new Vector2(62f, -12f));

        Text number = CreateText("Number Label", numberPill.transform, (index + 1).ToString(CultureInfo.InvariantCulture), 13, new Color32(255, 248, 232, 255), TextAnchor.MiddleCenter, FontStyle.Bold);
        Stretch(number.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image textShade = CreateRoundedPanel("Closing Sensitive Question Text Shade", root.transform, new Color(1.000f, 0.985f, 0.930f, 0.94f), 10);
        textShade.raycastTarget = false;
        Stretch(textShade.rectTransform, Vector2.zero, Vector2.one, new Vector2(14f, 14f), new Vector2(-14f, -166f));

        Text label = CreateText("Label", root.transform, question, 18, new Color32(30, 41, 59, 255), TextAnchor.MiddleLeft, FontStyle.Bold);
        label.lineSpacing = 1.02f;
        label.resizeTextForBestFit = true;
        label.resizeTextMinSize = 13;
        label.resizeTextMaxSize = 18;
        Stretch(label.rectTransform, Vector2.zero, Vector2.one, new Vector2(26f, 18f), new Vector2(-26f, -170f));
        return button;
    }

    private string GetClosingSensitiveIllustrationResource(int index, string question)
    {
        switch (Mathf.Clamp(index, 0, 5))
        {
            case 0: return "ai-card-help-hands";
            case 1: return "ai-card-boundary-table";
            case 2: return "ai-card-independent-room";
            case 3: return "ai-card-study-laptop";
            case 4: return "ai-card-mobility-map";
            case 5: return "ai-card-ordinary-day";
            default: return GetIllustrationResourceForQuestion(question);
        }
    }

    private void CreateCompletionChoiceOverlay(Transform parent)
    {
        Image overlay = CreatePanel("Completion Choice Overlay", parent, FocusModalOverlayColor);
        completionChoiceObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image shadow = CreateRoundedPanel("Completion Choice Shadow", completionChoiceObject.transform, ModalShadowColor, 28);
        shadow.raycastTarget = false;
        Stretch(shadow.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-330f, -178f), new Vector2(338f, 170f));

        Image panel = CreatePaperPanel("Completion Choice Panel", completionChoiceObject.transform, new Color(0.985f, 0.965f, 0.900f, 0.99f), 24, 8);
        Stretch(panel.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-344f, -160f), new Vector2(324f, 188f));

        Image accent = CreateRoundedPanel("Completion Choice Accent", panel.transform, new Color32(177, 113, 58, 230), 6);
        accent.raycastTarget = false;
        Stretch(accent.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(34f, -74f), new Vector2(-34f, -64f));

        Text title = CreateText("Completion Choice Title", panel.transform, "질문 5개를 마쳤어요", 28, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(title.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(38f, -48f), new Vector2(-38f, -14f));

        Text subtitle = CreateText(
            "Completion Choice Subtitle",
            panel.transform,
            "여기서 잠깐 멈춥니다. 질문을 5개 더 이어가거나, 마지막 질문으로 넘어갈 수 있어요.",
            17,
            new Color32(51, 65, 85, 250),
            TextAnchor.UpperLeft,
            FontStyle.Normal);
        subtitle.lineSpacing = 1.08f;
        subtitle.resizeTextForBestFit = true;
        subtitle.resizeTextMinSize = 13;
        subtitle.resizeTextMaxSize = 17;
        Stretch(subtitle.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(38f, -128f), new Vector2(-38f, -88f));

        completionMoreButton = CreateNoteActionButton("Completion Choice More", panel.transform, "5개 더 물어보기", true);
        Stretch(completionMoreButton.GetComponent<RectTransform>(), Vector2.zero, Vector2.one, new Vector2(38f, 62f), new Vector2(-352f, -238f));
        completionMoreButton.onClick.AddListener(() =>
        {
            if (completionChoiceObject != null) completionChoiceObject.SetActive(false);
            SubmitMore();
        });

        completionFinishButton = CreateNoteActionButton("Completion Choice Finish", panel.transform, "끝내기", false);
        Stretch(completionFinishButton.GetComponent<RectTransform>(), Vector2.zero, Vector2.one, new Vector2(332f, 62f), new Vector2(-38f, -238f));
        SetButtonColor(completionFinishButton, new Color(0.045f, 0.052f, 0.064f, 0.82f), new Color(1f, 0.96f, 0.86f, 0.98f));
        completionFinishButton.onClick.AddListener(() =>
        {
            if (completionChoiceObject != null) completionChoiceObject.SetActive(false);
            ShowClosingCard();
        });

        completionChoiceObject.SetActive(false);
    }

    private void ShowCompletionChoiceOverlay()
    {
        if (completionChoiceObject == null) return;

        pendingCompletionChoiceAfterDialogue = false;
        if (closingCardObject != null) closingCardObject.SetActive(false);
        if (closingSensitiveQuestionObject != null) closingSensitiveQuestionObject.SetActive(false);
        SetQuestionNoteOpen(false);
        completionChoiceObject.SetActive(true);
        completionChoiceObject.transform.SetAsLastSibling();

        bool hasNext = HasNextQuestionCategory();
        if (completionMoreButton != null)
        {
            completionMoreButton.gameObject.SetActive(hasNext);
            completionMoreButton.interactable = hasNext;
        }
        if (completionFinishButton != null) completionFinishButton.interactable = true;

        SetLeadButtonsInteractable(false);
        UpdateLeadSlipVisibility();
        statusText.text = $"{BuildActiveCategoryLabel()} {RequiredQuestionCount}문답 완료 · 더 물어볼지 끝낼지 선택하세요";
        SelectFirstInteractable(completionChoiceObject, "Completion Choice More", "Completion Choice Finish");
    }

    private void CreateClosingCardOverlay(Transform parent)
    {
        Image overlay = CreatePanel("Closing Card Overlay", parent, ModalOverlayColor);
        closingCardObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image shadow = CreateRoundedPanel("Closing Card Shadow", closingCardObject.transform, ModalShadowColor, 34);
        Stretch(shadow.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-676f, -398f), new Vector2(684f, 386f));

        Image card = CreatePaperPanel("Closing Card", closingCardObject.transform, new Color(0.985f, 0.965f, 0.900f, 0.99f), 34, 7);
        Stretch(card.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-690f, -378f), new Vector2(670f, 406f));

        closingCardIllustrationImage = CreateIllustrationImage(
            "Closing Result Illustration",
            card.transform,
            "ending-card-reflection-wide",
            new Color(1f, 1f, 1f, 0.94f));
        if (closingCardIllustrationImage != null)
        {
            closingCardIllustrationImage.transform.SetAsFirstSibling();
            closingCardIllustrationImage.color = new Color(1f, 1f, 1f, 0.94f);
            closingCardIllustrationImage.preserveAspect = true;
            Stretch(closingCardIllustrationImage.rectTransform, Vector2.zero, Vector2.one, new Vector2(64f, 284f), new Vector2(-704f, -166f));
        }

        Image illustrationVeil = CreateRoundedPanel("Closing Result Illustration Veil", card.transform, new Color(0.030f, 0.024f, 0.018f, 0.08f), 18);
        illustrationVeil.raycastTarget = false;
        Stretch(illustrationVeil.rectTransform, Vector2.zero, Vector2.one, new Vector2(64f, 284f), new Vector2(-704f, -166f));
        illustrationVeil.transform.SetSiblingIndex(closingCardIllustrationImage != null ? 1 : 0);

        Image accent = CreateRoundedPanel("Closing Card Accent", card.transform, new Color32(177, 113, 58, 235), 7);
        Stretch(accent.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(46f, -74f), new Vector2(-46f, -64f));

        Image upperTape = CreateRoundedPanel("Closing Card Upper Tape", card.transform, new Color(0.90f, 0.80f, 0.58f, 0.24f), 5);
        upperTape.raycastTarget = false;
        Stretch(upperTape.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(-70f, -16f), new Vector2(70f, -6f));
        upperTape.rectTransform.localRotation = Quaternion.Euler(0f, 0f, -1.6f);

        Text title = CreateText("Closing Card Title", card.transform, "대화의 끝에 남기는 말", 32, new Color32(30, 41, 59, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(title.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(48f, -52f), new Vector2(-48f, -12f));

        Text subtitle = CreateText("Closing Card Subtitle", card.transform, "질문으로 들은 장면을 지나, 마지막으로 대상자에게 남길 말을 적어 주세요.", 17, new Color32(71, 85, 105, 255), TextAnchor.UpperLeft, FontStyle.Normal);
        Stretch(subtitle.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(48f, -108f), new Vector2(-48f, -78f));

        Image quotePaper = CreatePaperPanel("Closing Quote Paper", card.transform, new Color(1f, 0.985f, 0.940f, 0.00f), 14, 0);
        quotePaper.raycastTarget = false;
        Stretch(quotePaper.rectTransform, Vector2.zero, Vector2.one, new Vector2(64f, 284f), new Vector2(-704f, -166f));

        Image quoteSpine = CreateRoundedPanel("Closing Quote Spine", quotePaper.transform, new Color(0.70f, 0.44f, 0.23f, 0f), 4);
        quoteSpine.raycastTarget = false;
        Stretch(quoteSpine.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(20f, 20f), new Vector2(26f, -20f));

        for (int i = 0; i < 4; i++)
        {
            Image rule = CreatePanel($"Closing Quote Rule {i + 1}", quotePaper.transform, new Color(0.44f, 0.34f, 0.20f, 0f));
            rule.raycastTarget = false;
            Stretch(rule.rectTransform, new Vector2(0f, 1f), Vector2.one, new Vector2(52f, -46f - i * 36f), new Vector2(-38f, -45f - i * 36f));
        }

        Image quoteFocus = CreateRoundedPanel("Closing Quote Focus", quotePaper.transform, new Color(0.030f, 0.025f, 0.020f, 0f), 14);
        quoteFocus.raycastTarget = false;
        Stretch(quoteFocus.rectTransform, Vector2.zero, Vector2.one, new Vector2(58f, 46f), new Vector2(-38f, -50f));

        closingCardQuoteText = CreateText("Closing Card Quote", card.transform, "", 28, new Color32(255, 248, 232, 255), TextAnchor.MiddleCenter, FontStyle.Bold);
        closingCardQuoteText.lineSpacing = 1.08f;
        closingCardQuoteText.resizeTextForBestFit = true;
        closingCardQuoteText.resizeTextMinSize = 20;
        closingCardQuoteText.resizeTextMaxSize = 28;
        Stretch(closingCardQuoteText.rectTransform, Vector2.zero, Vector2.one, new Vector2(156f, 440f), new Vector2(-156f, -232f));

        closingCardCaptionText = CreateText("Closing Card Caption", card.transform, "", 16, new Color32(255, 246, 225, 235), TextAnchor.UpperCenter, FontStyle.Normal);
        closingCardCaptionText.lineSpacing = 1.08f;
        closingCardCaptionText.resizeTextForBestFit = true;
        closingCardCaptionText.resizeTextMinSize = 13;
        closingCardCaptionText.resizeTextMaxSize = 16;
        Stretch(closingCardCaptionText.rectTransform, Vector2.zero, Vector2.one, new Vector2(156f, 402f), new Vector2(-156f, -274f));

        Text messageTitle = CreateText("Closing Message Title", card.transform, "대상자에게 남길 말", 18, new Color32(30, 41, 59, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(messageTitle.rectTransform, Vector2.zero, Vector2.one, new Vector2(64f, 126f), new Vector2(-64f, -616f));

        closingMessageInput = CreateClosingMessageInput(card.transform);
        Stretch(closingMessageInput.GetComponent<RectTransform>(), Vector2.zero, Vector2.one, new Vector2(64f, 64f), new Vector2(-560f, -650f));
        closingMessageInput.onValueChanged.AddListener(_ =>
        {
            closingMessageToInterviewee = GetClosingMessageToInterviewee();
            if (closingMessageValidationText != null && !string.IsNullOrWhiteSpace(closingMessageToInterviewee))
            {
                closingMessageValidationText.text = "저장할 준비가 되었습니다.";
                closingMessageValidationText.color = new Color32(22, 101, 52, 245);
            }
            SaveSession();
        });

        closingMessageValidationText = CreateText("Closing Message Validation", card.transform, "남길 말을 먼저 입력해 주세요.", 13, new Color32(124, 45, 18, 245), TextAnchor.UpperLeft, FontStyle.Bold);
        closingMessageValidationText.resizeTextForBestFit = true;
        closingMessageValidationText.resizeTextMinSize = 10;
        closingMessageValidationText.resizeTextMaxSize = 12;
        Stretch(closingMessageValidationText.rectTransform, Vector2.zero, Vector2.one, new Vector2(64f, 28f), new Vector2(-560f, -732f));

        Image summaryPanel = CreatePaperPanel("Closing Summary Panel", card.transform, new Color(1.000f, 0.985f, 0.940f, 0.94f), 14, 6);
        Stretch(summaryPanel.rectTransform, Vector2.zero, Vector2.one, new Vector2(732f, 284f), new Vector2(-64f, -166f));

        Image summaryClip = CreateRoundedPanel("Closing Summary Clip", summaryPanel.transform, new Color32(177, 113, 58, 205), 4);
        summaryClip.raycastTarget = false;
        Stretch(summaryClip.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(18f, 18f), new Vector2(24f, -18f));

        closingCardSummaryText = CreateText("Closing Summary Text", summaryPanel.transform, "", 18, new Color32(30, 41, 59, 245), TextAnchor.UpperLeft, FontStyle.Normal);
        closingCardSummaryText.lineSpacing = 1.24f;
        closingCardSummaryText.horizontalOverflow = HorizontalWrapMode.Wrap;
        closingCardSummaryText.verticalOverflow = VerticalWrapMode.Truncate;
        closingCardSummaryText.resizeTextForBestFit = false;
        closingCardSummaryText.fontSize = 17;
        Stretch(closingCardSummaryText.rectTransform, Vector2.zero, Vector2.one, new Vector2(44f, 30f), new Vector2(-34f, -30f));
        closingCreditsTextRect = null;

        closingCardChoiceButtons = new Button[closingQuotes.Length];
        for (int i = 0; i < closingCardChoiceButtons.Length; i++)
        {
            int captured = i;
            Button choice = CreateClosingChoiceTagButton($"Closing Choice {i + 1}", card.transform, closingChoiceLabels[i], i);
            Stretch(choice.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(48f + i * 166f, 92f), new Vector2(198f + i * 166f, 136f));
            choice.onClick.AddListener(() =>
            {
                SelectClosingCard(captured);
                SaveSession();
            });
            choice.gameObject.SetActive(false);
            closingCardChoiceButtons[i] = choice;
        }

        closingCardSaveButton = CreateNoteActionButton("Closing Card Save", card.transform, "기록함에 저장", true);
        Stretch(closingCardSaveButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-520f, 76f), new Vector2(-360f, 126f));
        closingCardSaveButton.gameObject.SetActive(false);
        closingCardSaveButton.onClick.AddListener(() =>
        {
            lastClosingCardShortcutAction = "save-button";
            SaveEndingRecord();
        });

        closingCardContinueButton = CreateNoteActionButton("Closing Card Continue", card.transform, "5개 더 물어보기", false);
        Stretch(closingCardContinueButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-344f, 76f), new Vector2(-174f, 126f));
        closingCardContinueButton.gameObject.SetActive(false);
        SetButtonColor(closingCardContinueButton, new Color(0.045f, 0.052f, 0.064f, 0.80f), new Color(1f, 0.96f, 0.86f, 0.98f));
        closingCardContinueButton.onClick.AddListener(() =>
        {
            lastClosingCardShortcutAction = "next-category-button";
            ContinueToNextQuestionCategory();
        });

        closingCardCloseButton = CreateNoteActionButton("Closing Card Close", card.transform, "끝내기", false);
        Stretch(closingCardCloseButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-214f, 76f), new Vector2(-64f, 126f));
        SetButtonColor(closingCardCloseButton, new Color(0.70f, 0.44f, 0.23f, 0.90f), new Color(1f, 0.96f, 0.86f, 0.98f));
        closingCardCloseButton.onClick.AddListener(() =>
        {
            if (!HasSavedEndingRecordThisSession() || string.IsNullOrWhiteSpace(GetClosingMessageToInterviewee()))
            {
                SaveEndingRecord();
                if (!HasSavedEndingRecordThisSession()) return;
            }
            ReturnToMainMenuAfterEnding();
        });

        Button feedbackButton = CreateNoteActionButton("Closing Card Feedback", card.transform, "의견 남기기", false);
        Stretch(feedbackButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-520f, 22f), new Vector2(-360f, 64f));
        feedbackButton.gameObject.SetActive(false);
        SetButtonColor(feedbackButton, new Color(0.045f, 0.052f, 0.064f, 0.82f), new Color(1f, 0.96f, 0.86f, 0.98f));
        feedbackButton.onClick.AddListener(() => SetPlaytestFeedbackOpen(true));

        SelectClosingCard(0);
        closingCardObject.SetActive(false);
    }

    private void SelectClosingCard(int index)
    {
        int selected = Mathf.Clamp(index, 0, closingQuotes.Length - 1);
        selectedClosingIndex = selected;
        if (closingCardQuoteText != null) closingCardQuoteText.text = string.Empty;
        if (closingCardCaptionText != null) closingCardCaptionText.text = string.Empty;
        UpdateClosingSummary();

        if (closingCardChoiceButtons == null) return;
        for (int i = 0; i < closingCardChoiceButtons.Length; i++)
        {
            Color background = i == selected
                ? (Color)new Color32(177, 113, 58, 235)
                : new Color(1f, 0.99f, 0.95f, 0.96f);
            Color foreground = i == selected ? Color.white : (Color)new Color32(30, 41, 59, 255);
            SetButtonColor(closingCardChoiceButtons[i], background, foreground);
        }

        RefreshClosingChoiceLabels();
    }

    private void SaveEndingRecord()
    {
        try
        {
            string message = GetClosingMessageToInterviewee();
            if (string.IsNullOrWhiteSpace(message))
            {
                statusText.text = "대상자에게 남길 말을 먼저 입력해 주세요";
                if (closingMessageValidationText != null)
                {
                    closingMessageValidationText.text = "빈칸으로는 저장할 수 없습니다.";
                    closingMessageValidationText.color = new Color32(124, 45, 18, 255);
                }
                if (closingMessageInput != null)
                {
                    closingMessageInput.ActivateInputField();
                }
                PlaySound(errorClip);
                return;
            }

            closingMessageToInterviewee = message;
            string directory = GetEndingRecordDirectory();
            Directory.CreateDirectory(directory);

            string stamp = DateTime.Now.ToString("yyyyMMdd-HHmmss-fff");
            string fileName = $"ending-{stamp}.txt";
            string path = Path.Combine(directory, fileName);
            File.WriteAllText(path, BuildEndingRecordText(), Encoding.UTF8);
            string messagePath = Path.Combine(directory, $"message-to-interviewee-{stamp}.txt");
            File.WriteAllText(messagePath, BuildIntervieweeMessageText(), Encoding.UTF8);
            lastSavedEndingRecordPath = path;
            lastSavedIntervieweeMessagePath = messagePath;

            selectedRecordArchiveIndex = 0;
            if (recordArchiveObject != null)
            {
                SetRecordArchiveOpen(true);
            }

            PlaySound(confirmClip);
            statusText.text = "기록 저장됨 · 대상자에게 전할 메시지도 저장";
            if (closingMessageValidationText != null)
            {
                closingMessageValidationText.text = "전달용 파일로 저장했습니다. 대상자에게 꼭 전해드릴게요.";
                closingMessageValidationText.color = new Color32(22, 101, 52, 245);
            }
        }
        catch (Exception ex)
        {
            statusText.text = "기록 저장에 실패했습니다";
            Debug.LogWarning($"Failed to save ending record: {ex.Message}");
        }
    }

    private static string GetEndingRecordDirectory()
    {
        return Path.Combine(Application.persistentDataPath, "EndingCards");
    }

    private static string GetPlaytestFeedbackDirectory()
    {
        return Path.Combine(Application.persistentDataPath, "FeedbackNotes");
    }

    private static string GetLegacyPlaytestFeedbackDirectory()
    {
        return Path.Combine(Application.persistentDataPath, "PlaytestFeedback");
    }

    private string BuildEndingRecordText()
    {
        int selected = Mathf.Clamp(selectedClosingIndex, 0, closingQuotes.Length - 1);
        StringBuilder builder = new StringBuilder();
        builder.AppendLine(GameTitle);
        builder.AppendLine($"저장 시각: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
        builder.AppendLine();
        builder.AppendLine("세션 요약");
        builder.AppendLine($"문답 수: {conversationTurns}");
        builder.AppendLine($"세션 완성도: {BuildSessionCompletionLine()}");
        builder.AppendLine($"가장 많이 물은 태도: {GetDominantAttitude()}");
        builder.AppendLine($"질문 흐름: {BuildClosingQuestionFlowLine(RequiredQuestionCount, 240)}");
        builder.AppendLine();
        builder.AppendLine("오늘 남길 문장");
        builder.AppendLine(closingQuotes[selected]);
        builder.AppendLine(closingCaptions[selected]);
        builder.AppendLine($"선택 이유: {BuildClosingSelectionLine(selected)}");
        builder.AppendLine();
        builder.AppendLine("대상자에게 남길 말");
        builder.AppendLine(GetClosingMessageToInterviewee());
        if (!string.IsNullOrWhiteSpace(selectedClosingSensitiveQuestion))
        {
            builder.AppendLine();
            builder.AppendLine("마지막으로 살핀 질문");
            builder.AppendLine(selectedClosingSensitiveQuestion);
            builder.AppendLine(selectedClosingSensitiveAnswer);
        }
        builder.AppendLine($"다음에 이어볼 질문: {BuildNextSessionPromptLine()}");
        builder.AppendLine();
        builder.AppendLine("오늘의 대화");
        string transcript = BuildPlainConversationLog();
        builder.AppendLine(string.IsNullOrWhiteSpace(transcript) ? "아직 저장할 대화가 없습니다." : transcript);

        return builder.ToString();
    }

    private string GetClosingMessageToInterviewee()
    {
        if (closingMessageInput != null)
        {
            return (closingMessageInput.text ?? string.Empty).Trim();
        }

        return closingMessageToInterviewee ?? string.Empty;
    }

    private string BuildIntervieweeMessageText()
    {
        StringBuilder builder = new StringBuilder();
        builder.AppendLine($"{GameTitle} 전달용 메시지");
        builder.AppendLine($"저장 시각: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
        builder.AppendLine();
        builder.AppendLine("아래 문장은 인터뷰 대상자에게 전달하기 위해 저장한 메시지입니다.");
        builder.AppendLine();
        builder.AppendLine(GetClosingMessageToInterviewee());
        builder.AppendLine();
        builder.AppendLine("함께 남긴 결과 문장");
        int selected = Mathf.Clamp(selectedClosingIndex, 0, closingQuotes.Length - 1);
        builder.AppendLine(closingQuotes[selected]);
        builder.AppendLine(closingCaptions[selected]);
        return builder.ToString();
    }

    private string BuildPlaytestFeedbackText(DateTime savedAt)
    {
        string rating = GetPlaytestRatingLabel(selectedPlaytestRating);
        string commercialReadiness = GetPlaytestCommercialReadinessLabel(selectedPlaytestCommercialReadiness);
        string issueSeverity = GetPlaytestIssueSeverityLabel(selectedPlaytestIssueSeverity);
        string note = playtestFeedbackInput != null ? (playtestFeedbackInput.text ?? string.Empty).Trim() : string.Empty;
        string[] qualityAreas = GetPlaytestQualityAreas(note);
        string[] riskTags = GetPlaytestRiskTags();
        BuildInfoSummary buildInfo = TryReadBuildInfo();

        StringBuilder builder = new StringBuilder();
        builder.AppendLine($"{GameTitle} 의견 메모");
        builder.AppendLine($"저장 시각: {savedAt:yyyy-MM-dd HH:mm:ss}");
        builder.AppendLine($"세션 ID: {playtestSessionId}");
        builder.AppendLine($"빌드 ID: {GetBuildIdForRecord(buildInfo)}");
        builder.AppendLine($"앱 버전: {GetBuildVersionForRecord(buildInfo)}");
        builder.AppendLine($"실행 환경: {Application.platform} / {SystemInfo.operatingSystem}");
        builder.AppendLine($"화면: {Screen.width}x{Screen.height}, 전체화면: {Screen.fullScreen}");
        builder.AppendLine($"설정: 글자 크기 단계 {dialogueSizeLevel}, 움직임 줄임 {reducedMotionEnabled}, 읽기 쉬운 화면 {highContrastEnabled}, 서버 필수 {(!localAnswerOnly)}, 소리 단계 {soundLevel}");
        builder.AppendLine($"평가: {rating}");
        builder.AppendLine($"5달러 기준: {commercialReadiness}");
        builder.AppendLine($"이슈 등급: {issueSeverity}");
        builder.AppendLine($"문답 수: {conversationTurns}");
        builder.AppendLine($"세션 완성도: {BuildSessionCompletionLine()}");
        builder.AppendLine($"다음 질문 방향: {BuildNextSessionPromptLine()}");
        builder.AppendLine($"주된 질문 태도: {GetDominantAttitude()}");
        builder.AppendLine($"{RequiredQuestionCount}문답 완료: {(IsCompletedFiveTurnSession() ? "예" : "아니오")}");
        builder.AppendLine($"마무리 기록 저장: {(HasSavedEndingRecordThisSession() ? "예" : "아니오")}");
        builder.AppendLine($"긍정 근거 마무리 필요: {(ShouldRequireEndingRecordForPositiveEvidence() ? "예" : "아니오")}");
        builder.AppendLine($"긍정 근거 사용 가능: {(IsPositiveQualityEvidenceReady() ? "예" : "아니오")}");
        builder.AppendLine($"선택 초점: {GetPlaytestQualityFocusLabel(selectedPlaytestQualityFocus)} ({GetPlaytestQualityFocusAreaId(selectedPlaytestQualityFocus)})");
        builder.AppendLine($"품질 영역: {FormatPlaytestTags(qualityAreas)}");
        builder.AppendLine($"위험 태그: {FormatPlaytestTags(riskTags)}");
        builder.AppendLine($"증거 등급: {GetPlaytestEvidenceTier()}");
        builder.AppendLine($"추천 조치: {BuildReviewActionRecommendationLine()}");
        builder.AppendLine($"상업 품질 근거: {BuildCommercialQualityEvidenceLine()}");
        builder.AppendLine();
        builder.AppendLine("메모");
        builder.AppendLine(string.IsNullOrWhiteSpace(note) ? "입력된 메모가 없습니다." : note);
        builder.AppendLine();
        builder.AppendLine("대화 로그");
        string transcript = BuildPlainConversationLog();
        builder.AppendLine(string.IsNullOrWhiteSpace(transcript) ? "아직 저장할 대화가 없습니다." : transcript);
        return builder.ToString();
    }

    private string BuildPlaytestFeedbackManifestJson(DateTime savedAt)
    {
        string rating = GetPlaytestRatingLabel(selectedPlaytestRating);
        string commercialReadiness = GetPlaytestCommercialReadinessLabel(selectedPlaytestCommercialReadiness);
        string issueSeverity = GetPlaytestIssueSeverityLabel(selectedPlaytestIssueSeverity);
        string note = GetPlaytestFeedbackNote();
        BuildInfoSummary buildInfo = TryReadBuildInfo();
        PlaytestFeedbackManifest manifest = new PlaytestFeedbackManifest
        {
            schemaVersion = "6",
            sessionId = playtestSessionId,
            savedAt = savedAt.ToString("o"),
            rating = rating,
            commercialReadiness = commercialReadiness,
            issueSeverity = issueSeverity,
            conversationTurns = conversationTurns,
            sessionCompletionLine = BuildSessionCompletionLine(),
            openedMemoryCount = discoveredThemes.Count,
            memoryThemeCount = memoryThemes.Length,
            openedThemes = GetOpenedMemoryThemeNames(),
            openedSceneTags = GetOpenedSceneTags(),
            lastTheme = lastTheme,
            dominantAttitude = GetDominantAttitude(),
            deepMemoryCount = CountDeepMemories(),
            firstImpression = BuildFirstImpressionDisplayLabel(),
            firstImpressionTheme = GetThemeForFirstImpression(),
            firstImpressionThemeOpened = IsFirstImpressionThemeOpened(),
            firstImpressionThemeDeep = IsFirstImpressionThemeDeep(),
            firstImpressionArc = BuildFirstImpressionArcLine(),
            buildId = GetBuildIdForRecord(buildInfo),
            appVersion = GetBuildVersionForRecord(buildInfo),
            productName = buildInfo != null && !string.IsNullOrWhiteSpace(buildInfo.productName) ? buildInfo.productName : Application.productName,
            runtimePlatform = Application.platform.ToString(),
            operatingSystem = SystemInfo.operatingSystem,
            screen = $"{Screen.width}x{Screen.height}",
            fullscreen = Screen.fullScreen,
            dialogueSizeLevel = dialogueSizeLevel,
            reducedMotionEnabled = reducedMotionEnabled,
            highContrastEnabled = highContrastEnabled,
            localAnswerOnly = localAnswerOnly,
            soundLevel = soundLevel,
            completedFiveTurnSession = IsCompletedFiveTurnSession(),
            positiveEvidenceRequiresCompletedSession = IsPositiveEvidenceSelection(),
            positiveEvidenceRequiresEndingRecord = ShouldRequireEndingRecordForPositiveEvidence(),
            endingRecordSavedThisSession = HasSavedEndingRecordThisSession(),
            qualityEvidenceReady = IsPositiveQualityEvidenceReady(),
            qualityFocusArea = GetPlaytestQualityFocusAreaId(selectedPlaytestQualityFocus),
            qualityAreas = GetPlaytestQualityAreas(note),
            riskTags = GetPlaytestRiskTags(),
            evidenceTier = GetPlaytestEvidenceTier(),
            reviewActionRecommendation = BuildReviewActionRecommendationLine(),
            commercialQualityEvidenceLine = BuildCommercialQualityEvidenceLine()
        };

        return JsonUtility.ToJson(manifest, true);
    }

    private string[] GetOpenedSceneTags()
    {
        EnsureMemoryNotes();
        List<string> tags = new List<string>();
        for (int i = 0; i < memoryThemes.Length; i++)
        {
            string theme = memoryThemes[i];
            if (!discoveredThemes.Contains(theme)) continue;

            bool deep = deepMemoryUnlocked != null && i < deepMemoryUnlocked.Length && deepMemoryUnlocked[i];
            tags.Add($"{theme}:{(deep ? "deep" : "shallow")}");
        }

        return tags.ToArray();
    }

    private string[] GetOpenedMemoryThemeNames()
    {
        List<string> opened = new List<string>();
        for (int i = 0; i < memoryThemes.Length; i++)
        {
            if (discoveredThemes.Contains(memoryThemes[i]))
            {
                opened.Add(memoryThemes[i]);
            }
        }

        return opened.ToArray();
    }

    private static string GetPlaytestRatingLabel(int rating)
    {
        if (rating <= 1) return "헷갈림";
        if (rating >= 3) return "좋음";
        return "보통";
    }

    private static string GetPlaytestCommercialReadinessLabel(int readiness)
    {
        if (readiness <= 1) return "부족";
        if (readiness >= 3) return "충분";
        return "보류";
    }

    private static string GetPlaytestIssueSeverityLabel(int severity)
    {
        switch (Mathf.Clamp(severity, 0, 3))
        {
            case 1: return "P2";
            case 2: return "P1";
            case 3: return "P0";
            default: return "없음";
        }
    }

    private static string GetPlaytestIssueSeverityButtonLabel(int severity)
    {
        switch (Mathf.Clamp(severity, 0, 3))
        {
            case 1: return "사소한 문제";
            case 2: return "진행 방해";
            case 3: return "진행 불가";
            default: return "문제 없음";
        }
    }

    private static string GetPlaytestFeedbackGroupLabel(int group)
    {
        switch (Mathf.Clamp(group, 0, 3))
        {
            case 1: return "완성도 느낌";
            case 2: return "문제 단계";
            case 3: return "주요 영역";
            default: return "전체 느낌";
        }
    }

    private static string GetPlaytestQualityFocusAreaId(int focus)
    {
        switch (Mathf.Clamp(focus, 0, 8))
        {
            case 1: return "core_loop";
            case 2: return "writing";
            case 3: return "readability";
            case 4: return "controls";
            case 5: return "trust_privacy";
            case 6: return "art_presentation";
            case 7: return "trailer_store";
            case 8: return "stability_package";
            default: return "auto";
        }
    }

    private static string GetPlaytestQualityFocusLabel(int focus)
    {
        switch (Mathf.Clamp(focus, 0, 8))
        {
            case 1: return "진행";
            case 2: return "문장";
            case 3: return "읽기";
            case 4: return "조작";
            case 5: return "신뢰";
            case 6: return "시각";
            case 7: return "상점";
            case 8: return "안정";
            default: return "전체 느낌";
        }
    }

    private static string GetPlaytestQualityFocusButtonLabel(int focus)
    {
        return $"초점: {GetPlaytestQualityFocusLabel(focus)}";
    }

    private static void AddUniqueTag(List<string> tags, string tag)
    {
        if (string.IsNullOrWhiteSpace(tag) || tags.Contains(tag)) return;
        tags.Add(tag);
    }

    private static bool TextHasAnyKeyword(string text, string[] keywords)
    {
        if (string.IsNullOrWhiteSpace(text)) return false;
        for (int i = 0; i < keywords.Length; i++)
        {
            if (text.IndexOf(keywords[i], StringComparison.OrdinalIgnoreCase) >= 0)
            {
                return true;
            }
        }

        return false;
    }

    private string[] GetPlaytestQualityAreas(string note)
    {
        List<string> areas = new List<string>();
        AddUniqueTag(areas, "core_loop");
        string focusArea = GetPlaytestQualityFocusAreaId(selectedPlaytestQualityFocus);
        if (!string.Equals(focusArea, "auto", StringComparison.Ordinal))
        {
            AddUniqueTag(areas, focusArea);
        }

        if (TextHasAnyKeyword(note, new[] { "말투", "AI", "사람", "설명문", "답변", "대화", "어조", "문장" }))
        {
            AddUniqueTag(areas, "writing");
        }
        if (TextHasAnyKeyword(note, new[] { "긴", "길", "스크롤", "읽", "글자", "잘림", "화면", "대사", "자막", "넘", "뚫" }) || highContrastEnabled || dialogueSizeLevel != 0)
        {
            AddUniqueTag(areas, "readability");
        }
        if (TextHasAnyKeyword(note, new[] { "입력", "버튼", "키보드", "마우스", "설정", "저장", "삭제", "기록", "조작" }))
        {
            AddUniqueTag(areas, "controls");
        }
        if (TextHasAnyKeyword(note, new[] { "API", "키", "마이크", "로컬", "삭제 안내", "개인정보", "신뢰", "서버" }) || localAnswerOnly)
        {
            AddUniqueTag(areas, "trust_privacy");
        }
        if (TextHasAnyKeyword(note, new[] { "캐릭터", "사람", "배경", "보라", "색", "그래픽", "그림", "캡슐", "스크린샷", "밝" }))
        {
            AddUniqueTag(areas, "art_presentation");
        }
        if (TextHasAnyKeyword(note, new[] { "트레일러", "상점", "가격", "5달러", "유료", "구매", "소개" }))
        {
            AddUniqueTag(areas, "trailer_store");
        }
        if (TextHasAnyKeyword(note, new[] { "실행", "오류", "멈춤", "서버", "fallback", "지원", "번들", "패키지", "튕" }) || selectedPlaytestIssueSeverity >= 2)
        {
            AddUniqueTag(areas, "stability_package");
        }

        return areas.ToArray();
    }

    private string[] GetPlaytestRiskTags()
    {
        List<string> tags = new List<string>();
        if (!IsCompletedFiveTurnSession()) AddUniqueTag(tags, "incomplete-session");
        if (!HasSavedEndingRecordThisSession()) AddUniqueTag(tags, "ending-record-missing");
        if (selectedPlaytestRating <= 1) AddUniqueTag(tags, "negative-rating");
        if (selectedPlaytestCommercialReadiness <= 1) AddUniqueTag(tags, "commercial-insufficient");
        else if (selectedPlaytestCommercialReadiness == 2) AddUniqueTag(tags, "commercial-hold");
        if (selectedPlaytestIssueSeverity > 0) AddUniqueTag(tags, $"issue-{GetPlaytestIssueSeverityLabel(selectedPlaytestIssueSeverity).ToLowerInvariant()}");
        if (dialogueSizeLevel != 0 || reducedMotionEnabled || highContrastEnabled) AddUniqueTag(tags, "accessibility-settings-used");
        if (localAnswerOnly) AddUniqueTag(tags, "local-only");
        return tags.ToArray();
    }

    private string GetPlaytestEvidenceTier()
    {
        if (IsPositiveQualityEvidenceReady()) return "positive-complete-session";
        if (ShouldRequireCompletedPlaytestSession()) return "incomplete-positive";
        if (ShouldRequireEndingRecordForPositiveEvidence()) return "ending-record-needed";
        if (ShouldRequirePlaytestFeedbackNote()) return "issue-or-hold";
        return "neutral-note";
    }

    private string BuildReviewActionRecommendationLine()
    {
        if (IsPositiveQualityEvidenceReady())
        {
            return $"긍정 근거: {RequiredQuestionCount}문답과 마무리 기록이 완료되었습니다. 대화 톤, 조작, 마무리 기록을 함께 검토하세요.";
        }
        if (ShouldRequireCompletedPlaytestSession())
        {
            return $"근거 보강: 긍정 의견은 {RequiredQuestionCount}문답 완료 뒤 다시 저장해야 합니다.";
        }
        if (ShouldRequireEndingRecordForPositiveEvidence())
        {
            return "근거 보강: 마무리 기록 저장 뒤 긍정 의견을 다시 남겨야 합니다.";
        }
        if (selectedPlaytestIssueSeverity >= 2)
        {
            return $"우선 수정: {GetPlaytestIssueSeverityLabel(selectedPlaytestIssueSeverity)} 문제를 이슈로 등록하고 재검증하세요.";
        }
        if (selectedPlaytestIssueSeverity == 1)
        {
            return "수정 후보: 사소한 문제를 P2 이슈로 등록하고 다음 빌드에서 확인하세요.";
        }
        if (selectedPlaytestRating <= 1 || selectedPlaytestCommercialReadiness <= 1)
        {
            return "우선 개선: 메모의 품질 영역을 묶고 원인을 재현하세요.";
        }
        if (selectedPlaytestCommercialReadiness == 2)
        {
            return "판단 보강: 메모의 품질 영역을 다음 외부 리뷰에서 다시 확인하세요.";
        }

        return "관찰 메모: 대화 로그와 열린 장면을 다음 확인 때 함께 보세요.";
    }

    private string BuildCommercialQualityEvidenceLine()
    {
        if (IsPositiveQualityEvidenceReady())
        {
            return $"점수표 후보: {RequiredQuestionCount}문답 완료, 마무리 기록 저장, 좋음/충분함/문제 없음이 함께 충족되었습니다.";
        }
        if (ShouldRequireCompletedPlaytestSession())
        {
            return $"점수표 보류: 긍정 판정 전에 {RequiredQuestionCount}문답 완료 증거가 필요합니다.";
        }
        if (ShouldRequireEndingRecordForPositiveEvidence())
        {
            return "점수표 보류: 긍정 판정 전에 마무리 기록 저장 증거가 필요합니다.";
        }
        if (selectedPlaytestIssueSeverity > 0)
        {
            return $"점수표 보류: {GetPlaytestIssueSeverityLabel(selectedPlaytestIssueSeverity)} 이슈를 외부 이슈 레지스터에 등록해야 합니다.";
        }
        if (selectedPlaytestRating <= 1 || selectedPlaytestCommercialReadiness <= 1)
        {
            return "점수표 보류: 낮은 평가나 부족 판정의 원인을 메모와 대화 로그로 재현해야 합니다.";
        }
        if (selectedPlaytestCommercialReadiness == 2)
        {
            return "점수표 보류: 5달러 충분 판정 전 다음 외부 리뷰에서 재확인 필요.";
        }

        return "점수표 참고: 중립 관찰 메모로 품질 영역과 대화 로그를 비교합니다.";
    }

    private static string FormatPlaytestTags(string[] tags)
    {
        return tags != null && tags.Length > 0 ? string.Join(", ", tags) : "none";
    }

    private static string GetBuildIdForRecord(BuildInfoSummary buildInfo)
    {
        return buildInfo != null && !string.IsNullOrWhiteSpace(buildInfo.buildId) ? buildInfo.buildId : "unknown";
    }

    private static string GetBuildVersionForRecord(BuildInfoSummary buildInfo)
    {
        return buildInfo != null && !string.IsNullOrWhiteSpace(buildInfo.version) ? buildInfo.version : Application.version;
    }

    private static BuildInfoSummary TryReadBuildInfo()
    {
        List<string> candidates = GetBuildInfoCandidatePaths();
        for (int i = 0; i < candidates.Count; i++)
        {
            string path = candidates[i];
            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path)) continue;

            try
            {
                string json = File.ReadAllText(path, Encoding.UTF8);
                BuildInfoSummary info = JsonUtility.FromJson<BuildInfoSummary>(json);
                if (info != null && !string.IsNullOrWhiteSpace(info.buildId))
                {
                    return info;
                }
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"Failed to read build info for playtest feedback: {ex.Message}");
            }
        }

        return null;
    }

    private static List<string> GetBuildInfoCandidatePaths()
    {
        List<string> candidates = new List<string>();
        try
        {
            DirectoryInfo dataDirectory = new DirectoryInfo(Application.dataPath);
            DirectoryInfo parent = dataDirectory.Parent;
            if (parent != null)
            {
                AddBuildInfoCandidate(candidates, Path.Combine(parent.FullName, "BUILD_INFO.json"));
                AddBuildInfoCandidate(candidates, Path.Combine(parent.FullName, "Build", "BUILD_INFO.json"));

                DirectoryInfo grandParent = parent.Parent;
                if (grandParent != null)
                {
                    AddBuildInfoCandidate(candidates, Path.Combine(grandParent.FullName, "BUILD_INFO.json"));
                }
            }
        }
        catch (Exception ex)
        {
            Debug.LogWarning($"Failed to resolve build info paths: {ex.Message}");
        }

        return candidates;
    }

    private static void AddBuildInfoCandidate(List<string> candidates, string path)
    {
        if (!string.IsNullOrWhiteSpace(path) && !candidates.Contains(path))
        {
            candidates.Add(path);
        }
    }

    private string BuildPlainConversationLog()
    {
        string log = StripRichTextTags(logBuilder.ToString()).Trim();
        if (!string.IsNullOrWhiteSpace(log)) return log;

        if (history.Count == 0) return string.Empty;

        StringBuilder builder = new StringBuilder();
        foreach (ChatMessage message in history)
        {
            string speaker = message.role == "user" ? "나" : "답변";
            builder.AppendLine(speaker);
            builder.AppendLine((message.content ?? string.Empty).Trim());
            builder.AppendLine();
        }

        return builder.ToString().Trim();
    }

    private static string StripRichTextTags(string value)
    {
        if (string.IsNullOrEmpty(value)) return string.Empty;

        StringBuilder builder = new StringBuilder(value.Length);
        bool insideTag = false;
        for (int i = 0; i < value.Length; i++)
        {
            char ch = value[i];
            if (ch == '<')
            {
                insideTag = true;
                continue;
            }

            if (ch == '>' && insideTag)
            {
                insideTag = false;
                continue;
            }

            if (!insideTag)
            {
                builder.Append(ch);
            }
        }

        return builder.ToString();
    }

    private void UpdateClosingSummary()
    {
        if (closingCardSummaryText == null) return;

        StringBuilder builder = new StringBuilder();
        string sceneTags = BuildOpenedSceneTags(3);
        builder.AppendLine("오늘의 대화");
        builder.AppendLine("질문 5개를 마쳤습니다.");
        builder.AppendLine();
        builder.AppendLine("질문으로 본 생활");
        builder.AppendLine(string.IsNullOrWhiteSpace(sceneTags) ? "전체 대화 기록" : sceneTags);
        if (!string.IsNullOrWhiteSpace(selectedClosingSensitiveQuestion))
        {
            builder.AppendLine();
            builder.AppendLine("마지막 질문");
            builder.AppendLine(ShortenForCard(selectedClosingSensitiveQuestion, 58));
        }
        builder.AppendLine();
        builder.Append("남길 말을 적고 끝내 주세요.");

        closingCardSummaryText.text = builder.ToString();
        RefreshClosingChoiceLabels();
    }

    private string BuildClosingQuestionAnswerLine(int maxLength)
    {
        string lastQuestion = string.Empty;
        string lastAnswer = string.Empty;
        for (int i = history.Count - 1; i >= 0; i--)
        {
            ChatMessage message = history[i];
            if (message == null) continue;
            if (string.IsNullOrWhiteSpace(lastAnswer) && string.Equals(message.role, "assistant", StringComparison.Ordinal))
            {
                lastAnswer = CleanAssistantReplyText(message.content);
                continue;
            }
            if (string.IsNullOrWhiteSpace(lastQuestion) && string.Equals(message.role, "user", StringComparison.Ordinal))
            {
                lastQuestion = CleanAssistantReplyText(message.content);
            }
            if (!string.IsNullOrWhiteSpace(lastQuestion) && !string.IsNullOrWhiteSpace(lastAnswer)) break;
        }

        if (string.IsNullOrWhiteSpace(lastQuestion) && string.IsNullOrWhiteSpace(lastAnswer))
        {
            return "아직 요약할 질답이 없습니다.";
        }

        if (string.IsNullOrWhiteSpace(lastAnswer))
        {
            return $"Q. {ShortenForCard(lastQuestion, maxLength)}";
        }

        string line = $"Q. {ShortenForCard(lastQuestion, 34)} -> A. {ShortenForCard(lastAnswer, maxLength)}";
        return ShortenForCard(line, maxLength + 44);
    }

    private string BuildClosingResultInsightLine()
    {
        string sceneTags = BuildOpenedSceneTags(2);
        string attitude = GetDominantAttitude();
        if (!string.IsNullOrWhiteSpace(sceneTags))
        {
            return $"이번 경로는 {sceneTags} 쪽으로 시선을 옮겼고, {attitude}의 질문 흐름으로 정리됩니다.";
        }

        return $"이번 경로는 {BuildFirstImpressionDisplayLabel()}에서 시작했고, {attitude}의 질문 흐름으로 마무리됩니다.";
    }

    private string BuildSessionCompletionLine()
    {
        return IsCompletedFiveTurnSession()
            ? $"{RequiredQuestionCount}문답 완료"
            : $"{Mathf.Clamp(conversationTurns, 0, RequiredQuestionCount)}/{RequiredQuestionCount} 문답";
    }

    private string BuildNextSessionPromptLine()
    {
        return "전체 질문 풀에서 5개를 더 이어가 보세요.";
    }

    private string GetFirstShallowOpenedTheme()
    {
        if (memoryThemes == null || discoveredThemes == null) return string.Empty;

        for (int i = 0; i < memoryThemes.Length; i++)
        {
            string theme = memoryThemes[i];
            if (!discoveredThemes.Contains(theme)) continue;

            bool deep = deepMemoryUnlocked != null && i < deepMemoryUnlocked.Length && deepMemoryUnlocked[i];
            if (!deep) return theme;
        }

        return string.Empty;
    }

    private string GetFirstUnopenedTheme()
    {
        if (memoryThemes == null || discoveredThemes == null) return string.Empty;

        for (int i = 0; i < memoryThemes.Length; i++)
        {
            string theme = memoryThemes[i];
            if (!discoveredThemes.Contains(theme)) return theme;
        }

        return string.Empty;
    }

    private void RefreshClosingChoiceLabels()
    {
        if (closingCardChoiceButtons == null || closingChoiceLabels == null) return;

        int recommended = GetRecommendedClosingIndex();
        for (int i = 0; i < closingCardChoiceButtons.Length && i < closingChoiceLabels.Length; i++)
        {
            Text label = FindChildText(closingCardChoiceButtons[i].transform, "Label");
            if (label != null)
            {
                label.text = i == recommended ? $"추천 · {closingChoiceLabels[i]}" : closingChoiceLabels[i];
            }
        }
    }

    private string BuildOpenedSceneTags(int maxCount)
    {
        EnsureMemoryNotes();
        if (memoryThemes == null || discoveredThemes == null) return string.Empty;

        List<string> tags = new List<string>();
        for (int i = 0; i < memoryThemes.Length; i++)
        {
            string theme = memoryThemes[i];
            if (!discoveredThemes.Contains(theme)) continue;

            bool deep = deepMemoryUnlocked != null && i < deepMemoryUnlocked.Length && deepMemoryUnlocked[i];
            tags.Add($"{theme} {(deep ? "깊음" : "얕음")}");
            if (tags.Count >= maxCount) break;
        }

        if (tags.Count == 0) return string.Empty;

        int openedCount = GetOpenedMemoryLines().Count;
        string joined = string.Join(", ", tags);
        if (openedCount > tags.Count)
        {
            joined += $" 외 {openedCount - tags.Count}";
        }

        return joined;
    }

    private List<string> GetOpenedMemoryLines()
    {
        EnsureMemoryNotes();
        List<string> opened = new List<string>();
        for (int i = 0; i < memoryThemes.Length; i++)
        {
            if (discoveredThemes.Contains(memoryThemes[i]))
            {
                string note = memoryNotes != null && i < memoryNotes.Length ? memoryNotes[i] : string.Empty;
                bool deep = deepMemoryUnlocked != null && i < deepMemoryUnlocked.Length && deepMemoryUnlocked[i];
                string line = $"{memoryThemes[i]} [{(deep ? "깊은 기록" : "얕은 기록")}]: {memoryCaptions[i]}";
                if (!string.IsNullOrWhiteSpace(note))
                {
                    line += $" ({note})";
                }
                opened.Add(line);
            }
        }
        return opened;
    }

    private string BuildFirstImpressionLabel()
    {
        return string.IsNullOrWhiteSpace(firstImpression) ? "아직 고르지 않음" : firstImpression;
    }

    private string BuildFirstImpressionDisplayLabel()
    {
        return HasFirstImpressionChoice() ? firstImpression : "전체 대화 시작";
    }

    private bool HasFirstImpressionChoice()
    {
        return !string.IsNullOrWhiteSpace(firstImpression);
    }

    private string GetDominantAttitude()
    {
        EnsureAttitudeCounts();
        int bestIndex = -1;
        int bestCount = 0;
        for (int i = 0; i < attitudeCounts.Length && i < attitudeNames.Length; i++)
        {
            if (attitudeCounts[i] > bestCount)
            {
                bestIndex = i;
                bestCount = attitudeCounts[i];
            }
        }

        return bestIndex >= 0 ? $"{attitudeNames[bestIndex]} {bestCount}회" : "아직 없음";
    }

    private string BuildPerspectiveShiftLine()
    {
        string deepLine = CountDeepMemories() > 0 ? "깊은 기록까지 열면서" : "얕은 기록을 열면서";
        if (!HasFirstImpressionChoice())
        {
            return $"처음에는 열린 장면을 따라갔고, 지금은 {deepLine} 보이지 않던 생활의 맥락까지 남겼습니다.";
        }

        string impression = BuildFirstImpressionLabel();
        string subject = string.Equals(impression, "이야기 보기", StringComparison.Ordinal) ? "이야기 보기 모드로" : $"{impression}이";
        return $"처음에는 {subject} 먼저 보였고, 지금은 {deepLine} 그 뒤의 생활까지 남겼습니다.{BuildFirstImpressionResonanceLine()}";
    }

    private string BuildFirstImpressionResonanceLine()
    {
        string theme = GetThemeForFirstImpression();
        if (string.IsNullOrWhiteSpace(theme)) return string.Empty;

        bool opened = discoveredThemes != null && discoveredThemes.Contains(theme);
        int index = Array.IndexOf(memoryThemes, theme);
        bool deep = opened && deepMemoryUnlocked != null && index >= 0 && index < deepMemoryUnlocked.Length && deepMemoryUnlocked[index];

        if (deep)
        {
            return $" 처음 본 {firstImpression}은 {theme} 깊은 기록까지 이어졌습니다.";
        }
        if (opened)
        {
            return $" 처음 본 {firstImpression}은 {theme} 장면으로 이어졌습니다.";
        }

        return $" 처음 본 {firstImpression}은 아직 {theme} 장면까지 닿지 않았습니다.";
    }

    private int GetRecommendedClosingIndex()
    {
        string dominant = GetDominantAttitude();
        if (dominant.StartsWith("배려", StringComparison.Ordinal))
        {
            return 0;
        }

        if (discoveredThemes != null && (discoveredThemes.Contains("이동") || string.Equals(firstImpression, "목발", StringComparison.Ordinal)))
        {
            return 1;
        }

        if (CountDeepMemories() > 0 || !string.IsNullOrWhiteSpace(GetThemeForFirstImpression()))
        {
            return 2;
        }

        return Mathf.Clamp(selectedClosingIndex, 0, closingQuotes.Length - 1);
    }

    private string BuildClosingSelectionLine(int index)
    {
        int selected = Mathf.Clamp(index, 0, closingChoiceLabels.Length - 1);
        string label = closingChoiceLabels[selected];
        bool hasImpression = HasFirstImpressionChoice();
        string impression = BuildFirstImpressionLabel();
        string attitude = GetDominantAttitude();
        int deepCount = CountDeepMemories();

        if (selected == 0)
        {
            if (string.Equals(attitude, "아직 없음", StringComparison.Ordinal))
            {
                return $"{label}은 아직 질문이 적은 상태에서, 먼저 묻는 태도를 남깁니다.";
            }

            return $"{label}은 {attitude}의 질문 흐름을 먼저 묻는 태도로 정리합니다.";
        }
        if (selected == 1)
        {
            if (!hasImpression)
            {
                return $"{label}은 오늘 열린 장면을 하루의 동선으로 묶습니다.";
            }

            return $"{label}은 처음 본 {impression}과 열린 장면을 하루의 동선으로 묶습니다.";
        }

        if (!hasImpression)
        {
            return $"{label}은 깊은 기록 {deepCount}개를 한 사람의 생활로 묶습니다.";
        }

        return $"{label}은 처음 본 {impression} 뒤에 열린 깊은 기록 {deepCount}개를 한 사람의 생활로 묶습니다.";
    }

    private void CreateMemoryBookOverlay(Transform parent)
    {
        Image overlay = CreatePanel("Memory Book Overlay", parent, new Color(0.96f, 0.92f, 0.80f, 0.12f));
        memoryBookObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image shadow = CreateRoundedPanel("Memory Book Shadow", memoryBookObject.transform, new Color(0.030f, 0.022f, 0.014f, 0.14f), 12);
        Stretch(shadow.rectTransform, new Vector2(1f, 0.5f), new Vector2(1f, 0.5f), new Vector2(-590f, -264f), new Vector2(-58f, 272f));

        Image page = CreatePaperPanel("Memory Book Page", memoryBookObject.transform, new Color(0.985f, 0.965f, 0.900f, 0.985f), 12, 10);
        Stretch(page.rectTransform, new Vector2(1f, 0.5f), new Vector2(1f, 0.5f), new Vector2(-580f, -254f), new Vector2(-70f, 258f));
        page.rectTransform.localRotation = Quaternion.Euler(0f, 0f, 0.55f);

        Image spine = CreateRoundedPanel("Memory Book Spine", page.transform, new Color(0.57f, 0.33f, 0.16f, 0.24f), 6);
        spine.raycastTarget = false;
        Stretch(spine.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(24f, 28f), new Vector2(30f, -28f));

        for (int i = 0; i < 5; i++)
        {
            Image ring = CreatePanel($"Memory Book Binding Ring {i + 1}", page.transform, new Color(0.045f, 0.052f, 0.064f, 0.070f));
            ring.sprite = GetCircleSprite();
            ring.raycastTarget = false;
            Stretch(ring.rectTransform, new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(17f, -92f - i * 72f), new Vector2(39f, -70f - i * 72f));
        }

        for (int i = 0; i < 5; i++)
        {
            Image pageRule = CreatePanel($"Memory Book Page Rule {i + 1}", page.transform, new Color(0.50f, 0.42f, 0.28f, 0.032f));
            pageRule.raycastTarget = false;
            Stretch(pageRule.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(52f, -116f - i * 70f), new Vector2(-34f, -115f - i * 70f));
        }

        Image topRail = CreateRoundedPanel("Memory Book Brass Rail", page.transform, new Color(0.70f, 0.44f, 0.23f, 0.18f), 3);
        topRail.raycastTarget = false;
        Stretch(topRail.rectTransform, new Vector2(0f, 1f), Vector2.one, new Vector2(52f, -64f), new Vector2(-36f, -62f));

        Text title = CreateText("Memory Book Title", page.transform, "대화 메모", 22, new Color32(30, 41, 59, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(title.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(50f, -50f), new Vector2(-36f, -18f));

        memoryBookCountText = CreateText("Memory Book Count", page.transform, "0/6 장면", 13, new Color32(71, 85, 105, 238), TextAnchor.UpperRight, FontStyle.Bold);
        Stretch(memoryBookCountText.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(50f, -50f), new Vector2(-38f, -18f));

        memoryBookSubtitleText = CreateText("Memory Book Subtitle", page.transform, "책상 위에 남은 장면들", 13, new Color32(71, 85, 105, 232), TextAnchor.UpperLeft, FontStyle.Normal);
        Stretch(memoryBookSubtitleText.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(50f, -82f), new Vector2(-38f, -58f));

        memoryCardImages = new Image[memoryThemes.Length];
        memoryCardIllustrationImages = new Image[memoryThemes.Length];
        memoryCardButtons = new Button[memoryThemes.Length];
        memoryCardTexts = new Text[memoryThemes.Length];
        for (int i = 0; i < memoryThemes.Length; i++)
        {
            int capturedIndex = i;
            int column = i % 2;
            int row = i / 2;
            float left = 62f + column * 206f;
            float top = -112f - row * 96f;

            Image card = CreateMemorySceneCard(page.transform, memoryThemes[i], i);
            Stretch(card.rectTransform, new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(left, top - 76f), new Vector2(left + 176f, top));
            memoryCardImages[i] = card;
            Image illustration = CreateIllustrationImage(
                $"Memory Card Illustration {memoryThemes[i]}",
                card.transform,
                GetIllustrationResourceForTheme(memoryThemes[i]),
                new Color(1f, 1f, 1f, 0.26f));
            if (illustration != null)
            {
                illustration.transform.SetAsFirstSibling();
                Stretch(illustration.rectTransform, Vector2.zero, Vector2.one, new Vector2(58f, 9f), new Vector2(-8f, -9f));
                memoryCardIllustrationImages[i] = illustration;
            }
            Button cardButton = card.GetComponent<Button>();
            if (cardButton != null)
            {
                memoryCardButtons[i] = cardButton;
                cardButton.onClick.AddListener(() => SubmitMemoryCardQuestion(capturedIndex));
            }

            Text cardText = CreateText($"Memory Card Text {memoryThemes[i]}", card.transform, "", 12, new Color32(71, 85, 105, 244), TextAnchor.UpperLeft, FontStyle.Normal);
            cardText.lineSpacing = 1.03f;
            cardText.verticalOverflow = VerticalWrapMode.Truncate;
            Stretch(cardText.rectTransform, Vector2.zero, Vector2.one, new Vector2(32f, 13f), new Vector2(-12f, -10f));
            memoryCardTexts[i] = cardText;
        }

        memoryCompletionBadgeImage = CreateRoundedPanel("Memory Completion Badge", page.transform, new Color(0.57f, 0.33f, 0.16f, 0.52f), 8);
        Stretch(memoryCompletionBadgeImage.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(62f, 30f), new Vector2(316f, 64f));
        Image badgeMark = CreateRoundedPanel("Memory Completion Badge Mark", memoryCompletionBadgeImage.transform, new Color(1f, 0.93f, 0.68f, 0.42f), 4);
        badgeMark.raycastTarget = false;
        Stretch(badgeMark.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(13f, 9f), new Vector2(18f, -9f));

        memoryCompletionBadgeText = CreateText("Memory Completion Badge Text", memoryCompletionBadgeImage.transform, "", 12, new Color(1f, 0.96f, 0.86f, 0.96f), TextAnchor.MiddleCenter, FontStyle.Bold);
        Stretch(memoryCompletionBadgeText.rectTransform, Vector2.zero, Vector2.one, new Vector2(24f, 0f), new Vector2(-10f, 0f));

        Button closeButton = CreateNoteActionButton("Memory Book Close", page.transform, "닫기", false);
        Stretch(closeButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-126f, 30f), new Vector2(-42f, 64f));
        SetButtonColor(closeButton, new Color(0.50f, 0.30f, 0.17f, 0.78f), new Color(1f, 0.96f, 0.86f, 0.98f));
        closeButton.onClick.AddListener(() => SetMemoryBookOpen(false));

        UpdateMemoryBook();
        memoryBookObject.SetActive(false);
    }

    private Image CreateMemorySceneCard(Transform parent, string theme, int index)
    {
        Image card = CreatePaperPanel($"Memory Card {theme}", parent, new Color(1f, 0.99f, 0.95f, 0.94f), 6, 20 + index);
        card.raycastTarget = true;
        Button button = card.gameObject.AddComponent<Button>();
        button.targetGraphic = card;
        ColorBlock colors = button.colors;
        colors.normalColor = card.color;
        colors.highlightedColor = new Color(1f, 0.95f, 0.82f, 0.98f);
        colors.pressedColor = new Color(0.90f, 0.78f, 0.54f, 0.98f);
        colors.disabledColor = new Color(0.78f, 0.74f, 0.68f, 0.52f);
        button.colors = colors;

        Transform root = card.transform;
        Image tape = CreateRoundedPanel("Memory Card Tape", root, new Color(0.90f, 0.80f, 0.58f, 0.16f), 4);
        tape.raycastTarget = false;
        Stretch(tape.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(-26f, -7f), new Vector2(26f, -4f));
        tape.rectTransform.localRotation = Quaternion.Euler(0f, 0f, index % 2 == 0 ? -2.0f : 1.6f);

        Image tab = CreateRoundedPanel("Memory Card Index Tab", root, new Color(0.70f, 0.44f, 0.23f, 0.34f), 3);
        tab.raycastTarget = false;
        Stretch(tab.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(10f, 13f), new Vector2(23f, -13f));

        Text number = CreateText("Memory Card Number", root, (index + 1).ToString(CultureInfo.InvariantCulture), 9, new Color(1f, 0.96f, 0.86f, 0.82f), TextAnchor.UpperCenter, FontStyle.Bold);
        number.raycastTarget = false;
        Stretch(number.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(10f, 15f), new Vector2(23f, -15f));

        Image pin = CreatePanel("Memory Card Pin", root, new Color(0.42f, 0.30f, 0.16f, 0.08f));
        pin.sprite = GetCircleSprite();
        pin.raycastTarget = false;
        Stretch(pin.rectTransform, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-22f, -21f), new Vector2(-13f, -12f));

        for (int i = 0; i < 2; i++)
        {
            Image rule = CreatePanel($"Memory Card Rule {i + 1}", root, new Color(0.44f, 0.34f, 0.20f, 0.034f));
            rule.raycastTarget = false;
            Stretch(rule.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(30f, -31f - i * 20f), new Vector2(-12f, -30f - i * 20f));
        }

        return card;
    }

    private void SetMemoryBookOpen(bool open)
    {
        if (memoryBookObject != null) memoryBookObject.SetActive(open);
        if (open)
        {
            selectedMemoryCardIndex = Mathf.Clamp(selectedMemoryCardIndex, 0, Mathf.Max(0, memoryThemes.Length - 1));
            UpdateMemoryBook();
            if (closingCardObject != null) closingCardObject.SetActive(false);
            PlayPageSound();
            statusText.text = "대화 메모를 열었습니다";
            SelectFirstInteractable(memoryBookObject, "Memory Card", "Memory Book Close");
        }
        else
        {
            ClearSelectionIfInside(memoryBookObject);
        }

        ShowHotspotLabels();
    }

    private void SubmitMemoryCardQuestion(int index)
    {
        SubmitMemoryCardQuestion(index, "submit-click");
    }

    private void SubmitMemoryCardQuestion(int index, string action)
    {
        if (index < 0 || index >= memoryThemes.Length || busy)
        {
            lastMemoryCardAction = "blocked";
            lastMemoryBookShortcutAction = "blocked";
            return;
        }

        string theme = memoryThemes[index];
        string question = index < themeLeadQuestions.Length ? themeLeadQuestions[index] : GetLeadQuestion(index);
        selectedMemoryCardIndex = index;
        lastMemoryCardAction = theme;
        lastMemoryBookShortcutAction = string.IsNullOrWhiteSpace(action) ? "submit" : action;
        SetMemoryBookOpen(false);
        SubmitPresetQuestion(question);
        if (statusText != null)
        {
            statusText.text = $"{theme} 장면으로 이어갑니다";
        }
    }

    private void CollectTheme(string rawTheme, string question, string reply, string attitude = "")
    {
        string theme = CanonicalTheme(rawTheme);
        if (string.IsNullOrWhiteSpace(theme)) return;

        bool deepUnlocked = StoreMemoryNote(theme, question, reply, attitude);
        bool deep = IsDeepMemoryUnlocked(theme);
        lastChoiceConsequenceLine = BuildChoiceConsequenceLine(theme, attitude, deep, deepUnlocked);

        discoveredThemes.Add(theme);
        if (memoryUnlockToastObject != null) memoryUnlockToastObject.SetActive(false);

        UpdateMemoryBook();
        UpdateClosingSummary();
    }

    private void ShowMemoryUnlockToast(string theme)
    {
        string line = BuildMemoryRewardLine(theme, false);
        lastRewardLine = line;
        if (memoryUnlockToastText != null) memoryUnlockToastText.text = line;
        if (memoryUnlockToastObject != null) memoryUnlockToastObject.SetActive(true);
        if (memoryUnlockToastGroup != null) memoryUnlockToastGroup.alpha = 0f;
        if (memoryUnlockToastRect != null) memoryUnlockToastRect.localScale = Vector3.one;
        memoryUnlockToastDuration = 3.1f;
        memoryUnlockToastUntil = Time.unscaledTime + memoryUnlockToastDuration;
        memoryUnlockPulseUntil = Time.unscaledTime + 1.0f;
        PlaySound(memoryUnlockClip);
        if (statusText != null)
        {
            statusText.text = line;
        }
    }

    private void ShowMemoryCompletionToast()
    {
        memoryCompletionCelebrated = true;
        string line = BuildMemoryRewardLine(string.Empty, true);
        lastRewardLine = line;
        if (memoryUnlockToastText != null) memoryUnlockToastText.text = line;
        if (memoryUnlockToastObject != null) memoryUnlockToastObject.SetActive(true);
        if (memoryUnlockToastGroup != null) memoryUnlockToastGroup.alpha = 0f;
        if (memoryUnlockToastRect != null) memoryUnlockToastRect.localScale = Vector3.one;
        memoryUnlockToastDuration = 3.6f;
        memoryUnlockToastUntil = Time.unscaledTime + memoryUnlockToastDuration;
        memoryUnlockPulseUntil = Time.unscaledTime + 1.4f;
        PlaySound(confirmClip);
        if (statusText != null)
        {
            statusText.text = line;
        }
    }

    private string BuildMemoryRewardLine(string theme, bool completion)
    {
        if (completion)
        {
            return "여섯 장면 완성 · 기록함에서 오늘의 겉!=속 경로를 다시 볼 수 있습니다.";
        }

        string safeTheme = string.IsNullOrWhiteSpace(theme) ? "장면" : CanonicalTheme(theme);
        return IsDeepMemoryUnlocked(safeTheme)
            ? $"깊은 기록 열림: {safeTheme}의 속 생활까지 확인했습니다."
            : $"{safeTheme} 장면 열림 · 어떻게/왜/무엇이 편한지 물으면 깊어집니다.";
    }

    private bool StoreMemoryNote(string theme, string question, string reply, string attitude)
    {
        EnsureMemoryNotes();
        int index = Array.IndexOf(memoryThemes, theme);
        if (index < 0 || index >= memoryNotes.Length) return false;

        bool deep = ShouldUnlockDeepMemory(theme, question, attitude);
        string note = BuildMemoryNote(question, reply, attitude, deep);
        if (!string.IsNullOrWhiteSpace(note))
        {
            memoryNotes[index] = note;
        }

        bool newlyDeep = deep && !deepMemoryUnlocked[index];
        if (deep)
        {
            deepMemoryUnlocked[index] = true;
        }

        return newlyDeep;
    }

    private bool IsDeepMemoryUnlocked(string theme)
    {
        int index = Array.IndexOf(memoryThemes, theme);
        return index >= 0 && deepMemoryUnlocked != null && index < deepMemoryUnlocked.Length && deepMemoryUnlocked[index];
    }

    private string BuildChoiceConsequenceLine(string theme, string attitude, bool deep, bool newlyDeep)
    {
        string safeTheme = string.IsNullOrWhiteSpace(theme) ? "장면" : theme;
        string safeAttitude = string.IsNullOrWhiteSpace(attitude) ? "태도 없음" : attitude;
        string depth = deep ? "깊은 기록" : "얕은 기록";

        if (newlyDeep)
        {
            return $"질문 결과: {safeAttitude} 질문 -> {safeTheme} 깊은 기록 · 단서와 속 생활이 맞물렸습니다.";
        }
        if (deep)
        {
            return $"질문 결과: {safeAttitude} 질문 -> {safeTheme} 깊은 기록 유지 · 이미 열린 속 이야기를 다시 확인했습니다.";
        }

        return $"질문 결과: {safeAttitude} 질문 -> {safeTheme} 얕은 기록 · 어떻게/왜/무엇이 편한지 물으면 깊어집니다.";
    }

    private bool ShouldUnlockDeepMemory(string theme, string question, string attitude)
    {
        if (string.IsNullOrWhiteSpace(theme) || string.IsNullOrWhiteSpace(question)) return false;
        if (!string.Equals(attitude, "배려", StringComparison.Ordinal) && !string.Equals(attitude, "호기심", StringComparison.Ordinal)) return false;
        if (IsFirstImpressionTheme(theme) && HasAny(question, firstImpression, "먼저", "이어", "생활", "의미", "하루"))
        {
            return true;
        }

        switch (theme)
        {
            case "일상": return HasAny(question, "평범", "하루", "목발보다", "사람");
            case "이동": return HasAny(question, "처음", "공간", "동선", "엘리베이터", "화장실");
            case "도움": return HasAny(question, "어떻게 도와", "편할까요", "방식", "먼저 물");
            case "일과 공부": return HasAny(question, "책상", "노트북", "직장", "박사", "공부");
            case "독립": return HasAny(question, "자취", "독립", "집", "자기이해");
            case "취미": return HasAny(question, "취미", "게임", "노래방", "쉬는");
            default: return false;
        }
    }

    private static string BuildMemoryNote(string question, string reply, string attitude = "", bool deep = false)
    {
        string source = string.IsNullOrWhiteSpace(question) ? reply : question;
        source = (source ?? string.Empty).Replace("\r", " ").Replace("\n", " ").Trim();
        while (source.Contains("  "))
        {
            source = source.Replace("  ", " ");
        }

        if (string.IsNullOrWhiteSpace(source)) return string.Empty;
        string depth = deep ? "깊은 기록" : "얕은 기록";
        string tag = string.IsNullOrWhiteSpace(attitude) ? string.Empty : $" · {attitude}";
        return $"{depth}{tag}: {ShortenForCard(source, 24)}";
    }

    private static string ShortenForCard(string value, int maxLength)
    {
        string text = value ?? string.Empty;
        if (text.Length <= maxLength) return text;
        return text.Substring(0, Mathf.Max(0, maxLength - 3)).TrimEnd() + "...";
    }

    private string CanonicalTheme(string rawTheme)
    {
        string value = rawTheme ?? string.Empty;
        if (HasAny(value, "취미", "게임", "노래방")) return "취미";
        if (HasAny(value, "자취", "독립", "자기이해")) return "독립";
        if (HasAny(value, "일과", "공부", "직장", "책상", "노트북", "박사")) return "일과 공부";
        if (HasAny(value, "도움", "배려", "조율")) return "도움";
        if (HasAny(value, "이동", "접근성", "처음", "동선", "길", "교통")) return "이동";
        if (HasAny(value, "일상", "평범", "사람", "이야기")) return "일상";
        return string.Empty;
    }

    private void UpdateMemoryBook()
    {
        EnsureMemoryNotes();
        int count = discoveredThemes.Count;
        int deepCount = CountDeepMemories();
        bool complete = count >= memoryThemes.Length;
        if (memoryBookCountText != null) memoryBookCountText.text = $"{count}/6 장면 · 깊은 기록 {deepCount}";

        if (memoryBookButton != null)
        {
            Text buttonLabel = memoryBookButton.GetComponentInChildren<Text>();
            if (buttonLabel != null) buttonLabel.text = "";
        }

        if (memoryBookSubtitleText != null)
        {
            memoryBookSubtitleText.text = BuildMemoryBookSubtitle(complete);
        }

        if (memoryCompletionBadgeImage != null)
        {
            memoryCompletionBadgeImage.color = complete
                ? new Color(0.57f, 0.33f, 0.16f, 0.68f)
                : new Color(1f, 0.99f, 0.95f, 0.82f);
        }

        if (memoryCompletionBadgeText != null)
        {
            memoryCompletionBadgeText.text = complete
                ? "모든 장면 완성"
                : $"남은 장면 {Mathf.Max(0, memoryThemes.Length - count)}개";
            memoryCompletionBadgeText.color = complete ? new Color(1f, 0.96f, 0.86f, 0.98f) : (Color)new Color32(71, 85, 105, 232);
        }

        UpdateQuestionPhoneProgress();
        UpdateNoteTabContent();

        if (memoryCardImages == null || memoryCardTexts == null) return;
        for (int i = 0; i < memoryThemes.Length; i++)
        {
            bool unlocked = discoveredThemes.Contains(memoryThemes[i]);
            if (memoryCardImages[i] != null)
            {
                bool selected = i == selectedMemoryCardIndex;
                Color cardColor = unlocked
                    ? (selected ? new Color(0.78f, 0.93f, 0.82f, 1.00f) : new Color(0.88f, 0.96f, 0.90f, 1.00f))
                    : (selected ? new Color(1.00f, 0.94f, 0.80f, 0.98f) : new Color(1f, 0.99f, 0.95f, 0.86f));
                memoryCardImages[i].color = cardColor;
                UpdateMemoryCardButton(i, cardColor, selected);
            }

            if (memoryCardIllustrationImages != null && i < memoryCardIllustrationImages.Length && memoryCardIllustrationImages[i] != null)
            {
                memoryCardIllustrationImages[i].color = unlocked
                    ? new Color(1f, 1f, 1f, 0.46f)
                    : new Color(1f, 1f, 1f, 0.22f);
            }

            if (memoryCardTexts[i] != null)
            {
                memoryCardTexts[i].color = unlocked ? new Color32(30, 41, 59, 255) : new Color32(100, 116, 139, 232);
                string note = memoryNotes != null && i < memoryNotes.Length ? memoryNotes[i] : string.Empty;
                bool deep = deepMemoryUnlocked != null && i < deepMemoryUnlocked.Length && deepMemoryUnlocked[i];
                memoryCardTexts[i].text = unlocked
                    ? BuildMemoryCardText(memoryThemes[i], memoryCaptions[i], note, deep)
                    : $"<b>{SanitizeRichText(memoryThemes[i])}</b>\n아직 듣지 못한 장면";
            }
        }
    }

    private void UpdateMemoryCardButton(int index, Color cardColor, bool selected)
    {
        if (memoryCardButtons == null || index < 0 || index >= memoryCardButtons.Length) return;
        Button button = memoryCardButtons[index];
        if (button == null) return;

        button.interactable = !busy;
        ColorBlock colors = button.colors;
        colors.normalColor = cardColor;
        colors.highlightedColor = Color.Lerp(cardColor, new Color(1f, 0.86f, 0.48f, cardColor.a), selected ? 0.48f : 0.34f);
        colors.pressedColor = Color.Lerp(cardColor, new Color(0.55f, 0.34f, 0.16f, cardColor.a), selected ? 0.36f : 0.28f);
        colors.disabledColor = new Color(cardColor.r, cardColor.g, cardColor.b, Mathf.Clamp01(cardColor.a * 0.62f));
        button.colors = colors;
    }

    private int CountDeepMemories()
    {
        EnsureMemoryNotes();
        int count = 0;
        for (int i = 0; i < deepMemoryUnlocked.Length; i++)
        {
            if (deepMemoryUnlocked[i]) count++;
        }
        return count;
    }

    private string BuildMemoryBookSubtitle(bool complete)
    {
        string target = BuildFirstImpressionTargetLine();
        if (!string.IsNullOrWhiteSpace(target))
        {
            return complete
                ? $"여섯 장면 완성 · {target}"
                : target;
        }

        return complete
            ? "여섯 장면 완성 · 더 깊이 물어볼 수 있습니다."
            : "질문을 이어 가며 기록을 더 열어 봅니다.";
    }

    private string BuildFirstImpressionTargetLine()
    {
        string theme = GetThemeForFirstImpression();
        if (string.IsNullOrWhiteSpace(theme)) return string.Empty;

        if (IsFirstImpressionThemeDeep())
        {
            return $"첫 인상 {firstImpression}이 {theme} 깊은 기록까지 이어졌습니다.";
        }
        if (IsFirstImpressionThemeOpened())
        {
            return $"첫 인상 {firstImpression}에서 {theme} 깊은 기록을 더 물어보세요.";
        }

        return $"첫 인상 {firstImpression}에서 {theme} 장면으로 이어가 보세요.";
    }

    private string GetThemeForFirstImpression()
    {
        switch (firstImpression)
        {
            case "목발": return "이동";
            case "책상": return "일과 공부";
            case "표정": return "일상";
            default: return string.Empty;
        }
    }

    private bool IsFirstImpressionTheme(string theme)
    {
        string impressionTheme = GetThemeForFirstImpression();
        return !string.IsNullOrWhiteSpace(impressionTheme) && string.Equals(theme, impressionTheme, StringComparison.Ordinal);
    }

    private bool IsFirstImpressionThemeOpened()
    {
        string theme = GetThemeForFirstImpression();
        return !string.IsNullOrWhiteSpace(theme) && discoveredThemes != null && discoveredThemes.Contains(theme);
    }

    private bool IsFirstImpressionThemeDeep()
    {
        string theme = GetThemeForFirstImpression();
        int index = Array.IndexOf(memoryThemes, theme);
        return IsFirstImpressionThemeOpened()
            && deepMemoryUnlocked != null
            && index >= 0
            && index < deepMemoryUnlocked.Length
            && deepMemoryUnlocked[index];
    }

    private string BuildFirstImpressionArcState()
    {
        string theme = GetThemeForFirstImpression();
        if (string.IsNullOrWhiteSpace(theme))
        {
            return "첫 인상을 고르면 생활 장면과 연결됩니다.";
        }

        if (IsFirstImpressionThemeDeep())
        {
            return $"{firstImpression} -> {theme} 깊은 기록";
        }
        if (IsFirstImpressionThemeOpened())
        {
            return $"{firstImpression} -> {theme} 장면 열림";
        }

        return $"{firstImpression} -> {theme} 장면 대기";
    }

    private string BuildFirstImpressionArcLine()
    {
        string theme = GetThemeForFirstImpression();
        if (string.IsNullOrWhiteSpace(theme))
        {
            return "첫 인상을 고르면 겉으로 보인 단서가 속의 생활 장면으로 이어집니다.";
        }

        if (IsFirstImpressionThemeDeep())
        {
            return $"{firstImpression} -> {theme} 깊은 기록. 처음 본 겉 단서가 속 생활까지 이어졌습니다.";
        }
        if (IsFirstImpressionThemeOpened())
        {
            return $"{firstImpression} -> {theme} 장면 열림. 질문을 이어 가면 더 깊어질 수 있습니다.";
        }

        return $"{firstImpression} -> {theme} 장면 대기. 다음 질문이 겉과 속을 연결합니다.";
    }

    private void UpdateQuestionPhoneProgress()
    {
        int count = discoveredThemes.Count;
        int total = memoryThemes.Length;
        int deep = CountDeepMemories();

        if (questionPhoneProgressText != null)
        {
            questionPhoneProgressText.text = IsCompletedFiveTurnSession()
                ? $"질문 {RequiredQuestionCount}/{RequiredQuestionCount} · 선택 대기"
                : $"질문 {Mathf.Clamp(conversationTurns, 0, RequiredQuestionCount)}/{RequiredQuestionCount} · 전체 기록";
        }

        if (questionPhoneGuideText != null)
        {
            questionPhoneGuideText.text = BuildQuestionPhoneGuideText(count, total, deep);
            questionPhoneGuideText.color = IsCompletedFiveTurnSession()
                ? new Color32(22, 101, 52, 245)
                : new Color32(51, 65, 85, 238);
        }

        if (chapterButtons == null) return;
        for (int i = 0; i < chapterButtons.Length && i < memoryThemes.Length; i++)
        {
            Button button = chapterButtons[i];
            if (button == null) continue;

            bool unlocked = discoveredThemes.Contains(memoryThemes[i]);
            Text label = button.GetComponentInChildren<Text>();
            if (label != null)
            {
                label.text = BuildChapterButtonLabel(memoryThemes[i]);
            }

            SetButtonColor(
                button,
                unlocked ? new Color(0.82f, 0.66f, 0.44f, 0.58f) : new Color(1f, 0.99f, 0.95f, 0.88f),
                unlocked ? new Color32(15, 23, 42, 238) : new Color32(15, 23, 42, 248));

            if (chapterIllustrationImages != null && i < chapterIllustrationImages.Length && chapterIllustrationImages[i] != null)
            {
                chapterIllustrationImages[i].color = unlocked
                    ? new Color(1f, 1f, 1f, 0.56f)
                    : new Color(1f, 1f, 1f, 0.30f);
            }
        }
    }

    private string BuildChapterButtonLabel(string theme)
    {
        string canonical = CanonicalTheme(theme);
        int index = Array.IndexOf(memoryThemes, canonical);
        bool opened = discoveredThemes != null && discoveredThemes.Contains(canonical);
        bool deep = opened && deepMemoryUnlocked != null && index >= 0 && index < deepMemoryUnlocked.Length && deepMemoryUnlocked[index];

        if (string.Equals(activeQuestionCategory, canonical, StringComparison.Ordinal))
        {
            return $"{canonical} · {Mathf.Clamp(activeCategoryQuestionCount, 0, RequiredQuestionCount)}/{RequiredQuestionCount}";
        }
        if (deep) return $"{canonical} · 깊음";
        if (opened) return $"{canonical} · 깊게";
        return $"{canonical} · 열기";
    }

    private string BuildChapterStateSummaryLine()
    {
        if (memoryThemes == null || memoryThemes.Length == 0) return string.Empty;

        int unopened = 0;
        int shallow = 0;
        int deep = 0;
        for (int i = 0; i < memoryThemes.Length; i++)
        {
            string theme = memoryThemes[i];
            bool opened = discoveredThemes != null && discoveredThemes.Contains(theme);
            bool isDeep = opened && deepMemoryUnlocked != null && i < deepMemoryUnlocked.Length && deepMemoryUnlocked[i];
            if (isDeep) deep++;
            else if (opened) shallow++;
            else unopened++;
        }

        return $"장면: 새로 열기 {unopened} · 더 묻기 {shallow} · 깊음 {deep}";
    }

    private string BuildQuestionPhoneGuideText(int openedScenes, int totalScenes, int deepScenes)
    {
        int remainingQuestions = Mathf.Max(0, RequiredQuestionCount - conversationTurns);

        if (IsCompletedFiveTurnSession())
        {
            return "질문 5개 완료 · 5개 더 물어보기 또는 끝내기 선택";
        }

        if (conversationTurns <= 0)
        {
            return "전체 기록에서 중요한 질문 3개를 먼저 보여 줍니다.";
        }

        return $"전체 질문 흐름 · 남은 질문 {remainingQuestions}개";
    }

    private string BuildQuestionSessionQualityLine(int deepScenes, int totalScenes)
    {
        string dominant = GetDominantAttitude();
        string attitude = string.Equals(dominant, "아직 없음", StringComparison.Ordinal)
            ? "질문 전"
            : $"주된 질문 {dominant}";
        return $"{attitude} · 깊은 {deepScenes}/{totalScenes}";
    }

    private string BuildFirstImpressionTargetBadge()
    {
        string theme = GetThemeForFirstImpression();
        if (string.IsNullOrWhiteSpace(theme)) return string.Empty;

        int index = Array.IndexOf(memoryThemes, theme);
        bool opened = discoveredThemes != null && discoveredThemes.Contains(theme);
        bool deep = opened && deepMemoryUnlocked != null && index >= 0 && index < deepMemoryUnlocked.Length && deepMemoryUnlocked[index];

        if (deep) return $"첫 인상 {theme} 깊음";
        if (opened) return $"첫 인상 {theme} 더 묻기";
        return $"첫 인상 {theme}";
    }

    private string BuildCompletedQuestionGuideText(int deepScenes, int totalScenes)
    {
        string target = BuildFirstImpressionTargetLine();
        if (!string.IsNullOrWhiteSpace(target))
        {
            return $"마무리 가능 · {BuildQuestionSessionQualityLine(deepScenes, totalScenes)}";
        }

        return $"마무리 가능 · {BuildQuestionSessionQualityLine(deepScenes, totalScenes)}";
    }

    private static string BuildMemoryCardText(string theme, string caption, string note, bool deep)
    {
        string depthLabel = deep ? "깊은 기록" : "얕은 기록";
        string text = $"<b>{SanitizeRichText(theme)}</b> · {depthLabel}\n{SanitizeRichText(ShortenForCard(caption, 18))}";
        if (!string.IsNullOrWhiteSpace(note))
        {
            text += $"\n<size=10>{SanitizeRichText(note)}</size>";
        }
        return text;
    }

    private void EnsureMemoryNotes()
    {
        if (memoryNotes == null || memoryNotes.Length != memoryThemes.Length)
        {
            string[] next = new string[memoryThemes.Length];
            if (memoryNotes != null)
            {
                Array.Copy(memoryNotes, next, Mathf.Min(memoryNotes.Length, next.Length));
            }
            memoryNotes = next;
        }

        if (deepMemoryUnlocked == null || deepMemoryUnlocked.Length != memoryThemes.Length)
        {
            bool[] nextDeep = new bool[memoryThemes.Length];
            if (deepMemoryUnlocked != null)
            {
                Array.Copy(deepMemoryUnlocked, nextDeep, Mathf.Min(deepMemoryUnlocked.Length, nextDeep.Length));
            }
            deepMemoryUnlocked = nextDeep;
        }
    }

    private void EnsureAttitudeCounts()
    {
        if (attitudeCounts == null || attitudeCounts.Length != attitudeNames.Length)
        {
            int[] next = new int[attitudeNames.Length];
            if (attitudeCounts != null)
            {
                Array.Copy(attitudeCounts, next, Mathf.Min(attitudeCounts.Length, next.Length));
            }
            attitudeCounts = next;
        }
    }

    private void CreateFirstImpressionOverlay(Transform parent)
    {
        Image overlay = CreatePanel("First Impression Overlay", parent, new Color(0.030f, 0.024f, 0.018f, 0.56f));
        firstImpressionObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image shadow = CreateRoundedPanel("First Impression Shadow", firstImpressionObject.transform, ModalShadowColor, 26);
        Stretch(shadow.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-440f, -206f), new Vector2(440f, 194f));

        Image panel = CreatePaperPanel("First Impression Panel", firstImpressionObject.transform, new Color(0.985f, 0.965f, 0.900f, 0.98f), 26, 11);
        Stretch(panel.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-452f, -188f), new Vector2(428f, 212f));

        Image accent = CreateRoundedPanel("First Impression Accent", panel.transform, new Color32(177, 113, 58, 235), 7);
        Stretch(accent.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(46f, -76f), new Vector2(-46f, -66f));

        Text title = CreateText("First Impression Title", panel.transform, "먼저 눈에 들어온 장면", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(title.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(46f, -54f), new Vector2(-46f, -14f));

        firstImpressionPromptText = CreateText(
            "First Impression Prompt",
            panel.transform,
            "정답을 맞히는 선택이 아닙니다. 지금 먼저 보이는 겉 단서를 고르면, 그 단서가 어떤 속 생활로 이어지는지 5번의 질문으로 확인합니다.",
            17,
            new Color32(51, 65, 85, 255),
            TextAnchor.UpperLeft,
            FontStyle.Normal);
        firstImpressionPromptText.lineSpacing = 1.12f;
        Stretch(firstImpressionPromptText.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(46f, -128f), new Vector2(-46f, -82f));

        firstImpressionButtons = new Button[firstImpressionOptions.Length];
        for (int i = 0; i < firstImpressionOptions.Length; i++)
        {
            int captured = i;
            Button button = CreateButton(
                $"First Impression {firstImpressionOptions[i]}",
                panel.transform,
                BuildFirstImpressionOptionLabel(firstImpressionOptions[i]),
                i == 0 ? new Color32(146, 83, 40, 245) : new Color32(30, 41, 59, 238),
                Color.white,
                19);
            Stretch(button.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(62f + i * 260f, 76f), new Vector2(-566f + i * 260f, 140f));
            Image illustration = CreateIllustrationImage(
                $"First Impression Illustration {firstImpressionOptions[i]}",
                button.transform,
                GetIllustrationResourceForFirstImpression(firstImpressionOptions[i]),
                new Color(1f, 1f, 1f, 0.30f));
            if (illustration != null)
            {
                illustration.transform.SetAsFirstSibling();
                Stretch(illustration.rectTransform, Vector2.zero, Vector2.one, new Vector2(10f, 7f), new Vector2(-170f, -7f));
                Text optionLabel = FindChildText(button.transform, "Label");
                if (optionLabel != null)
                {
                    optionLabel.alignment = TextAnchor.MiddleLeft;
                    Stretch(optionLabel.rectTransform, Vector2.zero, Vector2.one, new Vector2(72f, 4f), new Vector2(-12f, -4f));
                }
            }
            button.onClick.AddListener(() => SelectFirstImpression(firstImpressionOptions[captured]));
            firstImpressionButtons[i] = button;
        }

        firstImpressionObject.SetActive(false);
    }

    private void CreateStartMenuOverlay(Transform parent)
    {
        Image overlay = CreatePanel("Start Menu Overlay", parent, Color.white);
        startMenuObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        overlay.sprite = LoadBackgroundSprite();
        overlay.preserveAspect = false;

        CreateSceneDepthLayers(startMenuObject.transform);
        if (!UseIntegratedSceneArtwork)
        {
            CreateAvatarSoftLayer(startMenuObject.transform, "Start Menu Avatar Backdrop Shadow", new Color(0.018f, 0.014f, 0.010f, 0.12f), new Vector2(620f, 430f), new Vector2(-126f, -72f), -2.0f);
            CreateAvatarSoftLayer(startMenuObject.transform, "Start Menu Avatar Contact Shadow", new Color(0.012f, 0.010f, 0.008f, 0.20f), new Vector2(520f, 88f), new Vector2(-110f, -344f), -1.2f);

            Image startAvatar = CreatePanel("Start Menu Avatar", startMenuObject.transform, Color.white);
            startAvatar.sprite = avatarSprites.TryGetValue(ExpressionState.Idle, out Sprite idleSprite) ? idleSprite : null;
            startAvatar.preserveAspect = true;
            startAvatar.useSpriteMesh = true;
            startAvatar.raycastTarget = false;
            RectTransform startAvatarRect = startAvatar.rectTransform;
            startAvatarRect.anchorMin = new Vector2(0.5f, 0.5f);
            startAvatarRect.anchorMax = new Vector2(0.5f, 0.5f);
            startAvatarRect.pivot = new Vector2(0.5f, 0.5f);
            startAvatarRect.sizeDelta = new Vector2(820f, 556f);
            startAvatarRect.anchoredPosition = new Vector2(-118f, -62f);
            startAvatarRect.localScale = AvatarScale(1f);

            Image startAvatarWash = CreatePanel("Start Menu Avatar Scene Wash", startMenuObject.transform, new Color(0.96f, 0.82f, 0.60f, 0f));
            startAvatarWash.sprite = startAvatar.sprite;
            startAvatarWash.preserveAspect = true;
            startAvatarWash.useSpriteMesh = true;
            startAvatarWash.raycastTarget = false;
            RectTransform startAvatarWashRect = startAvatarWash.rectTransform;
            startAvatarWashRect.anchorMin = startAvatarRect.anchorMin;
            startAvatarWashRect.anchorMax = startAvatarRect.anchorMax;
            startAvatarWashRect.pivot = startAvatarRect.pivot;
            startAvatarWashRect.sizeDelta = startAvatarRect.sizeDelta;
            startAvatarWashRect.anchoredPosition = startAvatarRect.anchoredPosition;
            startAvatarWashRect.localScale = startAvatarRect.localScale;
        }

        CreateLowerTableEdgeLayer(startMenuObject.transform);

        Image storefrontFill = CreatePanel("Start Menu Storefront Fill Light", startMenuObject.transform, new Color(1.000f, 0.940f, 0.800f, 0.08f));
        Stretch(storefrontFill.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        storefrontFill.raycastTarget = false;

        Image dim = CreatePanel("Start Menu Scene Dim", startMenuObject.transform, new Color(0.030f, 0.024f, 0.018f, 0.105f));
        Stretch(dim.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
        dim.raycastTarget = false;

        Image leftReadability = CreatePanel("Start Menu Left Readability Wash", startMenuObject.transform, new Color(0.030f, 0.024f, 0.018f, 0.08f));
        Stretch(leftReadability.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 1f), new Vector2(0f, 0f), new Vector2(560f, 0f));
        leftReadability.raycastTarget = false;

        Image bottomShade = CreatePanel("Start Menu Bottom Shade", startMenuObject.transform, new Color(0.030f, 0.024f, 0.018f, 0.22f));
        Stretch(bottomShade.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(0f, 0f), new Vector2(0f, 196f));
        bottomShade.raycastTarget = false;

        Image titleReadability = CreateRoundedPanel("Start Menu Title Readability", startMenuObject.transform, new Color(0.020f, 0.016f, 0.012f, 0.20f), 8);
        Stretch(titleReadability.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(122f, 648f), new Vector2(648f, 842f));
        titleReadability.raycastTarget = false;

        Text title = CreateText("Start Menu Title", startMenuObject.transform, StartMenuDisplayTitle, 68, new Color32(255, 242, 210, 252), TextAnchor.UpperLeft, FontStyle.Bold);
        AddTextShadow(title, new Color(0f, 0f, 0f, 0.55f), new Vector2(3f, -3f));
        title.resizeTextForBestFit = true;
        title.resizeTextMinSize = 52;
        title.resizeTextMaxSize = 68;
        Stretch(title.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(134f, 746f), new Vector2(600f, 832f));

        Text subtitle = CreateText("Start Menu Subtitle", startMenuObject.transform, GameSubtitle, 19, new Color32(255, 244, 214, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        AddTextShadow(subtitle, new Color(0f, 0f, 0f, 0.64f), new Vector2(2f, -2f));
        subtitle.lineSpacing = 1.08f;
        subtitle.resizeTextForBestFit = true;
        subtitle.resizeTextMinSize = 15;
        subtitle.resizeTextMaxSize = 19;
        Stretch(subtitle.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(138f, 708f), new Vector2(624f, 740f));

        startObjectiveText = CreateText("Start Menu Objective", startMenuObject.transform, BuildStartObjectiveLine(), 16, new Color32(255, 238, 204, 246), TextAnchor.UpperLeft, FontStyle.Bold);
        AddTextShadow(startObjectiveText, new Color(0f, 0f, 0f, 0.62f), new Vector2(2f, -2f));
        startObjectiveText.lineSpacing = 1.05f;
        startObjectiveText.resizeTextForBestFit = true;
        startObjectiveText.resizeTextMinSize = 12;
        startObjectiveText.resizeTextMaxSize = 16;
        Stretch(startObjectiveText.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(140f, 656f), new Vector2(618f, 696f));

        startMenuFlowPanel = CreateRoundedPanel("Start Menu Flow", startMenuObject.transform, new Color(0.030f, 0.024f, 0.018f, 0.34f), 6);
        Stretch(startMenuFlowPanel.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(140f, 318f), new Vector2(544f, 354f));
        startMenuFlowPanel.gameObject.SetActive(false);

        startSavePreviewText = CreateText("Start Menu Save Preview", startMenuFlowPanel.transform, "", 13, new Color32(255, 236, 198, 226), TextAnchor.MiddleLeft, FontStyle.Bold);
        startSavePreviewText.lineSpacing = 1.05f;
        startSavePreviewText.resizeTextForBestFit = true;
        startSavePreviewText.resizeTextMinSize = 10;
        startSavePreviewText.resizeTextMaxSize = 12;
        Stretch(startSavePreviewText.rectTransform, Vector2.zero, Vector2.one, new Vector2(14f, 2f), new Vector2(-14f, -2f));

        continueButton = CreateButton("Continue Interview Button", startMenuObject.transform, "이어하기", new Color(0.08f, 0.06f, 0.045f, 0.56f), new Color32(255, 238, 204, 246), 17);
        StyleStartMenuButtonLabel(continueButton, 17);
        Stretch(continueButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(140f, 560f), new Vector2(544f, 612f));
        continueButton.onClick.AddListener(() =>
        {
            if (!EnsureServerReadyForStart()) return;
            if (LoadSavedSession())
            {
                lastStartMenuAction = "continue-button";
                StartSession(true);
                statusText.text = "저장된 대화를 이어갑니다";
            }
        });

        startButton = CreateButton("Start Interview Button", startMenuObject.transform, "처음부터 시작", new Color(0.42f, 0.25f, 0.13f, 0.82f), new Color32(255, 240, 210, 250), 18);
        StyleStartMenuButtonLabel(startButton, 18);
        Stretch(startButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(140f, 500f), new Vector2(544f, 552f));
        startButton.onClick.AddListener(() => RequestFreshStart(true));

        startNoteButton = CreateButton("Start With Phone Button", startMenuObject.transform, "질문 노트", new Color(0.08f, 0.06f, 0.045f, 0.54f), new Color32(236, 224, 198, 232), 16);
        StyleStartMenuButtonLabel(startNoteButton, 16);
        Stretch(startNoteButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(140f, 440f), new Vector2(544f, 492f));
        startNoteButton.onClick.AddListener(() => RequestFreshStart(true));

        startStoryButton = CreateButton("Start Story Mode Button", startMenuObject.transform, "이야기 먼저 보기", new Color(0.08f, 0.06f, 0.045f, 0.54f), new Color32(236, 224, 198, 232), 16);
        StyleStartMenuButtonLabel(startStoryButton, 16);
        Stretch(startStoryButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(140f, 380f), new Vector2(544f, 432f));
        startStoryButton.onClick.AddListener(RequestStoryMode);
        startStoryButton.gameObject.SetActive(false);

        Button archiveButton = CreateStartUtilityButton("Record Archive From Start Button", startMenuObject.transform, "기록");
        Stretch(archiveButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(140f, 90f), new Vector2(222f, 126f));
        archiveButton.onClick.AddListener(() => SetRecordArchiveOpen(true));
        archiveButton.gameObject.SetActive(false);

        startSettingsButton = CreateStartUtilityButton("Settings From Start Button", startMenuObject.transform, "설정");
        Stretch(startSettingsButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(140f, 90f), new Vector2(228f, 126f));
        startSettingsButton.onClick.AddListener(() => SetSettingsMenuOpen(true));

        startAboutButton = CreateStartUtilityButton("Start About Button", startMenuObject.transform, "정보");
        Stretch(startAboutButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(244f, 90f), new Vector2(332f, 126f));
        startAboutButton.onClick.AddListener(() => SetAboutMenuOpen(true));

        Button quitButton = CreateStartUtilityButton("Quit From Start Button", startMenuObject.transform, "종료");
        Stretch(quitButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(348f, 90f), new Vector2(436f, 126f));
        quitButton.onClick.AddListener(Application.Quit);
        quitButton.gameObject.SetActive(false);

        UpdateContinueButton();
    }

    private void CreatePauseMenuOverlay(Transform parent)
    {
        Image overlay = CreatePanel("Pause Menu Overlay", parent, ModalOverlayColor);
        pauseMenuObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image panel = CreateRoundedPanel("Pause Menu Panel", pauseMenuObject.transform, new Color(0.985f, 0.965f, 0.900f, 0.99f), 28);
        Stretch(panel.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-280f, -220f), new Vector2(280f, 224f));

        Text title = CreateText("Pause Menu Title", panel.transform, "잠시 멈춤", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(title.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(42f, -54f), new Vector2(-42f, -16f));

        Text body = CreateText("Pause Menu Body", panel.transform, "대화를 이어가거나, 처음부터 다시 시작할 수 있습니다.", 16, new Color32(71, 85, 105, 255), TextAnchor.UpperLeft, FontStyle.Normal);
        Stretch(body.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(42f, -104f), new Vector2(-42f, -72f));

        Button resumeButton = CreateButton("Resume Button", panel.transform, "계속하기", new Color32(177, 113, 58, 245), Color.white, 17);
        Stretch(resumeButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(42f, 186f), new Vector2(-42f, 236f));
        resumeButton.onClick.AddListener(() => SetPauseMenuOpen(false));

        Button settingsButton = CreateButton("Settings From Pause Button", panel.transform, "설정", new Color32(30, 41, 59, 238), Color.white, 17);
        Stretch(settingsButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(42f, 126f), new Vector2(-42f, 176f));
        settingsButton.onClick.AddListener(() => SetSettingsMenuOpen(true));

        Button restartButton = CreateButton("Restart Button", panel.transform, "처음부터", new Color32(30, 41, 59, 238), Color.white, 17);
        Stretch(restartButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(42f, 66f), new Vector2(-42f, 116f));
        restartButton.onClick.AddListener(() => RequestFreshStart(true));

        Button quitButton = CreateButton("Quit From Pause Button", panel.transform, "종료", new Color(1f, 0.99f, 0.95f, 0.96f), new Color32(30, 41, 59, 255), 17);
        Stretch(quitButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(42f, 6f), new Vector2(-42f, 56f));
        quitButton.onClick.AddListener(Application.Quit);

        pauseMenuObject.SetActive(false);
    }

    private static string BuildStartObjectiveLine()
    {
        return "먼저 보이는 장면을 고르고, 질문으로 그 뒤의 생활을 확인합니다.";
    }

    private void CreateSettingsMenuOverlay(Transform parent)
    {
        Image overlay = CreatePanel("Settings Menu Overlay", parent, ModalOverlayColor);
        settingsMenuObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image panel = CreateRoundedPanel("Settings Menu Panel", settingsMenuObject.transform, new Color(0.985f, 0.965f, 0.900f, 0.99f), 28);
        Stretch(panel.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-300f, -210f), new Vector2(300f, 216f));

        Text title = CreateText("Settings Menu Title", panel.transform, "설정", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(title.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(42f, -54f), new Vector2(-42f, -16f));

        Text textSizeLabel = CreateText("Settings Text Size Label", panel.transform, "글자 크기", 16, new Color32(51, 65, 85, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(textSizeLabel.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(42f, -116f), new Vector2(-42f, -86f));

        settingsTextSizeButtons = new Button[3];
        string[] labels = { "작게", "기본", "크게" };
        int[] levels = { -1, 0, 1 };
        for (int i = 0; i < settingsTextSizeButtons.Length; i++)
        {
            int level = levels[i];
            Button button = CreateButton($"Settings Text Size {labels[i]}", panel.transform, labels[i], new Color32(30, 41, 59, 238), Color.white, 16);
            Stretch(button.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(42f + i * 162f, 232f), new Vector2(184f + i * 162f, 282f));
            button.onClick.AddListener(() => SetDialogueSizeLevel(level, true));
            settingsTextSizeButtons[i] = button;
        }

        Text screenLabel = CreateText("Settings Screen Label", panel.transform, "화면, 소리, 답변", 16, new Color32(51, 65, 85, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(screenLabel.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(42f, -232f), new Vector2(-42f, -202f));

        fullscreenButton = CreateButton("Fullscreen Toggle Button", panel.transform, "전체 화면", new Color32(30, 41, 59, 238), Color.white, 16);
        Stretch(fullscreenButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(42f, 144f), new Vector2(290f, 194f));
        fullscreenButton.onClick.AddListener(() => SetFullscreenEnabled(!fullscreenEnabled, true));

        soundButton = CreateButton("Sound Toggle Button", panel.transform, "소리 기본", new Color32(30, 41, 59, 238), Color.white, 16);
        Stretch(soundButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(310f, 144f), new Vector2(-42f, 194f));
        soundButton.onClick.AddListener(CycleSoundLevel);

        reducedMotionButton = CreateButton("Reduced Motion Toggle Button", panel.transform, "움직임 기본", new Color32(30, 41, 59, 238), Color.white, 16);
        Stretch(reducedMotionButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(42f, 82f), new Vector2(290f, 132f));
        reducedMotionButton.onClick.AddListener(() => SetReducedMotionEnabled(!reducedMotionEnabled, true));

        highContrastButton = CreateButton("High Contrast Toggle Button", panel.transform, "읽기 쉬운 화면", new Color32(30, 41, 59, 238), Color.white, 16);
        Stretch(highContrastButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(310f, 82f), new Vector2(-42f, 132f));
        highContrastButton.onClick.AddListener(() => SetHighContrastEnabled(!highContrastEnabled, true));

        Button archiveButton = CreateButton("Open Record Archive Button", panel.transform, "기록함", new Color32(30, 41, 59, 238), Color.white, 16);
        Stretch(archiveButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(42f, 18f), new Vector2(162f, 68f));
        archiveButton.onClick.AddListener(() => SetRecordArchiveOpen(true));

        Button aboutButton = CreateButton("About Button", panel.transform, "정보", new Color32(30, 41, 59, 238), Color.white, 16);
        Stretch(aboutButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(174f, 18f), new Vector2(294f, 68f));
        aboutButton.onClick.AddListener(() => SetAboutMenuOpen(true));

        localAnswerOnlyButton = CreateButton("Local Answer Only Toggle Button", panel.transform, "서버 필수", new Color32(30, 41, 59, 238), Color.white, 15);
        Stretch(localAnswerOnlyButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(306f, 18f), new Vector2(426f, 68f));
        localAnswerOnlyButton.onClick.AddListener(RefreshServerStatus);

        Button closeButton = CreateButton("Close Settings Button", panel.transform, "닫기", new Color32(146, 83, 40, 245), Color.white, 17);
        Stretch(closeButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(438f, 18f), new Vector2(558f, 68f));
        closeButton.onClick.AddListener(() => SetSettingsMenuOpen(false));

        UpdateSettingsControls();
        settingsMenuObject.SetActive(false);
    }

    private void CreateAboutMenuOverlay(Transform parent)
    {
        Image overlay = CreatePanel("About Menu Overlay", parent, ModalOverlayColor);
        aboutMenuObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image panel = CreateRoundedPanel("About Menu Panel", aboutMenuObject.transform, new Color(0.985f, 0.965f, 0.900f, 0.99f), 28);
        Stretch(panel.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-390f, -250f), new Vector2(390f, 254f));

        Text title = CreateText("About Menu Title", panel.transform, "정보", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(title.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -56f), new Vector2(-44f, -16f));

        Text body = CreateText(
            "About Menu Body",
            panel.transform,
            "이 앱은 2026년 5월 1일 인터뷰와 조별 활동 자료를 바탕으로 만들었습니다.\n\n답변은 확인된 자료와 서버 연결 상태를 기준으로 이어집니다. API 키는 앱이나 기록 파일에 저장하지 않습니다.\n\n서버와 API 답변이 준비되지 않으면 시작하거나 질문할 수 없습니다.\n\n마이크 녹음은 전사할 때만 서버로 보내며, 마무리 기록과 의견 메모는 이 컴퓨터에 저장됩니다.\n\n자료에 없는 개인정보, 진단명, 회사명, 주소, 연락처는 만들지 않습니다.",
            16,
            new Color32(51, 65, 85, 255),
            TextAnchor.UpperLeft,
            FontStyle.Normal);
        body.lineSpacing = 1.05f;
        body.resizeTextForBestFit = true;
        body.resizeTextMinSize = 14;
        body.resizeTextMaxSize = 16;
        Stretch(body.rectTransform, Vector2.zero, Vector2.one, new Vector2(44f, 204f), new Vector2(-44f, -92f));

        Image statusPanel = CreateRoundedPanel("About Server Status Panel", panel.transform, new Color(0.88f, 0.96f, 0.90f, 0.88f), 16);
        Stretch(statusPanel.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(44f, 138f), new Vector2(-44f, 202f));

        serverStatusText = CreateText("About Server Status Text", statusPanel.transform, ServerStatusIdleText, 15, new Color32(30, 41, 59, 255), TextAnchor.MiddleLeft, FontStyle.Bold);
        serverStatusText.resizeTextForBestFit = true;
        serverStatusText.resizeTextMinSize = 11;
        serverStatusText.resizeTextMaxSize = 15;
        Stretch(serverStatusText.rectTransform, Vector2.zero, Vector2.one, new Vector2(20f, 12f), new Vector2(-184f, -12f));

        Button serverRefreshButton = CreateButton("About Server Refresh Button", statusPanel.transform, "상태 확인", new Color32(146, 83, 40, 245), Color.white, 15);
        Stretch(serverRefreshButton.GetComponent<RectTransform>(), new Vector2(1f, 0.5f), new Vector2(1f, 0.5f), new Vector2(-166f, -22f), new Vector2(-18f, 22f));
        serverRefreshButton.onClick.AddListener(RefreshServerStatus);

        Button recordFolderButton = CreateButton("About Record Folder Button", panel.transform, "기록 폴더", new Color32(30, 41, 59, 238), Color.white, 16);
        Stretch(recordFolderButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(44f, 24f), new Vector2(208f, 74f));
        recordFolderButton.onClick.AddListener(OpenEndingRecordFolder);

        Button feedbackFolderButton = CreateButton("About Feedback Folder Button", panel.transform, "의견 폴더", new Color32(30, 41, 59, 238), Color.white, 16);
        Stretch(feedbackFolderButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(224f, 24f), new Vector2(388f, 74f));
        feedbackFolderButton.onClick.AddListener(OpenPlaytestFeedbackFolder);

        clearLocalDataButton = CreateButton("About Clear Local Data Button", panel.transform, "저장 삭제", new Color32(133, 111, 82, 230), Color.white, 16);
        Stretch(clearLocalDataButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(404f, 24f), new Vector2(568f, 74f));
        clearLocalDataButton.onClick.AddListener(HandleClearLocalDataButtonClick);

        clearLocalDataHintPanel = CreateRoundedPanel("About Clear Local Data Hint Panel", panel.transform, new Color(1f, 0.99f, 0.95f, 0.82f), 12);
        Stretch(clearLocalDataHintPanel.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(44f, 86f), new Vector2(-44f, 132f));

        clearLocalDataHintText = CreateText("About Clear Local Data Hint", clearLocalDataHintPanel.transform, "저장 삭제는 확인 후 실행됩니다.", 15, new Color32(88, 72, 54, 255), TextAnchor.MiddleLeft, FontStyle.Bold);
        clearLocalDataHintText.resizeTextForBestFit = true;
        clearLocalDataHintText.resizeTextMinSize = 12;
        clearLocalDataHintText.resizeTextMaxSize = 15;
        Stretch(clearLocalDataHintText.rectTransform, Vector2.zero, Vector2.one, new Vector2(22f, 8f), new Vector2(-22f, -8f));

        Button closeButton = CreateButton("Close About Button", panel.transform, "닫기", new Color32(146, 83, 40, 245), Color.white, 17);
        Stretch(closeButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-208f, 24f), new Vector2(-44f, 74f));
        closeButton.onClick.AddListener(() => SetAboutMenuOpen(false));

        UpdateClearLocalDataButton();
        aboutMenuObject.SetActive(false);
    }

    private void CreateRecordArchiveOverlay(Transform parent)
    {
        Image overlay = CreatePanel("Record Archive Overlay", parent, ModalOverlayColor);
        recordArchiveObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image shadow = CreateRoundedPanel("Record Archive Shadow", recordArchiveObject.transform, ModalShadowColor, 34);
        Stretch(shadow.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-562f, -328f), new Vector2(574f, 316f));

        Image panel = CreateRoundedPanel("Record Archive Panel", recordArchiveObject.transform, new Color(0.985f, 0.965f, 0.900f, 0.99f), 34);
        Stretch(panel.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-574f, -310f), new Vector2(550f, 334f));

        Image accent = CreateRoundedPanel("Record Archive Accent", panel.transform, new Color32(177, 113, 58, 235), 7);
        Stretch(accent.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(46f, -78f), new Vector2(-46f, -68f));

        Text title = CreateText("Record Archive Title", panel.transform, "기록함", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(title.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(48f, -56f), new Vector2(-48f, -16f));

        Text subtitle = CreateText("Record Archive Subtitle", panel.transform, "저장한 마무리 기록을 다시 읽을 수 있습니다.", 16, new Color32(71, 85, 105, 255), TextAnchor.UpperLeft, FontStyle.Normal);
        Stretch(subtitle.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(48f, -116f), new Vector2(-48f, -84f));

        Image listPanel = CreateRoundedPanel("Record Archive List Panel", panel.transform, new Color(0.88f, 0.96f, 0.90f, 0.78f), 20);
        Stretch(listPanel.rectTransform, Vector2.zero, Vector2.one, new Vector2(48f, 108f), new Vector2(-740f, -150f));

        recordArchiveListTitleText = CreateText("Record Archive List Title", listPanel.transform, "최근 기록", 16, new Color32(30, 41, 59, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(recordArchiveListTitleText.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(22f, -38f), new Vector2(-22f, -12f));

        recordArchiveButtons = new Button[RecordArchiveSlotCount];
        for (int i = 0; i < recordArchiveButtons.Length; i++)
        {
            int captured = i;
            Button button = CreateButton($"Record Archive Slot {i + 1}", listPanel.transform, "", new Color(1f, 0.99f, 0.95f, 0.96f), new Color32(30, 41, 59, 255), 14);
            Stretch(button.GetComponent<RectTransform>(), new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(22f, -92f - i * 54f), new Vector2(-22f, -52f - i * 54f));
            button.onClick.AddListener(() => SelectRecordArchive(captured));
            recordArchiveButtons[i] = button;
        }

        Image previewPanel = CreateRoundedPanel("Record Archive Preview Panel", panel.transform, new Color(1f, 0.99f, 0.95f, 0.96f), 20);
        Stretch(previewPanel.rectTransform, Vector2.zero, Vector2.one, new Vector2(394f, 108f), new Vector2(-48f, -150f));

        Text previewTitle = CreateText("Record Archive Preview Title", previewPanel.transform, "마무리 기록", 17, new Color32(30, 41, 59, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(previewTitle.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(24f, -40f), new Vector2(-24f, -12f));

        Image previewHeader = CreateRoundedPanel("Record Archive Preview Header", previewPanel.transform, new Color(0.84f, 0.94f, 0.88f, 0.88f), 10);
        previewHeader.raycastTarget = false;
        Stretch(previewHeader.rectTransform, new Vector2(0f, 1f), Vector2.one, new Vector2(24f, -88f), new Vector2(-34f, -50f));

        recordArchivePreviewHeaderText = CreateText("Record Archive Preview Header Text", previewHeader.transform, "", RecordArchivePreviewHeaderFontSize, RecordArchivePreviewHeaderColor, TextAnchor.MiddleLeft, FontStyle.Bold);
        recordArchivePreviewHeaderText.resizeTextForBestFit = true;
        recordArchivePreviewHeaderText.resizeTextMinSize = 12;
        recordArchivePreviewHeaderText.resizeTextMaxSize = RecordArchivePreviewHeaderFontSize;
        Stretch(recordArchivePreviewHeaderText.rectTransform, Vector2.zero, Vector2.one, new Vector2(16f, 4f), new Vector2(-16f, -4f));

        GameObject scrollObject = new GameObject("Record Archive Scroll", typeof(RectTransform), typeof(ScrollRect));
        scrollObject.transform.SetParent(previewPanel.transform, false);
        recordArchiveScrollRect = scrollObject.GetComponent<ScrollRect>();
        RectTransform scrollRectTransform = scrollObject.GetComponent<RectTransform>();
        Stretch(scrollRectTransform, Vector2.zero, Vector2.one, new Vector2(24f, 20f), new Vector2(-34f, -104f));

        GameObject viewportObject = new GameObject("Record Archive Viewport", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Mask));
        viewportObject.transform.SetParent(scrollObject.transform, false);
        Image viewportImage = viewportObject.GetComponent<Image>();
        viewportImage.color = new Color(1f, 1f, 1f, 0.01f);
        viewportObject.GetComponent<Mask>().showMaskGraphic = false;
        recordArchiveViewportRect = viewportObject.GetComponent<RectTransform>();
        Stretch(recordArchiveViewportRect, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        GameObject contentObject = new GameObject("Record Archive Content", typeof(RectTransform));
        contentObject.transform.SetParent(viewportObject.transform, false);
        recordArchiveContentRect = contentObject.GetComponent<RectTransform>();
        recordArchiveContentRect.anchorMin = new Vector2(0f, 1f);
        recordArchiveContentRect.anchorMax = new Vector2(1f, 1f);
        recordArchiveContentRect.pivot = new Vector2(0.5f, 1f);
        recordArchiveContentRect.offsetMin = Vector2.zero;
        recordArchiveContentRect.offsetMax = Vector2.zero;
        recordArchiveContentRect.sizeDelta = new Vector2(0f, 360f);

        recordArchivePreviewText = CreateText("Record Archive Preview Text", contentObject.transform, "", RecordArchivePreviewBodyFontSize, RecordArchivePreviewBodyColor, TextAnchor.UpperLeft, FontStyle.Normal);
        recordArchivePreviewText.supportRichText = false;
        recordArchivePreviewText.lineSpacing = RecordArchivePreviewBodyLineSpacing;
        Stretch(recordArchivePreviewText.rectTransform, Vector2.zero, Vector2.one, new Vector2(0f, 0f), new Vector2(-12f, -8f));

        recordArchiveScrollRect.viewport = recordArchiveViewportRect;
        recordArchiveScrollRect.content = recordArchiveContentRect;
        recordArchiveScrollRect.horizontal = false;
        recordArchiveScrollRect.vertical = true;
        recordArchiveScrollRect.movementType = ScrollRect.MovementType.Clamped;
        recordArchiveScrollRect.scrollSensitivity = 34f;

        Scrollbar previewScrollbar = CreateVerticalScrollbar("Record Archive Scrollbar", previewPanel.transform);
        Stretch(previewScrollbar.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 1f), new Vector2(-24f, 20f), new Vector2(-14f, -104f));
        recordArchiveScrollRect.verticalScrollbar = previewScrollbar;
        recordArchiveScrollRect.verticalScrollbarVisibility = ScrollRect.ScrollbarVisibility.AutoHide;

        Button folderButton = CreateButton("Record Archive Folder Button", panel.transform, "폴더 열기", new Color32(30, 41, 59, 238), Color.white, 15);
        Stretch(folderButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(48f, 42f), new Vector2(180f, 88f));
        folderButton.onClick.AddListener(OpenEndingRecordFolder);

        Button refreshButton = CreateButton("Record Archive Refresh Button", panel.transform, "새로고침", new Color32(30, 41, 59, 238), Color.white, 15);
        Stretch(refreshButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(192f, 42f), new Vector2(324f, 88f));
        refreshButton.onClick.AddListener(RefreshRecordArchive);

        recordArchiveDeleteButton = CreateButton("Record Archive Delete Button", panel.transform, "선택 삭제", new Color32(133, 111, 82, 230), Color.white, 15);
        Stretch(recordArchiveDeleteButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(336f, 42f), new Vector2(468f, 88f));
        recordArchiveDeleteButton.onClick.AddListener(RequestDeleteSelectedRecord);

        recordArchiveCancelDeleteButton = CreateButton("Record Archive Cancel Delete Button", panel.transform, "취소", new Color32(30, 41, 59, 238), Color.white, 15);
        Stretch(recordArchiveCancelDeleteButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(480f, 42f), new Vector2(600f, 88f));
        recordArchiveCancelDeleteButton.onClick.AddListener(CancelPendingRecordDelete);
        recordArchiveCancelDeleteButton.gameObject.SetActive(false);

        recordArchiveDeleteHintPanel = CreateRoundedPanel("Record Archive Delete Hint Panel", panel.transform, new Color(1f, 0.99f, 0.95f, 0.66f), 10);
        Stretch(recordArchiveDeleteHintPanel.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(486f, 42f), new Vector2(-212f, 88f));

        recordArchiveDeleteHintText = CreateText("Record Archive Delete Hint", recordArchiveDeleteHintPanel.transform, "", 14, new Color32(71, 85, 105, 230), TextAnchor.MiddleLeft, FontStyle.Bold);
        recordArchiveDeleteHintText.resizeTextForBestFit = true;
        recordArchiveDeleteHintText.resizeTextMinSize = 11;
        recordArchiveDeleteHintText.resizeTextMaxSize = 14;
        Stretch(recordArchiveDeleteHintText.rectTransform, Vector2.zero, Vector2.one, new Vector2(16f, 6f), new Vector2(-16f, -6f));

        Button closeButton = CreateButton("Record Archive Close Button", panel.transform, "닫기", new Color32(146, 83, 40, 245), Color.white, 16);
        Stretch(closeButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-188f, 42f), new Vector2(-48f, 88f));
        closeButton.onClick.AddListener(() => SetRecordArchiveOpen(false));

        recordArchiveObject.SetActive(false);
    }

    private void CreatePlaytestFeedbackOverlay(Transform parent)
    {
        Image overlay = CreatePanel("Playtest Feedback Overlay", parent, ModalOverlayColor);
        playtestFeedbackObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image panel = CreateRoundedPanel("Playtest Feedback Panel", playtestFeedbackObject.transform, new Color(0.985f, 0.965f, 0.900f, 0.99f), 28);
        Stretch(panel.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-430f, -306f), new Vector2(430f, 304f));

        Image accent = CreateRoundedPanel("Playtest Feedback Accent", panel.transform, new Color32(177, 113, 58, 235), 7);
        Stretch(accent.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -76f), new Vector2(-44f, -66f));

        Text title = CreateText("Playtest Feedback Title", panel.transform, "의견 남기기", 30, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(title.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -54f), new Vector2(-44f, -16f));

        Text body = CreateText(
            "Playtest Feedback Body",
            panel.transform,
            "이야기를 마친 뒤 느낀 점을 남겨 주세요. 좋았던 부분, 헷갈린 흐름, 멈춘 지점을 적으면 다음 수정에 도움이 됩니다. 메모와 세션 정보는 이 컴퓨터에만 저장됩니다.",
            16,
            new Color32(51, 65, 85, 255),
            TextAnchor.UpperLeft,
            FontStyle.Normal);
        body.lineSpacing = 1.12f;
        Stretch(body.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -132f), new Vector2(-44f, -86f));

        Text ratingLabel = CreateText("Playtest Rating Label", panel.transform, "전체 느낌", 13, new Color32(71, 85, 105, 238), TextAnchor.MiddleLeft, FontStyle.Bold);
        Stretch(ratingLabel.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -154f), new Vector2(-44f, -136f));

        playtestRatingButtons = new Button[3];
        string[] labels = { "헷갈림", "보통", "좋음" };
        for (int i = 0; i < labels.Length; i++)
        {
            int rating = i + 1;
            Button button = CreateButton($"Playtest Rating {labels[i]}", panel.transform, labels[i], new Color32(30, 41, 59, 238), Color.white, 15);
            Stretch(button.GetComponent<RectTransform>(), new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(44f + i * 176f, -206f), new Vector2(200f + i * 176f, -158f));
            button.onClick.AddListener(() => SelectPlaytestRating(rating));
            playtestRatingButtons[i] = button;
        }

        Text readinessLabel = CreateText("Playtest Commercial Readiness Label", panel.transform, "완성도 느낌", 13, new Color32(71, 85, 105, 238), TextAnchor.MiddleLeft, FontStyle.Bold);
        Stretch(readinessLabel.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -224f), new Vector2(-44f, -206f));

        playtestCommercialReadinessButtons = new Button[3];
        string[] commercialLabels = { "더 다듬기", "조금 아쉬움", "충분함" };
        for (int i = 0; i < commercialLabels.Length; i++)
        {
            int readiness = i + 1;
            Button button = CreateButton($"Playtest Commercial Readiness {commercialLabels[i]}", panel.transform, commercialLabels[i], new Color32(30, 41, 59, 238), Color.white, 14);
            Stretch(button.GetComponent<RectTransform>(), new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(44f + i * 176f, -276f), new Vector2(200f + i * 176f, -228f));
            button.onClick.AddListener(() => SelectPlaytestCommercialReadiness(readiness));
            playtestCommercialReadinessButtons[i] = button;
        }

        Text issueLabel = CreateText("Playtest Issue Severity Label", panel.transform, "문제 단계", 13, new Color32(71, 85, 105, 238), TextAnchor.MiddleLeft, FontStyle.Bold);
        Stretch(issueLabel.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -294f), new Vector2(-44f, -276f));

        playtestIssueSeverityButtons = new Button[4];
        string[] issueLabels = { GetPlaytestIssueSeverityButtonLabel(0), GetPlaytestIssueSeverityButtonLabel(1), GetPlaytestIssueSeverityButtonLabel(2), GetPlaytestIssueSeverityButtonLabel(3) };
        for (int i = 0; i < issueLabels.Length; i++)
        {
            int severity = i;
            Button button = CreateButton($"Playtest Issue Severity {issueLabels[i]}", panel.transform, issueLabels[i], new Color32(30, 41, 59, 238), Color.white, 14);
            Stretch(button.GetComponent<RectTransform>(), new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(44f + i * 138f, -344f), new Vector2(166f + i * 138f, -298f));
            button.onClick.AddListener(() => SelectPlaytestIssueSeverity(severity));
            playtestIssueSeverityButtons[i] = button;
        }

        Text focusLabel = CreateText("Playtest Quality Focus Label", panel.transform, "주요 영역", 13, new Color32(71, 85, 105, 238), TextAnchor.MiddleLeft, FontStyle.Bold);
        Stretch(focusLabel.rectTransform, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-250f, -294f), new Vector2(-44f, -276f));

        playtestQualityFocusButton = CreateButton("Playtest Quality Focus", panel.transform, GetPlaytestQualityFocusButtonLabel(selectedPlaytestQualityFocus), new Color32(30, 41, 59, 238), Color.white, 14);
        Stretch(playtestQualityFocusButton.GetComponent<RectTransform>(), new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-250f, -344f), new Vector2(-44f, -298f));
        playtestQualityFocusButton.onClick.AddListener(() => CyclePlaytestQualityFocus(1, "focus-button"));

        Image evidencePanel = CreateRoundedPanel("Playtest Evidence Hint Panel", panel.transform, new Color(0.88f, 0.96f, 0.90f, 0.72f), 10);
        Stretch(evidencePanel.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -386f), new Vector2(-44f, -354f));

        playtestFeedbackEvidenceText = CreateText("Playtest Evidence Hint", evidencePanel.transform, "", 13, new Color32(51, 65, 85, 245), TextAnchor.MiddleLeft, FontStyle.Bold);
        playtestFeedbackEvidenceText.resizeTextForBestFit = true;
        playtestFeedbackEvidenceText.resizeTextMinSize = 10;
        playtestFeedbackEvidenceText.resizeTextMaxSize = 13;
        Stretch(playtestFeedbackEvidenceText.rectTransform, Vector2.zero, Vector2.one, new Vector2(16f, 4f), new Vector2(-16f, -4f));

        Image readinessPanel = CreateRoundedPanel("Playtest Readiness Panel", panel.transform, new Color(1f, 0.99f, 0.95f, 0.82f), 10);
        Stretch(readinessPanel.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -428f), new Vector2(-44f, -394f));

        playtestFeedbackReadinessText = CreateText("Playtest Readiness Status", readinessPanel.transform, "", 13, new Color32(71, 85, 105, 245), TextAnchor.MiddleLeft, FontStyle.Bold);
        playtestFeedbackReadinessText.resizeTextForBestFit = true;
        playtestFeedbackReadinessText.resizeTextMinSize = 10;
        playtestFeedbackReadinessText.resizeTextMaxSize = 13;
        Stretch(playtestFeedbackReadinessText.rectTransform, Vector2.zero, Vector2.one, new Vector2(16f, 4f), new Vector2(-16f, -4f));

        playtestFeedbackInput = CreatePlaytestFeedbackInput(panel.transform);
        Stretch(playtestFeedbackInput.GetComponent<RectTransform>(), Vector2.zero, Vector2.one, new Vector2(44f, 118f), new Vector2(-44f, -452f));

        playtestFeedbackStatusText = CreateText("Playtest Feedback Status", panel.transform, "이 컴퓨터에만 저장되는 메모입니다.", 14, new Color32(71, 85, 105, 255), TextAnchor.UpperLeft, FontStyle.Normal);
        Stretch(playtestFeedbackStatusText.rectTransform, Vector2.zero, Vector2.one, new Vector2(44f, 88f), new Vector2(-44f, -500f));

        Button folderButton = CreateButton("Playtest Feedback Folder", panel.transform, "폴더 열기", new Color32(30, 41, 59, 238), Color.white, 15);
        Stretch(folderButton.GetComponent<RectTransform>(), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(44f, 38f), new Vector2(176f, 84f));
        folderButton.onClick.AddListener(OpenPlaytestFeedbackFolder);

        Button saveButton = CreateButton("Playtest Feedback Save", panel.transform, "저장", new Color32(146, 83, 40, 245), Color.white, 15);
        Stretch(saveButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-324f, 38f), new Vector2(-192f, 84f));
        saveButton.onClick.AddListener(SavePlaytestFeedback);

        Button closeButton = CreateButton("Playtest Feedback Close", panel.transform, "닫기", new Color32(30, 41, 59, 238), Color.white, 15);
        Stretch(closeButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-176f, 38f), new Vector2(-44f, 84f));
        closeButton.onClick.AddListener(() => SetPlaytestFeedbackOpen(false));

        SelectPlaytestRating(selectedPlaytestRating);
        SelectPlaytestCommercialReadiness(selectedPlaytestCommercialReadiness);
        SelectPlaytestIssueSeverity(selectedPlaytestIssueSeverity);
        SelectPlaytestQualityFocus(selectedPlaytestQualityFocus);
        UpdatePlaytestFeedbackEvidenceText();
        playtestFeedbackObject.SetActive(false);
    }

    private void CreateRestartConfirmOverlay(Transform parent)
    {
        Image overlay = CreatePanel("Fresh Start Confirm Overlay", parent, FocusModalOverlayColor);
        restartConfirmObject = overlay.gameObject;
        Stretch(overlay.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Image shadow = CreateRoundedPanel("Fresh Start Confirm Shadow", restartConfirmObject.transform, ModalShadowColor, 30);
        Stretch(shadow.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-330f, -170f), new Vector2(342f, 162f));

        Image panel = CreateRoundedPanel("Fresh Start Confirm Panel", restartConfirmObject.transform, new Color(0.985f, 0.965f, 0.900f, 0.99f), 30);
        Stretch(panel.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(-342f, -152f), new Vector2(330f, 180f));

        Image accent = CreateRoundedPanel("Fresh Start Confirm Accent", panel.transform, new Color32(177, 113, 58, 235), 7);
        Stretch(accent.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -76f), new Vector2(-44f, -66f));

        Text title = CreateText("Fresh Start Confirm Title", panel.transform, "처음부터 시작할까요?", 28, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Bold);
        Stretch(title.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(44f, -54f), new Vector2(-44f, -14f));

        Text body = CreateText(
            "Fresh Start Confirm Body",
            panel.transform,
            "현재 이어하기 데이터와 진행 중인 대화 메모가 지워집니다.\n기록함에 저장한 마무리 기록은 남습니다.",
            17,
            new Color32(51, 65, 85, 255),
            TextAnchor.UpperLeft,
            FontStyle.Normal);
        body.lineSpacing = 1.12f;
        Stretch(body.rectTransform, Vector2.zero, Vector2.one, new Vector2(44f, 112f), new Vector2(-44f, -126f));

        Button confirmButton = CreateButton("Fresh Start Confirm Button", panel.transform, "새로 시작", new Color32(146, 83, 40, 245), Color.white, 17);
        Stretch(confirmButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-304f, 42f), new Vector2(-166f, 90f));
        confirmButton.onClick.AddListener(() =>
        {
            if (pendingFreshStartStoryMode)
            {
                StartFreshStoryMode();
            }
            else
            {
                StartFreshSession(pendingFreshStartWithPhone);
            }
        });

        Button cancelButton = CreateButton("Fresh Start Cancel Button", panel.transform, "취소", new Color32(30, 41, 59, 238), Color.white, 17);
        Stretch(cancelButton.GetComponent<RectTransform>(), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(-148f, 42f), new Vector2(-44f, 90f));
        cancelButton.onClick.AddListener(() => SetRestartConfirmOpen(false));

        restartConfirmObject.SetActive(false);
    }

    private void StartSession(bool openQuestionPhone)
    {
        if (!EnsureServerReadyForStart()) return;
        if (startMenuObject != null) startMenuObject.SetActive(false);
        SetPauseMenuOpen(false);
        SetSettingsMenuOpen(false);
        SetAboutMenuOpen(false);
        if (closingCardObject != null) closingCardObject.SetActive(false);
        if (memoryBookObject != null) memoryBookObject.SetActive(false);
        if (firstImpressionObject != null) firstImpressionObject.SetActive(false);
        if (playtestFeedbackObject != null) playtestFeedbackObject.SetActive(false);
        CloseHotspotPreview();
        SetRecordArchiveOpen(false);
        SetRestartConfirmOpen(false);
        SetQuestionNoteOpen(openQuestionPhone);
        statusText.text = openQuestionPhone ? "질문 노트에서 주제를 고를 수 있습니다" : "인터뷰 시작";
        SetDirectInputOpen(false, false);
    }

    private void RequestFreshStart(bool openQuestionPhone)
    {
        if (!EnsureServerReadyForStart()) return;
        pendingFreshStartStoryMode = false;
        pendingFreshStartWithPhone = openQuestionPhone;
        if (HasProgressToDiscard())
        {
            SetRestartConfirmOpen(true);
            return;
        }

        StartFreshSession(openQuestionPhone);
    }

    private void RequestStoryMode()
    {
        if (!EnsureServerReadyForStart()) return;
        pendingFreshStartStoryMode = true;
        pendingFreshStartWithPhone = false;
        if (HasProgressToDiscard())
        {
            SetRestartConfirmOpen(true);
            return;
        }

        StartFreshStoryMode();
    }

    private bool HasProgressToDiscard()
    {
        return HasSavedSession()
            || conversationTurns > 0
            || discoveredThemes.Count > 0
            || !string.IsNullOrWhiteSpace(firstImpression)
            || !string.IsNullOrWhiteSpace(logBuilder.ToString());
    }

    private void StartFreshSession(bool openQuestionPhone)
    {
        if (!EnsureServerReadyForStart()) return;
        SetRestartConfirmOpen(false);
        StopStoryMode(null);
        ResetSession();
        SetPauseMenuOpen(false);
        StartSession(false);
        StartOpeningStoryMode(openQuestionPhone);
    }

    private void StartFreshStoryMode()
    {
        if (!EnsureServerReadyForStart()) return;
        SetRestartConfirmOpen(false);
        StopStoryMode(null);
        ResetSession();
        SetPauseMenuOpen(false);
        StartSession(false);
        firstImpression = "이야기 보기";
        StartStoryMode();
    }

    private void StartOpeningStoryMode(bool openQuestionPhoneAfterChoice)
    {
        if (storyModeCoroutine != null)
        {
            StopCoroutine(storyModeCoroutine);
            storyModeCoroutine = null;
        }

        pendingOpeningStoryQuestionPhone = openQuestionPhoneAfterChoice;
        pendingFirstImpressionOpenQuestionPhone = openQuestionPhoneAfterChoice;
        openingStoryModeActive = true;
        storyModeActive = true;
        storyModeAdvanceRequested = false;
        lastStoryModeShortcutAction = "opening-start";
        storyModeIndex = 0;
        storyModeCoroutine = StartCoroutine(PlayOpeningStoryMode());
    }

    private IEnumerator PlayOpeningStoryMode()
    {
        busy = true;
        CloseHotspotPreview();
        SetQuestionNoteOpen(false);
        SetFlowButtonsInteractable(false);
        SetStoryModeInterface(true);
        if (statusText != null) statusText.text = "먼저 이 사람이 누구인지 충분히 듣고, 그다음 질문을 고릅니다.";

        for (int i = 0; i < openingStoryLines.Length; i++)
        {
            if (!storyModeActive || !openingStoryModeActive) yield break;

            storyModeIndex = i;
            storyModeAdvanceRequested = false;
            string theme = i < openingStoryThemes.Length ? openingStoryThemes[i] : "일상";
            string line = openingStoryLines[i];
            currentStoryModeBeatLine = BuildOpeningStoryBeatLine(i);
            currentStoryModePaceLine = BuildStoryModePaceLine(Mathf.Min(i, storyModePaceCues.Length - 1));

            AppendMessage("이야기", line, "#0f766e");
            lastTheme = theme;
            lastEvidenceLine = $"{theme} 도입 장면을 먼저 봤습니다. {currentStoryModeBeatLine}";
            ApplyStoryModeSceneDirection(Mathf.Min(i, storyModeThemes.Length - 1), theme);
            SetExpression(ClassifyExpression(theme, line));
            PresentAssistant(line, i == 0 ? "먼저 듣는 이야기" : "이어지는 이야기");
            ShowSceneFocus(GetSceneFocusLabelForTheme(theme), GetSceneFocusPositionForTheme(theme), "도입 장면", 2.0f);
            UpdateLeadPrompts(currentStoryModeBeatLine);
            UpdateActionButtons();
            UpdateNoteTabContent();
            SetFlowButtonsInteractable(false);
            SetStoryModeInterface(true);
            UpdateStoryModeControlState();

            if (statusText != null)
            {
                statusText.text = $"본인 이야기 {i + 1}/{openingStoryLines.Length} · 듣고 나서 질문을 고릅니다.";
            }

            yield return WaitForStoryModeAdvance(9999f);
        }

        FinishOpeningStoryMode();
    }

    private void FinishOpeningStoryMode()
    {
        openingStoryModeActive = false;
        storyModeActive = false;
        storyModeAdvanceRequested = false;
        storyModeCoroutine = null;
        busy = false;
        currentStoryModeBeatLine = "방금 본 장면에서 출발합니다.";
        currentStoryModePaceLine = string.Empty;
        ResetStoryModeSceneDirection();
        SetStoryModeInterface(false);
        SetFlowButtonsInteractable(true);
        UpdateActionButtons();
        if (sendButton != null) sendButton.interactable = serverReady;
        UpdateMicButtonState();
        firstImpression = string.Empty;
        activeQuestionCategory = string.Empty;
        activeCategoryQuestionCount = 0;
        UpdateLeadPrompts("전체 기록에서 중요한 질문을 먼저 골랐습니다.", BuildLeadQuestionSet(null));
        SetQuestionNoteOpen(pendingOpeningStoryQuestionPhone);
        UpdateNoteTabContent();
        UpdateClosingSummary();
        if (statusText != null) statusText.text = "이야기를 다 들었습니다 · 바로 질문을 골라 주세요";
        SaveSession();
    }

    private string BuildOpeningStoryBeatLine(int index)
    {
        switch (index)
        {
            case 0:
                return "겉: 이동 도구 · 속: 회사원, 박사과정생, 자취하는 사람";
            case 1:
                return "겉: 목발 · 속: 하루를 밖으로 이어주는 준비";
            case 2:
                return "겉: 도움 받는 순간 · 속: 먼저 묻고 조율하는 관계";
            case 3:
                return "겉: 책상 · 속: 일과 공부를 이어가는 자기 몫";
            case 4:
                return "겉: 자취방 · 속: 생활을 직접 정하는 독립";
            default:
                return "겉: 취미 · 속: 쉬고 좋아하는 것까지 있는 사람";
        }
    }

    private void ShowFirstImpressionChoice(bool openQuestionPhoneAfterChoice)
    {
        pendingFirstImpressionOpenQuestionPhone = openQuestionPhoneAfterChoice;
        if (firstImpressionObject != null)
        {
            firstImpressionObject.SetActive(true);
            firstImpressionObject.transform.SetAsLastSibling();
            SelectFirstInteractable(firstImpressionObject, "First Impression 목발", "First Impression 책상", "First Impression 표정");
        }
        if (firstImpressionPromptText != null)
        {
            firstImpressionPromptText.text = openQuestionPhoneAfterChoice
                ? "이제 방금 들은 이야기에서 더 묻고 싶은 장면을 고르세요. 정답이 아니라 질문의 출발점입니다. 고른 장면은 질문 노트 첫 장에 남습니다."
                : "이제 방금 들은 이야기에서 더 묻고 싶은 장면을 고르세요. 겉으로 보인 단서를 고르면, 연결된 생활 장면에서 질문을 시작합니다.";
        }
        SetFlowButtonsInteractable(false);
        if (sendButton != null) sendButton.interactable = false;
        if (micButton != null) micButton.interactable = false;
        if (statusText != null) statusText.text = "첫인상 선택";
    }

    private void SelectFirstImpression(string value)
    {
        if (openingStoryModeActive || storyModeActive || storyModeCoroutine != null)
        {
            StopStoryMode(null);
        }

        firstImpression = string.IsNullOrWhiteSpace(value) ? "목발" : value.Trim();
        if (firstImpressionObject != null) firstImpressionObject.SetActive(false);

        string line = BuildFirstImpressionOpening(firstImpression);
        PresentAssistant(line, "첫 인상");
        AppendMessage("첫 인상", $"{firstImpression}을 먼저 보았습니다.", "#92400e");
        lastEvidenceLine = $"처음 본 것: {firstImpression}. 이후 대화에서 그 장면이 생활과 어떻게 이어지는지 확인합니다. {BuildFirstImpressionArcLine()}";
        UpdateLeadPrompts("첫 인상에서 이어지는 질문입니다.", BuildFirstImpressionQuestions(firstImpression));
        SetQuestionNoteOpen(true);
        SetFlowButtonsInteractable(true);
        UpdateActionButtons();
        UpdateNoteTabContent();
        UpdateClosingSummary();
        if (sendButton != null) sendButton.interactable = serverReady;
        UpdateMicButtonState();
        if (statusText != null) statusText.text = $"처음 본 것: {firstImpression}";
        SaveSession();
    }

    private string BuildFirstImpressionOpening(string value)
    {
        if (string.Equals(value, "목발", StringComparison.Ordinal))
        {
            return "목발을 골랐다면 이동 준비부터 물어보셔도 좋아요. 처음 가는 곳을 어떻게 확인하는지, 도움이 필요한 순간을 어떻게 맞춰 가는지 이어서 물어봐 주세요.";
        }
        if (string.Equals(value, "책상", StringComparison.Ordinal))
        {
            return "책상이 먼저 궁금하셨다면, 제 일과 공부, 정리하는 시간이 먼저 눈에 들어온 거예요. 이제 직장 일과 박사과정은 물론, 그 사이사이의 이동과 쉬는 시간까지 이어서 물어보실 수 있어요.";
        }
        if (string.Equals(value, "표정", StringComparison.Ordinal))
        {
            return "표정이 먼저 궁금하셨다면, 무엇보다 '사람'을 먼저 보신 거예요. 이제 그 표정 뒤에 있는 평범한 하루, 그러니까 일과 이동과 취미가 어떻게 한 사람 안에 같이 담기는지 물어봐 주세요.";
        }
        return "방금 들으신 이야기에서 마음에 걸린 장면을 하나 붙잡고, 그게 어떤 생활로 이어지는지 같이 물어가 볼게요.";
    }

    private string BuildFirstImpressionOptionLabel(string value)
    {
        if (string.Equals(value, "목발", StringComparison.Ordinal)) return "목발\n이동과 도움 묻기";
        if (string.Equals(value, "책상", StringComparison.Ordinal)) return "책상\n일과 공부 묻기";
        if (string.Equals(value, "표정", StringComparison.Ordinal)) return "표정\n평범한 하루 묻기";
        return value;
    }

    private string GetThemeForFirstImpressionOption(string value)
    {
        if (string.Equals(value, "목발", StringComparison.Ordinal)) return "이동";
        if (string.Equals(value, "책상", StringComparison.Ordinal)) return "일과 공부";
        if (string.Equals(value, "표정", StringComparison.Ordinal)) return "일상";
        return string.Empty;
    }

    private string BuildFirstImpressionOptionMapLine()
    {
        if (firstImpressionOptions == null || firstImpressionOptions.Length == 0) return string.Empty;

        List<string> pairs = new List<string>();
        for (int i = 0; i < firstImpressionOptions.Length; i++)
        {
            string option = firstImpressionOptions[i];
            string theme = GetThemeForFirstImpressionOption(option);
            if (!string.IsNullOrWhiteSpace(theme))
            {
                pairs.Add($"{option} -> {theme}");
            }
        }

        return string.Join(" · ", pairs.ToArray());
    }

    private string[] BuildFirstImpressionQuestions(string value)
    {
        if (string.Equals(value, "목발", StringComparison.Ordinal))
        {
            return new[]
            {
                "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?",
                "목발을 보고 들어온 관람객이 나갈 때는 무엇을 함께 기억하면 좋을까요?",
                "도움을 주기 전에 어떤 말로 먼저 물어보는 게 편한가요?"
            };
        }
        if (string.Equals(value, "책상", StringComparison.Ordinal))
        {
            return new[]
            {
                "책상 앞에서 직장 일과 박사과정 공부는 어떻게 이어지나요?",
                "노트북과 메모는 이동 이야기 너머의 어떤 생활을 보여주나요?",
                "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?"
            };
        }
        return new[]
        {
            "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?",
            "도움을 받을 때 설명할 시간이 필요하다는 말은 어떤 뜻인가요?",
            "게임과 코인노래방 같은 취미가 같이 보여야 하는 이유는 무엇인가요?"
        };
    }

    private string BuildFirstImpressionTargetQuestion()
    {
        string theme = GetThemeForFirstImpression();
        if (string.IsNullOrWhiteSpace(firstImpression) || string.IsNullOrWhiteSpace(theme)) return string.Empty;

        int index = Array.IndexOf(memoryThemes, theme);
        bool deep = index >= 0 && deepMemoryUnlocked != null && index < deepMemoryUnlocked.Length && deepMemoryUnlocked[index];
        if (deep) return string.Empty;

        if (string.Equals(firstImpression, "목발", StringComparison.Ordinal))
        {
            return "목발을 짚고 하루를 시작할 때 가장 먼저 신경 쓰는 장면은 무엇인가요?";
        }
        if (string.Equals(firstImpression, "책상", StringComparison.Ordinal))
        {
            return "책상 앞에서 직장 일과 박사과정 공부는 어떻게 이어지나요?";
        }
        if (string.Equals(firstImpression, "표정", StringComparison.Ordinal))
        {
            return "평범한 사람으로 기억되고 싶다는 말은 어떤 장면까지 봐 달라는 뜻인가요?";
        }

        return $"처음 본 {firstImpression}이 {theme} 생활과 어떻게 이어지나요?";
    }

    private void SetRestartConfirmOpen(bool open)
    {
        if (restartConfirmObject == null) return;

        restartConfirmObject.SetActive(open);
        if (open)
        {
            restartConfirmObject.transform.SetAsLastSibling();
            if (inputField != null) inputField.DeactivateInputField();
            SelectFirstInteractable(restartConfirmObject, "Fresh Start Cancel Button", "Fresh Start Confirm Button");
            statusText.text = pendingFreshStartStoryMode ? "이야기 모드 시작 확인" : "처음부터 확인";
        }
        else
        {
            ClearSelectionIfInside(restartConfirmObject);
        }

        ShowHotspotLabels();
    }

    private bool HasSavedSession()
    {
        SaveState state;
        return TryReadSavedState(out state);
    }

    private void UpdateContinueButton()
    {
        if (continueButton == null && startSavePreviewText == null) return;

        if (!EnableSessionResume)
        {
            if (continueButton != null)
            {
                continueButton.gameObject.SetActive(false);
                continueButton.interactable = false;
            }

            if (startMenuFlowPanel != null)
            {
                startMenuFlowPanel.gameObject.SetActive(false);
            }

            if (startButton != null)
            {
                Text label = startButton.GetComponentInChildren<Text>();
                if (label != null) label.text = "처음부터 시작";
                Stretch(
                    startButton.GetComponent<RectTransform>(),
                    new Vector2(0f, 0f),
                    new Vector2(0f, 0f),
                    new Vector2(140f, 560f),
                    new Vector2(544f, 612f));
                SetButtonColor(
                    startButton,
                    new Color(0.42f, 0.25f, 0.13f, 0.82f),
                    new Color32(255, 240, 210, 250));
            }

            if (startNoteButton != null)
            {
                startNoteButton.gameObject.SetActive(true);
                Text label = startNoteButton.GetComponentInChildren<Text>();
                if (label != null) label.text = "질문 노트";
                Stretch(
                    startNoteButton.GetComponent<RectTransform>(),
                    new Vector2(0f, 0f),
                    new Vector2(0f, 0f),
                    new Vector2(140f, 500f),
                    new Vector2(544f, 552f));
                SetButtonColor(
                    startNoteButton,
                    new Color(0.08f, 0.06f, 0.045f, 0.54f),
                    new Color32(236, 224, 198, 232));
            }

            if (startStoryButton != null)
            {
                startStoryButton.gameObject.SetActive(false);
            }

            if (startSavePreviewText != null)
            {
                startSavePreviewText.text = string.Empty;
            }

            ApplyServerAvailabilityToStartButtons();
            return;
        }

        SaveState state;
        bool hasSave = TryReadSavedState(out state);

        if (continueButton != null)
        {
            continueButton.gameObject.SetActive(hasSave);
            continueButton.interactable = hasSave && serverReady;
            Text label = continueButton.GetComponentInChildren<Text>();
            if (label != null) label.text = "이어하기";

            SetButtonColor(
                continueButton,
                new Color(0.70f, 0.44f, 0.23f, 0.82f),
                new Color32(255, 240, 210, 250));

            Stretch(
                continueButton.GetComponent<RectTransform>(),
                new Vector2(0f, 0f),
                new Vector2(0f, 0f),
                new Vector2(140f, 560f),
                new Vector2(544f, 612f));
        }

        if (startMenuFlowPanel != null)
        {
            startMenuFlowPanel.gameObject.SetActive(hasSave);
        }

        if (startButton != null)
        {
            Text label = startButton.GetComponentInChildren<Text>();
            if (label != null) label.text = hasSave ? "처음부터 다시" : "처음부터 시작";

            Stretch(
                startButton.GetComponent<RectTransform>(),
                new Vector2(0f, 0f),
                new Vector2(0f, 0f),
                hasSave ? new Vector2(140f, 500f) : new Vector2(140f, 560f),
                hasSave ? new Vector2(544f, 552f) : new Vector2(544f, 612f));

            SetButtonColor(
                startButton,
                hasSave ? new Color(0.08f, 0.06f, 0.045f, 0.54f) : new Color(0.42f, 0.25f, 0.13f, 0.82f),
                hasSave ? new Color32(236, 224, 198, 232) : new Color32(255, 240, 210, 250));
        }

        if (startNoteButton != null)
        {
            startNoteButton.gameObject.SetActive(true);
            Text label = startNoteButton.GetComponentInChildren<Text>();
            if (label != null) label.text = "질문 노트";

            Stretch(
                startNoteButton.GetComponent<RectTransform>(),
                new Vector2(0f, 0f),
                new Vector2(0f, 0f),
                hasSave ? new Vector2(140f, 440f) : new Vector2(140f, 500f),
                hasSave ? new Vector2(544f, 492f) : new Vector2(544f, 552f));

            SetButtonColor(
                startNoteButton,
                new Color(0.08f, 0.06f, 0.045f, 0.54f),
                new Color32(236, 224, 198, 232));
        }

        if (startStoryButton != null)
        {
            startStoryButton.gameObject.SetActive(false);
        }

        if (startSavePreviewText != null)
        {
            startSavePreviewText.text = $"이어하기 가능 · {BuildStartSavePreview(state)}";
            startSavePreviewText.color = hasSave ? new Color32(255, 236, 198, 226) : new Color32(236, 224, 198, 190);
        }

        ApplyServerAvailabilityToStartButtons();
    }

    private bool TryReadSavedState(out SaveState state)
    {
        state = null;
        if (!EnableSessionResume) return false;
        string raw = PlayerPrefs.GetString(SaveKey, string.Empty);
        if (string.IsNullOrWhiteSpace(raw)) return false;

        try
        {
            state = JsonUtility.FromJson<SaveState>(raw);
        }
        catch (Exception)
        {
            state = null;
            return false;
        }

        return state != null && (state.conversationTurns > 0 || !string.IsNullOrWhiteSpace(state.firstImpression));
    }

    private string BuildStartSavePreview(SaveState state)
    {
        int questions = Mathf.Clamp(state != null ? state.conversationTurns : 0, 0, RequiredQuestionCount);
        string progress = questions >= RequiredQuestionCount ? "마무리 가능" : $"질문 {questions}/{RequiredQuestionCount}";
        return $"지난 대화 · {progress}";
    }

    private bool EnsureServerReadyForStart()
    {
        if (serverReady) return true;

        if (!serverStatusKnown && serverStatusCoroutine == null)
        {
            RefreshServerStatus();
        }

        ShowServerRequiredBlock();
        return false;
    }

    private void ShowServerRequiredBlock()
    {
        string detail = string.IsNullOrWhiteSpace(serverRequiredMessage) ? ServerRequiredBlockedText : serverRequiredMessage;
        statusText.text = serverStatusKnown ? "서버 연결 필요" : "서버 확인 중";
        PresentAssistant($"서버가 정상 연결되지 않아 실행할 수 없습니다.\n\n{detail}", "서버 연결 필요");
        PlaySound(errorClip);
        SetFlowButtonsInteractable(false);
        if (sendButton != null) sendButton.interactable = false;
        if (micButton != null) micButton.interactable = false;
        ApplyServerAvailabilityToUi();
    }

    private static bool IsServerConfigReady(ServerConfigResponse config)
    {
        return config != null && config.apiAvailable && config.chatModelReady;
    }

    private void SetServerAvailability(bool ready, bool known, string message)
    {
        serverReady = ready;
        serverStatusKnown = known;
        serverRequiredMessage = string.IsNullOrWhiteSpace(message)
            ? (ready ? "서버 연결됨" : ServerRequiredBlockedText)
            : message;
        ApplyServerAvailabilityToUi();
    }

    private void ApplyServerAvailabilityToUi()
    {
        ApplyServerAvailabilityToStartButtons();

        if (!serverReady)
        {
            SetLeadButtonsInteractable(false);
            if (sendButton != null && !busy) sendButton.interactable = false;
        }

        UpdateMicButtonState();
    }

    private void ApplyServerAvailabilityToStartButtons()
    {
        if (startButton != null) startButton.interactable = serverReady;
        if (startNoteButton != null) startNoteButton.interactable = serverReady;
        if (startStoryButton != null) startStoryButton.interactable = serverReady;

        if (continueButton != null && continueButton.gameObject.activeSelf)
        {
            continueButton.interactable = serverReady;
        }

        if (startObjectiveText != null)
        {
            startObjectiveText.text = serverReady ? BuildStartObjectiveLine() : BuildStartServerRequiredLine();
        }
    }

    private string BuildStartServerRequiredLine()
    {
        string detail = string.IsNullOrWhiteSpace(serverRequiredMessage) ? ServerRequiredBlockedText : serverRequiredMessage;
        return $"서버 연결 필요: {ShortenForCard(detail, 42)}\n연결되면 시작할 수 있습니다.";
    }

    private int CountSavedThemes(SaveState state)
    {
        if (state == null || state.discoveredThemes == null) return 0;

        HashSet<string> themes = new HashSet<string>();
        for (int i = 0; i < state.discoveredThemes.Length; i++)
        {
            string theme = CanonicalTheme(state.discoveredThemes[i]);
            if (!string.IsNullOrWhiteSpace(theme)) themes.Add(theme);
        }

        return Mathf.Clamp(themes.Count, 0, memoryThemes.Length);
    }

    private string LastSavedThemeLabel(SaveState state)
    {
        if (state == null) return string.Empty;

        string theme = CanonicalTheme(state.lastTheme);
        if (string.IsNullOrWhiteSpace(theme) && state.discoveredThemes != null)
        {
            for (int i = state.discoveredThemes.Length - 1; i >= 0; i--)
            {
                theme = CanonicalTheme(state.discoveredThemes[i]);
                if (!string.IsNullOrWhiteSpace(theme)) break;
            }
        }

        return theme;
    }

    private void SaveSession()
    {
        if (!EnableSessionResume) return;
        if (conversationTurns <= 0 && discoveredThemes.Count <= 0 && string.IsNullOrWhiteSpace(firstImpression)) return;
        EnsureMemoryNotes();
        EnsureAttitudeCounts();

        SaveState state = new SaveState
        {
            history = history.ToArray(),
            discoveredThemes = new List<string>(discoveredThemes).ToArray(),
            memoryNotes = memoryNotes ?? new string[memoryThemes.Length],
            deepMemoryUnlocked = deepMemoryUnlocked ?? new bool[memoryThemes.Length],
            currentLeadQuestions = currentLeadQuestions ?? BuildLeadQuestionSet(null),
            lastTheme = lastTheme,
            lastEvidenceLine = lastEvidenceLine,
            lastAnswerSource = lastAnswerSource,
            lastServerError = lastServerError,
            firstImpression = firstImpression,
            attitudeCounts = attitudeCounts ?? new int[attitudeNames.Length],
            lastQuestionAttitude = lastQuestionAttitude,
            activeQuestionCategory = string.Empty,
            activeCategoryQuestionCount = Mathf.Clamp(conversationTurns, 0, RequiredQuestionCount),
            lastChoiceConsequenceLine = lastChoiceConsequenceLine,
            leadIntro = leadText != null ? leadText.text : string.Empty,
            speaker = speakerText != null ? speakerText.text : "답변",
            dialogue = dialogueText != null ? dialogueText.text : OpeningText,
            log = logBuilder.ToString(),
            conversationTurns = conversationTurns,
            chatEntryCount = chatEntryCount,
            expression = (int)currentExpression,
            dialogueSizeLevel = dialogueSizeLevel,
            selectedClosingIndex = selectedClosingIndex,
            closingSensitiveQuestionAnswered = closingSensitiveQuestionAnswered,
            selectedClosingSensitiveQuestion = selectedClosingSensitiveQuestion,
            selectedClosingSensitiveAnswer = selectedClosingSensitiveAnswer,
            closingMessageToInterviewee = GetClosingMessageToInterviewee()
        };

        PlayerPrefs.SetString(SaveKey, JsonUtility.ToJson(state));
        PlayerPrefs.Save();
        UpdateContinueButton();
    }

    private void SeedSmokeSavedSession()
    {
        if (!EnableSessionResume) return;

        string[] seededThemes = { "이동", "도움", "일과 공부" };
        string[] seededNotes = new string[memoryThemes.Length];
        for (int i = 0; i < seededThemes.Length; i++)
        {
            int themeIndex = Array.IndexOf(memoryThemes, seededThemes[i]);
            if (themeIndex >= 0)
            {
                seededNotes[themeIndex] = BuildMemoryNote($"{seededThemes[i]}에 대해 이어 묻던 중입니다.", string.Empty);
            }
        }

        SaveState state = new SaveState
        {
            history = new[]
            {
                new ChatMessage { role = "user", content = "처음 가는 곳에서는 무엇부터 확인하나요?" },
                new ChatMessage { role = "assistant", content = "처음 가는 곳에서는 입구, 엘리베이터, 화장실 위치처럼 하루를 덜 지치게 해 주는 정보부터 확인하게 돼요." },
                new ChatMessage { role = "user", content = "도움을 받을 때는 어떤 방식이 편한가요?" },
                new ChatMessage { role = "assistant", content = "무엇이 필요한지 먼저 물어봐 주고, 제가 정한 방식에 맞춰 주는 도움이 편해요." }
            },
            discoveredThemes = seededThemes,
            memoryNotes = seededNotes,
            deepMemoryUnlocked = new[] { false, true, true, true, false, false },
            currentLeadQuestions = new[]
            {
                "직장에서는 어떤 도움 방식이 편했나요?",
                "공부와 일을 이어갈 때 책상은 어떤 의미였나요?",
                "자취방이 독립에 어떤 영향을 줬나요?"
            },
            lastTheme = "일과 공부",
            lastEvidenceLine = "직장과 공부 이야기는 도움을 받는 장면을 넘어, 자기 몫을 이어가는 장면으로 남습니다.",
            firstImpression = "목발",
            attitudeCounts = new[] { 1, 1, 1, 0 },
            lastQuestionAttitude = "호기심",
            activeQuestionCategory = string.Empty,
            activeCategoryQuestionCount = 3,
            lastChoiceConsequenceLine = "질문 결과: 일과 공부 기록 · 단서와 생활이 맞물렸습니다.",
            leadIntro = "지난 대화에서 이어갈 질문입니다.",
            speaker = "지난 답변",
            dialogue = "저장된 대화에서는 이동, 도움, 일과 공부 이야기를 이어가던 중입니다.",
            log = "나: 처음 가는 곳에서는 무엇부터 확인하나요?\n상대: 입구, 엘리베이터, 화장실 위치처럼 하루를 덜 지치게 해 주는 정보부터 확인하게 돼요.\n\n나: 도움을 받을 때는 어떤 방식이 편한가요?\n상대: 무엇이 필요한지 먼저 물어봐 주고, 제가 정한 방식에 맞춰 주는 도움이 편해요.",
            conversationTurns = 3,
            chatEntryCount = 4,
            expression = (int)ExpressionState.Idle,
            dialogueSizeLevel = dialogueSizeLevel,
            selectedClosingIndex = selectedClosingIndex,
            closingSensitiveQuestionAnswered = false,
            selectedClosingSensitiveQuestion = string.Empty,
            selectedClosingSensitiveAnswer = string.Empty,
            closingMessageToInterviewee = string.Empty
        };

        PlayerPrefs.SetString(SaveKey, JsonUtility.ToJson(state));
        PlayerPrefs.Save();
        UpdateContinueButton();
    }

    private bool LoadSavedSession()
    {
        if (!EnableSessionResume) return false;

        string raw = PlayerPrefs.GetString(SaveKey, string.Empty);
        if (string.IsNullOrWhiteSpace(raw)) return false;

        SaveState state;
        try
        {
            state = JsonUtility.FromJson<SaveState>(raw);
        }
        catch (Exception)
        {
            ClearSavedSession();
            return false;
        }

        if (state == null || (state.conversationTurns <= 0 && string.IsNullOrWhiteSpace(state.firstImpression))) return false;

        history.Clear();
        if (state.history != null)
        {
            history.AddRange(state.history);
        }

        discoveredThemes.Clear();
        if (state.discoveredThemes != null)
        {
            foreach (string theme in state.discoveredThemes)
            {
                string canonical = CanonicalTheme(theme);
                if (!string.IsNullOrWhiteSpace(canonical)) discoveredThemes.Add(canonical);
            }
        }
        memoryCompletionCelebrated = discoveredThemes.Count >= memoryThemes.Length;

        EnsureMemoryNotes();
        Array.Clear(memoryNotes, 0, memoryNotes.Length);
        if (state.memoryNotes != null)
        {
            Array.Copy(state.memoryNotes, memoryNotes, Mathf.Min(state.memoryNotes.Length, memoryNotes.Length));
        }
        Array.Clear(deepMemoryUnlocked, 0, deepMemoryUnlocked.Length);
        if (state.deepMemoryUnlocked != null)
        {
            Array.Copy(state.deepMemoryUnlocked, deepMemoryUnlocked, Mathf.Min(state.deepMemoryUnlocked.Length, deepMemoryUnlocked.Length));
        }

        logBuilder.Length = 0;
        if (!string.IsNullOrEmpty(state.log)) logBuilder.Append(state.log);
        if (chatLogText != null) chatLogText.text = logBuilder.ToString();

        conversationTurns = Mathf.Max(0, state.conversationTurns);
        chatEntryCount = Mathf.Max(0, state.chatEntryCount);
        lastTheme = string.IsNullOrWhiteSpace(state.lastTheme) ? "시작" : state.lastTheme;
        lastEvidenceLine = string.IsNullOrWhiteSpace(state.lastEvidenceLine) ? "아직 표시할 자료가 없습니다." : state.lastEvidenceLine;
        lastAnswerSource = string.IsNullOrWhiteSpace(state.lastAnswerSource) ? "대기" : state.lastAnswerSource;
        lastServerError = state.lastServerError ?? string.Empty;
        firstImpression = string.IsNullOrWhiteSpace(state.firstImpression) ? string.Empty : state.firstImpression;
        EnsureAttitudeCounts();
        Array.Clear(attitudeCounts, 0, attitudeCounts.Length);
        if (state.attitudeCounts != null)
        {
            Array.Copy(state.attitudeCounts, attitudeCounts, Mathf.Min(state.attitudeCounts.Length, attitudeCounts.Length));
        }
        lastQuestionAttitude = string.IsNullOrWhiteSpace(state.lastQuestionAttitude) ? string.Empty : state.lastQuestionAttitude;
        activeQuestionCategory = string.Empty;
        activeCategoryQuestionCount = Mathf.Clamp(conversationTurns, 0, RequiredQuestionCount);
        lastChoiceConsequenceLine = string.IsNullOrWhiteSpace(state.lastChoiceConsequenceLine) ? string.Empty : state.lastChoiceConsequenceLine;
        currentLeadQuestions = state.currentLeadQuestions != null && state.currentLeadQuestions.Length == 3
            ? state.currentLeadQuestions
            : BuildLeadQuestionSet(null);

        int expressionIndex = Mathf.Clamp(state.expression, 0, Enum.GetValues(typeof(ExpressionState)).Length - 1);
        dialogueSizeLevel = Mathf.Clamp(state.dialogueSizeLevel, -1, 1);
        selectedClosingIndex = Mathf.Clamp(state.selectedClosingIndex, 0, closingQuotes.Length - 1);
        closingSensitiveQuestionAnswered = state.closingSensitiveQuestionAnswered;
        selectedClosingSensitiveQuestion = state.selectedClosingSensitiveQuestion ?? string.Empty;
        selectedClosingSensitiveAnswer = state.selectedClosingSensitiveAnswer ?? string.Empty;
        closingMessageToInterviewee = state.closingMessageToInterviewee ?? string.Empty;
        if (closingMessageInput != null) closingMessageInput.text = closingMessageToInterviewee;
        PlayerPrefs.SetInt(TextSizeKey, dialogueSizeLevel);
        PlayerPrefs.Save();
        ApplyDialogueTextSize(false);
        SetExpression((ExpressionState)expressionIndex);
        SelectClosingCard(selectedClosingIndex);
        PresentAssistant(string.IsNullOrWhiteSpace(state.dialogue) ? OpeningText : state.dialogue, string.IsNullOrWhiteSpace(state.speaker) ? "답변" : state.speaker);
        UpdateLeadPrompts(string.IsNullOrWhiteSpace(state.leadIntro) ? BuildLeadIntro() : state.leadIntro, BuildLeadQuestionSet(currentLeadQuestions));
        UpdateMemoryBook();
        UpdateActionButtons();
        UpdateNoteTabContent();
        SetFlowButtonsInteractable(true);
        return true;
    }

    private void ClearSavedSession()
    {
        PlayerPrefs.DeleteKey(SaveKey);
        PlayerPrefs.Save();
        UpdateContinueButton();
    }

    private void ResetSession()
    {
        StopStoryMode(null);
        ClearSavedSession();
        history.Clear();
        logBuilder.Length = 0;
        discoveredThemes.Clear();
        EnsureMemoryNotes();
        Array.Clear(memoryNotes, 0, memoryNotes.Length);
        Array.Clear(deepMemoryUnlocked, 0, deepMemoryUnlocked.Length);
        EnsureAttitudeCounts();
        Array.Clear(attitudeCounts, 0, attitudeCounts.Length);
        chatEntryCount = 0;
        leadOffset = 0;
        conversationTurns = 0;
        activeQuestionCategory = string.Empty;
        activeCategoryQuestionCount = 0;
        selectedClosingIndex = 0;
        pendingClosingSensitiveQuestion = false;
        pendingCompletionChoiceAfterDialogue = false;
        closingSensitiveQuestionAnswered = false;
        selectedClosingSensitiveQuestion = string.Empty;
        selectedClosingSensitiveAnswer = string.Empty;
        closingMessageToInterviewee = string.Empty;
        selectedMemoryCardIndex = 0;
        selectedPlaytestFeedbackGroup = 0;
        memoryCompletionCelebrated = false;
        lastSubmitFrame = -1;
        lastTheme = "시작";
        lastEvidenceLine = "아직 표시할 자료가 없습니다.";
        lastAnswerSource = "대기";
        lastServerError = string.Empty;
        firstImpression = string.Empty;
        lastQuestionAttitude = string.Empty;
        lastChoiceConsequenceLine = string.Empty;
        lastMemoryCardAction = "none";
        lastMemoryBookShortcutAction = "none";
        lastClosingCardShortcutAction = "none";
        lastRecordArchiveShortcutAction = "none";
        lastPlaytestFeedbackShortcutAction = "none";
        lastStartMenuAction = "none";
        lastSavedEndingRecordPath = string.Empty;
        lastSavedIntervieweeMessagePath = string.Empty;
        currentLeadQuestions = BuildLeadQuestionSet(null);
        busy = false;

        if (recording)
        {
            Microphone.End(micDevice);
            recording = false;
        }

        if (inputField != null) inputField.text = string.Empty;
        if (closingMessageInput != null) closingMessageInput.text = string.Empty;
        if (closingMessageValidationText != null)
        {
            closingMessageValidationText.text = "남길 말을 먼저 입력해 주세요.";
            closingMessageValidationText.color = new Color32(124, 45, 18, 245);
        }
        SetDirectInputOpen(false, false);
        if (chatLogText != null) chatLogText.text = string.Empty;
        if (closingCardObject != null) closingCardObject.SetActive(false);
        if (memoryBookObject != null) memoryBookObject.SetActive(false);
        if (firstImpressionObject != null) firstImpressionObject.SetActive(false);
        if (playtestFeedbackObject != null) playtestFeedbackObject.SetActive(false);
        if (playtestFeedbackInput != null) playtestFeedbackInput.text = string.Empty;
        if (memoryUnlockToastObject != null) memoryUnlockToastObject.SetActive(false);
        if (memoryBookButton != null) memoryBookButton.GetComponent<RectTransform>().localScale = Vector3.one;
        CloseHotspotPreview();
        SetQuestionNoteOpen(false);
        SetExpression(ExpressionState.Idle);
        PresentAssistant(OpeningText, "오늘의 시작");
        UpdateLeadPrompts("제가 먼저 이런 순서로 이야기를 열어볼게요.");
        UpdateMemoryBook();
        UpdateActionButtons();
        UpdateNoteTabContent();
        sendButton.interactable = true;
        UpdateMicButtonState();
        SetFlowButtonsInteractable(true);
        statusText.text = "처음부터 다시 시작";
    }

    private void ReturnToMainMenuAfterEnding()
    {
        StopStoryMode(null);
        ResetSession();

        if (completionChoiceObject != null) completionChoiceObject.SetActive(false);
        if (closingSensitiveQuestionObject != null) closingSensitiveQuestionObject.SetActive(false);
        if (closingCardObject != null) closingCardObject.SetActive(false);
        if (firstImpressionObject != null) firstImpressionObject.SetActive(false);
        if (memoryBookObject != null) memoryBookObject.SetActive(false);
        if (playtestFeedbackObject != null) playtestFeedbackObject.SetActive(false);
        CloseHotspotPreview();
        SetQuestionNoteOpen(false);
        SetRecordArchiveOpen(false);
        SetRestartConfirmOpen(false);
        SetPauseMenuOpen(false);
        SetSettingsMenuOpen(false);
        SetAboutMenuOpen(false);
        SetDirectInputOpen(false, false);

        if (startMenuObject != null)
        {
            startMenuObject.SetActive(true);
            startMenuObject.transform.SetAsLastSibling();
        }

        UpdateContinueButton();
        if (statusText != null) statusText.text = "메인 화면으로 돌아왔습니다";
        SelectFirstInteractable(startMenuObject, "Start Interview Button", "Start With Phone Button", "Start Story Mode Button");
    }

    private void StartStoryMode()
    {
        if (storyModeCoroutine != null)
        {
            StopCoroutine(storyModeCoroutine);
            storyModeCoroutine = null;
        }

        storyModeActive = true;
        storyModeAdvanceRequested = false;
        lastStoryModeShortcutAction = "none";
        storyModeIndex = 0;
        storyModeCoroutine = StartCoroutine(PlayStoryMode());
    }

    private IEnumerator PlayStoryMode()
    {
        storyModeActive = true;
        busy = true;
        CloseHotspotPreview();
        SetQuestionNoteOpen(false);
        SetFlowButtonsInteractable(false);
        SetStoryModeInterface(true);
        if (statusText != null) statusText.text = "이야기 모드 진행 중 · 직접 질문하거나 Esc로 멈춤";

        for (int i = 0; i < storyModeLines.Length; i++)
        {
            if (!storyModeActive) yield break;

            storyModeIndex = i;
            storyModeAdvanceRequested = false;
            string theme = i < storyModeThemes.Length ? storyModeThemes[i] : "일상";
            string line = storyModeLines[i];
            currentStoryModeBeatLine = BuildStoryModeBeatLine(i);
            currentStoryModePaceLine = BuildStoryModePaceLine(i);

            history.Add(new ChatMessage { role = "assistant", content = line });
            TrimHistory();
            AppendMessage("이야기", line, "#0f766e");

            lastTheme = theme;
            lastEvidenceLine = $"{theme} 장면을 이야기 모드로 들었습니다. {currentStoryModeBeatLine} · {currentStoryModePaceLine}";
            ApplyStoryModeSceneDirection(i, theme);
            SetExpression(ClassifyExpression(theme, line));
            PresentAssistant(line, i == 0 ? "이야기 모드" : "이어지는 이야기");
            CollectTheme(theme, "이야기 모드", line);
            ShowSceneFocus(GetSceneFocusLabelForTheme(theme), GetSceneFocusPositionForTheme(theme), "이야기 장면", 2.2f);
            UpdateLeadPrompts(currentStoryModeBeatLine);
            UpdateActionButtons();
            UpdateNoteTabContent();
            SetFlowButtonsInteractable(false);
            SetStoryModeInterface(true);
            UpdateStoryModeControlState();
            SaveSession();

            if (statusText != null)
            {
                statusText.text = $"이야기 모드 {Mathf.Min(i + 1, storyModeLines.Length)}/{storyModeLines.Length} · {currentStoryModeBeatLine}";
            }

            yield return WaitForStoryModeAdvance(reducedMotionEnabled ? StoryModeLineDelaySeconds + 1.2f : StoryModeLineDelaySeconds);
            if (storyModeActive && !reducedMotionEnabled && i < storyModeLines.Length - 1)
            {
                if (statusText != null) statusText.text = $"잠시 장면을 남기는 중 · {BuildStoryModeQuietMomentLine(i)}";
                yield return WaitForStoryModeAdvance(GetStoryModeQuietSeconds(i));
            }
        }

        storyModeActive = false;
        storyModeAdvanceRequested = false;
        storyModeCoroutine = null;
        busy = false;
        currentStoryModeBeatLine = BuildStoryModeBeatLine(storyModeLines.Length - 1);
        currentStoryModePaceLine = BuildStoryModePaceLine(storyModeLines.Length - 1);
        ResetStoryModeSceneDirection();
        SetStoryModeInterface(false);
        SetFlowButtonsInteractable(true);
        UpdateActionButtons();
        if (sendButton != null) sendButton.interactable = true;
        if (statusText != null) statusText.text = "이야기 모드 완료 · 마무리 가능";
        SaveSession();

        yield return new WaitForSecondsRealtime(reducedMotionEnabled ? 1.2f : 1.6f);
        if (!storyModeActive)
        {
            ShowClosingCard();
        }
    }

    private void StopStoryMode(string statusMessage)
    {
        if (!storyModeActive && storyModeCoroutine == null) return;

        storyModeActive = false;
        openingStoryModeActive = false;
        storyModeAdvanceRequested = false;
        currentStoryModeBeatLine = string.Empty;
        currentStoryModePaceLine = string.Empty;
        if (storyModeCoroutine != null)
        {
            StopCoroutine(storyModeCoroutine);
            storyModeCoroutine = null;
        }

        busy = false;
        ShowHotspotLabels();
        ResetStoryModeSceneDirection();
        SetStoryModeInterface(false);
        SetFlowButtonsInteractable(true);
        UpdateActionButtons();
        UpdateMicButtonState();
        if (sendButton != null) sendButton.interactable = true;
        if (!string.IsNullOrWhiteSpace(statusMessage) && statusText != null)
        {
            statusText.text = statusMessage;
        }
        UpdateDialoguePageCue();
    }

    private string BuildStoryModeBeatLine(int index)
    {
        string outer = index >= 0 && index < storyModeOuterCues.Length ? storyModeOuterCues[index] : "겉 장면";
        string inner = index >= 0 && index < storyModeInnerCues.Length ? storyModeInnerCues[index] : "속 이야기";
        return $"겉: {outer} · 속: {inner}";
    }

    private string BuildStoryModePaceLine(int index)
    {
        string cue = index >= 0 && index < storyModePaceCues.Length ? storyModePaceCues[index] : "짧은 정적 0.8초 · 방 톤 유지 · 장면 단서에 시선 이동";
        return $"연출: {cue}";
    }

    private string BuildStoryModeQuietMomentLine(int index)
    {
        string cue = index >= 0 && index < storyModeOuterCues.Length ? storyModeOuterCues[index] : "장면";
        return $"{cue} 장면을 남깁니다";
    }

    private float GetStoryModeQuietSeconds(int index)
    {
        if (index == storyModeLines.Length - 1) return 1.0f;
        return index == 2 ? 0.9f : 0.75f;
    }

    private IEnumerator WaitForStoryModeAdvance(float seconds)
    {
        float endTime = Time.realtimeSinceStartup + Mathf.Max(0.1f, seconds);
        while (storyModeActive && Time.realtimeSinceStartup < endTime)
        {
            if (storyModeAdvanceRequested)
            {
                storyModeAdvanceRequested = false;
                yield break;
            }

            yield return null;
        }
    }

    private void RequestStoryModeAdvance()
    {
        RequestStoryModeAdvance("next-button");
    }

    private void RequestStoryModeAdvance(string source)
    {
        if (!storyModeActive) return;
        if (TryAdvanceDialoguePage()) return;

        lastStoryModeShortcutAction = string.IsNullOrWhiteSpace(source) ? "next" : source;
        storyModeAdvanceRequested = true;
        if (statusText != null)
        {
            statusText.text = "다음 장면으로 넘깁니다";
        }
    }

    private void StopStoryModeForDirectQuestion()
    {
        StopStoryModeForDirectQuestion("question-button");
    }

    private void StopStoryModeForDirectQuestion(string source)
    {
        lastStoryModeShortcutAction = string.IsNullOrWhiteSpace(source) ? "question" : source;
        if (openingStoryModeActive && string.IsNullOrWhiteSpace(firstImpression))
        {
            firstImpression = "이야기 보기";
            lastEvidenceLine = "도입 이야기를 먼저 듣고 직접 질문으로 넘어갔습니다.";
            UpdateLeadPrompts("방금 들은 이야기에서 바로 물어볼 수 있습니다.", new[]
            {
                "목발보다 먼저 있는 하루는 어떤 모습인가요?",
                "처음 가는 곳에서는 무엇부터 확인하나요?",
                "책상과 노트북은 어떤 의미인가요?"
            });
        }
        StopStoryMode("직접 질문으로 이어갑니다");
        SetDirectInputOpen(true, true);
    }

    private void SetStoryModeInterface(bool active)
    {
        if (inputField != null)
        {
            inputField.gameObject.SetActive(!active);
            if (active) inputField.DeactivateInputField();
        }

        if (sendButton != null) sendButton.gameObject.SetActive(!active);
        if (micButton != null) micButton.gameObject.SetActive(!active && directInputOpen);
        if (storyNextButton != null) storyNextButton.gameObject.SetActive(active);
        if (storyQuestionButton != null) storyQuestionButton.gameObject.SetActive(active && !openingStoryModeActive);
        if (storyFinishButton != null) storyFinishButton.gameObject.SetActive(active && !openingStoryModeActive);
        UpdateStoryModeControlState();
        UpdateLeadSlipVisibility();

        if (!active)
        {
            UpdateQuestionInputLayout();
            if (questionNoteOpen)
            {
                SetQuestionNoteOpen(true);
            }
        }
    }

    private void UpdateStoryModeControlState()
    {
        bool active = storyModeActive;
        bool canFinish = IsCompletedFiveTurnSession();

        if (storyNextButton != null)
        {
            Text label = storyNextButton.GetComponentInChildren<Text>();
            if (label != null) label.text = GetStoryModeNextButtonLabel();
            storyNextButton.interactable = active;
            SetButtonColor(
                storyNextButton,
                active ? new Color(0.70f, 0.44f, 0.23f, 0.72f) : new Color(0.93f, 0.89f, 0.80f, 0.58f),
                active ? new Color(1f, 0.96f, 0.86f, 0.96f) : new Color(0.30f, 0.24f, 0.18f, 0.64f));
        }

        if (storyQuestionButton != null)
        {
            Text label = storyQuestionButton.GetComponentInChildren<Text>();
            if (label != null) label.text = "직접 질문";
            storyQuestionButton.interactable = active && !openingStoryModeActive;
            SetButtonColor(
                storyQuestionButton,
                active && !openingStoryModeActive ? new Color(0.16f, 0.11f, 0.07f, 0.58f) : new Color(0.93f, 0.89f, 0.80f, 0.58f),
                active && !openingStoryModeActive ? new Color(1f, 0.96f, 0.86f, 0.92f) : new Color(0.30f, 0.24f, 0.18f, 0.64f));
        }

        if (storyFinishButton != null)
        {
            Text label = storyFinishButton.GetComponentInChildren<Text>();
            if (label != null) label.text = canFinish ? "마무리" : $"{RequiredQuestionCount}문답 후";
            storyFinishButton.interactable = active && canFinish;
            SetButtonColor(
                storyFinishButton,
                canFinish ? (Color)new Color32(177, 113, 58, 238) : new Color(0.12f, 0.09f, 0.06f, 0.30f),
                canFinish ? Color.white : new Color(1f, 0.96f, 0.86f, 0.72f));
        }
    }

    private string GetStoryModeNextButtonLabel()
    {
        int total = Mathf.Max(1, openingStoryModeActive ? openingStoryLines.Length : (storyModeLines != null ? storyModeLines.Length : 1));
        if (storyModeIndex >= total - 1)
        {
            return openingStoryModeActive ? "질문하기" : "마무리로";
        }

        int next = Mathf.Clamp(storyModeIndex + 2, 2, total);
        return $"다음 {next}/{total}";
    }

    private void ApplyStoryModeSceneDirection(int index, string theme)
    {
        if (avatarSceneWashImage != null)
        {
            avatarSceneWashImage.color = new Color(1f, 0.88f, 0.65f, 0f);
        }

        Vector2 focus = GetSceneFocusPositionForTheme(theme);
        ShowSceneFocus(GetSceneFocusLabelForTheme(theme), focus, index == 0 ? "첫 장면" : "다음 장면", 2.6f);
        TriggerScenePropReaction(GetSceneFocusLabelForTheme(theme), 3.0f);
    }

    private void ResetStoryModeSceneDirection()
    {
        if (avatarSceneWashImage != null)
        {
            avatarSceneWashImage.color = new Color(1f, 0.88f, 0.65f, 0f);
        }
    }

    private void HandleEscape()
    {
        if (storyModeActive)
        {
            StopStoryMode("이야기 모드를 멈췄습니다");
            return;
        }

        if (IsHotspotPreviewOpen())
        {
            CloseHotspotPreview();
            return;
        }

        if (restartConfirmObject != null && restartConfirmObject.activeSelf)
        {
            SetRestartConfirmOpen(false);
            return;
        }

        if (recordArchiveObject != null && recordArchiveObject.activeSelf)
        {
            SetRecordArchiveOpen(false);
            return;
        }

        if (playtestFeedbackObject != null && playtestFeedbackObject.activeSelf)
        {
            SetPlaytestFeedbackOpen(false);
            return;
        }

        if (aboutMenuObject != null && aboutMenuObject.activeSelf)
        {
            SetAboutMenuOpen(false);
            return;
        }

        if (startMenuObject != null && startMenuObject.activeSelf)
        {
            if (settingsMenuObject != null && settingsMenuObject.activeSelf)
            {
                SetSettingsMenuOpen(false);
            }
            return;
        }

        if (settingsMenuObject != null && settingsMenuObject.activeSelf)
        {
            SetSettingsMenuOpen(false);
            return;
        }

        if (closingCardObject != null && closingCardObject.activeSelf)
        {
            closingCardObject.SetActive(false);
            statusText.text = "마무리 카드를 닫았습니다";
            return;
        }

        if (completionChoiceObject != null && completionChoiceObject.activeSelf)
        {
            statusText.text = "5개 더 물어볼지 끝낼지 선택해 주세요";
            return;
        }

        if (closingSensitiveQuestionObject != null && closingSensitiveQuestionObject.activeSelf)
        {
            statusText.text = "마지막 질문 카드 하나를 골라 주세요";
            return;
        }

        if (memoryBookObject != null && memoryBookObject.activeSelf)
        {
            memoryBookObject.SetActive(false);
            statusText.text = "대화 메모를 닫았습니다";
            return;
        }

        if (questionNoteOpen)
        {
            SetQuestionNoteOpen(false);
            statusText.text = "질문 노트를 닫았습니다";
            return;
        }

        if (directInputOpen)
        {
            SetDirectInputOpen(false, false);
            return;
        }

        SetPauseMenuOpen(pauseMenuObject == null || !pauseMenuObject.activeSelf);
    }

    private void HandleKeyboardShortcuts()
    {
        if (IsCancelKeyDown())
        {
            HandleEscape();
            return;
        }

        if (IsHotspotPreviewOpen())
        {
            if (IsSubmitKeyDown())
            {
                SubmitPendingHotspotQuestion();
            }
            return;
        }

        if (HandleStoryModeShortcuts())
        {
            return;
        }

        if (HandleRecordArchiveShortcuts())
        {
            return;
        }

        if (HandlePlaytestFeedbackShortcuts())
        {
            return;
        }

        if (HandleClosingCardShortcuts())
        {
            return;
        }

        if (HandleMemoryBookShortcuts())
        {
            return;
        }

        if (IsTypingInTextField()) return;
        if (restartConfirmObject != null && restartConfirmObject.activeSelf) return;
        if (playtestFeedbackObject != null && playtestFeedbackObject.activeSelf) return;

        if (IsKeyDown(KeyCode.Alpha1) || IsKeyDown(KeyCode.Keypad1))
        {
            SelectNoteTabShortcut(0);
            return;
        }
        if (IsKeyDown(KeyCode.Alpha2) || IsKeyDown(KeyCode.Keypad2))
        {
            SelectNoteTabShortcut(1);
            return;
        }
        if (IsKeyDown(KeyCode.Alpha3) || IsKeyDown(KeyCode.Keypad3))
        {
            SelectNoteTabShortcut(2);
            return;
        }

        if (questionNoteOpen && (IsKeyDown(KeyCode.LeftArrow) || IsKeyDown(KeyCode.RightArrow)))
        {
            ShowNoteTab(2);
            return;
        }

        if (HandleReadingScrollShortcuts())
        {
            return;
        }

        if (HandleGamepadShortcuts())
        {
            return;
        }

        if (IsKeyDown(KeyCode.F))
        {
            RunShortcutAction("fullscreen");
        }
        else if (IsKeyDown(KeyCode.Equals) || IsKeyDown(KeyCode.Plus) || IsKeyDown(KeyCode.KeypadPlus))
        {
            RunShortcutAction("text-up");
        }
        else if (IsKeyDown(KeyCode.Minus) || IsKeyDown(KeyCode.Underscore) || IsKeyDown(KeyCode.KeypadMinus))
        {
            RunShortcutAction("text-down");
        }
        else if (HandleOpenPanelShortcutToggles())
        {
            return;
        }
        else if (HasModalShortcutBlocker())
        {
            return;
        }
        else if (IsKeyDown(KeyCode.Q))
        {
            RunShortcutAction("question");
        }
        else if (IsKeyDown(KeyCode.M))
        {
            RunShortcutAction("memory");
        }
        else if (IsKeyDown(KeyCode.R))
        {
            RunShortcutAction("records");
        }
        else if (IsKeyDown(KeyCode.S))
        {
            RunShortcutAction("settings");
        }
        else if (IsKeyDown(KeyCode.I))
        {
            RunShortcutAction("info");
        }
    }

    private bool IsKeyDown(KeyCode key)
    {
        return (smokeKeyDownOverride.HasValue && smokeKeyDownOverride.Value == key) || Input.GetKeyDown(key);
    }

    private bool IsCancelKeyDown()
    {
        return IsKeyDown(KeyCode.Escape) || IsKeyDown(KeyCode.JoystickButton1);
    }

    private bool HandleStoryModeShortcuts()
    {
        if (!storyModeActive) return false;

        if (IsKeyDown(KeyCode.RightArrow) || IsKeyDown(KeyCode.Space) || IsKeyDown(KeyCode.Return) || IsKeyDown(KeyCode.KeypadEnter))
        {
            RequestStoryModeAdvance("next-key");
            return true;
        }

        if (IsKeyDown(KeyCode.JoystickButton0) || IsKeyDown(KeyCode.JoystickButton5))
        {
            RequestStoryModeAdvance("next-gamepad");
            return true;
        }

        if (IsKeyDown(KeyCode.Q))
        {
            StopStoryModeForDirectQuestion("question-key");
            return true;
        }

        if (IsKeyDown(KeyCode.JoystickButton2))
        {
            StopStoryModeForDirectQuestion("question-gamepad");
            return true;
        }

        if (IsKeyDown(KeyCode.End) || IsKeyDown(KeyCode.JoystickButton3))
        {
            lastStoryModeShortcutAction = "finish-shortcut";
            if (IsCompletedFiveTurnSession())
            {
                ShowClosingCard();
            }
            else if (statusText != null)
            {
                statusText.text = $"{RequiredQuestionCount}문답 후 마무리할 수 있습니다";
            }
            return true;
        }

        return false;
    }

    private bool HandleRecordArchiveShortcuts()
    {
        if (recordArchiveObject == null || !recordArchiveObject.activeSelf) return false;

        if (TryGetRecordArchiveShortcutIndex(out int shortcutIndex))
        {
            SelectRecordArchiveByShortcut(shortcutIndex, $"choice-{shortcutIndex + 1}-key");
            return true;
        }

        if (IsKeyDown(KeyCode.UpArrow) || IsKeyDown(KeyCode.LeftArrow) || IsKeyDown(KeyCode.JoystickButton4))
        {
            CycleRecordArchiveSelection(-1, IsKeyDown(KeyCode.JoystickButton4) ? "previous-gamepad" : "previous-key");
            return true;
        }

        if (IsKeyDown(KeyCode.DownArrow) || IsKeyDown(KeyCode.RightArrow) || IsKeyDown(KeyCode.JoystickButton5))
        {
            CycleRecordArchiveSelection(1, IsKeyDown(KeyCode.JoystickButton5) ? "next-gamepad" : "next-key");
            return true;
        }

        if (IsKeyDown(KeyCode.Delete) || IsKeyDown(KeyCode.Backspace) || IsKeyDown(KeyCode.D) || IsKeyDown(KeyCode.JoystickButton2))
        {
            lastRecordArchiveShortcutAction = IsKeyDown(KeyCode.JoystickButton2) ? "delete-gamepad" : "delete-key";
            RequestDeleteSelectedRecord();
            return true;
        }

        if (IsKeyDown(KeyCode.C))
        {
            lastRecordArchiveShortcutAction = "cancel-delete-key";
            CancelPendingRecordDelete();
            return true;
        }

        return false;
    }

    private bool TryGetRecordArchiveShortcutIndex(out int index)
    {
        index = -1;
        KeyCode[] alphaKeys = { KeyCode.Alpha1, KeyCode.Alpha2, KeyCode.Alpha3, KeyCode.Alpha4, KeyCode.Alpha5, KeyCode.Alpha6 };
        KeyCode[] keypadKeys = { KeyCode.Keypad1, KeyCode.Keypad2, KeyCode.Keypad3, KeyCode.Keypad4, KeyCode.Keypad5, KeyCode.Keypad6 };
        int count = Mathf.Min(GetVisibleRecordArchiveCount(), alphaKeys.Length);
        for (int i = 0; i < count; i++)
        {
            if (IsKeyDown(alphaKeys[i]) || IsKeyDown(keypadKeys[i]))
            {
                index = i;
                return true;
            }
        }

        return false;
    }

    private int GetVisibleRecordArchiveCount()
    {
        int pathCount = recordArchivePaths != null ? recordArchivePaths.Length : 0;
        return Mathf.Min(pathCount, RecordArchiveSlotCount);
    }

    private void CycleRecordArchiveSelection(int delta, string action)
    {
        int count = GetVisibleRecordArchiveCount();
        if (count <= 0)
        {
            lastRecordArchiveShortcutAction = "empty";
            UpdateRecordDeleteButton();
            return;
        }

        int current = Mathf.Clamp(selectedRecordArchiveIndex, 0, count - 1);
        int next = (current + delta + count) % count;
        SelectRecordArchiveByShortcut(next, action);
    }

    private void SelectRecordArchiveByShortcut(int index, string action)
    {
        int count = GetVisibleRecordArchiveCount();
        if (count <= 0)
        {
            lastRecordArchiveShortcutAction = "empty";
            UpdateRecordDeleteButton();
            return;
        }

        lastRecordArchiveShortcutAction = string.IsNullOrWhiteSpace(action) ? "select" : action;
        SelectRecordArchive(Mathf.Clamp(index, 0, count - 1));
    }

    private bool HandleClosingCardShortcuts()
    {
        if (closingCardObject == null || !closingCardObject.activeSelf) return false;
        if (closingCardChoiceButtons == null || closingCardChoiceButtons.Length == 0) return false;

        if (IsKeyDown(KeyCode.Alpha1) || IsKeyDown(KeyCode.Keypad1))
        {
            SelectClosingCardByShortcut(0, "choice-1-key");
            return true;
        }

        if (IsKeyDown(KeyCode.Alpha2) || IsKeyDown(KeyCode.Keypad2))
        {
            SelectClosingCardByShortcut(1, "choice-2-key");
            return true;
        }

        if (IsKeyDown(KeyCode.Alpha3) || IsKeyDown(KeyCode.Keypad3))
        {
            SelectClosingCardByShortcut(2, "choice-3-key");
            return true;
        }

        if (IsKeyDown(KeyCode.LeftArrow) || IsKeyDown(KeyCode.JoystickButton4))
        {
            CycleClosingCardShortcut(-1, IsKeyDown(KeyCode.JoystickButton4) ? "previous-gamepad" : "previous-key");
            return true;
        }

        if (IsKeyDown(KeyCode.RightArrow) || IsKeyDown(KeyCode.JoystickButton5))
        {
            CycleClosingCardShortcut(1, IsKeyDown(KeyCode.JoystickButton5) ? "next-gamepad" : "next-key");
            return true;
        }

        if (IsKeyDown(KeyCode.Return) || IsKeyDown(KeyCode.KeypadEnter) || IsKeyDown(KeyCode.Space) || IsKeyDown(KeyCode.JoystickButton0))
        {
            lastClosingCardShortcutAction = IsKeyDown(KeyCode.JoystickButton0) ? "save-gamepad" : "save-key";
            SaveEndingRecord();
            return true;
        }

        return true;
    }

    private void CycleClosingCardShortcut(int delta, string action)
    {
        int count = closingCardChoiceButtons != null ? closingCardChoiceButtons.Length : closingQuotes.Length;
        if (count <= 0) return;
        int next = (selectedClosingIndex + delta + count) % count;
        SelectClosingCardByShortcut(next, action);
    }

    private void SelectClosingCardByShortcut(int index, string action)
    {
        int count = closingCardChoiceButtons != null ? closingCardChoiceButtons.Length : closingQuotes.Length;
        if (count <= 0) return;
        SelectClosingCard(Mathf.Clamp(index, 0, count - 1));
        lastClosingCardShortcutAction = string.IsNullOrWhiteSpace(action) ? "select" : action;
        SaveSession();
        PlayPageSound();
    }

    private bool HandleMemoryBookShortcuts()
    {
        if (memoryBookObject == null || !memoryBookObject.activeSelf) return false;
        if (memoryCardButtons == null || memoryCardButtons.Length == 0) return true;

        if (TryGetMemoryCardShortcutIndex(out int shortcutIndex))
        {
            SelectMemoryCardByShortcut(shortcutIndex, $"choice-{shortcutIndex + 1}-key");
            return true;
        }

        if (IsKeyDown(KeyCode.LeftArrow) || IsKeyDown(KeyCode.JoystickButton4))
        {
            CycleMemoryCardSelection(-1, IsKeyDown(KeyCode.JoystickButton4) ? "previous-gamepad" : "previous-key");
            return true;
        }

        if (IsKeyDown(KeyCode.RightArrow) || IsKeyDown(KeyCode.JoystickButton5))
        {
            CycleMemoryCardSelection(1, IsKeyDown(KeyCode.JoystickButton5) ? "next-gamepad" : "next-key");
            return true;
        }

        if (IsKeyDown(KeyCode.UpArrow))
        {
            CycleMemoryCardSelection(-2, "up-key");
            return true;
        }

        if (IsKeyDown(KeyCode.DownArrow))
        {
            CycleMemoryCardSelection(2, "down-key");
            return true;
        }

        if (IsKeyDown(KeyCode.Return) || IsKeyDown(KeyCode.KeypadEnter) || IsKeyDown(KeyCode.Space) || IsKeyDown(KeyCode.JoystickButton0))
        {
            SubmitMemoryCardQuestion(selectedMemoryCardIndex, IsKeyDown(KeyCode.JoystickButton0) ? "submit-gamepad" : "submit-key");
            return true;
        }

        return true;
    }

    private bool TryGetMemoryCardShortcutIndex(out int index)
    {
        index = -1;
        KeyCode[] alphaKeys = { KeyCode.Alpha1, KeyCode.Alpha2, KeyCode.Alpha3, KeyCode.Alpha4, KeyCode.Alpha5, KeyCode.Alpha6 };
        KeyCode[] keypadKeys = { KeyCode.Keypad1, KeyCode.Keypad2, KeyCode.Keypad3, KeyCode.Keypad4, KeyCode.Keypad5, KeyCode.Keypad6 };
        int count = Mathf.Min(memoryCardButtons != null ? memoryCardButtons.Length : 0, alphaKeys.Length);
        for (int i = 0; i < count; i++)
        {
            if (IsKeyDown(alphaKeys[i]) || IsKeyDown(keypadKeys[i]))
            {
                index = i;
                return true;
            }
        }

        return false;
    }

    private void CycleMemoryCardSelection(int delta, string action)
    {
        int count = memoryCardButtons != null ? memoryCardButtons.Length : memoryThemes.Length;
        if (count <= 0) return;
        int next = (selectedMemoryCardIndex + delta + count) % count;
        SelectMemoryCardByShortcut(next, action);
    }

    private void SelectMemoryCardByShortcut(int index, string action)
    {
        int count = memoryCardButtons != null ? memoryCardButtons.Length : memoryThemes.Length;
        if (count <= 0) return;
        selectedMemoryCardIndex = Mathf.Clamp(index, 0, count - 1);
        lastMemoryBookShortcutAction = string.IsNullOrWhiteSpace(action) ? "select" : action;
        UpdateMemoryBook();
        PlayPageSound();
    }

    private bool HandleGamepadShortcuts()
    {
        if (IsKeyDown(KeyCode.JoystickButton0))
        {
            if (startMenuObject != null && startMenuObject.activeSelf)
            {
                RequestFreshStart(false);
                return true;
            }

            if (!HasModalShortcutBlocker() || questionNoteOpen)
            {
                return TrySubmitLeadShortcut(selectedLeadIndex);
            }

            return false;
        }

        if (questionNoteOpen && (IsKeyDown(KeyCode.JoystickButton4) || IsKeyDown(KeyCode.JoystickButton5)))
        {
            ShowNoteTab(2);
            return true;
        }

        if ((IsKeyDown(KeyCode.JoystickButton4) || IsKeyDown(KeyCode.JoystickButton5)) && CanUseLeadSelectionShortcuts())
        {
            int delta = IsKeyDown(KeyCode.JoystickButton5) ? 1 : -1;
            CycleSelectedLead(delta);
            return true;
        }

        if (IsKeyDown(KeyCode.JoystickButton4))
        {
            RunShortcutAction("text-down");
            return true;
        }

        if (IsKeyDown(KeyCode.JoystickButton5))
        {
            RunShortcutAction("text-up");
            return true;
        }

        if (HandleOpenPanelShortcutToggles())
        {
            return true;
        }

        if (HasModalShortcutBlocker())
        {
            return false;
        }

        if (IsKeyDown(KeyCode.JoystickButton2))
        {
            RunShortcutAction("question");
            return true;
        }

        if (IsKeyDown(KeyCode.JoystickButton3))
        {
            RunShortcutAction("memory");
            return true;
        }

        if (IsKeyDown(KeyCode.JoystickButton6))
        {
            RunShortcutAction("records");
            return true;
        }

        if (IsKeyDown(KeyCode.JoystickButton7))
        {
            RunShortcutAction("settings");
            return true;
        }

        return false;
    }

    private bool IsTypingInTextField()
    {
        return (inputField != null && inputField.isFocused) ||
            (playtestFeedbackInput != null && playtestFeedbackInput.isFocused);
    }

    private void SubmitLeadShortcut(int index)
    {
        TrySubmitLeadShortcut(index);
    }

    private bool TrySubmitLeadShortcut(int index)
    {
        if (busy) return false;
        if (startMenuObject != null && startMenuObject.activeSelf) return false;
        if (settingsMenuObject != null && settingsMenuObject.activeSelf) return false;
        if (aboutMenuObject != null && aboutMenuObject.activeSelf) return false;
        if (recordArchiveObject != null && recordArchiveObject.activeSelf) return false;
        if (closingCardObject != null && closingCardObject.activeSelf) return false;
        if (closingSensitiveQuestionObject != null && closingSensitiveQuestionObject.activeSelf) return false;
        if (memoryBookObject != null && memoryBookObject.activeSelf) return false;
        if (leadButtons == null || index < 0 || index >= leadButtons.Length) return false;
        if (leadButtons[index] == null || !leadButtons[index].interactable) return false;

        selectedLeadIndex = Mathf.Clamp(index, 0, leadButtons.Length - 1);
        UpdateLeadSelectionStyles();
        string question = GetLeadQuestion(index);
        if (!TryStartPreparedQuestion(question)) return false;
        if (inputField != null) inputField.text = string.Empty;
        if (questionNoteOpen) SetQuestionNoteOpen(false);
        return true;
    }

    private bool CanUseLeadSelectionShortcuts()
    {
        if (busy || directInputOpen || questionNoteOpen) return false;
        if (startMenuObject != null && startMenuObject.activeSelf) return false;
        if (HasModalShortcutBlocker()) return false;
        if (leadButtons == null || leadButtons.Length == 0) return false;
        if (!ShowFloatingLeadSlips) return false;
        for (int i = 0; i < leadButtons.Length; i++)
        {
            if (leadButtons[i] != null && leadButtons[i].gameObject.activeInHierarchy && leadButtons[i].interactable)
            {
                return true;
            }
        }

        return false;
    }

    private void CycleSelectedLead(int delta)
    {
        if (leadButtons == null || leadButtons.Length == 0) return;
        selectedLeadIndex = (selectedLeadIndex + delta + leadButtons.Length) % leadButtons.Length;
        UpdateLeadSelectionStyles();
        PlayPageSound();
    }

    private void SelectNoteTabShortcut(int index)
    {
        if (questionNoteOpen)
        {
            ShowNoteTab(index);
            return;
        }

        SubmitLeadShortcut(index);
    }

    private bool HandleReadingScrollShortcuts()
    {
        bool lineUp = IsKeyDown(KeyCode.UpArrow);
        bool lineDown = IsKeyDown(KeyCode.DownArrow);
        bool pageUp = IsKeyDown(KeyCode.PageUp);
        bool pageDown = IsKeyDown(KeyCode.PageDown);
        bool home = IsKeyDown(KeyCode.Home);
        bool end = IsKeyDown(KeyCode.End);
        if (!lineUp && !lineDown && !pageUp && !pageDown && !home && !end) return false;

        bool recordArchiveOpen = recordArchiveObject != null && recordArchiveObject.activeSelf;
        bool noteHistoryOpen = questionNoteOpen && noteHistoryScrollRect != null;
        if (!recordArchiveOpen && !noteHistoryOpen && (lineDown || pageDown || end))
        {
            if (TryAdvanceDialoguePage()) return true;
            if (pendingCompletionChoiceAfterDialogue)
            {
                ShowCompletionChoiceOverlay();
                return true;
            }
            if (storyModeActive)
            {
                RequestStoryModeAdvance("keyboard-page");
                return true;
            }
        }

        ScrollRect target = GetActiveKeyboardScrollRect();
        if (target == null) return false;

        if (home)
        {
            SetKeyboardScrollPosition(target, 1f);
            return true;
        }

        if (end)
        {
            SetKeyboardScrollPosition(target, 0f);
            return true;
        }

        float delta = 0f;
        if (lineUp) delta += KeyboardLineScrollStep;
        if (lineDown) delta -= KeyboardLineScrollStep;
        if (pageUp) delta += KeyboardPageScrollStep;
        if (pageDown) delta -= KeyboardPageScrollStep;
        SetKeyboardScrollPosition(target, target.verticalNormalizedPosition + delta);
        return true;
    }

    private ScrollRect GetActiveKeyboardScrollRect()
    {
        if (recordArchiveObject != null && recordArchiveObject.activeSelf)
        {
            return recordArchiveScrollRect;
        }

        if (questionNoteOpen)
        {
            return noteHistoryScrollRect;
        }

        if (startMenuObject != null && startMenuObject.activeSelf) return null;
        if (settingsMenuObject != null && settingsMenuObject.activeSelf) return null;
        if (aboutMenuObject != null && aboutMenuObject.activeSelf) return null;
        if (pauseMenuObject != null && pauseMenuObject.activeSelf) return null;
        if (closingCardObject != null && closingCardObject.activeSelf) return null;
        if (closingSensitiveQuestionObject != null && closingSensitiveQuestionObject.activeSelf) return null;
        if (memoryBookObject != null && memoryBookObject.activeSelf) return null;
        return null;
    }

    private void SetKeyboardScrollPosition(ScrollRect target, float position)
    {
        if (target == null) return;
        Canvas.ForceUpdateCanvases();
        target.verticalNormalizedPosition = Mathf.Clamp01(position);
        Canvas.ForceUpdateCanvases();
    }

    private bool HandleOpenPanelShortcutToggles()
    {
        if (questionNoteOpen)
        {
            if (IsKeyDown(KeyCode.Q))
            {
                RunShortcutAction("question");
                return true;
            }

            return false;
        }

        if (recordArchiveObject != null && recordArchiveObject.activeSelf)
        {
            if (IsKeyDown(KeyCode.R))
            {
                RunShortcutAction("records");
                return true;
            }

            return false;
        }

        if (settingsMenuObject != null && settingsMenuObject.activeSelf)
        {
            if (IsKeyDown(KeyCode.S))
            {
                RunShortcutAction("settings");
                return true;
            }

            return false;
        }

        if (aboutMenuObject != null && aboutMenuObject.activeSelf)
        {
            if (IsKeyDown(KeyCode.I))
            {
                RunShortcutAction("info");
                return true;
            }

            return false;
        }

        if (memoryBookObject != null && memoryBookObject.activeSelf)
        {
            if (IsKeyDown(KeyCode.M))
            {
                RunShortcutAction("memory");
                return true;
            }

            return false;
        }

        if (pauseMenuObject != null && pauseMenuObject.activeSelf && IsKeyDown(KeyCode.S))
        {
            RunShortcutAction("settings");
            return true;
        }

        return false;
    }

    private bool HasModalShortcutBlocker()
    {
        return questionNoteOpen ||
            (recordArchiveObject != null && recordArchiveObject.activeSelf) ||
            (settingsMenuObject != null && settingsMenuObject.activeSelf) ||
            (aboutMenuObject != null && aboutMenuObject.activeSelf) ||
            (pauseMenuObject != null && pauseMenuObject.activeSelf) ||
            (completionChoiceObject != null && completionChoiceObject.activeSelf) ||
            (closingCardObject != null && closingCardObject.activeSelf) ||
            (closingSensitiveQuestionObject != null && closingSensitiveQuestionObject.activeSelf) ||
            (memoryBookObject != null && memoryBookObject.activeSelf);
    }

    private void RunShortcutAction(string action)
    {
        if (string.IsNullOrWhiteSpace(action)) return;

        switch (action.Trim().ToLowerInvariant())
        {
            case "question":
            case "phone":
                if (startMenuObject != null && startMenuObject.activeSelf) startMenuObject.SetActive(false);
                SetQuestionNoteOpen(!questionNoteOpen);
                break;
            case "note-question":
                if (!questionNoteOpen) SetQuestionNoteOpen(true);
                ShowNoteTab(0);
                break;
            case "note-evidence":
                if (!questionNoteOpen) SetQuestionNoteOpen(true);
                ShowNoteTab(1);
                break;
            case "note-history":
                if (!questionNoteOpen) SetQuestionNoteOpen(true);
                ShowNoteTab(2);
                break;
            case "memory":
                if (startMenuObject != null && startMenuObject.activeSelf) startMenuObject.SetActive(false);
                SetMemoryBookOpen(memoryBookObject == null || !memoryBookObject.activeSelf);
                break;
            case "records":
            case "archive":
                SetRecordArchiveOpen(recordArchiveObject == null || !recordArchiveObject.activeSelf);
                break;
            case "settings":
                SetSettingsMenuOpen(settingsMenuObject == null || !settingsMenuObject.activeSelf);
                break;
            case "info":
            case "about":
                SetAboutMenuOpen(aboutMenuObject == null || !aboutMenuObject.activeSelf);
                break;
            case "fullscreen":
                SetFullscreenEnabled(!fullscreenEnabled, true);
                break;
            case "text-up":
                ChangeDialogueSize(1);
                break;
            case "text-down":
                ChangeDialogueSize(-1);
                break;
            case "lead-theme":
            case "other-theme":
                ShowOtherThemeLeadQuestions();
                break;
            case "lead-refresh":
            case "refresh-questions":
                RefreshVisibleLeadQuestions();
                break;
        }
    }

    private void SetPauseMenuOpen(bool open)
    {
        if (pauseMenuObject != null) pauseMenuObject.SetActive(open);
        if (open)
        {
            if (inputField != null) inputField.DeactivateInputField();
            SelectFirstInteractable(pauseMenuObject, "Resume Button", "Settings From Pause Button", "Restart Button");
            statusText.text = "일시정지";
        }
        else
        {
            ClearSelectionIfInside(pauseMenuObject);
        }

        ShowHotspotLabels();
    }

    private void SetAboutMenuOpen(bool open)
    {
        if (aboutMenuObject != null) aboutMenuObject.SetActive(open);
        if (open)
        {
            aboutMenuObject.transform.SetAsLastSibling();
            if (inputField != null) inputField.DeactivateInputField();
            UpdateClearLocalDataButton();
            SetServerStatusIdle();
            SelectFirstInteractable(aboutMenuObject, "About Server Refresh Button", "About Record Folder Button", "About Feedback Folder Button", "Close About Button");
            statusText.text = "정보";
        }
        else
        {
            ClearSelectionIfInside(aboutMenuObject);
            ResetClearLocalDataPrompt();
            if (serverStatusCoroutine != null)
            {
                StopCoroutine(serverStatusCoroutine);
                serverStatusCoroutine = null;
            }
            if (settingsMenuObject != null && settingsMenuObject.activeSelf)
            {
                statusText.text = "설정";
            }
        }

        ShowHotspotLabels();
    }

    private void SetServerStatusIdle()
    {
        if (serverStatusText == null)
        {
            return;
        }

        serverStatusText.text = serverReady
            ? serverRequiredMessage
            : (serverStatusKnown ? serverRequiredMessage : ServerStatusIdleText);
    }

    private void RefreshServerStatus()
    {
        if (serverStatusCoroutine != null)
        {
            StopCoroutine(serverStatusCoroutine);
            serverStatusCoroutine = null;
        }

        SetServerAvailability(false, false, ServerRequiredCheckingText);

        if (serverStatusText != null)
        {
            serverStatusText.text = "로컬 서버 확인 중...";
        }

        serverStatusCoroutine = StartCoroutine(CheckServerStatus());
    }

    private IEnumerator CheckServerStatus()
    {
        string message = ServerRequiredBlockedText;
        bool ready = false;

        using (UnityWebRequest request = UnityWebRequest.Get($"{ServerBaseUrl}/api/config"))
        {
            request.timeout = 10;
            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                ServerConfigResponse config = null;
                try
                {
                    config = JsonUtility.FromJson<ServerConfigResponse>(request.downloadHandler.text);
                }
                catch (ArgumentException)
                {
                    config = null;
                }

                if (IsServerConfigReady(config))
                {
                    message = $"서버 연결됨 · API 답변 사용 · {FormatServerModel(config.chatModel)}";
                    ready = true;
                }
                else if (config != null && config.apiAvailable)
                {
                    string detail = string.IsNullOrWhiteSpace(config.chatModelError)
                        ? "채팅 모델 준비 안 됨"
                        : ShortenForCard(config.chatModelError, 72);
                    message = $"서버 연결됨 · {detail} · 내장 답변 사용";
                    ready = true;
                }
                else if (config != null)
                {
                    message = "서버 연결됨 · API 키 없음 · 내장 답변 사용";
                    ready = true;
                }
            }
            else
            {
                message = string.IsNullOrWhiteSpace(request.error)
                    ? ServerRequiredBlockedText
                    : $"서버 연결 실패 · {ShortenForCard(request.error, 72)}";
            }
        }

        SetServerAvailability(ready, true, message);

        if (serverStatusText != null)
        {
            serverStatusText.text = message;
        }

        serverStatusCoroutine = null;
    }

    private void SetSettingsMenuOpen(bool open)
    {
        if (settingsMenuObject != null) settingsMenuObject.SetActive(open);
        if (open)
        {
            if (inputField != null) inputField.DeactivateInputField();
            UpdateSettingsControls();
            SelectFirstInteractable(settingsMenuObject, "Settings Text Size 기본", "Fullscreen Toggle Button", "Close Settings Button");
            statusText.text = "설정";
        }
        else
        {
            ClearSelectionIfInside(settingsMenuObject);
        }

        ShowHotspotLabels();
    }

    private void ChangeDialogueSize(int delta)
    {
        SetDialogueSizeLevel(dialogueSizeLevel + delta, true);
    }

    private void SetDialogueSizeLevel(int level, bool persist)
    {
        dialogueSizeLevel = Mathf.Clamp(level, -1, 1);
        if (persist)
        {
            PlayerPrefs.SetInt(TextSizeKey, dialogueSizeLevel);
            PlayerPrefs.Save();
        }

        ApplyDialogueTextSize(true);
        if (statusText != null)
        {
            statusText.text = dialogueSizeLevel > 0 ? "큰 글자" : (dialogueSizeLevel < 0 ? "작은 글자" : "기본 글자");
        }
        if (persist) SaveSession();
    }

    private void ApplyDialogueTextSize(bool refresh)
    {
        if (dialogueText != null)
        {
            dialogueText.fontSize = dialogueSizeLevel > 0 ? 23 : (dialogueSizeLevel < 0 ? 18 : 20);
            dialogueText.lineSpacing = dialogueSizeLevel > 0 ? 1.08f : (dialogueSizeLevel < 0 ? 1.10f : 1.08f);
            dialogueText.fontStyle = FontStyle.Normal;
            dialogueText.color = highContrastEnabled ? new Color32(8, 15, 28, 255) : new Color32(30, 41, 59, 246);
        }

        SetDialogueSizeButtonState();
        UpdateSettingsControls();

        if (refresh && dialogueScrollRect != null && dialogueContentRect != null)
        {
            RefreshDialogueScroll();
        }
    }

    private void SetDialogueSizeButtonState()
    {
        if (dialogueSizeDownButton != null)
        {
            dialogueSizeDownButton.interactable = dialogueSizeLevel > -1;
            SetButtonColor(
                dialogueSizeDownButton,
                dialogueSizeLevel > -1 ? (Color)new Color32(30, 41, 59, 226) : new Color(0.22f, 0.24f, 0.27f, 0.50f),
                dialogueSizeLevel > -1 ? Color.white : new Color(1f, 1f, 1f, 0.45f));
        }

        if (dialogueSizeUpButton != null)
        {
            dialogueSizeUpButton.interactable = dialogueSizeLevel < 1;
            SetButtonColor(
                dialogueSizeUpButton,
                dialogueSizeLevel < 1 ? (Color)new Color32(30, 41, 59, 226) : new Color(0.22f, 0.24f, 0.27f, 0.50f),
                dialogueSizeLevel < 1 ? Color.white : new Color(1f, 1f, 1f, 0.45f));
        }
    }

    private void SetFullscreenEnabled(bool enabled, bool persist)
    {
        fullscreenEnabled = enabled;
        ApplyDisplayResolution();

        if (persist)
        {
            PlayerPrefs.SetInt(FullscreenKey, fullscreenEnabled ? 1 : 0);
            PlayerPrefs.Save();
        }

        UpdateSettingsControls();
        if (statusText != null)
        {
            statusText.text = fullscreenEnabled ? "전체 화면" : "창 모드";
        }
    }

    private void CycleSoundLevel()
    {
        int next = soundLevel == 2 ? 1 : (soundLevel == 1 ? 0 : 2);
        SetSoundLevel(next, true);
        if (soundLevel > 0) PlaySound(confirmClip);
    }

    private void SetSoundLevel(int level, bool persist)
    {
        soundLevel = Mathf.Clamp(level, 0, 2);
        if (persist)
        {
            PlayerPrefs.SetInt(SoundLevelKey, soundLevel);
            PlayerPrefs.Save();
        }

        ApplySoundSettings(true);
        UpdateSettingsControls();

        if (statusText != null)
        {
            statusText.text = GetSoundLevelLabel();
        }
    }

    private void SetReducedMotionEnabled(bool enabled, bool persist)
    {
        reducedMotionEnabled = enabled;
        if (persist)
        {
            PlayerPrefs.SetInt(ReducedMotionKey, reducedMotionEnabled ? 1 : 0);
            PlayerPrefs.Save();
        }

        if (reducedMotionEnabled)
        {
            if (avatarRect != null)
            {
                avatarRect.anchoredPosition = avatarBasePosition;
                avatarRect.localScale = AvatarScale(1f);
            }

            for (int i = 0; i < hotspotPulseRects.Count; i++)
            {
                if (hotspotPulseRects[i] != null) hotspotPulseRects[i].localScale = Vector3.one;
                if (i < hotspotPulseImages.Count && hotspotPulseImages[i] != null)
                {
                    Color color = hotspotPulseImages[i].color;
                    color.a = 0.010f;
                    hotspotPulseImages[i].color = color;
                }
            }

            if (memoryUnlockToastRect != null) memoryUnlockToastRect.localScale = Vector3.one;
        }

        UpdateSettingsControls();
        if (statusText != null)
        {
            statusText.text = reducedMotionEnabled ? "움직임 줄임" : "움직임 기본";
        }
    }

    private void SetHighContrastEnabled(bool enabled, bool persist)
    {
        highContrastEnabled = enabled;
        if (persist)
        {
            PlayerPrefs.SetInt(HighContrastKey, highContrastEnabled ? 1 : 0);
            PlayerPrefs.Save();
        }

        ApplyHighContrastMode(true);
        UpdateSettingsControls();
        if (statusText != null)
        {
            statusText.text = highContrastEnabled ? "읽기 쉬운 화면 켜짐" : "읽기 쉬운 화면 꺼짐";
        }
    }

    private void ApplyHighContrastMode(bool refreshDialogue)
    {
        if (highContrastDimImage != null)
        {
            highContrastDimImage.color = highContrastEnabled
                ? new Color(0.018f, 0.023f, 0.030f, 0.28f)
                : new Color(0.018f, 0.023f, 0.030f, 0f);
            highContrastDimImage.gameObject.SetActive(highContrastEnabled);
        }

        if (dialogueText != null)
        {
            dialogueText.fontStyle = FontStyle.Normal;
            dialogueText.color = highContrastEnabled ? new Color32(8, 15, 28, 255) : new Color32(30, 41, 59, 246);
        }

        if (inputField != null)
        {
            if (inputField.textComponent != null)
            {
                inputField.textComponent.color = highContrastEnabled ? new Color32(8, 15, 28, 255) : new Color32(30, 41, 59, 240);
                inputField.textComponent.fontStyle = FontStyle.Normal;
            }

            if (inputField.placeholder != null)
            {
                inputField.placeholder.color = highContrastEnabled ? new Color32(35, 48, 68, 210) : new Color32(71, 85, 105, 172);
            }
        }

        if (speakerText != null)
        {
            speakerText.color = highContrastEnabled ? (Color)new Color32(10, 18, 32, 255) : new Color(0.20f, 0.13f, 0.07f, 0.88f);
        }

        if (refreshDialogue)
        {
            RefreshDialogueScroll();
        }
    }

    private void SetLocalAnswerOnlyEnabled(bool enabled, bool persist)
    {
        localAnswerOnly = false;
        if (recording)
        {
            try
            {
                Microphone.End(micDevice);
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"Failed to stop microphone while enabling local answers: {ex.Message}");
            }

            recording = false;
            recordingClip = null;
            SetExpression(ExpressionState.Idle);
            SetFlowButtonsInteractable(true);
        }

        if (persist)
        {
            PlayerPrefs.SetInt(LocalAnswerOnlyKey, 0);
            PlayerPrefs.Save();
        }

        UpdateSettingsControls();
        UpdateMicButtonState();
        UpdateProgressTracker();
        if (statusText != null)
        {
            statusText.text = "서버 답변 필수";
        }
        RefreshServerStatus();
    }

    private void ApplySoundSettings(bool updatePlayback)
    {
        float master = soundLevel == 0 ? 0f : (soundLevel == 1 ? 0.42f : 0.72f);

        if (sfxSource != null)
        {
            sfxSource.volume = master;
        }

        if (ambienceSource != null)
        {
            ambienceSource.volume = master * 0.14f;
            if (soundLevel > 0)
            {
                if (!ambienceSource.isPlaying) ambienceSource.Play();
            }
            else if (ambienceSource.isPlaying)
            {
                ambienceSource.Stop();
            }
        }
    }

    private void PlayButtonSound()
    {
        PlaySound(buttonClickClip);
    }

    private void PlayPageSound()
    {
        PlaySound(pageTurnClip);
    }

    private void PlaySound(AudioClip clip)
    {
        if (soundLevel <= 0 || sfxSource == null || clip == null) return;
        sfxSource.PlayOneShot(clip, 1f);
    }

    private void OpenEndingRecordFolder()
    {
        try
        {
            string directory = GetEndingRecordDirectory();
            Directory.CreateDirectory(directory);
            Application.OpenURL("file:///" + directory.Replace("\\", "/"));
            statusText.text = "기록 폴더를 열었습니다";
        }
        catch (Exception ex)
        {
            statusText.text = "기록 폴더를 열 수 없습니다";
            Debug.LogWarning($"Failed to open ending record folder: {ex.Message}");
        }
    }

    private void RequestClearLocalData()
    {
        if (pendingClearLocalDataUntil > 0f && Time.realtimeSinceStartup <= pendingClearLocalDataUntil)
        {
            ClearLocalSavedDataAndRecords();
            return;
        }

        pendingClearLocalDataUntil = Time.realtimeSinceStartup + 4f;
        statusText.text = "저장 데이터와 기록이 완전히 지워집니다";
        UpdateClearLocalDataButton();
    }

    private void HandleClearLocalDataButtonClick()
    {
        bool confirming = pendingClearLocalDataUntil > 0f && Time.realtimeSinceStartup <= pendingClearLocalDataUntil;
        RequestClearLocalData();
        lastClearLocalDataAction = confirming ? "confirm-button" : "prompt-button";
    }

    private void ClearLocalSavedDataAndRecords()
    {
        int deletedCount = 0;
        try
        {
            deletedCount = DeleteEndingRecordFiles();
            deletedCount += DeletePlaytestFeedbackFiles();
            pendingClearLocalDataUntil = 0f;
            ResetSession();

            if (recordArchiveObject != null && recordArchiveObject.activeSelf)
            {
                RefreshRecordArchive();
            }

            SetAboutMenuOpen(false);
            SetSettingsMenuOpen(false);
            UpdateContinueButton();
            UpdateClearLocalDataButton();
            PlaySound(confirmClip);
            statusText.text = deletedCount > 0
                ? $"저장 데이터와 기록 {deletedCount}개를 삭제했습니다"
                : "저장 데이터를 삭제했습니다";
        }
        catch (Exception ex)
        {
            pendingClearLocalDataUntil = 0f;
            UpdateClearLocalDataButton();
            statusText.text = "저장 데이터를 삭제할 수 없습니다";
            Debug.LogWarning($"Failed to clear local data: {ex.Message}");
        }
    }

    private int DeleteEndingRecordFiles()
    {
        string directory = GetEndingRecordDirectory();
        if (!Directory.Exists(directory)) return 0;

        int deleted = 0;
        foreach (string path in Directory.GetFiles(directory, "ending-*.txt"))
        {
            File.Delete(path);
            deleted++;
        }
        foreach (string path in Directory.GetFiles(directory, "message-to-interviewee-*.txt"))
        {
            File.Delete(path);
            deleted++;
        }

        return deleted;
    }

    private int DeletePlaytestFeedbackFiles()
    {
        int deleted = 0;
        foreach (string directory in new[] { GetPlaytestFeedbackDirectory(), GetLegacyPlaytestFeedbackDirectory() })
        {
            if (!Directory.Exists(directory)) continue;

            foreach (string path in Directory.GetFiles(directory, "feedback-*.*"))
            {
                File.Delete(path);
                deleted++;
            }
        }

        return deleted;
    }

    private void ResetClearLocalDataPrompt()
    {
        pendingClearLocalDataUntil = 0f;
        UpdateClearLocalDataButton();
    }

    private void UpdateClearLocalDataButton()
    {
        if (clearLocalDataButton == null) return;

        bool confirming = pendingClearLocalDataUntil > 0f && Time.realtimeSinceStartup <= pendingClearLocalDataUntil;
        Text label = clearLocalDataButton.GetComponentInChildren<Text>();
        if (label != null) label.text = confirming ? "삭제 확정" : "저장 삭제";
        SetButtonColor(
            clearLocalDataButton,
            confirming ? new Color32(190, 82, 62, 245) : new Color32(133, 111, 82, 230),
            Color.white);

        if (clearLocalDataHintText != null)
        {
            clearLocalDataHintText.text = confirming
                ? "저장 데이터와 기록이 완전히 지워집니다. 삭제 확정으로 진행하세요."
                : "저장 삭제는 확인 후 실행됩니다.";
            clearLocalDataHintText.color = confirming
                ? new Color32(153, 27, 27, 245)
                : new Color32(71, 85, 105, 230);
            clearLocalDataHintText.fontStyle = FontStyle.Bold;
        }

        if (clearLocalDataHintPanel != null)
        {
            clearLocalDataHintPanel.color = confirming
                ? new Color(0.99f, 0.88f, 0.82f, 0.95f)
                : new Color(1f, 0.99f, 0.95f, 0.82f);
        }
    }

    private void UpdateClearLocalDataPromptTimeout()
    {
        if (pendingClearLocalDataUntil <= 0f) return;
        if (Time.realtimeSinceStartup <= pendingClearLocalDataUntil) return;

        pendingClearLocalDataUntil = 0f;
        UpdateClearLocalDataButton();
    }

    private void SetRecordArchiveOpen(bool open)
    {
        if (recordArchiveObject == null) return;

        recordArchiveObject.SetActive(open);
        if (!open)
        {
            ClearSelectionIfInside(recordArchiveObject);
            ShowHotspotLabels();
            return;
        }

        recordArchiveObject.transform.SetAsLastSibling();
        if (inputField != null) inputField.DeactivateInputField();
        if (aboutMenuObject != null && aboutMenuObject.activeSelf) aboutMenuObject.SetActive(false);
        if (closingCardObject != null && closingCardObject.activeSelf) closingCardObject.SetActive(false);
        if (closingSensitiveQuestionObject != null && closingSensitiveQuestionObject.activeSelf) closingSensitiveQuestionObject.SetActive(false);
        if (memoryBookObject != null && memoryBookObject.activeSelf) memoryBookObject.SetActive(false);

        RefreshRecordArchive();
        SelectFirstInteractable(recordArchiveObject, "Record Archive Slot 1", "Record Archive Refresh Button", "Record Archive Close Button");
        PlayPageSound();
        statusText.text = "기록함";
        ShowHotspotLabels();
    }

    private void SetPlaytestFeedbackOpen(bool open)
    {
        if (playtestFeedbackObject == null) return;

        playtestFeedbackObject.SetActive(open);
        if (!open)
        {
            if (directInputOpen && inputField != null) inputField.ActivateInputField();
            ShowHotspotLabels();
            return;
        }

        playtestFeedbackObject.transform.SetAsLastSibling();
        if (inputField != null) inputField.DeactivateInputField();
        if (playtestFeedbackInput != null) playtestFeedbackInput.ActivateInputField();
        if (playtestFeedbackStatusText != null) playtestFeedbackStatusText.text = "이 컴퓨터에만 저장되는 메모입니다.";
        selectedPlaytestFeedbackGroup = Mathf.Clamp(selectedPlaytestFeedbackGroup, 0, 3);
        SelectPlaytestRating(selectedPlaytestRating);
        SelectPlaytestCommercialReadiness(selectedPlaytestCommercialReadiness);
        SelectPlaytestIssueSeverity(selectedPlaytestIssueSeverity);
        SelectPlaytestQualityFocus(selectedPlaytestQualityFocus);
        UpdatePlaytestFeedbackEvidenceText();
        statusText.text = "의견 남기기";
        ShowHotspotLabels();
    }

    private void SelectPlaytestRating(int rating)
    {
        selectedPlaytestRating = Mathf.Clamp(rating, 1, 3);
        if (playtestRatingButtons == null) return;

        for (int i = 0; i < playtestRatingButtons.Length; i++)
        {
            bool selected = i == selectedPlaytestRating - 1;
            SetButtonColor(
                playtestRatingButtons[i],
                selected ? new Color32(177, 113, 58, 245) : new Color32(30, 41, 59, 238),
                Color.white);
        }

        UpdatePlaytestFeedbackEvidenceText();
    }

    private void SelectPlaytestCommercialReadiness(int readiness)
    {
        selectedPlaytestCommercialReadiness = Mathf.Clamp(readiness, 1, 3);
        if (playtestCommercialReadinessButtons == null) return;

        for (int i = 0; i < playtestCommercialReadinessButtons.Length; i++)
        {
            bool selected = i == selectedPlaytestCommercialReadiness - 1;
            SetButtonColor(
                playtestCommercialReadinessButtons[i],
                selected ? new Color32(177, 113, 58, 245) : new Color32(30, 41, 59, 238),
                Color.white);
        }

        UpdatePlaytestFeedbackEvidenceText();
    }

    private void SelectPlaytestIssueSeverity(int severity)
    {
        selectedPlaytestIssueSeverity = Mathf.Clamp(severity, 0, 3);
        if (playtestIssueSeverityButtons == null) return;

        for (int i = 0; i < playtestIssueSeverityButtons.Length; i++)
        {
            bool selected = i == selectedPlaytestIssueSeverity;
            SetButtonColor(
                playtestIssueSeverityButtons[i],
                selected ? new Color32(177, 113, 58, 245) : new Color32(30, 41, 59, 238),
                Color.white);
        }

        UpdatePlaytestFeedbackEvidenceText();
    }

    private void SelectPlaytestQualityFocus(int focus)
    {
        selectedPlaytestQualityFocus = Mathf.Clamp(focus, 0, 8);
        if (playtestQualityFocusButton != null)
        {
            Text label = playtestQualityFocusButton.GetComponentInChildren<Text>();
            if (label != null) label.text = GetPlaytestQualityFocusButtonLabel(selectedPlaytestQualityFocus);
            SetButtonColor(
                playtestQualityFocusButton,
                selectedPlaytestQualityFocus > 0 ? new Color32(177, 113, 58, 245) : new Color32(30, 41, 59, 238),
                Color.white);
        }

        UpdatePlaytestFeedbackEvidenceText();
    }

    private void CyclePlaytestQualityFocus(int delta, string action)
    {
        selectedPlaytestFeedbackGroup = 3;
        lastPlaytestFeedbackShortcutAction = string.IsNullOrWhiteSpace(action) ? "focus-cycle" : action;
        SelectPlaytestQualityFocus(WrapInclusive(selectedPlaytestQualityFocus + delta, 0, 8));
        PlayPageSound();
    }

    private void UpdatePlaytestFeedbackEvidenceText()
    {
        if (playtestFeedbackEvidenceText == null) return;

        bool completed = IsCompletedFiveTurnSession();
        bool positive = IsPositiveEvidenceSelection();
        bool needsNote = ShouldRequirePlaytestFeedbackNote();
        int turns = Mathf.Clamp(conversationTurns, 0, RequiredQuestionCount);

        if (IsPositiveQualityEvidenceReady())
        {
            playtestFeedbackEvidenceText.text = $"저장 가능: {RequiredQuestionCount}문답 완료 · 마무리 기록 저장 · 세션 정보 저장";
            playtestFeedbackEvidenceText.color = new Color32(22, 101, 52, 245);
        }
        else if (ShouldRequireEndingRecordForPositiveEvidence())
        {
            playtestFeedbackEvidenceText.text = "마무리 기록 대기: 좋은 평가는 기록 저장 뒤 남겨 주세요";
            playtestFeedbackEvidenceText.color = new Color32(153, 27, 27, 245);
        }
        else if (positive)
        {
            playtestFeedbackEvidenceText.text = $"완주 대기: {RequiredQuestionCount}문답 {turns}/{RequiredQuestionCount} · 좋은 평가는 완료 후 저장";
            playtestFeedbackEvidenceText.color = new Color32(153, 27, 27, 245);
        }
        else if (needsNote)
        {
            playtestFeedbackEvidenceText.text = "수정 메모 필요: 더 다듬기/조금 아쉬움/문제 있음 · 짧게 남겨 주세요";
            playtestFeedbackEvidenceText.color = new Color32(146, 64, 14, 245);
        }
        else
        {
            playtestFeedbackEvidenceText.text = $"저장 전 확인: {RequiredQuestionCount}문답 {turns}/{RequiredQuestionCount} · 완성도 느낌과 문제 단계 저장";
            playtestFeedbackEvidenceText.color = new Color32(51, 65, 85, 245);
        }

        if (playtestFeedbackReadinessText != null)
        {
            playtestFeedbackReadinessText.text = BuildPlaytestFeedbackReadinessLine(turns, completed, positive);
            playtestFeedbackReadinessText.color = IsPositiveQualityEvidenceReady()
                ? new Color32(22, 101, 52, 245)
                : new Color32(71, 85, 105, 245);
        }
    }

    private string BuildPlaytestFeedbackReadinessLine(int turns, bool completed, bool positive)
    {
        string turnState = completed ? $"문답 {RequiredQuestionCount}/{RequiredQuestionCount} 완료" : $"문답 {turns}/{RequiredQuestionCount} 진행";
        string recordState = HasSavedEndingRecordThisSession() ? "마무리 기록 저장" : "마무리 기록 전";
        string selectionState = positive ? "좋은 평가 선택" : "수정 의견 저장 가능";
        return $"{turnState} · {recordState} · {selectionState}";
    }

    private bool HandlePlaytestFeedbackShortcuts()
    {
        if (playtestFeedbackObject == null || !playtestFeedbackObject.activeSelf) return false;

        if (IsKeyDown(KeyCode.F1)) { SelectPlaytestFeedbackRatingByShortcut(1, "rating-1-key"); return true; }
        if (IsKeyDown(KeyCode.F2)) { SelectPlaytestFeedbackRatingByShortcut(2, "rating-2-key"); return true; }
        if (IsKeyDown(KeyCode.F3)) { SelectPlaytestFeedbackRatingByShortcut(3, "rating-3-key"); return true; }
        if (IsKeyDown(KeyCode.F4)) { SelectPlaytestFeedbackReadinessByShortcut(1, "readiness-1-key"); return true; }
        if (IsKeyDown(KeyCode.F5)) { SelectPlaytestFeedbackReadinessByShortcut(2, "readiness-2-key"); return true; }
        if (IsKeyDown(KeyCode.F6)) { SelectPlaytestFeedbackReadinessByShortcut(3, "readiness-3-key"); return true; }
        if (IsKeyDown(KeyCode.F7)) { SelectPlaytestFeedbackIssueByShortcut(0, "issue-0-key"); return true; }
        if (IsKeyDown(KeyCode.F8)) { SelectPlaytestFeedbackIssueByShortcut(1, "issue-1-key"); return true; }
        if (IsKeyDown(KeyCode.F9)) { SelectPlaytestFeedbackIssueByShortcut(2, "issue-2-key"); return true; }
        if (IsKeyDown(KeyCode.F10)) { SelectPlaytestFeedbackIssueByShortcut(3, "issue-3-key"); return true; }

        if (IsKeyDown(KeyCode.JoystickButton3))
        {
            selectedPlaytestFeedbackGroup = (selectedPlaytestFeedbackGroup + 1) % 4;
            lastPlaytestFeedbackShortcutAction = "group-next-gamepad";
            UpdatePlaytestFeedbackEvidenceText();
            PlayPageSound();
            return true;
        }

        if (IsKeyDown(KeyCode.JoystickButton4) || IsKeyDown(KeyCode.JoystickButton5))
        {
            int delta = IsKeyDown(KeyCode.JoystickButton5) ? 1 : -1;
            CyclePlaytestFeedbackGroupValue(delta, IsKeyDown(KeyCode.JoystickButton5) ? "next-gamepad" : "previous-gamepad");
            return true;
        }

        if (IsKeyDown(KeyCode.F11) || IsKeyDown(KeyCode.JoystickButton0))
        {
            lastPlaytestFeedbackShortcutAction = IsKeyDown(KeyCode.JoystickButton0) ? "save-gamepad" : "save-key";
            SavePlaytestFeedback();
            return true;
        }

        if (IsKeyDown(KeyCode.F12))
        {
            lastPlaytestFeedbackShortcutAction = "close-key";
            SetPlaytestFeedbackOpen(false);
            return true;
        }

        return false;
    }

    private void SelectPlaytestFeedbackRatingByShortcut(int rating, string action)
    {
        selectedPlaytestFeedbackGroup = 0;
        lastPlaytestFeedbackShortcutAction = string.IsNullOrWhiteSpace(action) ? "rating" : action;
        SelectPlaytestRating(rating);
        PlayPageSound();
    }

    private void SelectPlaytestFeedbackReadinessByShortcut(int readiness, string action)
    {
        selectedPlaytestFeedbackGroup = 1;
        lastPlaytestFeedbackShortcutAction = string.IsNullOrWhiteSpace(action) ? "readiness" : action;
        SelectPlaytestCommercialReadiness(readiness);
        PlayPageSound();
    }

    private void SelectPlaytestFeedbackIssueByShortcut(int severity, string action)
    {
        selectedPlaytestFeedbackGroup = 2;
        lastPlaytestFeedbackShortcutAction = string.IsNullOrWhiteSpace(action) ? "issue" : action;
        SelectPlaytestIssueSeverity(severity);
        PlayPageSound();
    }

    private void CyclePlaytestFeedbackGroupValue(int delta, string action)
    {
        lastPlaytestFeedbackShortcutAction = string.IsNullOrWhiteSpace(action) ? "cycle" : action;
        if (selectedPlaytestFeedbackGroup == 0)
        {
            SelectPlaytestRating(WrapInclusive(selectedPlaytestRating + delta, 1, 3));
        }
        else if (selectedPlaytestFeedbackGroup == 1)
        {
            SelectPlaytestCommercialReadiness(WrapInclusive(selectedPlaytestCommercialReadiness + delta, 1, 3));
        }
        else if (selectedPlaytestFeedbackGroup == 2)
        {
            SelectPlaytestIssueSeverity(WrapInclusive(selectedPlaytestIssueSeverity + delta, 0, 3));
        }
        else
        {
            SelectPlaytestQualityFocus(WrapInclusive(selectedPlaytestQualityFocus + delta, 0, 8));
        }

        PlayPageSound();
    }

    private static int WrapInclusive(int value, int min, int max)
    {
        int count = max - min + 1;
        if (count <= 0) return min;
        return ((value - min) % count + count) % count + min;
    }

    private void SavePlaytestFeedback()
    {
        SavePlaytestFeedbackToDirectory(GetPlaytestFeedbackDirectory());
    }

    private bool ShouldRequirePlaytestFeedbackNote()
    {
        return selectedPlaytestRating <= 1
            || selectedPlaytestCommercialReadiness <= 2
            || selectedPlaytestIssueSeverity > 0;
    }

    private string GetPlaytestFeedbackNote()
    {
        return playtestFeedbackInput != null ? (playtestFeedbackInput.text ?? string.Empty).Trim() : string.Empty;
    }

    private bool IsCompletedFiveTurnSession()
    {
        return conversationTurns >= RequiredQuestionCount;
    }

    private string BuildActiveCategoryLabel()
    {
        return "오늘의 대화";
    }

    private bool HasSavedEndingRecordThisSession()
    {
        return !string.IsNullOrWhiteSpace(lastSavedEndingRecordPath);
    }

    private bool IsPositiveEvidenceSelection()
    {
        return selectedPlaytestRating >= 3
            && selectedPlaytestCommercialReadiness >= 3
            && selectedPlaytestIssueSeverity == 0;
    }

    private bool ShouldRequireCompletedPlaytestSession()
    {
        return IsPositiveEvidenceSelection() && !IsCompletedFiveTurnSession();
    }

    private bool ShouldRequireEndingRecordForPositiveEvidence()
    {
        return IsPositiveEvidenceSelection() && IsCompletedFiveTurnSession() && !HasSavedEndingRecordThisSession();
    }

    private bool IsPositiveQualityEvidenceReady()
    {
        return IsPositiveEvidenceSelection() && IsCompletedFiveTurnSession() && HasSavedEndingRecordThisSession();
    }

    private void SavePlaytestFeedbackToDirectory(string directory)
    {
        try
        {
            string note = GetPlaytestFeedbackNote();
            if (ShouldRequireCompletedPlaytestSession())
            {
                if (playtestFeedbackStatusText != null)
                {
                    playtestFeedbackStatusText.text = $"좋음, 충분함, 문제 없음은 {RequiredQuestionCount}문답을 마친 뒤 저장해 주세요. 중간에 생긴 문제는 단계와 메모로 남길 수 있습니다.";
                }
                statusText.text = $"{RequiredQuestionCount}문답 완료 필요";
                return;
            }

            if (ShouldRequireEndingRecordForPositiveEvidence())
            {
                if (playtestFeedbackStatusText != null)
                {
                    playtestFeedbackStatusText.text = "좋음, 충분함, 문제 없음은 마무리 기록을 저장한 뒤 남길 수 있습니다.";
                }
                statusText.text = "마무리 기록 필요";
                return;
            }

            if (ShouldRequirePlaytestFeedbackNote() && note.Length < 8)
            {
                if (playtestFeedbackStatusText != null)
                {
                    playtestFeedbackStatusText.text = "더 다듬기, 조금 아쉬움, 문제 있음을 골랐다면 어디가 걸렸는지 짧게 남겨 주세요.";
                }
                statusText.text = "의견 메모 필요";
                if (playtestFeedbackInput != null) playtestFeedbackInput.ActivateInputField();
                return;
            }

            Directory.CreateDirectory(directory);

            DateTime savedAt = DateTime.Now;
            string stem = $"feedback-{playtestSessionId}-{savedAt:yyyyMMdd-HHmmss-fff}";
            string textPath = Path.Combine(directory, stem + ".txt");
            string manifestPath = Path.Combine(directory, stem + ".json");
            File.WriteAllText(textPath, BuildPlaytestFeedbackText(savedAt), Encoding.UTF8);
            File.WriteAllText(manifestPath, BuildPlaytestFeedbackManifestJson(savedAt), Encoding.UTF8);

            if (playtestFeedbackInput != null) playtestFeedbackInput.text = string.Empty;
            if (playtestFeedbackStatusText != null) playtestFeedbackStatusText.text = "의견과 세션 정보를 이 컴퓨터에 저장했습니다.";
            UpdatePlaytestFeedbackEvidenceText();
            PlaySound(confirmClip);
            statusText.text = "의견 저장됨";
        }
        catch (Exception ex)
        {
            if (playtestFeedbackStatusText != null) playtestFeedbackStatusText.text = "의견 저장에 실패했습니다.";
            statusText.text = "의견 저장 실패";
            Debug.LogWarning($"Failed to save playtest feedback: {ex.Message}");
        }
    }

    private void OpenPlaytestFeedbackFolder()
    {
        try
        {
            string directory = GetPlaytestFeedbackDirectory();
            Directory.CreateDirectory(directory);
            Application.OpenURL("file:///" + directory.Replace("\\", "/"));
            statusText.text = "의견 폴더를 열었습니다";
        }
        catch (Exception ex)
        {
            statusText.text = "의견 폴더를 열 수 없습니다";
            Debug.LogWarning($"Failed to open playtest feedback folder: {ex.Message}");
        }
    }

    private IEnumerator ClearPlaytestFeedbackSelectionNextFrame()
    {
        yield return null;
        if (playtestFeedbackInput == null) yield break;

        int end = playtestFeedbackInput.text != null ? playtestFeedbackInput.text.Length : 0;
        playtestFeedbackInput.caretPosition = end;
        playtestFeedbackInput.selectionAnchorPosition = end;
        playtestFeedbackInput.selectionFocusPosition = end;
        playtestFeedbackInput.MoveTextEnd(false);
        playtestFeedbackInput.DeactivateInputField();
        if (EventSystem.current != null)
        {
            EventSystem.current.SetSelectedGameObject(null);
        }
    }

    private void RefreshRecordArchive()
    {
        if (recordArchiveButtons == null || recordArchivePreviewText == null) return;
        ResetRecordDeletePrompt();

        string directory = GetEndingRecordDirectory();
        Directory.CreateDirectory(directory);

        List<string> files = new List<string>(Directory.GetFiles(directory, "ending-*.txt"));
        files.Sort((left, right) => string.Compare(Path.GetFileName(right), Path.GetFileName(left), StringComparison.OrdinalIgnoreCase));
        recordArchivePaths = files.ToArray();
        selectedRecordArchiveIndex = Mathf.Clamp(selectedRecordArchiveIndex, 0, Mathf.Max(0, recordArchivePaths.Length - 1));

        int visibleCount = Mathf.Min(recordArchivePaths.Length, recordArchiveButtons.Length);
        if (recordArchiveListTitleText != null)
        {
            recordArchiveListTitleText.text = recordArchivePaths.Length == 0
                ? "최근 기록"
                : FormatRecordArchiveListTitle(visibleCount, recordArchivePaths.Length);
        }

        for (int i = 0; i < recordArchiveButtons.Length; i++)
        {
            Button button = recordArchiveButtons[i];
            if (button == null) continue;

            bool visible = i < visibleCount;
            button.gameObject.SetActive(visible);
            if (!visible) continue;

            Text label = button.GetComponentInChildren<Text>();
            if (label != null)
            {
                label.text = FormatRecordArchiveLabel(recordArchivePaths[i]);
                label.lineSpacing = 0.90f;
                label.resizeTextMinSize = 9;
            }
        }

        if (visibleCount == 0)
        {
            selectedRecordArchiveIndex = -1;
            if (recordArchivePreviewHeaderText != null)
            {
                recordArchivePreviewHeaderText.text = "저장된 마무리 기록 없음";
            }

            recordArchivePreviewText.text = "아직 저장된 마무리 기록이 없습니다.\n\n다섯 번의 대화 뒤 남길 문장을 고르고 저장하면 이곳에 남습니다.";
            UpdateRecordArchiveButtonColors();
            UpdateRecordDeleteButton();
            RefreshRecordArchiveScroll();
            return;
        }

        SelectRecordArchive(Mathf.Clamp(selectedRecordArchiveIndex, 0, visibleCount - 1));
    }

    private static string FormatRecordArchiveListTitle(int visibleCount, int totalCount)
    {
        if (totalCount <= 0) return "최근 기록";
        if (totalCount <= visibleCount) return $"최근 기록 {visibleCount}개";
        return $"최근 {visibleCount}개 기록";
    }

    private void SelectRecordArchive(int index)
    {
        if (recordArchivePaths == null || recordArchivePreviewText == null) return;
        if (index < 0 || index >= recordArchivePaths.Length || index >= RecordArchiveSlotCount) return;

        ResetRecordDeletePrompt();
        selectedRecordArchiveIndex = index;
        string path = recordArchivePaths[index];
        try
        {
            recordArchivePreviewText.text = File.ReadAllText(path, Encoding.UTF8);
            if (recordArchivePreviewHeaderText != null)
            {
                recordArchivePreviewHeaderText.text = BuildRecordArchivePreviewHeader(path);
            }
        }
        catch (Exception ex)
        {
            recordArchivePreviewText.text = $"기록을 읽을 수 없습니다.\n{ex.Message}";
            if (recordArchivePreviewHeaderText != null)
            {
                recordArchivePreviewHeaderText.text = "기록을 읽을 수 없음";
            }
        }

        UpdateRecordArchiveButtonColors();
        UpdateRecordDeleteButton();
        PlayPageSound();
        RefreshRecordArchiveScroll();
    }

    private void RequestDeleteSelectedRecord()
    {
        string path = GetSelectedRecordPath();
        if (string.IsNullOrWhiteSpace(path))
        {
            statusText.text = "삭제할 기록이 없습니다";
            UpdateRecordDeleteButton();
            return;
        }

        if (string.Equals(pendingDeleteRecordPath, path, StringComparison.OrdinalIgnoreCase) && Time.realtimeSinceStartup <= pendingDeleteRecordUntil)
        {
            DeleteSelectedRecord(path);
            return;
        }

        pendingDeleteRecordPath = path;
        pendingDeleteRecordUntil = Time.realtimeSinceStartup + 4f;
        statusText.text = "한 번 더 누르면 선택한 기록이 삭제됩니다";
        UpdateRecordDeleteButton();
    }

    private void DeleteSelectedRecord(string path)
    {
        try
        {
            if (File.Exists(path))
            {
                File.Delete(path);
            }
            string companionPath = GetIntervieweeMessagePathForEndingRecord(path);
            if (!string.IsNullOrWhiteSpace(companionPath) && File.Exists(companionPath))
            {
                File.Delete(companionPath);
            }

            pendingDeleteRecordPath = string.Empty;
            pendingDeleteRecordUntil = 0f;
            selectedRecordArchiveIndex = Mathf.Max(0, selectedRecordArchiveIndex - 1);
            RefreshRecordArchive();
            PlaySound(confirmClip);
            statusText.text = "선택한 기록을 삭제했습니다";
        }
        catch (Exception ex)
        {
            ResetRecordDeletePrompt();
            statusText.text = "기록을 삭제할 수 없습니다";
            Debug.LogWarning($"Failed to delete ending record: {ex.Message}");
            UpdateRecordDeleteButton();
        }
    }

    private static string GetIntervieweeMessagePathForEndingRecord(string endingRecordPath)
    {
        if (string.IsNullOrWhiteSpace(endingRecordPath)) return string.Empty;
        string directory = Path.GetDirectoryName(endingRecordPath);
        string name = Path.GetFileNameWithoutExtension(endingRecordPath);
        if (string.IsNullOrWhiteSpace(directory) || string.IsNullOrWhiteSpace(name)) return string.Empty;
        if (!name.StartsWith("ending-", StringComparison.Ordinal)) return string.Empty;
        string stamp = name.Substring("ending-".Length);
        return Path.Combine(directory, $"message-to-interviewee-{stamp}.txt");
    }

    private string GetSelectedRecordPath()
    {
        if (recordArchivePaths == null) return string.Empty;
        if (selectedRecordArchiveIndex < 0 || selectedRecordArchiveIndex >= recordArchivePaths.Length) return string.Empty;
        if (selectedRecordArchiveIndex >= RecordArchiveSlotCount) return string.Empty;
        return recordArchivePaths[selectedRecordArchiveIndex];
    }

    private void ResetRecordDeletePrompt()
    {
        pendingDeleteRecordPath = string.Empty;
        pendingDeleteRecordUntil = 0f;
    }

    private void CancelPendingRecordDelete()
    {
        if (string.IsNullOrWhiteSpace(pendingDeleteRecordPath)) return;

        ResetRecordDeletePrompt();
        statusText.text = "기록 삭제를 취소했습니다";
        UpdateRecordDeleteButton();
    }

    private void UpdateRecordDeleteButton()
    {
        if (recordArchiveDeleteButton == null) return;

        string selectedPath = GetSelectedRecordPath();
        bool hasSelection = !string.IsNullOrWhiteSpace(selectedPath);
        bool awaitingConfirm = hasSelection
            && string.Equals(pendingDeleteRecordPath, selectedPath, StringComparison.OrdinalIgnoreCase)
            && Time.realtimeSinceStartup <= pendingDeleteRecordUntil;

        recordArchiveDeleteButton.interactable = hasSelection;
        Text label = recordArchiveDeleteButton.GetComponentInChildren<Text>();
        if (label != null)
        {
            label.text = awaitingConfirm ? "삭제 확정" : "선택 삭제";
        }

        if (recordArchiveCancelDeleteButton != null)
        {
            recordArchiveCancelDeleteButton.gameObject.SetActive(awaitingConfirm);
            recordArchiveCancelDeleteButton.interactable = awaitingConfirm;
            SetButtonColor(recordArchiveCancelDeleteButton, new Color32(30, 41, 59, 238), Color.white);
        }

        if (recordArchiveDeleteHintPanel != null)
        {
            Stretch(
                recordArchiveDeleteHintPanel.rectTransform,
                new Vector2(0f, 0f),
                new Vector2(1f, 0f),
                new Vector2(awaitingConfirm ? 612f : 486f, 42f),
                new Vector2(-212f, 88f));
        }

        if (recordArchiveDeleteHintText != null)
        {
            if (!hasSelection)
            {
                recordArchiveDeleteHintText.text = recordArchivePaths == null || recordArchivePaths.Length == 0
                    ? "저장한 마무리 기록이 아직 없습니다."
                    : "삭제할 기록을 먼저 선택하세요.";
                recordArchiveDeleteHintText.color = RecordArchivePreviewMutedColor;
                if (recordArchiveDeleteHintPanel != null) recordArchiveDeleteHintPanel.color = new Color(1f, 0.99f, 0.95f, 0.58f);
            }
            else if (awaitingConfirm)
            {
                recordArchiveDeleteHintText.text = "기록이 완전히 지워집니다. 계속하려면 삭제 확정을 누르세요.";
                recordArchiveDeleteHintText.color = new Color32(153, 27, 27, 245);
                if (recordArchiveDeleteHintPanel != null) recordArchiveDeleteHintPanel.color = new Color(0.99f, 0.88f, 0.82f, 0.92f);
            }
            else
            {
                recordArchiveDeleteHintText.text = "선택 삭제는 한 번 더 확인한 뒤 실행됩니다.";
                recordArchiveDeleteHintText.color = RecordArchivePreviewMutedColor;
                if (recordArchiveDeleteHintPanel != null) recordArchiveDeleteHintPanel.color = new Color(1f, 0.99f, 0.95f, 0.66f);
            }
        }

        SetButtonColor(
            recordArchiveDeleteButton,
            !hasSelection
                ? new Color(0.78f, 0.80f, 0.82f, 0.70f)
                : (awaitingConfirm ? (Color)new Color32(185, 28, 28, 235) : (Color)new Color32(133, 111, 82, 230)),
            !hasSelection ? (Color)new Color32(71, 85, 105, 230) : Color.white);
    }

    private void UpdateRecordDeletePromptTimeout()
    {
        if (string.IsNullOrWhiteSpace(pendingDeleteRecordPath)) return;
        if (Time.realtimeSinceStartup <= pendingDeleteRecordUntil) return;

        ResetRecordDeletePrompt();
        UpdateRecordDeleteButton();
    }

    private void UpdateRecordArchiveButtonColors()
    {
        if (recordArchiveButtons == null) return;
        for (int i = 0; i < recordArchiveButtons.Length; i++)
        {
            Button button = recordArchiveButtons[i];
            if (button == null || !button.gameObject.activeSelf) continue;

            bool selected = i == selectedRecordArchiveIndex;
            SetButtonColor(
                button,
                selected ? (Color)new Color32(177, 113, 58, 235) : new Color(1f, 0.99f, 0.95f, 0.96f),
                selected ? Color.white : (Color)new Color32(30, 41, 59, 255));
        }
    }

    private static string FormatRecordArchiveLabel(string path)
    {
        string dateLabel = FormatRecordArchiveShortDateLabel(path);
        string metaLabel = ExtractRecordMetaLabel(path);
        string lead = string.IsNullOrWhiteSpace(metaLabel) ? dateLabel : $"{dateLabel} · {metaLabel}";
        string quote = ExtractRecordQuote(path);
        if (string.IsNullOrWhiteSpace(quote)) return lead;
        return $"{lead}\n{ShortenForCard(quote, 20)}";
    }

    private static string BuildRecordArchivePreviewHeader(string path)
    {
        string dateLabel = FormatRecordArchiveDateLabel(path);
        string metaLabel = ExtractRecordMetaLabel(path);
        string quote = ExtractRecordQuote(path);
        string lead = string.IsNullOrWhiteSpace(metaLabel) ? dateLabel : $"{dateLabel} · {metaLabel}";
        return string.IsNullOrWhiteSpace(quote)
            ? lead
            : $"{lead} · {ShortenForCard(quote, 34)}";
    }

    private static string FormatRecordArchiveShortDateLabel(string path)
    {
        string full = FormatRecordArchiveDateLabel(path);
        return full.Length >= 16 && full[4] == '.' ? full.Substring(5) : full;
    }

    private static string FormatRecordArchiveDateLabel(string path)
    {
        string name = Path.GetFileNameWithoutExtension(path);
        string dateLabel = string.IsNullOrWhiteSpace(name) ? "마무리 기록" : name;
        if (!string.IsNullOrWhiteSpace(name) && name.StartsWith("ending-", StringComparison.Ordinal) && name.Length >= 22)
        {
            string stamp = name.Substring(7, 15);
            if (stamp.Length == 15)
            {
                dateLabel = $"{stamp.Substring(0, 4)}.{stamp.Substring(4, 2)}.{stamp.Substring(6, 2)} {stamp.Substring(9, 2)}:{stamp.Substring(11, 2)}";
            }
        }

        return dateLabel;
    }

    private static string ExtractRecordMetaLabel(string path)
    {
        try
        {
            string[] lines = File.ReadAllLines(path, Encoding.UTF8);
            string turns = ExtractRecordField(lines, "문답 수:");
            string scenes = ExtractRecordField(lines, "열린 장면:");

            List<string> parts = new List<string>();
            if (!string.IsNullOrWhiteSpace(turns))
            {
                parts.Add($"{turns.Trim()}문답");
            }
            if (!string.IsNullOrWhiteSpace(scenes))
            {
                parts.Add($"장면 {scenes.Trim()}");
            }

            return string.Join(" · ", parts.ToArray());
        }
        catch (Exception)
        {
            return string.Empty;
        }
    }

    private static string ExtractRecordField(string[] lines, string prefix)
    {
        if (lines == null) return string.Empty;
        foreach (string rawLine in lines)
        {
            string line = rawLine != null ? rawLine.Trim() : string.Empty;
            if (!line.StartsWith(prefix, StringComparison.Ordinal)) continue;
            return line.Substring(prefix.Length).Trim();
        }

        return string.Empty;
    }

    private static string ExtractRecordQuote(string path)
    {
        try
        {
            string[] lines = File.ReadAllLines(path, Encoding.UTF8);
            for (int i = 0; i < lines.Length; i++)
            {
                if (lines[i].Trim() != "오늘 남길 문장") continue;

                for (int j = i + 1; j < lines.Length; j++)
                {
                    string line = lines[j].Trim();
                    if (!string.IsNullOrWhiteSpace(line)) return line;
                }
            }
        }
        catch (Exception)
        {
            return string.Empty;
        }

        return string.Empty;
    }

    private void RefreshRecordArchiveScroll()
    {
        if (recordArchivePreviewText == null || recordArchiveContentRect == null || recordArchiveScrollRect == null) return;

        Canvas.ForceUpdateCanvases();
        float minHeight = recordArchiveViewportRect != null ? recordArchiveViewportRect.rect.height + 1f : 360f;
        float preferred = recordArchivePreviewText.preferredHeight + 32f;
        recordArchiveContentRect.sizeDelta = new Vector2(0f, Mathf.Max(minHeight, preferred));
        Canvas.ForceUpdateCanvases();
        recordArchiveScrollRect.verticalNormalizedPosition = 1f;
    }

    private void UpdateSettingsControls()
    {
        if (settingsTextSizeButtons != null)
        {
            int[] levels = { -1, 0, 1 };
            for (int i = 0; i < settingsTextSizeButtons.Length; i++)
            {
                bool selected = dialogueSizeLevel == levels[i];
                SetButtonColor(
                    settingsTextSizeButtons[i],
                    selected ? new Color32(177, 113, 58, 245) : new Color32(30, 41, 59, 238),
                    Color.white);
            }
        }

        if (fullscreenButton != null)
        {
            Text label = fullscreenButton.GetComponentInChildren<Text>();
            if (label != null) label.text = fullscreenEnabled ? "창 모드로 전환" : "전체 화면으로 전환";
            SetButtonColor(fullscreenButton, new Color32(30, 41, 59, 238), Color.white);
        }

        if (soundButton != null)
        {
            Text label = soundButton.GetComponentInChildren<Text>();
            if (label != null) label.text = GetSoundLevelLabel();
            SetButtonColor(
                soundButton,
                soundLevel == 0 ? new Color32(71, 85, 105, 220) : new Color32(177, 113, 58, 238),
                Color.white);
        }

        if (reducedMotionButton != null)
        {
            Text label = reducedMotionButton.GetComponentInChildren<Text>();
            if (label != null) label.text = reducedMotionEnabled ? "움직임 줄임 켜짐" : "움직임 줄임 꺼짐";
            SetButtonColor(
                reducedMotionButton,
                reducedMotionEnabled ? new Color32(177, 113, 58, 238) : new Color32(30, 41, 59, 238),
                Color.white);
        }

        if (highContrastButton != null)
        {
            Text label = highContrastButton.GetComponentInChildren<Text>();
            if (label != null) label.text = highContrastEnabled ? "읽기 쉬움 켜짐" : "읽기 쉬움 꺼짐";
            SetButtonColor(
                highContrastButton,
                highContrastEnabled ? new Color32(177, 113, 58, 238) : new Color32(30, 41, 59, 238),
                Color.white);
        }

        if (localAnswerOnlyButton != null)
        {
            Text label = localAnswerOnlyButton.GetComponentInChildren<Text>();
            if (label != null) label.text = serverReady ? "서버 정상" : "서버 확인";
            localAnswerOnlyButton.interactable = true;
            SetButtonColor(
                localAnswerOnlyButton,
                serverReady ? new Color32(177, 113, 58, 238) : new Color32(30, 41, 59, 238),
                Color.white);
        }
    }

    private static void SetButtonColor(Button button, Color background, Color textColor)
    {
        if (button == null) return;
        Image image = button.GetComponent<Image>();
        if (image != null) image.color = background;

        ColorBlock colors = button.colors;
        colors.normalColor = background;
        colors.highlightedColor = Color.Lerp(background, Color.white, 0.14f);
        colors.pressedColor = Color.Lerp(background, Color.black, 0.12f);
        colors.disabledColor = new Color(background.r, background.g, background.b, Mathf.Clamp01(Mathf.Max(background.a * 0.72f, 0.34f)));
        button.colors = colors;

        Text label = button.GetComponentInChildren<Text>();
        if (label != null) label.color = textColor;
    }

    private InputField CreateInput(Transform parent)
    {
        GameObject root = new GameObject("Question Input", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(InputField));
        root.transform.SetParent(parent, false);
        Image background = root.GetComponent<Image>();
        background.color = new Color(1.000f, 0.985f, 0.940f, 0.92f);
        background.sprite = GetPaperRoundedSprite(5, 31);
        background.type = Image.Type.Sliced;

        Image lowerRule = CreatePanel("Question Input Writing Rule", root.transform, new Color(0.48f, 0.36f, 0.20f, 0.24f));
        lowerRule.raycastTarget = false;
        Stretch(lowerRule.rectTransform, Vector2.zero, Vector2.one, new Vector2(12f, 6f), new Vector2(-12f, 7f));

        Image leftFiber = CreateRoundedPanel("Question Input Torn Fiber", root.transform, new Color(0.70f, 0.44f, 0.23f, 0.12f), 2);
        leftFiber.raycastTarget = false;
        Stretch(leftFiber.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(7f, 5f), new Vector2(10f, -5f));

        GameObject textObject = new GameObject("Text", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
        textObject.transform.SetParent(root.transform, false);
        Text text = textObject.GetComponent<Text>();
        ApplyTextStyle(text, "", 18, new Color32(30, 41, 59, 240), TextAnchor.MiddleLeft, FontStyle.Normal);
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(20f, 2f), new Vector2(-14f, 2f));

        GameObject placeholderObject = new GameObject("Placeholder", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
        placeholderObject.transform.SetParent(root.transform, false);
        Text placeholder = placeholderObject.GetComponent<Text>();
        ApplyTextStyle(placeholder, "질문을 입력하세요", 18, new Color32(71, 85, 105, 172), TextAnchor.MiddleLeft, FontStyle.Normal);
        Stretch(placeholder.rectTransform, Vector2.zero, Vector2.one, new Vector2(20f, 2f), new Vector2(-14f, 2f));

        InputField field = root.GetComponent<InputField>();
        field.textComponent = text;
        field.placeholder = placeholder;
        field.lineType = InputField.LineType.SingleLine;
        field.characterLimit = 1000;
        field.onEndEdit.AddListener(_ =>
        {
            if (IsSubmitKeyDown())
            {
                SubmitCurrentInput();
            }
        });
        return field;
    }

    private InputField CreatePlaytestFeedbackInput(Transform parent)
    {
        GameObject root = new GameObject("Playtest Feedback Input", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(InputField));
        root.transform.SetParent(parent, false);
        Image background = root.GetComponent<Image>();
        background.color = new Color(1f, 0.99f, 0.95f, 0.96f);
        background.sprite = GetRoundedSprite(18);
        background.type = Image.Type.Sliced;

        GameObject textObject = new GameObject("Text", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
        textObject.transform.SetParent(root.transform, false);
        Text text = textObject.GetComponent<Text>();
        ApplyTextStyle(text, "", 16, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Normal);
        text.lineSpacing = 1.08f;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(18f, 14f), new Vector2(-18f, -14f));

        GameObject placeholderObject = new GameObject("Placeholder", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
        placeholderObject.transform.SetParent(root.transform, false);
        Text placeholder = placeholderObject.GetComponent<Text>();
        ApplyTextStyle(placeholder, "예: 질문 흐름은 좋았지만 기록 저장 전 안내가 더 필요했습니다.", 16, new Color32(100, 116, 139, 255), TextAnchor.UpperLeft, FontStyle.Normal);
        placeholder.lineSpacing = 1.08f;
        Stretch(placeholder.rectTransform, Vector2.zero, Vector2.one, new Vector2(18f, 14f), new Vector2(-18f, -14f));

        InputField field = root.GetComponent<InputField>();
        field.textComponent = text;
        field.placeholder = placeholder;
        field.lineType = InputField.LineType.MultiLineNewline;
        field.characterLimit = 600;
        field.selectionColor = new Color(0.70f, 0.45f, 0.23f, 0.18f);
        return field;
    }

    private InputField CreateClosingMessageInput(Transform parent)
    {
        GameObject root = new GameObject("Closing Message Input", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(InputField));
        root.transform.SetParent(parent, false);
        Image background = root.GetComponent<Image>();
        background.color = new Color(1f, 0.99f, 0.95f, 0.96f);
        background.sprite = GetPaperRoundedSprite(8, 41);
        background.type = Image.Type.Sliced;

        GameObject textObject = new GameObject("Text", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
        textObject.transform.SetParent(root.transform, false);
        Text text = textObject.GetComponent<Text>();
        ApplyTextStyle(text, "", 15, new Color32(15, 23, 42, 255), TextAnchor.UpperLeft, FontStyle.Normal);
        text.lineSpacing = 1.08f;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(14f, 10f), new Vector2(-14f, -10f));

        GameObject placeholderObject = new GameObject("Placeholder", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
        placeholderObject.transform.SetParent(root.transform, false);
        Text placeholder = placeholderObject.GetComponent<Text>();
        ApplyTextStyle(placeholder, "예: 오늘 이야기를 들으며 어떤 점을 새롭게 보게 되었는지 남겨 주세요.", 14, new Color32(100, 116, 139, 230), TextAnchor.UpperLeft, FontStyle.Normal);
        placeholder.lineSpacing = 1.08f;
        Stretch(placeholder.rectTransform, Vector2.zero, Vector2.one, new Vector2(14f, 10f), new Vector2(-14f, -10f));

        InputField field = root.GetComponent<InputField>();
        field.textComponent = text;
        field.placeholder = placeholder;
        field.lineType = InputField.LineType.MultiLineNewline;
        field.characterLimit = 360;
        field.selectionColor = new Color(0.70f, 0.45f, 0.23f, 0.18f);
        return field;
    }

    private Button CreateButton(string name, Transform parent, string label, Color background, Color textColor, int fontSize)
    {
        GameObject root = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button));
        root.transform.SetParent(parent, false);
        Image image = root.GetComponent<Image>();
        image.sprite = GetRoundedSprite(9);
        image.type = Image.Type.Sliced;
        image.color = background;

        Image topEdge = CreatePanel("Button Top Edge", root.transform, new Color(1f, 0.90f, 0.64f, 0.055f));
        topEdge.raycastTarget = false;
        Stretch(topEdge.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(3f, -4f), new Vector2(-3f, -2f));

        Image bottomShade = CreatePanel("Button Bottom Shade", root.transform, new Color(0f, 0f, 0f, 0.045f));
        bottomShade.raycastTarget = false;
        Stretch(bottomShade.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(3f, 2f), new Vector2(-3f, 4f));

        Button button = root.GetComponent<Button>();
        ColorBlock colors = button.colors;
        colors.normalColor = background;
        colors.highlightedColor = Color.Lerp(background, Color.white, 0.14f);
        colors.pressedColor = Color.Lerp(background, Color.black, 0.12f);
        colors.disabledColor = new Color(0.25f, 0.29f, 0.35f, 0.65f);
        button.colors = colors;
        button.onClick.AddListener(PlayButtonSound);

        Text text = CreateText("Label", root.transform, label, fontSize, textColor, TextAnchor.MiddleCenter, FontStyle.Bold);
        text.resizeTextForBestFit = true;
        text.resizeTextMinSize = 11;
        text.resizeTextMaxSize = fontSize;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(12f, 4f), new Vector2(-12f, -4f));
        return button;
    }

    private Button CreateStartUtilityButton(string name, Transform parent, string label)
    {
        Color background = new Color(0.030f, 0.024f, 0.018f, 0.34f);
        GameObject root = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button));
        root.transform.SetParent(parent, false);

        Image image = root.GetComponent<Image>();
        image.sprite = GetRoundedSprite(5);
        image.type = Image.Type.Sliced;
        image.color = background;

        Image underline = CreatePanel("Start Utility Underline", root.transform, new Color(0.96f, 0.62f, 0.30f, 0.52f));
        underline.raycastTarget = false;
        Stretch(underline.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(8f, 5f), new Vector2(-8f, 7f));

        Button button = root.GetComponent<Button>();
        ColorBlock colors = button.colors;
        colors.normalColor = background;
        colors.highlightedColor = new Color(0.16f, 0.11f, 0.07f, 0.56f);
        colors.pressedColor = new Color(0.70f, 0.44f, 0.23f, 0.42f);
        colors.disabledColor = new Color(0.08f, 0.07f, 0.06f, 0.18f);
        button.colors = colors;
        button.onClick.AddListener(PlayButtonSound);

        Text text = CreateText("Label", root.transform, label, 15, new Color32(236, 224, 198, 238), TextAnchor.MiddleCenter, FontStyle.Bold);
        text.resizeTextForBestFit = true;
        text.resizeTextMinSize = 11;
        text.resizeTextMaxSize = 15;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(8f, 2f), new Vector2(-8f, -4f));
        return button;
    }

    private static void StyleStartMenuButtonLabel(Button button, int fontSize)
    {
        if (button == null) return;

        Text text = FindChildText(button.transform, "Label");
        if (text == null) return;

        text.alignment = TextAnchor.MiddleLeft;
        text.fontSize = fontSize;
        text.resizeTextMinSize = 12;
        text.resizeTextMaxSize = fontSize;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(28f, 4f), new Vector2(-18f, -4f));
    }

    private static void AddTextShadow(Text text, Color color, Vector2 distance)
    {
        if (text == null) return;

        Shadow shadow = text.gameObject.AddComponent<Shadow>();
        shadow.effectColor = color;
        shadow.effectDistance = distance;
        shadow.useGraphicAlpha = true;
    }

    private Button CreateSceneClueSlipButton(string name, Transform parent, int index)
    {
        Color[] papers =
        {
            new Color(0.052f, 0.039f, 0.028f, 0.76f),
            new Color(0.062f, 0.046f, 0.032f, 0.72f),
            new Color(0.046f, 0.036f, 0.028f, 0.74f)
        };
        Color paper = papers[Mathf.Abs(index) % papers.Length];
        Button button = CreateObjectButtonRoot(name, parent, paper, new Color32(244, 232, 206, 214), 7);
        Transform root = button.transform;

        Transform shadeTransform = root.Find("Object Button Shade");
        if (shadeTransform != null && shadeTransform.TryGetComponent(out Image shadeImage))
        {
            shadeImage.color = new Color(0f, 0f, 0f, 0.040f);
        }

        Image tape = CreateRoundedPanel("Scene Clue Tape", root, new Color(0.90f, 0.80f, 0.58f, 0.10f), 4);
        tape.raycastTarget = false;
        Stretch(tape.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(-38f, -9f), new Vector2(38f, -4f));
        tape.rectTransform.localRotation = Quaternion.Euler(0f, 0f, index % 2 == 0 ? -1.6f : 1.2f);

        Image brassMark = CreateRoundedPanel("Scene Clue Brass Mark", root, new Color(0.78f, 0.54f, 0.28f, 0.32f), 3);
        brassMark.raycastTarget = false;
        Stretch(brassMark.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 1f), new Vector2(12f, 7f), new Vector2(15f, -7f));

        Image pin = CreatePanel("Scene Clue Pin", root, new Color(1f, 0.90f, 0.64f, 0.20f));
        pin.sprite = GetCircleSprite();
        pin.raycastTarget = false;
        Stretch(pin.rectTransform, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(18f, -2f), new Vector2(22f, 2f));

        Image fold = CreateRoundedPanel("Scene Clue Fold", root, new Color(1f, 0.985f, 0.925f, 0.055f), 3);
        fold.raycastTarget = false;
        Stretch(fold.rectTransform, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-24f, -18f), new Vector2(-9f, -5f));

        for (int i = 0; i < 2; i++)
        {
            Image rule = CreatePanel($"Scene Clue Rule {i + 1}", root, new Color(1f, 0.88f, 0.62f, 0.050f));
            rule.raycastTarget = false;
            Stretch(rule.rectTransform, Vector2.zero, Vector2.one, new Vector2(30f, 13f + i * 11f), new Vector2(-18f, 14f + i * 11f));
        }

        Text action = CreateText("Action Label", root, "추천 질문", 11, new Color32(255, 218, 154, 218), TextAnchor.MiddleLeft, FontStyle.Bold);
        action.resizeTextForBestFit = true;
        action.resizeTextMinSize = 9;
        action.resizeTextMaxSize = 11;
        Stretch(action.rectTransform, Vector2.zero, Vector2.one, new Vector2(24f, 51f), new Vector2(-14f, -7f));

        Text text = CreateText("Label", root, "", 14, new Color32(255, 245, 218, 242), TextAnchor.MiddleLeft, FontStyle.Bold);
        text.resizeTextForBestFit = true;
        text.resizeTextMinSize = 10;
        text.resizeTextMaxSize = 14;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(24f, 7f), new Vector2(-14f, -27f));
        return button;
    }

    private Button CreateNoteIndexTabButton(string name, Transform parent, string label, int index)
    {
        Color[] tabColors =
        {
            new Color(0.965f, 0.930f, 0.820f, 0.88f),
            new Color(0.940f, 0.965f, 0.895f, 0.86f),
            new Color(0.930f, 0.945f, 0.985f, 0.84f)
        };
        Button button = CreateObjectButtonRoot(name, parent, tabColors[Mathf.Abs(index) % tabColors.Length], new Color32(46, 32, 18, 232), 5);
        Transform root = button.transform;

        Image indexStrip = CreatePanel("Note Index Strip", root, new Color(0.84f, 0.58f, 0.30f, 0.14f));
        indexStrip.raycastTarget = false;
        Stretch(indexStrip.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(7f, 5f), new Vector2(12f, -5f));

        Image thumbShadow = CreatePanel("Note Index Fold Shadow", root, new Color(0f, 0f, 0f, 0.016f));
        thumbShadow.raycastTarget = false;
        Stretch(thumbShadow.rectTransform, Vector2.zero, new Vector2(1f, 0f), new Vector2(8f, 3f), new Vector2(-8f, 5f));

        Text text = CreateText("Label", root, label, 14, new Color32(46, 32, 18, 232), TextAnchor.MiddleCenter, FontStyle.Bold);
        text.resizeTextForBestFit = true;
        text.resizeTextMinSize = 11;
        text.resizeTextMaxSize = 14;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(14f, 2f), new Vector2(-8f, -2f));
        return button;
    }

    private Button CreateNotebookChapterButton(string name, Transform parent, string label, int index)
    {
        Color[] papers =
        {
            new Color(0.955f, 0.980f, 0.920f, 0.96f),
            new Color(0.930f, 0.955f, 0.985f, 0.94f)
        };
        Button button = CreateObjectButtonRoot(name, parent, papers[Mathf.Abs(index) % papers.Length], new Color32(15, 23, 42, 248), 6);
        Transform root = button.transform;

        Image punch = CreatePanel("Chapter Punch", root, new Color(1f, 0.88f, 0.62f, 0.045f));
        punch.sprite = GetCircleSprite();
        punch.raycastTarget = false;
        Stretch(punch.rectTransform, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(12f, -5f), new Vector2(22f, 5f));

        Image brassClip = CreateRoundedPanel("Chapter Brass Clip", root, new Color(0.84f, 0.58f, 0.30f, 0.22f), 3);
        brassClip.raycastTarget = false;
        Stretch(brassClip.rectTransform, new Vector2(0f, 0f), new Vector2(0f, 1f), new Vector2(28f, 6f), new Vector2(32f, -6f));

        for (int i = 0; i < 2; i++)
        {
            Image rule = CreatePanel($"Chapter Rule {i + 1}", root, new Color(1f, 0.88f, 0.62f, 0.026f));
            rule.raycastTarget = false;
            Stretch(rule.rectTransform, Vector2.zero, Vector2.one, new Vector2(42f, 9f + i * 12f), new Vector2(-12f, 10f + i * 12f));
        }

        Text text = CreateText("Label", root, label, 15, new Color32(15, 23, 42, 248), TextAnchor.MiddleLeft, FontStyle.Bold);
        text.resizeTextForBestFit = true;
        text.resizeTextMinSize = 11;
        text.resizeTextMaxSize = 15;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(40f, 3f), new Vector2(-8f, -3f));
        return button;
    }

    private Button CreateNoteActionButton(string name, Transform parent, string label, bool primary)
    {
        Color background = primary ? new Color(0.70f, 0.44f, 0.23f, 0.78f) : new Color(0.045f, 0.052f, 0.064f, 0.74f);
        Button button = CreateObjectButtonRoot(name, parent, background, Color.white, 7);
        Transform root = button.transform;

        Image topRule = CreatePanel("Note Action Top Rule", root, new Color(1f, 0.93f, 0.68f, primary ? 0.18f : 0.10f));
        topRule.raycastTarget = false;
        Stretch(topRule.rectTransform, new Vector2(0f, 1f), Vector2.one, new Vector2(10f, -7f), new Vector2(-10f, -5f));

        Image sideMark = CreateRoundedPanel("Note Action Side Mark", root, primary ? new Color(0.98f, 0.90f, 0.66f, 0.50f) : new Color(0.70f, 0.44f, 0.23f, 0.38f), 3);
        sideMark.raycastTarget = false;
        Stretch(sideMark.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(10f, 8f), new Vector2(15f, -8f));

        Text text = CreateText("Label", root, label, 14, new Color(1f, 0.96f, 0.86f, 0.96f), TextAnchor.MiddleLeft, FontStyle.Bold);
        text.resizeTextForBestFit = true;
        text.resizeTextMinSize = 9;
        text.resizeTextMaxSize = 14;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(24f, 4f), new Vector2(-10f, -4f));
        return button;
    }

    private Button CreateClosingChoiceTagButton(string name, Transform parent, string label, int index)
    {
        Color[] papers =
        {
            new Color(1.000f, 0.985f, 0.930f, 0.96f),
            new Color(0.965f, 0.945f, 0.875f, 0.96f),
            new Color(0.940f, 0.965f, 0.895f, 0.94f)
        };
        Button button = CreateObjectButtonRoot(name, parent, papers[Mathf.Abs(index) % papers.Length], new Color32(30, 41, 59, 255), 7);
        Transform root = button.transform;

        Image tab = CreateRoundedPanel("Closing Choice Side Tab", root, new Color32(177, 113, 58, 210), 4);
        tab.raycastTarget = false;
        Stretch(tab.rectTransform, Vector2.zero, new Vector2(0f, 1f), new Vector2(10f, 8f), new Vector2(18f, -8f));

        Image pin = CreatePanel("Closing Choice Pin", root, new Color(0.42f, 0.30f, 0.16f, 0.22f));
        pin.sprite = GetCircleSprite();
        pin.raycastTarget = false;
        Stretch(pin.rectTransform, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-22f, -17f), new Vector2(-12f, -7f));

        Text text = CreateText("Label", root, label, 14, new Color32(30, 41, 59, 255), TextAnchor.MiddleCenter, FontStyle.Bold);
        text.resizeTextForBestFit = true;
        text.resizeTextMinSize = 10;
        text.resizeTextMaxSize = 14;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(20f, 4f), new Vector2(-12f, -4f));
        return button;
    }

    private Button CreateNotebookTabButton(string name, Transform parent, string label)
    {
        Color paper = new Color(0.030f, 0.024f, 0.018f, 0.12f);
        Button button = CreateObjectButtonRoot(name, parent, paper, new Color32(248, 240, 222, 176), 7);
        Transform root = button.transform;

        Transform shadeTransform = root.Find("Object Button Shade");
        if (shadeTransform != null && shadeTransform.TryGetComponent(out Image shadeImage))
        {
            shadeImage.color = new Color(0f, 0f, 0f, 0.010f);
        }

        Image page = CreateRoundedPanel("Notebook Icon Page", root, new Color(0.80f, 0.90f, 0.94f, 0.085f), 3);
        page.raycastTarget = false;
        Stretch(page.rectTransform, Vector2.zero, Vector2.one, new Vector2(10f, 7f), new Vector2(-9f, -6f));

        for (int i = 0; i < 2; i++)
        {
            Image line = CreateRoundedPanel($"Notebook Icon Line {i + 1}", root, new Color(1f, 0.94f, 0.74f, 0.045f), 2);
            line.raycastTarget = false;
            Stretch(line.rectTransform, Vector2.zero, Vector2.one, new Vector2(14f, 11f + i * 5f), new Vector2(-13f, 12f + i * 5f));
        }

        Text text = CreateText("Label", root, label, 13, new Color(1f, 0.96f, 0.86f, 0.62f), TextAnchor.MiddleCenter, FontStyle.Bold);
        text.resizeTextForBestFit = true;
        text.resizeTextMinSize = 9;
        text.resizeTextMaxSize = 13;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(5f, 2f), new Vector2(-5f, -2f));
        return button;
    }

    private Button CreateBookmarkButton(string name, Transform parent, string label)
    {
        Color paper = new Color(0.030f, 0.024f, 0.018f, 0.10f);
        Button button = CreateObjectButtonRoot(name, parent, paper, new Color(1f, 0.96f, 0.86f, 0.50f), 7);
        Transform root = button.transform;

        Transform shadeTransform = root.Find("Object Button Shade");
        if (shadeTransform != null && shadeTransform.TryGetComponent(out Image shadeImage))
        {
            shadeImage.color = new Color(0f, 0f, 0f, 0.010f);
        }

        Image body = CreateRoundedPanel("Bookmark Icon Body", root, new Color(0.94f, 0.70f, 0.42f, 0.095f), 3);
        body.raycastTarget = false;
        Stretch(body.rectTransform, Vector2.zero, Vector2.one, new Vector2(11f, 6f), new Vector2(-11f, -7f));

        Image tail = CreateRoundedPanel("Bookmark Icon Notch", root, new Color(0.030f, 0.024f, 0.018f, 0.0f), 2);
        tail.raycastTarget = false;
        Stretch(tail.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(-4f, 6f), new Vector2(4f, 10f));

        Image shine = CreateRoundedPanel("Bookmark Icon Shine", root, new Color(1f, 0.95f, 0.76f, 0.0f), 2);
        shine.raycastTarget = false;
        Stretch(shine.rectTransform, Vector2.zero, Vector2.one, new Vector2(14f, 8f), new Vector2(16f, -9f));

        Text text = CreateText("Label", root, label, 10, new Color(1f, 0.96f, 0.86f, 0.50f), TextAnchor.MiddleCenter, FontStyle.Bold);
        text.resizeTextForBestFit = true;
        text.resizeTextMinSize = 8;
        text.resizeTextMaxSize = 10;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(12f, 3f), new Vector2(-6f, -3f));
        return button;
    }

    private Button CreatePenTabButton(string name, Transform parent, string label)
    {
        Color brass = new Color(0.70f, 0.44f, 0.23f, 0.26f);
        Button button = CreateObjectButtonRoot(name, parent, brass, new Color(1f, 0.96f, 0.86f, 0.72f), 6);
        Transform root = button.transform;

        Image penBody = CreateRoundedPanel("Pen Body", root, new Color(0.08f, 0.09f, 0.10f, 0.14f), 4);
        penBody.raycastTarget = false;
        Stretch(penBody.rectTransform, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(12f, -1.5f), new Vector2(34f, 1.5f));
        penBody.rectTransform.localRotation = Quaternion.Euler(0f, 0f, -10f);

        Image penTip = CreatePanel("Pen Tip", root, new Color(0.98f, 0.90f, 0.66f, 0.16f));
        penTip.raycastTarget = false;
        Stretch(penTip.rectTransform, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(32f, -1.5f), new Vector2(38f, 1.5f));
        penTip.rectTransform.localRotation = Quaternion.Euler(0f, 0f, -10f);

        Text text = CreateText("Label", root, label, 11, new Color(1f, 0.96f, 0.86f, 0.72f), TextAnchor.MiddleRight, FontStyle.Bold);
        text.resizeTextForBestFit = true;
        text.resizeTextMinSize = 9;
        text.resizeTextMaxSize = 11;
        Stretch(text.rectTransform, Vector2.zero, Vector2.one, new Vector2(38f, 3f), new Vector2(-10f, -3f));
        return button;
    }

    private Button CreateObjectButtonRoot(string name, Transform parent, Color background, Color textColor, int radius)
    {
        GameObject root = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button));
        root.transform.SetParent(parent, false);

        Image image = root.GetComponent<Image>();
        image.sprite = GetRoundedSprite(radius);
        image.type = Image.Type.Sliced;
        image.color = background;

        Image shade = CreatePanel("Object Button Shade", root.transform, new Color(0f, 0f, 0f, 0.045f));
        shade.raycastTarget = false;
        Stretch(shade.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(4f, 3f), new Vector2(-4f, 6f));

        Button button = root.GetComponent<Button>();
        ColorBlock colors = button.colors;
        colors.normalColor = background;
        colors.highlightedColor = Color.Lerp(background, Color.white, 0.12f);
        colors.pressedColor = Color.Lerp(background, Color.black, 0.10f);
        colors.disabledColor = new Color(0.25f, 0.29f, 0.35f, 0.55f);
        button.colors = colors;
        button.onClick.AddListener(PlayButtonSound);

        return button;
    }

    private Scrollbar CreateVerticalScrollbar(string name, Transform parent)
    {
        GameObject root = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Scrollbar));
        root.transform.SetParent(parent, false);
        Image track = root.GetComponent<Image>();
        track.sprite = GetRoundedSprite(3);
        track.type = Image.Type.Sliced;
        track.color = new Color(0.56f, 0.44f, 0.30f, 0.016f);

        GameObject slidingArea = new GameObject("Sliding Area", typeof(RectTransform));
        slidingArea.transform.SetParent(root.transform, false);
        RectTransform slidingAreaRT = slidingArea.GetComponent<RectTransform>();
        Stretch(slidingAreaRT, Vector2.zero, Vector2.one, new Vector2(0f, 4f), new Vector2(0f, -4f));

        GameObject handle = new GameObject("Handle", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
        handle.transform.SetParent(slidingArea.transform, false);
        Image handleImage = handle.GetComponent<Image>();
        handleImage.sprite = GetRoundedSprite(3);
        handleImage.type = Image.Type.Sliced;
        handleImage.color = new Color(0.64f, 0.44f, 0.22f, 0.105f);
        RectTransform handleRT = handle.GetComponent<RectTransform>();
        Stretch(handleRT, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

        Scrollbar scrollbar = root.GetComponent<Scrollbar>();
        scrollbar.direction = Scrollbar.Direction.BottomToTop;
        scrollbar.targetGraphic = handleImage;
        scrollbar.handleRect = handleRT;
        return scrollbar;
    }

    private Image CreatePanel(string name, Transform parent, Color color)
    {
        GameObject root = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
        root.transform.SetParent(parent, false);
        Image image = root.GetComponent<Image>();
        image.color = color;
        return image;
    }

    private Image CreateRoundedPanel(string name, Transform parent, Color color, int radius)
    {
        Image image = CreatePanel(name, parent, color);
        image.sprite = GetRoundedSprite(radius);
        image.type = Image.Type.Sliced;
        return image;
    }

    private Image CreatePaperPanel(string name, Transform parent, Color color, int radius, int grainVariant)
    {
        Image image = CreatePanel(name, parent, color);
        image.sprite = GetPaperRoundedSprite(radius, grainVariant);
        image.type = Image.Type.Sliced;
        return image;
    }

    private Text CreateText(string name, Transform parent, string value, int size, Color color, TextAnchor anchor, FontStyle style)
    {
        GameObject root = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
        root.transform.SetParent(parent, false);
        Text text = root.GetComponent<Text>();
        ApplyTextStyle(text, value, size, color, anchor, style);
        return text;
    }

    private void ApplyTextStyle(Text text, string value, int size, Color color, TextAnchor anchor, FontStyle style)
    {
        Font chosenFont = GetUiFontForStyle(style);
        text.font = chosenFont;
        text.text = value;
        text.fontSize = size;
        text.color = color;
        text.alignment = anchor;
        text.fontStyle = chosenFont == uiFont ? style : FontStyle.Normal;
        text.horizontalOverflow = HorizontalWrapMode.Wrap;
        text.verticalOverflow = VerticalWrapMode.Overflow;
        text.supportRichText = true;
    }

    private static void Stretch(RectTransform rect, Vector2 anchorMin, Vector2 anchorMax, Vector2 offsetMin, Vector2 offsetMax)
    {
        rect.anchorMin = anchorMin;
        rect.anchorMax = anchorMax;
        rect.offsetMin = offsetMin;
        rect.offsetMax = offsetMax;
    }

    private Sprite GetRoundedSprite(int radius)
    {
        string key = $"rounded-{radius}";
        if (generatedSprites.TryGetValue(key, out Sprite sprite)) return sprite;

        const int size = 96;
        Texture2D texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
        texture.wrapMode = TextureWrapMode.Clamp;
        texture.filterMode = FilterMode.Bilinear;

        float r = Mathf.Clamp(radius, 2, size / 2 - 1);
        Color32[] pixels = new Color32[size * size];
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                float cx = x < r ? r : (x > size - r ? size - r : x);
                float cy = y < r ? r : (y > size - r ? size - r : y);
                float distance = Vector2.Distance(new Vector2(x, y), new Vector2(cx, cy));
                float alpha = distance <= r ? 1f : Mathf.Clamp01(r + 1f - distance);
                pixels[y * size + x] = new Color(1f, 1f, 1f, alpha);
            }
        }

        texture.SetPixels32(pixels);
        texture.Apply();
        sprite = Sprite.Create(texture, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100f, 0, SpriteMeshType.FullRect, new Vector4(radius, radius, radius, radius));
        generatedSprites[key] = sprite;
        return sprite;
    }

    private Sprite GetPaperRoundedSprite(int radius, int variant)
    {
        string key = $"paper-rounded-{radius}-{variant}";
        if (generatedSprites.TryGetValue(key, out Sprite sprite)) return sprite;

        const int size = 128;
        Texture2D texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
        texture.wrapMode = TextureWrapMode.Clamp;
        texture.filterMode = FilterMode.Bilinear;

        float r = Mathf.Clamp(radius, 2, size / 2 - 1);
        Color32[] pixels = new Color32[size * size];
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                float cx = x < r ? r : (x > size - r ? size - r : x);
                float cy = y < r ? r : (y > size - r ? size - r : y);
                float distance = Vector2.Distance(new Vector2(x, y), new Vector2(cx, cy));
                float edgeAlpha = distance <= r ? 1f : Mathf.Clamp01(r + 1f - distance);

                float grain = PaperGrainValue(x, y, variant);
                float fiber = Mathf.Sin((x + variant * 13f) * 0.18f + (y - variant * 7f) * 0.045f) * 0.5f + 0.5f;
                float tintValue = Mathf.Clamp01(grain * 0.66f + fiber * 0.34f);
                byte tint = (byte)Mathf.RoundToInt(Mathf.Lerp(238f, 255f, tintValue));

                float fleck = PaperGrainValue(x + 31, y + 47, variant + 17);
                if (fleck > 0.986f)
                {
                    tint = (byte)Mathf.Max(210, tint - 26);
                }

                float alpha = edgeAlpha * Mathf.Lerp(0.94f, 1f, grain);
                pixels[y * size + x] = new Color32(tint, tint, tint, (byte)Mathf.RoundToInt(alpha * 255f));
            }
        }

        texture.SetPixels32(pixels);
        texture.Apply();
        sprite = Sprite.Create(texture, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100f, 0, SpriteMeshType.FullRect, new Vector4(radius, radius, radius, radius));
        generatedSprites[key] = sprite;
        return sprite;
    }

    private static float PaperGrainValue(int x, int y, int variant)
    {
        unchecked
        {
            uint value = (uint)x * 374761393u + (uint)y * 668265263u + (uint)variant * 2246822519u;
            value = (value ^ (value >> 13)) * 1274126177u;
            value ^= value >> 16;
            return (value & 0x00FFFFFFu) / 16777215f;
        }
    }

    private Sprite GetCircleSprite()
    {
        const string key = "circle";
        if (generatedSprites.TryGetValue(key, out Sprite sprite)) return sprite;

        const int size = 96;
        Texture2D texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
        texture.wrapMode = TextureWrapMode.Clamp;
        texture.filterMode = FilterMode.Bilinear;

        float center = (size - 1) * 0.5f;
        float radius = center - 1f;
        Color32[] pixels = new Color32[size * size];
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                float distance = Vector2.Distance(new Vector2(x, y), new Vector2(center, center));
                float alpha = distance <= radius ? 1f : Mathf.Clamp01(radius + 1f - distance);
                pixels[y * size + x] = new Color(1f, 1f, 1f, alpha);
            }
        }

        texture.SetPixels32(pixels);
        texture.Apply();
        sprite = Sprite.Create(texture, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100f);
        generatedSprites[key] = sprite;
        return sprite;
    }

    private Sprite GetSoftEllipseSprite()
    {
        const string key = "soft-ellipse";
        if (generatedSprites.TryGetValue(key, out Sprite sprite)) return sprite;

        const int width = 256;
        const int height = 160;
        Texture2D texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
        texture.wrapMode = TextureWrapMode.Clamp;
        texture.filterMode = FilterMode.Bilinear;

        Color32[] pixels = new Color32[width * height];
        Vector2 center = new Vector2((width - 1) * 0.5f, (height - 1) * 0.5f);
        float radiusX = width * 0.48f;
        float radiusY = height * 0.46f;
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                float dx = (x - center.x) / radiusX;
                float dy = (y - center.y) / radiusY;
                float distance = Mathf.Sqrt(dx * dx + dy * dy);
                float alpha = Mathf.Clamp01(1f - distance);
                alpha = alpha * alpha * (3f - 2f * alpha);
                pixels[y * width + x] = new Color(1f, 1f, 1f, alpha);
            }
        }

        texture.SetPixels32(pixels);
        texture.Apply();
        sprite = Sprite.Create(texture, new Rect(0, 0, width, height), new Vector2(0.5f, 0.5f), 100f);
        generatedSprites[key] = sprite;
        return sprite;
    }

    private Sprite GetDeskOcclusionGradientSprite()
    {
        const string key = "desk_occlusion_gradient_v1";
        if (generatedSprites.TryGetValue(key, out Sprite sprite)) return sprite;

        const int width = 256;
        const int height = 96;
        Texture2D texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
        texture.wrapMode = TextureWrapMode.Clamp;
        texture.filterMode = FilterMode.Bilinear;

        Color32[] pixels = new Color32[width * height];
        for (int y = 0; y < height; y++)
        {
            float y01 = y / (height - 1f);
            float bottomFade = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.00f, 0.16f, y01));
            float topFade = 1f - Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.58f, 0.98f, y01));
            for (int x = 0; x < width; x++)
            {
                float x01 = x / (width - 1f);
                float leftFade = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.00f, 0.08f, x01));
                float rightFade = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(1.00f, 0.92f, x01));
                float grain = PaperGrainValue(x, y, 113) * 0.10f + 0.95f;
                float alpha = Mathf.Clamp01(bottomFade * topFade * Mathf.Min(leftFade, rightFade) * grain);
                pixels[y * width + x] = new Color32(255, 255, 255, (byte)Mathf.RoundToInt(alpha * 255f));
            }
        }

        texture.SetPixels32(pixels);
        texture.Apply();
        sprite = Sprite.Create(texture, new Rect(0, 0, width, height), new Vector2(0.5f, 0.5f), 100f);
        generatedSprites[key] = sprite;
        return sprite;
    }

    private Sprite GetSceneGrainSprite()
    {
        const string key = "scene-grain-v1";
        if (generatedSprites.TryGetValue(key, out Sprite sprite)) return sprite;

        const int width = 384;
        const int height = 216;
        Texture2D texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
        texture.wrapMode = TextureWrapMode.Repeat;
        texture.filterMode = FilterMode.Point;

        Color32[] pixels = new Color32[width * height];
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                float fine = PaperGrainValue(x, y, 43);
                float fiber = PaperGrainValue(x / 2, y / 2, 71);
                float value = Mathf.Clamp01(fine * 0.72f + fiber * 0.28f);
                bool darkSpeck = value < 0.22f;
                bool lightDust = value > 0.92f;
                byte red = darkSpeck ? (byte)38 : (lightDust ? (byte)255 : (byte)148);
                byte green = darkSpeck ? (byte)31 : (lightDust ? (byte)232 : (byte)126);
                byte blue = darkSpeck ? (byte)24 : (lightDust ? (byte)194 : (byte)92);
                float alpha = darkSpeck ? Mathf.Lerp(0.006f, 0.018f, 1f - value) : (lightDust ? Mathf.Lerp(0.003f, 0.010f, value) : 0.0015f);
                pixels[y * width + x] = new Color32(red, green, blue, (byte)Mathf.RoundToInt(alpha * 255f));
            }
        }

        texture.SetPixels32(pixels);
        texture.Apply();
        sprite = Sprite.Create(texture, new Rect(0, 0, width, height), new Vector2(0.5f, 0.5f), 100f);
        generatedSprites[key] = sprite;
        return sprite;
    }

    private Sprite GetSceneVignetteSprite()
    {
        const string key = "scene-vignette-v1";
        if (generatedSprites.TryGetValue(key, out Sprite sprite)) return sprite;

        const int width = 384;
        const int height = 216;
        Texture2D texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
        texture.wrapMode = TextureWrapMode.Clamp;
        texture.filterMode = FilterMode.Bilinear;

        Color32[] pixels = new Color32[width * height];
        for (int y = 0; y < height; y++)
        {
            float y01 = y / (height - 1f);
            for (int x = 0; x < width; x++)
            {
                float x01 = x / (width - 1f);
                float dx = (x01 - 0.50f) / 0.58f;
                float dy = (y01 - 0.48f) / 0.62f;
                float radial = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.48f, 1.22f, dx * dx + dy * dy));
                float top = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.58f, 1.00f, y01));
                float bottom = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.34f, 0.00f, y01));
                float alpha = radial * 0.070f + top * 0.044f + bottom * 0.026f;
                pixels[y * width + x] = new Color32(18, 13, 9, (byte)Mathf.Clamp(Mathf.RoundToInt(alpha * 255f), 0, 255));
            }
        }

        texture.SetPixels32(pixels);
        texture.Apply();
        sprite = Sprite.Create(texture, new Rect(0, 0, width, height), new Vector2(0.5f, 0.5f), 100f);
        generatedSprites[key] = sprite;
        return sprite;
    }

    private Sprite GetAvatarBoundaryBlendSprite()
    {
        const string key = "avatar-boundary-blend-strip-v2";
        if (generatedSprites.TryGetValue(key, out Sprite sprite)) return sprite;

        Texture2D source = LoadBackgroundTexture();
        if (source == null) return null;

        const int startX = 512;
        const int width = 664;
        const int height = 10;
        const float centerCanvasY = 785f;
        Texture2D texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
        texture.name = "avatar_boundary_blend_strip";
        texture.wrapMode = TextureWrapMode.Clamp;
        texture.filterMode = FilterMode.Bilinear;

        Color32[] pixels = new Color32[width * height];
        try
        {
            for (int y = 0; y < height; y++)
            {
                float canvasY = centerCanvasY - height * 0.5f + y;
                float v = Mathf.Clamp01(canvasY / Mathf.Max(1f, TargetHeight - 1f));
                for (int x = 0; x < width; x++)
                {
                    float u = (startX + x) / Mathf.Max(1f, TargetWidth - 1f);
                    Color sample = source.GetPixelBilinear(u, v);
                    sample.r = Mathf.Lerp(sample.r, 1.0f, 0.10f);
                    sample.g = Mathf.Lerp(sample.g, 0.97f, 0.10f);
                    sample.b = Mathf.Lerp(sample.b, 0.90f, 0.10f);
                    float y01 = height <= 1 ? 1f : y / (height - 1f);
                    float edgeFade = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0f, 0.32f, y01)) *
                        Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(1f, 0.68f, y01));
                    sample.a = edgeFade;
                    pixels[y * width + x] = sample;
                }
            }
        }
        catch (Exception ex)
        {
            Debug.LogWarning($"Background texture must be readable for avatar boundary blend strip: {source.name}. {ex.Message}");
            return null;
        }

        texture.SetPixels32(pixels);
        texture.Apply(false, true);
        sprite = Sprite.Create(texture, new Rect(0, 0, width, height), new Vector2(0.5f, 0.5f), 100f);
        generatedSprites[key] = sprite;
        return sprite;
    }

    private Sprite GetBackgroundDeskForegroundSprite()
    {
        const string key = "background-desk-foreground-fresh-v1";
        if (generatedSprites.TryGetValue(key, out Sprite sprite)) return sprite;

        Texture2D source = LoadBackgroundTexture();
        if (source == null) return null;

        Color32[] sourcePixels;
        try
        {
            sourcePixels = source.GetPixels32();
        }
        catch (Exception ex)
        {
            Debug.LogWarning($"Background texture must be readable for desk foreground mask: {source.name}. {ex.Message}");
            return null;
        }

        int width = source.width;
        int height = source.height;
        Color32[] pixels = new Color32[sourcePixels.Length];
        for (int y = 0; y < height; y++)
        {
            float y01 = y / Mathf.Max(1f, height - 1f);
            for (int x = 0; x < width; x++)
            {
                float x01 = x / Mathf.Max(1f, width - 1f);
                float tableTop = 0.326f + Mathf.Sin((x01 - 0.50f) * Mathf.PI) * 0.003f + Mathf.Lerp(0.002f, -0.002f, x01);
                float belowTableTop = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(tableTop + 0.004f, tableTop - 0.004f, y01));
                float leftFade = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.020f, 0.090f, x01));
                float rightFade = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.980f, 0.910f, x01));
                float centralWeight = Mathf.Clamp01(Mathf.Min(leftFade, rightFade));

                float alpha = Mathf.Clamp01(belowTableTop * centralWeight);

                if (alpha <= 0.001f)
                {
                    pixels[y * width + x] = new Color32(0, 0, 0, 0);
                    continue;
                }

                Color32 pixel = sourcePixels[y * width + x];
                float warmWash = 0.001f;
                float lowerGlow = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.0f, tableTop + 0.12f, y01)) * 0.001f;
                float r = Mathf.Lerp(pixel.r, 255f, warmWash + lowerGlow);
                float g = Mathf.Lerp(pixel.g, 247f, warmWash + lowerGlow);
                float b = Mathf.Lerp(pixel.b, 230f, warmWash + lowerGlow);

                pixels[y * width + x] = new Color32(
                    (byte)Mathf.Clamp(Mathf.RoundToInt(r), 0, 255),
                    (byte)Mathf.Clamp(Mathf.RoundToInt(g), 0, 255),
                    (byte)Mathf.Clamp(Mathf.RoundToInt(b), 0, 255),
                    (byte)Mathf.Clamp(Mathf.RoundToInt(alpha * 255f), 0, 255));
            }
        }

        Texture2D texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
        texture.name = "background_desk_foreground_mask";
        texture.wrapMode = TextureWrapMode.Clamp;
        texture.filterMode = FilterMode.Bilinear;
        texture.SetPixels32(pixels);
        texture.Apply(false, true);

        sprite = Sprite.Create(texture, new Rect(0, 0, width, height), new Vector2(0.5f, 0.5f), 100f);
        generatedSprites[key] = sprite;
        return sprite;
    }

    private static float EllipseMask(float x, float y, float centerX, float centerY, float radiusX, float radiusY)
    {
        float dx = (x - centerX) / Mathf.Max(0.0001f, radiusX);
        float dy = (y - centerY) / Mathf.Max(0.0001f, radiusY);
        float distance = Mathf.Sqrt(dx * dx + dy * dy);
        return Mathf.Clamp01(1f - Mathf.SmoothStep(0.72f, 1.0f, distance));
    }

    private static void AddPointerTrigger(EventTrigger trigger, EventTriggerType type, Action action)
    {
        EventTrigger.Entry entry = new EventTrigger.Entry { eventID = type };
        entry.callback.AddListener(_ => action());
        trigger.triggers.Add(entry);
    }

    private void SubmitCurrentInput()
    {
        if (inputField == null) return;

        string question = (inputField.text ?? string.Empty).Trim();
        if (TryStartQuestion(question))
        {
            inputField.text = string.Empty;
            SetDirectInputOpen(false, false);
        }
        else if (string.IsNullOrWhiteSpace(question))
        {
            SetDirectInputOpen(true, true);
        }
    }

    private void SubmitPresetQuestion(string question)
    {
        if (TryStartPreparedQuestion(question) && inputField != null)
        {
            inputField.text = string.Empty;
        }
    }

    private void SubmitChapterQuestion(string chapter)
    {
        if (busy) return;
        RefreshVisibleLeadQuestions();
    }

    private void SubmitMore()
    {
        if (completionChoiceObject != null && completionChoiceObject.activeSelf)
        {
            completionChoiceObject.SetActive(false);
        }

        if (IsCompletedFiveTurnSession())
        {
            ContinueToNextQuestionCategory();
            return;
        }

        SubmitPresetQuestion(GetLeadQuestion(0));
    }

    private bool TryStartPreparedQuestion(string question)
    {
        if (storyModeActive)
        {
            StopStoryMode("추천 질문으로 전환합니다");
        }

        if (pendingClosingSensitiveQuestion)
        {
            AnswerClosingSensitiveQuestion(question);
            return false;
        }

        if (IsCompletedFiveTurnSession())
        {
            if (pendingCompletionChoiceAfterDialogue && HasUnreadDialoguePage())
            {
                statusText.text = "마지막 답변을 끝까지 읽은 뒤 선택해 주세요";
                UpdateDialoguePageCue();
                return false;
            }

            statusText.text = $"{BuildActiveCategoryLabel()} {RequiredQuestionCount}문답을 마쳤습니다 · 5개 더 물어보기 또는 끝내기를 선택하세요";
            ShowCompletionChoiceOverlay();
            return false;
        }

        if (busy || string.IsNullOrWhiteSpace(question)) return false;
        if (lastSubmitFrame == Time.frameCount) return false;

        lastSubmitFrame = Time.frameCount;
        HideHotspotLabels();
        busy = true;
        PlaySound(questionSelectClip);
        StartCoroutine(SendPreparedQuestion(question.Trim()));
        return true;
    }

    private void ShowEvidence()
    {
        if (busy) return;
        SetQuestionNoteOpen(true);
        ShowNoteTab(1);
    }

    private void ShowClosingCard()
    {
        if (storyModeActive)
        {
            StopStoryMode("이야기 모드를 멈추고 마무리 카드를 엽니다");
        }

        if (completionChoiceObject != null && completionChoiceObject.activeSelf)
        {
            completionChoiceObject.SetActive(false);
        }

        if (busy || !IsCompletedFiveTurnSession()) return;
        if (pendingCompletionChoiceAfterDialogue)
        {
            if (HasUnreadDialoguePage())
            {
                statusText.text = "마지막 답변을 끝까지 읽은 뒤 선택해 주세요";
                UpdateDialoguePageCue();
                return;
            }

            ShowCompletionChoiceOverlay();
            return;
        }

        if (pendingClosingSensitiveQuestion)
        {
            statusText.text = "마지막 질문을 하나만 골라 주세요";
            SetLeadButtonsInteractable(true);
            return;
        }
        if (ShouldAskClosingSensitiveQuestion())
        {
            ShowClosingSensitiveQuestionStep();
            return;
        }

        ShowClosingCardNow();
    }

    private bool ShouldAskClosingSensitiveQuestion()
    {
        return !closingSensitiveQuestionAnswered
            && !pendingClosingSensitiveQuestion
            && closingSensitiveQuestions != null
            && closingSensitiveQuestions.Length >= 6;
    }

    private void ShowClosingSensitiveQuestionStep()
    {
        pendingClosingSensitiveQuestion = true;
        selectedClosingSensitiveQuestion = string.Empty;
        selectedClosingSensitiveAnswer = string.Empty;

        if (closingCardObject != null) closingCardObject.SetActive(false);
        if (closingSensitiveQuestionObject != null) closingSensitiveQuestionObject.SetActive(true);
        SetQuestionNoteOpen(false);
        SetExpression(ExpressionState.Empathetic);
        PresentAssistant("끝내기 전에 말로 묻기 어려운 질문을 하나만 골라 주세요. 카드 하나를 고르면 짧게 답하고 마무리 화면으로 넘어갑니다.", "마지막 질문");
        AppendMessage("마지막 질문 안내", "끝내기 전에 말로 묻기 어려운 질문을 하나만 골라 주세요.", "#5b21b6");
        SetLeadButtonsInteractable(false);
        UpdateLeadSelectionStyles();
        UpdateLeadSlipVisibility();
        statusText.text = "마지막 질문을 하나만 골라 주세요";
        SelectFirstInteractable(closingSensitiveQuestionObject, "Closing Sensitive Question Card");
        SaveSession();
    }

    private void AnswerClosingSensitiveQuestion(string question)
    {
        if (!pendingClosingSensitiveQuestion || string.IsNullOrWhiteSpace(question)) return;

        int index = 0;
        for (int i = 0; i < closingSensitiveQuestions.Length; i++)
        {
            if (string.Equals(BuildLeadQuestionKey(closingSensitiveQuestions[i]), BuildLeadQuestionKey(question), StringComparison.Ordinal))
            {
                index = i;
                break;
            }
        }

        string answer = closingSensitiveAnswers[Mathf.Clamp(index, 0, closingSensitiveAnswers.Length - 1)];
        pendingClosingSensitiveQuestion = false;
        closingSensitiveQuestionAnswered = true;
        selectedClosingSensitiveQuestion = closingSensitiveQuestions[Mathf.Clamp(index, 0, closingSensitiveQuestions.Length - 1)];
        selectedClosingSensitiveAnswer = answer;
        if (closingSensitiveQuestionObject != null) closingSensitiveQuestionObject.SetActive(false);

        AppendMessage("나", selectedClosingSensitiveQuestion, "#334155");
        AppendMessage("답변", answer, "#0f766e");
        history.Add(new ChatMessage { role = "user", content = selectedClosingSensitiveQuestion });
        history.Add(new ChatMessage { role = "assistant", content = answer });
        TrimHistory();

        SetLeadButtonsInteractable(false);
        SetExpression(ExpressionState.Empathetic);
        PresentAssistant(answer, "마지막 답변");
        PlaySound(answerReadyClip);
        statusText.text = "마지막 답변입니다 · 읽은 뒤 끝내기를 눌러 마무리하세요";
        UpdateActionButtons();
        SaveSession();
    }

    private void ShowClosingCardNow()
    {
        string closing = BuildConversationClosingPrompt();

        pendingClosingSensitiveQuestion = false;
        pendingCompletionChoiceAfterDialogue = false;
        if (closingSensitiveQuestionObject != null) closingSensitiveQuestionObject.SetActive(false);
        SetExpression(ExpressionState.Empathetic);
        PresentAssistant(closing, "마무리 카드");
        AppendMessage("마무리", closing, "#5b21b6");
        SelectClosingCard(GetRecommendedClosingIndex());
        if (closingCardObject != null) closingCardObject.SetActive(true);
        SetDialogueScrollCueVisible(false);
        if (closingMessageInput != null && string.IsNullOrWhiteSpace(closingMessageInput.text) && !string.IsNullOrWhiteSpace(closingMessageToInterviewee))
        {
            closingMessageInput.text = closingMessageToInterviewee;
        }
        if (closingMessageValidationText != null)
        {
            bool hasMessage = !string.IsNullOrWhiteSpace(GetClosingMessageToInterviewee());
            closingMessageValidationText.text = hasMessage ? "저장할 준비가 되었습니다." : "남길 말을 먼저 입력해 주세요.";
            closingMessageValidationText.color = hasMessage ? new Color32(22, 101, 52, 245) : new Color32(124, 45, 18, 245);
        }
        if (closingCardContinueButton != null)
        {
            closingCardContinueButton.gameObject.SetActive(false);
            closingCardContinueButton.interactable = false;
        }
        if (closingCardSaveButton != null) closingCardSaveButton.gameObject.SetActive(false);
        if (closingCardCloseButton != null)
        {
            closingCardCloseButton.gameObject.SetActive(true);
            closingCardCloseButton.interactable = true;
        }
        closingCreditsStartedAt = Time.unscaledTime;
        SelectFirstInteractable(closingCardObject, "Closing Card Close");
        ShowHotspotLabels();
        PlaySound(resultCardClip);
        statusText.text = $"{BuildActiveCategoryLabel()} {RequiredQuestionCount}문답 마무리 화면을 열었습니다";
    }

    private void CompleteFiveQuestionSession()
    {
        busy = false;
        if (sendButton != null) sendButton.interactable = false;
        if (micButton != null) micButton.interactable = false;
        SetFlowButtonsInteractable(false);
        UpdateQuestionInputLayout();
        UpdateQuestionPhoneProgress();
        UpdateActionButtons();
        SaveSession();
        pendingCompletionChoiceAfterDialogue = true;
        statusText.text = $"{BuildActiveCategoryLabel()} {RequiredQuestionCount}문답 완료 · 답변을 끝까지 읽은 뒤 선택하세요";
        UpdateDialoguePageCue();
    }

    private string BuildConversationClosingPrompt()
    {
        string sceneLine = BuildConversationThemeLine();
        string questionFlow = BuildClosingQuestionFlowLine(RequiredQuestionCount, 220);
        string coreQa = BuildClosingQuestionAnswerLine(180);
        string nextLine = "5개를 더 물어볼 수도 있고, 여기서 기록하고 끝낼 수도 있습니다.";
        return $"오늘의 대화에서 질문 5개를 마쳤습니다. 아래에 대상자에게 남길 말을 적어 주세요.\n\n{sceneLine}\n질문 흐름: {questionFlow}\n대표 질답: {coreQa}\n\n{nextLine}";
    }

    private string BuildConversationThemeLine()
    {
        List<string> opened = GetOpenedMemoryLines();
        if (opened.Count > 0)
        {
            int limit = Mathf.Min(opened.Count, 3);
            List<string> compact = new List<string>();
            for (int i = 0; i < limit; i++)
            {
                string line = opened[i];
                int dash = line.IndexOf(" - ", StringComparison.Ordinal);
                compact.Add(dash >= 0 ? line.Substring(0, dash).Trim() : line.Trim());
            }

            return "오늘 대화에서 열린 장면: " + string.Join(", ", compact.ToArray());
        }

        string theme = CanonicalTheme(lastTheme);
        if (!string.IsNullOrWhiteSpace(theme))
        {
            return $"오늘 대화에서 붙잡은 장면: {theme}";
        }

        return "오늘 대화에서 붙잡은 장면을 마지막 카드에 남깁니다.";
    }

    private string BuildClosingQuestionFlowLine(int maxQuestions, int maxLength)
    {
        List<string> questions = new List<string>();
        for (int i = 0; i < history.Count; i++)
        {
            ChatMessage message = history[i];
            if (message == null || !string.Equals(message.role, "user", StringComparison.Ordinal)) continue;

            string clean = CleanAssistantReplyText(message.content);
            if (string.IsNullOrWhiteSpace(clean)) continue;
            questions.Add(clean);
        }

        if (questions.Count == 0)
        {
            return "아직 질문 흐름이 없습니다.";
        }

        int start = Mathf.Max(0, questions.Count - Mathf.Max(1, maxQuestions));
        List<string> compact = new List<string>();
        for (int i = start; i < questions.Count; i++)
        {
            int displayIndex = i + 1;
            compact.Add($"{displayIndex}. {BuildLeadCardTitle(questions[i])}");
        }

        return ShortenForCard(string.Join(" -> ", compact.ToArray()), maxLength);
    }

    private bool TryStartQuestion(string question)
    {
        if (pendingClosingSensitiveQuestion)
        {
            AnswerClosingSensitiveQuestion(question);
            return false;
        }

        if (!serverReady)
        {
            if (!serverStatusKnown && serverStatusCoroutine == null)
            {
                RefreshServerStatus();
            }

            ShowServerRequiredBlock();
            return false;
        }

        if (storyModeActive)
        {
            StopStoryMode("직접 질문으로 전환합니다");
        }

        if (IsCompletedFiveTurnSession())
        {
            if (pendingCompletionChoiceAfterDialogue && HasUnreadDialoguePage())
            {
                statusText.text = "마지막 답변을 끝까지 읽은 뒤 선택해 주세요";
                UpdateDialoguePageCue();
                return false;
            }

            statusText.text = $"{BuildActiveCategoryLabel()} {RequiredQuestionCount}문답을 마쳤습니다 · 5개 더 물어보기 또는 끝내기를 선택하세요";
            ShowCompletionChoiceOverlay();
            return false;
        }

        if (busy || string.IsNullOrWhiteSpace(question)) return false;
        if (lastSubmitFrame == Time.frameCount) return false;

        lastSubmitFrame = Time.frameCount;
        HideHotspotLabels();
        busy = true;
        PlaySound(questionSelectClip);
        StartCoroutine(SendQuestion(question.Trim()));
        return true;
    }

    private static string ClassifyQuestionAttitude(string question)
    {
        string text = question ?? string.Empty;
        if (HasAny(text, "필요하죠", "제한", "힘들", "못하", "혼자 할 수", "당연", "극복")) return "단정";
        if (HasAny(text, "어떻게 도와", "편할까요", "괜찮을까요", "먼저 물", "방식")) return "배려";
        if (HasAny(text, "무엇", "어떤", "왜", "어떻게", "의미", "궁금", "알고 싶")) return "호기심";
        return "거리두기";
    }

    private void RecordQuestionAttitude(string attitude)
    {
        EnsureAttitudeCounts();
        lastQuestionAttitude = string.IsNullOrWhiteSpace(attitude) ? "거리두기" : attitude;
        int index = Array.IndexOf(attitudeNames, lastQuestionAttitude);
        if (index < 0) index = attitudeNames.Length - 1;
        attitudeCounts[index]++;
    }

    private ChatMessage[] BuildChatRequestMessages(string attitude)
    {
        List<ChatMessage> messages = new List<ChatMessage>(history.Count + 1);
        messages.Add(new ChatMessage
        {
            role = "system",
            content = $"현재 질문 태도 태그: {attitude}. 태그는 내부 기록용입니다. 답변 첫머리에 질문 태도 평가나 고정 도입문을 붙이지 말고, 사용자가 물은 내용에 바로 답하세요."
        });
        messages.AddRange(history);
        return messages.ToArray();
    }

    private string ApplyAttitudeReaction(string reply, string attitude)
    {
        return CleanAssistantReplyText(reply);
    }

    private string ApplyFirstImpressionFrame(string reply)
    {
        return CleanAssistantReplyText(reply);
    }

    private bool IsSubmitKeyDown()
    {
        bool shiftHeld = Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift);
        return !shiftHeld && (IsKeyDown(KeyCode.Return) || IsKeyDown(KeyCode.KeypadEnter) || IsKeyDown(KeyCode.JoystickButton0));
    }

    private IEnumerator SendPreparedQuestion(string question)
    {
        string questionAttitude = ClassifyQuestionAttitude(question);
        RecordQuestionAttitude(questionAttitude);
        if (sendButton != null) sendButton.interactable = false;
        if (micButton != null) micButton.interactable = false;
        SetFlowButtonsInteractable(false);

        AppendMessage("나", question, "#334155");
        history.Add(new ChatMessage { role = "user", content = question });
        conversationTurns++;
        RegisterQuestionForActiveCategory(question);
        UpdateActionButtons();
        UpdateQuestionPhoneProgress();

        SetExpression(ExpressionState.Thinking);
        PresentAssistant(ThinkingReplyText, "생각 중");
        ShowSceneFocus("질문", new Vector2(-28f, -306f), "준비된 답변", 1.2f);
        statusText.text = "추천 질문 답변을 여는 중...";
        yield return null;

        string reply = ApplyAttitudeReaction(MakeLocalReply(question), questionAttitude);
        reply = ApplyFirstImpressionFrame(reply);
        history.Add(new ChatMessage { role = "assistant", content = reply });
        TrimHistory();
        AppendMessage("답변", reply, "#0f766e");

        SetExpression(ClassifyExpression(question, reply));
        PresentAssistant(reply, "답변");
        if (!IsCompletedFiveTurnSession())
        {
            PlaySound(answerReadyClip);
        }

        lastTheme = ClassifyTheme(question, reply);
        lastAnswerSource = "prepared";
        lastServerError = string.Empty;
        lastEvidenceLine = "추천 질문은 인터뷰 정리 자료를 바탕으로 미리 준비한 답변으로 바로 열었습니다.";
        CollectTheme(lastTheme, question, reply, questionAttitude);
        string focusLabel = GetSceneFocusLabelForTheme(lastTheme);
        TriggerScenePropReaction(focusLabel, 3.4f);
        UpdateLeadPrompts(BuildLeadIntro(), BuildContextLeadQuestions(question, reply));
        UpdateActionButtons();
        UpdateNoteTabContent();
        UpdateClosingSummary();

        if (IsCompletedFiveTurnSession())
        {
            CompleteFiveQuestionSession();
            yield break;
        }

        statusText.text = "추천 질문 답변을 열었습니다";
        busy = false;
        if (sendButton != null) sendButton.interactable = serverReady;
        ShowHotspotLabels();
        UpdateMicButtonState();
        SetFlowButtonsInteractable(true);
        SaveSession();
    }

    private IEnumerator SendQuestion(string question)
    {
        string questionAttitude = ClassifyQuestionAttitude(question);
        RecordQuestionAttitude(questionAttitude);
        sendButton.interactable = false;
        micButton.interactable = false;
        SetFlowButtonsInteractable(false);

        yield return CheckServerStatus();
        if (!serverReady)
        {
            busy = false;
            ShowServerRequiredBlock();
            yield break;
        }

        AppendMessage("나", question, "#334155");
        history.Add(new ChatMessage { role = "user", content = question });
        conversationTurns++;
        RegisterQuestionForActiveCategory(question);
        UpdateActionButtons();
        UpdateQuestionPhoneProgress();

        SetExpression(ExpressionState.Thinking);
        PresentAssistant(ThinkingReplyText, "생각 중");
        ShowSceneFocus("질문", new Vector2(-28f, -306f), "책상에 남김", 1.5f);
        statusText.text = ThinkingReplyText;

        ChatResponse response = null;
        string error = null;

        ChatRequest payload = new ChatRequest { messages = BuildChatRequestMessages(questionAttitude) };
        byte[] body = Encoding.UTF8.GetBytes(JsonUtility.ToJson(payload));

        using (UnityWebRequest request = new UnityWebRequest($"{ServerBaseUrl}/api/chat", "POST"))
        {
            request.timeout = 30;
            request.uploadHandler = new UploadHandlerRaw(body);
            request.downloadHandler = new DownloadHandlerBuffer();
            request.SetRequestHeader("Content-Type", "application/json; charset=utf-8");
            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                response = JsonUtility.FromJson<ChatResponse>(request.downloadHandler.text);
            }
            else
            {
                error = request.error;
            }
        }

        bool hasServerReply = response != null && !string.IsNullOrWhiteSpace(response.reply);
        if (!hasServerReply && string.IsNullOrWhiteSpace(error))
        {
            error = "서버 답변이 비어 있음";
        }
        if (!hasServerReply)
        {
            string fallbackReply = ApplyAttitudeReaction(MakeLocalReply(question), questionAttitude);
            fallbackReply = ApplyFirstImpressionFrame(fallbackReply);
            history.Add(new ChatMessage { role = "assistant", content = fallbackReply });
            TrimHistory();
            AppendMessage("답변", fallbackReply, "#0f766e");

            lastAnswerSource = "server-fallback";
            lastServerError = error ?? "서버 답변을 받을 수 없습니다.";
            SetServerAvailability(serverReady, true, $"API 호출 실패 · 내장 답변 사용 · {ShortenForCard(lastServerError, 52)}");
            SetExpression(ClassifyExpression(question, fallbackReply));
            PresentAssistant(fallbackReply, "답변");
            PlaySound(answerReadyClip);
            lastEvidenceLine = BuildEvidenceLine(null, lastAnswerSource, lastServerError);
            lastTheme = ClassifyTheme(question, fallbackReply);
            CollectTheme(lastTheme, question, fallbackReply, questionAttitude);
            string fallbackFocusLabel = GetSceneFocusLabelForTheme(lastTheme);
            TriggerScenePropReaction(fallbackFocusLabel, 3.4f);
            UpdateLeadPrompts(BuildLeadIntro(), BuildContextLeadQuestions(question, fallbackReply));
            UpdateQuestionPhoneProgress();
            UpdateActionButtons();
            UpdateNoteTabContent();
            UpdateClosingSummary();

            if (IsCompletedFiveTurnSession())
            {
                CompleteFiveQuestionSession();
                yield break;
            }

            busy = false;
            if (sendButton != null) sendButton.interactable = serverReady;
            UpdateMicButtonState();
            SetFlowButtonsInteractable(true);
            ShowHotspotLabels();
            statusText.text = "API 호출 실패 · 내장 답변으로 이어갑니다";
            SaveSession();
            yield break;
        }

        string responseSource = response != null ? (response.source ?? string.Empty).Trim() : string.Empty;
        bool usedServerLocalFallback = responseSource.StartsWith("local", StringComparison.OrdinalIgnoreCase);
        SetServerAvailability(true, true, usedServerLocalFallback ? "서버 연결됨 · 내장 답변 사용" : "서버 연결됨 · API 답변 사용");
        string reply = response.reply.Trim();
        lastAnswerSource = usedServerLocalFallback ? "server-fallback" : "server";
        lastServerError = string.Empty;
        reply = CleanAssistantReplyText(reply);
        if (string.IsNullOrWhiteSpace(reply))
        {
            reply = "서버 답변이 비어 있습니다. 서버 상태를 확인한 뒤 다시 시도해 주세요.";
        }
        reply = ApplyAttitudeReaction(reply, questionAttitude);
        reply = ApplyFirstImpressionFrame(reply);

        history.Add(new ChatMessage { role = "assistant", content = reply });
        TrimHistory();
        AppendMessage("답변", reply, "#0f766e");

        SetExpression(ClassifyExpression(question, reply));
        PresentAssistant(reply, "답변");
        if (!IsCompletedFiveTurnSession())
        {
            PlaySound(answerReadyClip);
        }

        lastTheme = response != null && !string.IsNullOrWhiteSpace(response.theme) ? response.theme.Trim() : ClassifyTheme(question, reply);
        lastEvidenceLine = BuildEvidenceLine(response, lastAnswerSource, lastServerError);
        CollectTheme(lastTheme, question, reply, questionAttitude);
        string focusLabel = GetSceneFocusLabelForTheme(lastTheme);
        TriggerScenePropReaction(focusLabel, 3.4f);
        string[] followUpQuestions = response != null && response.suggestions != null && response.suggestions.Length > 0
            ? response.suggestions
            : BuildContextLeadQuestions(question, reply);
        UpdateLeadPrompts(BuildLeadIntro(), followUpQuestions);
        UpdateActionButtons();
        UpdateNoteTabContent();
        UpdateClosingSummary();

        if (IsCompletedFiveTurnSession())
        {
            CompleteFiveQuestionSession();
            yield break;
        }

        statusText.text = "이어갈 수 있습니다";

        busy = false;
        sendButton.interactable = serverReady;
        ShowHotspotLabels();
        UpdateMicButtonState();
        SetFlowButtonsInteractable(true);
        SaveSession();
    }

    private void ToggleRecording()
    {
        if (busy) return;
        if (localAnswerOnly)
        {
            statusText.text = "서버 답변 필수 모드입니다.";
            return;
        }
        if (!serverReady)
        {
            ShowServerRequiredBlock();
            return;
        }

        if (recording)
        {
            StopRecordingAndTranscribe();
            return;
        }

        if (Microphone.devices == null || Microphone.devices.Length == 0)
        {
            statusText.text = "사용 가능한 마이크를 찾지 못했습니다.";
            PlaySound(errorClip);
            return;
        }

        micDevice = Microphone.devices[0];
        recordingClip = Microphone.Start(micDevice, false, MaxRecordingSeconds, MicFrequency);
        recording = true;
        UpdateMicButtonState();
        sendButton.interactable = false;
        SetFlowButtonsInteractable(false);
        SetExpression(ExpressionState.Listening);
        PresentAssistant("말씀을 듣고 있어요. 끝나면 정지를 눌러 주세요.", "음성 입력");
        PlaySound(recordingStartClip);
    }

    private void StopRecordingAndTranscribe()
    {
        int recordedSamples = Microphone.GetPosition(micDevice);
        Microphone.End(micDevice);
        recording = false;
        UpdateMicButtonState();
        sendButton.interactable = true;
        PlaySound(recordingStopClip);

        if (recordingClip == null)
        {
            statusText.text = "녹음 데이터가 없습니다.";
            SetExpression(ExpressionState.Idle);
            SetFlowButtonsInteractable(true);
            PlaySound(errorClip);
            return;
        }

        if (recordedSamples <= 0)
        {
            recordedSamples = recordingClip.samples;
        }

        byte[] wav = EncodeWav(recordingClip, Mathf.Clamp(recordedSamples, 0, recordingClip.samples));
        StartCoroutine(TranscribeAndSend(wav));
    }

    private IEnumerator TranscribeAndSend(byte[] wav)
    {
        if (localAnswerOnly)
        {
            statusText.text = "서버 답변 필수 모드입니다.";
            busy = false;
            sendButton.interactable = serverReady;
            UpdateMicButtonState();
            SetFlowButtonsInteractable(serverReady);
            SetExpression(ExpressionState.Idle);
            yield break;
        }
        if (!serverReady)
        {
            ShowServerRequiredBlock();
            busy = false;
            sendButton.interactable = false;
            UpdateMicButtonState();
            SetFlowButtonsInteractable(false);
            SetExpression(ExpressionState.Idle);
            yield break;
        }

        busy = true;
        sendButton.interactable = false;
        micButton.interactable = false;
        SetFlowButtonsInteractable(false);
        SetExpression(ExpressionState.Thinking);
        PresentAssistant("음성을 텍스트로 바꾸는 중입니다.", "전사 중");
        statusText.text = "음성을 텍스트로 바꾸는 중...";

        TranscribeResponse response = null;
        string error = null;
        using (UnityWebRequest request = new UnityWebRequest($"{ServerBaseUrl}/api/transcribe", "POST"))
        {
            request.uploadHandler = new UploadHandlerRaw(wav);
            request.downloadHandler = new DownloadHandlerBuffer();
            request.SetRequestHeader("Content-Type", "audio/wav");
            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                response = JsonUtility.FromJson<TranscribeResponse>(request.downloadHandler.text);
            }
            else
            {
                error = request.error;
            }
        }

        busy = false;
        sendButton.interactable = true;
        UpdateMicButtonState();
        SetFlowButtonsInteractable(true);

        string text = response != null ? (response.text ?? string.Empty).Trim() : string.Empty;
        if (!string.IsNullOrEmpty(text))
        {
            inputField.text = text;
            SubmitCurrentInput();
        }
        else
        {
            statusText.text = string.IsNullOrEmpty(error) ? "전사 결과가 비어 있습니다." : $"전사 실패: {error}";
            SetExpression(ExpressionState.Idle);
            PlaySound(errorClip);
        }
    }

    private void SetExpression(ExpressionState state)
    {
        if (currentExpression != state)
        {
            expressionChangedAt = Time.time;
        }

        currentExpression = state;
        if (avatarImage != null && avatarSprites.TryGetValue(state, out Sprite sprite) && sprite != null)
        {
            avatarImage.sprite = sprite;
            if (avatarSilhouetteShadowImage != null)
            {
                avatarSilhouetteShadowImage.sprite = sprite;
            }
        }

        if (avatarHandsImage != null && avatarHandSprites.TryGetValue(state, out Sprite handsSprite) && handsSprite != null)
        {
            avatarHandsImage.sprite = handsSprite;
        }
    }

    private void AnimateAvatar()
    {
        if (avatarRect == null) return;
        if (reducedMotionEnabled)
        {
            avatarRect.anchoredPosition = avatarBasePosition;
            avatarRect.localScale = AvatarScale(1f);
            UpdateAvatarIntegrationLayers(0f, 1f);
            return;
        }

        float elapsed = Mathf.Max(0f, Time.time - expressionChangedAt);
        float settle = Mathf.Clamp01(elapsed / 0.32f);
        Vector2 gesture = GetAvatarGestureOffset(currentExpression, Time.time, settle);
        float lift = Mathf.Sin(Time.time * 1.4f) * 0.28f + gesture.y;
        float scalePulse = GetAvatarScalePulse(currentExpression, Time.time, settle);
        float lean = gesture.x;

        avatarRect.anchoredPosition = avatarBasePosition + new Vector2(lean, lift);
        avatarRect.localScale = AvatarScale(scalePulse);
        UpdateAvatarIntegrationLayers(lift, scalePulse, lean);
    }

    private Vector2 GetAvatarGestureOffset(ExpressionState state, float now, float settle)
    {
        float enter = 1f - settle;
        switch (state)
        {
            case ExpressionState.Listening:
                return new Vector2(Mathf.Sin(now * 1.1f) * 0.40f, -1.3f + Mathf.Sin(now * 2.1f) * 0.20f);
            case ExpressionState.Thinking:
                return new Vector2(-1.2f * enter + Mathf.Sin(now * 0.9f) * 0.28f, -2.2f + Mathf.Sin(now * 1.5f) * 0.16f);
            case ExpressionState.Explaining:
                return new Vector2(Mathf.Sin(now * 1.8f) * 1.1f, 1.4f + Mathf.Sin(now * 3.2f) * 0.42f);
            case ExpressionState.Empathetic:
                return new Vector2(-0.9f + Mathf.Sin(now * 1.0f) * 0.24f, -0.9f + Mathf.Sin(now * 1.7f) * 0.16f);
            case ExpressionState.Speaking:
                return new Vector2(Mathf.Sin(now * 2.0f) * 0.60f, Mathf.Sin(now * 3.0f) * 0.32f);
            default:
                return new Vector2(Mathf.Sin(now * 0.7f) * 0.18f, 0f);
        }
    }

    private float GetAvatarScalePulse(ExpressionState state, float now, float settle)
    {
        float enter = (1f - settle) * 0.004f;
        switch (state)
        {
            case ExpressionState.Explaining:
                return 1.002f + enter + Mathf.Sin(now * 4.1f) * 0.0045f;
            case ExpressionState.Speaking:
                return 1.001f + enter + Mathf.Sin(now * 3.7f) * 0.0035f;
            case ExpressionState.Thinking:
                return 0.998f - enter * 0.4f + Mathf.Sin(now * 1.6f) * 0.0018f;
            case ExpressionState.Empathetic:
                return 0.999f + Mathf.Sin(now * 1.9f) * 0.0016f;
            case ExpressionState.Listening:
                return 1.000f + Mathf.Sin(now * 2.0f) * 0.0018f;
            default:
                return 1f + Mathf.Sin(now * 1.4f) * 0.0012f;
        }
    }

    private void UpdateAvatarIntegrationLayers(float lift, float scalePulse, float lean = 0f)
    {
        if (avatarBackShadowRect != null)
        {
            avatarBackShadowRect.anchoredPosition = avatarBasePosition + new Vector2(-8f + lean * 0.25f, -10f + lift * 0.22f);
            avatarBackShadowRect.localScale = AvatarScale(1.02f + (scalePulse - 1f) * 0.45f);
        }

        if (avatarContactShadowRect != null)
        {
            float liftAbs = Mathf.Abs(lift);
            avatarContactShadowRect.anchoredPosition = avatarBasePosition + new Vector2(0f, -168f);
            avatarContactShadowRect.localScale = new Vector3(1.05f + (scalePulse - 1f) * 0.35f + liftAbs * 0.0015f, Mathf.Max(0.90f, 1f - liftAbs * 0.012f), 1f);
        }

        if (avatarSilhouetteShadowRect != null)
        {
            avatarSilhouetteShadowRect.anchoredPosition = avatarBasePosition + new Vector2(6f + lean * 0.20f, -9f + lift * 0.16f);
            avatarSilhouetteShadowRect.localScale = AvatarScale(1.010f + (scalePulse - 1f) * 0.30f);
        }

        if (avatarSceneWashRect != null)
        {
            avatarSceneWashRect.anchoredPosition = avatarBasePosition + new Vector2(lean, lift);
            avatarSceneWashRect.localScale = AvatarScale(scalePulse);
        }

        if (avatarHandsRect != null)
        {
            avatarHandsRect.sizeDelta = avatarRect != null ? avatarRect.sizeDelta : avatarHandsRect.sizeDelta;
            avatarHandsRect.anchoredPosition = avatarBasePosition + new Vector2(lean * 0.50f, 86f + lift * 0.45f);
            avatarHandsRect.localScale = AvatarScale(scalePulse);
        }

        if (avatarHandsContactShadowRect != null)
        {
            float liftAbs = Mathf.Abs(lift);
            avatarHandsContactShadowRect.anchoredPosition = avatarBasePosition + new Vector2(4f + lean * 0.32f, -148f + lift * 0.06f);
            avatarHandsContactShadowRect.localScale = new Vector3(1.04f + (scalePulse - 1f) * 0.24f + liftAbs * 0.0012f, Mathf.Max(0.90f, 1f - liftAbs * 0.010f), 1f);
        }
    }

    private static Vector3 AvatarScale(float uniformScale)
    {
        return new Vector3(AvatarHorizontalScale * uniformScale, uniformScale, 1f);
    }

    private void AnimateHotspots()
    {
        if (reducedMotionEnabled)
        {
            for (int i = 0; i < hotspotPulseRects.Count; i++)
            {
                RectTransform rect = hotspotPulseRects[i];
                if (rect != null && rect.localScale != Vector3.one) rect.localScale = Vector3.one;
                if (i < hotspotPulseImages.Count && hotspotPulseImages[i] != null)
                {
                    Color color = hotspotPulseImages[i].color;
                    if (!Mathf.Approximately(color.a, 0.020f))
                    {
                        color.a = 0.020f;
                        hotspotPulseImages[i].color = color;
                    }
                }
            }
            return;
        }

        float wave = (Mathf.Sin(Time.time * 1.6f) + 1f) * 0.5f;
        float scale = Mathf.Lerp(1.00f, 1.025f, wave);
        float alpha = Mathf.Lerp(0.040f, 0.018f, wave);

        for (int i = 0; i < hotspotPulseRects.Count; i++)
        {
            RectTransform rect = hotspotPulseRects[i];
            if (rect != null) rect.localScale = new Vector3(scale, scale, 1f);
            if (i < hotspotPulseImages.Count && hotspotPulseImages[i] != null)
            {
                Color color = hotspotPulseImages[i].color;
                color.a = alpha;
                hotspotPulseImages[i].color = color;
            }
        }
    }

    private void AnimateLeadQuestionSlips()
    {
        if (leadRects == null || leadBasePositions == null || leadBaseRotations == null) return;

        bool readingFocus = IsDialogueReadingFocusActive();
        for (int i = 0; i < leadRects.Length; i++)
        {
            RectTransform rect = leadRects[i];
            if (rect == null) continue;

            bool hover = leadHoverStates != null && i < leadHoverStates.Length && leadHoverStates[i];
            bool selected = i == selectedLeadIndex;
            if (reducedMotionEnabled || questionNoteOpen)
            {
                Vector2 staticPosition = readingFocus ? GetReadingFocusLeadPosition(i) : leadBasePositions[i];
                float staticScale = readingFocus ? GetReadingFocusLeadScale(selected, hover) : (selected && !questionNoteOpen ? 1.012f : 1f);
                rect.anchoredPosition = staticPosition;
                rect.localRotation = Quaternion.Euler(0f, 0f, readingFocus ? 0f : leadBaseRotations[i]);
                rect.localScale = new Vector3(staticScale, staticScale, 1f);
                if (leadShadowRects != null && i < leadShadowRects.Length && leadShadowRects[i] != null && leadShadowBasePositions != null)
                {
                    leadShadowRects[i].anchoredPosition = readingFocus ? GetReadingFocusLeadShadowPosition(i) : leadShadowBasePositions[i];
                    float shadowScale = readingFocus ? 0.90f : 1f;
                    leadShadowRects[i].localScale = new Vector3(shadowScale, shadowScale, 1f);
                }
                continue;
            }

            float wave = Mathf.Sin(Time.time * 0.65f + i * 1.7f);
            float hoverLift = hover || selected ? 4f : 0f;
            Vector2 targetPosition = readingFocus
                ? GetReadingFocusLeadPosition(i) + new Vector2(0f, hoverLift * 0.5f)
                : leadBasePositions[i] + new Vector2(0f, wave * 0.75f + hoverLift);
            float targetAngle = readingFocus ? 0f : leadBaseRotations[i] + wave * 0.14f + (hover || selected ? 0.25f : 0f);
            float targetScale = readingFocus ? GetReadingFocusLeadScale(selected, hover) : (hover || selected ? 1.018f : 1f);
            float t = Mathf.Clamp01(Time.deltaTime * 8.5f);

            rect.anchoredPosition = Vector2.Lerp(rect.anchoredPosition, targetPosition, t);
            float currentAngle = rect.localEulerAngles.z;
            if (currentAngle > 180f) currentAngle -= 360f;
            rect.localRotation = Quaternion.Euler(0f, 0f, Mathf.LerpAngle(currentAngle, targetAngle, t));
            rect.localScale = Vector3.Lerp(rect.localScale, new Vector3(targetScale, targetScale, 1f), t);

            if (leadShadowRects != null && i < leadShadowRects.Length && leadShadowRects[i] != null && leadShadowBasePositions != null)
            {
                RectTransform shadow = leadShadowRects[i];
                Vector2 shadowTarget = readingFocus
                    ? GetReadingFocusLeadShadowPosition(i)
                    : leadShadowBasePositions[i] + new Vector2(hover ? 1f : 0f, hover ? -2f : 0f);
                float shadowScale = readingFocus ? 0.90f : (hover ? 1.035f : 1f);
                shadow.anchoredPosition = Vector2.Lerp(shadow.anchoredPosition, shadowTarget, t);
                shadow.localScale = Vector3.Lerp(shadow.localScale, new Vector3(shadowScale, shadowScale, 1f), t);
            }
        }
    }

    private Vector2 GetReadingFocusLeadPosition(int index)
    {
        if (leadBasePositions == null || index < 0 || index >= leadBasePositions.Length) return Vector2.zero;
        float[] yPositions = { 360f, 368f, 360f };
        float y = index < yPositions.Length ? yPositions[index] : 360f;
        return new Vector2(leadBasePositions[index].x, y);
    }

    private Vector2 GetReadingFocusLeadShadowPosition(int index)
    {
        if (leadShadowBasePositions == null || index < 0 || index >= leadShadowBasePositions.Length) return GetReadingFocusLeadPosition(index);
        Vector2 leadPosition = GetReadingFocusLeadPosition(index);
        return new Vector2(leadShadowBasePositions[index].x, leadPosition.y - 8f);
    }

    private static float GetReadingFocusLeadScale(bool selected, bool hover)
    {
        if (hover) return 0.955f;
        if (selected) return 0.945f;
        return 0.920f;
    }

    private void AnimateMemoryUnlockToast()
    {
        float now = Time.unscaledTime;
        if (memoryUnlockToastObject != null && memoryUnlockToastObject.activeSelf)
        {
            float remaining = memoryUnlockToastUntil - now;
            if (remaining <= 0f)
            {
                memoryUnlockToastObject.SetActive(false);
                if (memoryUnlockToastRect != null) memoryUnlockToastRect.localScale = Vector3.one;
            }
            else
            {
                float duration = memoryUnlockToastDuration > 0f ? memoryUnlockToastDuration : 2.8f;
                float elapsed = duration - remaining;
                float fadeIn = Mathf.Clamp01(elapsed / 0.16f);
                float fadeOut = Mathf.Clamp01(remaining / 0.42f);
                if (memoryUnlockToastGroup != null) memoryUnlockToastGroup.alpha = Mathf.Min(fadeIn, fadeOut);
                if (memoryUnlockToastRect != null)
                {
                    float pop = reducedMotionEnabled ? 1f : 1f + Mathf.Sin(Mathf.Clamp01(elapsed / 0.34f) * Mathf.PI) * 0.014f;
                    memoryUnlockToastRect.localScale = new Vector3(pop, pop, 1f);
                }
            }
        }

        if (memoryBookButton != null)
        {
            RectTransform rect = memoryBookButton.GetComponent<RectTransform>();
            if (rect != null)
            {
                if (now < memoryUnlockPulseUntil)
                {
                    float pulse = 1f + Mathf.Sin(now * 18f) * 0.035f;
                    rect.localScale = new Vector3(pulse, pulse, 1f);
                }
                else if (rect.localScale != Vector3.one)
                {
                    rect.localScale = Vector3.one;
                }
            }
        }
    }

    private void AnimateClosingCredits()
    {
        if (closingCardObject == null || !closingCardObject.activeSelf || closingCreditsTextRect == null) return;

        float elapsed = Mathf.Max(0f, Time.unscaledTime - closingCreditsStartedAt);
        float y = reducedMotionEnabled ? -92f : Mathf.Repeat(elapsed * 10f, 190f) - 96f;
        closingCreditsTextRect.anchoredPosition = new Vector2(closingCreditsTextRect.anchoredPosition.x, y);
    }

    private void PresentAssistant(string text, string speaker)
    {
        speakerText.text = speaker;
        currentDialogueFullText = CleanAssistantReplyText(text);
        BuildDialoguePages(currentDialogueFullText);
        dialoguePageIndex = 0;
        RefreshDialoguePage();
    }

    private void BuildDialoguePages(string text)
    {
        dialoguePages.Clear();

        string clean = string.IsNullOrWhiteSpace(text) ? string.Empty : text.Trim();
        if (clean.Length <= DialoguePageSoftCharLimit)
        {
            dialoguePages.Add(clean);
            return;
        }

        string[] paragraphs = Regex.Split(clean, @"\n\s*\n");
        StringBuilder page = new StringBuilder();
        for (int i = 0; i < paragraphs.Length; i++)
        {
            string paragraph = (paragraphs[i] ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(paragraph)) continue;

            if (paragraph.Length > DialoguePageSoftCharLimit)
            {
                FlushDialoguePage(page);
                SplitLongDialogueParagraph(paragraph);
                continue;
            }

            int projected = page.Length == 0 ? paragraph.Length : page.Length + 2 + paragraph.Length;
            if (projected > DialoguePageSoftCharLimit)
            {
                FlushDialoguePage(page);
            }

            if (page.Length > 0) page.Append("\n\n");
            page.Append(paragraph);
        }

        FlushDialoguePage(page);
        if (dialoguePages.Count == 0) dialoguePages.Add(clean);
    }

    private void SplitLongDialogueParagraph(string paragraph)
    {
        string[] sentences = Regex.Split(paragraph, @"(?<=[.!?。！？]|[요다까죠요니다습니다])\s+");
        StringBuilder page = new StringBuilder();
        for (int i = 0; i < sentences.Length; i++)
        {
            string sentence = (sentences[i] ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(sentence)) continue;

            if (sentence.Length > DialoguePageSoftCharLimit)
            {
                FlushDialoguePage(page);
                for (int start = 0; start < sentence.Length; start += DialoguePageSoftCharLimit)
                {
                    int length = Mathf.Min(DialoguePageSoftCharLimit, sentence.Length - start);
                    dialoguePages.Add(sentence.Substring(start, length).Trim());
                }
                continue;
            }

            int projected = page.Length == 0 ? sentence.Length : page.Length + 1 + sentence.Length;
            if (projected > DialoguePageSoftCharLimit)
            {
                FlushDialoguePage(page);
            }

            if (page.Length > 0) page.Append(' ');
            page.Append(sentence);
        }

        FlushDialoguePage(page);
    }

    private void FlushDialoguePage(StringBuilder page)
    {
        if (page == null || page.Length == 0) return;
        dialoguePages.Add(page.ToString().Trim());
        page.Length = 0;
    }

    private void RefreshDialoguePage()
    {
        if (dialogueText != null)
        {
            if (dialoguePages.Count == 0)
            {
                dialogueText.text = currentDialogueFullText;
            }
            else
            {
                dialoguePageIndex = Mathf.Clamp(dialoguePageIndex, 0, dialoguePages.Count - 1);
                dialogueText.text = dialoguePages[dialoguePageIndex];
            }
        }

        EnsureCurrentDialoguePageFitsViewport();
        RefreshDialogueScroll();
        UpdateDialoguePageCue();
    }

    private void EnsureCurrentDialoguePageFitsViewport()
    {
        if (dialogueText == null || dialogueViewportRect == null || dialoguePages == null || dialoguePages.Count == 0) return;

        const int maxPasses = 8;
        for (int pass = 0; pass < maxPasses; pass++)
        {
            Canvas.ForceUpdateCanvases();
            float availableHeight = Mathf.Max(90f, dialogueViewportRect.rect.height - 64f);
            string page = dialogueText.text ?? string.Empty;
            if (dialogueText.preferredHeight <= availableHeight || page.Length < 90) return;

            string[] split = SplitDialoguePageForViewport(page);
            if (split == null || split.Length < 2) return;

            int insertIndex = Mathf.Clamp(dialoguePageIndex, 0, dialoguePages.Count - 1);
            dialoguePages.RemoveAt(insertIndex);
            for (int i = split.Length - 1; i >= 0; i--)
            {
                dialoguePages.Insert(insertIndex, split[i]);
            }

            dialoguePageIndex = insertIndex;
            dialogueText.text = dialoguePages[dialoguePageIndex];
        }
    }

    private string[] SplitDialoguePageForViewport(string page)
    {
        string clean = CleanAssistantReplyText(page);
        if (clean.Length < 90) return null;

        string[] paragraphs = Regex.Split(clean, @"\n\s*\n");
        if (paragraphs.Length > 1)
        {
            return SplitDialogueSegments(paragraphs, "\n\n");
        }

        string[] sentences = Regex.Split(clean, @"(?<=[.!?。！？]|[요다까죠요니다습니다])\s+");
        if (sentences.Length > 1)
        {
            return SplitDialogueSegments(sentences, " ");
        }

        int midpoint = clean.Length / 2;
        int splitAt = clean.LastIndexOf(' ', midpoint);
        if (splitAt < 45) splitAt = midpoint;

        string first = clean.Substring(0, splitAt).Trim();
        string second = clean.Substring(splitAt).Trim();
        return string.IsNullOrWhiteSpace(first) || string.IsNullOrWhiteSpace(second)
            ? null
            : new[] { first, second };
    }

    private static string[] SplitDialogueSegments(string[] rawSegments, string separator)
    {
        List<string> segments = new List<string>();
        for (int i = 0; i < rawSegments.Length; i++)
        {
            string segment = (rawSegments[i] ?? string.Empty).Trim();
            if (!string.IsNullOrWhiteSpace(segment)) segments.Add(segment);
        }

        if (segments.Count < 2) return null;

        int totalLength = 0;
        for (int i = 0; i < segments.Count; i++) totalLength += segments[i].Length;

        int firstLength = 0;
        int splitIndex = 1;
        for (int i = 0; i < segments.Count - 1; i++)
        {
            firstLength += segments[i].Length;
            splitIndex = i + 1;
            if (firstLength >= totalLength / 2) break;
        }

        string first = string.Join(separator, segments.GetRange(0, splitIndex).ToArray()).Trim();
        string second = string.Join(separator, segments.GetRange(splitIndex, segments.Count - splitIndex).ToArray()).Trim();
        return string.IsNullOrWhiteSpace(first) || string.IsNullOrWhiteSpace(second)
            ? null
            : new[] { first, second };
    }

    private bool TryAdvanceDialoguePage()
    {
        if (dialoguePages.Count <= 1 || dialoguePageIndex >= dialoguePages.Count - 1) return false;
        dialoguePageIndex++;
        RefreshDialoguePage();
        return true;
    }

    private bool HasUnreadDialoguePage()
    {
        return dialoguePages != null && dialoguePages.Count > 1 && dialoguePageIndex < dialoguePages.Count - 1;
    }

    private void AdvanceDialoguePageOrStory()
    {
        if (TryAdvanceDialoguePage()) return;
        if (pendingCompletionChoiceAfterDialogue)
        {
            ShowCompletionChoiceOverlay();
            return;
        }
        if (storyModeActive)
        {
            RequestStoryModeAdvance("dialogue-click");
        }
    }

    private void RefreshDialogueScroll()
    {
        if (dialogueContentRect == null || dialogueScrollRect == null) return;

        Canvas.ForceUpdateCanvases();
        float minHeight = dialogueViewportRect != null ? dialogueViewportRect.rect.height : 160f;
        float preferred = dialogueText != null ? dialogueText.preferredHeight + 64f : minHeight;
        dialogueContentRect.sizeDelta = new Vector2(0f, Mathf.Max(minHeight, preferred));
        Canvas.ForceUpdateCanvases();
        dialogueScrollRect.verticalNormalizedPosition = 1f;
    }

    private void UpdateDialoguePageCue()
    {
        bool hasNextPage = dialoguePages.Count > 1 && dialoguePageIndex < dialoguePages.Count - 1;
        bool canAdvanceStory = !hasNextPage && storyModeActive;
        bool canOpenCompletionChoice = !hasNextPage && pendingCompletionChoiceAfterDialogue;
        SetDialogueScrollCueVisible(hasNextPage || canAdvanceStory || canOpenCompletionChoice);
        Image cueImage = dialogueScrollCueObject != null ? dialogueScrollCueObject.GetComponent<Image>() : null;
        if (dialoguePageCueText != null)
        {
            if (hasNextPage)
            {
                dialoguePageCueText.text = $"대사가 더 있어요 · 클릭해서 다음 대사 보기 {dialoguePageIndex + 2}/{dialoguePages.Count}";
                dialoguePageCueText.fontSize = 14;
                dialoguePageCueText.color = new Color32(255, 248, 225, 255);
                if (cueImage != null) cueImage.color = new Color(0.60f, 0.34f, 0.13f, 0.92f);
            }
            else if (canOpenCompletionChoice)
            {
                dialoguePageCueText.text = "답변을 다 읽었어요 · 클릭해서 다음 선택하기";
                dialoguePageCueText.fontSize = 14;
                dialoguePageCueText.color = new Color32(255, 248, 225, 255);
                if (cueImage != null) cueImage.color = new Color(0.60f, 0.34f, 0.13f, 0.92f);
            }
            else
            {
                dialoguePageCueText.text = openingStoryModeActive ? "다음 이야기 보기" : "다음 장면 보기";
                dialoguePageCueText.fontSize = 14;
                dialoguePageCueText.color = new Color32(255, 248, 225, 244);
                if (cueImage != null) cueImage.color = new Color(0.36f, 0.22f, 0.11f, 0.74f);
            }
        }
    }

    private void SetDialogueScrollCueVisible(bool visible)
    {
        if (dialogueScrollCueObject != null && dialogueScrollCueObject.activeSelf != visible)
        {
            dialogueScrollCueObject.SetActive(visible);
        }
    }

    private void UpdateLeadPrompts(string intro, string[] questions = null)
    {
        leadText.text = intro;
        if (questions != null)
        {
            currentLeadQuestions = BuildLeadQuestionSet(questions);
        }
        else if (currentLeadQuestions == null || currentLeadQuestions.Length != leadButtons.Length)
        {
            currentLeadQuestions = BuildLeadQuestionSet(null);
        }

        for (int i = 0; i < leadButtons.Length; i++)
        {
            string question = GetLeadQuestion(i);
            Text label = FindChildText(leadButtons[i].transform, "Label");
            if (label != null)
            {
                label.text = BuildLeadCardLabel(i, question);
            }

            Text action = FindChildText(leadButtons[i].transform, "Action Label");
            if (action != null)
            {
                action.text = $"추천 질문 {i + 1}";
            }

            if (leadIllustrationImages != null && i < leadIllustrationImages.Length && leadIllustrationImages[i] != null)
            {
                Sprite sprite = LoadIllustrationSprite(GetIllustrationResourceForQuestion(question));
                if (sprite != null)
                {
                    leadIllustrationImages[i].sprite = sprite;
                }
            }
        }
        selectedLeadIndex = Mathf.Clamp(selectedLeadIndex, 0, leadButtons.Length - 1);
        UpdateLeadSelectionStyles();
    }

    private void ShowOtherThemeLeadQuestions()
    {
        RefreshVisibleLeadQuestions();
    }

    private void RefreshVisibleLeadQuestions()
    {
        if (busy || storyModeActive || IsCompletedFiveTurnSession()) return;

        leadOffset += Mathf.Max(1, leadButtons != null ? leadButtons.Length : 3);
        string intro = "전체 기록에서 새 추천 질문을 골랐습니다. 이미 물어본 질문은 빼고 보여 줍니다.";
        UpdateLeadPrompts(intro, BuildLeadQuestionSet(null));
        if (statusText != null) statusText.text = "추천 질문을 새로 골랐습니다";
        SaveSession();
    }

    private void UpdateLeadSelectionStyles()
    {
        if (leadButtons == null) return;

        for (int i = 0; i < leadButtons.Length; i++)
        {
            Button button = leadButtons[i];
            if (button == null) continue;

            bool selected = i == selectedLeadIndex;
            Color background = selected
                ? new Color(0.78f, 0.52f, 0.27f, 0.84f)
                : new Color(0.052f + i * 0.004f, 0.039f + i * 0.003f, 0.028f, 0.74f);
            Color foreground = selected
                ? new Color(1f, 0.98f, 0.86f, 0.98f)
                : (Color)new Color32(255, 245, 218, 236);
            SetButtonColor(button, background, foreground);
        }
    }

    private static Text FindChildText(Transform root, string objectName)
    {
        if (root == null) return null;
        Text[] texts = root.GetComponentsInChildren<Text>(true);
        for (int i = 0; i < texts.Length; i++)
        {
            if (texts[i] != null && texts[i].gameObject.name == objectName)
            {
                return texts[i];
            }
        }

        return texts.Length > 0 ? texts[0] : null;
    }

    private static string BuildLeadCardLabel(int index, string question)
    {
        return ShortenLeadQuestion(question, 74);
    }

    private static string BuildLeadAttitudeHint(string attitude)
    {
        return string.Empty;
    }

    private static string BuildLeadCardTitle(string question)
    {
        if (HasAny(question, "평범", "하루")) return "평범한 하루";
        if (HasAny(question, "끈기", "흘러간다", "버틴", "조정")) return "끈기";
        if (HasAny(question, "지원 서비스", "교통 정보", "전동휠체어")) return "이동 지원";
        if (HasAny(question, "처음", "공간", "곳", "엘리베이터", "화장실")) return "처음 가는 곳";
        if (HasAny(question, "설명할 시간", "혼자 할 수", "도움", "배려")) return "도움 받는 방식";
        if (HasAny(question, "책상", "노트북", "컴퓨터", "메모")) return "책상과 노트북";
        if (HasAny(question, "자취", "독립", "집")) return "자취방";
        if (HasAny(question, "취미", "게임", "노래방")) return "취미";
        if (HasAny(question, "목발", "이동")) return "이동과 목발";
        if (HasAny(question, "직장", "회사", "박사", "공부", "기여", "결과물")) return "일과 공부";
        if (HasAny(question, "한국", "미국")) return "이동 환경";
        if (HasAny(question, "생활", "장면")) return "생활 장면";

        string clean = CleanAssistantReplyText(question);
        if (clean.Length <= 12) return clean;
        return clean.Substring(0, 12).TrimEnd() + "...";
    }

    private static string ShortenLeadQuestion(string question, int maxLength)
    {
        string clean = CleanAssistantReplyText(question).Replace("\r", " ").Replace("\n", " ").Trim();
        clean = Regex.Replace(clean, @"\s+", " ");
        if (string.IsNullOrWhiteSpace(clean)) return "무엇을 더 물어볼까요?";
        if (!clean.EndsWith("?", StringComparison.Ordinal) && !clean.EndsWith("요?", StringComparison.Ordinal))
        {
            clean = clean.TrimEnd('.', '。', '!', '！') + "?";
        }
        if (clean.Length <= maxLength) return clean;
        return clean.Substring(0, Mathf.Max(0, maxLength - 1)).TrimEnd() + "…";
    }

    private string GetLeadQuestion(int index)
    {
        if (currentLeadQuestions != null && currentLeadQuestions.Length > index && !string.IsNullOrWhiteSpace(currentLeadQuestions[index]))
        {
            return currentLeadQuestions[index];
        }

        return leadQuestions[(leadOffset + index) % leadQuestions.Length];
    }

    private string BuildLeadIntro()
    {
        int remaining = Mathf.Max(0, RequiredQuestionCount - conversationTurns);
        if (remaining <= 0) return "질문 5개를 마쳤습니다. 5개 더 물어볼지 끝낼지 고르세요.";
        return $"전체 기록에서 중요한 질문을 골랐습니다 · 남은 질문 {remaining}개";
    }

    private void SetActiveQuestionCategory(string theme, bool resetProgress)
    {
        string canonical = CanonicalTheme(theme);
        if (string.IsNullOrWhiteSpace(canonical)) return;

        if (!string.Equals(activeQuestionCategory, canonical, StringComparison.Ordinal))
        {
            activeQuestionCategory = canonical;
            activeCategoryQuestionCount = 0;
        }
        else if (resetProgress)
        {
            activeCategoryQuestionCount = 0;
        }

        UpdateLeadPrompts("전체 기록에서 중요한 질문을 골랐습니다.", BuildLeadQuestionSet(null));
        UpdateQuestionPhoneProgress();
        UpdateActionButtons();
    }

    private void EnsureActiveCategoryForQuestion(string question)
    {
        activeQuestionCategory = string.Empty;
    }

    private void RegisterQuestionForActiveCategory(string question)
    {
        activeQuestionCategory = string.Empty;
        activeCategoryQuestionCount = Mathf.Clamp(conversationTurns, 0, RequiredQuestionCount);
    }

    private void RollbackActiveCategoryQuestion()
    {
        activeCategoryQuestionCount = Mathf.Max(0, activeCategoryQuestionCount - 1);
    }

    private bool IsActiveQuestionCategoryLocked()
    {
        return false;
    }

    private bool HasNextQuestionCategory()
    {
        return true;
    }

    private int GetNextQuestionCategoryIndex()
    {
        int currentIndex = Array.IndexOf(memoryThemes, CanonicalTheme(activeQuestionCategory));
        if (currentIndex < 0) return memoryThemes != null && memoryThemes.Length > 0 ? 0 : -1;
        int next = currentIndex + 1;
        return next >= 0 && next < memoryThemes.Length ? next : -1;
    }

    private void ContinueToNextQuestionCategory()
    {
        if (closingCardObject != null) closingCardObject.SetActive(false);
        if (completionChoiceObject != null) completionChoiceObject.SetActive(false);
        pendingClosingSensitiveQuestion = false;
        pendingCompletionChoiceAfterDialogue = false;
        conversationTurns = 0;
        activeQuestionCategory = string.Empty;
        activeCategoryQuestionCount = 0;
        leadOffset += Mathf.Max(1, leadButtons != null ? leadButtons.Length : 3);
        lastSavedEndingRecordPath = string.Empty;
        lastSavedIntervieweeMessagePath = string.Empty;
        PlaySound(categoryTransitionClip);
        UpdateLeadPrompts("전체 기록에서 다음 5문답을 시작합니다.", BuildLeadQuestionSet(null));
        SetFlowButtonsInteractable(true);
        UpdateQuestionInputLayout();
        UpdateQuestionPhoneProgress();
        UpdateActionButtons();
        if (statusText != null) statusText.text = "다음 5문답을 시작합니다";
        ShowHotspotLabels();
        UpdateNoteTabContent();
        ShowNoteTab(2);
        if (questionNoteOpen)
        {
            UpdateNoteTabContent();
            SetQuestionNoteOpen(true);
        }
        SelectFirstInteractable(null, "Floating Question 1", "Floating Question 2", "Floating Question 3");
        SaveSession();
    }

    private string[] BuildCategoryLeadQuestionSet(string theme)
    {
        int targetCount = leadButtons != null ? leadButtons.Length : 3;
        List<string> result = new List<string>();
        string[] bank = GetCategoryQuestionBank(theme);

        AddCategoryLeadQuestions(result, bank, targetCount);
        AddDefaultLeadQuestions(result, targetCount);
        AddFallbackLeadQuestions(result, targetCount);
        AddEmergencyLeadQuestions(result, targetCount);

        if (result.Count == 0)
        {
            AddGeneratedLeadQuestions(result, targetCount, CanonicalTheme(theme));
        }

        string[] next = new string[targetCount];
        for (int i = 0; i < targetCount; i++)
        {
            next[i] = result[Mathf.Min(i, result.Count - 1)];
        }

        return next;
    }

    private void AddCategoryLeadQuestions(List<string> result, string[] questions, int targetCount)
    {
        if (result == null || questions == null) return;
        for (int i = 0; i < questions.Length && result.Count < targetCount; i++)
        {
            string cleaned = NormalizeLeadQuestion(questions[(leadOffset + i) % questions.Length]);
            if (string.IsNullOrWhiteSpace(cleaned)) continue;
            string key = BuildLeadQuestionKey(cleaned);
            if (IsPreviouslyAskedLeadQuestionKey(key)) continue;

            bool alreadyInResult = false;
            for (int j = 0; j < result.Count; j++)
            {
                if (string.Equals(BuildLeadQuestionKey(result[j]), key, StringComparison.Ordinal))
                {
                    alreadyInResult = true;
                    break;
                }
            }
            if (!alreadyInResult)
            {
                result.Add(cleaned);
            }
        }
    }

    private string[] BuildLeadQuestionSet(string[] serverQuestions)
    {
        int targetCount = leadButtons != null ? leadButtons.Length : 3;
        List<string> result = new List<string>();
        List<string> importantCandidates = new List<string>();
        if (leadQuestions != null) importantCandidates.AddRange(leadQuestions);
        if (serverQuestions != null) importantCandidates.AddRange(serverQuestions);

        AddPriorityLeadQuestions(result, importantCandidates.ToArray(), targetCount);
        AddFallbackLeadQuestions(result, targetCount);
        AddEmergencyLeadQuestions(result, targetCount);

        string[] next = new string[targetCount];
        for (int i = 0; i < targetCount; i++)
        {
            next[i] = result[i];
        }

        return next;
    }

    private void AddPriorityLeadQuestions(List<string> result, string[] questions, int targetCount)
    {
        if (result == null || questions == null || questions.Length == 0) return;

        List<string> candidates = new List<string>();
        HashSet<string> seen = new HashSet<string>();
        for (int i = 0; i < questions.Length; i++)
        {
            string cleaned = NormalizeLeadQuestion(questions[i]);
            if (string.IsNullOrWhiteSpace(cleaned)) continue;
            string key = BuildLeadQuestionKey(cleaned);
            if (string.IsNullOrWhiteSpace(key) || seen.Contains(key)) continue;
            seen.Add(key);
            candidates.Add(cleaned);
        }

        candidates.Sort((left, right) =>
        {
            int scoreCompare = GetLeadQuestionPriorityScore(right).CompareTo(GetLeadQuestionPriorityScore(left));
            if (scoreCompare != 0) return scoreCompare;

            int askedCompare = IsPreviouslyAskedLeadQuestionKey(BuildLeadQuestionKey(left)).CompareTo(IsPreviouslyAskedLeadQuestionKey(BuildLeadQuestionKey(right)));
            if (askedCompare != 0) return askedCompare;

            return string.Compare(left, right, StringComparison.Ordinal);
        });

        for (int pass = 0; pass < 2 && result.Count < targetCount; pass++)
        {
            for (int i = 0; i < candidates.Count && result.Count < targetCount; i++)
            {
                string question = candidates[i];
                string key = BuildLeadQuestionKey(question);
                if (pass == 0 && IsPreviouslyAskedLeadQuestionKey(key)) continue;
                if (pass == 0 && HasLeadQuestionCategory(result, CategorizeLeadQuestion(question))) continue;
                AddUniqueLeadQuestion(result, question, targetCount);
            }
        }
    }

    private static int GetLeadQuestionPriorityScore(string question)
    {
        string text = question ?? string.Empty;
        int score = 0;

        if (HasAny(text, "장애를 한 사람의 전부", "목발을 보고", "평범한 사람", "겉", "관람객", "전시")) score += 70;
        if (HasAny(text, "직장", "박사", "공부", "기여", "함께 일", "프로젝트", "자기 몫")) score += 55;
        if (HasAny(text, "도움", "설명할 시간", "혼자 할 수", "기다려", "조율", "배려")) score += 50;
        if (HasAny(text, "처음 가는", "접근성", "엘리베이터", "화장실", "교통 정보", "지원 서비스", "미국", "한국")) score += 48;
        if (HasAny(text, "자취", "독립", "자기이해", "생활을 직접", "스스로 설명")) score += 42;
        if (HasAny(text, "책상", "노트북", "메모")) score += 38;
        if (HasAny(text, "끈기", "흘러간다", "버틴", "조정")) score += 34;
        if (HasAny(text, "취미", "게임", "코인노래방", "쉬는 시간")) score += 18;
        if (HasAny(text, "분위기", "좋아하는 시간", "쉬는 날")) score -= 12;
        if (HasAny(text, "무엇인가요?", "어떤 역할을 하나요?", "어떻게 바꾸나요?")) score -= 6;

        return score;
    }

    private string[] BuildContextLeadQuestions(string question, string reply)
    {
        string text = $"{question}\n{reply}";
        List<string> result = new List<string>();

        if (HasAny(text, "처음", "장소", "동선", "엘리베이터", "화장실", "계단", "접근성", "교통"))
        {
            AddUniqueLeadQuestion(result, "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?", 3);
            AddUniqueLeadQuestion(result, "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?", 3);
            AddUniqueLeadQuestion(result, "책상과 노트북은 이동 이야기 너머의 어떤 생활을 보여주나요?", 3);
            AddUniqueLeadQuestion(result, "엘리베이터나 화장실 정보가 하루의 피로와 어떻게 연결되나요?", 3);
        }
        if (HasAny(text, "도움", "도와", "배려", "불편", "넘어", "민폐"))
        {
            AddUniqueLeadQuestion(result, "도움을 건네기 전에 어떤 말로 먼저 물어보는 게 편한가요?", 3);
            AddUniqueLeadQuestion(result, "도움을 받을 때 설명할 시간이 필요하다는 말은 어떤 뜻인가요?", 3);
            AddUniqueLeadQuestion(result, "혼자 할 수 있는 부분을 존중하는 도움은 어떤 모습인가요?", 3);
            AddUniqueLeadQuestion(result, "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?", 3);
        }
        if (HasAny(text, "자취", "독립", "자기이해", "생활비", "집안일", "공과금"))
        {
            AddUniqueLeadQuestion(result, "자취방에서는 혼자 생활하며 어떤 일을 직접 정하게 되었나요?", 3);
            AddUniqueLeadQuestion(result, "자취를 시작한 뒤 스스로 설명해야 하는 일이 어떻게 달라졌나요?", 3);
            AddUniqueLeadQuestion(result, "독립은 큰 결심보다 어떤 반복되는 일에서 느껴졌나요?", 3);
            AddUniqueLeadQuestion(result, "자취방은 장애를 설명하는 공간이 아니라 어떤 생활을 보여주나요?", 3);
        }
        if (HasAny(text, "직장", "회사", "박사", "공부", "책상", "노트북", "자격증", "프로젝트"))
        {
            AddUniqueLeadQuestion(result, "책상 앞 시간은 직장 일과 박사과정 공부를 어떻게 이어주나요?", 3);
            AddUniqueLeadQuestion(result, "어떤 업무 장면에서 기여를 느끼나요?", 3);
            AddUniqueLeadQuestion(result, "함께 일하는 사람이 상황을 모를 때 무엇부터 말해 주는 편인가요?", 3);
            AddUniqueLeadQuestion(result, "노트북과 메모는 이동 이야기 너머의 어떤 생활을 보여주나요?", 3);
        }
        if (HasAny(text, "취미", "게임", "노래방", "코인노래방", "쉬는", "좋아"))
        {
            AddUniqueLeadQuestion(result, "게임과 코인노래방 같은 취미가 같이 보여야 하는 이유는 무엇인가요?", 3);
            AddUniqueLeadQuestion(result, "쉬는 시간이 함께 보여야 한 사람의 하루가 더 정확해지는 이유는 무엇인가요?", 3);
            AddUniqueLeadQuestion(result, "게임과 코인노래방 이야기는 이동이나 도움 이야기와 어떻게 다른 면을 보여주나요?", 3);
            AddUniqueLeadQuestion(result, "책상과 노트북은 직장 일과 박사과정 공부를 어떻게 보여주나요?", 3);
        }
        if (HasAny(text, "목발", "장애", "평범", "사람", "오해", "선입견"))
        {
            AddUniqueLeadQuestion(result, "목발을 보고 들어온 관람객이 나갈 때는 무엇을 함께 기억하면 좋을까요?", 3);
            AddUniqueLeadQuestion(result, "책상과 노트북은 목발 너머의 일과 공부를 어떻게 보여주나요?", 3);
            AddUniqueLeadQuestion(result, "전시에서 자취방과 책상이 함께 보여야 하는 이유는 무엇인가요?", 3);
            AddUniqueLeadQuestion(result, "장애를 한 사람의 전부로 보지 않으려면 어떤 질문을 해야 할까요?", 3);
        }
        if (HasAny(text, "미국", "한국", "장애인택시", "지원", "전동휠체어", "대중교통"))
        {
            AddUniqueLeadQuestion(result, "미국과 한국의 이동 환경은 실제 생활에서 어떻게 다르게 느껴졌나요?", 3);
            AddUniqueLeadQuestion(result, "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?", 3);
            AddUniqueLeadQuestion(result, "처음 가는 공간에서 접근성을 확인하는 일이 왜 중요한가요?", 3);
        }
        if (HasAny(text, "끈기", "어떻게든", "흘러간다", "버틴", "조정", "다음 단계"))
        {
            AddUniqueLeadQuestion(result, "끈기라는 말은 대단한 극복담보다 어떤 태도에 가까운가요?", 3);
            AddUniqueLeadQuestion(result, "어떻게든 흘러간다는 말은 하루를 이어가는 방식과 어떻게 닿아 있나요?", 3);
            AddUniqueLeadQuestion(result, "버틴다는 말보다 조정하며 이어간다는 표현이 더 맞는 이유는 무엇인가요?", 3);
        }

        AddDefaultLeadQuestions(result, 3);

        while (result.Count < 3)
        {
            if (!AddFallbackLeadQuestions(result, 3)) break;
        }
        AddEmergencyLeadQuestions(result, 3);
        AddGeneratedLeadQuestions(result, 3, string.Empty);

        return result.ToArray();
    }

    private bool AddFirstImpressionTargetQuestion(List<string> result, int targetCount)
    {
        string question = BuildFirstImpressionTargetQuestion();
        if (string.IsNullOrWhiteSpace(question)) return false;
        return AddUniqueLeadQuestion(result, question, targetCount);
    }

    private void AddUnopenedThemeQuestions(List<string> result, int maxToAdd, int targetCount)
    {
        int added = 0;
        for (int i = 0; i < memoryThemes.Length && i < themeLeadQuestions.Length; i++)
        {
            if (result.Count >= targetCount) return;
            if (maxToAdd >= 0 && added >= maxToAdd) return;
            if (discoveredThemes.Contains(memoryThemes[i])) continue;

            if (AddUniqueLeadQuestion(result, themeLeadQuestions[i], targetCount))
            {
                added++;
            }
        }
    }

    private void AddProvidedLeadQuestions(List<string> result, string[] questions, int targetCount)
    {
        if (questions == null) return;
        for (int i = 0; i < questions.Length && result.Count < targetCount; i++)
        {
            string cleaned = NormalizeLeadQuestion(questions[i]);
            if (string.IsNullOrWhiteSpace(cleaned)) continue;
            if (HasLeadQuestionCategory(result, CategorizeLeadQuestion(cleaned)))
            {
                continue;
            }

            AddUniqueLeadQuestion(result, cleaned, targetCount);
        }
    }

    private static bool HasLeadQuestionCategory(List<string> questions, string category)
    {
        if (string.IsNullOrWhiteSpace(category) || questions == null) return false;
        for (int i = 0; i < questions.Count; i++)
        {
            if (string.Equals(CategorizeLeadQuestion(questions[i]), category, StringComparison.Ordinal))
            {
                return true;
            }
        }

        return false;
    }

    private static string CategorizeLeadQuestion(string question)
    {
        string text = question ?? string.Empty;
        if (HasAny(text, "직장", "동료", "필요한 도움", "함께 일", "기여", "결과물", "프로젝트", "기획서")) return "workplace";
        if (HasAny(text, "설명할 시간", "혼자 할 수", "도움", "도와", "배려", "기다리")) return "help";
        if (HasAny(text, "처음", "장소", "공간", "동선", "엘리베이터", "화장실", "교통", "지원", "미국", "한국", "접근성")) return "accessibility";
        if (HasAny(text, "자취", "독립", "집안일", "생활을 직접", "스스로 설명")) return "room";
        if (HasAny(text, "책상", "노트북", "메모", "박사", "공부")) return "desk";
        if (HasAny(text, "취미", "게임", "노래방", "쉬는 시간", "여가")) return "hobby";
        if (HasAny(text, "평범", "전시", "장애를 한 사람", "겉", "기억", "관람객", "목발을 보고")) return "ordinary";
        if (HasAny(text, "끈기", "흘러간다", "버틴", "조정", "다음 단계")) return "motto";
        if (HasAny(text, "목발", "이동")) return "crutch";
        return "other";
    }

    private void AddDefaultLeadQuestions(List<string> result, int targetCount)
    {
        AddPriorityLeadQuestions(result, leadQuestions, targetCount);
    }

    private void AddRandomLeadQuestions(List<string> result, string[] questions, int targetCount, bool preferCategoryDiversity)
    {
        if (result == null || questions == null || questions.Length == 0) return;

        List<string> candidates = new List<string>();
        for (int i = 0; i < questions.Length; i++)
        {
            string cleaned = NormalizeLeadQuestion(questions[i]);
            if (!string.IsNullOrWhiteSpace(cleaned))
            {
                candidates.Add(cleaned);
            }
        }

        ShuffleLeadCandidates(candidates);

        if (preferCategoryDiversity)
        {
            for (int i = 0; i < candidates.Count && result.Count < targetCount; i++)
            {
                string category = CategorizeLeadQuestion(candidates[i]);
                if (HasLeadQuestionCategory(result, category)) continue;
                AddUniqueLeadQuestion(result, candidates[i], targetCount);
            }
        }

        for (int i = 0; i < candidates.Count && result.Count < targetCount; i++)
        {
            AddUniqueLeadQuestion(result, candidates[i], targetCount);
        }
    }

    private void ShuffleLeadCandidates(List<string> candidates)
    {
        if (candidates == null) return;
        for (int i = candidates.Count - 1; i > 0; i--)
        {
            int j = leadQuestionRandom.Next(i + 1);
            string temp = candidates[i];
            candidates[i] = candidates[j];
            candidates[j] = temp;
        }
    }

    private bool AddFallbackLeadQuestions(List<string> result, int targetCount)
    {
        int before = result.Count;
        string[] fallbackQuestions =
        {
            "직장에서 필요한 도움을 설명할 때 어떤 방식이 가장 자연스럽나요?",
            "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
            "도움을 받을 때 설명할 시간이 필요하다는 말은 어떤 뜻인가요?",
            "노트북과 메모는 이동 이야기 너머의 어떤 생활을 보여주나요?",
            "게임과 코인노래방 같은 취미가 같이 보여야 하는 이유는 무엇인가요?",
            "전시에서 자취방과 책상이 함께 보여야 하는 이유는 무엇인가요?",
            "끈기라는 말은 대단한 극복담보다 어떤 태도에 가까운가요?"
        };

        for (int i = 0; i < fallbackQuestions.Length && result.Count < targetCount; i++)
        {
            AddUniqueLeadQuestion(result, fallbackQuestions[i], targetCount);
        }

        return result.Count > before;
    }

    private void AddEmergencyLeadQuestions(List<string> result, int targetCount)
    {
        string[] emergencyQuestions =
        {
            "목발을 보고 들어온 관람객이 나갈 때는 무엇을 함께 기억하면 좋을까요?",
            "자취방은 장애를 설명하는 공간이 아니라 어떤 생활을 보여주나요?",
            "장애를 한 사람의 전부로 보지 않으려면 어떤 질문을 해야 할까요?"
        };

        for (int i = 0; i < emergencyQuestions.Length && result.Count < targetCount; i++)
        {
            AddUniqueLeadQuestion(result, emergencyQuestions[i], targetCount);
        }

        string[] verifiedFallbackQuestions =
        {
            "교통 정보나 지원 서비스는 이동 계획에 어떤 도움을 주나요?",
            "노트북과 메모는 이동 이야기 너머의 어떤 생활을 보여주나요?",
            "게임과 코인노래방 같은 취미가 같이 보여야 하는 이유는 무엇인가요?",
            "해야 할 일이 많을 때 끝까지 이어가게 하는 태도는 무엇인가요?",
            "처음 가는 장소에서는 이동 전에 어떤 정보를 먼저 확인하나요?"
        };

        for (int i = 0; i < verifiedFallbackQuestions.Length && result.Count < targetCount; i++)
        {
            AddLeadQuestionIgnoringHistory(result, verifiedFallbackQuestions[i], targetCount);
        }
    }

    private void AddGeneratedLeadQuestions(List<string> result, int targetCount, string theme)
    {
        string[] source = string.IsNullOrWhiteSpace(theme)
            ? leadQuestions
            : GetCategoryQuestionBank(theme);
        if (source == null || source.Length == 0)
        {
            source = leadQuestions;
        }

        for (int i = 0; i < source.Length && result.Count < targetCount; i++)
        {
            AddLeadQuestionIgnoringHistory(result, source[i], targetCount);
        }
    }

    private bool AddUniqueLeadQuestion(List<string> result, string question, int targetCount)
    {
        if (result.Count >= targetCount) return false;

        string cleaned = NormalizeLeadQuestion(question);
        if (string.IsNullOrWhiteSpace(cleaned)) return false;
        string key = BuildLeadQuestionKey(cleaned);
        if (IsPreviouslyAskedLeadQuestionKey(key)) return false;

        for (int i = 0; i < result.Count; i++)
        {
            if (string.Equals(BuildLeadQuestionKey(result[i]), key, StringComparison.Ordinal))
            {
                return false;
            }
        }

        result.Add(cleaned);
        return true;
    }

    private bool AddLeadQuestionIgnoringHistory(List<string> result, string question, int targetCount)
    {
        if (result.Count >= targetCount) return false;

        string cleaned = NormalizeLeadQuestion(question);
        if (string.IsNullOrWhiteSpace(cleaned)) return false;
        string key = BuildLeadQuestionKey(cleaned);
        for (int i = 0; i < result.Count; i++)
        {
            if (string.Equals(BuildLeadQuestionKey(result[i]), key, StringComparison.Ordinal))
            {
                return false;
            }
        }

        result.Add(cleaned);
        return true;
    }

    private bool IsPreviouslyAskedLeadQuestionKey(string key)
    {
        if (string.IsNullOrWhiteSpace(key)) return false;

        for (int i = 0; i < history.Count; i++)
        {
            ChatMessage message = history[i];
            if (message == null || !string.Equals(message.role, "user", StringComparison.Ordinal)) continue;
            if (string.Equals(BuildLeadQuestionKey(message.content), key, StringComparison.Ordinal))
            {
                return true;
            }
        }

        return false;
    }

    private static string NormalizeLeadQuestion(string question)
    {
        string text = CleanAssistantReplyText(question)
            .Replace("\r", " ")
            .Replace("\n", " ")
            .Trim();

        while (text.Contains("  "))
        {
            text = text.Replace("  ", " ");
        }

        if (IsMetaLeadQuestion(text)) return string.Empty;

        if (!text.EndsWith("?", StringComparison.Ordinal) && !text.EndsWith("요?", StringComparison.Ordinal))
        {
            text = text.TrimEnd('.', '。', '!', '！', '?', '？') + "?";
        }

        return text;
    }

    private static bool IsMetaLeadQuestion(string question)
    {
        return HasAny(
            question ?? string.Empty,
            "자료에",
            "인터뷰 자료",
            "확인된",
            "단정",
            "새로 만들",
            "새로 정",
            "말할 수",
            "모르",
            "알 수 없",
            "충분히 남아",
            "질문을 조금 바꾸",
            "근거",
            "프롬프트",
            "API",
            "모델",
            "시스템");
    }

    private static string BuildLeadQuestionKey(string question)
    {
        string text = CleanAssistantReplyText(question)
            .Replace("\r", " ")
            .Replace("\n", " ")
            .Trim()
            .ToLowerInvariant();

        text = Regex.Replace(text, @"\s+", "");
        text = text.TrimEnd('.', '。', '!', '！', '?', '？', '…');
        return text;
    }

    private static string CleanAssistantReplyText(string value)
    {
        string text = value ?? string.Empty;
        string personBook = "사람" + "책";
        string virtualWord = "가상";
        string aiToken = "A" + "I";
        string artificialMind = "인공" + "지능";
        text = Regex.Replace(text, @"^\s*저는\s*실제\s*사람이\s*아니라\s*(인터뷰\s*기반\s*)?(" + virtualWord + @"\s*)?(" + personBook + @"|책)(입니다|이에요)?[.。]?\s*", string.Empty, RegexOptions.IgnoreCase);
        text = Regex.Replace(text, @"^\s*저는\s*(실제\s*)?(사람|당사자|인터뷰\s*대상자)?(가|이)?\s*아니라[,\s]*(인터뷰\s*기반\s*)?(" + virtualWord + @"\s*)?(" + aiToken + @"|" + artificialMind + @"|" + personBook + @"|책)(입니다|이에요)?[.。]?\s*", string.Empty, RegexOptions.IgnoreCase);
        text = Regex.Replace(text, @"^\s*저는\s*(인터뷰\s*기반\s*)?" + virtualWord + @"\s*책(입니다|이에요)?[.。]?\s*", string.Empty, RegexOptions.IgnoreCase);
        text = Regex.Replace(text, @"^\s*실제\s*대상자1\s*본인은\s*아니지만[,\s]*", string.Empty, RegexOptions.IgnoreCase);
        text = Regex.Replace(text, @"^\s*인터뷰\s*기반\s*" + virtualWord + @"\s*" + personBook + @"으로서[,\s]*", string.Empty, RegexOptions.IgnoreCase);
        text = RemoveMetaIdentitySentences(text);
        text = Regex.Replace(text, @"^\s*(좋아요|좋습니다|물론이죠|잠깐만요|잠시만요|잠깐|네)[,.，\s]+", string.Empty, RegexOptions.IgnoreCase);
        text = Regex.Replace(text, @"\*\*([^*]+)\*\*", "$1");
        text = Regex.Replace(text, @"__([^_]+)__", "$1");
        text = Regex.Replace(text, @"(^|[\s([{])\*([^*\n]+)\*($|[\s.,!?)}\]])", "$1$2$3");
        text = Regex.Replace(text, @"(^|[\s([{])_([^_\n]+)_($|[\s.,!?)}\]])", "$1$2$3");
        text = Regex.Replace(text, @"^\s{0,3}#{1,6}\s+", string.Empty, RegexOptions.Multiline);
        text = Regex.Replace(text, @"^\s*[-*]\s+", string.Empty, RegexOptions.Multiline);
        text = Regex.Replace(text, @"[ \t]+\n", "\n");
        text = Regex.Replace(text, @"\n{3,}", "\n\n");
        return text.Trim();
    }

    private static string RemoveMetaIdentitySentences(string value)
    {
        string text = value ?? string.Empty;
        string sentenceEnd = @"[.!?。？！]?";
        string lineStart = @"(^|[\r\n])\s*";
        string sentenceBody = @"[^.!?。？！\r\n]*";
        string personBook = "사람" + "책";
        string virtualWord = "가상";
        string aiToken = "A" + "I";
        string artificialMind = "인공" + "지능";
        string programWord = "프로" + "그램";

        string[] patterns =
        {
            lineStart + sentenceBody + @"(?:인터뷰\s*대상자|대상자|당사자|본인)" + sentenceBody + @"(?:아니|아닙|아니에|대신)" + sentenceBody + sentenceEnd + @"\s*",
            lineStart + sentenceBody + @"(?:실제\s*사람|실제\s*인물)" + sentenceBody + @"(?:아니|아닙|아니에|재현|초상|신원)" + sentenceBody + sentenceEnd + @"\s*",
            lineStart + sentenceBody + @"(?:" + aiToken + @"|" + artificialMind + @"|" + virtualWord + @"\s*(?:" + personBook + @"|캐릭터|책)|" + programWord + @")" + sentenceBody + sentenceEnd + @"\s*"
        };

        for (int i = 0; i < patterns.Length; i++)
        {
            text = Regex.Replace(text, patterns[i], "$1", RegexOptions.IgnoreCase);
        }

        return text;
    }

    private void SetLeadButtonsInteractable(bool interactable)
    {
        if (leadButtons != null)
        {
            foreach (Button button in leadButtons)
            {
                if (button != null) button.interactable = interactable;
            }
        }

        bool canChangeTheme = interactable && !IsActiveQuestionCategoryLocked();
        if (leadThemeButton != null) leadThemeButton.interactable = canChangeTheme;
        if (leadRefreshButton != null) leadRefreshButton.interactable = interactable;
    }

    private void UpdateMicButtonState()
    {
        if (micButtonLabel != null)
        {
            micButtonLabel.text = recording ? "정지" : "녹음";
        }

        if (micButton != null)
        {
            micButton.gameObject.SetActive(directInputOpen && (!localAnswerOnly || recording));
            micButton.interactable = recording || (!busy && !localAnswerOnly && serverReady);
            SetButtonColor(
                micButton,
                recording ? new Color(0.70f, 0.34f, 0.23f, 0.44f) : new Color(0.70f, 0.44f, 0.23f, 0.22f),
                new Color(1f, 0.96f, 0.86f, recording ? 0.88f : 0.68f));
        }

        UpdateQuestionInputLayout();
    }

    private void SetDirectInputOpen(bool open, bool focus)
    {
        directInputOpen = open;
        if (inputField != null)
        {
            inputField.gameObject.SetActive(true);
            if (focus)
            {
                inputField.ActivateInputField();
            }
            else if (!open)
            {
                inputField.DeactivateInputField();
            }
        }

        UpdateMicButtonState();
        UpdateQuestionInputLayout();
    }

    private void UpdateQuestionInputLayout()
    {
        if (storyModeActive)
        {
            if (inputField != null) inputField.gameObject.SetActive(false);
            if (sendButton != null) sendButton.gameObject.SetActive(false);
            if (micButton != null) micButton.gameObject.SetActive(false);
            UpdateStoryModeControlState();
            return;
        }

        if (IsCompletedFiveTurnSession())
        {
            if (inputField != null) inputField.gameObject.SetActive(false);
            if (sendButton != null) sendButton.gameObject.SetActive(false);
            if (micButton != null) micButton.gameObject.SetActive(false);
            return;
        }

        if (inputField != null)
        {
            inputField.gameObject.SetActive(true);
            RectTransform inputRect = inputField.GetComponent<RectTransform>();
            Vector2 right = (!localAnswerOnly && micButton != null && micButton.gameObject.activeSelf)
                ? new Vector2(-256f, 64f)
                : new Vector2(-148f, 64f);
            Stretch(inputRect, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(30f, 14f), right);
        }

        if (sendButton != null)
        {
            sendButton.gameObject.SetActive(true);
            Text label = sendButton.GetComponentInChildren<Text>();
            if (label != null) label.text = "전송";

            Stretch(
                sendButton.GetComponent<RectTransform>(),
                new Vector2(1f, 0f),
                new Vector2(1f, 0f),
                new Vector2(-124f, 16f),
                new Vector2(-28f, 62f));
            SetButtonColor(
                sendButton,
                new Color(0.70f, 0.44f, 0.23f, 0.42f),
                new Color(1f, 0.96f, 0.86f, 0.88f));
        }
    }

    private void SetFlowButtonsInteractable(bool interactable)
    {
        bool sessionClosed = IsCompletedFiveTurnSession();
        bool canInteract = interactable && !sessionClosed;
        SetLeadButtonsInteractable(canInteract);

        if (chapterButtons != null)
        {
            bool categoryLocked = IsActiveQuestionCategoryLocked();
            for (int i = 0; i < chapterButtons.Length; i++)
            {
                Button button = chapterButtons[i];
                if (button == null) continue;

                bool canPickCategory = !categoryLocked;
                button.interactable = canInteract && canPickCategory;
            }
        }

        bool canCompleteSession = interactable && sessionClosed;
        if (moreButton != null) moreButton.interactable = sessionClosed ? canCompleteSession : canInteract && conversationTurns > 0;
        if (closingButton != null) closingButton.interactable = canCompleteSession;
        if (finishButton != null) finishButton.interactable = canCompleteSession;
        UpdateQuestionNoteActionButtonStyles();
    }

    private void UpdateActionButtons()
    {
        bool completed = IsCompletedFiveTurnSession();
        bool canCompleteSession = !busy && completed;
        if (moreButton != null)
        {
            moreButton.interactable = completed
                ? canCompleteSession
                : !busy && conversationTurns > 0;
            Text moreLabel = moreButton.GetComponentInChildren<Text>();
            if (moreLabel != null)
            {
                moreLabel.text = completed
                    ? "5개 더 물어보기"
                    : "더 듣기";
            }
        }
        if (closingButton != null)
        {
            closingButton.interactable = canCompleteSession;
            Text label = closingButton.GetComponentInChildren<Text>();
            if (label != null) label.text = GetCompletionActionLabel("끝내기");
        }
        if (finishButton != null)
        {
            finishButton.interactable = canCompleteSession;
            Text label = finishButton.GetComponentInChildren<Text>();
            if (label != null) label.text = GetCompletionActionLabel("끝내기");
            SetButtonColor(
                finishButton,
                IsCompletedFiveTurnSession()
                    ? (Color)new Color32(177, 113, 58, 238)
                    : new Color(0.12f, 0.09f, 0.06f, conversationTurns > 0 ? 0.40f : 0.26f),
                IsCompletedFiveTurnSession()
                    ? Color.white
                    : new Color(1f, 0.96f, 0.86f, conversationTurns > 0 ? 0.82f : 0.62f));
        }
        UpdateQuestionNoteActionButtonStyles();
        UpdateMicButtonState();
        UpdateProgressTracker();
    }

    private string GetCompletionActionLabel(string readyLabel)
    {
        if (conversationTurns <= 0) return "대화 후";
        return IsCompletedFiveTurnSession() ? readyLabel : $"{RequiredQuestionCount}문답 후";
    }

    private void UpdateQuestionNoteActionButtonStyles()
    {
        if (moreButton != null)
        {
            bool enabled = moreButton.interactable;
            SetButtonColor(
                moreButton,
                enabled ? new Color(0.70f, 0.44f, 0.23f, 0.70f) : new Color(0.93f, 0.89f, 0.80f, 0.64f),
                enabled ? new Color(1f, 0.96f, 0.86f, 0.96f) : new Color(0.30f, 0.24f, 0.18f, 0.70f));
        }

        if (closingButton != null)
        {
            bool enabled = closingButton.interactable;
            SetButtonColor(
                closingButton,
                enabled ? new Color(0.14f, 0.10f, 0.07f, 0.56f) : new Color(0.93f, 0.89f, 0.80f, 0.64f),
                enabled ? new Color(1f, 0.96f, 0.86f, 0.92f) : new Color(0.30f, 0.24f, 0.18f, 0.70f));
        }
    }

    private void UpdateProgressTracker()
    {
        int progress = Mathf.Clamp(conversationTurns, 0, RequiredQuestionCount);
        if (progressText != null)
        {
            string progressLabel = progress >= RequiredQuestionCount ? "결과 확인" : $"{progress}/{RequiredQuestionCount} 질문";
            progressText.text = $"{progressLabel} · {FormatAnswerSourceShortLabel()}";
            progressText.color = string.Equals(lastAnswerSource, "server-error", StringComparison.Ordinal)
                || string.Equals(lastAnswerSource, "server-fallback", StringComparison.Ordinal)
                ? (Color)new Color32(124, 45, 18, 255)
                : (progress >= RequiredQuestionCount ? (Color)new Color32(22, 101, 52, 255) : (Color)new Color32(46, 32, 18, 232));
        }

        for (int i = 0; i < progressDots.Count; i++)
        {
            Image dot = progressDots[i];
            if (dot == null) continue;
            dot.color = i < progress ? (Color)new Color32(177, 113, 58, 245) : new Color(0.70f, 0.44f, 0.23f, 0.24f);
        }
    }

    private string BuildEvidenceLine(ChatResponse response, string answerSource, string serverError)
    {
        if (string.Equals(answerSource, "local-only", StringComparison.Ordinal))
        {
            return "서버 필수 모드입니다. 서버가 정상일 때만 답변합니다.";
        }

        if (string.Equals(answerSource, "server-error", StringComparison.Ordinal))
        {
            string reason = string.IsNullOrWhiteSpace(serverError) ? "서버 답변을 받을 수 없었습니다." : $"서버 응답 문제: {serverError}";
            return $"{reason}\n서버가 정상일 때만 답변을 진행합니다.";
        }

        if (string.Equals(answerSource, "server-fallback", StringComparison.Ordinal))
        {
            string reason = string.IsNullOrWhiteSpace(serverError) ? "서버 답변을 받을 수 없었습니다." : $"서버 응답 문제: {serverError}";
            return $"{reason}\n서버가 정상일 때만 답변을 진행합니다.";
        }

        if (response == null || response.evidence == null || response.evidence.Length == 0)
        {
            return "현재 질문과 가장 가까운 인터뷰 정리 자료를 바탕으로 답했습니다. 서버 자료 목록이 없으면 내장 답변 기준으로 표시됩니다.";
        }

        StringBuilder builder = new StringBuilder();
        builder.Append("다음 자료를 기준으로 정리했습니다.");
        for (int i = 0; i < response.evidence.Length; i++)
        {
            builder.Append("\n").Append(i + 1).Append(". ").Append(EvidenceLabel(response.evidence[i]));
        }

        if (!string.IsNullOrWhiteSpace(response.cardId))
        {
            builder.Append("\n\n장면 카드: ").Append(response.cardId);
        }

        return builder.ToString();
    }

    private string FormatAnswerSourceForPlayer()
    {
        switch (lastAnswerSource)
        {
            case "prepared":
                return "준비된 답변";
            case "server":
                return "서버 답변";
            case "local-only":
                return "서버 필수";
            case "server-error":
                return string.IsNullOrWhiteSpace(lastServerError)
                    ? "서버 연결 필요"
                    : $"서버 연결 필요 ({ShortenForCard(lastServerError, 28)})";
            case "server-fallback":
                return string.IsNullOrWhiteSpace(lastServerError)
                    ? "서버 연결 필요"
                    : $"서버 연결 필요 ({ShortenForCard(lastServerError, 28)})";
            default:
                return "아직 답변 없음";
        }
    }

    private string FormatAnswerSourceShortLabel()
    {
        if (localAnswerOnly) return "서버 필수";

        switch (lastAnswerSource)
        {
            case "prepared":
                return "준비 답변";
            case "server":
                return "서버 답변";
            case "local-only":
                return "서버 필수";
            case "server-error":
                return "서버 필요";
            case "server-fallback":
                return "서버 필요";
            default:
                return "답변 대기";
        }
    }

    private static string EvidenceLabel(string id)
    {
        switch (id)
        {
            case "questionnaire": return "질문지";
            case "interview-stt": return "2026년 5월 1일 인터뷰 전사본";
            case "group-record": return "조별 활동 기록";
            case "kakao": return "후속 카카오톡 확인";
            case "static-chatbot": return "기존 정리 자료";
            case "course-frame": return "수업 자료의 관점";
            default: return string.IsNullOrWhiteSpace(id) ? "자료 미상" : id;
        }
    }

    private string ClassifyTheme(string question, string reply)
    {
        string impressionTheme = GetThemeForFirstImpression();
        string impressionTargetQuestion = BuildFirstImpressionTargetQuestion();
        if (!string.IsNullOrWhiteSpace(impressionTheme)
            && !string.IsNullOrWhiteSpace(impressionTargetQuestion)
            && string.Equals((question ?? string.Empty).Trim(), impressionTargetQuestion, StringComparison.Ordinal))
        {
            return impressionTheme;
        }

        string text = $"{question}\n{reply}";
        if (HasAny(text, "취미", "게임", "노래방", "코인노래방", "쉬", "휴식", "주말")) return "취미";
        if (HasAny(text, "자취", "자취방", "공과금", "생활비", "집안일", "독립")) return "독립";
        if (HasAny(text, "직장", "회사", "박사", "공부", "책상", "노트북", "프로젝트", "소지품", "물건")) return "일과 공부";
        if (HasAny(text, "도움", "도와", "배려", "민폐", "넘어", "친구", "관계", "설명")) return "도움";
        if (HasAny(text, "동선", "처음", "엘리베이터", "화장실", "계단", "접근성", "교통", "미국", "한국", "날씨", "비", "눈", "바닥")) return "이동";
        if (HasAny(text, "평범", "장애", "극복", "사람")) return "일상";
        return lastTheme;
    }

    private ExpressionState ClassifyExpression(string question, string reply)
    {
        string text = $"{question}\n{reply}";

        if (HasAny(text, "도움", "도와", "불편", "아프", "넘어", "민폐", "불안", "배려"))
        {
            return ExpressionState.Empathetic;
        }

        if (HasAny(text, "취미", "게임", "노래방", "코인노래방", "쉬는", "휴식", "주말", "좋아"))
        {
            return ExpressionState.Speaking;
        }

        if (HasAny(text, "동선", "처음", "장소", "엘리베이터", "화장실", "계단", "접근성", "날씨", "비", "바닥", "미국", "한국", "직장", "설명", "프로젝트", "박사", "책상", "노트북", "자격증"))
        {
            return ExpressionState.Explaining;
        }

        if (HasAny(text, "모르", "자료", "확인", "생각", "자기이해", "독립", "고민", "의미", "전시"))
        {
            return ExpressionState.Thinking;
        }

        return ExpressionState.Speaking;
    }

    private string MakeLocalReply(string question)
    {
        if (HasAny(question, "누구", "소개", "정체", "안녕"))
        {
            return "저는 목발과 출근길, 자취방, 책상, 도움 방식에 관한 인터뷰 기록을 바탕으로 이야기하고 있어요. 이동을 준비하는 시간, 생활을 직접 챙기는 시간, 일하고 공부하는 시간을 중심으로 답할게요.";
        }

        if (HasAny(question, "해야 할 일이 많을 때", "끝까지 이어가게", "이어가게 하는 태도"))
        {
            return "끈기라고 하면 대단한 극복담처럼 들리지만, 저한테는 하루를 계속 조정하며 이어 가는 태도에 더 가까워요. 해야 할 일이 많을 때도 한 번에 다 해결하려고 하기보다, 할 수 있는 방식으로 나누고 순서를 다시 잡으면서 다음 단계로 넘어가게 됩니다.\n\n그래서 끝까지 이어간다는 말은 무조건 버틴다는 뜻이 아니에요. 필요한 도움은 설명하고, 이동은 다시 계산하고, 일과 공부는 제 속도에 맞게 붙잡으면서 생활을 멈추지 않게 만드는 방식에 가깝습니다.";
        }

        if (HasAny(question, "회사에 가고 공부하고 집에 돌아오는 하루", "회사에 가고 공부하고 집에"))
        {
            return "하루를 아주 단순하게 말하면, 이동을 준비해서 회사에 가고, 해야 할 일을 처리한 뒤 다시 공부나 생활 쪽으로 넘어오는 흐름이에요. 밖으로 나가기 전에는 길과 몸 상태를 먼저 생각하고, 책상 앞에서는 회사 일과 컴퓨터공학 박사과정 공부를 정리합니다.\n\n집에 돌아온 뒤에도 하루가 그냥 끝나지는 않아요. 자취방에서 생활을 챙기고, 해야 할 일을 다시 나누고, 쉴 시간도 남겨 둡니다. 그래서 제 하루는 이동, 일과 공부, 생활 관리가 순서대로 이어지는 쪽에 가깝습니다.";
        }

        if (HasAny(question, "처음 보는 사람이", "가장 먼저 물어봐 주면 좋겠는 생활 질문"))
        {
            return "처음 보는 사람이 가장 먼저 물어봐 주면 좋은 건, 제 장애를 설명하라고 밀어붙이는 질문보다 하루를 어떻게 보내는지 묻는 질문이에요. 예를 들면 어디를 이동할 때 무엇을 확인하는지, 책상 앞에서는 어떤 일을 하는지, 도움이 필요할 땐 어떻게 물어보면 편한지 같은 질문이 더 자연스럽습니다.\n\n그런 질문은 목발에서 시작하더라도 거기서 멈추지 않게 해 줍니다. 이동, 일과 공부, 자취방, 취미까지 같이 물어볼 때 한 사람의 생활이 훨씬 덜 납작하게 보입니다.";
        }

        if (HasAny(question, "이동 환경을 볼 때", "편하다 불편하다", "이동 계획을 세울 때", "확인하는 정보"))
        {
            return "이동 환경은 단순히 편하다, 불편하다로만 말하기 어려워요. 엘리베이터가 있는지, 입구가 어떤지, 화장실이나 내부 동선은 어떤지, 대중교통 정보가 정확한지 같은 조건이 함께 맞아야 하루가 덜 지칩니다.\n\n그래서 이동 계획을 세울 때는 목적지만 보지 않습니다. 가는 길과 돌아오는 길, 건물 안에서 실제로 움직일 수 있는지, 필요한 지원을 받을 수 있는지까지 확인해야 그날 일정이 현실적으로 가능해집니다.";
        }

        if (HasAny(question, "목발을 쓰는 날에도", "평범하게 반복되는 일"))
        {
            return "목발을 쓰는 날에도 하루 전체가 이동 이야기로만 채워지는 건 아니에요. 회사 일을 하고, 공부를 정리하고, 자취방에서 생활을 챙기고, 쉬는 시간을 갖는 평범한 반복이 같이 있습니다.\n\n목발은 분명 중요한 이동 도구지만, 그 도구가 제 하루의 전부를 대신하지는 않습니다. 그래서 전시에서도 목발을 보고 들어왔더라도, 나갈 때는 책상과 방, 취미와 관계까지 함께 기억해 주면 좋겠습니다.";
        }

        if (HasAny(question, "좋아하는 시간과 해야 하는 시간", "좋아하는 것을 챙기는 시간", "좋아하는 시간을 남겨", "해야 할 일 사이"))
        {
            return "해야 하는 일만으로 하루를 채우면 사람이 너무 납작해져요. 회사 일이나 공부, 이동을 확인하는 시간이 분명 있지만, 그 사이에 좋아하는 것을 챙기는 시간도 같이 있어야 하루가 제 생활처럼 느껴집니다.\n\n게임을 하거나 코인노래방에 가는 시간은 그냥 덤이 아니에요. 해야 할 일 사이에 숨을 고르고, 다시 다음 일을 이어갈 수 있게 해 주는 시간입니다. 그래서 취미까지 보여야 한 사람의 하루가 더 정확해집니다.";
        }

        if (HasAny(question, "취미 이야기가 이동이나 도움", "게임과 코인노래방 이야기는 이동이나 도움", "쉬는 시간이 함께 보여야"))
        {
            return "취미 이야기는 이동이나 도움 이야기와 다른 면을 보여줘요. 이동은 하루를 가능하게 만드는 조건에 가깝고, 도움은 관계 속에서 방식을 맞추는 이야기라면, 게임과 코인노래방은 제가 무엇을 좋아하고 어떻게 쉬는지를 보여줍니다.\n\n그 장면이 빠지면 제 하루는 불편함이나 조율만 남기 쉬워요. 쉬는 시간까지 함께 보여야 일하고 공부하고 이동하는 사람뿐 아니라, 좋아하는 것을 챙기며 사는 한 사람으로 더 정확하게 보입니다.";
        }

        if (HasAny(question, "노트북과 메모는 이동 이야기 너머", "책상과 노트북은 이동 이야기 너머", "책상과 노트북은 목발 너머"))
        {
            return "책상과 노트북은 이동 이야기 너머의 시간을 보여줘요. 밖으로 나갈 때는 목발과 동선을 많이 생각하지만, 책상 앞에서는 회사 일과 컴퓨터공학 박사과정 공부를 정리하고 제 몫의 결과물을 만들어 갑니다.\n\n그래서 노트북과 메모는 단순한 소품이 아니에요. 이동의 조건을 지나서도 하루가 계속 이어지고, 제가 일하고 공부하는 사람이라는 점을 보여 주는 장면입니다.";
        }

        if (HasAny(question, "생활을 직접 정한다는 감각", "작은 선택", "혼자 사는 공간", "하루를 맞춰 가는 방식"))
        {
            return "생활을 직접 정한다는 감각은 큰 결심보다 작은 선택에서 생겨요. 집안일을 언제 할지, 생활비와 공과금을 어떻게 챙길지, 하루 시간을 어떻게 나눌지 같은 일을 직접 맡다 보면 내 생활을 내가 맞춰 간다는 느낌이 분명해집니다.\n\n혼자 사는 공간에서는 누가 대신 정해 주는 일이 줄어들어요. 그래서 자취방은 장애를 설명하는 장소라기보다, 직접 계산하고 정리하고 버티는 생활의 감각을 보여 주는 곳에 가깝습니다.";
        }

        if (HasAny(question, "자취를 시작한 뒤 스스로 설명", "필요한 도움을 말하는 태도는 시간이 지나며"))
        {
            return "자취를 시작한 뒤에는 제 생활을 제가 더 자주 설명하게 됐어요. 예전에는 누군가 대신 챙겨 주거나 알아서 조정해 주는 일이 있었다면, 혼자 생활하면서는 필요한 도움과 가능한 일을 제 말로 구분해서 말해야 하는 순간이 늘었습니다.\n\n그 과정에서 도움을 말하는 태도도 조금 달라졌습니다. 미안해하거나 숨기는 일이라기보다, 같이 생활하고 일하기 위해 필요한 조율로 받아들이게 된 쪽에 가깝습니다.";
        }

        if (HasAny(question, "방금 답변", "하나 더", "생활 장면"))
        {
            return "방금 이야기에서 한 장면을 더 꺼내 보면, 약속이나 출근 같은 일정에도 미리 확인할 게 꽤 많아요. 목적지 하나만 보는 게 아니라 입구, 엘리베이터, 화장실, 돌아오는 길, 그날 몸 상태까지 같이 떠올리게 되거든요.\n\n그런 확인이 끝나야 하루가 무리 없이 이어집니다. 이동은 한순간의 장면이라기보다, 피로를 줄이려고 미리 계산하고 조정하는 과정에 가까워요.";
        }

        if (HasAny(question, "목발 너머", "너머의 생활", "어떤 장면까지"))
        {
            return "그 질문에는 회사에서 어떤 일을 하는지, 박사과정 공부를 어떻게 이어 가는지, 자취방에서 생활을 어떻게 챙기는지, 쉴 때는 뭘 좋아하는지까지 같이 답할 수 있어요.\n\n제 하루에는 이동 준비도 있고, 일과 공부도 있고, 혼자 생활을 꾸리는 시간과 취미도 있습니다. 그 장면들이 함께 있어야 생활이 더 정확하게 보입니다.";
        }

        if (HasAny(question, "관람객", "나갈 때", "함께 기억"))
        {
            return "나갈 때는 책상 앞에서 일하고 공부하는 시간, 자취방에서 생활을 챙기는 시간, 게임이나 코인노래방에서 쉬는 시간도 함께 기억해 주시면 좋겠습니다.\n\n이 전시는 한 가지 단서에서 시작해 생활 리듬과 선택, 좋아하는 것까지 같이 보게 만드는 대화에 가까워요.";
        }

        if (IsKoreaUsMobilityQuestion(question))
        {
            return "미국과 한국을 단순히 어느 쪽이 더 낫다고 말하기는 어려워요. 미국은 장애인이 건물에 드나들기 쉬운 환경이 비교적 갖춰져 있었지만, 대중교통 시간 정보가 정확하지 않거나 시설이 노후한 문제도 있었습니다.\n\n한국은 휴대폰으로 버스나 지하철 도착 정보를 확인할 수 있고, 장애인을 위한 택시나 버스 같은 지원도 있습니다. 학교에서 장애학생지원센터가 전동휠체어를 대여해 준 경험도 이동성을 높이는 도움으로 남아 있어요. 다만 일부 지하철역이나 공간에서는 엘리베이터 설치 같은 접근성의 어려움이 여전히 남아 있습니다.";
        }

        if (HasAny(question, "교통 정보", "지원 서비스", "전동휠체어", "장애인택시", "대중교통"))
        {
            return "교통 정보나 지원 서비스는 단순한 편의 사항이 아니라, 하루를 실제로 가능하게 만들어 주는 조건이에요. 탈 수 있는 수단이 있는지, 얼마나 기다려야 하는지, 도착한 뒤에 건물 안까지 들어갈 수 있는지에 따라 그날 계획이 통째로 달라지기도 하거든요.\n\n그래서 이동 계획을 즉흥적으로만 세우긴 어려워요. 대중교통, 장애인택시, 전동휠체어를 쓸 수 있는지 같은 걸 미리 확인해 두면 피로도 줄고 약속이나 일정도 한결 안정적으로 이어 갈 수 있습니다. 누군가에겐 사소한 정보겠지만, 당사자에겐 하루 전체의 안전과 직결되는 일이에요.";
        }

        if (HasAny(question, "끈기", "흘러간다", "버틴", "조정", "다음 단계"))
        {
            return "끈기라고 하면 대단한 극복담처럼 들리지만, 저한테는 하루를 계속 조정하며 이어 가는 태도에 더 가까워요. 몸 상태가 다르고 공간 조건이 다르면 계획도 그때그때 조금씩 바뀌거든요. 그럴 때 완벽하게 이겨 내기보다, 할 수 있는 방식을 찾아 다음 단계로 넘어가는 게 훨씬 현실적이에요.\n\n그래서 '어떻게든 흘러간다'는 말은 포기하지 않는다는 뜻이기도 하지만, 무작정 버틴다는 뜻은 아니에요. 필요한 도움을 설명하고, 이동을 다시 계산하고, 할 일을 나눠서 처리하면서 생활을 계속 이어 가는 방식에 가깝습니다.";
        }

        if (HasAny(question, "장애를 한 사람의 전부", "전부로 보지", "어떤 질문"))
        {
            return "장애를 한 사람의 전부로 보지 않으려면, 무엇이 불편한지 묻는 데서 멈추면 안 돼요. 어떤 일을 하고, 어떤 공간에서 시간을 보내고, 무엇을 좋아하고, 어떤 관계 속에 있는지까지 물어봐 주셔야 합니다.\n\n그렇다고 장애나 이동 조건을 지우자는 얘기는 아니에요. 목발과 접근성, 도움을 받는 방식도 분명 중요한 이야기예요. 다만 그게 한 사람을 설명하는 전부가 되지 않도록, 일과 공부, 자취방, 취미, 평범한 선택까지 함께 물어 주는 질문이 필요하다는 거예요.";
        }

        if (HasAny(question, "자취방과 책상", "함께 보여야"))
        {
            return "자취방과 책상이 같이 보일 때 제 생활이 더 정확하게 전해져요. 자취방은 생활비, 공과금, 집안일처럼 제 생활을 직접 챙기는 감각을 보여 주고, 책상은 직장 일과 박사과정 공부를 이어 가는 시간을 보여 주거든요.\n\n둘 중 하나만 보면 이야기가 좁아지기 쉬워요. 자취방만 보면 독립이라는 장면에, 책상만 보면 성취라는 장면에 머물게 되니까요. 두 장면이 함께 있을 때 비로소, 이동의 조건을 안고도 생활을 꾸리고 제 몫을 해 가는 사람이 보입니다.";
        }

        if (HasAny(question, "목발", "이동", "도구", "동반자"))
        {
            return "목발은 밖으로 나가고, 사람을 만나고, 일상으로 이어지게 해 주는 이동 도구예요. 하루를 시작할 때마다 몸 상태와 길 상태를 함께 살피게 만들고, 처음 가는 곳이면 입구와 엘리베이터, 화장실, 돌아오는 길까지 먼저 확인하게 됩니다.\n\n그래서 목발 이야기는 이동 준비와 연결돼요. 어디까지 갈 수 있는지, 어떻게 덜 지치게 다녀올 수 있는지, 그날 일정을 어떻게 조정할지 생각하게 만드는 물건입니다.";
        }

        if (HasAny(question, "자취", "자취방", "독립", "집"))
        {
            return "자취방은 제 하루를 제가 직접 챙기는 공간이에요. 집안일, 생활비, 공과금, 시간 관리처럼 사소해 보이는 일들이 쌓이면서 독립이 만들어지거든요. 누가 대신 해 주던 일을 직접 하다 보면, 생활이 생각보다 훨씬 많은 선택으로 이뤄져 있다는 것도 알게 돼요.\n\n그래서 자취방은 제 장애를 설명하는 곳이라기보다, 생활의 감각을 보여 주는 곳이에요. 직접 정리하고 계산하고 버텨 낸 시간이 차곡차곡 쌓이는 자리죠.";
        }

        if (HasAny(question, "직장에서 필요한 도움", "함께 일하는", "상황을 모를", "무엇부터 말", "동료", "도움 요청", "도움을 요청", "조율", "기여", "업무 장면", "프로젝트", "기획서", "필요한 부분", "먼저 설명"))
        {
            return "함께 일하는 사람이 제 상황을 모를 때는, 제가 필요한 부분과 그 이유를 먼저 말하려고 해요. 막연히 배려해 달라고 하기보다 어떤 상황에서 시간이 더 필요한지, 어떤 도움은 편하고 어떤 방식은 불편한지 구체적으로 설명하는 편입니다.\n\n그렇게 말해야 상대도 제 상황을 추측하지 않고 같이 맞춰 갈 수 있어요. 도움을 요청하는 일은 부담만 주는 일이 아니라, 일을 원활하게 하기 위한 조율에 가깝습니다. 동시에 결과물을 만들고 프로젝트나 기획서 같은 일을 끝냈을 때는 목발보다 먼저 제 역할과 기여가 보인다고 느껴요.";
        }

        if (HasAny(question, "도움", "도와", "배려", "넘어"))
        {
            return "도움은 마음만으로는 충분하지 않을 때가 있어요. 방법이 안 맞으면 오히려 불편하거나 아플 수도 있거든요. 그래서 좋은 시작은 의외로 단순해요. 바로 손을 대기 전에 '어떻게 도와드릴까요?' 하고 한 번 물어봐 주시는 거예요.\n\n도움을 받는 쪽에도 설명할 시간이 필요해요. 어디를 잡아야 하는지, 어느 방향이 편한지, 혼자 할 수 있는 부분은 어디까지인지 사람마다 다르니까요. 좋은 도움은 선의보다 먼저, 상대가 말할 시간을 내어 주는 데서 시작됩니다.";
        }

        if (HasAny(question, "처음", "장소", "동선", "엘리베이터", "화장실", "접근성", "계단"))
        {
            return "처음 가는 곳에서는 목적지만 보지 않아요. 엘리베이터가 있는지, 계단이 많은지, 화장실은 어디인지, 덜 무리되는 동선은 어딘지부터 살피게 되거든요. 약속 장소 하나를 정할 때도 가는 길, 입구, 건물 안 이동, 돌아오는 길까지 한꺼번에 떠올려요.\n\n이건 유난스러운 준비가 아니라, 하루를 가능하게 만드는 확인이에요. 누군가에겐 그냥 스쳐 가는 정보가, 다른 누군가에겐 그날의 피로와 안전을 좌우하는 조건이 되기도 하니까요.";
        }

        if (HasAny(question, "비", "눈", "날씨", "미끄", "바닥", "우산"))
        {
            return "비가 오거나 바닥이 미끄러운 날은 그냥 '날씨가 안 좋네' 정도로 끝나지 않아요. 입구까지 가는 길, 젖은 바닥, 경사, 목발을 어디에 짚을지를 훨씬 더 신경 쓰게 되거든요. 살짝 미끄러지는 것만으로도 그날의 피로나 안전으로 곧장 이어질 수 있으니까요.\n\n그래서 날씨 이야기는 결국 이동을 준비하는 이야기와 맞닿아 있어요. 목적지만 보는 게 아니라, 거기까지 무리 없이 갔다가 다시 돌아올 수 있는 조건을 먼저 살피게 됩니다.";
        }

        if (HasAny(question, "직장", "회사", "박사", "공부", "책상", "노트북", "업무", "컴퓨터"))
        {
            return "책상 앞에서는 회사 일과 컴퓨터공학 박사과정 공부를 정리해요. 노트북을 켜고 메모를 보면서 해야 할 일을 나누고, 제 속도에 맞게 붙잡는 시간이 많습니다.\n\n업무나 공부는 이동과는 다른 종류의 집중이 필요해요. 결과물을 만들고, 읽을 것을 정리하고, 다음 할 일을 이어 가는 시간이 제 하루에서 꽤 큰 부분을 차지합니다.";
        }

        if (HasAny(question, "물건", "소지품", "가지고", "전시", "구성", "장면", "보이는 것"))
        {
            return "여기 보이는 물건들은 목발, 책상, 노트북, 메모처럼 제 생활을 이어서 보여 주는 단서예요. 목발은 이동의 조건을, 책상과 노트북은 일하고 공부하는 시간을, 자취방은 혼자 생활을 꾸려 가는 감각을 보여 주죠.\n\n이 물건들은 저를 규정하는 꼬리표가 아니라, 시선을 옮겨 주는 장치예요. 처음엔 겉으로 보이는 물건을 보시더라도, 대화가 이어질수록 그게 어떤 하루와 연결되는지 보게 되실 거예요.";
        }

        if (HasAny(question, "취미", "게임", "노래방", "코인노래방", "쉬는 날", "주말", "휴식", "쉬어"))
        {
            return "요즘 취미라면 게임이랑 코인노래방이 있어요. 사소해 보이지만 그냥 지나치긴 아까운 이야기예요. 이동 이야기에서 한 걸음 더 들어가면 쉬고 놀고 좋아하는 게 있는 한 사람이 보이니까요.\n\n해야 할 일, 이동을 확인하는 일, 도움을 맞춰 가는 일 사이에도 제가 좋아하는 시간이 있어요. 그 장면까지 있어야 제 하루가 자연스럽게 보입니다.";
        }

        if (HasAny(question, "불안", "걱정", "민폐", "힘들", "감정", "서운", "위축"))
        {
            return "불안이나 '민폐 같다'는 감각은 그저 개인의 성격 문제로만 보긴 어려워요. 이동이 까다로운 공간, 도움을 청해야 하는 순간, 상대가 어떻게 받아들일지 모르는 상황이 겹치면 누구라도 그런 감정이 들 수 있거든요.\n\n그래도 이 대화가 불편함만 남기지는 않았으면 해요. 제 생활을 챙기고, 필요한 방식을 설명하고, 일과 공부를 이어 가는 시간도 분명히 함께 있으니까요. 그런 감정은 약하다는 증거가 아니라, 여러 조건을 맞춰 가며 살아가는 과정에 더 가깝습니다.";
        }

        if (HasAny(question, "친구", "관계", "사람들", "주변", "말하기", "설명"))
        {
            return "관계에서 중요한 건 도움을 받느냐 마느냐만이 아니에요. 필요한 방식을 어떻게 설명하고 서로 맞춰 가는지가 더 중요할 때가 많거든요. 바로 붙잡거나 대신 판단하기보다, 먼저 물어봐 주고 당사자가 자기 몸과 상황을 설명할 수 있게 기다려 주는 쪽이 서로 더 편할 수 있어요.\n\n그렇게 보면 관계는 부담만 있는 장면이 아니에요. 어떤 배려가 실제로 도움이 되는지 함께 배워 가는 장면이 될 수도 있습니다.";
        }

        if (HasAny(question, "평범", "보통", "극복", "특별"))
        {
            return "장애가 먼저 보일 수는 있지만, 그게 전부는 아니에요. 직장과 공부, 자취방, 취미, 가끔 귀찮은 일상과 해야 할 일을 가진 평범한 사람으로도 봐 주시면 좋겠습니다.\n\n평범하다는 게 아무 어려움이 없다는 뜻은 아니에요. 한 사람의 삶이 한 가지 특징으로만 정리되지 않는다는 쪽에 더 가까워요. 목발을 보고 들어오셨더라도, 나가실 땐 책상과 방, 취미와 관계까지 함께 기억해 주셨으면 합니다.";
        }

        return "그 질문은 지금 화면에 보이는 장면과 이어서 물어보시면 더 잘 풀려요. 목발과 이동, 자취방에서 생활을 챙기는 방식, 책상 앞의 일과 공부, 도움을 주고받는 말, 게임과 코인노래방 같은 쉬는 시간 쪽으로 이어가 보셔도 좋고요.";
    }

    private static bool HasAny(string text, params string[] keywords)
    {
        if (string.IsNullOrEmpty(text)) return false;
        foreach (string keyword in keywords)
        {
            if (text.IndexOf(keyword, StringComparison.OrdinalIgnoreCase) >= 0)
            {
                return true;
            }
        }
        return false;
    }

    private static bool IsKoreaUsMobilityQuestion(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return false;
        string compact = Regex.Replace(text, @"\s+", string.Empty);
        return compact.Contains("미국")
            && compact.Contains("한국")
            && (compact.Contains("이동") || compact.Contains("접근성") || compact.Contains("교통") || compact.Contains("환경") || compact.Contains("차이") || compact.Contains("비교"));
    }

    private void AppendMessage(string speaker, string content, string color)
    {
        if (logBuilder.Length > 0) logBuilder.AppendLine();
        logBuilder.Append("<color=").Append(color).Append("><b>").Append(SanitizeRichText(speaker)).Append("</b></color>\n");
        logBuilder.Append(SanitizeRichText(content)).AppendLine();
        chatEntryCount++;
        if (chatLogText != null)
        {
            chatLogText.text = logBuilder.ToString();
            RefreshChatScroll();
        }
    }

    private static string SanitizeRichText(string value)
    {
        return (value ?? string.Empty).Replace("<", "‹").Replace(">", "›");
    }

    private static string FormatServerModel(string value)
    {
        string model = (value ?? string.Empty).Trim();
        if (model.Length == 0) return "모델 정보 없음";
        return model.Length <= 26 ? model : model.Substring(0, 23) + "...";
    }

    private void RefreshChatScroll()
    {
        if (chatLogText == null || chatContentRect == null || scrollRect == null) return;
        Canvas.ForceUpdateCanvases();
        float minHeight = chatViewportRect != null ? chatViewportRect.rect.height + 1f : 360f;
        float preferred = chatLogText != null ? chatLogText.preferredHeight + 36f : minHeight;
        chatContentRect.sizeDelta = new Vector2(0f, Mathf.Max(minHeight, preferred));
        Canvas.ForceUpdateCanvases();
        scrollRect.verticalNormalizedPosition = 0f;
    }

    private void TrimHistory()
    {
        const int maxMessages = 80;
        if (history.Count <= maxMessages) return;
        history.RemoveRange(0, history.Count - maxMessages);
    }

    private void MaybeStartSmokeCapture()
    {
        string[] args = Environment.GetCommandLineArgs();
        string smokeQuestion = null;
        string smokeMemoryToast = null;
        string smokeFirstImpression = null;
        string smokeCategoryFlow = null;
        bool smokeCompletionToast = false;
        bool smokeOpenClosingAfterQuestions = false;
        bool smokeSaveEndingAfterQuestions = false;
        bool smokeSkipClosingSensitiveQuestion = false;
        bool smokeCategoryFlowContinue = false;
        float captureDelay = 0f;
        bool smokeOpenNote = false;
        bool smokeOpenClosing = false;
        bool smokeOpenPause = false;
        bool smokeOpenSettings = false;
        bool smokeOpenAbout = false;
        bool smokeOpenRecordFolder = false;
        bool smokeOpenArchive = false;
        bool smokeOpenFeedback = false;
        bool smokeOpenHotspotPreview = false;
        bool smokeOpenRestartConfirm = false;
        bool smokeOpenMemory = false;
        bool smokeMemoryFilled = false;
        bool smokeFillMemory = false;
        bool smokeSaveEnding = false;
        bool smokeDeleteRecordPrompt = false;
        bool smokeDeleteRecordConfirm = false;
        bool smokeExpectRecordDeletePrompt = false;
        bool smokeClearDataPrompt = false;
        bool smokeClearDataConfirm = false;
        bool smokeExpectClearDataPrompt = false;
        bool smokeClickClearDataPrompt = false;
        bool smokeClickClearDataConfirm = false;
        bool smokeSaveFeedback = false;
        bool smokeFeedbackRequireNote = false;
        bool smokeFeedbackRequireCompleteSession = false;
        bool smokeReducedMotion = false;
        bool smokeHighContrast = false;
        bool smokeExpectHighContrast = false;
        bool smokeLocalOnly = false;
        bool smokeLongDialogue = false;
        bool smokeExpectDialogueScrollable = false;
        bool smokeExpectAvatarNatural = false;
        bool smokeThinkingState = false;
        bool smokeExpectThinkingCopy = false;
        bool smokeExpectServerFallback = false;
        bool smokeStartFreshSession = false;
        bool smokeStartStoryMode = false;
        bool smokeExpectStoryMode = false;
        bool smokeExpectAudio = false;
        bool smokeExpectDialogueReadingFocus = false;
        bool smokeKeyArt = false;
        bool smokeSkipStart = false;
        bool smokeKeepStart = false;
        bool smokeLoadSave = false;
        bool smokeClearSave = false;
        bool smokeSeedSave = false;
        bool smokeClickContinueButton = false;
        bool smokeClickClosingSave = false;
        bool smokeClickClosingContinue = false;
        bool smokeClickClosingClose = false;
        bool smokeClickStoryNext = false;
        bool smokeClickStoryQuestion = false;
        bool smokeClickMemoryCard = false;
        int smokeMemoryCardIndex = 0;
        string smokeFeedbackOutput = null;
        string smokeStateOutput = null;
        string smokeClosingMessage = null;
        int? smokeDialogueSizeLevel = null;
        int? smokeSoundLevel = null;
        int smokeNoteTab = 0;
        List<string> smokeShortcutActions = new List<string>();
        List<KeyCode> smokeShortcutKeys = new List<KeyCode>();
        List<KeyCode> smokeDelayedKeys = new List<KeyCode>();
        List<string> smokeExpectedOpenPanels = new List<string>();
        List<string> smokeExpectedClosedPanels = new List<string>();
        List<string> smokeQuestions = new List<string>();

        for (int i = 0; i < args.Length; i++)
        {
            if (args[i] == "--smoke-long-dialogue")
            {
                smokeLongDialogue = true;
                PresentAssistant(
                    "긴 답변 테스트입니다. 이 문장은 화면을 뚫고 내려가지 않아야 합니다. 답변이 여러 문단으로 길어지면 하단 대사창에서 한 번에 다 밀어 넣지 않고, 클릭해서 다음 대사로 넘길 수 있어야 합니다.\n\n직장과 박사과정 이야기를 예로 들면, 책상과 노트북은 도움받는 사람으로만 보지 않게 해주는 장면입니다. 직장에서는 필요한 부분을 먼저 설명하고, 결과물로 기여를 확인하는 경험이 중요합니다. 박사과정 역시 공부와 일이 만나는 자리이며, 장애라는 표지보다 한 사람이 자기 몫을 이어가는 일상의 감각을 보여주는 장면입니다.\n\n이 마지막 문단까지 포함해도 대사창 바깥으로 흘러나가지 않고, 다음 표시를 눌러 순서대로 읽을 수 있는지 확인합니다.",
                    "긴 답변 테스트");
            }
            else if (args[i] == "--smoke-expect-dialogue-scrollable")
            {
                smokeExpectDialogueScrollable = true;
            }
            else if (args[i] == "--smoke-expect-avatar-natural")
            {
                smokeExpectAvatarNatural = true;
            }
            else if (args[i] == "--smoke-thinking-state")
            {
                smokeThinkingState = true;
            }
            else if (args[i] == "--smoke-expect-thinking-copy")
            {
                smokeExpectThinkingCopy = true;
            }
            else if (args[i] == "--smoke-expect-server-fallback")
            {
                smokeExpectServerFallback = true;
            }
            else if (args[i] == "--smoke-start-fresh")
            {
                smokeStartFreshSession = true;
            }
            else if (args[i] == "--smoke-start-story-mode")
            {
                smokeStartStoryMode = true;
            }
            else if (args[i] == "--smoke-first-impression" && i < args.Length - 1)
            {
                smokeFirstImpression = ReadSmokeTextArgument(args, i + 1);
            }
            else if (args[i] == "--smoke-category-flow" && i < args.Length - 1)
            {
                smokeCategoryFlow = ReadSmokeTextArgument(args, i + 1);
            }
            else if (args[i] == "--smoke-category-flow-continue")
            {
                smokeCategoryFlowContinue = true;
            }
            else if (args[i] == "--smoke-expect-story-mode")
            {
                smokeExpectStoryMode = true;
            }
            else if (args[i] == "--smoke-expect-audio")
            {
                smokeExpectAudio = true;
            }
            else if (args[i] == "--smoke-expect-dialogue-reading-focus")
            {
                smokeExpectDialogueReadingFocus = true;
            }
            else if (args[i] == "--smoke-open-note")
            {
                smokeOpenNote = true;
            }
            else if (args[i] == "--smoke-note-tab" && i < args.Length - 1)
            {
                string tab = args[i + 1];
                smokeOpenNote = true;
                smokeNoteTab = tab == "evidence" ? 1 : (tab == "history" ? 2 : 0);
            }
            else if (args[i] == "--smoke-focus-input")
            {
                SetDirectInputOpen(true, true);
            }
            else if (args[i] == "--smoke-open-closing")
            {
                smokeOpenClosing = true;
            }
            else if (args[i] == "--smoke-skip-closing-sensitive-question")
            {
                smokeSkipClosingSensitiveQuestion = true;
            }
            else if (args[i] == "--smoke-open-closing-after-questions")
            {
                smokeOpenClosingAfterQuestions = true;
            }
            else if (args[i] == "--smoke-save-ending-after-questions")
            {
                smokeOpenClosingAfterQuestions = true;
                smokeSaveEndingAfterQuestions = true;
            }
            else if (args[i] == "--smoke-open-pause")
            {
                smokeOpenPause = true;
            }
            else if (args[i] == "--smoke-open-settings")
            {
                smokeOpenSettings = true;
            }
            else if (args[i] == "--smoke-open-about")
            {
                smokeOpenAbout = true;
            }
            else if (args[i] == "--smoke-open-record-folder")
            {
                smokeOpenRecordFolder = true;
            }
            else if (args[i] == "--smoke-open-archive")
            {
                smokeOpenArchive = true;
            }
            else if (args[i] == "--smoke-open-feedback")
            {
                smokeOpenFeedback = true;
            }
            else if (args[i] == "--smoke-open-hotspot-preview")
            {
                smokeOpenHotspotPreview = true;
            }
            else if (args[i] == "--smoke-open-restart-confirm")
            {
                smokeOpenRestartConfirm = true;
            }
            else if (args[i] == "--smoke-open-memory")
            {
                smokeOpenMemory = true;
            }
            else if (args[i] == "--smoke-memory-filled")
            {
                smokeOpenMemory = true;
                smokeMemoryFilled = true;
            }
            else if (args[i] == "--smoke-fill-memory")
            {
                smokeFillMemory = true;
            }
            else if (args[i] == "--smoke-click-memory-card")
            {
                smokeOpenMemory = true;
                smokeClickMemoryCard = true;
                if (i < args.Length - 1 && int.TryParse(args[i + 1], out int parsedMemoryCardIndex))
                {
                    smokeMemoryCardIndex = Mathf.Max(0, parsedMemoryCardIndex);
                }
            }
            else if (args[i] == "--smoke-save-ending")
            {
                smokeSaveEnding = true;
            }
            else if (args[i] == "--smoke-delete-record-prompt")
            {
                smokeDeleteRecordPrompt = true;
            }
            else if (args[i] == "--smoke-delete-record-confirm")
            {
                smokeDeleteRecordConfirm = true;
            }
            else if (args[i] == "--smoke-expect-record-delete-prompt")
            {
                smokeExpectRecordDeletePrompt = true;
            }
            else if (args[i] == "--smoke-clear-data-prompt")
            {
                smokeClearDataPrompt = true;
            }
            else if (args[i] == "--smoke-expect-clear-data-prompt")
            {
                smokeExpectClearDataPrompt = true;
            }
            else if (args[i] == "--smoke-clear-data-confirm")
            {
                smokeClearDataConfirm = true;
            }
            else if (args[i] == "--smoke-click-clear-data-prompt")
            {
                smokeOpenAbout = true;
                smokeClickClearDataPrompt = true;
            }
            else if (args[i] == "--smoke-click-clear-data-confirm")
            {
                smokeOpenAbout = true;
                smokeClickClearDataConfirm = true;
            }
            else if (args[i] == "--smoke-save-feedback")
            {
                smokeOpenFeedback = true;
                smokeSaveFeedback = true;
            }
            else if (args[i] == "--smoke-feedback-require-note")
            {
                smokeOpenFeedback = true;
                smokeFeedbackRequireNote = true;
            }
            else if (args[i] == "--smoke-feedback-require-complete-session")
            {
                smokeOpenFeedback = true;
                smokeFeedbackRequireCompleteSession = true;
            }
            else if (args[i] == "--smoke-feedback-output" && i < args.Length - 1)
            {
                smokeFeedbackOutput = args[i + 1];
            }
            else if (args[i] == "--smoke-reduced-motion")
            {
                smokeReducedMotion = true;
            }
            else if (args[i] == "--smoke-high-contrast")
            {
                smokeHighContrast = true;
            }
            else if (args[i] == "--smoke-expect-high-contrast")
            {
                smokeExpectHighContrast = true;
            }
            else if (args[i] == "--smoke-local-only")
            {
                smokeLocalOnly = true;
            }
            else if (args[i] == "--smoke-key-art")
            {
                smokeKeyArt = true;
            }
            else if (args[i] == "--smoke-skip-start")
            {
                smokeSkipStart = true;
            }
            else if (args[i] == "--smoke-keep-start")
            {
                smokeKeepStart = true;
            }
            else if (args[i] == "--smoke-load-save")
            {
                smokeLoadSave = true;
            }
            else if (args[i] == "--smoke-clear-save")
            {
                smokeClearSave = true;
            }
            else if (args[i] == "--smoke-seed-save")
            {
                smokeSeedSave = true;
            }
            else if (args[i] == "--smoke-click-continue")
            {
                smokeClickContinueButton = true;
                smokeKeepStart = true;
            }
            else if (args[i] == "--smoke-click-closing-save")
            {
                smokeClickClosingSave = true;
                smokeOpenClosing = true;
            }
            else if (args[i] == "--smoke-click-closing-continue")
            {
                smokeClickClosingContinue = true;
                smokeOpenClosing = true;
            }
            else if (args[i] == "--smoke-click-closing-close")
            {
                smokeClickClosingClose = true;
                smokeOpenClosing = true;
            }
            else if ((args[i] == "--smoke-closing-message" || args[i] == "--smoke-ending-message") && i < args.Length - 1)
            {
                smokeClosingMessage = ReadSmokeTextArgument(args, i + 1);
            }
            else if (args[i] == "--smoke-show-memory-toast")
            {
                smokeMemoryToast = ReadSmokeTextArgument(args, i + 1);
            }
            else if (args[i] == "--smoke-show-completion-toast")
            {
                smokeCompletionToast = true;
            }
            else if (args[i] == "--smoke-click-story-next")
            {
                smokeClickStoryNext = true;
                smokeStartStoryMode = true;
            }
            else if (args[i] == "--smoke-click-story-question")
            {
                smokeClickStoryQuestion = true;
                smokeStartStoryMode = true;
            }
            else if (args[i] == "--smoke-submit-questions" && i < args.Length - 1)
            {
                AddSmokeQuestions(smokeQuestions, ReadSmokeTextArgument(args, i + 1));
            }
            else if (args[i] == "--smoke-shortcut-action" && i < args.Length - 1)
            {
                smokeShortcutActions.Add(args[i + 1]);
            }
            else if (args[i] == "--smoke-key" && i < args.Length - 1)
            {
                if (TryParseSmokeKey(args[i + 1], out KeyCode key))
                {
                    smokeShortcutKeys.Add(key);
                }
            }
            else if (args[i] == "--smoke-delayed-key" && i < args.Length - 1)
            {
                if (TryParseSmokeKey(args[i + 1], out KeyCode key))
                {
                    smokeDelayedKeys.Add(key);
                }
            }
            else if (args[i] == "--smoke-state-output" && i < args.Length - 1)
            {
                smokeStateOutput = args[i + 1];
            }
            else if (args[i] == "--smoke-expect-open" && i < args.Length - 1)
            {
                AddSmokePanelNames(smokeExpectedOpenPanels, args[i + 1]);
            }
            else if (args[i] == "--smoke-expect-closed" && i < args.Length - 1)
            {
                AddSmokePanelNames(smokeExpectedClosedPanels, args[i + 1]);
            }
        }

        if (smokeOpenNote)
        {
            SetQuestionNoteOpen(true);
            ShowNoteTab(smokeNoteTab);
        }

        if (smokeOpenClosing)
        {
            conversationTurns = Mathf.Max(conversationTurns, 5);
            if (smokeSkipClosingSensitiveQuestion)
            {
                closingSensitiveQuestionAnswered = true;
                pendingClosingSensitiveQuestion = false;
            }
            UpdateActionButtons();
            ShowClosingCard();
        }

        if (!string.IsNullOrWhiteSpace(smokeClosingMessage))
        {
            closingMessageToInterviewee = smokeClosingMessage.Trim();
            if (closingMessageInput != null)
            {
                closingMessageInput.text = closingMessageToInterviewee;
            }
            if (closingMessageValidationText != null)
            {
                closingMessageValidationText.text = "저장할 준비가 되었습니다.";
                closingMessageValidationText.color = new Color32(22, 101, 52, 245);
            }
        }

        if (smokeMemoryFilled || smokeFillMemory)
        {
            EnsureMemoryNotes();
            for (int i = 0; i < memoryThemes.Length; i++)
            {
                discoveredThemes.Add(memoryThemes[i]);
                memoryNotes[i] = BuildMemoryNote($"{memoryThemes[i]}에 대해 더 물어봤습니다.", string.Empty);
            }
            memoryCompletionCelebrated = true;
            UpdateMemoryBook();
            UpdateQuestionPhoneProgress();
            UpdateClosingSummary();
        }

        for (int i = 0; i < args.Length - 1; i++)
        {
            if (args[i] == "--smoke-submit-question")
            {
                smokeQuestion = ReadSmokeTextArgument(args, i + 1);
            }
            else if (args[i] == "--smoke-capture-delay" && float.TryParse(args[i + 1], out float parsedDelay))
            {
                captureDelay = Mathf.Max(0f, parsedDelay);
            }
            else if (args[i] == "--smoke-show-memory-toast")
            {
                smokeMemoryToast = args[i + 1];
            }
            else if (args[i] == "--smoke-dialogue-size")
            {
                string size = args[i + 1];
                smokeDialogueSizeLevel = size == "large" ? 1 : (size == "small" ? -1 : 0);
            }
            else if (args[i] == "--smoke-sound-level")
            {
                string level = args[i + 1];
                if (string.Equals(level, "off", StringComparison.OrdinalIgnoreCase) || level == "0")
                {
                    smokeSoundLevel = 0;
                }
                else if (string.Equals(level, "small", StringComparison.OrdinalIgnoreCase) || level == "1")
                {
                    smokeSoundLevel = 1;
                }
                else if (string.Equals(level, "default", StringComparison.OrdinalIgnoreCase) || level == "2")
                {
                    smokeSoundLevel = 2;
                }
            }
        }

        if (smokeClearSave)
        {
            ClearSavedSession();
        }

        if (smokeSeedSave)
        {
            SeedSmokeSavedSession();
        }

        if (smokeLoadSave && LoadSavedSession())
        {
            smokeSkipStart = true;
        }

        if (smokeDialogueSizeLevel.HasValue)
        {
            SetDialogueSizeLevel(smokeDialogueSizeLevel.Value, false);
        }

        if (smokeSoundLevel.HasValue)
        {
            SetSoundLevel(smokeSoundLevel.Value, false);
        }

        if (smokeReducedMotion)
        {
            SetReducedMotionEnabled(true, false);
        }

        if (smokeHighContrast)
        {
            SetHighContrastEnabled(true, false);
        }

        bool smokeAutomationActive = smokeSkipStart || smokeLongDialogue || smokeExpectDialogueScrollable || smokeExpectAvatarNatural || smokeThinkingState || smokeExpectThinkingCopy || smokeExpectServerFallback || smokeStartFreshSession || smokeStartStoryMode || smokeExpectStoryMode || smokeExpectAudio || smokeExpectDialogueReadingFocus || smokeKeyArt || smokeLocalOnly || smokeHighContrast || smokeOpenNote || smokeOpenClosing || smokeOpenPause || smokeOpenSettings || smokeOpenAbout || smokeOpenArchive || smokeOpenFeedback || smokeFeedbackRequireNote || smokeFeedbackRequireCompleteSession || smokeOpenHotspotPreview || smokeOpenRestartConfirm || smokeOpenMemory || smokeClickContinueButton || smokeClickClosingSave || smokeClickClosingContinue || smokeClickClosingClose || smokeClickStoryQuestion || smokeClickStoryNext || smokeClickMemoryCard || smokeDeleteRecordPrompt || smokeDeleteRecordConfirm || smokeClearDataPrompt || smokeClearDataConfirm || smokeClickClearDataPrompt || smokeClickClearDataConfirm || smokeShortcutActions.Count > 0 || smokeShortcutKeys.Count > 0 || smokeDelayedKeys.Count > 0 || smokeQuestions.Count > 0 || !string.IsNullOrWhiteSpace(smokeStateOutput) || !string.IsNullOrWhiteSpace(smokeQuestion) || !string.IsNullOrWhiteSpace(smokeClosingMessage) || !string.IsNullOrWhiteSpace(smokeMemoryToast) || !string.IsNullOrWhiteSpace(smokeFirstImpression) || !string.IsNullOrWhiteSpace(smokeCategoryFlow) || smokeCompletionToast || smokeSoundLevel.HasValue;
        if (smokeLocalOnly)
        {
            SetLocalAnswerOnlyEnabled(true, false);
        }
        else if (smokeAutomationActive)
        {
            SetLocalAnswerOnlyEnabled(false, false);
        }

        if (smokeAutomationActive && !smokeKeepStart)
        {
            if (startMenuObject != null) startMenuObject.SetActive(false);
        }

        if (smokeStartFreshSession)
        {
            StartFreshSession(true);
        }
        else if (smokeStartStoryMode)
        {
            StartFreshStoryMode();
        }

        if (!string.IsNullOrWhiteSpace(smokeFirstImpression))
        {
            SelectFirstImpression(smokeFirstImpression);
        }

        if (smokeClickContinueButton)
        {
            RunSmokeContinueButtonClick();
        }

        if (smokeClickStoryNext)
        {
            RunSmokeStoryNextButtonClick();
        }

        if (smokeClickStoryQuestion)
        {
            RunSmokeStoryQuestionButtonClick();
        }

        if (smokeOpenHotspotPreview)
        {
            OpenHotspotPreview("책상", "책상 앞에서 이어지는 하루는 어떤 모습인가요?");
        }

        if (!string.IsNullOrWhiteSpace(smokeQuestion))
        {
            StartCoroutine(SmokeSubmitQuestion(smokeQuestion));
        }
        else if (!string.IsNullOrWhiteSpace(smokeCategoryFlow))
        {
            StartCoroutine(SmokeSubmitCategoryFlow(smokeCategoryFlow, smokeCategoryFlowContinue));
        }
        else if (smokeQuestions.Count > 0)
        {
            StartCoroutine(SmokeSubmitQuestionSequence(smokeQuestions.ToArray(), smokeOpenClosingAfterQuestions, smokeSaveEndingAfterQuestions));
        }

        if (smokeThinkingState)
        {
            SetExpression(ExpressionState.Thinking);
            PresentAssistant(ThinkingReplyText, "생각 중");
            if (statusText != null) statusText.text = ThinkingReplyText;
        }

        if (!string.IsNullOrWhiteSpace(smokeMemoryToast))
        {
            StartCoroutine(SmokeShowMemoryToast(smokeMemoryToast));
        }

        if (smokeCompletionToast)
        {
            StartCoroutine(SmokeShowMemoryCompletionToast());
        }

        if (smokeOpenPause)
        {
            SetPauseMenuOpen(true);
        }

        if (smokeOpenSettings)
        {
            SetSettingsMenuOpen(true);
        }

        if (smokeOpenAbout)
        {
            SetAboutMenuOpen(true);
        }

        if (smokeClearDataPrompt || smokeClearDataConfirm)
        {
            if (aboutMenuObject != null && !aboutMenuObject.activeSelf)
            {
                SetAboutMenuOpen(true);
            }

            RequestClearLocalData();
            if (smokeClearDataConfirm)
            {
                RequestClearLocalData();
            }
        }

        if (smokeClickClearDataPrompt)
        {
            RunSmokeClearLocalDataButtonClick();
        }

        if (smokeClickClearDataConfirm)
        {
            RunSmokeClearLocalDataButtonClick();
            RunSmokeClearLocalDataButtonClick();
        }

        if (smokeOpenMemory)
        {
            SetMemoryBookOpen(true);
        }

        if (smokeClickMemoryCard)
        {
            SubmitMemoryCardQuestion(smokeMemoryCardIndex);
        }

        if (smokeOpenRecordFolder)
        {
            OpenEndingRecordFolder();
        }

        if (smokeSaveEnding)
        {
            SaveEndingRecord();
        }

        if (smokeClickClosingSave)
        {
            RunSmokeClosingSaveButtonClick();
        }

        if (smokeClickClosingContinue)
        {
            RunSmokeClosingContinueButtonClick();
        }

        if (smokeClickClosingClose)
        {
            RunSmokeClosingCloseButtonClick();
        }

        if (smokeOpenArchive)
        {
            SetRecordArchiveOpen(true);
        }

        if (smokeOpenFeedback)
        {
            SetPlaytestFeedbackOpen(true);
            if (playtestFeedbackInput != null)
            {
                bool defaultCaptureOnly = !smokeSaveFeedback && !smokeFeedbackRequireNote && !smokeFeedbackRequireCompleteSession;
                playtestFeedbackInput.text = smokeFeedbackRequireNote || defaultCaptureOnly
                    ? string.Empty
                    : "스모크 QA: 질문 흐름, 대화 기록, 저장을 확인했습니다. 진행을 막는 이슈는 없습니다.";
                playtestFeedbackInput.caretPosition = playtestFeedbackInput.text.Length;
                playtestFeedbackInput.selectionAnchorPosition = playtestFeedbackInput.text.Length;
                playtestFeedbackInput.selectionFocusPosition = playtestFeedbackInput.text.Length;
                if (defaultCaptureOnly)
                {
                    StartCoroutine(ClearPlaytestFeedbackSelectionNextFrame());
                }
            }
            SelectPlaytestRating(smokeFeedbackRequireNote ? 1 : 3);
            SelectPlaytestCommercialReadiness(smokeFeedbackRequireNote ? 1 : 3);
            SelectPlaytestIssueSeverity(smokeFeedbackRequireNote ? 2 : 0);
            if (smokeSaveFeedback || smokeFeedbackRequireNote || smokeFeedbackRequireCompleteSession)
            {
                if (string.IsNullOrWhiteSpace(smokeFeedbackOutput))
                {
                    SavePlaytestFeedback();
                }
                else
                {
                    SavePlaytestFeedbackToDirectory(smokeFeedbackOutput);
                }
            }
        }

        if (smokeDeleteRecordPrompt || smokeDeleteRecordConfirm)
        {
            if (recordArchiveObject != null && !recordArchiveObject.activeSelf)
            {
                SetRecordArchiveOpen(true);
            }

            RequestDeleteSelectedRecord();
            if (smokeDeleteRecordConfirm)
            {
                RequestDeleteSelectedRecord();
            }
        }

        if (smokeOpenRestartConfirm)
        {
            SetRestartConfirmOpen(true);
        }

        for (int i = 0; i < smokeShortcutActions.Count; i++)
        {
            RunShortcutAction(smokeShortcutActions[i]);
        }

        for (int i = 0; i < smokeShortcutKeys.Count; i++)
        {
            RunSmokeKeyPress(smokeShortcutKeys[i]);
        }

        for (int i = 0; i < smokeDelayedKeys.Count; i++)
        {
            StartCoroutine(RunSmokeKeyPressAfterDelay(smokeDelayedKeys[i], 0.15f));
        }

        if (smokeKeyArt)
        {
            SetMarketingKeyArtMode();
        }

        if (!string.IsNullOrWhiteSpace(smokeStateOutput))
        {
            StartCoroutine(WriteSmokeStateAndQuit(smokeStateOutput, captureDelay, smokeExpectedOpenPanels, smokeExpectedClosedPanels, smokeExpectDialogueScrollable, smokeExpectAvatarNatural, smokeExpectThinkingCopy, smokeExpectServerFallback, smokeExpectStoryMode, smokeExpectRecordDeletePrompt, smokeExpectClearDataPrompt, smokeExpectHighContrast, smokeExpectAudio, smokeExpectDialogueReadingFocus));
            return;
        }

        for (int i = 0; i < args.Length - 1; i++)
        {
            if (args[i] == "--smoke-capture")
            {
                StartCoroutine(CaptureAndQuit(args[i + 1], captureDelay));
                return;
            }
        }
    }

    private void RunSmokeKeyPress(KeyCode key)
    {
        smokeKeyDownOverride = key;
        try
        {
            HandleKeyboardShortcuts();
        }
        finally
        {
            smokeKeyDownOverride = null;
        }
    }

    private void RunSmokeStoryNextButtonClick()
    {
        if (storyNextButton == null || !storyNextButton.gameObject.activeSelf || !storyNextButton.interactable)
        {
            lastStoryModeShortcutAction = "next-button-unavailable";
            if (statusText != null) statusText.text = "다음 장면 버튼을 누를 수 없습니다";
            return;
        }

        storyNextButton.onClick.Invoke();
    }

    private void RunSmokeContinueButtonClick()
    {
        if (continueButton == null || !continueButton.gameObject.activeInHierarchy || !continueButton.interactable)
        {
            lastStartMenuAction = "continue-button-unavailable";
            if (statusText != null) statusText.text = "이어하기 버튼을 누를 수 없습니다";
            return;
        }

        continueButton.onClick.Invoke();
    }

    private void RunSmokeClosingSaveButtonClick()
    {
        if (closingCardSaveButton == null || !closingCardSaveButton.gameObject.activeInHierarchy || !closingCardSaveButton.interactable)
        {
            lastClosingCardShortcutAction = "save-button-unavailable";
            if (statusText != null) statusText.text = "기록함에 저장 버튼을 누를 수 없습니다";
            return;
        }

        closingCardSaveButton.onClick.Invoke();
    }

    private void RunSmokeClosingContinueButtonClick()
    {
        if (closingCardContinueButton == null || !closingCardContinueButton.gameObject.activeInHierarchy || !closingCardContinueButton.interactable)
        {
            lastClosingCardShortcutAction = "continue-button-unavailable";
            if (statusText != null) statusText.text = "질문 더 하기 버튼을 누를 수 없습니다";
            return;
        }

        closingCardContinueButton.onClick.Invoke();
    }

    private void RunSmokeClosingCloseButtonClick()
    {
        if (closingCardCloseButton == null || !closingCardCloseButton.gameObject.activeInHierarchy || !closingCardCloseButton.interactable)
        {
            lastClosingCardShortcutAction = "close-button-unavailable";
            if (statusText != null) statusText.text = "끝내기 버튼을 누를 수 없습니다";
            return;
        }

        lastClosingCardShortcutAction = "close-button";
        closingCardCloseButton.onClick.Invoke();
    }

    private void RunSmokeClearLocalDataButtonClick()
    {
        if (clearLocalDataButton == null || !clearLocalDataButton.gameObject.activeInHierarchy || !clearLocalDataButton.interactable)
        {
            lastClearLocalDataAction = "button-unavailable";
            if (statusText != null) statusText.text = "저장 삭제 버튼을 누를 수 없습니다";
            return;
        }

        clearLocalDataButton.onClick.Invoke();
    }

    private void RunSmokeStoryQuestionButtonClick()
    {
        if (storyQuestionButton == null || !storyQuestionButton.gameObject.activeSelf || !storyQuestionButton.interactable)
        {
            lastStoryModeShortcutAction = "question-button-unavailable";
            if (statusText != null) statusText.text = "직접 질문 버튼을 누를 수 없습니다";
            return;
        }

        storyQuestionButton.onClick.Invoke();
    }

    private IEnumerator RunSmokeKeyPressAfterDelay(KeyCode key, float delaySeconds)
    {
        yield return new WaitForSecondsRealtime(Mathf.Max(0f, delaySeconds));
        RunSmokeKeyPress(key);
    }

    private static bool TryParseSmokeKey(string value, out KeyCode key)
    {
        key = KeyCode.None;
        string normalized = (value ?? string.Empty).Trim();
        if (normalized.Length == 0) return false;

        switch (normalized)
        {
            case "+":
                normalized = "Plus";
                break;
            case "-":
                normalized = "Minus";
                break;
            case "Left":
                normalized = "LeftArrow";
                break;
            case "Right":
                normalized = "RightArrow";
                break;
            case "Up":
                normalized = "UpArrow";
                break;
            case "Down":
                normalized = "DownArrow";
                break;
        }

        try
        {
            key = (KeyCode)Enum.Parse(typeof(KeyCode), normalized, true);
            return true;
        }
        catch (ArgumentException)
        {
            return false;
        }
    }

    private static void AddSmokePanelNames(List<string> target, string value)
    {
        if (target == null || string.IsNullOrWhiteSpace(value)) return;
        string[] names = value.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries);
        for (int i = 0; i < names.Length; i++)
        {
            string name = names[i].Trim();
            if (name.Length > 0) target.Add(name);
        }
    }

    private static void AddSmokeQuestions(List<string> target, string value)
    {
        if (target == null || string.IsNullOrWhiteSpace(value)) return;
        string[] questions = value.Split(new[] { '|', '\n' }, StringSplitOptions.RemoveEmptyEntries);
        for (int i = 0; i < questions.Length; i++)
        {
            string question = questions[i].Trim();
            if (question.Length > 0) target.Add(question);
        }
    }

    private IEnumerator WriteSmokeStateAndQuit(string path, float delaySeconds, List<string> expectedOpenPanels, List<string> expectedClosedPanels, bool expectDialogueScrollable, bool expectAvatarNatural, bool expectThinkingCopy, bool expectServerFallback, bool expectStoryMode, bool expectRecordDeletePrompt, bool expectClearDataPrompt, bool expectHighContrast, bool expectAudio, bool expectDialogueReadingFocus)
    {
        yield return null;
        if (delaySeconds > 0f)
        {
            yield return new WaitForSeconds(delaySeconds);
        }

        bool passed = WriteSmokeStateReport(path, expectedOpenPanels, expectedClosedPanels, expectDialogueScrollable, expectAvatarNatural, expectThinkingCopy, expectServerFallback, expectStoryMode, expectRecordDeletePrompt, expectClearDataPrompt, expectHighContrast, expectAudio, expectDialogueReadingFocus);
        yield return null;
        Application.Quit(passed ? 0 : 31);
    }

    private bool WriteSmokeStateReport(string path, List<string> expectedOpenPanels, List<string> expectedClosedPanels, bool expectDialogueScrollable, bool expectAvatarNatural, bool expectThinkingCopy, bool expectServerFallback, bool expectStoryMode, bool expectRecordDeletePrompt, bool expectClearDataPrompt, bool expectHighContrast, bool expectAudio, bool expectDialogueReadingFocus)
    {
        bool passed = true;
        StringBuilder builder = new StringBuilder();
        builder.AppendLine("type\tname\texpected\tactual\tresult");

        AppendSmokePanelState(builder, "question");
        AppendSmokePanelState(builder, "memory");
        AppendSmokePanelState(builder, "records");
        AppendSmokePanelState(builder, "settings");
        AppendSmokePanelState(builder, "about");
        AppendSmokePanelState(builder, "pause");
        AppendSmokePanelState(builder, "closing");
        AppendSmokePanelState(builder, "feedback");
        AppendSmokePanelState(builder, "hotspot");
        AppendSmokePanelState(builder, "start");
        builder.Append("state\tmodal-blocker\t\t")
            .Append(HasModalShortcutBlocker() ? "open" : "closed")
            .AppendLine("\tINFO");
        builder.Append("state\tgame-title\t\t")
            .Append(EscapeSmokeCell(GameTitle))
            .AppendLine("\tINFO");
        builder.Append("state\tproduct-name\t\t")
            .Append(EscapeSmokeCell(Application.productName))
            .AppendLine("\tINFO");
        BuildInfoSummary buildInfo = TryReadBuildInfo();
        builder.Append("state\tbuild-id\t\t")
            .Append(EscapeSmokeCell(GetBuildIdForRecord(buildInfo)))
            .AppendLine("\tINFO");
        builder.Append("state\tapp-version\t\t")
            .Append(EscapeSmokeCell(GetBuildVersionForRecord(buildInfo)))
            .AppendLine("\tINFO");
        builder.Append("state\tui-font\t\t")
            .Append(EscapeSmokeCell(GetUiFontReport()))
            .AppendLine("\tINFO");
        builder.Append("state\tnote-tab\t\t")
            .Append(EscapeSmokeCell(GetSmokeNoteTabName()))
            .AppendLine("\tINFO");
        builder.Append("state\tnote-panel\t\t")
            .Append(questionNoteObject != null && questionNoteObject.activeInHierarchy ? "open" : "closed")
            .AppendLine("\tINFO");
        builder.Append("state\thistory-note-preview\t\t")
            .Append(EscapeSmokeCell(noteHistoryText != null ? ShortenForCard(noteHistoryText.text, 220) : string.Empty))
            .AppendLine("\tINFO");
        builder.Append("state\tdialogue-size-level\t\t")
            .Append(dialogueSizeLevel)
            .AppendLine("\tINFO");
        builder.Append("state\tselected-lead-index\t\t")
            .Append(selectedLeadIndex.ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\tselected-lead-title\t\t")
            .Append(EscapeSmokeCell(GetSelectedLeadTitle()))
            .AppendLine("\tINFO");
        builder.Append("state\tselected-lead-label\t\t")
            .Append(EscapeSmokeCell(GetSelectedLeadLabel()))
            .AppendLine("\tINFO");
        builder.Append("state\tlead-slips-visible-count\t\t")
            .Append(CountActiveLeadSlips().ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\thotspot-labels-visible-count\t\t")
            .Append(CountActiveHotspotLabels().ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\thotspots-visible-count\t\t")
            .Append(CountActiveHotspots().ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        AppendSmokeConversationState(builder);
        passed &= AppendSmokeLeadSlipLayout(builder);
        passed &= AppendSmokeStartUtilityState(builder);
        passed &= AppendSmokeAboutServerStatus(builder);
        passed &= AppendSmokeDialogueLayout(builder, expectDialogueScrollable);
        passed &= AppendSmokeAvatarLayout(builder, expectAvatarNatural);
        passed &= AppendSmokeThinkingCopy(builder, expectThinkingCopy);
        passed &= AppendSmokeServerFallback(builder, expectServerFallback);
        passed &= AppendSmokeStoryMode(builder, expectStoryMode);
        passed &= AppendSmokeRecordDeletePrompt(builder, expectRecordDeletePrompt);
        passed &= AppendSmokeClearDataPrompt(builder, expectClearDataPrompt);
        passed &= AppendSmokeAccessibilitySettings(builder, expectHighContrast);
        passed &= AppendSmokeAudioState(builder, expectAudio);
        passed &= AppendSmokeDialogueReadingFocus(builder, expectDialogueReadingFocus);

        passed &= AppendSmokeExpectations(builder, expectedOpenPanels, true);
        passed &= AppendSmokeExpectations(builder, expectedClosedPanels, false);

        string directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        File.WriteAllText(path, builder.ToString(), Encoding.UTF8);
        return passed;
    }

    private int CountActiveLeadSlips()
    {
        int count = 0;
        if (leadButtons == null) return count;

        for (int i = 0; i < leadButtons.Length; i++)
        {
            if (leadButtons[i] != null && leadButtons[i].gameObject.activeInHierarchy)
            {
                count++;
            }
        }

        return count;
    }

    private int CountActiveHotspotLabels()
    {
        int count = 0;
        for (int i = 0; i < hotspotLabelObjects.Count; i++)
        {
            if (hotspotLabelObjects[i] != null && hotspotLabelObjects[i].activeInHierarchy)
            {
                count++;
            }
        }

        return count;
    }

    private int CountActiveHotspots()
    {
        int count = 0;
        for (int i = 0; i < hotspotRootObjects.Count; i++)
        {
            if (hotspotRootObjects[i] != null && hotspotRootObjects[i].activeInHierarchy)
            {
                count++;
            }
        }

        return count;
    }

    private float GetMaxActiveLeadSlipY()
    {
        float max = float.MinValue;
        if (leadRects == null) return 0f;

        for (int i = 0; i < leadRects.Length; i++)
        {
            if (leadRects[i] != null && leadRects[i].gameObject.activeInHierarchy)
            {
                max = Mathf.Max(max, leadRects[i].anchoredPosition.y);
            }
        }

        return max == float.MinValue ? 0f : max;
    }

    private bool AppendSmokeLeadSlipLayout(StringBuilder builder)
    {
        string overlap = FindLeadSlipOverlap();
        bool pass = overlap == "none";
        builder.Append("layout\tlead-slip-overlap\t\t")
            .Append(EscapeSmokeCell(overlap))
            .AppendLine(pass ? "\tPASS" : "\tFAIL");
        return pass;
    }

    private string FindLeadSlipOverlap()
    {
        if (leadRects == null || leadRects.Length < 2) return "none";

        for (int i = 0; i < leadRects.Length; i++)
        {
            RectTransform a = leadRects[i];
            if (a == null || !a.gameObject.activeInHierarchy) continue;
            Rect aRect = GetAnchoredRect(a, 4f);

            for (int j = i + 1; j < leadRects.Length; j++)
            {
                RectTransform b = leadRects[j];
                if (b == null || !b.gameObject.activeInHierarchy) continue;
                if (aRect.Overlaps(GetAnchoredRect(b, 4f)))
                {
                    return $"{i + 1}-{j + 1}";
                }
            }
        }

        return "none";
    }

    private static Rect GetAnchoredRect(RectTransform rectTransform, float padding)
    {
        Rect rect = rectTransform.rect;
        Vector2 position = rectTransform.anchoredPosition;
        Vector2 pivot = rectTransform.pivot;
        float x = position.x - pivot.x * rect.width - padding;
        float y = position.y - pivot.y * rect.height - padding;
        return new Rect(x, y, rect.width + padding * 2f, rect.height + padding * 2f);
    }

    private bool AppendSmokeDialogueReadingFocus(StringBuilder builder, bool expectFocus)
    {
        bool focusActive = IsDialogueReadingFocusActive();
        int hotspotCount = CountActiveHotspots();
        int labelCount = CountActiveHotspotLabels();
        int leadCount = CountActiveLeadSlips();
        float maxLeadY = GetMaxActiveLeadSlipY();

        builder.Append("state\tdialogue-reading-focus\t\t")
            .Append(focusActive ? "active" : "inactive")
            .AppendLine("\tINFO");
        builder.Append("state\tdialogue-reading-followup-max-y\t\t")
            .Append(FormatSmokeNumber(maxLeadY))
            .AppendLine("\tINFO");

        if (!expectFocus)
        {
            return true;
        }

        bool focusPass = focusActive;
        bool hotspotsPass = hotspotCount == 0;
        bool labelsPass = labelCount == 0;
        bool leadsPass = leadCount > 0;
        bool dockPass = maxLeadY <= 372f;

        builder.Append("expect\tdialogue-reading-focus\tactive\t")
            .Append(focusActive ? "active" : "inactive")
            .Append("\t")
            .AppendLine(focusPass ? "PASS" : "FAIL");
        builder.Append("expect\tdialogue-reading-hotspots\t0\t")
            .Append(hotspotCount.ToString(CultureInfo.InvariantCulture))
            .Append("\t")
            .AppendLine(hotspotsPass ? "PASS" : "FAIL");
        builder.Append("expect\tdialogue-reading-hotspot-labels\t0\t")
            .Append(labelCount.ToString(CultureInfo.InvariantCulture))
            .Append("\t")
            .AppendLine(labelsPass ? "PASS" : "FAIL");
        builder.Append("expect\tdialogue-reading-followups\tvisible\t")
            .Append(leadCount.ToString(CultureInfo.InvariantCulture))
            .Append("\t")
            .AppendLine(leadsPass ? "PASS" : "FAIL");
        builder.Append("expect\tdialogue-reading-followup-dock\t<=372\t")
            .Append(FormatSmokeNumber(maxLeadY))
            .Append("\t")
            .AppendLine(dockPass ? "PASS" : "FAIL");

        return focusPass && hotspotsPass && labelsPass && leadsPass && dockPass;
    }

    private bool AppendSmokeStoryMode(StringBuilder builder, bool expectActive)
    {
        string speaker = speakerText != null ? speakerText.text : string.Empty;
        string dialogue = dialogueText != null ? dialogueText.text : string.Empty;
        string status = statusText != null ? statusText.text : string.Empty;

        builder.Append("story\tactive\t\t")
            .Append(storyModeActive ? "active" : "inactive")
            .AppendLine("\tINFO");
        builder.Append("story\tindex\t\t")
            .Append(storyModeIndex.ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\tstory-index\t\t")
            .Append(storyModeIndex.ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\tstory-shortcut-action\t\t")
            .Append(EscapeSmokeCell(lastStoryModeShortcutAction))
            .AppendLine("\tINFO");
        builder.Append("story\tspeaker\t\t")
            .Append(EscapeSmokeCell(speaker))
            .AppendLine("\tINFO");
        builder.Append("story\tdialogue\t\t")
            .Append(EscapeSmokeCell(ShortenForCard(dialogue, 80)))
            .AppendLine("\tINFO");
        builder.Append("story\tstatus\t\t")
            .Append(EscapeSmokeCell(status))
            .AppendLine("\tINFO");
        builder.Append("story\tbeat\t\t")
            .Append(EscapeSmokeCell(currentStoryModeBeatLine))
            .AppendLine("\tINFO");
        builder.Append("story\tpace\t\t")
            .Append(EscapeSmokeCell(currentStoryModePaceLine))
            .AppendLine("\tINFO");
        builder.Append("state\tstory-pace-line\t\t")
            .Append(EscapeSmokeCell(currentStoryModePaceLine))
            .AppendLine("\tINFO");
        builder.Append("story\tnext-label\t\t")
            .Append(EscapeSmokeCell(GetSmokeButtonLabel(storyNextButton)))
            .AppendLine("\tINFO");
        builder.Append("story\tquestion-label\t\t")
            .Append(EscapeSmokeCell(GetSmokeButtonLabel(storyQuestionButton)))
            .AppendLine("\tINFO");
        builder.Append("story\tfinish-label\t\t")
            .Append(EscapeSmokeCell(GetSmokeButtonLabel(storyFinishButton)))
            .AppendLine("\tINFO");
        builder.Append("story\tcontrols-visible\t\t")
            .Append(AreStoryModeControlsVisible() ? "visible" : "hidden")
            .AppendLine("\tINFO");
        builder.Append("story\tfinish-control\t\t")
            .Append(storyFinishButton != null && storyFinishButton.interactable ? "enabled" : "disabled")
            .AppendLine("\tINFO");
        float quietSeconds = 0f;
        for (int i = 0; i < Mathf.Max(0, storyModeLines.Length - 1); i++)
        {
            quietSeconds += GetStoryModeQuietSeconds(i);
        }
        float estimatedSeconds = storyModeLines.Length * StoryModeLineDelaySeconds
            + quietSeconds
            + 1.6f;
        builder.Append("story\testimated-seconds\t\t")
            .Append(estimatedSeconds.ToString("0.0", CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");

        if (!expectActive)
        {
            return true;
        }

        bool activePass = storyModeActive;
        bool speakerPass = speaker.Contains("이야기");
        bool dialoguePass = !string.IsNullOrWhiteSpace(dialogue) && dialogue.Contains("목발");
        bool beatPass = currentStoryModeBeatLine.Contains("겉:") && currentStoryModeBeatLine.Contains("속:");
        bool pacePass = currentStoryModePaceLine.Contains("연출:") && currentStoryModePaceLine.Contains("짧은 정적") && currentStoryModePaceLine.Contains("시선");
        bool turnsPass = openingStoryModeActive || conversationTurns > 0;
        string expectedQuestionLabel = openingStoryModeActive ? string.Empty : "직접 질문";
        string expectedFinishLabel = openingStoryModeActive ? string.Empty : $"{RequiredQuestionCount}문답 후";
        bool questionControlPass = openingStoryModeActive
            ? storyQuestionButton != null && !storyQuestionButton.gameObject.activeSelf
            : storyQuestionButton != null && storyQuestionButton.interactable && string.Equals(GetSmokeButtonLabel(storyQuestionButton), expectedQuestionLabel, StringComparison.Ordinal);
        bool controlPass = AreStoryModeControlsVisible()
            && string.Equals(GetSmokeButtonLabel(storyNextButton), GetStoryModeNextButtonLabel(), StringComparison.Ordinal)
            && questionControlPass
            && (openingStoryModeActive || string.Equals(GetSmokeButtonLabel(storyFinishButton), expectedFinishLabel, StringComparison.Ordinal))
            && storyNextButton != null && storyNextButton.interactable
            && storyFinishButton != null && !storyFinishButton.interactable;

        builder.Append("expect\tstory-active\tactive\t")
            .Append(storyModeActive ? "active" : "inactive")
            .Append("\t")
            .AppendLine(activePass ? "PASS" : "FAIL");
        builder.Append("expect\tstory-speaker\t이야기\t")
            .Append(EscapeSmokeCell(speaker))
            .Append("\t")
            .AppendLine(speakerPass ? "PASS" : "FAIL");
        builder.Append("expect\tstory-dialogue\t첫 이야기\t")
            .Append(dialoguePass ? "present" : "missing")
            .Append("\t")
            .AppendLine(dialoguePass ? "PASS" : "FAIL");
        builder.Append("expect\tstory-beat\t겉/속 장면 비트\t")
            .Append(beatPass ? "present" : "missing")
            .Append("\t")
            .AppendLine(beatPass ? "PASS" : "FAIL");
        builder.Append("expect\tstory-pace\t정적/소리/시선 연출\t")
            .Append(pacePass ? "present" : "missing")
            .Append("\t")
            .AppendLine(pacePass ? "PASS" : "FAIL");
        builder.Append("expect\tstory-turns\t>0\t")
            .Append(conversationTurns.ToString(CultureInfo.InvariantCulture))
            .Append("\t")
            .AppendLine(turnsPass ? "PASS" : "FAIL");
        builder.Append("expect\tstory-controls\t다음 장면/직접 질문/").Append(RequiredQuestionCount.ToString(CultureInfo.InvariantCulture)).Append("문답 후\t")
            .Append(controlPass ? "visible" : "missing")
            .Append("\t")
            .AppendLine(controlPass ? "PASS" : "FAIL");

        return activePass && speakerPass && dialoguePass && beatPass && pacePass && turnsPass && controlPass;
    }

    private bool AppendSmokeRecordDeletePrompt(StringBuilder builder, bool expectPrompt)
    {
        string selectedPath = GetSelectedRecordPath();
        bool hasSelection = !string.IsNullOrWhiteSpace(selectedPath);
        bool awaitingConfirm = hasSelection
            && string.Equals(pendingDeleteRecordPath, selectedPath, StringComparison.OrdinalIgnoreCase)
            && Time.realtimeSinceStartup <= pendingDeleteRecordUntil;
        string label = string.Empty;
        if (recordArchiveDeleteButton != null)
        {
            Text text = recordArchiveDeleteButton.GetComponentInChildren<Text>();
            label = text != null ? text.text : string.Empty;
        }
        string hint = recordArchiveDeleteHintText != null ? recordArchiveDeleteHintText.text : string.Empty;
        string cancelLabel = string.Empty;
        bool cancelVisible = recordArchiveCancelDeleteButton != null && recordArchiveCancelDeleteButton.gameObject.activeSelf;
        if (recordArchiveCancelDeleteButton != null)
        {
            Text text = recordArchiveCancelDeleteButton.GetComponentInChildren<Text>();
            cancelLabel = text != null ? text.text : string.Empty;
        }
        bool labelPass = !expectPrompt || string.Equals(label, "삭제 확정", StringComparison.Ordinal);
        bool hintPass = !expectPrompt || hint.Contains("완전히 지워집니다");
        bool cancelPass = !expectPrompt || (cancelVisible && string.Equals(cancelLabel, "취소", StringComparison.Ordinal));
        bool promptPass = !expectPrompt || awaitingConfirm;

        builder.Append("state\trecord-delete-selection\t\t")
            .Append(hasSelection ? "selected" : "none")
            .AppendLine("\tINFO");
        builder.Append("state\trecord-delete-pending\t\t")
            .Append(awaitingConfirm ? "pending" : "idle")
            .AppendLine(expectPrompt ? (promptPass ? "\tPASS" : "\tFAIL") : "\tINFO");
        builder.Append("state\trecord-delete-label\t삭제 확정\t")
            .Append(EscapeSmokeCell(label))
            .AppendLine(expectPrompt ? (labelPass ? "\tPASS" : "\tFAIL") : "\tINFO");
        builder.Append("state\trecord-delete-hint\t완전히 지워집니다\t")
            .Append(EscapeSmokeCell(hint))
            .AppendLine(expectPrompt ? (hintPass ? "\tPASS" : "\tFAIL") : "\tINFO");
        builder.Append("state\trecord-delete-cancel\t취소\t")
            .Append(EscapeSmokeCell(cancelVisible ? cancelLabel : "hidden"))
            .AppendLine(expectPrompt ? (cancelPass ? "\tPASS" : "\tFAIL") : "\tINFO");

        return promptPass && labelPass && hintPass && cancelPass;
    }

    private bool AppendSmokeClearDataPrompt(StringBuilder builder, bool expectPrompt)
    {
        bool awaitingConfirm = pendingClearLocalDataUntil > 0f
            && Time.realtimeSinceStartup <= pendingClearLocalDataUntil;
        string label = string.Empty;
        if (clearLocalDataButton != null)
        {
            Text text = clearLocalDataButton.GetComponentInChildren<Text>();
            label = text != null ? text.text : string.Empty;
        }

        string hint = clearLocalDataHintText != null ? clearLocalDataHintText.text : string.Empty;
        bool labelPass = !expectPrompt || string.Equals(label, "삭제 확정", StringComparison.Ordinal);
        bool hintPass = !expectPrompt || hint.Contains("완전히 지워집니다");
        bool promptPass = !expectPrompt || awaitingConfirm;

        builder.Append("state\tclear-data-action\t\t")
            .Append(EscapeSmokeCell(lastClearLocalDataAction))
            .AppendLine("\tINFO");
        builder.Append("state\tclear-data-pending\t\t")
            .Append(awaitingConfirm ? "pending" : "idle")
            .AppendLine(expectPrompt ? (promptPass ? "\tPASS" : "\tFAIL") : "\tINFO");
        builder.Append("state\tclear-data-label\t삭제 확정\t")
            .Append(EscapeSmokeCell(label))
            .AppendLine(expectPrompt ? (labelPass ? "\tPASS" : "\tFAIL") : "\tINFO");
        builder.Append("state\tclear-data-hint\t완전히 지워집니다\t")
            .Append(EscapeSmokeCell(hint))
            .AppendLine(expectPrompt ? (hintPass ? "\tPASS" : "\tFAIL") : "\tINFO");

        return promptPass && labelPass && hintPass;
    }

    private bool AppendSmokeAccessibilitySettings(StringBuilder builder, bool expectHighContrast)
    {
        bool highContrastPass = !expectHighContrast || highContrastEnabled;
        string highContrastLabel = string.Empty;
        string reducedMotionLabel = string.Empty;
        string soundLabel = string.Empty;
        string localAnswerLabel = string.Empty;
        if (highContrastButton != null)
        {
            Text text = highContrastButton.GetComponentInChildren<Text>();
            highContrastLabel = text != null ? text.text : string.Empty;
        }
        if (reducedMotionButton != null)
        {
            Text text = reducedMotionButton.GetComponentInChildren<Text>();
            reducedMotionLabel = text != null ? text.text : string.Empty;
        }
        if (soundButton != null)
        {
            Text text = soundButton.GetComponentInChildren<Text>();
            soundLabel = text != null ? text.text : string.Empty;
        }
        if (localAnswerOnlyButton != null)
        {
            Text text = localAnswerOnlyButton.GetComponentInChildren<Text>();
            localAnswerLabel = text != null ? text.text : string.Empty;
        }

        builder.Append("state\treduced-motion\t\t")
            .Append(reducedMotionEnabled ? "on" : "off")
            .AppendLine("\tINFO");
        builder.Append("state\treduced-motion-label\t\t")
            .Append(EscapeSmokeCell(reducedMotionLabel))
            .AppendLine("\tINFO");
        builder.Append("state\thigh-contrast\t")
            .Append(expectHighContrast ? "on" : string.Empty)
            .Append("\t")
            .Append(highContrastEnabled ? "on" : "off")
            .AppendLine(expectHighContrast ? (highContrastPass ? "\tPASS" : "\tFAIL") : "\tINFO");
        builder.Append("state\thigh-contrast-label\t\t")
            .Append(EscapeSmokeCell(highContrastLabel))
            .AppendLine("\tINFO");
        builder.Append("state\tsound-label\t\t")
            .Append(EscapeSmokeCell(soundLabel))
            .AppendLine("\tINFO");
        builder.Append("state\tlocal-answer-label\t\t")
            .Append(EscapeSmokeCell(localAnswerLabel))
            .AppendLine("\tINFO");

        return highContrastPass;
    }

    private bool AppendSmokeAudioState(StringBuilder builder, bool expectAudio)
    {
        string soundLabel = string.Empty;
        if (soundButton != null)
        {
            Text text = soundButton.GetComponentInChildren<Text>();
            soundLabel = text != null ? text.text : string.Empty;
        }

        float expectedSfxVolume = soundLevel == 0 ? 0f : (soundLevel == 1 ? 0.42f : 0.72f);
        float expectedAmbienceVolume = expectedSfxVolume * 0.14f;
        float actualSfxVolume = sfxSource != null ? sfxSource.volume : -1f;
        float actualAmbienceVolume = ambienceSource != null ? ambienceSource.volume : -1f;
        bool ambiencePlaying = ambienceSource != null && ambienceSource.isPlaying;
        bool clipsReady =
            buttonClickClip != null &&
            pageTurnClip != null &&
            questionSelectClip != null &&
            answerReadyClip != null &&
            memoryUnlockClip != null &&
            confirmClip != null &&
            resultCardClip != null &&
            categoryTransitionClip != null &&
            errorClip != null &&
            recordingStartClip != null &&
            recordingStopClip != null &&
            roomToneClip != null;
        bool labelPass = GetSoundLevelLabel().Equals(soundLabel, StringComparison.Ordinal);
        bool sfxPass = Mathf.Abs(actualSfxVolume - expectedSfxVolume) <= 0.015f;
        bool ambienceVolumePass = Mathf.Abs(actualAmbienceVolume - expectedAmbienceVolume) <= 0.015f;
        bool ambienceStatePass = soundLevel == 0 ? !ambiencePlaying : ambiencePlaying;
        bool pass = !expectAudio || (clipsReady && labelPass && sfxPass && ambienceVolumePass && ambienceStatePass);

        builder.Append("state\tsound-level\t\t")
            .Append(soundLevel.ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\tsound-level-label\t\t")
            .Append(EscapeSmokeCell(GetSoundLevelLabel()))
            .AppendLine("\tINFO");
        builder.Append("state\tsound-button-label\t\t")
            .Append(EscapeSmokeCell(soundLabel))
            .AppendLine("\tINFO");
        builder.Append("state\tsfx-volume\t\t")
            .Append(FormatSmokeNumber(actualSfxVolume))
            .AppendLine("\tINFO");
        builder.Append("state\tambience-volume\t\t")
            .Append(FormatSmokeNumber(actualAmbienceVolume))
            .AppendLine("\tINFO");
        builder.Append("state\tambience-playing\t\t")
            .Append(ambiencePlaying ? "playing" : "stopped")
            .AppendLine("\tINFO");
        builder.Append("state\taudio-clips\t\t")
            .Append(clipsReady ? "ready" : "missing")
            .AppendLine("\tINFO");

        if (expectAudio)
        {
            builder.Append("expect\taudio-settings\tconsistent\t")
                .Append(pass ? "consistent" : "mismatch")
                .Append("\t")
                .AppendLine(pass ? "PASS" : "FAIL");
        }

        return pass;
    }

    private string GetSoundLevelLabel()
    {
        if (soundLevel <= 0) return "소리 끔";
        return soundLevel == 1 ? "소리 작게" : "소리 기본";
    }

    private static string GetSmokeButtonLabel(Button button)
    {
        if (button == null) return string.Empty;
        Text label = button.GetComponentInChildren<Text>();
        return label != null ? label.text : string.Empty;
    }

    private bool AreStoryModeControlsVisible()
    {
        bool nextVisible = storyNextButton != null && storyNextButton.gameObject.activeSelf;
        if (openingStoryModeActive)
        {
            return nextVisible
                && storyQuestionButton != null && !storyQuestionButton.gameObject.activeSelf
                && storyFinishButton != null && !storyFinishButton.gameObject.activeSelf;
        }

        bool baseControls = nextVisible && storyQuestionButton != null && storyQuestionButton.gameObject.activeSelf;
        return baseControls && storyFinishButton != null && storyFinishButton.gameObject.activeSelf;
    }

    private string GetRecordArchiveSlotLabel(int index)
    {
        if (recordArchiveButtons == null || index < 0 || index >= recordArchiveButtons.Length) return string.Empty;
        Button button = recordArchiveButtons[index];
        if (button == null || !button.gameObject.activeSelf) return string.Empty;
        return GetSmokeButtonLabel(button);
    }

    private string GetMemoryCardLabel(int index)
    {
        if (memoryCardTexts == null || index < 0 || index >= memoryCardTexts.Length) return string.Empty;
        Text label = memoryCardTexts[index];
        return label != null ? label.text : string.Empty;
    }

    private int CountMemoryCardButtons()
    {
        int count = 0;
        if (memoryCardButtons == null) return count;
        for (int i = 0; i < memoryCardButtons.Length; i++)
        {
            if (memoryCardButtons[i] != null)
            {
                count++;
            }
        }

        return count;
    }

    private string GetClosingChoiceLabel(int index)
    {
        if (closingChoiceLabels == null || index < 0 || index >= closingChoiceLabels.Length) return string.Empty;
        return closingChoiceLabels[index];
    }

    private void AppendSmokeConversationState(StringBuilder builder)
    {
        builder.Append("state\texpression\t\t")
            .Append(currentExpression.ToString())
            .AppendLine("\tINFO");
        builder.Append("state\tconversation-turns\t\t")
            .Append(conversationTurns.ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\tfinish-button\t\t")
            .Append(finishButton != null && finishButton.interactable ? "enabled" : "disabled")
            .AppendLine("\tINFO");
        builder.Append("state\tfinish-button-label\t\t")
            .Append(EscapeSmokeCell(GetSmokeButtonLabel(finishButton)))
            .AppendLine("\tINFO");
        builder.Append("state\tclosing-button-label\t\t")
            .Append(EscapeSmokeCell(GetSmokeButtonLabel(closingButton)))
            .AppendLine("\tINFO");
        builder.Append("state\tclosing-save-button-label\t\t")
            .Append(EscapeSmokeCell(GetSmokeButtonLabel(closingCardSaveButton)))
            .AppendLine("\tINFO");
        builder.Append("state\tclosing-continue-button-label\t\t")
            .Append(EscapeSmokeCell(GetSmokeButtonLabel(closingCardContinueButton)))
            .AppendLine("\tINFO");
        builder.Append("state\tselected-closing-index\t\t")
            .Append(selectedClosingIndex.ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\tselected-closing-label\t\t")
            .Append(EscapeSmokeCell(GetClosingChoiceLabel(selectedClosingIndex)))
            .AppendLine("\tINFO");
        builder.Append("state\tclosing-recommendation-line\t\t")
            .Append(EscapeSmokeCell(BuildClosingSelectionLine(selectedClosingIndex)))
            .AppendLine("\tINFO");
        builder.Append("state\tsession-completion-line\t\t")
            .Append(EscapeSmokeCell(BuildSessionCompletionLine()))
            .AppendLine("\tINFO");
        builder.Append("state\tclosing-shortcut-action\t\t")
            .Append(EscapeSmokeCell(lastClosingCardShortcutAction))
            .AppendLine("\tINFO");
        builder.Append("state\tfirst-impression\t\t")
            .Append(EscapeSmokeCell(BuildFirstImpressionLabel()))
            .AppendLine("\tINFO");
        builder.Append("state\tfirst-impression-display\t\t")
            .Append(EscapeSmokeCell(BuildFirstImpressionDisplayLabel()))
            .AppendLine("\tINFO");
        builder.Append("state\tfirst-impression-option-map\t\t")
            .Append(EscapeSmokeCell(BuildFirstImpressionOptionMapLine()))
            .AppendLine("\tINFO");
        builder.Append("state\tfirst-impression-option-1-label\t\t")
            .Append(EscapeSmokeCell(GetFirstImpressionButtonLabel(0)))
            .AppendLine("\tINFO");
        builder.Append("state\tfirst-impression-option-2-label\t\t")
            .Append(EscapeSmokeCell(GetFirstImpressionButtonLabel(1)))
            .AppendLine("\tINFO");
        builder.Append("state\tlast-attitude\t\t")
            .Append(EscapeSmokeCell(string.IsNullOrWhiteSpace(lastQuestionAttitude) ? "없음" : lastQuestionAttitude))
            .AppendLine("\tINFO");
        builder.Append("state\tdominant-attitude\t\t")
            .Append(EscapeSmokeCell(GetDominantAttitude()))
            .AppendLine("\tINFO");
        builder.Append("state\tdeep-memory-count\t\t")
            .Append(CountDeepMemories().ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\tanswer-source\t\t")
            .Append(EscapeSmokeCell(lastAnswerSource))
            .AppendLine("\tINFO");
        builder.Append("state\tprogress-label\t\t")
            .Append(EscapeSmokeCell(progressText != null ? progressText.text : string.Empty))
            .AppendLine("\tINFO");
        builder.Append("state\tquestion-guide\t\t")
            .Append(EscapeSmokeCell(questionPhoneGuideText != null ? questionPhoneGuideText.text : string.Empty))
            .AppendLine("\tINFO");
        builder.Append("state\tquestion-session-quality-line\t\t")
            .Append(EscapeSmokeCell(BuildQuestionSessionQualityLine(CountDeepMemories(), memoryThemes != null ? memoryThemes.Length : 0)))
            .AppendLine("\tINFO");
        builder.Append("state\tquestion-chapter-state-line\t\t")
            .Append(EscapeSmokeCell(BuildChapterStateSummaryLine()))
            .AppendLine("\tINFO");
        builder.Append("state\tquestion-chapter-1-label\t\t")
            .Append(EscapeSmokeCell(GetChapterButtonLabel(0)))
            .AppendLine("\tINFO");
        builder.Append("state\tquestion-chapter-3-label\t\t")
            .Append(EscapeSmokeCell(GetChapterButtonLabel(2)))
            .AppendLine("\tINFO");
        builder.Append("state\tchoice-consequence-line\t\t")
            .Append(EscapeSmokeCell(lastChoiceConsequenceLine))
            .AppendLine("\tINFO");
        builder.Append("state\treward-line\t\t")
            .Append(EscapeSmokeCell(lastRewardLine))
            .AppendLine("\tINFO");
        builder.Append("state\treward-toast-visible\t\t")
            .Append(memoryUnlockToastObject != null && memoryUnlockToastObject.activeInHierarchy ? "visible" : "hidden")
            .AppendLine("\tINFO");
        builder.Append("state\treward-toast-text\t\t")
            .Append(EscapeSmokeCell(memoryUnlockToastText != null ? memoryUnlockToastText.text : string.Empty))
            .AppendLine("\tINFO");
        builder.Append("state\tnext-session-prompt-line\t\t")
            .Append(EscapeSmokeCell(BuildNextSessionPromptLine()))
            .AppendLine("\tINFO");
        builder.Append("state\tfirst-impression-target\t\t")
            .Append(EscapeSmokeCell(BuildFirstImpressionTargetLine()))
            .AppendLine("\tINFO");
        builder.Append("state\tfirst-impression-arc\t\t")
            .Append(EscapeSmokeCell(BuildFirstImpressionArcLine()))
            .AppendLine("\tINFO");
        builder.Append("state\tfirst-impression-theme-opened\t\t")
            .Append(IsFirstImpressionThemeOpened() ? "true" : "false")
            .AppendLine("\tINFO");
        builder.Append("state\tfirst-impression-theme-deep\t\t")
            .Append(IsFirstImpressionThemeDeep() ? "true" : "false")
            .AppendLine("\tINFO");
        builder.Append("state\tfirst-impression-theme\t\t")
            .Append(EscapeSmokeCell(GetThemeForFirstImpression()))
            .AppendLine("\tINFO");
        builder.Append("state\trecord-archive-first-label\t\t")
            .Append(EscapeSmokeCell(GetRecordArchiveSlotLabel(0)))
            .AppendLine("\tINFO");
        builder.Append("state\trecord-archive-shortcut-action\t\t")
            .Append(EscapeSmokeCell(lastRecordArchiveShortcutAction))
            .AppendLine("\tINFO");
        builder.Append("state\tselected-record-archive-index\t\t")
            .Append(selectedRecordArchiveIndex.ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\tselected-record-archive-label\t\t")
            .Append(EscapeSmokeCell(GetRecordArchiveSlotLabel(selectedRecordArchiveIndex)))
            .AppendLine("\tINFO");
        builder.Append("state\tmemory-card-action\t\t")
            .Append(EscapeSmokeCell(lastMemoryCardAction))
            .AppendLine("\tINFO");
        builder.Append("state\tmemory-book-shortcut-action\t\t")
            .Append(EscapeSmokeCell(lastMemoryBookShortcutAction))
            .AppendLine("\tINFO");
        builder.Append("state\tselected-memory-card-index\t\t")
            .Append(selectedMemoryCardIndex.ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\tselected-memory-card-label\t\t")
            .Append(EscapeSmokeCell(GetMemoryCardLabel(selectedMemoryCardIndex)))
            .AppendLine("\tINFO");
        builder.Append("state\tmemory-card-buttons\t\t")
            .Append(CountMemoryCardButtons().ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\tmemory-card-first-label\t\t")
            .Append(EscapeSmokeCell(GetMemoryCardLabel(0)))
            .AppendLine("\tINFO");
        builder.Append("state\tserver-error\t\t")
            .Append(EscapeSmokeCell(lastServerError))
            .AppendLine("\tINFO");
        builder.Append("state\tclosing-summary\t\t")
            .Append(EscapeSmokeCell(closingCardSummaryText != null ? ShortenForCard(closingCardSummaryText.text, 120) : string.Empty))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-status\t\t")
            .Append(EscapeSmokeCell(playtestFeedbackStatusText != null ? playtestFeedbackStatusText.text : string.Empty))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-readiness-line\t\t")
            .Append(EscapeSmokeCell(playtestFeedbackReadinessText != null ? playtestFeedbackReadinessText.text : string.Empty))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-note-length\t\t")
            .Append(GetPlaytestFeedbackNote().Length.ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-shortcut-action\t\t")
            .Append(EscapeSmokeCell(lastPlaytestFeedbackShortcutAction))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-selected-group\t\t")
            .Append(GetPlaytestFeedbackGroupLabel(selectedPlaytestFeedbackGroup))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-rating\t\t")
            .Append(EscapeSmokeCell(GetPlaytestRatingLabel(selectedPlaytestRating)))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-commercial-readiness\t\t")
            .Append(EscapeSmokeCell(GetPlaytestCommercialReadinessLabel(selectedPlaytestCommercialReadiness)))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-issue-severity\t\t")
            .Append(EscapeSmokeCell(GetPlaytestIssueSeverityLabel(selectedPlaytestIssueSeverity)))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-issue-severity-label\t\t")
            .Append(EscapeSmokeCell(GetPlaytestIssueSeverityButtonLabel(selectedPlaytestIssueSeverity)))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-quality-focus\t\t")
            .Append(EscapeSmokeCell(GetPlaytestQualityFocusAreaId(selectedPlaytestQualityFocus)))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-quality-focus-label\t\t")
            .Append(EscapeSmokeCell(GetPlaytestQualityFocusButtonLabel(selectedPlaytestQualityFocus)))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-completed-five-turn-session\t\t")
            .Append(IsCompletedFiveTurnSession() ? "true" : "false")
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-positive-quality-ready\t\t")
            .Append(IsPositiveQualityEvidenceReady() ? "true" : "false")
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-ending-record-saved\t\t")
            .Append(HasSavedEndingRecordThisSession() ? "true" : "false")
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-quality-areas\t\t")
            .Append(EscapeSmokeCell(FormatPlaytestTags(GetPlaytestQualityAreas(GetPlaytestFeedbackNote()))))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-risk-tags\t\t")
            .Append(EscapeSmokeCell(FormatPlaytestTags(GetPlaytestRiskTags())))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-evidence-tier\t\t")
            .Append(EscapeSmokeCell(GetPlaytestEvidenceTier()))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-review-action\t\t")
            .Append(EscapeSmokeCell(BuildReviewActionRecommendationLine()))
            .AppendLine("\tINFO");
        builder.Append("state\tfeedback-commercial-quality-evidence\t\t")
            .Append(EscapeSmokeCell(BuildCommercialQualityEvidenceLine()))
            .AppendLine("\tINFO");

        if (leadButtons == null) return;
        for (int i = 0; i < leadButtons.Length; i++)
        {
            string label = string.Empty;
            if (leadButtons[i] != null)
            {
                Text text = FindChildText(leadButtons[i].transform, "Label");
                label = text != null ? text.text : string.Empty;
            }

            builder.Append("lead\tquestion-")
                .Append((i + 1).ToString(CultureInfo.InvariantCulture))
                .Append("\t\t")
                .Append(EscapeSmokeCell(label))
                .AppendLine("\tINFO");
        }
    }

    private bool AppendSmokeThinkingCopy(StringBuilder builder, bool expectConcise)
    {
        string dialogue = dialogueText != null ? dialogueText.text : string.Empty;
        string status = statusText != null ? statusText.text : string.Empty;
        string speaker = speakerText != null ? speakerText.text : string.Empty;

        builder.Append("copy\tthinking-dialogue\t\t")
            .Append(EscapeSmokeCell(dialogue))
            .AppendLine("\tINFO");
        builder.Append("copy\tthinking-status\t\t")
            .Append(EscapeSmokeCell(status))
            .AppendLine("\tINFO");
        builder.Append("copy\tthinking-speaker\t\t")
            .Append(EscapeSmokeCell(speaker))
            .AppendLine("\tINFO");

        if (!expectConcise)
        {
            return true;
        }

        bool linePass = string.Equals(dialogue, ThinkingReplyText, StringComparison.Ordinal)
            && string.Equals(status, ThinkingReplyText, StringComparison.Ordinal);
        bool speakerPass = string.Equals(speaker, "생각 중", StringComparison.Ordinal);
        bool forbiddenPass = !Regex.IsMatch($"{dialogue}\n{status}", "좋아요|좋습니다|물론이죠|잠깐", RegexOptions.IgnoreCase);
        bool lengthPass = dialogue.Length <= 24 && status.Length <= 24;

        builder.Append("expect\tthinking-line\tconcise\t")
            .Append(linePass ? "concise" : "changed")
            .Append("\t")
            .AppendLine(linePass ? "PASS" : "FAIL");
        builder.Append("expect\tthinking-speaker\t생각 중\t")
            .Append(EscapeSmokeCell(speaker))
            .Append("\t")
            .AppendLine(speakerPass ? "PASS" : "FAIL");
        builder.Append("expect\tthinking-forbidden-prefix\tabsent\t")
            .Append(forbiddenPass ? "absent" : "present")
            .Append("\t")
            .AppendLine(forbiddenPass ? "PASS" : "FAIL");
        builder.Append("expect\tthinking-length\tshort\t")
            .Append(lengthPass ? "short" : "long")
            .Append("\t")
            .AppendLine(lengthPass ? "PASS" : "FAIL");

        return linePass && speakerPass && forbiddenPass && lengthPass;
    }

    private bool AppendSmokeStartUtilityState(StringBuilder builder)
    {
        bool startOpen = startMenuObject != null && startMenuObject.activeSelf;
        bool settingsVisible = startSettingsButton != null && startSettingsButton.gameObject.activeInHierarchy;
        bool aboutVisible = startAboutButton != null && startAboutButton.gameObject.activeInHierarchy;
        SaveState savedState;
        bool hasSave = TryReadSavedState(out savedState);
        bool continueVisible = continueButton != null && continueButton.gameObject.activeInHierarchy;
        bool continueInteractable = continueButton != null && continueButton.interactable;
        string savePreviewLine = startSavePreviewText != null ? startSavePreviewText.text : string.Empty;
        string objectiveLine = startObjectiveText != null ? startObjectiveText.text : string.Empty;
        bool objectiveVisible = startObjectiveText != null && startObjectiveText.gameObject.activeInHierarchy;
        bool objectivePass = !startOpen || (objectiveVisible
            && (objectiveLine.Contains("본인 이야기")
                || objectiveLine.Contains("서버 연결")
                || objectiveLine.Contains("서버가 정상")));
        bool pass = !startOpen || (settingsVisible && aboutVisible && objectivePass);

        builder.Append("state\tstart-menu-open\t\t")
            .Append(startOpen ? "open" : "closed")
            .AppendLine("\tINFO");
        builder.Append("state\tstart-menu-action\t\t")
            .Append(EscapeSmokeCell(lastStartMenuAction))
            .AppendLine("\tINFO");
        builder.Append("state\tstart-save-present\t\t")
            .Append(hasSave ? "yes" : "no")
            .AppendLine("\tINFO");
        builder.Append("state\tstart-save-preview-line\t\t")
            .Append(EscapeSmokeCell(savePreviewLine))
            .AppendLine("\tINFO");
        builder.Append("state\tstart-continue-visible\t\t")
            .Append(continueVisible ? "visible" : "hidden")
            .AppendLine("\tINFO");
        builder.Append("state\tstart-continue-interactable\t\t")
            .Append(continueInteractable ? "enabled" : "disabled")
            .AppendLine("\tINFO");
        builder.Append("state\tstart-continue-label\t\t")
            .Append(EscapeSmokeCell(GetSmokeButtonLabel(continueButton)))
            .AppendLine("\tINFO");
        builder.Append("state\tstart-settings-visible\t\t")
            .Append(settingsVisible ? "visible" : "hidden")
            .AppendLine("\tINFO");
        builder.Append("state\tstart-about-visible\t\t")
            .Append(aboutVisible ? "visible" : "hidden")
            .AppendLine("\tINFO");
        builder.Append("state\tstart-objective-visible\t\t")
            .Append(objectiveVisible ? "visible" : "hidden")
            .AppendLine("\tINFO");
        builder.Append("state\tstart-objective-line\t\t")
            .Append(EscapeSmokeCell(objectiveLine))
            .AppendLine("\tINFO");
        builder.Append("expect\tstart-utility-visible\tvisible\t")
            .Append(pass ? "visible" : "hidden")
            .Append("\t")
            .AppendLine(pass ? "PASS" : "FAIL");
        builder.Append("expect\tstart-objective\t겉 장면/속 맥락\t")
            .Append(objectivePass ? "present" : "missing")
            .Append("\t")
            .AppendLine(objectivePass ? "PASS" : "FAIL");

        return pass;
    }

    private bool AppendSmokeAboutServerStatus(StringBuilder builder)
    {
        string aboutStatus = serverStatusText != null ? serverStatusText.text : string.Empty;
        bool aboutOpen = aboutMenuObject != null && aboutMenuObject.activeSelf;
        bool settled = !aboutOpen || (
            !string.IsNullOrWhiteSpace(aboutStatus) &&
            !aboutStatus.Contains("확인 중") &&
            !aboutStatus.Contains("확인하고"));

        builder.Append("state\tabout-server-status\t\t")
            .Append(EscapeSmokeCell(aboutStatus))
            .AppendLine("\tINFO");
        builder.Append("expect\tabout-server-status\tsettled\t")
            .Append(settled ? "settled" : EscapeSmokeCell(aboutStatus))
            .Append("\t")
            .AppendLine(settled ? "PASS" : "FAIL");

        return settled;
    }

    private bool AppendSmokeServerFallback(StringBuilder builder, bool expectFallback)
    {
        builder.Append("state\tanswer-source-label\t\t")
            .Append(EscapeSmokeCell(FormatAnswerSourceForPlayer()))
            .AppendLine("\tINFO");

        if (!expectFallback)
        {
            return true;
        }

        string status = statusText != null ? statusText.text : string.Empty;
        bool sourcePass = string.Equals(lastAnswerSource, "server-fallback", StringComparison.Ordinal);
        bool statusPass = status.Contains("내장 답변");
        bool dialoguePass = dialogueText != null && !string.IsNullOrWhiteSpace(dialogueText.text) && !string.Equals(dialogueText.text, ThinkingReplyText, StringComparison.Ordinal);

        builder.Append("expect\tserver-fallback-source\tserver-fallback\t")
            .Append(EscapeSmokeCell(lastAnswerSource))
            .Append("\t")
            .AppendLine(sourcePass ? "PASS" : "FAIL");
        builder.Append("expect\tserver-fallback-status\t내장 답변\t")
            .Append(EscapeSmokeCell(status))
            .Append("\t")
            .AppendLine(statusPass ? "PASS" : "FAIL");
        builder.Append("expect\tserver-fallback-dialogue\treply\t")
            .Append(dialoguePass ? "reply" : "missing")
            .Append("\t")
            .AppendLine(dialoguePass ? "PASS" : "FAIL");

        return sourcePass && statusPass && dialoguePass;
    }

    private bool AppendSmokeAvatarLayout(StringBuilder builder, bool expectNatural)
    {
        Canvas.ForceUpdateCanvases();

        if (avatarRect == null || avatarImage == null)
        {
            builder.Append("layout\tavatar\t\tmissing\t")
                .AppendLine(expectNatural ? "FAIL" : "INFO");
            return !expectNatural;
        }

        float width = avatarRect.rect.width;
        float height = avatarRect.rect.height;
        float scaleX = avatarRect.localScale.x;
        float scaleY = avatarRect.localScale.y;
        float scaleRatio = Mathf.Abs(scaleY) > 0.001f ? scaleX / scaleY : 0f;
        float footprintRatio = height > 0.001f ? (width * Mathf.Abs(scaleX)) / (height * Mathf.Abs(scaleY)) : 0f;
        bool preserveAspect = avatarImage.preserveAspect;
        bool hasSprite = avatarImage.sprite != null;

        builder.Append("layout\tavatar-width\t\t")
            .Append(FormatSmokeNumber(width))
            .AppendLine("\tINFO");
        builder.Append("layout\tavatar-height\t\t")
            .Append(FormatSmokeNumber(height))
            .AppendLine("\tINFO");
        builder.Append("layout\tavatar-scale-ratio\t\t")
            .Append(FormatSmokeNumber(scaleRatio))
            .AppendLine("\tINFO");
        builder.Append("layout\tavatar-footprint-ratio\t\t")
            .Append(FormatSmokeNumber(footprintRatio))
            .AppendLine("\tINFO");

        if (!expectNatural)
        {
            return true;
        }

        bool scalePass = scaleRatio >= 0.98f && scaleRatio <= 1.04f;
        bool footprintPass = footprintRatio >= 1.10f && footprintRatio <= 1.30f;
        bool spritePass = preserveAspect && hasSprite;

        builder.Append("expect\tavatar-horizontal-scale\tnatural\t")
            .Append(scalePass ? "natural" : "compressed")
            .Append("\t")
            .AppendLine(scalePass ? "PASS" : "FAIL");
        builder.Append("expect\tavatar-footprint\tnatural\t")
            .Append(footprintPass ? "natural" : "distorted")
            .Append("\t")
            .AppendLine(footprintPass ? "PASS" : "FAIL");
        builder.Append("expect\tavatar-preserve-aspect\ton\t")
            .Append(spritePass ? "on" : "off")
            .Append("\t")
            .AppendLine(spritePass ? "PASS" : "FAIL");

        return scalePass && footprintPass && spritePass;
    }

    private bool AppendSmokeDialogueLayout(StringBuilder builder, bool expectPaged)
    {
        Canvas.ForceUpdateCanvases();

        if (dialogueScrollRect == null || dialogueViewportRect == null || dialogueContentRect == null || dialogueText == null)
        {
            builder.Append("layout\tdialogue\t\tmissing\t")
                .AppendLine(expectPaged ? "FAIL" : "INFO");
            return !expectPaged;
        }

        float viewportHeight = dialogueViewportRect.rect.height;
        float contentHeight = dialogueContentRect.rect.height;
        float preferredTextHeight = dialogueText.preferredHeight + 64f;
        bool scrollDisabled = !dialogueScrollRect.vertical && dialogueScrollRect.verticalScrollbar == null;
        bool textFitsContent = preferredTextHeight <= contentHeight + 3f;
        bool cueVisible = dialogueScrollCueObject != null && dialogueScrollCueObject.activeSelf;
        bool paged = dialoguePages.Count > 1;
        bool hasNextPage = paged && dialoguePageIndex < dialoguePages.Count - 1;

        builder.Append("layout\tdialogue-viewport-height\t\t")
            .Append(FormatSmokeNumber(viewportHeight))
            .AppendLine("\tINFO");
        builder.Append("layout\tdialogue-content-height\t\t")
            .Append(FormatSmokeNumber(contentHeight))
            .AppendLine("\tINFO");
        builder.Append("layout\tdialogue-preferred-height\t\t")
            .Append(FormatSmokeNumber(preferredTextHeight))
            .AppendLine("\tINFO");
        builder.Append("layout\tdialogue-page-count\t\t")
            .Append(dialoguePages.Count.ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");
        builder.Append("layout\tdialogue-page-index\t\t")
            .Append(dialoguePageIndex.ToString(CultureInfo.InvariantCulture))
            .AppendLine("\tINFO");

        if (!expectPaged)
        {
            return true;
        }

        bool pagedPass = paged;
        bool fitPass = textFitsContent;
        bool cuePass = cueVisible;
        bool scrollDisabledPass = scrollDisabled;

        builder.Append("expect\tdialogue-paged\tpaged\t")
            .Append(paged ? "paged" : "single")
            .Append("\t")
            .AppendLine(pagedPass ? "PASS" : "FAIL");
        builder.Append("expect\tdialogue-text-fit\tfit\t")
            .Append(textFitsContent ? "fit" : "clipped")
            .Append("\t")
            .AppendLine(fitPass ? "PASS" : "FAIL");
        builder.Append("expect\tdialogue-page-cue\tvisible\t")
            .Append(cueVisible ? "visible" : "hidden")
            .Append("\t")
            .AppendLine((cuePass && hasNextPage) ? "PASS" : "FAIL");
        builder.Append("expect\tdialogue-scroll-disabled\tdisabled\t")
            .Append(scrollDisabled ? "disabled" : "enabled")
            .Append("\t")
            .AppendLine(scrollDisabledPass ? "PASS" : "FAIL");

        return pagedPass && fitPass && cuePass && hasNextPage && scrollDisabledPass;
    }

    private static string FormatSmokeNumber(float value)
    {
        return value.ToString("0.0", CultureInfo.InvariantCulture);
    }

    private static string EscapeSmokeCell(string value)
    {
        return (value ?? string.Empty)
            .Replace("\r", " ")
            .Replace("\n", " ")
            .Replace("\t", " ")
            .Trim();
    }

    private void AppendSmokePanelState(StringBuilder builder, string panel)
    {
        if (!TryGetSmokePanelState(panel, out bool open))
        {
            builder.Append("state\t").Append(panel).Append("\t\tunknown\tFAIL").AppendLine();
            return;
        }

        builder.Append("state\t")
            .Append(panel)
            .Append("\t\t")
            .Append(open ? "open" : "closed")
            .AppendLine("\tINFO");
    }

    private string GetSmokeNoteTabName()
    {
        switch (currentNoteTabIndex)
        {
            case 1: return "evidence";
            case 2: return "history";
            default: return "question";
        }
    }

    private string GetSelectedLeadTitle()
    {
        if (leadButtons == null || leadButtons.Length == 0) return string.Empty;
        int index = Mathf.Clamp(selectedLeadIndex, 0, leadButtons.Length - 1);
        return BuildLeadCardTitle(GetLeadQuestion(index));
    }

    private string GetSelectedLeadLabel()
    {
        if (leadButtons == null || leadButtons.Length == 0) return string.Empty;
        int index = Mathf.Clamp(selectedLeadIndex, 0, leadButtons.Length - 1);
        return BuildLeadCardLabel(index, GetLeadQuestion(index));
    }

    private string GetChapterButtonLabel(int index)
    {
        if (chapterButtons == null || index < 0 || index >= chapterButtons.Length || chapterButtons[index] == null) return string.Empty;
        Text label = chapterButtons[index].GetComponentInChildren<Text>();
        return label != null ? label.text : string.Empty;
    }

    private string GetFirstImpressionButtonLabel(int index)
    {
        if (firstImpressionButtons == null || index < 0 || index >= firstImpressionButtons.Length || firstImpressionButtons[index] == null) return string.Empty;
        Text label = firstImpressionButtons[index].GetComponentInChildren<Text>();
        return label != null ? label.text : string.Empty;
    }

    private bool AppendSmokeExpectations(StringBuilder builder, List<string> panels, bool expectedOpen)
    {
        bool passed = true;
        if (panels == null) return true;

        for (int i = 0; i < panels.Count; i++)
        {
            string panel = panels[i];
            bool known = TryGetSmokePanelState(panel, out bool actualOpen);
            bool result = known && actualOpen == expectedOpen;
            passed &= result;

            builder.Append("expect\t")
                .Append(panel)
                .Append("\t")
                .Append(expectedOpen ? "open" : "closed")
                .Append("\t")
                .Append(known ? (actualOpen ? "open" : "closed") : "unknown")
                .Append("\t")
                .AppendLine(result ? "PASS" : "FAIL");
        }

        return passed;
    }

    private bool TryGetSmokePanelState(string panel, out bool open)
    {
        open = false;
        switch ((panel ?? string.Empty).Trim().ToLowerInvariant())
        {
            case "question":
            case "phone":
            case "note":
                open = questionNoteOpen;
                return true;
            case "memory":
            case "memorybook":
                open = memoryBookObject != null && memoryBookObject.activeSelf;
                return true;
            case "records":
            case "archive":
                open = recordArchiveObject != null && recordArchiveObject.activeSelf;
                return true;
            case "settings":
                open = settingsMenuObject != null && settingsMenuObject.activeSelf;
                return true;
            case "about":
            case "info":
                open = aboutMenuObject != null && aboutMenuObject.activeSelf;
                return true;
            case "pause":
                open = pauseMenuObject != null && pauseMenuObject.activeSelf;
                return true;
            case "closing":
                open = closingCardObject != null && closingCardObject.activeSelf;
                return true;
            case "completion":
            case "completionchoice":
                open = completionChoiceObject != null && completionChoiceObject.activeSelf;
                return true;
            case "feedback":
                open = playtestFeedbackObject != null && playtestFeedbackObject.activeSelf;
                return true;
            case "hotspot":
            case "hotspotpreview":
                open = hotspotPreviewObject != null && hotspotPreviewObject.activeSelf;
                return true;
            case "restart":
                open = restartConfirmObject != null && restartConfirmObject.activeSelf;
                return true;
            case "start":
                open = startMenuObject != null && startMenuObject.activeSelf;
                return true;
            default:
                return false;
        }
    }

    private IEnumerator SmokeSubmitQuestion(string question)
    {
        yield return null;
        if (inputField != null)
        {
            SetDirectInputOpen(true, true);
            inputField.text = question;
        }

        SubmitCurrentInput();
        yield return null;
        Debug.Log($"Smoke submit immediate chat entries: {chatEntryCount}");

        float deadline = Time.realtimeSinceStartup + 10f;
        while (busy && Time.realtimeSinceStartup < deadline)
        {
            yield return null;
        }

        Debug.Log($"Smoke submit final chat entries: {chatEntryCount}");
    }

    private IEnumerator SmokeSubmitQuestionSequence(string[] questions, bool openClosingAfterQuestions, bool saveEndingAfterQuestions)
    {
        yield return null;
        if (questions == null || questions.Length == 0) yield break;

        for (int i = 0; i < questions.Length; i++)
        {
            string question = questions[i];
            if (string.IsNullOrWhiteSpace(question)) continue;

            float readyDeadline = Time.realtimeSinceStartup + 10f;
            while (busy && Time.realtimeSinceStartup < readyDeadline)
            {
                yield return null;
            }

            if (inputField != null)
            {
                SetDirectInputOpen(true, true);
                inputField.text = question.Trim();
            }

            SubmitCurrentInput();
            yield return null;

            float answerDeadline = Time.realtimeSinceStartup + 12f;
            while (busy && Time.realtimeSinceStartup < answerDeadline)
            {
                yield return null;
            }

            Debug.Log($"Smoke sequence question {i + 1}/{questions.Length}, turns: {conversationTurns}, busy: {busy}");
        }

        if (openClosingAfterQuestions && !busy && conversationTurns > 0)
        {
            ShowClosingCard();
            yield return null;
        }

        if (saveEndingAfterQuestions && !busy)
        {
            SaveEndingRecord();
            yield return null;
        }
    }

    private IEnumerator SmokeSubmitCategoryFlow(string theme, bool continueToNextCategory)
    {
        yield return null;

        string category = CanonicalTheme(theme);
        if (string.IsNullOrWhiteSpace(category)) category = "일상";

        if (startMenuObject != null) startMenuObject.SetActive(false);
        SetQuestionNoteOpen(true);
        ShowNoteTab(0);
        SetActiveQuestionCategory(category, true);

        for (int i = 0; i < RequiredQuestionCount; i++)
        {
            float readyDeadline = Time.realtimeSinceStartup + 10f;
            while (busy && Time.realtimeSinceStartup < readyDeadline)
            {
                yield return null;
            }

            string question = GetLeadQuestion(0);
            if (string.IsNullOrWhiteSpace(question))
            {
                string[] bank = GetCategoryQuestionBank(category);
                question = bank != null && bank.Length > 0 ? bank[Mathf.Min(i, bank.Length - 1)] : $"{category}에 대해 더 들려주세요.";
            }

            SubmitPresetQuestion(question);
            yield return null;

            float answerDeadline = Time.realtimeSinceStartup + 12f;
            while (busy && Time.realtimeSinceStartup < answerDeadline)
            {
                yield return null;
            }

            Debug.Log($"Smoke category flow {category} question {i + 1}/{RequiredQuestionCount}, category turns: {activeCategoryQuestionCount}, closing: {(closingCardObject != null && closingCardObject.activeSelf)}");
        }

        if (continueToNextCategory)
        {
            SubmitMore();
            yield return null;
        }
    }

    private IEnumerator SmokeShowMemoryToast(string theme)
    {
        yield return null;
        ShowMemoryUnlockToast(theme);
    }

    private IEnumerator SmokeShowMemoryCompletionToast()
    {
        yield return null;
        ShowMemoryCompletionToast();
    }

    private void SetMarketingKeyArtMode()
    {
        if (avatarImage != null)
        {
            SetExpression(ExpressionState.Idle);
        }

        if (avatarRect != null)
        {
            avatarRect.anchoredPosition = new Vector2(-328f, -12f);
            avatarRect.sizeDelta = new Vector2(720f, 600f);
            avatarRect.localScale = AvatarScale(1f);
            avatarBasePosition = avatarRect.anchoredPosition;
            UpdateAvatarIntegrationLayers(0f, 1f);
        }

        if (UseIntegratedSceneArtwork)
        {
            if (avatarImage != null)
            {
                avatarImage.color = new Color(1f, 1f, 1f, 0f);
            }
            return;
        }

        Transform root = avatarImage != null ? avatarImage.transform.parent : null;
        if (root == null) return;

        for (int i = 0; i < root.childCount; i++)
        {
            Transform child = root.GetChild(i);
            bool keep =
                child.name == "Illustrated Study Room" ||
                child.name == "Scene Warm Wash" ||
                child.name == "Avatar Backdrop Shadow" ||
                child.name == "Avatar Contact Shadow" ||
                child.name == "Seated Character";
            child.gameObject.SetActive(keep);
        }
    }

    private static string ReadSmokeTextArgument(string[] args, int startIndex)
    {
        List<string> parts = new List<string>();
        for (int i = startIndex; i < args.Length; i++)
        {
            if (args[i].StartsWith("--", StringComparison.Ordinal)) break;
            parts.Add(args[i]);
        }

        return string.Join(" ", parts).Trim();
    }

    private IEnumerator CaptureAndQuit(string path, float delaySeconds)
    {
        yield return null;
        if (delaySeconds > 0f)
        {
            yield return new WaitForSeconds(delaySeconds);
        }
        yield return new WaitForEndOfFrame();

        string directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        ScreenCapture.CaptureScreenshot(path);
        yield return new WaitForSeconds(1.0f);
        Application.Quit();
    }

    private static byte[] EncodeWav(AudioClip clip, int sampleFrames)
    {
        int channels = clip.channels;
        int frequency = clip.frequency;
        int sampleCount = Mathf.Max(0, sampleFrames * channels);
        float[] samples = new float[sampleCount];
        clip.GetData(samples, 0);

        byte[] data = new byte[44 + sampleCount * 2];
        WriteString(data, 0, "RIFF");
        WriteInt(data, 4, data.Length - 8);
        WriteString(data, 8, "WAVE");
        WriteString(data, 12, "fmt ");
        WriteInt(data, 16, 16);
        WriteShort(data, 20, 1);
        WriteShort(data, 22, (short)channels);
        WriteInt(data, 24, frequency);
        WriteInt(data, 28, frequency * channels * 2);
        WriteShort(data, 32, (short)(channels * 2));
        WriteShort(data, 34, 16);
        WriteString(data, 36, "data");
        WriteInt(data, 40, sampleCount * 2);

        int offset = 44;
        for (int i = 0; i < samples.Length; i++)
        {
            short sample = (short)Mathf.Clamp(samples[i] * short.MaxValue, short.MinValue, short.MaxValue);
            WriteShort(data, offset, sample);
            offset += 2;
        }

        return data;
    }

    private static void WriteString(byte[] data, int offset, string value)
    {
        for (int i = 0; i < value.Length; i++)
        {
            data[offset + i] = (byte)value[i];
        }
    }

    private static void WriteInt(byte[] data, int offset, int value)
    {
        data[offset] = (byte)(value & 0xff);
        data[offset + 1] = (byte)((value >> 8) & 0xff);
        data[offset + 2] = (byte)((value >> 16) & 0xff);
        data[offset + 3] = (byte)((value >> 24) & 0xff);
    }

    private static void WriteShort(byte[] data, int offset, short value)
    {
        data[offset] = (byte)(value & 0xff);
        data[offset + 1] = (byte)((value >> 8) & 0xff);
    }
}
