include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))

include(joinpath(@__DIR__, "write_ecrad_candidates.jl"))
include(joinpath(@__DIR__, "ecrad_accuracy_diagnostics.jl"))
include(joinpath(@__DIR__, "ecrad_all_sky_cloud_effect_diagnostics.jl"))

const CLOUD_SWEEP_TARGET_CASE = "ecckd_all_sky_tropical_column"

const CLOUD_SWEEP_ENV_KEYS = (
    "RH_CANDIDATE_GAS_OPTICS",
    "RH_CLOUD_EFFECTIVE_RADIUS_OPTICS",
    "RH_LIQUID_CLOUD_LW_MASS_ABSORPTION",
    "RH_ICE_CLOUD_LW_MASS_ABSORPTION",
    "RH_LIQUID_CLOUD_SW_SINGLE_SCATTERING_ALBEDO",
    "RH_ICE_CLOUD_SW_SINGLE_SCATTERING_ALBEDO",
    "RH_LIQUID_CLOUD_SW_SCATTERING_ASYMMETRY",
    "RH_ICE_CLOUD_SW_SCATTERING_ASYMMETRY",
    "RH_CLOUD_FRACTION_EXPONENT",
    "RH_LIQUID_CLOUD_EFFECTIVE_RADIUS_SW_SCALE",
    "RH_ICE_CLOUD_EFFECTIVE_RADIUS_SW_SCALE",
    "RH_CLOUD_SCATTERING_TABLE_OPTICS",
    "RH_CLOUD_SCATTERING_MAPPING_METHOD",
    "RH_CLOUD_SCATTERING_LAYER_EFFECTIVE_RADIUS",
    "RH_CLOUD_SCATTERING_DELTA_EDDINGTON_AVERAGE",
    "RH_CLOUD_SCATTERING_THICK_AVERAGING",
    "RH_CLOUD_SCATTERING_DELTA_EDDINGTON_SCALE",
    "RH_CLOUD_SCATTERING_SW_SSA_SCALE",
    "RH_CLOUD_LW_TABLE_EXTINCTION_AS_ABSORPTION",
    "RH_LW_CLOUD_SCATTERING",
    "RH_LIQUID_CLOUD_SCATTERING_SW_SCALE",
    "RH_ICE_CLOUD_SCATTERING_SW_SCALE",
    "RH_CLOUD_OVERLAP_LONGWAVE",
    "RH_CLOUD_OVERLAP_LONGWAVE_RULE",
    "RH_CLOUD_OVERLAP_SHORTWAVE",
    "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS",
    "RH_CLOUD_OVERLAP_RULE",
    "RH_CLOUD_INHOM_OVERLAP_EXPONENT",
    "RH_SW_CLOUD_INHOM_OVERLAP_EXPONENT",
    "RH_LW_CLOUD_INHOM_OVERLAP_EXPONENT",
    "RH_AEROSOL_OPTICS",
    "RH_AEROSOL_DELTA_EDDINGTON_SCALE",
    "RH_IFS_AEROSOL_TABLE_OPTICS",
    "RH_IFS_AEROSOL_RELATIVE_HUMIDITY",
    "RH_IFS_AEROSOL_LAYER_RELATIVE_HUMIDITY",
)

