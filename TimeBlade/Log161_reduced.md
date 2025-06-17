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


[HandController] PARALLAX: finger=(69.1), movement=-748.1, offset=175.5
UnityEngine.Debug:Log (object)
HandController:UpdateParallaxHandShift (UnityEngine.Vector2) (at Assets/UI/HandController.cs:2638)
HandController:HandleTouchMove (UnityEngine.Vector2) (at Assets/UI/HandController.cs:590)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:326)
HandController:Update () (at Assets/UI/HandController.cs:284)

[HandController] UpdateCardSelectionAtPosition - Looking for card at (69.07, 229.59), 1 raycast hits
UnityEngine.Debug:Log (object)
HandController:UpdateCardSelectionAtPosition (UnityEngine.Vector2) (at Assets/UI/HandController.cs:1772)
HandController:HandleTouchMove (UnityEngine.Vector2) (at Assets/UI/HandController.cs:594)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:326)
HandController:Update () (at Assets/UI/HandController.cs:284)

[HandController] PARALLAX: finger=(69.1), movement=-748.1, offset=175.5
UnityEngine.Debug:Log (object)
HandController:UpdateParallaxHandShift (UnityEngine.Vector2) (at Assets/UI/HandController.cs:2638)
HandController:HandleTouchMove (UnityEngine.Vector2) (at Assets/UI/HandController.cs:590)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:326)
HandController:Update () (at Assets/UI/HandController.cs:284)

[HandController] UpdateCardSelectionAtPosition - Looking for card at (69.07, 229.59), 1 raycast hits
UnityEngine.Debug:Log (object)
HandController:UpdateCardSelectionAtPosition (UnityEngine.Vector2) (at Assets/UI/HandController.cs:1772)
HandController:HandleTouchMove (UnityEngine.Vector2) (at Assets/UI/HandController.cs:594)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:326)
HandController:Update () (at Assets/UI/HandController.cs:284)

[EnemySpawner] Gegner gespawnt: TutorialEnemy(Clone) (#2)
UnityEngine.Debug:Log (object)
RiftEnemySpawner:SpawnEnemy () (at Assets/_Core/Enemy/RiftEnemySpawner.cs:149)
RiftEnemySpawner/<SpawnLoop>d__22:MoveNext () (at Assets/_Core/Enemy/RiftEnemySpawner.cs:107)
UnityEngine.SetupCoroutine:InvokeMoveNext (System.Collections.IEnumerator,intptr) (at /Users/bokken/build/output/unity/unity/Runtime/Export/Scripting/Coroutines.cs:17)

[RiftEnemy] Auto-added BoxCollider2D to TutorialEnemy(Clone) with default size
UnityEngine.Debug:Log (object)
RiftEnemy:EnsureColliderExists () (at Assets/_Core/Enemy/RiftEnemy.cs:82)
RiftEnemy:Initialize () (at Assets/_Core/Enemy/RiftEnemy.cs:118)
TutorialEnemy:Initialize () (at Assets/_Core/Enemy/Enemies/TutorialEnemy.cs:31)
RiftEnemy:Start () (at Assets/_Core/Enemy/RiftEnemy.cs:103)

[RiftCombat] Gegner registriert: TutorialEnemy(Clone) (Total: 3)
UnityEngine.Debug:Log (object)
RiftCombatManager:RegisterEnemy (RiftEnemy) (at Assets/_Core/BattleSystem/RiftCombatManager.cs:202)
RiftEnemy:Initialize () (at Assets/_Core/Enemy/RiftEnemy.cs:123)
TutorialEnemy:Initialize () (at Assets/_Core/Enemy/Enemies/TutorialEnemy.cs:31)
RiftEnemy:Start () (at Assets/_Core/Enemy/RiftEnemy.cs:103)

[HandController] Resetting hand offset to center (was: 175.5)
UnityEngine.Debug:Log (object)
HandController:AnimateHandToCenter () (at Assets/UI/HandController.cs:2672)
HandController:HandleTouchEnd () (at Assets/UI/HandController.cs:751)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:330)
HandController:Update () (at Assets/UI/HandController.cs:284)

[HandController] Animating hand container back to center
UnityEngine.Debug:Log (object)
HandController:AnimateHandToCenter () (at Assets/UI/HandController.cs:2690)
HandController:HandleTouchEnd () (at Assets/UI/HandController.cs:751)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:330)
HandController:Update () (at Assets/UI/HandController.cs:284)

[CardUI] SetTouchStartedOnValidArea called with: False
UnityEngine.Debug:Log (object)
CardUI:SetTouchStartedOnValidArea (bool) (at Assets/UI/CardUI.cs:929)
HandController:HandleTouchEnd () (at Assets/UI/HandController.cs:760)
HandController:HandleTouchInput () (at Assets/UI/HandController.cs:330)
HandController:Update () (at Assets/UI/HandController.cs:284)

[HandController] Updated base position for Schildschlag to (-160.00, 0.00, 0.00) after animation
UnityEngine.Debug:Log (object)
HandController/<>c__DisplayClass85_0:<UpdateCardLayout>b__0 () (at Assets/UI/HandController.cs:1345)
LeanTween:update () (at Assets/LeanTween/Framework/LeanTween.cs:440)
LeanTween:Update () (at Assets/LeanTween/Framework/LeanTween.cs:369)

[HandController] Updated base position for Zeitblock to (-80.00, 12.50, 0.00) after animation
UnityEngine.Debug:Log (object)
HandController/<>c__DisplayClass85_0:<UpdateCardLayout>b__0 () (at Assets/UI/HandController.cs:1345)
LeanTween:update () (at Assets/LeanTween/Framework/LeanTween.cs:440)
LeanTween:Update () (at Assets/LeanTween/Framework/LeanTween.cs:369)

[HandController] Updated base position for Schwertschlag to (0.00, 25.00, 0.00) after animation
UnityEngine.Debug:Log (object)
HandController/<>c__DisplayClass85_0:<UpdateCardLayout>b__0 () (at Assets/UI/HandController.cs:1345)
LeanTween:update () (at Assets/LeanTween/Framework/LeanTween.cs:440)
LeanTween:Update () (at Assets/LeanTween/Framework/LeanTween.cs:369)

[HandController] Updated base position for Schwertschlag to (80.00, 12.50, 0.00) after animation
UnityEngine.Debug:Log (object)
HandController/<>c__DisplayClass85_0:<UpdateCardLayout>b__0 () (at Assets/UI/HandController.cs:1345)
LeanTween:update () (at Assets/LeanTween/Framework/LeanTween.cs:440)
LeanTween:Update () (at Assets/LeanTween/Framework/LeanTween.cs:369)

[HandController] Updated base position for Zeitblock to (160.00, 0.00, 0.00) after animation
UnityEngine.Debug:Log (object)
HandController/<>c__DisplayClass85_0:<UpdateCardLayout>b__0 () (at Assets/UI/HandController.cs:1345)
LeanTween:update () (at Assets/LeanTween/Framework/LeanTween.cs:440)
LeanTween:Update () (at Assets/LeanTween/Framework/LeanTween.cs:369)

