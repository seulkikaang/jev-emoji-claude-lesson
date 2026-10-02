# TypeSafe JEV 연결 방식

2026-10-03에 TypeSafe 공식 문서를 직접 읽고 맞춘 내용입니다.

## 확인한 공식 문서

| 문서 | 확인한 내용 |
| --- | --- |
| [API reference](https://docs.typesafe.ai/api) | 주소 `POST https://api.typesafe.ai/v1/systemone`, `Authorization: Bearer <API_KEY>`, 요청과 응답 JSON 모양, 오류 코드 401·422·429·529 |
| [Choice](https://docs.typesafe.ai/primitives/choice) | 정해 둔 선택지 중 하나를 고르고, 모든 선택지의 확률을 돌려줌 |
| [Models](https://docs.typesafe.ai/models) | 모델 별칭 `jev-latest` (현재 `jev-1.13.0`), 입력 토큰당 과금, 한국어 정확도 안내 |
| [Line-by-line search 쿡북](https://docs.typesafe.ai/cookbooks/semantic_find) | Choice 확률로 여러 후보의 순위를 한 번에 매기는 방법, 선택지 최대 255개 |
| [Handling rate limits](https://docs.typesafe.ai/api#handling-rate-limits) | 429·529는 바로 다시 보내지 말고 점점 길게 기다렸다가 다시 시도 |

## 왜 Choice 질문 하나로 10개를 고르나요

JEV는 글을 만들어 내는 모델이 아니라 **정해진 형태의 결정**을 돌려주는 모델입니다.
Choice 질문은 답으로 "가장 맞는 선택지 하나"와 함께 **모든 선택지의 확률**을 돌려줍니다.
그래서 이모지 후보 232개를 선택지로 한 번에 보내고, 돌아온 확률이 높은 순서로 10개를 고르면 요청 한 번으로 10개를 추천할 수 있습니다.

- 선택지는 최대 255개라서 후보 목록을 232개로 맞췄습니다 (`EmojiCatalog.maxChoiceOptions`).
- 선택지 설명에는 이모지, 영어 뜻, 한국어 키워드를 함께 넣었습니다. JEV는 영어가 가장 정확하고 한국어도 처리합니다.
- 확률이 같으면 후보 목록 순서로 정렬합니다.

## 실제로 보내는 요청 (예시)

```json
{
  "model": "jev-latest",
  "state": {
    "text": "드디어 프로젝트 끝났다 다들 고생 많았어요",
    "kind": "text_near_cursor"
  },
  "questions": {
    "emoji": {
      "type": "choice",
      "instructions": "Which emoji best fits the feeling and topic of `text`, a sentence the user is writing right now? `text` may be Korean.",
      "criteria": {
        "tada": "🎉 celebration, congratulations, success (축하, 파티, 성공)",
        "clap": "👏 applause, well done (박수, 잘했어)",
        "...": "후보 232개"
      }
    }
  }
}
```

검색어로 추천할 때는 `kind`가 `search_query`가 되고, 질문 문장이 "검색어에 가장 맞는 이모지"로 바뀝니다.

## 돌아오는 응답 (예시 모양)

```json
{
  "model": "jev-1.13.0",
  "answers": {
    "emoji": {
      "type": "choice",
      "choice": "tada",
      "probabilities": { "tada": 0.41, "clap": 0.22, "...": 0.0 },
      "confidence": 0.63
    }
  },
  "usage": { "input_tokens": 6800, "output_tokens": 20 }
}
```

위 숫자는 모양을 보여 주기 위한 예시입니다.

## 오류 처리

| 상태 | 앱의 처리 |
| --- | --- |
| 200 | 확률 분포를 검사한 뒤 상위 10개 표시. 확률이 없거나 이상하면 오류로 처리하고 기본 이모지를 보여 주지 않음 |
| 401, 403 | "API 키를 확인해 주세요" + 설정 열기 버튼 |
| 400, 422 | "요청 형식이 맞지 않아요" + 오류 코드. 서버 오류 문장은 표시하지 않음 |
| 429, 529 | 0.5초, 1초 순서로 기다렸다가 최대 2번 다시 시도. `Retry-After` 헤더가 있으면 그 시간(최대 5초)을 따름. 그래도 실패하면 다시 시도 버튼 |
| 그 밖의 오류 | 상태 코드와 함께 다시 시도 버튼 |
| 네트워크 끊김, 15초 초과 | 원인과 다시 시도 버튼 |

## 비용 추정

- 요청 1번의 입력은 주로 후보 목록이라 약 6천~8천 토큰으로 **추정**합니다 (실제 값은 응답의 `usage.input_tokens`로 확인).
- `jev-1.13.0` 가격은 입력 100만 토큰당 0.042달러이고 출력 토큰은 무료입니다.
- 따라서 요청 1번은 약 0.0003달러 수준으로 추정합니다.

## API 키 처리

- 사용자가 설정 창에서 넣은 키를 맥의 로그인 키체인에 일반 암호 항목(`local.jevemoji.typesafe` / `api-key`)으로 저장합니다.
- 요청할 때마다 키체인에서 읽어 `Authorization` 헤더에만 넣습니다.
- 키는 소스 코드, 파일, 로그, 오류 메시지 어디에도 남지 않습니다.
