# Functions for workflow-mode.sh that validate the workflow mode configuration,
# describe the active mode to the agent and find the modes that own a skill.
#
# Usage:
#   yq -o=json scripts/hooks/workflow-modes.yaml \
#     | jq -c -s -L scripts/hooks --args \
#       'include "workflow-mode"; config($ARGS.positional)' \
#       scripts/hooks/workflow-modes.yaml

# Pass the input through when the condition holds, otherwise stop with the message.
def require($ok; $message): if $ok then . else error($message) end;

# True when the input is a string that matches the pattern.
def token($pattern): type == "string" and test($pattern);

# Reject any key of the input mapping that is not in the allowed list.
def only($allowed; $where):
  ((keys - $allowed) | join(", ")) as $extra
  | require($extra == ""; "\($where): unknown key(s): \($extra). Allowed keys: \($allowed | join(", "))");

def mode_name_pattern: "^[a-z0-9][a-z0-9-]{0,39}$";

# Turn a skill pattern into an anchored regular expression. Validation allows
# only letters, digits, '.', '_', '-', '*' and '?', so only '.' needs escaping.
def pattern_to_regex: "^" + (gsub("\\."; "\\.") | gsub("\\*"; ".*") | gsub("\\?"; ".")) + "$";

# Input: one configuration document. Validate it on its own, so that every
# error names the file, and pass it through.
def check_document($file):
  "\($file): " as $at
  | require(type == "object"; "\($at)the file must be a mapping that starts with 'version: 1'")
  | only(["version", "default", "modes"]; "\($at)configuration")
  | require(.version == 1; "\($at)version must be 1")
  | require(.default == null or (.default | token(mode_name_pattern)); "\($at)default must be a mode name")
  | require((.modes // []) | type == "array"; "\($at)modes must be a list")
  | (reduce (.modes // [])[] as $mode (
      [];
      require($mode | type == "object"; "\($at)each mode must be a mapping")
      | require($mode.name | token(mode_name_pattern); "\($at)mode name \($mode.name | tojson) must use lower case ASCII letters, digits and '-', start with a letter or digit and have at most 40 characters")
      | require(index($mode.name) == null; "\($at)mode \($mode.name) is defined more than once")
      | ($mode | only(["name", "skills", "description"]; "\($at)mode \($mode.name)")) as $_
      | require(($mode.skills // []) | type == "array" and all(.[]; token("^[A-Za-z0-9._*?-]{1,100}$")); "\($at)mode \($mode.name): skills must be a list of skill name patterns that use only ASCII letters, digits, '.', '_', '-', '*' and '?'")
      | require(($mode.description // "") | type == "string"; "\($at)mode \($mode.name): description must be text")
      | . + [$mode.name]
    )) as $_
  | .;

# Input: an array of configuration documents, the loadout file first and the
# drop-in files after it in sorted order. $files holds their paths in the same
# order. A later mode with the same name overrides the fields it sets, a later
# 'default' wins. Output: {default, default_file, modes} with every field
# resolved.
def config($files):
  require(type == "array" and length == ($files | length); "the configuration documents and file names do not match")
  | . as $docs
  | reduce range(0; length) as $i (
      {default: null, default_file: null, order: [], by: {}};
      ($docs[$i] | check_document($files[$i])) as $doc
      | if $doc | has("default") then .default = $doc.default | .default_file = $files[$i] else . end
      | reduce ($doc.modes // [])[] as $mode (
          .;
          if .by[$mode.name] then . else .order += [$mode.name] end
          | .by[$mode.name] += $mode
        )
    )
  | . as $merged
  | {
      default,
      default_file,
      modes: [.order[] as $name | $merged.by[$name] | {name: $name, skills: (.skills // []), description: (.description // "")}]
    }
  | . as $config
  | require(.default == null or any(.modes[]; .name == $config.default);
      "\(.default_file): default '\(.default)' must name a defined mode, "
      + (if (.modes | length) == 0 then "but no modes are defined" else "which is one of: \([.modes[].name] | join(", "))" end));

# Input: the resolved configuration. The names of the modes that own the skill.
def owners($skill): [.modes[] | select(any(.skills[]; pattern_to_regex as $re | $skill | test($re))) | .name];

# Input: a list of skill patterns. The installed skills that match one, as
# [{name, user_only}], in the order of $installed.
def matching($installed): . as $patterns | [$installed[] | .name as $name | select(any($patterns[]; pattern_to_regex as $re | $name | test($re)))];

# Input: the resolved configuration. A mode as a list item, '- name: patterns'.
def summary: "- \(.name): \(.skills | join(", "))";

# Input: a list of names. The names quoted and joined as 'a', 'b' and 'c'.
def and_list: map("'\(.)'") | if length < 2 then join("") else (.[:-1] | join(", ")) + " and " + .[-1] end;

# Input: a list of skill patterns. The patterns joined with ',' and shortened
# with '...' after the last whole pattern that fits in $width characters.
def skills_cell($width):
  if (join(",") | length) <= $width then
    join(",")
  else
    (reduce .[] as $pattern (
      {text: "", full: false};
      if .full then
        .
      elif ((.text + (if .text == "" then "" else "," end) + $pattern) | length) + 4 <= $width then
        .text += (if .text == "" then "" else "," end) + $pattern
      else
        .full = true
      end
    ) | .text) as $text
    | if $text == "" then .[0][0:($width - 3)] + "..." else $text + ",..." end
  end;

# Input: the resolved configuration. The text that tells the agent about the
# active mode when a session or a subagent starts, or empty when no mode is
# defined. $state is how the mode was found, as printed by 'mode-state' in
# workflow-mode.sh, $value the mode name or the chosen value, and $installed
# the installed skills, as printed by 'installed-skills'.
def session_context($state; $value; $installed):
  if (.modes | length) == 0 then
    empty
  elif $state == "undefined" then
    "Workflow mode: the workflow mode chosen for this worktree, '\($value | gsub("[\u0000-\u001f]"; " ") | .[0:40])', is not defined, so no mode is enforced. The defined modes are: \([.modes[].name] | join(", ")). Tell the user, who can choose a mode with 'make workflow-use mode=<name>' or return to the default with 'make workflow-clear'. Do not run these commands yourself."
  elif $state == "unreadable" or $state == "not-a-file" then
    "Workflow mode: the workflow mode chosen for this worktree cannot be read, so no mode is enforced. Tell the user to run 'make workflow-status' to see why. Do not change the mode yourself."
  elif $state == "chosen" or $state == "default" then
    (.modes[] | select(.name == $value)) as $mode
    # A pattern the active mode also lists is allowed, so it is never shown as forbidden
    | [.modes[] | select(.name != $value) | .skills -= $mode.skills | select(.skills | length > 0) | summary] as $others
    # The agent cannot load these, so it may only suggest them
    | [$mode.skills | matching($installed)[] | select(.user_only) | "/\(.name)"] as $manual
    | "Workflow mode: '\($value)' is active in this worktree."
      + (if $mode.description == "" then "" else "\nDescription: \($mode.description)" end)
      + "\nSkills of this mode: \($mode.skills | join(", "))."
      + (if ($manual | length) == 0 then "" else "\nThe user starts these skills of this mode with slash commands: \($manual | join(", ")). Suggest the next one when it fits. Do not load them or read their SKILL.md files yourself." end)
      + (if ($others | length) == 0 then "" else "\nOther modes own these skills. Do not use them unless this mode also owns them:\n\($others | join("\n"))" end)
      + "\nSkills that no mode owns stay available. To change the mode, ask the user to run 'make workflow-use mode=<name>' and to start a new chat session. Do not run it yourself."
  else
    "Workflow mode: no workflow mode is active in this worktree. The modes and the skills they own:\n\([.modes[] | summary] | join("\n"))\nBefore you use a skill that a mode owns, ask the user to choose a mode with 'make workflow-use mode=<name>' and to start a new chat session. Do not run it yourself."
  end;

# Input: the resolved configuration. Why the skill is refused, or empty when the
# active mode may use it. $active is the active mode, never empty.
def deny_reason($skill; $active):
  owners($skill) as $owners
  | if ($owners | length) == 0 or ($owners | index($active)) then
      empty
    else
      "Workflow mode: the skill '\($skill)' belongs to the workflow \(if ($owners | length) == 1 then "mode" else "modes" end) \($owners | and_list), but '\($active)' is active in this worktree. This refusal applies even if this session started in another mode. Continue the task without this skill. If the user wants it, they can run "
      + (if ($owners | length) == 1 then "'make workflow-use mode=\($owners[0])'" else "'make workflow-use mode=<name>' with one of \($owners | join(", "))" end)
      + " and start a new chat session. Do not run that command yourself or read the skill's SKILL.md instead."
    end;

# Input: the resolved configuration. Lines for 'make workflow-list' about the
# installed skills: a pattern that matches none, and the skills of a mode that
# only the user can start, which the hook never sees. $installed is as for
# session_context.
def skill_notes($installed):
  .modes[] as $mode
  | ($mode.skills[] | select([.] | matching($installed) | length == 0)
      | "WARNING: mode \($mode.name): the pattern '\(.)' matches no skill in .github/skills."),
    ([$mode.skills | matching($installed)[] | select(.user_only)] | length | select(. > 0)
      | "Note: mode \($mode.name) owns \(.) skill\(if . == 1 then "" else "s" end) that only the user can start with a slash command, so the hook never checks \(if . == 1 then "it" else "them" end).");

# Input: the resolved configuration. What 'make workflow-status' prints for a
# usable state: the active mode with its description, skills, where it is set
# and how to change it, or why no mode is active. $state and $value are as
# printed by 'mode-state' in workflow-mode.sh.
def status_block($state; $value):
  def wrap($width):
    reduce split(" ")[] as $word (
      [];
      if length == 0 then [$word]
      elif ((.[-1] + " " + $word) | length) <= $width then .[-1] += " " + $word
      else . + [$word] end
    );
  # Rows fit 80 columns: a 15 character label column and 65 for the text
  def row($label; $text):
    ($text | wrap(65)) as $lines
    | "  \($label)\(" " * (13 - ($label | length)))\($lines[0])" + ($lines[1:] | map("\n" + (" " * 15) + .) | join(""));
  [.modes[].name] as $names
  | if $state == "chosen" or $state == "default" then
      (.modes[] | select(.name == $value)) as $mode
      | ($names - [$value]) as $others
      | ["Workflow mode: \($value) (\(if $state == "chosen" then "chosen for this worktree" else "default" end))"]
        + (if $mode.description == "" then [] else [row("Description"; $mode.description)] end)
        + [row("Skills"; if ($mode.skills | length) == 0 then "none" else $mode.skills | join(", ") end)]
        + [row("Set by";
            if $state == "default" then "default in \(.default_file)"
            elif .default then "make workflow-use (make workflow-clear returns to \(.default))"
            else "make workflow-use (make workflow-clear leaves no mode active)" end)]
        + (if ($others | length) == 0 then [] else [
            row("Other modes"; $others | join(", ")),
            row("To change"; "make workflow-use mode=\(if ($others | length) == 1 then $others[0] else "<name>" end), then start a new chat session")
          ] end)
    elif $state == "no-default" then
      [
        "Workflow mode: none",
        row("Why"; "no mode is chosen and no default is set"),
        row("Modes"; $names | join(", ")),
        row("To choose"; "make workflow-use mode=<name>, then start a new chat session")
      ]
    else
      [
        "Workflow mode: none",
        row("Why"; "no modes are defined"),
        row("To add"; "create scripts/config/workflow-modes.d/<name>.yaml, see https://github.com/stefaniuk/loadout/blob/main/docs/workflow-modes.md")
      ]
    end
  | join("\n");
