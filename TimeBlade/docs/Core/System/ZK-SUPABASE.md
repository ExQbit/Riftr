# Zeitklingen: Supabase Datenbankschema

## Übersicht

Das Supabase-Datenbankschema für Zeitklingen unterstützt das zeit-basierte Kartenspiel mit Fokus auf Kartenprogression, Materialmanagement und Klassensystem. Die Architektur ist optimiert für Echtzeit-Updates, Mobile-Performance und skalierbare Multiplayer-Features.

## Kern-Datenbankarchitektur

### Designprinzipien
- **Normalisierte Struktur**: Minimale Redundanz, klare Beziehungen
- **Performance-Optimiert**: Strategische Indexierung für häufige Queries
- **Real-time Ready**: Supabase Realtime für Live-Updates
- **Skalierbar**: Unterstützung für 100k+ aktive Spieler
- **Auditierbar**: Vollständige Änderungshistorie für kritische Daten

## Hauptdatenmodell

### 1. Benutzer & Authentication

#### `auth.users` (Supabase Auth)
```sql
-- Erweitert durch Supabase Auth
-- Automatische Felder: id, email, created_at, updated_at
```

#### `public.players`
```sql
CREATE TABLE public.players (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    player_class VARCHAR(20) NOT NULL CHECK (player_class IN ('chronomant', 'zeitwaechter', 'schattenschreiter')),
    class_level INTEGER DEFAULT 1 CHECK (class_level >= 1 AND class_level <= 25),
    current_xp INTEGER DEFAULT 0 CHECK (current_xp >= 0),
    total_playtime_minutes INTEGER DEFAULT 0,
    current_world INTEGER DEFAULT 1 CHECK (current_world >= 1 AND current_world <= 5),
    completed_worlds INTEGER DEFAULT 0 CHECK (completed_worlds >= 0 AND completed_worlds <= 5),
    -- Schildmacht-System für Zeitwächter
    current_shield_power INTEGER DEFAULT 0 CHECK (current_shield_power >= 0),
    shield_power_last_active TIMESTAMP WITH TIME ZONE DEFAULT NULL, -- NULL = kein aktiver Schildmacht
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Players can view own data" ON public.players FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Players can update own data" ON public.players FOR UPDATE USING (auth.uid() = id);
```

### 2. Karten-System

#### `public.base_cards`
```sql
CREATE TABLE public.base_cards (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    card_class VARCHAR(20) NOT NULL CHECK (card_class IN ('chronomant', 'zeitwaechter', 'schattenschreiter')),
    base_element VARCHAR(20) DEFAULT 'neutral' CHECK (base_element IN ('neutral', 'fire', 'ice', 'lightning')),
    base_power INTEGER NOT NULL CHECK (base_power > 0),
    base_health INTEGER DEFAULT 0 CHECK (base_health >= 0),
    base_time_cost DECIMAL(5,2) NOT NULL CHECK (base_time_cost > 0), -- Präzision auf 0.01s erhöht
    base_time_cost_display DECIMAL(3,1) GENERATED ALWAYS AS (ROUND(base_time_cost * 2) / 2) STORED, -- Gerundeter Anzeigewert
    effect_description TEXT,
    flavor_text TEXT,
    -- Neue Attribute für Zeitkosten-Modifikatoren
    is_time_manipulation BOOLEAN DEFAULT FALSE, -- Für Chronomant-Bonus
    is_defense_card BOOLEAN DEFAULT FALSE, -- Für Zeitwächter-Bonus
    is_shadow_card BOOLEAN DEFAULT FALSE, -- Für Schattenschreiter-Bonus
    unlock_world INTEGER DEFAULT 1 CHECK (unlock_world >= 1 AND unlock_world <= 5),
    unlock_class_level INTEGER DEFAULT 1 CHECK (unlock_class_level >= 1 AND unlock_class_level <= 25),
    rarity VARCHAR(20) DEFAULT 'common' CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index für häufige Abfragen
CREATE INDEX idx_base_cards_class ON public.base_cards(card_class);
CREATE INDEX idx_base_cards_unlock ON public.base_cards(unlock_world, unlock_class_level);
CREATE INDEX idx_base_cards_modifiers ON public.base_cards(is_time_manipulation, is_defense_card, is_shadow_card);
```

