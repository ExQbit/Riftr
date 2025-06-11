# Zeitklingen: Unity Implementation Plan

This document outlines the step-by-step approach to building the Zeitklingen mobile card game in Unity, with a focus on breaking down tasks into manageable components that can be accomplished with AI assistance.

## Project Structure

```
Assets/
├── _Core/                       # Core systems and managers
│   ├── GameManager/             # Main game controller
│   ├── TimeSystem/              # Time mechanics
│   ├── SaveSystem/              # Player progress saving
│   └── AudioManager/            # Sound and music
│
├── Cards/                       # Card-related assets and scripts
│   ├── Base/                    # Base card classes
│   ├── Data/                    # Card definitions (ScriptableObjects)
│   │   ├── Chronomant/          # Mage class cards
│   │   ├── Zeitwachter/         # Warrior class cards
│   │   └── Schattenschreiter/   # Rogue class cards
│   ├── Evolution/               # Evolution system
│   ├── Rarity/                  # Rarity upgrade system
│   └── Visual/                  # Card visuals and effects
│
├── Combat/                      # Combat-related systems
│   ├── BattleManager/           # Main battle controller
│   ├── Effects/                 # Combat effects (DoT, slow, etc.)
│   └── FieldEffects/            # World-specific battle mechanics
│
├── Characters/                  # Player classes and enemies
│   ├── Player/                  # Player character classes
│   │   ├── Chronomant/          # Mage class
│   │   ├── Zeitwachter/         # Warrior class
│   │   └── Schattenschreiter/   # Rogue class
│   └── Enemies/                 # Enemy definitions and AI
│       ├── Standard/            # Regular enemies
│       ├── Elite/               # Elite enemies
│       └── Bosses/              # Boss enemies
│
├── Economy/                     # Game economy systems
│   ├── Materials/               # Material definitions
│   ├── Rewards/                 # Reward distribution
│   └── Shop/                    # In-game shop
│
├── UI/                          # User interface elements
│   ├── MainMenu/                # Main menu screens
│   ├── Battle/                  # Combat UI
│   ├── Card/                    # Card display and management
│   ├── Evolution/               # Evolution interface
│   └── Map/                     # World map and navigation
│
├── Worlds/                      # Game worlds and levels
│   ├── Tutorial/                # Tutorial level
│   ├── World1/                  # Zeitwirbel-Tal
│   ├── World2/                  # Flammen-Schmiede
│   ├── World3/                  # Eiszeit-Festung
│   ├── World4/                  # Gewittersphäre
│   ├── World5/                  # Chronos-Nexus
│   └── EndlessMode/             # Zeitlose Kammer (endless mode)
│
├── Resources/                   # General resources
│   ├── Prefabs/                 # Reusable prefabs
│   ├── Materials/               # Unity materials
│   └── Sprites/                 # General sprites
│
└── ThirdParty/                  # Third-party assets and plugins
```

## Implementation Roadmap

### 1. Core Game Loop Setup (First Priority)

#### 1.1 Create basic GameManager script
- [ ] Create script file structure
- [ ] Implement singleton pattern for global access
- [ ] Define game states enum (MainMenu, Battle, Map, etc.)
- [ ] Create methods for state transitions
- [ ] Add initialization logic
- [ ] Connect to UI state changes

#### 1.2 Implement TimeSystem foundation
- [ ] Create TimeManager script
- [ ] Implement 60-second countdown timer
- [ ] Add time consumption methods
- [ ] Create time gain/recovery methods
- [ ] Implement time manipulation mechanics (slow/speed)
- [ ] Add visual feedback for time changes

#### 1.3 Build simple UI framework
- [ ] Create canvas hierarchy for UI layers
- [ ] Design main menu layout
- [ ] Create battle UI with timer display
- [ ] Add card hand area
- [ ] Implement simple transitions between screens
- [ ] Create UI manager script

#### 1.4 Setup SaveSystem scaffold
- [ ] Create PlayerProgress class
- [ ] Define serializable data structures
- [ ] Implement basic save/load functionality
- [ ] Add auto-save triggers
- [ ] Create player preferences saving
- [ ] Test data persistence between sessions

### 2. Card System Foundation (Second Priority)

#### 2.1 Create base Card class
- [ ] Define Card ScriptableObject template
- [ ] Add core properties (name, cost, effects)
- [ ] Create card effect system
- [ ] Add card level properties
- [ ] Implement card rarity framework
- [ ] Setup evolution placeholders

#### 2.2 Implement 3-5 basic cards
- [ ] Create sample card scriptable objects
- [ ] Design simple card visual template
- [ ] Implement card prefab
- [ ] Add basic effect implementations
- [ ] Create card factory/loader
- [ ] Test cards in isolation

