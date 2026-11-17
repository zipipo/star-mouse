---
name: star-mouse-update
description: 유진이 동물실에서 한 작업(물 교체, 수컷 빼기, 출산, 분리, 사망·실험, 라벨 사진, 당번 엑셀)을 말하거나 사진·엑셀을 주고 STAR Mouse 사이트(zipipo.github.io/star-mouse)에 반영해달라고 할 때. 사이트 '현황 보내기' 내용을 받아 라벨·엑셀과 DOB로 맞춰보고, '작업 붙여넣기'용 JSON을 만들어 준다.
---

# STAR Mouse 작업 반영

사이트 데이터(Firestore)는 로그인해야 보이므로 클라우드 세션에서 직접 못 읽는다. 대신 사이트에 있는 두 버튼으로 주고받는다.

- **기록 탭 → `현황 보내기`**: 지금 cage·litter·최근 기록 120개를 JSON으로 복사 (두 버튼 모두 관리자 계정에만 보임)
- **기록 탭 → `작업 붙여넣기`**: Claude가 만든 JSON을 붙여넣고 미리보기 → 저장 (당번·관리자). 한 줄이라도 ✗면 저장 안 됨. 저장된 기록에는 `via:"붙여넣기"`가 붙고, 마지막에 `작업 붙여넣기` 기록(note)이 남는다.
- 크롬이 연결된 세션(데스크톱 앱 + Claude in Chrome)이면 사이트 콘솔에서 `starAgent.snapshot()`, `starAgent.preview(ops)`, `await starAgent.apply(ops, note)`를 바로 쓴다. 저장 전에 preview 결과를 유진에게 보여주고 확인받는다.
- `apply` 결과의 `undo`가 되돌리기 id다. 잘못 넣었으면 `await starAgent.undo(id)`로 그 저장 직전 상태로 돌린다 (그 cage를 그 뒤 다른 저장이 바꿨으면 막힘 → op로 직접 고침). snapshot events의 기록 id를 넣어도 같은 저장 묶음을 찾아 되돌린다. delEvent·editEvent는 되돌리기 대상이 아님.

## 사이트 화면 (유진이 동물실에서 보는 것)

- 첫 화면 **오늘 할 일**: 수컷 빼기(Mating D14~) · 출산 확인(Mating 시작 + 19일~, [출산 n마리]/[아직]/[출산 없음]) · 새끼 다시 세기(출산 D14, 다시 센 날은 `pups.cnt`) · 암수분리(출산 + 35일) · NTBC 교체(마지막 전체 교체 + 7일) · 인수인계 미확인 · 출산 기록 없는 새끼. 지난 일은 빨강으로 위에. [아직]은 `snooze`에 오늘 날짜로 남고 기록도 남는다.
- 같은 DOB cage 알파벳은 cage 창 [적었음]으로 `labW`에 남는다 (snapshot cages에는 안 나옴).
- 케이지 카드 제목은 라벨지처럼 **`♀ 26.04.06 / ♂ 26.06.21`** (Mating 중이면 데려온 수컷 DOB), cage id는 작게 아래. 같은 line에 같은 DOB cage가 여럿이면 `라벨에 1-D 적기`가 뜬다. 유진이 라벨 DOB로 말하면 검색칸(26.04.06 · 0406 · 4/6)으로 같은 cage를 찾게 하면 된다.
- 모든 저장은 첫 기록에 `chg`(바뀐 cage·litter 전후)가 붙고, 기록 없이 상태만 바뀌면 `상태 변경` 기록이 자동으로 남는다 (입력자 by 포함). 되돌리면 `되돌림` 기록(`undoOf`)이 남고 원래 기록은 줄을 그어 보인다. snapshot events 7번째 칸 `되돌림됨`이면 이미 되돌린 저장이니 다시 반영하지 않는다.

## 순서

