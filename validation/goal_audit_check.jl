include(joinpath(@__DIR__, "validation_results.jl"))

using Dates

const ABR_ROOT = normpath(joinpath(@__DIR__, ".."))
const BREEZE_ROOT = normpath(joinpath(ABR_ROOT, "..", "BreezeRadiativeHeatingDev", "Breeze.jl"))
const EXPECTED_BREEZE_SHA = "8a3dba0575a7b8c29cb8dfedc5fe391cab7d2938"
const EXPECTED_BREEZE_REMOTE = "https://github.com/NumericalEarth/Breeze.jl"

const GOAL_STEPS = (
    (
        name = "cloudless official ecCKD ecRad accuracy",
        definition = "Pass hard cloudless/no-aerosol ecRad thresholds with official ecCKD inputs.",
        status = "passed",
    ),
    (
        name = "32-g ecCKD/RRTMGP-compatible gas optics",
        definition = "Use the validated official ecCKD 32-g production model, freeze the 16-g model as a diagnostic, and emit direct RRTMGP comparison metrics on the same column ensemble.",
        status = "passed_32g_target",
    ),
    (
        name = "all-sky IFS conventions plus Breeze H100 4x",
        definition = "Pass current IFS all-sky cloud/aerosol/scattering/overlap solver thresholds and demonstrate >=4x H100 Breeze speedup over RRTMGP on a realistic RCEMIP-style workload.",
        status = "passed",
    ),
)

const VERIFIED_STATUS_BLOCKERS = Set([
    "official/reduced ecCKD gas-optics training",
])

