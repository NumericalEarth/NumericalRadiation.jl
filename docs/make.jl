using Documenter
using Literate
using NumericalRadiation

const DOCS_ROOT = @__DIR__
const REPO_ROOT = normpath(joinpath(DOCS_ROOT, ".."))
const LITERATE_ROOT = joinpath(REPO_ROOT, "examples", "literate")
const GENERATED_ROOT = joinpath(DOCS_ROOT, "src", "generated")
const ASSET_ROOT = joinpath(DOCS_ROOT, "src", "assets")

mkpath(GENERATED_ROOT)
mkpath(ASSET_ROOT)

for example in (
    "01_ckdmip_data_inventory.jl",
    "02_staged_ecckd_column.jl",
    "03_rrtmgp_validation_report.jl",
    "04_training_recovery_report.jl",
)
    Literate.markdown(
        joinpath(LITERATE_ROOT, example),
        GENERATED_ROOT;
        documenter = true,
        execute = true,
        credit = true,
    )
end

makedocs(
    sitename = "NumericalRadiation.jl",
    modules = [NumericalRadiation],
    authors = "NumericalEarth organization and contributors",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://NumericalEarth.github.io/AnalyticBandRadiation.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Architecture" => "architecture.md",
        "Radiative transfer" => "radiative_transfer.md",
        "Gas optics" => [
            "ecCKD files" => "gas_optics/ecckd_files.md",
            "ecCKD runtime workflow" => "gas_optics/ecckd_runtime_workflow.md",
            "ecCKD model selection" => "gas_optics/ecckd_model_selection.md",
            "Correlated-k method" => "gas_optics/correlated_k.md",
            "CKDMIP training data" => "gas_optics/ckdmip_training_data.md",
            "RRTMGP comparison" => "gas_optics/rrtmgp_comparison.md",
            "Training and recovery" => "gas_optics/ecckd_training_recovery.md",
        ],
        "Longwave" => "longwave.md",
        "Shortwave" => "shortwave.md",
        "Examples" => [
            "Single-column examples" => "single_column.md",
            "CKDMIP inventory" => "generated/01_ckdmip_data_inventory.md",
            "Staged ecCKD column" => "generated/02_staged_ecckd_column.md",
            "RRTMGP validation report" => "generated/03_rrtmgp_validation_report.md",
            "Training recovery report" => "generated/04_training_recovery_report.md",
            "Breeze integration" => "gas_optics/breeze_integration.md",
        ],
        "Notation" => "notation.md",
        "API reference" => [
            "Overview" => "api.md",
            "Staged runtime" => "api/staged_runtime.md",
            "ecCKD and data" => "api/ecckd.md",
            "Column schemes" => "api/column_schemes.md",
            "Metrics" => "api/metrics.md",
        ],
    ],
    warnonly = [:missing_docs, :cross_references],
)

deploydocs(
    repo = "github.com/NumericalEarth/AnalyticBandRadiation.jl.git",
    devbranch = "main",
    push_preview = true,
)
