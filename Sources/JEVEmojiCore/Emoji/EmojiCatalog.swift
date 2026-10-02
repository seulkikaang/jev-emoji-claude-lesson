import Foundation

/// The emoji Jev chooses from.
///
/// TypeSafe allows at most 255 options per Choice question, so this list stays below that.
/// Order matters only as a tie breaker when two emoji get the same probability.
public enum EmojiCatalog {
    public static let maxChoiceOptions = 255

    public static let all: [EmojiCandidate] = faces + feelings + love + gestures
        + celebration + work + food + nature + animals + activities + symbols

    static let faces: [EmojiCandidate] = [
        .init("grinning", "😀", "happy, cheerful smile", "기쁨, 웃음, 좋아"),
        .init("beaming", "😁", "beaming grin, proud joy", "신남, 뿌듯"),
        .init("joy", "😂", "tears of joy, very funny", "웃김, ㅋㅋㅋ, 빵터짐"),
        .init("rofl", "🤣", "rolling on the floor laughing", "대폭소, 개웃김"),
        .init("laughing", "😆", "laughing hard with squinting eyes", "깔깔, 신나"),
        .init("smile", "😊", "warm gentle smile, thankful", "미소, 흐뭇, 감사"),
        .init("slight_smile", "🙂", "polite slight smile, fine", "무난, 괜찮아, 예의"),
        .init("blush", "☺️", "shy and pleased", "수줍음, 쑥스러움"),
        .init("halo", "😇", "innocent, angelic, relieved", "천사, 착함, 다행"),
        .init("wink", "😉", "playful wink, joking", "장난, 윙크"),
        .init("relieved", "😌", "relieved, calm, content", "안도, 편안"),
        .init("heart_eyes", "😍", "adoring, in love, amazing", "반함, 최고, 너무 좋아"),
        .init("smiling_hearts", "🥰", "feeling loved, happy affection", "사랑받는, 행복"),
        .init("star_struck", "🤩", "star-struck, amazed, excited", "감탄, 대박, 설렘"),
        .init("kiss", "😘", "blowing a kiss, affection", "뽀뽀, 애정"),
        .init("yum", "😋", "delicious, tasty", "맛있다, 냠냠"),
        .init("zany", "😜", "silly, goofy, teasing", "장난, 엉뚱"),
        .init("cool", "😎", "cool, confident, relaxed", "멋짐, 자신감, 여유"),
        .init("nerd", "🤓", "nerdy, studying, geeky", "공부, 덕후"),
        .init("hugging", "🤗", "hug, warm welcome", "포옹, 환영, 위로"),
        .init("partying", "🥳", "party face, birthday celebration", "파티, 생일, 축하"),
        .init("upside_down", "🙃", "ironic, sarcastic, awkward", "어이없음, 반어"),
        .init("sweat_smile", "😅", "nervous laugh, awkward relief", "머쓱, 진땀, 다행"),
        .init("melting", "🫠", "melting, overwhelmed, embarrassed", "녹아내림, 민망"),
        .init("saluting", "🫡", "salute, roger that, respect", "충성, 알겠습니다, 존경"),
        .init("smirk", "😏", "smirk, knowing look, confident", "피식, 의미심장"),
        .init("thinking", "🤔", "thinking, wondering, unsure", "고민, 생각중, 글쎄"),
        .init("monocle", "🧐", "inspecting closely, skeptical", "의심, 꼼꼼히 보기"),
        .init("neutral", "😐", "neutral, unimpressed", "무표정, 덤덤"),
        .init("unamused", "😒", "unamused, displeased", "불만, 시큰둥"),
        .init("rolling_eyes", "🙄", "eye roll, exasperated", "어이없음, 짜증"),
        .init("grimacing", "😬", "awkward, cringe, oops", "민망, 아차"),
        .init("shush", "🤫", "secret, be quiet", "쉿, 비밀"),
        .init("zipper", "🤐", "keep mouth shut", "입 다물기, 비밀 유지"),
        .init("open_mouth", "😮", "surprised", "놀람, 오"),
        .init("astonished", "😲", "astonished", "깜짝"),
        .init("flushed", "😳", "embarrassed, flushed", "당황, 부끄러움"),
        .init("money_mouth", "🤑", "money, profit", "돈, 이득"),
        .init("ghost", "👻", "ghost, spooky, playful", "유령, 장난"),
        .init("robot", "🤖", "robot, AI, automation", "로봇, AI, 자동화"),
        .init("poop", "💩", "poop, bad result, joke", "똥, 망함"),
        .init("devil", "😈", "mischievous devil", "악마, 꿍꿍이")
    ]