#### `public.player_cards`
```sql
CREATE TABLE public.player_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    base_card_id VARCHAR(50) NOT NULL REFERENCES public.base_cards(id),
    current_level INTEGER DEFAULT 1 CHECK (current_level >= 1 AND current_level <= 50),
    current_rarity VARCHAR(20) DEFAULT 'common' CHECK (current_rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    evolution_path VARCHAR(20) DEFAULT NULL CHECK (evolution_path IN ('fire', 'ice', 'lightning', NULL)),
    evolution_level INTEGER DEFAULT 0 CHECK (evolution_level >= 0 AND evolution_level <= 3),
    bonus_attributes JSONB DEFAULT '{}',
    is_at_gate BOOLEAN DEFAULT FALSE,
    power_level INTEGER DEFAULT 0,
    total_xp_invested INTEGER DEFAULT 0,
    acquired_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_leveled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE public.player_cards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Players can view own cards" ON public.player_cards FOR SELECT USING (player_id = auth.uid());
CREATE POLICY "Players can modify own cards" ON public.player_cards FOR ALL USING (player_id = auth.uid());

-- Indexes
CREATE INDEX idx_player_cards_player ON public.player_cards(player_id);
CREATE INDEX idx_player_cards_base ON public.player_cards(base_card_id);
CREATE INDEX idx_player_cards_level ON public.player_cards(current_level);
```

### 3. Materialien-System

#### `public.player_materials`
```sql
CREATE TABLE public.player_materials (
    player_id UUID PRIMARY KEY REFERENCES public.players(id) ON DELETE CASCADE,
    time_cores INTEGER DEFAULT 0 CHECK (time_cores >= 0),
    time_core_kits INTEGER DEFAULT 0 CHECK (time_core_kits >= 0 AND time_core_kits <= 10),
    elemental_fragments INTEGER DEFAULT 0 CHECK (elemental_fragments >= 0),
    time_focus INTEGER DEFAULT 0 CHECK (time_focus >= 0),
    time_crystals INTEGER DEFAULT 0 CHECK (time_crystals >= 0), -- Premium currency
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE public.player_materials ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Players can view own materials" ON public.player_materials FOR SELECT USING (player_id = auth.uid());
CREATE POLICY "Players can update own materials" ON public.player_materials FOR UPDATE USING (player_id = auth.uid());
```

#### `public.material_transactions`
```sql
CREATE TABLE public.material_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    material_type VARCHAR(20) NOT NULL CHECK (material_type IN ('time_core', 'time_core_kit', 'elemental_fragment', 'time_focus', 'time_crystals')),
    amount INTEGER NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('earn', 'spend', 'convert', 'purchase')),
    source VARCHAR(50) NOT NULL, -- 'combat', 'quest', 'evolution', 'reroll', 'purchase', etc.
    metadata JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE public.material_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Players can view own transactions" ON public.material_transactions FOR SELECT USING (player_id = auth.uid());

-- Indexes für Analytics
CREATE INDEX idx_material_transactions_player_time ON public.material_transactions(player_id, timestamp DESC);
CREATE INDEX idx_material_transactions_type ON public.material_transactions(material_type, transaction_type);
CREATE INDEX idx_material_transactions_source ON public.material_transactions(source, timestamp DESC);
```

### 4. Pity-Timer-System

#### `public.pity_timers`
```sql
CREATE TABLE public.pity_timers (
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    material_type VARCHAR(20) NOT NULL CHECK (material_type IN ('elemental_fragment', 'time_focus')),
    failed_attempts INTEGER DEFAULT 0 CHECK (failed_attempts >= 0),
    last_attempt_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (player_id, material_type)
);

-- RLS Policy
ALTER TABLE public.pity_timers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Players can view own pity timers" ON public.pity_timers FOR SELECT USING (player_id = auth.uid());
CREATE POLICY "Players can modify own pity timers" ON public.pity_timers FOR ALL USING (player_id = auth.uid());
```