const PROMPT_ARTIFACT_CHECKLIST = (
    (
        requirement = "Plan reviewed and concrete three-step /goal captured",
        completion_criteria = "The project plan and audit list the three concrete goal gates with current status.",
        evidence = (
            "ecRad convention gap report",
            "ecRad hard-threshold accuracy gate",
            "reduced ecCKD gap report",
        ),
    ),
    (
        requirement = "Hard cloudless/no-aerosol official ecCKD accuracy thresholds",
        completion_criteria = "Official ecCKD clear/cloudless hard-gate artifacts pass.",
        evidence = (
            "ecRad hard-threshold accuracy gate",
            "ecRad cloudless/no-aerosol first hard gate",
        ),
    ),
    (
        requirement = "NetCDF/ecRad/ecCKD references discovered and usable",
        completion_criteria = "Reference manifest, upstream ecRad checkout, candidate schema, and official ecCKD files are present and valid.",
        evidence = (
            "ecRad reference manifest",
            "upstream ecRad checkout",
            "ecRad candidate schema preflight",
            "official ecCKD definition files recognized",
        ),
    ),
    (
        requirement = "Direct RRTMGP comparison through ColumnAtmosphere/RadiativeFluxes",
        completion_criteria = "The package-native RRTMGP extension and direct comparison test are implemented.",
        evidence = (
            "package-native RRTMGP comparison extension",
            "package-native RRTMGP comparison test",
        ),
    ),
    (
        requirement = "Fresh dedicated Breeze checkout and Breeze-owned extension",
        completion_criteria = "Old ABR Breeze extension is absent and the fresh Breeze checkout owns BreezeRadiativeHeatingExt.",
        evidence = (
            "old ABR Breeze extension removed",
            "dedicated BreezeRadiativeHeatingExt present",
            "Breeze tabulated ecCKD column amount conversion",
        ),
    ),
    (
        requirement = "Host-model access points for external solvers and vertical integrals",
        completion_criteria = "Access-point validation passes without unexported required APIs.",
        evidence = (
            "host-model access points",
        ),
    ),
    (
        requirement = "32-g ecCKD/RRTMGP-compatible production gas optics",
        completion_criteria = "The official ecCKD 32-g production path passes ecRad/ecCKD hard thresholds, the 16-g model is frozen as diagnostic evidence, and direct RRTMGP comparison metrics are emitted on the same column ensemble.",
        evidence = (
            "official ecCKD 32b baseline",
            "32-g ecCKD/RRTMGP comparison",
            "reduced ecCKD gap report",
            "reduced ecCKD acceptance decision",
            "reduced 16-g diagnostic hard-threshold record",
            "reduced ecCKD subset search",
            "reduced ecCKD subset search threshold status",
            "reduced ecCKD optimization preflight",
            "reduced ecCKD optimization gap status",
            "reduced 16-g diagnostic optimization objective record",
            "reduced ecCKD optimization block scan",
            "reduced ecCKD coefficient coordinate scan",
            "reduced ecCKD topology candidate scan",
            "reduced ecCKD subset-search topology scan",
        ),
    ),
    (
        requirement = "Reactant and Enzyme optimization path",
        completion_criteria = "Toy and official reduced optimization checks show Reactant and Enzyme availability, and full 16-g calibration against the RRTMGP/package reference is demonstrated.",
        evidence = (
            "toy ecCKD Reactant check",
            "toy ecCKD Enzyme check",
            "official reduced optimization Reactant dependency",
            "official reduced optimization Reactant check",
            "official reduced optimization Enzyme dependency",
            "official reduced optimization Enzyme check",
            "full Reactant/Enzyme RRTMGP-target 16-g calibration",
        ),
    ),
    (
        requirement = "End-to-end gas-optics training demonstration",
        completion_criteria = "Toy training passes, and an official/reduced ecCKD gas-optics training artifact demonstrates the production path.",
        evidence = (
            "toy ecCKD training",
            "toy ecCKD training RMSE improvement",
            "official/reduced ecCKD gas-optics training",
        ),
    ),
    (
        requirement = "Current IFS all-sky cloud/aerosol/scattering/overlap semantics",
        completion_criteria = "Cloud/scattering diagnostics, final IFS all-sky gate, and all-sky solver/reference-optics evidence pass.",
        evidence = (
            "ecRad all-sky IFS gate",
            "toy cloud validation",
            "ecRad all-sky cloud-effect diagnostics",
            "ecRad all-sky cloud parameter sweep",
            "ecRad all-sky optics gap diagnostic",
            "ecRad reference-optics solver gap diagnostic",
            "ecRad cloud scattering table ingestion",
        ),
    ),
    (
        requirement = "Validated ecCKD Breeze CPU and H100 support path",
        completion_criteria = "Validated ecCKD metadata flows through Breeze, CPU support is verified, and H100 tabulated multi-gas support is no longer blocked.",
        evidence = (
            "Breeze validated ecCKD CPU smoke",
            "Breeze validated ecCKD accuracy metadata smoke",
            "Breeze validated ecCKD CPU device-support metadata",
            "Breeze validated ecCKD trace-gas metadata",
            "Breeze tabulated ecCKD device column amount kernel",
            "Breeze tabulated ecCKD interpolation state kernel",
            "Breeze tabulated ecCKD absorption optical-depth kernel",
            "Breeze tabulated ecCKD Rayleigh optical-depth kernel",
            "Breeze tabulated ecCKD longwave source kernel",
            "Breeze tabulated ecCKD integrated optical-properties kernel",
            "Breeze tabulated ecCKD flux-divergence kernel",
            "Breeze tabulated ecCKD device workspace",
            "Breeze tabulated ecCKD device update path",
            "Breeze validated ecCKD H100 support preflight",
            "Breeze validated ecCKD H100 support source",
            "Breeze validated ecCKD H100 next implementation",
        ),
    ),
    (
        requirement = "Realistic RCEMIP-style H100 4x RRTMGP comparison with Nsight profiling",
        completion_criteria = "Final 1024-column RCEMIP-style H100 artifact supports >=4x over RRTMGP with validated ecCKD and Nsight Systems/Compute reports.",
        evidence = (
            "Breeze RCEMIP H100 4x acceptance",
            "Breeze RCEMIP realistic problem size",
            "Breeze RCEMIP gas model metadata",
            "Breeze RCEMIP Nsight Systems report",
            "Breeze RCEMIP Nsight Compute report",
            "Breeze GPU environment check",
            "Breeze H100 acceptance runbook",
            "Breeze H100 acceptance local preflight",
        ),
    ),
)

function command_output(cmd, dir)
    try
        return strip(read(setenv(cmd, dir = dir), String))
    catch
        return nothing
    end
end