    static let feelings: [EmojiCandidate] = [
        .init("pensive", "😔", "pensive, regretful", "우울, 아쉬움, 반성"),
        .init("sleepy", "😪", "sleepy, drowsy", "졸림"),
        .init("sleeping", "😴", "sleeping, bored, tired", "잠, 피곤, 지루"),
        .init("sick", "🤒", "sick with a fever", "아픔, 감기, 열"),
        .init("nauseated", "🤢", "disgusted, nauseous", "역겨움, 속 안 좋음"),
        .init("hot_face", "🥵", "very hot weather, overheated", "더위, 더워"),
        .init("cold_face", "🥶", "freezing cold", "추위, 추워"),
        .init("woozy", "🥴", "dizzy, tipsy", "어지러움, 취함"),
        .init("mind_blown", "🤯", "mind blown, shocked", "충격, 멘붕"),
        .init("confused", "😕", "confused, puzzled", "헷갈림, 혼란"),
        .init("worried", "😟", "worried, anxious", "걱정, 불안"),
        .init("pleading", "🥺", "pleading eyes, deeply touched", "부탁, 애원, 감동"),
        .init("cry", "😢", "crying, sad", "눈물, 슬픔"),
        .init("sob", "😭", "sobbing loudly, overwhelmed", "오열, 감동, 서러움"),
        .init("fearful", "😨", "scared", "무서움, 겁"),
        .init("scream", "😱", "screaming in fear, shocked", "경악, 충격"),
        .init("weary", "😩", "weary, fed up", "지침, 힘듦"),
        .init("tired", "😫", "tired and stressed", "피곤, 스트레스"),
        .init("triumph", "😤", "huffing, frustrated but determined", "씩씩, 의지, 분함"),
        .init("angry", "😠", "angry", "화남"),
        .init("rage", "😡", "furious rage", "분노, 열받음"),
        .init("skull", "💀", "dead from laughing or exhaustion", "죽겠다, 웃겨 죽음"),
        .init("facepalm", "🤦", "facepalm, frustrated at a mistake", "아이고, 한심"),
        .init("shrug", "🤷", "shrug, don't know", "몰라, 어쩔 수 없지")
    ]

    static let love: [EmojiCandidate] = [
        .init("red_heart", "❤️", "love, care", "사랑, 하트"),
        .init("pink_heart", "🩷", "sweet affection", "핑크, 다정"),
        .init("yellow_heart", "💛", "friendship, cheerful", "우정, 밝음"),
        .init("green_heart", "💚", "nature, health", "자연, 건강"),
        .init("blue_heart", "💙", "trust, calm", "신뢰, 차분"),
        .init("purple_heart", "💜", "compassion, fandom", "보라, 응원"),
        .init("broken_heart", "💔", "heartbreak", "이별, 상처"),
        .init("sparkling_heart", "💖", "sparkling love, excitement", "설렘"),
        .init("two_hearts", "💕", "lovely, affection", "사랑스러움"),
        .init("heart_hands", "🫶", "heart hands, gratitude", "고마워, 응원"),
        .init("love_letter", "💌", "love letter, heartfelt message", "편지, 고백"),
        .init("rose", "🌹", "romance, rose", "장미, 로맨스"),
        .init("ring", "💍", "engagement, wedding", "결혼, 프러포즈")
    ]