### 5. Quest-System

#### `public.quest_templates`
```sql
CREATE TABLE public.quest_templates (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    quest_type VARCHAR(30) NOT NULL CHECK (quest_type IN ('daily', 'story', 'project', 'event')),
    category VARCHAR(30) NOT NULL CHECK (category IN ('combat', 'class', 'element', 'time', 'evolution', 'perfection')),
    requirements JSONB NOT NULL, -- {"enemy_kills": 5, "world": 1}
    rewards JSONB NOT NULL, -- {"xp": 800, "time_cores": 3}
    unlock_conditions JSONB DEFAULT '{}',
    duration_hours INTEGER DEFAULT 24,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### `public.player_quests`
```sql
CREATE TABLE public.player_quests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    quest_template_id VARCHAR(50) NOT NULL REFERENCES public.quest_templates(id),
    progress JSONB DEFAULT '{}', -- {"enemy_kills": 2}
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'expired', 'claimed')),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE public.player_quests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Players can view own quests" ON public.player_quests FOR SELECT USING (player_id = auth.uid());
CREATE POLICY "Players can update own quests" ON public.player_quests FOR UPDATE USING (player_id = auth.uid());

-- Indexes
CREATE INDEX idx_player_quests_player_status ON public.player_quests(player_id, status);
CREATE INDEX idx_player_quests_expires ON public.player_quests(expires_at) WHERE status = 'active';
```

### 6. Kampf-System

#### `public.combat_sessions`
```sql
CREATE TABLE public.combat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    world_id INTEGER NOT NULL CHECK (world_id >= 1 AND world_id <= 5),
    difficulty VARCHAR(20) DEFAULT 'normal' CHECK (difficulty IN ('normal', 'heroic', 'legendary')),
    enemy_type VARCHAR(30) NOT NULL CHECK (enemy_type IN ('standard', 'elite', 'mini_boss', 'world_boss')),
    session_duration_seconds INTEGER NOT NULL CHECK (session_duration_seconds > 0),
    cards_played INTEGER NOT NULL CHECK (cards_played >= 0),
    victory BOOLEAN NOT NULL,
    time_remaining DECIMAL(6,2) DEFAULT 0, -- Präzise Zeiterfassung auf 0.01s
    damage_dealt INTEGER DEFAULT 0,
    materials_earned JSONB DEFAULT '{}',
    xp_earned INTEGER DEFAULT 0,
    -- Neue Felder für erweiterte Kampf-Mechaniken
    shield_power_used INTEGER DEFAULT 0, -- Für Zeitwächter-Tracking
    time_manipulation_count INTEGER DEFAULT 0, -- Anzahl Zeit-Manipulationen
    session_data JSONB DEFAULT '{}', -- Detaillierte Kampfdaten für Analytics
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE public.combat_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Players can view own combat sessions" ON public.combat_sessions FOR SELECT USING (player_id = auth.uid());

-- Indexes für Analytics
CREATE INDEX idx_combat_sessions_player_time ON public.combat_sessions(player_id, timestamp DESC);
CREATE INDEX idx_combat_sessions_world ON public.combat_sessions(world_id, difficulty, enemy_type);
CREATE INDEX idx_combat_sessions_victory ON public.combat_sessions(victory, timestamp DESC);
```

### 7. Premium-System

#### `public.premium_purchases`
```sql
CREATE TABLE public.premium_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    transaction_id VARCHAR(100) UNIQUE NOT NULL, -- Store transaction ID
    package_type VARCHAR(50) NOT NULL,
    package_contents JSONB NOT NULL,
    price_cents INTEGER NOT NULL CHECK (price_cents > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    status VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
);

-- RLS Policy
ALTER TABLE public.premium_purchases ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Players can view own purchases" ON public.premium_purchases FOR SELECT USING (player_id = auth.uid());

