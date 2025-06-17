[ShieldPower] System initialisiert
UnityEngine.Debug:Log (object)
ShieldPowerSystem:Initialize () (at Assets/_Core/Player/ShieldPowerSystem.cs:52)
ZeitwaechterPlayer:InitializePlayer () (at Assets/_Core/Player/ZeitwaechterPlayer.cs:86)
ZeitwaechterPlayer:Start () (at Assets/_Core/Player/ZeitwaechterPlayer.cs:77)

[Zeitwächter] Spieler initialisiert!
UnityEngine.Debug:Log (object)
ZeitwaechterPlayer:InitializePlayer () (at Assets/_Core/Player/ZeitwaechterPlayer.cs:91)
ZeitwaechterPlayer:Start () (at Assets/_Core/Player/ZeitwaechterPlayer.cs:77)

[HandController] Start - handContainer: HandContainer, cardUIPrefab: CardUIPrefab_Root
UnityEngine.Debug:LogWarning (object)
HandController:LogWarning (string,bool) (at Assets/UI/HandController.cs:144)
HandController:Start () (at Assets/UI/HandController.cs:156)

[HandController] Canvas gefunden: HUDCanvas, RenderMode: ScreenSpaceCamera
UnityEngine.Debug:Log (object)
HandController:SetupCanvasAndCamera () (at Assets/UI/HandController.cs:243)
HandController:Start () (at Assets/UI/HandController.cs:159)

[HandController] Canvas ist ScreenSpaceCamera - verwende Kamera: Main Camera
UnityEngine.Debug:Log (object)
HandController:SetupCanvasAndCamera () (at Assets/UI/HandController.cs:268)
HandController:Start () (at Assets/UI/HandController.cs:159)

[HandController] HandContainer scale: (1.00, 1.00, 1.00)
UnityEngine.Debug:LogWarning (object)
HandController:LogWarning (string,bool) (at Assets/UI/HandController.cs:144)
HandController:Start () (at Assets/UI/HandController.cs:169)

[HandController] ZeitwaechterPlayer.Instance found, subscribing to events
UnityEngine.Debug:Log (object)
HandController:LogInfo (string,bool) (at Assets/UI/HandController.cs:136)
HandController:Start () (at Assets/UI/HandController.cs:188)

[HandController] Using ONLY OnHandChanged -> UpdateHandDisplay (legacy events DISABLED)
UnityEngine.Debug:Log (object)
HandController:LogInfo (string,bool) (at Assets/UI/HandController.cs:136)
HandController:Start () (at Assets/UI/HandController.cs:193)

[HandController] Calling UpdateHandDisplay from Start
UnityEngine.Debug:Log (object)
HandController:LogInfo (string,bool) (at Assets/UI/HandController.cs:136)
HandController:Start () (at Assets/UI/HandController.cs:201)

=== ZEITKLINGEN GAMEPLAY-LOOP TEST ===
UnityEngine.Debug:Log (object)
RiftTestController:Start () (at Assets/_Core/GameManager/RiftTestController.cs:26)

Zeit-basiertes Kampfsystem - Spieler haben KEINE HP!
UnityEngine.Debug:Log (object)
RiftTestController:Start () (at Assets/_Core/GameManager/RiftTestController.cs:27)

=====================================
UnityEngine.Debug:Log (object)
RiftTestController:Start () (at Assets/_Core/GameManager/RiftTestController.cs:28)

[Test] Alle Systeme initialisiert
UnityEngine.Debug:Log (object)
RiftTestController:InitializeSystems () (at Assets/_Core/GameManager/RiftTestController.cs:81)
RiftTestController:Start () (at Assets/_Core/GameManager/RiftTestController.cs:31)

[Test] Starte Tutorial Rift...
UnityEngine.Debug:Log (object)
RiftTestController:StartTestRift () (at Assets/_Core/GameManager/RiftTestController.cs:111)

[RiftCombat] Starte Tutorial Rift...
UnityEngine.Debug:Log (object)
RiftCombatManager:StartRift (RiftTimeSystem/RiftType) (at Assets/_Core/BattleSystem/RiftCombatManager.cs:93)
RiftTestController:StartTestRift () (at Assets/_Core/GameManager/RiftTestController.cs:112)

[RiftCombat] State: Inactive → RiftStarting
UnityEngine.Debug:Log (object)
RiftCombatManager:ChangeState (RiftCombatManager/CombatState) (at Assets/_Core/BattleSystem/RiftCombatManager.cs:321)
RiftCombatManager:StartRift (RiftTimeSystem/RiftType) (at Assets/_Core/BattleSystem/RiftCombatManager.cs:95)
RiftTestController:StartTestRift () (at Assets/_Core/GameManager/RiftTestController.cs:112)