#### 2.3 Set up deck and hand management
- [ ] Create DeckManager class
- [ ] Implement card drawing mechanics
- [ ] Setup hand display and management
- [ ] Add card placement logic
- [ ] Implement discard pile
- [ ] Create deck building interface stub

#### 2.4 Design card interaction system
- [ ] Implement drag-and-drop mechanics
- [ ] Add card targeting system
- [ ] Create effect trigger framework
- [ ] Implement card validation (can play?)
- [ ] Add visual feedback for interactions
- [ ] Create card inspection view

### 3. Combat System Basics (Third Priority)

#### 3.1 Create BattleManager
- [ ] Setup battle initialization
- [ ] Implement turn structure
- [ ] Add win/loss conditions
- [ ] Create battle state machine
- [ ] Implement time system integration
- [ ] Add battle log system

#### 3.2 Implement basic enemy
- [ ] Create Enemy base class
- [ ] Design simple AI pattern system
- [ ] Implement basic attack logic
- [ ] Add enemy health/status display
- [ ] Create enemy factory
- [ ] Test enemy in battle context

#### 3.3 Set up combat effects system
- [ ] Create Effect class hierarchy
- [ ] Implement DoT (Damage over Time) system
- [ ] Add status effect framework
- [ ] Create buff/debuff system
- [ ] Implement effect visualization
- [ ] Add effect stacking mechanics

#### 3.4 Connect TimeSystem to Combat
- [ ] Implement time consumption for card play
- [ ] Add time-based enemy actions
- [ ] Create time steal mechanics
- [ ] Implement time recovery events
- [ ] Add critical time thresholds
- [ ] Create time manipulation feedback

### 4. Progression Systems (Fourth Priority)

#### 4.1 Implement card leveling
- [ ] Add XP and level properties to cards
- [ ] Create upgrade UI element
- [ ] Implement level-up mechanics
- [ ] Add stat scaling with levels
- [ ] Connect to SaveSystem
- [ ] Create visual level-up effects

#### 4.2 Create material system foundation
- [ ] Define material types (ScriptableObjects)
- [ ] Add inventory management
- [ ] Implement material acquisition
- [ ] Create material display UI
- [ ] Add material usage mechanics
- [ ] Connect to SaveSystem

#### 4.3 Set up evolution basics
- [ ] Implement evolution path templates
- [ ] Create evolution requirements system
- [ ] Design evolution UI
- [ ] Add evolution effects
- [ ] Implement material costs
- [ ] Connect to card system

### 5. First Playable Level (Fifth Priority)

#### 5.1 Build tutorial level flow
- [ ] Design tutorial sequence
- [ ] Implement tutorial manager
- [ ] Create guided battle
- [ ] Add tutorial prompts
- [ ] Implement forced actions
- [ ] Create tutorial completion tracking

#### 5.2 Set up world map navigation
- [ ] Create simple world map
- [ ] Add level selection
- [ ] Implement progress tracking
- [ ] Create world unlock system
- [ ] Add difficulty selection
- [ ] Connect to game progression

#### 5.3 Implement rewards system
- [ ] Create battle rewards screen
- [ ] Implement material drop tables
- [ ] Add card XP rewards
- [ ] Create special rewards
- [ ] Implement daily/weekly rewards
- [ ] Connect to progression systems

## Working With AI: Approach for Each Task

For each task, follow this process when working with AI assistance:

1. **Define data structures first**
   - Ask AI to help define classes, properties, and relationships
   - Example: "Help me define the properties and methods for the Card class in Unity"

2. **Request targeted script implementations**
   - Work on one script at a time
   - Example: "Let's implement the TimeManager.cs script that handles the 60-second timer"

3. **Start with functionality over visuals**
   - Use simple placeholder UI elements
   - Focus on making mechanics work before polishing

4. **Test frequently**
   - Implement small pieces and test before moving forward
   - Ask AI to help with debugging specific issues

5. **Use ScriptableObjects for data**
   - They're perfect for card data, enemies, levels, etc.
   - Example: "Help me create a CardData ScriptableObject to store card properties"

## Sample Task Breakdown: GameManager Implementation

```
Task: Create GameManager Script

1. Create folders:
   - Create Assets/_Core folder
   - Create Assets/_Core/GameManager folder

2. Create script:
   - Create GameManager.cs script in the GameManager folder

3. Implement singleton pattern:
   - Add static instance property
   - Create private Awake method
   - Implement DontDestroyOnLoad

4. Define game states:
   - Create GameState enum (MainMenu, Map, Battle, Evolution, Shop, etc.)
   - Add current state property
   - Create state change method with events

5. Add initialization:
   - Create initialization method
   - Set up references to other managers
   - Load player progress

6. Test implementation:
   - Create test scene
   - Add GameManager to scene
   - Verify singleton works across scene loads
```