const REQUIRED_ARTIFACTS = (
    (
        name = "old ABR Breeze extension removed",
        path = joinpath(ABR_ROOT, "ext", "NumericalRadiationBreezeExt.jl"),
        required_text = "",
        forbidden_text = "",
        expected_present = false,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "dedicated BreezeRadiativeHeatingExt present",
        path = joinpath(BREEZE_ROOT, "ext", "BreezeRadiativeHeatingExt", "BreezeRadiativeHeatingExt.jl"),
        required_text = "module BreezeRadiativeHeatingExt",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze tabulated ecCKD column amount conversion",
        path = joinpath(BREEZE_ROOT, "ext", "BreezeRadiativeHeatingExt", "BreezeRadiativeHeatingExt.jl"),
        required_text = "EcCKDTabulatedGasOpticsModel",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "ecRad reference manifest",
        path = joinpath(ABR_ROOT, "validation", "results", "ecrad_reference_manifest.json"),
        required_text = "\"status\": \"references_present_schema_valid\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "upstream ecRad checkout",
        path = joinpath(ABR_ROOT, "validation", "external", "ecrad", "README.md"),
        required_text = "ecRad",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "ecRad hard-threshold accuracy gate",
        path = joinpath(ABR_ROOT, "validation", "results", "ecrad_accuracy_gate.json"),
        required_text = "\"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "hard ecRad/ecCKD threshold comparison has not passed",
    ),
    (
        name = "ecRad cloudless/no-aerosol first hard gate",
        path = joinpath(ABR_ROOT, "validation", "results", "ecrad_cloudless_accuracy_gate.json"),
        required_text = "\"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "ecRad accuracy diagnostics",
        path = joinpath(ABR_ROOT, "validation", "results", "ecrad_accuracy_diagnostics.json"),
        required_text = "\"case\": \"ecrad_accuracy_diagnostics\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "ecRad all-sky cloud-effect diagnostics",
        path = joinpath(ABR_ROOT, "validation", "results", "ecrad_all_sky_cloud_effect_diagnostics.json"),
        required_text = "\"case\": \"ecrad_all_sky_cloud_effect_diagnostics\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "ecRad all-sky cloud parameter sweep",
        path = joinpath(ABR_ROOT, "validation", "results", "ecrad_all_sky_cloud_sweep.json"),
        required_text = "\"case\": \"ecrad_all_sky_cloud_sweep\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "ecRad all-sky IFS gate",
        path = joinpath(ABR_ROOT, "validation", "results", "ecrad_all_sky_ifs_gate.json"),
        required_text = "\"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = true,
        blocker_reason = "current IFS all-sky cloud/aerosol/scattering/overlap solver gate has not passed",
    ),
    (
        name = "ecRad all-sky optics gap diagnostic",
        path = joinpath(ABR_ROOT, "validation", "results", "ecrad_all_sky_optics_gap.json"),
        required_text = "\"case\": \"ecrad_all_sky_optics_gap\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "ecRad reference-optics solver gap diagnostic",
        path = joinpath(ABR_ROOT, "validation", "results", "ecrad_reference_optics_solver_gap.json"),
        required_text = "\"case\": \"ecrad_reference_optics_solver_gap\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "ecRad cloud scattering table ingestion",
        path = joinpath(ABR_ROOT, "validation", "results", "ecrad_cloud_scattering_tables_check.json"),
        required_text = "\"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "ecRad convention gap report",
        path = joinpath(ABR_ROOT, "validation", "ecrad_convention_gap_report.md"),
        required_text = "three concrete gates",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "ecRad candidate schema preflight",
        path = joinpath(ABR_ROOT, "validation", "results", "ecrad_candidate_schema.json"),
        required_text = "\"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "official ecCKD definition files recognized",
        path = joinpath(ABR_ROOT, "validation", "results", "official_ecckd_definition_files_check.json"),
        required_text = "\"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "toy ecCKD training",
        path = joinpath(ABR_ROOT, "validation", "results", "toy_ecckd_training.json"),
        required_text = "\"passed\": true",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "toy ecCKD Enzyme check",
        path = joinpath(ABR_ROOT, "validation", "results", "toy_ecckd_training.json"),
        required_text = "\"enzyme_check\": {\n  \"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "toy ecCKD Reactant check",
        path = joinpath(ABR_ROOT, "validation", "results", "toy_ecckd_training.json"),
        required_text = "\"reactant_check\": {\n  \"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "official/reduced ecCKD gas-optics training",
        path = joinpath(ABR_ROOT, "validation", "results", "official_ecckd_training.json"),
        required_text = "\"status\": \"partial\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = true,
        blocker_reason = "production official/reduced ecCKD training improves the objective but has not quantitatively recovered a published model",
    ),
    (
        name = "full Reactant/Enzyme RRTMGP-target 16-g calibration",
        path = joinpath(ABR_ROOT, "validation", "results",
                        "rrtmgp_target_16g_ad_calibration.json"),
        required_text = "\"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = true,
        blocker_reason = "full Reactant/Enzyme gradient-descent calibration of the 16-g model against the RRTMGP/package reference has not been demonstrated",
    ),
    (
        name = "toy cloud validation",
        path = joinpath(ABR_ROOT, "validation", "results", "toy_cloud_validation.json"),
        required_text = "\"passed\": true",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "host-model access points",
        path = joinpath(ABR_ROOT, "validation", "results", "access_points_check.json"),
        required_text = "\"status\": \"passed\"",
        forbidden_text = "\"exported\": false",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "package-native RRTMGP comparison extension",
        path = joinpath(ABR_ROOT, "ext", "NumericalRadiationRRTMGPExt.jl"),
        required_text = "module NumericalRadiationRRTMGPExt",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "RRTMGP extension for direct ColumnAtmosphere/RadiativeFluxes comparisons is not implemented",
    ),
    (
        name = "package-native RRTMGP comparison test",
        path = joinpath(ABR_ROOT, "test", "test_rrtmgp_ext.jl"),
        required_text = "RRTMGP extension direct ColumnAtmosphere comparison",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze RCEMIP H100 4x acceptance",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "rcemip_h100_32x32x64", "radiative_heating_rcemip_latest.json"),
        required_text = "\"final_4x_claim_supported\": true",
        forbidden_text = "\"status\": \"scaffold_not_final_4x_evidence\"",
        expected_present = true,
        completion_blocker = true,
        blocker_reason = "H100 RCEMIP artifact is still marked as scaffold evidence, not final production 4x evidence",
    ),
    (
        name = "Breeze RCEMIP realistic problem size",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "rcemip_h100_32x32x64", "radiative_heating_rcemip_latest.json"),
        required_text = "\"columns\": 1024",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze RCEMIP gas model metadata",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "rcemip_h100_32x32x64", "radiative_heating_rcemip_latest.json"),
        required_text = "\"gas_model_source\": \"validated_ecCKD\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = true,
        blocker_reason = "final H100 benchmark must use a validated ecCKD gas model, not synthetic fixed coefficients",
    ),
    (
        name = "Breeze validated ecCKD CPU smoke",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "validated_ecckd_cpu_smoke", "radiative_heating_rcemip_latest.json"),
        required_text = "\"gas_model_source\": \"validated_ecCKD\"",
        forbidden_text = "\"radiative_heating_runtime_supported\": false",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze validated ecCKD accuracy metadata smoke",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "validated_ecckd_cpu_smoke", "radiative_heating_rcemip_latest.json"),
        required_text = "\"gas_model_accuracy_status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze validated ecCKD CPU device-support metadata",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "validated_ecckd_cpu_smoke", "radiative_heating_rcemip_latest.json"),
        required_text = "\"gas_model_device_support_status\": \"supported\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze validated ecCKD trace-gas metadata",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "validated_ecckd_cpu_smoke", "radiative_heating_rcemip_latest.json"),
        required_text = "\"ch4\": 1.8e-6",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze tabulated ecCKD device column amount kernel",
        path = joinpath(BREEZE_ROOT, "ext", "BreezeRadiativeHeatingExt", "BreezeRadiativeHeatingExt.jl"),
        required_text = "tabulated_ecckd_column_amounts!",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze tabulated ecCKD interpolation state kernel",
        path = joinpath(BREEZE_ROOT, "ext", "BreezeRadiativeHeatingExt", "BreezeRadiativeHeatingExt.jl"),
        required_text = "tabulated_ecckd_interpolation_state!",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze tabulated ecCKD absorption optical-depth kernel",
        path = joinpath(BREEZE_ROOT, "ext", "BreezeRadiativeHeatingExt", "BreezeRadiativeHeatingExt.jl"),
        required_text = "tabulated_ecckd_absorption_optical_depths!",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze tabulated ecCKD Rayleigh optical-depth kernel",
        path = joinpath(BREEZE_ROOT, "ext", "BreezeRadiativeHeatingExt", "BreezeRadiativeHeatingExt.jl"),
        required_text = "tabulated_ecckd_rayleigh_optical_depths!",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze tabulated ecCKD longwave source kernel",
        path = joinpath(BREEZE_ROOT, "ext", "BreezeRadiativeHeatingExt", "BreezeRadiativeHeatingExt.jl"),
        required_text = "tabulated_ecckd_longwave_sources!",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze tabulated ecCKD integrated optical-properties kernel",
        path = joinpath(BREEZE_ROOT, "ext", "BreezeRadiativeHeatingExt", "BreezeRadiativeHeatingExt.jl"),
        required_text = "tabulated_ecckd_optical_properties!",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze tabulated ecCKD flux-divergence kernel",
        path = joinpath(BREEZE_ROOT, "ext", "BreezeRadiativeHeatingExt", "BreezeRadiativeHeatingExt.jl"),
        required_text = "tabulated_ecckd_flux_divergence!",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze tabulated ecCKD device workspace",
        path = joinpath(BREEZE_ROOT, "ext", "BreezeRadiativeHeatingExt", "BreezeRadiativeHeatingExt.jl"),
        required_text = "TabulatedEcCKDDeviceWorkspace",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze tabulated ecCKD device update path",
        path = joinpath(BREEZE_ROOT, "ext", "BreezeRadiativeHeatingExt", "BreezeRadiativeHeatingExt.jl"),
        required_text = "update_tabulated_ecckd_radiation_device!",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze validated ecCKD H100 support preflight",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "h100_validated_ecckd_preflight", "radiative_heating_h100_support_preflight_latest.json"),
        required_text = "\"gas_model_device_support_status\": \"supported\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze validated ecCKD H100 support source",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "h100_validated_ecckd_preflight", "radiative_heating_h100_support_preflight_latest.json"),
        required_text = "\"gas_model_device_support_source\": \"BreezeRadiativeHeatingExt\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze validated ecCKD H100 next implementation",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "h100_validated_ecckd_preflight", "radiative_heating_h100_support_preflight_latest.json"),
        required_text = "\"next_required_implementation\": \"none\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze validated ecCKD H100 missing kernel checklist",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "h100_validated_ecckd_preflight", "radiative_heating_h100_support_preflight_latest.json"),
        required_text = "\"missing_kernel_requirements\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze validated ecCKD H100 parity requirement",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "h100_validated_ecckd_preflight", "radiative_heating_h100_support_preflight_latest.json"),
        required_text = "CPU/GPU parity evidence",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze RCEMIP Nsight Systems report",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "rcemip_h100_32x32x64", "nsight", "radiative_heating_rcemip_nsys.nsys-rep"),
        required_text = "",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze RCEMIP Nsight Compute report",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "rcemip_h100_32x32x64", "nsight", "radiative_heating_rcemip_ncu.ncu-rep"),
        required_text = "",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze RCEMIP H100 smoke",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "rcemip_h100_smoke", "radiative_heating_rcemip_latest.json"),
        required_text = "\"backend\": \"H100\"",
        forbidden_text = "\"rrtmgp_runtime_supported\": false",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze reduced Pareto scaffold",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "reduced_pareto", "radiative_heating_reduced_pareto_latest.json"),
        required_text = "\"status\": \"h100_runtime_accuracy_failed_threshold\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze reduced 32x16 proxy timing",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "reduced_pareto", "ng_lw_32_ng_sw_16", "radiative_heating_rcemip_latest.json"),
        required_text = "\"gas_model_kind\": \"fixed_ecCKD_32_lw_16_sw\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze reduced accuracy scaffold",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "reduced_accuracy", "radiative_heating_reduced_accuracy_latest.json"),
        required_text = "\"status\": \"failed_threshold\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze reduced 32x16 proxy accuracy",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "reduced_accuracy", "radiative_heating_reduced_accuracy_latest.json"),
        required_text = "\"ng_lw\": 32",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced ecCKD size scan",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_size_scan.json"),
        required_text = "\"status\": \"only_full_32_sw_passes\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "official ecCKD 32b baseline",
        path = joinpath(ABR_ROOT, "validation", "results", "ecckd_32b_baseline_check.json"),
        required_text = "\"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "32-g ecCKD/RRTMGP comparison",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_32g_rrtmgp_comparison.json"),
        required_text = "\"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = true,
        blocker_reason = "32-g ecCKD production path has not emitted direct RRTMGP comparison metrics",
    ),
    (
        name = "reduced ecCKD gap report",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_gap_report.json"),
        required_text = "\"status\": \"reduced_shortwave_passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced ecCKD acceptance decision",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_gap_report.json"),
        required_text = "\"status\": \"decision_required\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced 16-g diagnostic hard-threshold record",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_accuracy.json"),
        required_text = "\"status\": \"failed_threshold\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced ecCKD subset search",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_subset_search.json"),
        required_text = "\"case\": \"radiative_heating_reduced_subset_search\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced ecCKD subset search threshold status",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_subset_search.json"),
        required_text = "\"status\": \"failed_threshold\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced ecCKD optimization preflight",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_optimization_preflight.json"),
        required_text = "\"status\": \"preflight_ready\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced ecCKD optimization gap status",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_optimization_preflight.json"),
        required_text = "\"acceptance_gap_status\": \"far_above_objective_target\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced 16-g diagnostic optimization objective record",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_optimization_preflight.json"),
        required_text = "\"acceptance_gap_status\": \"far_above_objective_target\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced ecCKD optimization block scan",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_optimization_preflight.json"),
        required_text = "\"block_trial_scan\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced ecCKD coefficient coordinate scan",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_optimization_preflight.json"),
        required_text = "\"coordinate_coefficient_scan\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced ecCKD topology candidate scan",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_optimization_preflight.json"),
        required_text = "\"topology_candidate_scan\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "reduced ecCKD subset-search topology scan",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_optimization_preflight.json"),
        required_text = "\"subset_search_topology_scan\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "official reduced optimization Reactant dependency",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_official_ad_checks.json"),
        required_text = "\"reactant_status\": \"available\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "official reduced optimization Reactant check",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_official_ad_checks.json"),
        required_text = "\"reactant_check\": {\n  \"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "official reduced optimization Enzyme dependency",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_official_ad_checks.json"),
        required_text = "\"enzyme_status\": \"available\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "official reduced optimization Enzyme check",
        path = joinpath(ABR_ROOT, "validation", "results", "reduced_ecckd_official_ad_checks.json"),
        required_text = "\"enzyme_check\": {\n  \"status\": \"passed\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze GPU environment check",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "gpu_environment_h100_job764_with_nsight", "radiative_heating_gpu_environment_latest.json"),
        required_text = "\"status\": \"ready_for_h100_nsight_gate\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze H100 acceptance runbook",
        path = joinpath(BREEZE_ROOT, "benchmarking", "radiative_heating_h100_acceptance.sh"),
        required_text = "radiative_heating_h100_support_preflight.jl",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
    (
        name = "Breeze H100 acceptance local preflight",
        path = joinpath(BREEZE_ROOT, "benchmarking", "results", "gpu_environment_h100_job764_with_nsight", "radiative_heating_gpu_environment_latest.json"),
        required_text = "\"status\": \"ready_for_h100_nsight_gate\"",
        forbidden_text = "",
        expected_present = true,
        completion_blocker = false,
        blocker_reason = "",
    ),
)

