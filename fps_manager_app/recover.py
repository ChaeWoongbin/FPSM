import json

log_path = r"C:\Users\Chae\.gemini\antigravity-cli\brain\c906ae56-4526-4bca-853d-be38f3479494\.system_generated\logs\transcript_full.jsonl"
file_path = r"lib\league_dashboard_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    lines = f.read().split("\n")

with open(log_path, "r", encoding="utf-8") as f:
    for line in f:
        obj = json.loads(line)
        if obj.get("type") == "PLANNER_RESPONSE":
            for call in obj.get("tool_calls", []):
                if call["name"] == "replace_file_content" and call["args"].get("TargetFile", "").endswith("league_dashboard_screen.dart"):
                    args = call["args"]
                    start = args["StartLine"] - 1
                    end = args["EndLine"]
                    replacement = args["ReplacementContent"].split("\n")
                    
                    # Some replacements might not have exactly matched the lines, but assuming they worked:
                    # Let's just apply it.
                    lines = lines[:start] + replacement + lines[end:]

        if obj.get("type") == "PLANNER_RESPONSE":
            for call in obj.get("tool_calls", []):
                if call["name"] == "run_command" and "git restore" in call["args"].get("CommandLine", ""):
                    # Stop recovering once we hit the fatal git restore command!
                    print("Hit git restore, stopping recovery.")
                    with open("lib/league_dashboard_screen_recovered.dart", "w", encoding="utf-8") as out:
                        out.write("\n".join(lines))
                    exit(0)

with open("lib/league_dashboard_screen_recovered.dart", "w", encoding="utf-8") as out:
    out.write("\n".join(lines))
print("Done")