    static let gestures: [EmojiCandidate] = [
        .init("thumbs_up", "👍", "approve, good, agreed", "좋아요, 오케이, 확인"),
        .init("thumbs_down", "👎", "disapprove", "별로, 싫어요"),
        .init("clap", "👏", "applause, well done", "박수, 잘했어"),
        .init("raised_hands", "🙌", "hooray, celebration", "만세, 야호"),
        .init("pray", "🙏", "please, thank you, hoping", "부탁, 감사, 기도"),
        .init("ok_hand", "👌", "okay, perfect", "오케이, 완벽"),
        .init("victory", "✌️", "peace, victory", "브이, 평화"),
        .init("crossed_fingers", "🤞", "good luck, hoping", "행운, 제발"),
        .init("wave", "👋", "hello, goodbye", "안녕, 인사"),
        .init("muscle", "💪", "strength, you can do it", "힘내, 화이팅"),
        .init("point_right", "👉", "look here, next", "여기, 다음"),
        .init("writing_hand", "✍️", "writing, taking notes", "작성, 메모"),
        .init("handshake", "🤝", "agreement, partnership", "협력, 계약, 합의"),
        .init("bow", "🙇", "bowing, apology, respect", "사과, 죄송, 꾸벅"),
        .init("raising_hand", "🙋", "volunteer, asking a question", "저요, 질문"),
        .init("no_gesture", "🙅", "no, not allowed", "안 돼, 금지"),
        .init("ok_gesture", "🙆", "okay, yes", "좋아, 가능"),
        .init("runner", "🏃", "running, in a hurry", "달리기, 서두름"),
        .init("dancer", "💃", "dancing, party mood", "춤, 신남"),
        .init("people_hugging", "🫂", "hug, comfort", "위로, 포옹"),
        .init("brain", "🧠", "brain, smart, thinking hard", "두뇌, 아이디어")
    ]

    static let celebration: [EmojiCandidate] = [
        .init("tada", "🎉", "celebration, congratulations, success", "축하, 파티, 성공"),
        .init("confetti", "🎊", "festive celebration", "축제"),
        .init("balloon", "🎈", "balloon, birthday", "풍선"),
        .init("gift", "🎁", "gift, present", "선물"),
        .init("cake", "🎂", "birthday cake", "생일"),
        .init("trophy", "🏆", "winner, achievement", "우승, 성과"),
        .init("gold_medal", "🥇", "first place", "1등, 금메달"),
        .init("fireworks", "🎆", "fireworks, new year", "불꽃놀이, 새해"),
        .init("christmas_tree", "🎄", "Christmas", "크리스마스"),
        .init("champagne", "🍾", "champagne, toast", "축배"),
        .init("sparkles", "✨", "sparkles, new, special", "반짝, 새로움, 특별"),
        .init("star", "⭐", "star, favorite, rating", "별, 즐겨찾기"),
        .init("glowing_star", "🌟", "shining, outstanding", "빛나는"),
        .init("crown", "👑", "king, the best", "왕, 최고"),
        .init("hundred", "💯", "perfect score, totally agree", "백점, 완벽, 인정"),
        .init("fire", "🔥", "hot, trending, awesome", "불타는, 대박, 열정")
    ]

    static let work: [EmojiCandidate] = [
        .init("laptop", "💻", "computer work, coding", "노트북, 개발, 업무"),
        .init("phone", "📱", "phone, mobile app", "휴대폰, 앱"),
        .init("email", "📧", "email", "이메일, 메일"),
        .init("memo", "📝", "notes, writing, to-do", "메모, 기록, 할 일"),
        .init("calendar", "📅", "schedule, date", "일정, 날짜, 약속"),
        .init("clipboard", "📋", "checklist, report", "체크리스트, 보고"),
        .init("chart_up", "📈", "growth, increase", "성장, 상승, 매출"),
        .init("chart_down", "📉", "decline, decrease", "하락, 감소"),
        .init("bar_chart", "📊", "data, statistics", "데이터, 통계"),
        .init("briefcase", "💼", "business, job", "출근, 회사, 비즈니스"),
        .init("books", "📚", "studying, reading", "공부, 독서"),
        .init("pencil", "✏️", "editing, draft", "수정, 초안"),
        .init("bulb", "💡", "idea, insight", "아이디어, 깨달음"),
        .init("target", "🎯", "goal, on target", "목표, 정확"),
        .init("rocket", "🚀", "launch, fast growth", "출시, 시작, 빠름"),
        .init("wrench", "🔧", "fixing, repair", "수리, 고침"),
        .init("lock", "🔒", "security, private", "보안, 잠금"),
        .init("key", "🔑", "key, the answer", "열쇠, 비결"),
        .init("magnifier", "🔍", "search, investigate", "검색, 조사"),
        .init("megaphone", "📣", "announcement, promotion", "공지, 홍보"),
        .init("pushpin", "📌", "important, pinned", "중요, 고정"),
        .init("hourglass", "⏳", "waiting, time running out", "기다림, 마감"),
        .init("alarm_clock", "⏰", "alarm, deadline, morning", "알람, 마감, 아침"),
        .init("money_bag", "💰", "money, revenue", "돈, 수익"),
        .init("graduation", "🎓", "graduation, passing an exam", "졸업, 합격")
    ]