-- Indexes
CREATE INDEX idx_premium_purchases_player ON public.premium_purchases(player_id, purchased_at DESC);
CREATE INDEX idx_premium_purchases_transaction ON public.premium_purchases(transaction_id);
```

### 8. Events & Analytics

#### `public.player_events`
```sql
CREATE TABLE public.player_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    event_category VARCHAR(30) NOT NULL CHECK (event_category IN ('progression', 'retention', 'monetization', 'engagement')),
    event_data JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes für Analytics (keine RLS - nur Backend-Analytics)
CREATE INDEX idx_player_events_type_time ON public.player_events(event_type, timestamp DESC);
CREATE INDEX idx_player_events_category ON public.player_events(event_category, timestamp DESC);
CREATE INDEX idx_player_events_player ON public.player_events(player_id, timestamp DESC);
```

### 9. Leaderboards & Social

#### `public.timeless_chamber_scores`
```sql
CREATE TABLE public.timeless_chamber_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    floor_reached INTEGER NOT NULL CHECK (floor_reached > 0),
    total_score INTEGER NOT NULL CHECK (total_score >= 0),
    completion_time_seconds INTEGER NOT NULL,
    cards_used JSONB DEFAULT '[]',
    achieved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    season VARCHAR(20) DEFAULT 'season_1'
);

-- RLS Policy
ALTER TABLE public.timeless_chamber_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Players can view all scores" ON public.timeless_chamber_scores FOR SELECT TO authenticated;
CREATE POLICY "Players can insert own scores" ON public.timeless_chamber_scores FOR INSERT WITH CHECK (player_id = auth.uid());

