# FPS Manager Flutter + HTML PoC

Flutter가 구단/선수/맵 선택을 관리하고 번들 HTML 경기 엔진을 Android WebView 또는 Flutter Web의 iframe에서 실행합니다. 참고 JSON의 오로라·크림슨 로스터와 로고/초상화를 표시하고, `MatchConfig`를 주입한 뒤 `match_end` 결과를 Flutter에 보관합니다.

```powershell
flutter pub get
flutter run -d <android-device-id>
flutter run -d chrome
```

Android는 로컬 에셋 WebView와 JavaScriptChannel을, Web은 `assets/assets/web/match/index.html`의 동일 출처 iframe과 `window.postMessage`를 사용합니다. iOS는 현재 스캐폴딩에 포함하지 않았습니다.

브리지 API: `initialize`, `initializeJson`, `start`, `pause`, `resume`, `setSpeed`, `getLiveState`, `getResult`, `getResultJson`. `service_ring`은 엔진의 `ring`으로 변환되며 결과에는 외부 ID가 유지됩니다.