    static let food: [EmojiCandidate] = [
        .init("coffee", "☕", "coffee, break time", "커피, 휴식, 카페"),
        .init("beer", "🍺", "beer", "맥주, 회식"),
        .init("cheers", "🍻", "cheers, drinking together", "건배, 짠"),
        .init("wine", "🍷", "wine", "와인"),
        .init("pizza", "🍕", "pizza", "피자"),
        .init("burger", "🍔", "burger", "햄버거"),
        .init("ramen", "🍜", "noodles, ramen", "라면, 국수"),
        .init("rice", "🍚", "rice meal", "밥"),
        .init("sushi", "🍣", "sushi", "초밥"),
        .init("chicken", "🍗", "fried chicken", "치킨"),
        .init("meat", "🥩", "meat, barbecue", "고기"),
        .init("salad", "🥗", "salad, diet", "샐러드, 다이어트"),
        .init("donut", "🍩", "donut, dessert", "도넛, 디저트"),
        .init("ice_cream", "🍦", "ice cream", "아이스크림"),
        .init("strawberry", "🍓", "strawberry", "딸기"),
        .init("bento", "🍱", "lunch box", "도시락, 점심"),
        .init("dining", "🍽️", "meal, dining out", "식사, 밥 먹자")
    ]

    static let nature: [EmojiCandidate] = [
        .init("sun", "☀️", "sunny", "맑음, 햇살"),
        .init("rainbow", "🌈", "rainbow, hope", "무지개, 희망"),
        .init("cloud", "☁️", "cloudy", "흐림"),
        .init("rain", "🌧️", "rain", "비"),
        .init("umbrella", "☔", "rainy day", "우산, 장마"),
        .init("snowflake", "❄️", "snow, winter cold", "눈, 겨울"),
        .init("snowman", "⛄", "winter fun", "눈사람"),
        .init("lightning", "⚡", "electric, fast, energy", "번개, 빠름, 에너지"),
        .init("wind", "🌬️", "windy", "바람"),
        .init("moon", "🌙", "night, good night", "밤, 잘 자"),
        .init("cherry_blossom", "🌸", "spring, cherry blossom", "봄, 벚꽃"),
        .init("sunflower", "🌻", "sunflower, summer", "해바라기, 여름"),
        .init("maple_leaf", "🍁", "autumn leaves", "가을, 단풍"),
        .init("tree", "🌳", "tree, nature", "나무, 자연"),
        .init("seedling", "🌱", "growth, new beginning", "새싹, 시작, 성장"),
        .init("bouquet", "💐", "flowers, congratulations", "꽃다발"),
        .init("ocean_wave", "🌊", "ocean, wave", "바다, 파도"),
        .init("mountain", "⛰️", "mountain, hiking", "산, 등산"),
        .init("earth", "🌏", "world, global", "세계, 지구")
    ]

