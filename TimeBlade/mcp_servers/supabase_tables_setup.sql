-- Zeitklingen Supabase Database Schema
-- This SQL script creates all necessary tables for the Zeitklingen card game

-- Cards table - stores all card definitions
CREATE TABLE IF NOT EXISTS cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('Chronomant', 'Zeitwächter', 'Schattenschreiter')),
    element TEXT NOT NULL CHECK (element IN ('Fire', 'Water', 'Air', 'Earth', 'Metal', 'Time')),
    base_cost INTEGER NOT NULL CHECK (base_cost >= 0),
    effect TEXT NOT NULL,
    evolution_level INTEGER NOT NULL DEFAULT 0 CHECK (evolution_level BETWEEN 0 AND 3),
    parent_card_id UUID REFERENCES cards(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Players table - stores player information
CREATE TABLE IF NOT EXISTS players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    last_login TIMESTAMP WITH TIME ZONE DEFAULT now(),
    account_level INTEGER DEFAULT 1
);

-- Player Cards - linking table for players and their cards
CREATE TABLE IF NOT EXISTS player_cards (
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
    level INTEGER NOT NULL DEFAULT 1 CHECK (level BETWEEN 1 AND 10),
    evolution_path TEXT,
    materials_used JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    PRIMARY KEY (player_id, card_id)
);

-- Materials table - stores all material definitions
CREATE TABLE IF NOT EXISTS materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    element TEXT NOT NULL CHECK (element IN ('Fire', 'Water', 'Air', 'Earth', 'Metal', 'Time', 'Universal')),
    rarity TEXT NOT NULL CHECK (rarity IN ('Common', 'Uncommon', 'Rare', 'Epic', 'Legendary')),
    effect TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Player Materials - linking table for players and their materials
CREATE TABLE IF NOT EXISTS player_materials (
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    material_id UUID REFERENCES materials(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    PRIMARY KEY (player_id, material_id)
);

-- Worlds table - stores world/level definitions
CREATE TABLE IF NOT EXISTS worlds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    element TEXT NOT NULL CHECK (element IN ('Fire', 'Water', 'Air', 'Earth', 'Metal', 'Time', 'Void')),
    primary_mechanic TEXT NOT NULL,
    description TEXT,
    difficulty_levels JSONB NOT NULL DEFAULT '["easy", "normal", "hard", "zeitriss"]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Player Progress - tracks player progress through worlds
CREATE TABLE IF NOT EXISTS player_progress (
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    world_id UUID REFERENCES worlds(id) ON DELETE CASCADE,
    completed BOOLEAN DEFAULT false,
    highest_difficulty TEXT DEFAULT 'easy',
    best_time INTEGER, -- in seconds
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    PRIMARY KEY (player_id, world_id)
);

-- Game Sessions - records gameplay metrics
CREATE TABLE IF NOT EXISTS game_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES players(id) ON DELETE SET NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    world_id UUID REFERENCES worlds(id) ON DELETE SET NULL,
    outcome TEXT CHECK (outcome IN ('win', 'loss', 'abandoned')),
    remaining_time INTEGER,
    cards_played JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- World Enemies - enemies in each world
CREATE TABLE IF NOT EXISTS world_enemies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    world_id UUID REFERENCES worlds(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    hp INTEGER NOT NULL CHECK (hp > 0),
    special_ability TEXT,
    deck_cards JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- World Drops - materials that can drop in each world
CREATE TABLE IF NOT EXISTS world_drops (
    world_id UUID REFERENCES worlds(id) ON DELETE CASCADE,
    material_id UUID REFERENCES materials(id) ON DELETE CASCADE,
    drop_rate FLOAT NOT NULL CHECK (drop_rate BETWEEN 0 AND 1),
    min_quantity INTEGER NOT NULL DEFAULT 1,
    max_quantity INTEGER NOT NULL,
    difficulty_required TEXT DEFAULT 'easy',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    PRIMARY KEY (world_id, material_id)
);

-- World Effects - special field effects for each world
CREATE TABLE IF NOT EXISTS world_effects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    world_id UUID REFERENCES worlds(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    effect_type TEXT NOT NULL CHECK (effect_type IN ('passive', 'triggered', 'timed')),
    effect_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Material Logs - logs of material acquisition and usage
CREATE TABLE IF NOT EXISTS material_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES players(id) ON DELETE SET NULL,
    changes JSONB NOT NULL,
    reason TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Player Stats - aggregate statistics about player performance
CREATE TABLE IF NOT EXISTS player_stats (
    player_id UUID PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
    total_games INTEGER DEFAULT 0,
    total_wins INTEGER DEFAULT 0,
    total_losses INTEGER DEFAULT 0,
    total_abandoned INTEGER DEFAULT 0,
    fastest_win INTEGER, -- in seconds
    cards_played INTEGER DEFAULT 0,
    favorite_card UUID REFERENCES cards(id),
    last_played TIMESTAMP WITH TIME ZONE
);

-- Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_cards_type ON cards(type);
CREATE INDEX IF NOT EXISTS idx_cards_element ON cards(element);
CREATE INDEX IF NOT EXISTS idx_cards_evolution_level ON cards(evolution_level);
CREATE INDEX IF NOT EXISTS idx_worlds_element ON worlds(element);
CREATE INDEX IF NOT EXISTS idx_game_sessions_player ON game_sessions(player_id);
CREATE INDEX IF NOT EXISTS idx_player_progress_completed ON player_progress(player_id, completed);
