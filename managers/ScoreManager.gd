# ScoreManager for Fusion Mania
# Manages score tracking and ranking system
extends Node

const SAVE_FILE = "user://fusion_mania_scores.save"
const MAX_SCORES = 10
const MILESTONE_INTERVAL = 500  # Score increment per level

var high_scores: Array = []
var current_score: int = 0
var last_milestone_score: int = 0

# Signals for score events
signal score_changed(new_score: int)
signal high_score_achieved(score: int, rank: int)
signal milestone_crossed(level: int, milestones_crossed: int)

func _ready():
	load_scores()

# Load scores from file
func load_scores():
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)

		if file:
			var json_string		= file.get_as_text()
			file.close()

			var json			= JSON.new()
			var parse_result	= json.parse(json_string)

			if parse_result == OK:
				high_scores = json.data
				print("✅ Scores loaded: %d entries" % high_scores.size())
			else:
				print("❌ Error parsing scores file")
				initialize_empty_scores()
	else:
		print("ℹ️ No scores file found, creating new one")
		initialize_empty_scores()


# Save scores to file
func save_scores():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(high_scores))
		file.close()
		print("✅ Scores saved: %d entries" % high_scores.size())


# Initialize empty scores list
func initialize_empty_scores():
	high_scores = []
	save_scores()


# Check if score would be a new high score (first place)
func is_new_high_score(new_score: int):
	# First score
	if high_scores.is_empty():
		return true

	var current_best = high_scores[0].score

	return new_score > current_best


# Add new score and return its rank (1-based, 0 if not in top 10)
func add_score(new_score: int):
	var score_entry = {
		"score": new_score,
		"date": Time.get_datetime_string_from_system()
	}

	high_scores.append(score_entry)

	# Sort by score descending
	high_scores.sort_custom(_compare_scores)

	# Keep only top 10
	if high_scores.size() > MAX_SCORES:
		high_scores = high_scores.slice(0, MAX_SCORES)

	# Find position of new score
	for i in range(high_scores.size()):
		if high_scores[i].score == new_score and high_scores[i].date == score_entry.date:
			save_scores()
			high_score_achieved.emit(new_score, i + 1)
			return i + 1

	save_scores()

	# Not in top 10
	return 0


# Score comparison function for sorting
func _compare_scores(a: Dictionary, b: Dictionary):
	var score_a = a.get("score", 0)
	var score_b = b.get("score", 0)

	# Sort by score descending
	if score_a != score_b:
		return score_a > score_b

	# If scores identical, favor older entry (smaller date)
	var date_a = a.get("date", "")
	var date_b = b.get("date", "")

	return date_a < date_b  # Smaller date = older = better rank


# Get all scores
func get_high_scores():
	return high_scores


# Get rank preview of a score without adding it
func get_rank_preview(score: int):
	var temp_scores = high_scores.duplicate()
	temp_scores.append({"score": score})
	temp_scores.sort_custom(func(a, b): return a.score > b.score)

	for i in range(temp_scores.size()):
		if temp_scores[i].score == score and not temp_scores[i].has("date"):
			# Return rank only if in top 10
			if i < MAX_SCORES:
				return i + 1

	# Not in top 10
	return 0


# Clear all scores (complete reset)
func reset_all_scores():
	high_scores.clear()
	save_scores()

	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)
		print("✓ Deleted all scores")

	print("All scores have been cleared!")


# Initialize current game score
func start_game():
	current_score = 0
	last_milestone_score = 0
	score_changed.emit(current_score)


# Add to current score
func add_to_score(points: int):
	current_score += points

	# Check for milestones
	var current_level = current_score / MILESTONE_INTERVAL
	var previous_level = last_milestone_score / MILESTONE_INTERVAL

	if current_level > previous_level:
		var milestones_crossed = current_level - previous_level
		milestone_crossed.emit(current_level, milestones_crossed)
		last_milestone_score = current_score

	score_changed.emit(current_score)


# Get current score
func get_current_score():
	return current_score


# Get high score (first place)
func get_high_score():
	if high_scores.is_empty():
		return 0
	return high_scores[0].score


# Get rank of a score
func get_score_rank(score: int):
	for i in range(high_scores.size()):
		if high_scores[i].score == score:
			return i + 1
	return 0