[RiftTimeSystem] Rift gestartet! Typ: Tutorial, Zeit: 90s
UnityEngine.Debug:Log (object)
RiftTimeSystem:StartRift (RiftTimeSystem/RiftType) (at Assets/_Core/TimeSystem/RiftTimeSystem.cs:87)
RiftCombatManager/<RiftStartSequence>d__36:MoveNext () (at Assets/_Core/BattleSystem/RiftCombatManager.cs:112)
UnityEngine.MonoBehaviour:StartCoroutine (System.Collections.IEnumerator)
RiftCombatManager:StartRift (RiftTimeSystem/RiftType) (at Assets/_Core/BattleSystem/RiftCombatManager.cs:96)
RiftTestController:StartTestRift () (at Assets/_Core/GameManager/RiftTestController.cs:112)

[RiftPointSystem] Rift initialisiert. Ziel: 100 Punkte für Boss-Spawn
UnityEngine.Debug:Log (object)
RiftPointSystem:InitializeRift (int) (at Assets/_Core/RiftSystem/RiftPointSystem.cs:71)
RiftCombatManager/<RiftStartSequence>d__36:MoveNext () (at Assets/_Core/BattleSystem/RiftCombatManager.cs:113)
UnityEngine.MonoBehaviour:StartCoroutine (System.Collections.IEnumerator)
RiftCombatManager:StartRift (RiftTimeSystem/RiftType) (at Assets/_Core/BattleSystem/RiftCombatManager.cs:96)
RiftTestController:StartTestRift () (at Assets/_Core/GameManager/RiftTestController.cs:112)

[ShieldPower] System initialisiert
UnityEngine.Debug:Log (object)
ShieldPowerSystem:Initialize () (at Assets/_Core/Player/ShieldPowerSystem.cs:52)
ZeitwaechterPlayer:PrepareForCombat () (at Assets/_Core/Player/ZeitwaechterPlayer.cs:121)
RiftCombatManager/<RiftStartSequence>d__36:MoveNext () (at Assets/_Core/BattleSystem/RiftCombatManager.cs:118)
UnityEngine.MonoBehaviour:StartCoroutine (System.Collections.IEnumerator)
--- MIDDLE CONTENT REMOVED FOR CLARITY ---
HandController:HandleTouchMove (UnityEngine.Vector2) (at Assets/UI/HandController.cs:594)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:326)
HandController:Update () (at Assets/UI/HandController.cs:284)

[HandController] Checking card 'Zeitblock' (index 0, sibling 4): localPoint=(-45.46, -28.42), inBounds=True, distance=53.61145
UnityEngine.Debug:Log (object)
HandController:UpdateCardSelectionAtPosition (UnityEngine.Vector2) (at Assets/UI/HandController.cs:1799)
HandController:HandleTouchMove (UnityEngine.Vector2) (at Assets/UI/HandController.cs:594)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:326)
HandController:Update () (at Assets/UI/HandController.cs:284)

[HandController] Selected topmost card: 'Zeitblock' with sibling index 4
UnityEngine.Debug:Log (object)
HandController:UpdateCardSelectionAtPosition (UnityEngine.Vector2) (at Assets/UI/HandController.cs:1820)
HandController:HandleTouchMove (UnityEngine.Vector2) (at Assets/UI/HandController.cs:594)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:326)
HandController:Update () (at Assets/UI/HandController.cs:284)

[CardUI] *** BLOCKING ONPOINTEREXIT - GLOBAL TOUCH ACTIVE *** for 'Zeitblock'
UnityEngine.Debug:LogError (object)
CardUI:OnPointerExit (UnityEngine.EventSystems.PointerEventData) (at Assets/UI/CardUI.cs:680)
UnityEngine.EventSystems.EventSystem:Update () (at ./Library/PackageCache/com.unity.ugui@03407c6d8751/Runtime/UGUI/EventSystem/EventSystem.cs:530)

[HandController] Fixing scale during layout for Zeitblock: (1.15, 1.15, 1.15)
UnityEngine.Debug:LogWarning (object)
HandController:UpdateCardLayout (bool,bool,CardUI) (at Assets/UI/HandController.cs:1266)
HandController:HandleTouchEnd () (at Assets/UI/HandController.cs:728)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:330)
HandController:Update () (at Assets/UI/HandController.cs:284)