const CLOUD_SWEEP_BASE = Dict(
    "RH_CANDIDATE_GAS_OPTICS" => "official_ecckd",
    "RH_CLOUD_EFFECTIVE_RADIUS_OPTICS" => "true",
    "RH_LIQUID_CLOUD_LW_MASS_ABSORPTION" => "100",
    "RH_ICE_CLOUD_LW_MASS_ABSORPTION" => "50",
    "RH_LIQUID_CLOUD_SW_SINGLE_SCATTERING_ALBEDO" => "1.0",
    "RH_ICE_CLOUD_SW_SINGLE_SCATTERING_ALBEDO" => "1.0",
    "RH_LIQUID_CLOUD_SW_SCATTERING_ASYMMETRY" => "0.85",
    "RH_ICE_CLOUD_SW_SCATTERING_ASYMMETRY" => "0.75",
    "RH_CLOUD_FRACTION_EXPONENT" => "0.5",
    "RH_LIQUID_CLOUD_EFFECTIVE_RADIUS_SW_SCALE" => "1.0",
    "RH_ICE_CLOUD_EFFECTIVE_RADIUS_SW_SCALE" => "1.0",
    "RH_CLOUD_SCATTERING_TABLE_OPTICS" => "false",
    "RH_CLOUD_SCATTERING_MAPPING_METHOD" => "ecrad",
    "RH_CLOUD_SCATTERING_LAYER_EFFECTIVE_RADIUS" => "true",
    "RH_CLOUD_SCATTERING_DELTA_EDDINGTON_AVERAGE" => "true",
    "RH_CLOUD_SCATTERING_THICK_AVERAGING" => "true",
    "RH_CLOUD_SCATTERING_DELTA_EDDINGTON_SCALE" => "true",
    "RH_CLOUD_SCATTERING_SW_SSA_SCALE" => "1.0",
    "RH_CLOUD_LW_TABLE_EXTINCTION_AS_ABSORPTION" => "false",
    "RH_LW_CLOUD_SCATTERING" => "false",
    "RH_LIQUID_CLOUD_SCATTERING_SW_SCALE" => "1.0",
    "RH_ICE_CLOUD_SCATTERING_SW_SCALE" => "1.0",
    "RH_CLOUD_OVERLAP_LONGWAVE" => "false",
    "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "adding",
    "RH_CLOUD_OVERLAP_SHORTWAVE" => "false",
    "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "false",
    "RH_CLOUD_OVERLAP_RULE" => "maximum",
    "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "2.0",
    "RH_AEROSOL_OPTICS" => "false",
    "RH_AEROSOL_DELTA_EDDINGTON_SCALE" => "true",
    "RH_IFS_AEROSOL_TABLE_OPTICS" => "false",
    "RH_IFS_AEROSOL_RELATIVE_HUMIDITY" => "0.8",
    "RH_IFS_AEROSOL_LAYER_RELATIVE_HUMIDITY" => "true",
)