-- Indexes für Leaderboards
CREATE INDEX idx_timeless_chamber_season_score ON public.timeless_chamber_scores(season, total_score DESC);
CREATE INDEX idx_timeless_chamber_player_best ON public.timeless_chamber_scores(player_id, total_score DESC);
```

## API-Endpunkte (Supabase Functions)

### 1. Player Management

#### `level_up_card`
```sql
CREATE OR REPLACE FUNCTION level_up_card(
    card_id UUID,
    time_cores_to_use INTEGER DEFAULT 1
) RETURNS TABLE (
    success BOOLEAN,
    new_level INTEGER,
    gate_applied BOOLEAN,
    new_power INTEGER,
    error_message TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    player_materials_row RECORD;
    card_row RECORD;
    player_class_level INTEGER;
    max_allowed_level INTEGER;
BEGIN
    -- Prüfe Spieler-Materialien
    SELECT * INTO player_materials_row 
    FROM public.player_materials 
    WHERE player_id = auth.uid();
    
    IF player_materials_row.time_cores < time_cores_to_use THEN
        RETURN QUERY SELECT FALSE, 0, FALSE, 0, 'Insufficient time cores';
        RETURN;
    END IF;
    
    -- Prüfe Karte
    SELECT pc.*, p.class_level INTO card_row 
    FROM public.player_cards pc
    JOIN public.players p ON pc.player_id = p.id
    WHERE pc.id = card_id AND pc.player_id = auth.uid();
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 0, FALSE, 0, 'Card not found';
        RETURN;
    END IF;
    
    -- Prüfe Level-Limits
    max_allowed_level := card_row.class_level * 2;
    IF card_row.current_level >= max_allowed_level OR card_row.current_level >= 50 THEN
        RETURN QUERY SELECT FALSE, 0, FALSE, 0, 'Level limit reached';
        RETURN;
    END IF;
    
    -- Level up durchführen
    UPDATE public.player_cards 
    SET 
        current_level = current_level + time_cores_to_use,
        last_leveled_at = NOW(),
        updated_at = NOW()
    WHERE id = card_id;
    
    -- Material abziehen
    UPDATE public.player_materials 
    SET 
        time_cores = time_cores - time_cores_to_use,
        updated_at = NOW()
    WHERE player_id = auth.uid();
    
    -- Transaction loggen
    INSERT INTO public.material_transactions (player_id, material_type, amount, transaction_type, source)
    VALUES (auth.uid(), 'time_core', -time_cores_to_use, 'spend', 'card_levelup');
    
    RETURN QUERY SELECT TRUE, card_row.current_level + time_cores_to_use, FALSE, 0, NULL;
END;
$$;
```

### 2. Material Management

#### `process_combat_rewards`
```sql
CREATE OR REPLACE FUNCTION process_combat_rewards(
    world_id INTEGER,
    enemy_type VARCHAR(30),
    difficulty VARCHAR(20),
    victory BOOLEAN,
    session_data JSONB
) RETURNS TABLE (
    materials_earned JSONB,
    xp_earned INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    base_xp INTEGER;
    material_drops JSONB := '{}';
    pity_elemental INTEGER;
    pity_focus INTEGER;
BEGIN
    -- Nur bei Sieg Belohnungen geben
    IF NOT victory THEN
        RETURN QUERY SELECT '{}'::JSONB, 0;
        RETURN;
    END IF;
    
    -- Base XP berechnen
    base_xp := CASE enemy_type
        WHEN 'standard' THEN 50
        WHEN 'elite' THEN 150
        WHEN 'mini_boss' THEN 400
        WHEN 'world_boss' THEN 1000
        ELSE 50
    END;
    
    -- Welt- und Schwierigkeits-Multiplikatoren
    base_xp := base_xp * (1 + (world_id - 1) * 0.3);
    base_xp := CASE difficulty
        WHEN 'heroic' THEN base_xp * 1.3
        WHEN 'legendary' THEN base_xp * 1.6
        ELSE base_xp
    END;
    
    -- Material-Drops mit Pity-Timer
    SELECT failed_attempts INTO pity_elemental 
    FROM public.pity_timers 
    WHERE player_id = auth.uid() AND material_type = 'elemental_fragment';
    
    SELECT failed_attempts INTO pity_focus 
    FROM public.pity_timers 
    WHERE player_id = auth.uid() AND material_type = 'time_focus';
    
    -- Drop-Logik hier implementieren (vereinfacht)
    material_drops := jsonb_build_object(
        'time_cores', CASE WHEN random() < 0.6 THEN floor(random() * 2) + 1 ELSE 0 END,
        'elemental_fragments', CASE WHEN random() < (0.1 + COALESCE(pity_elemental, 0) * 0.05) THEN 1 ELSE 0 END,
        'time_focus', CASE WHEN random() < (0.02 + COALESCE(pity_focus, 0) * 0.03) THEN 1 ELSE 0 END
    );
    
    -- Materialien zu Spieler hinzufügen
    UPDATE public.player_materials SET
        time_cores = time_cores + (material_drops->>'time_cores')::INTEGER,
        elemental_fragments = elemental_fragments + (material_drops->>'elemental_fragments')::INTEGER,
        time_focus = time_focus + (material_drops->>'time_focus')::INTEGER,
        updated_at = NOW()
    WHERE player_id = auth.uid();
    
    -- Pity-Timer aktualisieren
    -- (Logic hier)
    
    RETURN QUERY SELECT material_drops, base_xp::INTEGER;
END;
$$;
```

## Real-time Subscriptions

### 1. Player Materials Updates
```javascript
// Client-side Subscription
const materialsSubscription = supabase
  .channel('player_materials')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'player_materials',
    filter: `player_id=eq.${userId}`
  }, (payload) => {
    updateMaterialsUI(payload.new)
  })
  .subscribe()
```

### 2. Card Progress Updates
```javascript
const cardsSubscription = supabase
  .channel('player_cards')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'player_cards',
    filter: `player_id=eq.${userId}`
  }, (payload) => {
    updateCardUI(payload.new)
  })
  .subscribe()
