Feature: block-ai-attribution.sh rejects co-author trailers
  The framework's posture is that AI tools are inputs to your
  thinking, not credited authors. The hook enforces this at
  commit time.

  Background:
    Given the hook at hooks/block-ai-attribution.sh is installed
    And the hook intercepts Bash tool calls for `git commit`

  Scenario: Commit message with Co-Authored-By Claude trailer is blocked
    Given a commit message containing "Co-Authored-By: Claude"
    When the agent attempts `git commit -m "<message>"`
    Then the hook exits non-zero
    And the commit does not land

  Scenario: Commit message with Co-Authored-By GPT trailer is blocked
    Given a commit message containing "Co-Authored-By: GPT-4"
    When the agent attempts the commit
    Then the hook exits non-zero

  Scenario: Commit message that mentions Claude in prose is allowed
    Given a commit message body that says "CLAUDE.md updated to ..."
    And the message has no Co-Authored-By trailer
    When the agent attempts the commit
    Then the hook exits zero
    And the commit lands

  Scenario: Heredoc body that quotes a co-author trailer is allowed
    Given a commit message body that documents a rejected trailer pattern
    And the body wraps "Co-Authored-By:" in a code fence or quote
    When the agent attempts the commit
    Then the hook does not false-positive on the quoted text
