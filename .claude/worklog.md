# STAR Mouse 작업 기록

## 2026-11-16 · 출산 취소, NTBC 날짜·당번, op 추가 (claude/trusting-knuth-5osxwq)

- 출산 기록 때 `c.pups.fromWait`에 출산 직전 대기 기준일 저장 (대기 없이 Mating 중 출산이면 Mating 시작일).
- cage 메뉴 번식 줄에 `출산 취소` 버튼 (새끼 있는 cage만). 새끼 지우고 litter는 분리된 cage가 없으면 삭제, 있으면 종료 표시. `c.wait = fromWait`, 예전 기록이면 Mating 시작일 칸을 직접 채워야 저장됨 (출산일 이후·미래 날짜 막음). 기록 타입 `출산 취소`, cage의 출산 이력에도 보임.
- NTBC 창: 날짜칸 max=오늘, 저장 시 events에도 고른 날짜 들어감 (기존엔 저장한 날로 찍힘). `누가` 칸 추가, 기본값은 고른 날짜의 당번 2명 (`pairOn(date)`), ntbcLog.by에 저장, 기록 text는 `전체 · 유진·재혁`.
- starAgent OPS: `birthUndo`, `ntbc` 추가. `mateStart`에 `wait:true`(빈 cage에 출산 대기 켜기), start 형식·미래 날짜 검사 추가.
- 인수인계 엑셀 Plan에 `출산 취소`, `출산 대기` 포함.
- 확인: 데모 모드(?demo) 390px Playwright로 버튼 노출, 날짜 막기, op 미리보기·저장 결과 확인. 실제 Firestore 저장은 아직 확인 안 함 (배포 후 한 번 출산→취소 해보기).
