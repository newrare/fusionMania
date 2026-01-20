# Context: Global Managers

## 📋 Overview
Managers are singletons (AutoLoad) that handle global game systems.

---

## 🎵 AudioManager

### Responsibilities
- Background music management
- Sound effects management
- Mute/unmute music and SFX
- Save audio preferences

### Available Sounds
```gdscript
sounds = {
    "music_background":  "res://assets/sounds/music_background.mp3",
    "sfx_move":         "res://assets/sounds/sfx_move.wav",
    "sfx_fusion":       "res://assets/sounds/sfx_fusion.wav",
    "sfx_power":        "res://assets/sounds/sfx_power.wav",
    "sfx_game_over":    "res://assets/sounds/sfx_game_over.mp3",
    "sfx_win":          "res://assets/sounds/sfx_win.mp3",
    "sfx_button_hover": "res://assets/sounds/sfx_button_hover.wav",
    "sfx_button_click": "res://assets/sounds/sfx_button_click.wav"
}
```

### Main Methods
```gdscript
# Playback
play_sfx_move()
play_sfx_fusion()
play_sfx_power()
play_sfx_button_hover()
play_sfx_button_click()
play_sfx_game_over()
play_sfx_win()

# Controls
toggle_music()
toggle_sfx()
is_music_enabled() -> bool
is_sfx_enabled() -> bool

# System
cleanup()  # Important to avoid leaks
```

### Configuration File
`user://audio_settings.cfg`
```ini
[audio]
music_muted = false
sfx_muted = false
```

---

## 🌍 LanguageManager

### Responsibilities
- FR/EN translation management
- Dynamic language switching
- Save language preference

### Signal
```gdscript
signal language_changed
```

### Available Languages
- `fr`: French
- `en`: English

### Main Translation Keys
```gdscript
# Menu
"START", "RESUME", "RANKING", "OPTIONS", "PAUSE", "QUIT", "BACK"

# Game
"SCORE", "HIGH_SCORE", "MOVES", "GAME_OVER", "VICTORY", "FINAL_SCORE"

# Audio
"MUSIC_ACTIVE", "MUSIC_INACTIVE", "SFX_ACTIVE", "SFX_INACTIVE"

# Language
"LANGUAGE", "FRENCH", "ENGLISH"

# Powers (20 total)
"POWER_FIRE_HORIZONTAL", "POWER_FIRE_VERTICAL", "POWER_FIRE_CROSS"
"POWER_BOMB", "POWER_ICE", "POWER_SWITCH_HORIZONTAL", ...
```

### Main Methods
```gdscript
set_language(lang: String)
get_current_language() -> String
toggle_language(lang: String)
```

### Code Usage
```gdscript
# Get translation
var text = tr("START")  # Returns "Start" if language = en

# Listen to language changes
LanguageManager.language_changed.connect(_on_language_changed)
```

### Configuration File
`user://language_settings.cfg`
```ini
[language]
current = "en"
```

---

## 🏆 ScoreManager

### Responsibilities
- Current score management
- High scores saving (top 10)
- Milestone detection
- Score ranking

### Signals
```gdscript
signal score_changed(new_score: int)
signal high_score_achieved(score: int, rank: int)
signal milestone_crossed(level: int, milestones_crossed: int)
```

### Constants
```gdscript
const SAVE_FILE = "user://fusion_mania_scores.save"
const MAX_SCORES = 10
const MILESTONE_INTERVAL = 500  # Score per milestone
```

### Score Structure
```gdscript
{
    "score": 1500,
    "date": "2026-01-20T10:30:00"
}
```

### Main Methods
```gdscript
# Current score management
start_game()                    # Reset score to 0
add_to_score(points: int)       # Add points
get_current_score() -> int

# High scores
add_score(score: int) -> int    # Returns rank (1-10 or 0)
get_high_scores() -> Array
get_high_score() -> int         # Best score
is_new_high_score(score: int) -> bool

# Utilities
get_rank_preview(score: int) -> int
get_score_rank(score: int) -> int
reset_all_scores()              # Clear all
```

### Save File
`user://fusion_mania_scores.save`
```json
[
    {"score": 2048, "date": "2026-01-20T10:30:00"},
    {"score": 1024, "date": "2026-01-19T15:22:10"},
    ...
]
```

---

## 🔧 project.godot Configuration

```ini
[autoload]
AudioManager="*res://managers/AudioManager.gd"
LanguageManager="*res://managers/LanguageManager.gd"
ScoreManager="*res://managers/ScoreManager.gd"
```

---

## 💡 Best Practices

### Accessing Managers
```gdscript
# From anywhere in code
AudioManager.play_sfx_fusion()
LanguageManager.set_language("fr")
ScoreManager.add_to_score(10)
```

### Listening to Signals
```gdscript
func _ready():
    ScoreManager.score_changed.connect(_on_score_changed)
    LanguageManager.language_changed.connect(_update_ui)

func _on_score_changed(new_score: int):
    score_label.text = str(new_score)
```

### Cleanup
```gdscript
# AudioManager handles cleanup automatically
# But if manual cleanup needed:
AudioManager.cleanup()
```

---

## 🐛 Debug

### Verify Managers
```gdscript
func _ready():
    print("AudioManager ready: ", AudioManager != null)
    print("LanguageManager ready: ", LanguageManager != null)
    print("ScoreManager ready: ", ScoreManager != null)
```

### Useful Logs
- AudioManager: `🎵`, `🔇`, `✅`, `❌`
- LanguageManager: `✅`, `ℹ️`, `❌`
- ScoreManager: `✅`, `ℹ️`, `✓`