const CLOUD_SWEEP_TRIALS = (
    (name = "current_ssa1_g085_075_cf05_scale1",
     overrides = Dict{String, String}()),
    (name = "weaker_cloud_scale075",
     overrides = Dict("RH_LIQUID_CLOUD_EFFECTIVE_RADIUS_SW_SCALE" => "0.75",
                      "RH_ICE_CLOUD_EFFECTIVE_RADIUS_SW_SCALE" => "0.75")),
    (name = "weaker_cloud_scale05",
     overrides = Dict("RH_LIQUID_CLOUD_EFFECTIVE_RADIUS_SW_SCALE" => "0.5",
                      "RH_ICE_CLOUD_EFFECTIVE_RADIUS_SW_SCALE" => "0.5")),
    (name = "stronger_cloud_scale125",
     overrides = Dict("RH_LIQUID_CLOUD_EFFECTIVE_RADIUS_SW_SCALE" => "1.25",
                      "RH_ICE_CLOUD_EFFECTIVE_RADIUS_SW_SCALE" => "1.25")),
    (name = "cloud_fraction_linear",
     overrides = Dict("RH_CLOUD_FRACTION_EXPONENT" => "1.0")),
    (name = "cloud_fraction_binary_like",
     overrides = Dict("RH_CLOUD_FRACTION_EXPONENT" => "0.0")),
    (name = "less_forward_scattering",
     overrides = Dict("RH_LIQUID_CLOUD_SW_SCATTERING_ASYMMETRY" => "0.65",
                      "RH_ICE_CLOUD_SW_SCATTERING_ASYMMETRY" => "0.65")),
    (name = "earlier_ssa099_098",
     overrides = Dict("RH_LIQUID_CLOUD_SW_SINGLE_SCATTERING_ALBEDO" => "0.99",
                      "RH_ICE_CLOUD_SW_SINGLE_SCATTERING_ALBEDO" => "0.98")),
    (name = "table_scattering",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true")),
    (name = "table_scattering_ifs_aerosol_table",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_AEROSOL_OPTICS" => "true",
                      "RH_IFS_AEROSOL_TABLE_OPTICS" => "true")),
    (name = "table_scattering_ifs_aerosol_table_fixed_rh08",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_AEROSOL_OPTICS" => "true",
                      "RH_IFS_AEROSOL_TABLE_OPTICS" => "true",
                      "RH_IFS_AEROSOL_LAYER_RELATIVE_HUMIDITY" => "false")),
    (name = "table_scattering_scale2",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_LIQUID_CLOUD_SCATTERING_SW_SCALE" => "2.0",
                      "RH_ICE_CLOUD_SCATTERING_SW_SCALE" => "2.0")),
    (name = "table_scattering_scale3",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_LIQUID_CLOUD_SCATTERING_SW_SCALE" => "3.0",
                      "RH_ICE_CLOUD_SCATTERING_SW_SCALE" => "3.0")),
    (name = "table_scattering_overlap_maximum",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "maximum")),
    (name = "table_scattering_overlap_cloudy_region_average",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "average")),
    (name = "table_scattering_overlap_cloudy_region_maximum",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "maximum")),
    (name = "table_scattering_adding_cloudy_region",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "adding")),
    (name = "table_scattering_matrix_maximum_cloudy_region",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "matrix_maximum")),
    (name = "table_scattering_matrix_alpha_cloudy_region",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "matrix_alpha")),
    (name = "table_scattering_tripleclouds_alpha_cloudy_region",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha")),
    (name = "table_scattering_tripleclouds_alpha_cf1_cloudy_region",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p4_cloudy_region",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "4.0")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p4_cloudy_region_lw_overlap",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "adding",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "4.0")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p4_cloudy_region_lw_tripleclouds",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "4.0")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p2_cloudy_region_lw_tripleclouds",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "2.0")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p2_cloudy_region_ifs_aerosol",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "2.0",
                      "RH_AEROSOL_OPTICS" => "true",
                      "RH_IFS_AEROSOL_TABLE_OPTICS" => "true")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p2_cloudy_region_lw_tripleclouds_ifs_aerosol",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "2.0",
                      "RH_AEROSOL_OPTICS" => "true",
                      "RH_IFS_AEROSOL_TABLE_OPTICS" => "true")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p2_cloudy_region_lw_scattering_tripleclouds_ifs_aerosol",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "2.0",
                      "RH_LW_CLOUD_SCATTERING" => "true",
                      "RH_AEROSOL_OPTICS" => "true",
                      "RH_IFS_AEROSOL_TABLE_OPTICS" => "true")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p4_cloudy_region_ifs_aerosol",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "4.0",
                      "RH_AEROSOL_OPTICS" => "true",
                      "RH_IFS_AEROSOL_TABLE_OPTICS" => "true")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p4_cloudy_region_lw_tripleclouds_ifs_aerosol",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "4.0",
                      "RH_AEROSOL_OPTICS" => "true",
                      "RH_IFS_AEROSOL_TABLE_OPTICS" => "true")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p8_cloudy_region_ifs_aerosol",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "8.0",
                      "RH_AEROSOL_OPTICS" => "true",
                      "RH_IFS_AEROSOL_TABLE_OPTICS" => "true")),
    (name = "table_scattering_tripleclouds_alpha_cf1_sw_p8_lw_p4_cloudy_region_lw_tripleclouds",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_SW_CLOUD_INHOM_OVERLAP_EXPONENT" => "8.0",
                      "RH_LW_CLOUD_INHOM_OVERLAP_EXPONENT" => "4.0")),
    (name = "table_scattering_tripleclouds_alpha_cf1_sw_p12_lw_p4_cloudy_region_lw_tripleclouds",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_SW_CLOUD_INHOM_OVERLAP_EXPONENT" => "12.0",
                      "RH_LW_CLOUD_INHOM_OVERLAP_EXPONENT" => "4.0")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p4_cloudy_region_lw_tripleclouds_sw_ssa108",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_SCATTERING_SW_SSA_SCALE" => "1.08",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "4.0")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p4_cloudy_region_lw_tripleclouds_sw_ssa115",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_SCATTERING_SW_SSA_SCALE" => "1.15",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "4.0")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p8_cloudy_region_lw_tripleclouds",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "8.0")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p12_cloudy_region_lw_tripleclouds",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE" => "true",
                      "RH_CLOUD_OVERLAP_LONGWAVE_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "12.0")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p4_cloudy_region_lw_scattering",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "4.0",
                      "RH_LW_CLOUD_SCATTERING" => "true")),
    (name = "table_scattering_tripleclouds_alpha_cf1_p8_cloudy_region",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_FRACTION_EXPONENT" => "1.0",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "8.0")),
    (name = "table_scattering_tripleclouds_alpha_p8_cloudy_region",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "8.0")),
    (name = "table_scattering_tripleclouds_alpha_p12_cloudy_region",
     overrides = Dict("RH_CLOUD_SCATTERING_TABLE_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_SHORTWAVE" => "true",
                      "RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS" => "true",
                      "RH_CLOUD_OVERLAP_RULE" => "tripleclouds_alpha",
                      "RH_CLOUD_INHOM_OVERLAP_EXPONENT" => "12.0")),
)