[HandController] Hiding card preview
UnityEngine.Debug:Log (object)
HandController:HideCardPreview () (at Assets/UI/HandController.cs:2530)
HandController:HandleTouchEnd () (at Assets/UI/HandController.cs:745)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:330)
HandController:Update () (at Assets/UI/HandController.cs:284)

[HandController] Resetting hand offset to center (was: 174.3)
UnityEngine.Debug:Log (object)
HandController:AnimateHandToCenter () (at Assets/UI/HandController.cs:2689)
HandController:HandleTouchEnd () (at Assets/UI/HandController.cs:751)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:330)
HandController:Update () (at Assets/UI/HandController.cs:284)

[HandController] Animating hand container back to center
UnityEngine.Debug:Log (object)
HandController:AnimateHandToCenter () (at Assets/UI/HandController.cs:2707)
HandController:HandleTouchEnd () (at Assets/UI/HandController.cs:751)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:330)
HandController:Update () (at Assets/UI/HandController.cs:284)

[CardUI] SetTouchStartedOnValidArea called with: False
UnityEngine.Debug:Log (object)
CardUI:SetTouchStartedOnValidArea (bool) (at Assets/UI/CardUI.cs:929)
HandController:HandleTouchEnd () (at Assets/UI/HandController.cs:760)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:330)
HandController:Update () (at Assets/UI/HandController.cs:284)

[CardUI] Skipping base position update for Zeitblock - card is hovered
UnityEngine.Debug:Log (object)
CardUI:UpdateBasePosition (UnityEngine.Vector3) (at Assets/UI/CardUI.cs:1161)
HandController/<>c__DisplayClass85_0:<UpdateCardLayout>b__0 () (at Assets/UI/HandController.cs:1344)
LeanTween:update () (at Assets/LeanTween/Framework/LeanTween.cs:440)
LeanTween:Update () (at Assets/LeanTween/Framework/LeanTween.cs:369)

[HandController] Updated base position for Zeitblock to (-160.00, 0.00, 0.00) after animation
UnityEngine.Debug:Log (object)
HandController/<>c__DisplayClass85_0:<UpdateCardLayout>b__0 () (at Assets/UI/HandController.cs:1345)
LeanTween:update () (at Assets/LeanTween/Framework/LeanTween.cs:440)
LeanTween:Update () (at Assets/LeanTween/Framework/LeanTween.cs:369)

[HandController] Updated base position for Schwertschlag to (-80.00, 12.50, 0.00) after animation
UnityEngine.Debug:Log (object)
HandController/<>c__DisplayClass85_0:<UpdateCardLayout>b__0 () (at Assets/UI/HandController.cs:1345)
LeanTween:update () (at Assets/LeanTween/Framework/LeanTween.cs:440)
LeanTween:Update () (at Assets/LeanTween/Framework/LeanTween.cs:369)

[HandController] Updated base position for Schildschlag to (0.00, 25.00, 0.00) after animation
UnityEngine.Debug:Log (object)
HandController/<>c__DisplayClass85_0:<UpdateCardLayout>b__0 () (at Assets/UI/HandController.cs:1345)
LeanTween:update () (at Assets/LeanTween/Framework/LeanTween.cs:440)
LeanTween:Update () (at Assets/LeanTween/Framework/LeanTween.cs:369)

[HandController] Updated base position for Zeitblock to (80.00, 12.50, 0.00) after animation
UnityEngine.Debug:Log (object)
HandController/<>c__DisplayClass85_0:<UpdateCardLayout>b__0 () (at Assets/UI/HandController.cs:1345)
LeanTween:update () (at Assets/LeanTween/Framework/LeanTween.cs:440)
LeanTween:Update () (at Assets/LeanTween/Framework/LeanTween.cs:369)

[HandController] Updated base position for Schwertschlag to (160.00, 0.00, 0.00) after animation
UnityEngine.Debug:Log (object)
HandController/<>c__DisplayClass85_0:<UpdateCardLayout>b__0 () (at Assets/UI/HandController.cs:1345)
LeanTween:update () (at Assets/LeanTween/Framework/LeanTween.cs:440)
LeanTween:Update () (at Assets/LeanTween/Framework/LeanTween.cs:369)

[CardUI] *** ONPOINTEREXIT ALLOWED *** Mouse exit on 'Schwertschlag'
UnityEngine.Debug:LogError (object)
CardUI:OnPointerExit (UnityEngine.EventSystems.PointerEventData) (at Assets/UI/CardUI.cs:708)
UnityEngine.EventSystems.EventSystem:Update () (at ./Library/PackageCache/com.unity.ugui@03407c6d8751/Runtime/UGUI/EventSystem/EventSystem.cs:530)

