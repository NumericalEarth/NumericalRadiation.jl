using Documenter
using Literate
using NumericalRadiation

const DOCS_ROOT = @__DIR__
const REPO_ROOT = normpath(joinpath(DOCS_ROOT, ".."))
const LITERATE_ROOT = joinpath(REPO_ROOT, "examples")
const GENERATED_ROOT = joinpath(DOCS_ROOT, "src", "generated")
const ASSET_ROOT = joinpath(DOCS_ROOT, "src", "assets")

mkpath(GENERATED_ROOT)
mkpath(ASSET_ROOT)

for example in (
    "staged_ecckd_column.jl",
    "co2_forcing.jl",
    "rrtmgp_comparison.jl",
    "manabe_rce.jl",
    "all_sky_cre.jl",
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
        canonical = "https://NumericalEarth.github.io/NumericalRadiation.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Examples" => [
            "Single-column analytical radiation" => "single_column.md",
            "The staged interface" => "generated/staged_ecckd_column.md",
            "CO₂ forcing with ecCKD" => "generated/co2_forcing.md",
            "Correlated-k model spread" => "generated/rrtmgp_comparison.md",
            "Manabe radiative-convective equilibrium" => "generated/manabe_rce.md",
            "All-sky cloud radiative effect" => "generated/all_sky_cre.md",
        ],
        "Gas optics" => [
            "ecCKD files" => "gas_optics/ecckd_files.md",
            "ecCKD runtime workflow" => "gas_optics/ecckd_runtime_workflow.md",
            "Correlated-k method" => "gas_optics/correlated_k.md",
        ],
        "Solvers & schemes" => [
            "Radiative transfer" => "radiative_transfer.md",
            "Column solvers" => "solvers.md",
            "Cloud and aerosol optics" => "cloud_optics.md",
            "Longwave" => "longwave.md",
            "Shortwave" => "shortwave.md",
            "Notation" => "notation.md",
        ],
        "API reference" => [
            "Overview" => "api.md",
            "Staged runtime" => "api/staged_runtime.md",
            "ecCKD and data" => "api/ecckd.md",
            "Column schemes" => "api/column_schemes.md",
            "Metrics" => "api/metrics.md",
        ],
        "Architecture" => "architecture.md",
        "Validation" => "validation.md",
    ],
    checkdocs = :exports,
)

deploydocs(
    repo = "github.com/NumericalEarth/NumericalRadiation.jl.git",
    devbranch = "main",
    push_preview = true,
)