function with_cloud_sweep_environment(f, config)
    previous = Dict(key => get(ENV, key, nothing) for key in CLOUD_SWEEP_ENV_KEYS)
    try
        for (key, value) in CLOUD_SWEEP_BASE
            ENV[key] = value
        end
        for (key, value) in config
            ENV[key] = value
        end
        return f()
    finally
        for (key, value) in previous
            if value === nothing
                delete!(ENV, key)
            else
                ENV[key] = value
            end
        end
    end
end

function trial_configuration(overrides)
    config = copy(CLOUD_SWEEP_BASE)
    for (key, value) in overrides
        config[key] = value
    end
    return config
end

function all_sky_worst_ratio(diagnostics)
    rows = filter(row -> row.case == CLOUD_SWEEP_TARGET_CASE,
                  diagnostics.case_summary)
    isempty(rows) && return Inf
    return first(rows).worst_ratio
end

function all_sky_forcing_errors(diagnostics)
    metrics = filter(row -> row.case == CLOUD_SWEEP_TARGET_CASE,
                     diagnostics.worst_metrics)
    toa = filter(row -> row.metric == "toa_forcing_abs_error", metrics)
    surface = filter(row -> row.metric == "surface_forcing_abs_error", metrics)
    return (
        toa_forcing_abs_error = isempty(toa) ? nothing : first(toa).value,
        surface_forcing_abs_error = isempty(surface) ? nothing : first(surface).value,
    )
end

function cloud_effect_boundary_max(effect, boundary, component)
    isempty(effect.cases) && return nothing
    cases = filter(case -> case.case == CLOUD_SWEEP_TARGET_CASE, effect.cases)
    isempty(cases) && return nothing
    rows = first(cases).boundary_cloud_effects
    match = filter(row -> row.boundary == string(boundary) &&
                          row.component == string(component), rows)
    return isempty(match) ? nothing : first(match).max_abs
end

function cloud_effect_profile_max(effect, component)
    isempty(effect.cases) && return nothing
    cases = filter(case -> case.case == CLOUD_SWEEP_TARGET_CASE, effect.cases)
    isempty(cases) && return nothing
    rows = first(cases).profile_cloud_effects
    match = filter(row -> row.component == string(component), rows)
    return isempty(match) ? nothing : first(match).max_abs
end

function configuration_rows(config)
    return [(variable = key, value = config[key]) for key in sort(collect(keys(config)))]
end