function artifact_status(artifact)
    present = isfile(artifact.path)
    presence_matches = present == artifact.expected_present
    text_matches = artifact.expected_present ?
        (present && (artifact.required_text == "" ||
                     occursin(artifact.required_text, read(artifact.path, String)))) :
        true
    forbidden_text_found = artifact.expected_present && artifact.forbidden_text != "" ?
        (present && occursin(artifact.forbidden_text, read(artifact.path, String))) :
        false
    status = presence_matches && text_matches && !forbidden_text_found ? "verified" : "missing_or_unexpected"
    completion_blocker_active = artifact.completion_blocker &&
        (status != "verified" || artifact.name in VERIFIED_STATUS_BLOCKERS)
    return (
        name = artifact.name,
        path = artifact.path,
        present = present,
        expected_present = artifact.expected_present,
        presence_matches = presence_matches,
        required_text = artifact.required_text,
        required_text_found = text_matches,
        forbidden_text = artifact.forbidden_text,
        forbidden_text_found = forbidden_text_found,
        completion_blocker = artifact.completion_blocker,
        completion_blocker_active = completion_blocker_active,
        blocker_reason = artifact.blocker_reason,
        status = status,
    )
end

function json_number(path, key)
    isfile(path) || return nothing
    text = read(path, String)
    match = Base.match(Regex("\"$key\"\\s*:\\s*([-+0-9.eE]+)"), text)
    return match === nothing ? nothing : parse(Float64, match.captures[1])