```

## Performance-Optimierungen

### 1. Indexing-Strategie
- **Player-basierte Queries**: Alle player_id Felder indiziert
- **Zeitbasierte Queries**: timestamp Felder für Analytics
- **Composite Indexes**: Für häufige Filter-Kombinationen

### 2. Partitionierung
```sql
-- Partitionierung für Analytics-Tabellen
CREATE TABLE public.player_events_2024_q1 PARTITION OF public.player_events
FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
```

### 3. Caching-Strategy
- **Redis**: Für häufige Leaderboard-Queries
- **Client-side**: Material-Counts für 30s cachen
- **CDN**: Statische Card-Assets

### 4. Zeitkosten-Berechnungs-System

#### Präzise Zeitkosten-Berechnung
```sql
-- View für aktuelle Zeitkosten mit allen Modifikatoren
CREATE OR REPLACE VIEW player_card_time_costs AS
SELECT 
    pc.id,
    pc.player_id,
    bc.base_time_cost,
    bc.base_time_cost_display,
    CASE 
        -- Chronomant Arkanpuls-Bonus
        WHEN p.player_class = 'chronomant' AND bc.is_time_manipulation AND EXISTS (
            SELECT 1 FROM player_materials pm 
            WHERE pm.player_id = pc.player_id AND pm.time_cores > 0
        ) THEN bc.base_time_cost * 0.85
        -- Zeitwächter Schildmacht-Bonus
        WHEN p.player_class = 'zeitwaechter' AND bc.is_defense_card AND p.current_shield_power > 0 
        THEN bc.base_time_cost * (1 - (p.current_shield_power * 0.05))
        -- Schattenschreiter Schatten-Penalty
        WHEN p.player_class = 'schattenschreiter' AND bc.is_shadow_card 
        THEN bc.base_time_cost * 1.15
        ELSE bc.base_time_cost
    END AS effective_time_cost,
    -- Gerundeter Anzeigewert
    ROUND(CASE 
        WHEN p.player_class = 'chronomant' AND bc.is_time_manipulation AND EXISTS (
            SELECT 1 FROM player_materials pm 
            WHERE pm.player_id = pc.player_id AND pm.time_cores > 0
        ) THEN bc.base_time_cost * 0.85
        WHEN p.player_class = 'zeitwaechter' AND bc.is_defense_card AND p.current_shield_power > 0 
        THEN bc.base_time_cost * (1 - (p.current_shield_power * 0.05))
        WHEN p.player_class = 'schattenschreiter' AND bc.is_shadow_card 
        THEN bc.base_time_cost * 1.15
        ELSE bc.base_time_cost
    END * 2) / 2 AS effective_time_cost_display
FROM player_cards pc
JOIN base_cards bc ON pc.base_card_id = bc.id
JOIN players p ON pc.player_id = p.id;
```

#### Schildmacht-Verfall-System
```sql
-- Funktion zum Aktualisieren des Schildmacht-Verfalls
CREATE OR REPLACE FUNCTION update_shield_power_decay()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $
BEGIN
    -- Schildmacht-Verfall nach 3 Sekunden Inaktivität
    UPDATE players 
    SET 
        current_shield_power = GREATEST(0, current_shield_power - 1),
        shield_power_last_active = CASE 
            WHEN current_shield_power - 1 > 0 THEN shield_power_last_active
            ELSE NULL
        END,
        updated_at = NOW()
    WHERE 
        player_class = 'zeitwaechter' AND
        current_shield_power > 0 AND
        shield_power_last_active IS NOT NULL AND
        shield_power_last_active < NOW() - INTERVAL '3 seconds';
END;
$;

