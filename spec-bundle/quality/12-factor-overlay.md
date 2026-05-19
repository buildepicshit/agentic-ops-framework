# Quality — 12-Factor Overlay

Per the 12-factor methodology
(`file://../../research/primary-sources/12-factor.md`
§3). The framework itself is not a SaaS app, so this
overlay describes the per-factor posture for adopter
products operated under the framework — NOT the
framework's own internals.

| Factor | Title | Adopter posture under the framework |
|---|---|---|
| I | Codebase | One repo per product; the framework's `cross-repo-policy-enforcement` skill applies if the adopter operates a multi-repo fleet |
| II | Dependencies | Declared explicitly per `../deployment/requirements.md` |
| III | Config | Stored in environment per Factor III headline; the customization grammar (`../customization/`) extends this for application-domain knobs (Factor III only covers operating-system-boundary knobs) |
| IV | Backing Services | Adopter-specific; the framework is agnostic |
| V | Build, Release, Run | The framework's spec lifecycle (Preflight → … → Verify → Report+Close) is the release pattern; build artefacts are adopter-specific |
| VI | Processes | Adopter-specific; the framework does not impose stateless-process semantics |
| VII | Port Binding | Adopter-specific |
| VIII | Concurrency | Adopter-specific |
| IX | Disposability | The hook test harness's hermetic sandbox pattern (`../../tests/hooks/run-tests.sh`) exemplifies disposability for tests; adopters apply the same posture to their own test harnesses |
| X | Dev/Prod Parity | Adopter-specific; the framework's mechanical-verifiability quality goal supports it |
| XI | Logs | Adopter-specific; the framework's `session-start-context.sh` hook emits structured context as a per-session log |
| XII | Admin Processes | Adopter-specific |

## Scope

The framework's role in 12-factor adoption is
**operating-model**, not **runtime**. Adopters who want
12-factor conformance for their products combine:

- The framework's discipline (spec-first, citation
  grammar, lifecycle, hooks).
- Their language/runtime-specific 12-factor tooling
  (env-var libs, process supervisors, log routers,
  etc.).

The framework does NOT bundle 12-factor tooling. See
also `../non-goals/INDEX.md` Q "the framework does not
provide runtime libraries."
