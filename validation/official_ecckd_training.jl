include(joinpath(@__DIR__, "validation_results.jl"))

const OFFICIAL_TRAINING_JSON = validation_results_path("official_ecckd_training.json")
const OFFICIAL_TRAINING_MD = validation_results_path("official_ecckd_training.md")

# The committed official_ecckd_training artifact is frozen evidence.
#
# It was produced by the deterministic multi-stage greedy optimizer chain
# (reduced_ecckd_optimization_preflight.jl), which was demoted and deleted on
# 2026-07-18: the chain reduced the objective but plateaued at a final
# objective / hard target ratio of ~8.605 on the official 48-parameter path
# and never approached the gate (see validation/FROZEN_DIAGNOSTICS.md). The
# artifact keeps "status": "partial" and remains the recorded completion
# blocker for the gas-optics training gate until the recovered Reactant/Enzyme
# training pipeline recovers a published model quantitatively; that recovery
# work is owned by the published-recovery scripts
# (ecckd_published_recovery_vector_training.jl,
# ckdmip_original_objective_ad_batch.jl), not by this file.
#
# The producing scripts and their full optimizer logs are preserved on the
# archived ref `audit-trail-2026-07-17` (branch `audit-trail-pre-cleanup`).
function main()
    isfile(OFFICIAL_TRAINING_JSON) && isfile(OFFICIAL_TRAINING_MD) ||
        error("official_ecckd_training artifacts are frozen evidence produced by the " *
              "demoted greedy optimizer chain; recover them from the archived ref " *
              "audit-trail-2026-07-17 (branch audit-trail-pre-cleanup)")
    println("official_ecckd_training artifact is frozen evidence; keeping committed " *
            "artifact at $OFFICIAL_TRAINING_JSON")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