end

function training_improvement_status()
    path = joinpath(ABR_ROOT, "validation", "results", "toy_ecckd_training.json")
    flux_ratio = json_number(path, "flux_rmse_ratio")
    heating_ratio = json_number(path, "heating_rate_rmse_ratio")
    verified = flux_ratio !== nothing &&
               heating_ratio !== nothing &&
               flux_ratio < 1 &&
               heating_ratio < 1
    return (
        name = "toy ecCKD training RMSE improvement",
        path = path,
        present = isfile(path),
        flux_rmse_ratio = flux_ratio,
        heating_rate_rmse_ratio = heating_ratio,
        completion_blocker = false,
        completion_blocker_active = false,
        blocker_reason = "",
        status = verified ? "verified" : "missing_or_unexpected",
    )
end

function artifact_by_name(artifacts)
    Dict(artifact.name => artifact for artifact in artifacts)
end

function checklist_entry_status(check, artifacts_by_name)
    evidence_status = NamedTuple[]
    for name in check.evidence
        artifact = get(artifacts_by_name, name, nothing)
        push!(evidence_status, (
            artifact = name,
            present_in_audit = artifact !== nothing,
            status = artifact === nothing ? "missing_from_audit" : artifact.status,
            completion_blocker_active = artifact === nothing ? true : artifact.completion_blocker_active,
        ))
    end
    uncovered = any(evidence -> !evidence.present_in_audit ||
                               evidence.status != "verified",
                    evidence_status)
    blocked = (hasproperty(check, :known_blocker) && check.known_blocker) ||
              any(evidence -> evidence.completion_blocker_active,
                  evidence_status)
    return (
        requirement = check.requirement,
        completion_criteria = check.completion_criteria,
        status = uncovered ? "uncovered" : blocked ? "blocked" : "satisfied",
        evidence = evidence_status,
    )