1. 유진에게 **`현황 보내기` 내용 붙여넣기**를 먼저 요청한다 (cage id를 추측하지 않는다). 없으면 그것부터 받는다.
2. 라벨 사진·당번 엑셀·말로 한 작업을 snapshot과 맞춘다.
   - **실제 위치·출산 cage는 파란색 라벨지 기준** (파랑 = Mating·출산·실험 같은 특이사항 cage, 노랑 = FRG 일반, 분홍 = FAH 일반).
   - 라벨 `Cage No. M(7) − F(3)` = ♂ litter #7 × ♀ litter #3. 줄 그은 값은 이전 값, 옆에 쓴 값이 지금 값.
   - litter는 **DOB로** 판단한다: snapshot `litters`의 `[key, dob, mom, dad, 종료]`에서 같은 line·DOB를 찾는다. 같은 날 DOB가 둘이면 (예: FRG 12·13 둘 다 09-24) 엄마·마리수로 구분하고 애매하면 묻는다.
   - 당번 엑셀의 `#번호`는 사이트 litter 번호와 밀려 있을 수 있다 (예: 엑셀 #12 = 사이트 FRG 13). 번호 말고 DOB로 맞춘다.
3. 안 맞는 곳을 표로 짧게 보여주고, 판단이 필요한 것만 묻는다 (마리수, 어느 cage인지).
4. `작업 붙여넣기`용 JSON을 코드 블록 하나로 준다. 날짜는 실제 한 날 (`YYYY-MM-DD`), 미래 날짜는 안 됨.
5. 붙여넣고 미리보기에서 ✗가 나오면 그 줄을 받아서 고친다.

## JSON 형식

```json
{"note":"11/16 유진·재혁 물 교체, 수컷 빼기","ops":[
  {"op":"mateEnd","cage":"FRG 3-C","date":"2026-11-16"},
  {"op":"birth","cage":"FAH 2-B","date":"2026-11-11","n":5,"text":"D14에 재확인"}
]}
```

| op | 필드 | 하는 일 |
|---|---|---|
| `mateEnd` | cage, date | 수컷을 원래 cage(mate.from)로 돌려보내고 출산 대기로 |
| `birth` | cage, date, n?, unk?, text? | 새 litter 만들고 새끼 n. 작아서 못 셌으면 `"unk":true` (n은 대략, 생략 가능) |
| `birthUndo` | cage, date, wait?, text? | 출산 취소: 새끼(c.pups) 지우고 그 litter 삭제(분리된 cage 있으면 종료), 출산 대기로 되돌림. 대기 기준일은 출산 때 저장한 `fromWait`, 예전 기록(fromWait 없음)이면 `wait`(Mating 시작일) 필수 |
| `noBirth` | cage, date | 출산 대기 해제 |
| `mateStart` | cage, start, wait?, text? | Mating 시작일(또는 출산 대기 기준일) 고침. Mating·대기·새끼 다 없는 cage에 `"wait":true`면 start 기준으로 출산 대기를 새로 켬 |
| `ntbc` | date, scope (`"전체"` 또는 `"4마리↑"`), by?, text? | NTBC 교체: ntbcLog에 {date, scope, by} 추가 + NTBC 기록. by 생략하면 그 날짜 당번 2명 (예: `"유진·재혁"`) |
| `census` | cage, m?, f?, pups?, text?, date? | 실제 센 마리수로 맞춤 (실사). pups를 넣으면 `pups.cnt`에 그 날짜가 남아 '새끼 다시 세기' 할 일이 사라짐 |
| `death` / `exp` | cage, m?, f?, pups?, text, date | 빼기 (사망 / 실험) |
| `wean` | cage, date, rows:[{sx:"♂",n},{sx:"♀",n}] | 새끼 암수 분리 → 새 cage |
| `move` | cage, m?, f?, to ("new" 또는 cage id) | 이동 · 새 cage |
| `sex` | cage, mf? (♂→♀ 수), fm? (♀→♂ 수) | 성별 수정 |
| `memo` | cage, text | 메모 추가 |
| `litter` | litter, dob?, mom?, dad?, ended? | litter 정보 고침 (예: 엄마 litter 잘못) |
| `delEvent` | id, why | 잘못된 기록 삭제 (id는 snapshot events 첫 칸) |
| `editEvent` | id, date?/cage?/type?/text?, why | 기록 고침 |
| `log` | cage, type, text, date | 상태는 그대로, 기록만 남김 |

ops는 위에서부터 차례로 적용된다. 출산을 잘못 넣었으면 `birthUndo` 한 줄로 되돌린다 (원래 `출산` 기록은 남고 `출산 취소` 기록이 추가됨, 원래 기록까지 지우려면 `delEvent`). 출산을 다른 cage로 옮길 때는 `delEvent`(잘못된 출산 기록) + 잘못 붙은 새끼 정리(`census` pups 0 또는 `litter` ended) + 맞는 cage에 `birth` 순서로 쓴다. `delEvent`는 기록만 지우고 cage 상태는 안 바꾸니까 상태는 따로 op로 고친다.

## 규칙

- 출산 후 D14까지 cage 교체 금지라 새끼 수는 대략이다 → `text`에 "재확인 필요"를 넣고 D14 날짜를 알려준다.
- Mating 수컷은 2주(14일) 후 빼기, 출산 예정은 Mating 시작 + 19~21일.
- 모르는 건 지어내지 말고 묻는다. 확인 안 된 마리수는 넣지 않는다.
- 끝나면 `인수인계 엑셀`로 다음 번호를 받으라고 알려준다.