    static let animals: [EmojiCandidate] = [
        .init("dog", "🐶", "dog, puppy", "강아지"),
        .init("cat", "🐱", "cat", "고양이"),
        .init("rabbit", "🐰", "rabbit, cute", "토끼, 귀여움"),
        .init("bear", "🐻", "bear", "곰"),
        .init("panda", "🐼", "panda", "판다"),
        .init("fox", "🦊", "fox, clever", "여우"),
        .init("chick", "🐥", "baby chick, cute", "병아리, 귀여움"),
        .init("unicorn", "🦄", "unicorn, magical, rare", "유니콘, 특별"),
        .init("butterfly", "🦋", "butterfly, transformation", "나비, 변화"),
        .init("turtle", "🐢", "turtle, slow", "거북이, 느림"),
        .init("snail", "🐌", "snail, very slow", "달팽이, 느림"),
        .init("bee", "🐝", "busy bee, hardworking", "벌, 부지런"),
        .init("paw_prints", "🐾", "paw prints, pets", "발자국, 반려동물")
    ]

    static let activities: [EmojiCandidate] = [
        .init("airplane", "✈️", "travel, flight, business trip", "여행, 비행기, 출장"),
        .init("luggage", "🧳", "trip, packing", "여행 가방"),
        .init("beach", "🏖️", "beach vacation", "해변, 휴가"),
        .init("house", "🏠", "home", "집, 귀가"),
        .init("car", "🚗", "car, driving", "차, 운전"),
        .init("train", "🚆", "train, commute", "기차, 출퇴근"),
        .init("soccer", "⚽", "soccer", "축구"),
        .init("basketball", "🏀", "basketball", "농구"),
        .init("weightlifting", "🏋️", "weightlifting, workout", "운동, 헬스"),
        .init("meditation", "🧘", "meditation, calm mind", "명상, 요가, 마음 챙김"),
        .init("video_game", "🎮", "video games", "게임"),
        .init("music", "🎵", "music", "음악, 노래"),
        .init("headphones", "🎧", "listening to music", "음악 감상, 이어폰"),
        .init("microphone", "🎤", "singing, giving a talk", "노래방, 발표"),
        .init("clapper", "🎬", "movie, filming", "영화, 촬영"),
        .init("camera", "📸", "photo", "사진"),
        .init("palette", "🎨", "art, design", "그림, 디자인"),
        .init("shopping", "🛍️", "shopping", "쇼핑"),
        .init("hospital", "🏥", "hospital", "병원"),
        .init("pill", "💊", "medicine", "약")
    ]

    static let symbols: [EmojiCandidate] = [
        .init("check", "✅", "done, correct", "완료, 확인, 정답"),
        .init("cross", "❌", "wrong, no, cancel", "틀림, 취소"),
        .init("warning", "⚠️", "warning, caution", "주의, 경고"),
        .init("question", "❓", "question", "질문, 궁금"),
        .init("exclamation", "❗", "important", "중요, 강조"),
        .init("double_exclamation", "‼️", "urgent emphasis", "강조, 긴급"),
        .init("no_entry", "⛔", "forbidden, stop", "금지"),
        .init("sos", "🆘", "help, emergency", "도움, 긴급"),
        .init("new", "🆕", "new", "신규, 새로운"),
        .init("zzz", "💤", "sleep", "잠, 쿨쿨"),
        .init("speech", "💬", "chat, comment", "대화, 댓글"),
        .init("thought", "💭", "thought, daydream", "생각"),
        .init("dash", "💨", "dashing off quickly", "휙, 빠름"),
        .init("boom", "💥", "boom, impact", "쾅, 충격"),
        .init("dizzy", "💫", "dizzy, magic", "어질, 반짝"),
        .init("sweat_drops", "💦", "sweat, hard effort", "땀, 노력"),
        .init("bell", "🔔", "notification", "알림"),
        .init("location", "📍", "place, location", "위치, 장소"),
        .init("finish_flag", "🏁", "finish line, done", "완주, 끝"),
        .init("battery", "🔋", "recharged, energy", "충전, 에너지"),
        .init("low_battery", "🪫", "drained, low energy", "방전, 기진맥진"),
        .init("eyes", "👀", "looking, curious, watching", "눈치, 궁금, 지켜봄")
    ]
}