end

function prompt_artifact_checklist(artifacts)
    by_name = artifact_by_name(artifacts)
    return [checklist_entry_status(check, by_name) for check in PROMPT_ARTIFACT_CHECKLIST]
end

function breeze_checkout_status()
    sha = command_output(`git rev-parse HEAD`, BREEZE_ROOT)
    remote = command_output(`git remote get-url origin`, BREEZE_ROOT)
    dirty = command_output(`git status --short`, BREEZE_ROOT)
    return (
        path = BREEZE_ROOT,
        present = isdir(BREEZE_ROOT),
        head_sha = sha,
        expected_head_sha = EXPECTED_BREEZE_SHA,
        head_sha_matches_fresh_clone = sha == EXPECTED_BREEZE_SHA,
        origin_remote = remote,
        expected_origin_remote = EXPECTED_BREEZE_REMOTE,
        origin_remote_matches = remote == EXPECTED_BREEZE_REMOTE,
        dirty = !isempty(something(dirty, "")),
    )
end

function json_value(value)
    if value === nothing
        return "null"
    elseif value isa AbstractString
        escaped = replace(value,
            "\\" => "\\\\",
            "\"" => "\\\"",
            "\n" => "\\n",
            "\r" => "\\r",
            "\t" => "\\t",
        )
        return "\"" * escaped * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return json_object(value)
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join(json_value.(value), ", ") * "]"
    else
        return string(value)
    end