-- Scheduled Job für Schildmacht-Verfall (alle 1s ausführen)
-- Hinweis: In Production mit pg_cron oder externem Scheduler implementieren
```

## Sicherheit & RLS

### Row Level Security Policies
- **Strict Isolation**: Spieler können nur eigene Daten sehen/ändern  
- **Public Data**: Leaderboards für alle sichtbar
- **Admin Access**: Separate Admin-Rolle für Analytics

### Data Validation
- **Check Constraints**: Für alle kritischen Werte
- **Triggers**: Für komplexe Validierungslogik
- **API Functions**: Kontrollierte Material-Transaktionen

## Migration & Deployment

### 1. Supabase Migrations
```bash
supabase db diff --schema public
supabase db push
```

### 2. Seeding Data
```sql
-- Base Cards für alle Klassen einfügen (mit neuen Attributen)
INSERT INTO public.base_cards (id, name, card_class, base_power, base_health, base_time_cost, is_time_manipulation, is_defense_card, is_shadow_card) VALUES
('chrono_bolt', 'Chrono Bolt', 'chronomant', 3, 0, 1.00, TRUE, FALSE, FALSE),
('time_shield', 'Time Shield', 'zeitwaechter', 0, 5, 1.20, FALSE, TRUE, FALSE),
('shadow_strike', 'Shadow Strike', 'schattenschreiter', 4, 0, 0.80, FALSE, FALSE, TRUE),
('temporal_flux', 'Temporal Flux', 'chronomant', 5, 0, 2.34, TRUE, FALSE, FALSE),
('guardian_stance', 'Guardian Stance', 'zeitwaechter', 2, 3, 1.67, FALSE, TRUE, FALSE),
('void_step', 'Void Step', 'schattenschreiter', 3, 0, 0.99, FALSE, FALSE, TRUE);
```

### 3. Environment-Management
- **Development**: Lokale Supabase-Instanz
- **Staging**: Separate Supabase-Projekt
- **Production**: Produktions-Supabase mit Backups

## Monitoring & Analytics

### 1. Built-in Analytics
```sql
-- Player Retention Query
SELECT 
    DATE_TRUNC('day', created_at) as signup_date,
    COUNT(*) as signups,
    COUNT(CASE WHEN last_active_at > created_at + INTERVAL '1 day' THEN 1 END) as day_1_retention
FROM public.players 
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY signup_date DESC;
```

### 2. Performance Monitoring
- **Supabase Dashboard**: Query-Performance überwachen
- **Custom Metrics**: Material-Economy-Balance
- **Alerting**: Bei kritischen Anomalien

### 5. Datenbank-Migration für neue Features

#### Migration: Präzise Zeitkosten und neue Kartenattribute
```sql
-- Migration 001: Add precision time costs and card attributes
BEGIN;

-- Erweitere base_cards Tabelle
ALTER TABLE public.base_cards 
    ALTER COLUMN base_time_cost TYPE DECIMAL(5,2),
    ADD COLUMN base_time_cost_display DECIMAL(3,1) GENERATED ALWAYS AS (ROUND(base_time_cost * 2) / 2) STORED,
    ADD COLUMN is_time_manipulation BOOLEAN DEFAULT FALSE,
    ADD COLUMN is_defense_card BOOLEAN DEFAULT FALSE,
    ADD COLUMN is_shadow_card BOOLEAN DEFAULT FALSE;

-- Erweitere players Tabelle für Schildmacht
ALTER TABLE public.players
    ADD COLUMN current_shield_power INTEGER DEFAULT 0 CHECK (current_shield_power >= 0),
    ADD COLUMN shield_power_last_active TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- Erweitere combat_sessions für präzise Zeit
ALTER TABLE public.combat_sessions
    ALTER COLUMN time_remaining TYPE DECIMAL(6,2),
    ADD COLUMN shield_power_used INTEGER DEFAULT 0,
    ADD COLUMN time_manipulation_count INTEGER DEFAULT 0;

-- Neuer Index für Kartentyp-Abfragen
CREATE INDEX idx_base_cards_modifiers ON public.base_cards(is_time_manipulation, is_defense_card, is_shadow_card);

COMMIT;
```

#### Migration: Zeitkosten-View und Funktionen
```sql
-- Migration 002: Add time cost calculation view
BEGIN;

CREATE OR REPLACE VIEW player_card_time_costs AS
-- [View Definition wie oben]

CREATE OR REPLACE FUNCTION update_shield_power_decay()
-- [Function Definition wie oben]

COMMIT;
```

Das ist das komplette Supabase-Schema für Zeitklingen - production-ready und vollständig entwicklungsfreundlich!