function run_cloud_sweep_trial(trial)
    config = trial_configuration(trial.overrides)
    return with_cloud_sweep_environment(config) do
        write_candidates()
        diagnostics = run_accuracy_diagnostics()
        effect = run_all_sky_cloud_effect_diagnostics()
        forcing = all_sky_forcing_errors(diagnostics)
        (
            name = trial.name,
            configuration = configuration_rows(config),
            all_sky_worst_threshold_ratio = all_sky_worst_ratio(diagnostics),
            toa_forcing_abs_error_w_m2 = forcing.toa_forcing_abs_error,
            surface_forcing_abs_error_w_m2 = forcing.surface_forcing_abs_error,
            surface_sw_cloud_effect_max_abs_w_m2 =
                cloud_effect_boundary_max(effect, :surface, :sw),
            toa_sw_cloud_effect_max_abs_w_m2 =
                cloud_effect_boundary_max(effect, :toa, :sw),
            profile_sw_cloud_effect_max_abs_w_m2 =
                cloud_effect_profile_max(effect, :sw),
            heating_cloud_effect_max_abs_k_day =
                cloud_effect_profile_max(effect, :heating_rate),
        )
    end
end

function markdown_cloud_sweep_report(result)
    lines = String[
        "# ecRad All-Sky Cloud Sweep",
        "",
        "This diagnostic sweeps a small set of all-sky cloud optics knobs and rewrites the candidate NetCDF variables with the best trial at the end. It is diagnostic only; the hard source of truth remains `validation/ecrad_accuracy_gate.jl`.",
        "",
        "Best trial: `$(result.best_trial)`",
        "",
        "| Trial | Worst threshold ratio | TOA forcing | Surface forcing | TOA SW CRE max | Surface SW CRE max | Profile SW CRE max | Heating CRE max |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.trials
        push!(lines, "| `$(row.name)` | $(@sprintf("%.6g", row.all_sky_worst_threshold_ratio)) | $(fmt_optional(row.toa_forcing_abs_error_w_m2)) | $(fmt_optional(row.surface_forcing_abs_error_w_m2)) | $(fmt_optional(row.toa_sw_cloud_effect_max_abs_w_m2)) | $(fmt_optional(row.surface_sw_cloud_effect_max_abs_w_m2)) | $(fmt_optional(row.profile_sw_cloud_effect_max_abs_w_m2)) | $(fmt_optional(row.heating_cloud_effect_max_abs_k_day)) |")
    end
    append!(lines, [
        "",
        "## Best Configuration",
        "",
        "| Environment variable | Value |",
        "|---|---|",
    ])
    for row in result.best_configuration
        push!(lines, "| `$(row.variable)` | `$(row.value)` |")
    end
    return join(lines, "\n") * "\n"
end

fmt_optional(value) = value === nothing ? "missing" : @sprintf("%.12g", value)

function cloud_sweep_main()
    trials = [run_cloud_sweep_trial(trial) for trial in CLOUD_SWEEP_TRIALS]
    best_index = argmin([trial.all_sky_worst_threshold_ratio for trial in trials])
    best_trial = CLOUD_SWEEP_TRIALS[best_index]
    best_configuration = trial_configuration(best_trial.overrides)

    # Leave the candidate NetCDF variables in the best diagnostic state.
    with_cloud_sweep_environment(best_configuration) do
        write_candidates()
        diagnostics_main()
        all_sky_cloud_effect_diagnostics_main()
    end

    result = (
        case = "ecrad_all_sky_cloud_sweep",
        date = string(Dates.now()),
        best_trial = trials[best_index].name,
        best_configuration = configuration_rows(best_configuration),
        trials = trials,
    )

    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "ecrad_all_sky_cloud_sweep.json")
    md_path = joinpath(results_dir, "ecrad_all_sky_cloud_sweep.md")
    write(json_path, json_object(result))
    write(md_path, markdown_cloud_sweep_report(result))
    print(markdown_cloud_sweep_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    cloud_sweep_main()
end