end

function json_object(result)
    names = propertynames(result)
    lines = ["{"]
    for (i, name) in enumerate(names)
        comma = i == length(names) ? "" : ","
        push!(lines, "  \"$(name)\": $(json_value(getproperty(result, name)))$(comma)")
    end
    push!(lines, "}")
    return join(lines, "\n")
end

function markdown_report(result)
    lines = String[
        "# Radiative Heating Goal Audit Check",
        "",
        "Status: **$(result.status)**",
        "",
        "| Artifact | Status | Completion blocker |",
        "|---|---|---:|",
    ]
    for artifact in result.artifacts
        push!(lines, "| $(artifact.name) | $(artifact.status) | $(artifact.completion_blocker_active) |")
    end
    append!(lines, [
        "",
        "## Goal Steps",
        "",
        "| Step | Status | Definition |",
        "|---|---|---|",
    ])
    for step in result.goal_steps
        push!(lines, "| $(step.name) | `$(step.status)` | $(step.definition) |")
    end
    append!(lines, [
        "",
        "## Prompt-to-Artifact Checklist",
        "",
        "| Requirement | Status | Completion criteria | Evidence |",
        "|---|---|---|---|",
    ])
    for item in result.prompt_artifact_checklist
        evidence = join([evidence.artifact * " (`" * evidence.status * "`" *
                         (evidence.completion_blocker_active ? ", blocker" : "") * ")"
                         for evidence in item.evidence], "<br>")
        push!(lines, "| $(item.requirement) | `$(item.status)` | $(item.completion_criteria) | $(evidence) |")
    end
    append!(lines, [
        "",
        "## Dedicated Breeze Checkout",
        "",
        "| Field | Value |",
        "|---|---|",
        "| Path | `$(result.breeze_checkout.path)` |",
        "| HEAD SHA | `$(result.breeze_checkout.head_sha)` |",
        "| Fresh-clone SHA matches | $(result.breeze_checkout.head_sha_matches_fresh_clone) |",
        "| Origin remote | `$(result.breeze_checkout.origin_remote)` |",
        "| Origin remote matches | $(result.breeze_checkout.origin_remote_matches) |",
        "| Dirty worktree | $(result.breeze_checkout.dirty) |",
    ])
    append!(lines, [
        "",
        "Blocking reasons:",
        "",
    ])
    blockers = filter(artifact -> artifact.completion_blocker_active, result.artifacts)
    if isempty(blockers)
        push!(lines, "none")
    else
        for artifact in blockers
            push!(lines, "- $(artifact.name): $(artifact.blocker_reason)")
        end
    end
    return join(lines, "\n") * "\n"
