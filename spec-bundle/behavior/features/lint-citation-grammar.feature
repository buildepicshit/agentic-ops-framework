Feature: Lint enforces citation grammar on SPEC artefacts
  Per Gherkin conventions
  (url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/cucumber-gherkin.md §3)
  and the schema's citation grammar at
  file://../../schema/SPEC.schema.md §2.

  Background:
    Given a repo with the framework's scripts/lint-spec.sh
    And the schema at spec-bundle/schema/SPEC.schema.md

  Scenario: Fact-bearing paragraph without citation prefix is rejected
    Given a SPEC.md whose §1 Problem section makes a factual claim
    And that claim has no citation prefix in scope
    When the author runs `bash scripts/lint-spec.sh <path>`
    Then the lint exits non-zero
    And stderr contains "fact-bearing paragraph lacks citation prefix"

  Scenario: Cited paragraph passes
    Given a SPEC.md whose §1 Problem cites a `file://` source
    When the author runs `bash scripts/lint-spec.sh <path>`
    Then the lint reports zero citation errors

  Scenario: Editorial framing with lint-ok marker is allowed
    Given a SPEC.md paragraph that is editorial cross-reference
    And the paragraph carries `<!-- lint-ok: no-citation -->`
    When the author runs `bash scripts/lint-spec.sh <path>`
    Then the lint reports zero citation errors for that paragraph

  Scenario: Lowercase RFC 2119 keyword in normative section is advisory
    Given a SPEC.md §7 Decision Statement using lowercase "must"
    When the author runs `bash scripts/lint-spec.sh <path>`
    Then the lint reports a warning (exit code 2)
    And the artefact MAY still pass owner approval after warning review
