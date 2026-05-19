# Non-Goals — Facet-Level Negative Space

The second novel facet per research §4.2 (`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/leaddev-agent-compiled.md`
§3 articulates the broader risk; this facet closes
ambiguity at integration boundaries). For each of the
other seven facets, this document states what the facet
does NOT cover, so adopters and downstream readers can
tell where the framework's authority ends.

## Per-facet non-goals

### Architecture (`../architecture/`) does NOT cover

- A prescribed UML / ArchiMate / other diagramming
  notation. C4 + Structurizr DSL are RECOMMENDED, not
  REQUIRED.
- Code-level diagrams for the framework's own
  scripts/hooks. C4 Level 4 is "typically generated
  rather than authored" per
  `url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/c4-model.md` §3.
- A complete arc42 §6 Runtime View or §7 Deployment
  View for the framework itself (the framework is not
  a runtime service; deployment is documented in
  `../deployment/install.md`).

### Deployment (`../deployment/`) does NOT cover

- A specific operating system, container runtime, or
  CI/CD platform. Bash + Node + git is the runtime;
  any host that runs those suffices.
- Multi-tenancy concerns (no SaaS deployment shape).
- Continuous-deployment automation. The framework's
  release pattern is manual + tag + GitHub release.

### Behavior (`../behavior/`) does NOT cover

- HTTP API contracts for the framework itself (the
  framework has no API). OpenAPI is REQUIRED only for
  adopter products that ship HTTP APIs.
- Asynchronous-event contracts (AsyncAPI is
  RECOMMENDED for adopter products that ship event
  contracts; the framework has no events).
- GraphQL schemas.
- Performance / load contracts (those are quality
  scenarios in `../quality/`).

### Customization (`../customization/`) does NOT cover

- Adopter-product customization. K-1 through K-7
  describe how an adopter customises THEIR USE OF THE
  FRAMEWORK; the adopter's own product customization
  is THE ADOPTER'S customization facet, not the
  framework's.
- Customization knob discovery via runtime
  introspection. All knobs are declared statically in
  `knobs.schema.json`.

### Decisions (`../decisions/`) does NOT cover

- The MADR or Y-statements richer-template variants.
  The framework adopts Nygard's minimum template;
  adopters MAY use richer formats in their own repos.
- Pattern-language framing per Christopher Alexander
  (Nygard's allusion is metaphor, not commitment).
- Decisions about the adopter's product (those live
  in the adopter's own decisions facet).

### Quality (`../quality/`) does NOT cover

- Adopter-product quality requirements (those are
  THE ADOPTER'S quality facet).
- ISO 25010 / ASQ / Atlassian-style formal quality
  models. Quality scenarios per arc42 §10 are the
  framework's contract.
- Performance benchmarking. The framework is
  text-processing scripts; performance is not a
  load-bearing concern.

### Operations (`../operations/`) does NOT cover

- A runtime-service operating-model. The framework is
  static artefacts + scripts; there is no daemon to
  operate.
- Multi-region failover, traffic routing, capacity
  planning.
- Automatic remediation (the failure model is
  "fail loud, recover mechanically", not "self-heal").

## Cross-facet non-goals (framework as a whole)

- The framework does NOT prescribe a programming
  language for adopter products.
- The framework does NOT bundle an agent runtime;
  Claude Code, Codex, Gemini CLI, etc. are the
  runtimes; the framework is the operating-model the
  agent reads.
- The framework does NOT provide runtime libraries.
- The framework does NOT bind to a specific issue
  tracker; per the autonomous-issue-dispatch skill,
  the contract is tracker-agnostic.
- The framework does NOT provide automated
  remediation for adopter-product failures; the
  framework's lifecycle dispatches the work, the
  agent + owner execute it.
- The framework does NOT prescribe how adopter
  products are distributed; the sibling repo
  `agentic-installation-methodology` covers that
  methodology question separately.

## Why non-goals are first-class

Per research §4.2 (`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/leaddev-agent-compiled.md`
§3 risk surface), ambiguity for an installing agent
typically lives in what the spec DOESN'T say. By
enumerating non-goals per facet, this document closes
the inference surface — an installing agent reading the
framework's spec bundle can confirm what's deferred,
what's irrelevant, and what's adopter-owned.