end

function main()
    artifacts = Any[artifact_status(artifact) for artifact in REQUIRED_ARTIFACTS]
    push!(artifacts, training_improvement_status())
    checklist = prompt_artifact_checklist(artifacts)
    breeze_checkout = breeze_checkout_status()
    missing_or_unexpected = count(artifact -> artifact.status != "verified", artifacts)
    breeze_checkout_verified = breeze_checkout.present &&
                               breeze_checkout.head_sha_matches_fresh_clone &&
                               breeze_checkout.origin_remote_matches
    missing_or_unexpected += breeze_checkout_verified ? 0 : 1
    blockers = count(artifact -> artifact.completion_blocker_active, artifacts)
    result = (
        case = "radiative_heating_goal_audit_check",
        date = string(Dates.now()),
        status = missing_or_unexpected == 0 && blockers == 0 ? "complete" : "not_complete",
        missing_or_unexpected_artifact_count = missing_or_unexpected,
        completion_blocker_count = blockers,
        goal_steps = GOAL_STEPS,
        prompt_artifact_checklist = checklist,
        breeze_checkout = breeze_checkout,
        artifacts = artifacts,
    )

    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "goal_audit_check.json")
    md_path = joinpath(results_dir, "goal_audit_check.md")
    write(json_path, json_object(result))
    write(md_path, markdown_report(result))

    print(markdown_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

main()
