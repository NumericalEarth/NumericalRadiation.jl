# Gate-4 P1a cost/readiness probe (SYNTHETIC DATA ONLY).
#
# This probe times the original-objective loss kernels, Enzyme reverse-mode
# LOSS-INPUT ADJOINTS (gradients w.r.t. the assembled candidate heating/flux
# arrays — NOT coefficient gradients), Reactant compilation of the real SW
# loss function with synthetic inputs, and the SW32 recovery-vector
# flatten/write/reflatten plumbing, all at true SW32/LW32 shapes (54 layers,
# 55 interfaces,
# 32 g-points) using deterministic synthetic inputs (index-seeded ramps and
# sinusoids; no RNG). No CKDMIP files are read. The published SW32
# CKD-definition NetCDF is read only for recovery-vector shapes and plumbing
# (it is not CKDMIP data).
#
# Disclaimer: no objective-value or recovery claims; synthetic shapes only;
# 204,896-vector work is flatten/write/reflatten plumbing plus
# FD-infeasibility evidence only.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using Statistics
using TOML

include(joinpath(@__DIR__, "ecckd_original_objective_loss.jl"))
include(joinpath(@__DIR__, "ecckd_published_recovery_vector.jl"))

const GATE4_COST_PROBE_JSON = validation_results_path("gate4_cost_probe.json")
const GATE4_COST_PROBE_MD = validation_results_path("gate4_cost_probe.md")

const GATE4_NLAY = 54
const GATE4_NLEV = GATE4_NLAY + 1
const GATE4_NGPT = 32
const GATE4_EXPECTED_PARAMETER_COUNT = 204896
const GATE4_TIMING_SAMPLES = 5
const GATE4_FD_SUBSET_SIZE = 32
const GATE4_FD_GATE_THRESHOLD = 1.0e-6
const GATE4_FD_STEP_HEATING = 1.0e-6
const GATE4_FD_STEP_FLUX = 1.0e-2
const GATE4_DISCLAIMER =
    "no objective-value or recovery claims; synthetic shapes only; " *
    "204,896-vector work is flatten/write/reflatten plumbing plus " *
    "FD-infeasibility evidence only"

# --- deterministic synthetic inputs (no RNG, no CKDMIP data) -----------------

function gate4_synthetic_pressure_hl(nlev)
    return [2.0 + 101323.0 * ((i - 1) / (nlev - 1))^2 for i in 1:nlev]
end

# Normalized sqrt-pressure layer weights, the same construction as
# `ckdmip_layer_weight` in validation/ckdmip_original_objective_dataset.jl:30-39,
# applied to a synthetic pressure grid.
function gate4_sqrt_pressure_layer_weight(pressure_hl)
    pressure = Float64.(pressure_hl)
    all(diff(pressure) .> 0) ||
        throw(ArgumentError("synthetic pressure_hl must increase downward"))
    weight = sqrt.(pressure[2:end]) .- sqrt.(pressure[1:(end - 1)])
    return weight ./ sum(weight)
end

function gate4_synthetic_inputs(kind; nlay = GATE4_NLAY, ngpt = GATE4_NGPT)
    kind in (:longwave, :shortwave) ||
        throw(ArgumentError("kind must be :longwave or :shortwave"))
    nlev = nlay + 1
    phase = kind == :longwave ? 0.0 : 1.7
    pressure_hl = gate4_synthetic_pressure_hl(nlev)
    layer_weight = gate4_sqrt_pressure_layer_weight(pressure_hl)
    flux_dn_true = [100.0 + 60.0 * sin(0.11 * i + 0.37 * g + phase) + 0.5 * i
                    for i in 1:nlev, g in 1:ngpt]
    flux_up_true = [45.0 + 20.0 * cos(0.07 * i + 0.23 * g + phase) + 0.2 * i
                    for i in 1:nlev, g in 1:ngpt]
    flux_dn_fwd = flux_dn_true .+
        [0.5 + 0.3 * sin(0.19 * i + 0.29 * g + phase) for i in 1:nlev, g in 1:ngpt]
    flux_up_fwd = flux_up_true .+
        [0.4 + 0.25 * cos(0.17 * i + 0.31 * g + phase) for i in 1:nlev, g in 1:ngpt]
    heating_rate_true =
        [(1.0 + 0.8 * sin(0.21 * i + 0.13 * g + phase)) / ECCKD_HR_SECONDS_PER_DAY
         for i in 1:nlay, g in 1:ngpt]
    heating_rate_fwd = heating_rate_true .+
        [(0.05 + 0.1 * sin(0.31 * i + 0.11 * g + phase)) / ECCKD_HR_SECONDS_PER_DAY
         for i in 1:nlay, g in 1:ngpt]
    return (
        kind = kind,
        pressure_hl = pressure_hl,
        layer_weight = layer_weight,
        flux_dn_true = flux_dn_true,
        flux_up_true = flux_up_true,
        flux_dn_fwd = flux_dn_fwd,
        flux_up_fwd = flux_up_fwd,
        heating_rate_true = heating_rate_true,
        heating_rate_fwd = heating_rate_fwd,
    )
end

# --- loss-input candidate vector packing -------------------------------------

gate4_candidate_length(nlay, ngpt) = nlay * ngpt + 2 * (nlay + 1) * ngpt

function gate4_pack_candidate(inputs)
    return vcat(vec(inputs.heating_rate_fwd),
                vec(inputs.flux_dn_fwd),
                vec(inputs.flux_up_fwd))
end

function gate4_unpack_candidate(x, nlay, ngpt)
    nlev = nlay + 1
    nheat = nlay * ngpt
    nflux = nlev * ngpt
    heating_fwd = reshape(x[1:nheat], nlay, ngpt)
    flux_dn_fwd = reshape(x[(nheat + 1):(nheat + nflux)], nlev, ngpt)
    flux_up_fwd = reshape(x[(nheat + nflux + 1):(nheat + 2 * nflux)], nlev, ngpt)
    return heating_fwd, flux_dn_fwd, flux_up_fwd
end

# Three loss variants at true SW32/LW32 shapes: the LW general path, the SW
# general path, and the SW fast path (the early-return branch reached when
# flux_profile_weight == broadband_weight == spectral_boundary_weight == 0).
function gate4_loss_variants(lw, sw)
    lw_general = x -> begin
        heating_fwd, flux_dn_fwd, flux_up_fwd =
            gate4_unpack_candidate(x, GATE4_NLAY, GATE4_NGPT)
        ecckd_lw_ckd_loss(;
            heating_rate_fwd = heating_fwd,
            heating_rate_true = lw.heating_rate_true,
            flux_dn_fwd = flux_dn_fwd,
            flux_up_fwd = flux_up_fwd,
            flux_dn_true = lw.flux_dn_true,
            flux_up_true = lw.flux_up_true,
            layer_weight = lw.layer_weight,
            flux_weight = 0.2,
            flux_profile_weight = 0.02,
            broadband_weight = 0.2,
        )
    end
    sw_general = x -> begin
        heating_fwd, flux_dn_fwd, flux_up_fwd =
            gate4_unpack_candidate(x, GATE4_NLAY, GATE4_NGPT)
        ecckd_sw_ckd_loss(;
            heating_rate_fwd = heating_fwd,
            heating_rate_true = sw.heating_rate_true,
            flux_dn_fwd = flux_dn_fwd,
            flux_up_fwd = flux_up_fwd,
            flux_dn_true = sw.flux_dn_true,
            flux_up_true = sw.flux_up_true,
            layer_weight = sw.layer_weight,
            flux_weight = 0.4,
            flux_profile_weight = 0.02,
            broadband_weight = 0.2,
        )
    end
    sw_fast = x -> begin
        heating_fwd, flux_dn_fwd, flux_up_fwd =
            gate4_unpack_candidate(x, GATE4_NLAY, GATE4_NGPT)
        ecckd_sw_ckd_loss(;
            heating_rate_fwd = heating_fwd,
            heating_rate_true = sw.heating_rate_true,
            flux_dn_fwd = flux_dn_fwd,
            flux_up_fwd = flux_up_fwd,
            flux_dn_true = sw.flux_dn_true,
            flux_up_true = sw.flux_up_true,
            layer_weight = sw.layer_weight,
            flux_weight = 0.4,
            flux_profile_weight = 0.0,
            broadband_weight = 0.0,
        )
    end
    return (
        (
            name = "lw_general",
            loss_function = "ecckd_lw_ckd_loss",
            path = "general",
            weights = (flux_weight = 0.2, flux_profile_weight = 0.02,
                       broadband_weight = 0.2),
            inputs = lw,
            f = lw_general,
        ),
        (
            name = "sw_general",
            loss_function = "ecckd_sw_ckd_loss",
            path = "general",
            weights = (flux_weight = 0.4, flux_profile_weight = 0.02,
                       broadband_weight = 0.2),
            inputs = sw,
            f = sw_general,
        ),
        (
            name = "sw_fast_path",
            loss_function = "ecckd_sw_ckd_loss",
            path = "fast (early-return branch, ecckd_original_objective_loss.jl:128)",
            weights = (flux_weight = 0.4, flux_profile_weight = 0.0,
                       broadband_weight = 0.0),
            inputs = sw,
            f = sw_fast,
        ),
    )
end

# --- timing ------------------------------------------------------------------

function gate4_median_timing(f; samples = GATE4_TIMING_SAMPLES)
    f()  # discarded warmup
    times = Vector{Float64}(undef, samples)
    for k in 1:samples
        start = time_ns()
        f()
        times[k] = (time_ns() - start) / 1.0e9
    end
    return (median_seconds = median(times), samples_seconds = times)
end

# --- Enzyme loss-input adjoints (NOT coefficient gradients) -------------------

# Same Duplicated/autodiff pattern as `enzyme_gradient_for_loss` in
# test/test_ckdmip_pipeline.jl:606-614.
function gate4_enzyme_loss_input_adjoint(enzyme, f, x)
    gradient = zeros(length(x))
    duplicated = Base.invokelatest(enzyme.Duplicated, copy(x), gradient)
    const_f = Base.invokelatest(enzyme.Const, f)
    Base.invokelatest(enzyme.autodiff, enzyme.Reverse, const_f,
                      enzyme.Active, duplicated)
    return gradient
end

# Deterministic 32-entry FD subset: 16 heating entries spread by stride plus
# 8 surface-downwelling and 8 TOA-upwelling flux entries, all of which carry
# nonzero sensitivity in every loss variant (general and fast path).
function gate4_fd_subset_indices(nlay, ngpt)
    nlev = nlay + 1
    nheat = nlay * ngpt
    nflux = nlev * ngpt
    indices = Int[]
    heating_stride = div(nheat - 1, 15)
    for k in 0:15
        push!(indices, 1 + k * heating_stride)
    end
    for k in 0:7
        g = 1 + 4 * k
        push!(indices, nheat + (g - 1) * nlev + nlev)      # surface downwelling
    end
    for k in 0:7
        g = 2 + 4 * k
        push!(indices, nheat + nflux + (g - 1) * nlev + 1) # TOA upwelling
    end
    length(indices) == GATE4_FD_SUBSET_SIZE ||
        error("FD subset must contain $(GATE4_FD_SUBSET_SIZE) entries")
    allunique(indices) || error("FD subset indices must be unique")
    return indices
end

# The losses are exactly quadratic in their inputs, so central differences are
# exact up to roundoff for any step; block-scaled steps control cancellation
# error (heating entries are O(1e-5) K s^-1, flux entries are O(100) W m^-2).
gate4_fd_step(index, nheat) =
    index <= nheat ? GATE4_FD_STEP_HEATING : GATE4_FD_STEP_FLUX

function gate4_central_fd_component(f, x, index, step)
    plus = copy(x)
    minus = copy(x)
    plus[index] += step
    minus[index] -= step
    return (f(plus) - f(minus)) / (2 * step)
end

function gate4_fd_max_rel_error(f, x, gradient, indices, nheat)
    max_rel = 0.0
    worst = first(indices)
    for index in indices
        fd = gate4_central_fd_component(f, x, index, gate4_fd_step(index, nheat))
        rel = abs(gradient[index] - fd) / max(abs(fd), eps(Float64))
        if rel > max_rel
            max_rel = rel
            worst = index
        end
    end
    return (max_rel_error = max_rel, worst_index = worst)
end

# --- Reactant compile probe of the real SW loss function with synthetic inputs --------------------------------

# Same Base.require / set_default_backend / Core.eval / @compile pattern as
# `reactant_compile_loss_probe` in test/test_ckdmip_pipeline.jl:616-644, at
# true SW32 shapes and with compile time recorded separately.
function gate4_reactant_probe(sw; samples = GATE4_TIMING_SAMPLES)
    shape = (nlay = GATE4_NLAY, ninterface = GATE4_NLEV, ngpt = GATE4_NGPT)
    try
        load_start = time_ns()
        reactant = Base.require(
            Base.PkgId(Base.UUID("3c362404-f566-11ee-1572-e11a4b42c853"), "Reactant"))
        load_seconds = (time_ns() - load_start) / 1.0e9
        Base.invokelatest(reactant.set_default_backend, "cpu")
        Core.eval(@__MODULE__, :(const GATE4_REACTANT = $reactant))
        probe = Core.eval(@__MODULE__, quote
            function gate4_reactant_sw_loss(heating_fwd, heating_true,
                                            flux_dn_fwd, flux_up_fwd,
                                            flux_dn_true, flux_up_true,
                                            layer_weight)
                return ecckd_sw_ckd_loss(;
                    heating_rate_fwd = heating_fwd,
                    heating_rate_true = heating_true,
                    flux_dn_fwd = flux_dn_fwd,
                    flux_up_fwd = flux_up_fwd,
                    flux_dn_true = flux_dn_true,
                    flux_up_true = flux_up_true,
                    layer_weight = layer_weight,
                    flux_weight = 0.4,
                    flux_profile_weight = 0.0,
                    broadband_weight = 0.0,
                )
            end
            gate4_heating_fwd_ra = GATE4_REACTANT.to_rarray($(sw.heating_rate_fwd))
            gate4_heating_true_ra = GATE4_REACTANT.to_rarray($(sw.heating_rate_true))
            gate4_flux_dn_fwd_ra = GATE4_REACTANT.to_rarray($(sw.flux_dn_fwd))
            gate4_flux_up_fwd_ra = GATE4_REACTANT.to_rarray($(sw.flux_up_fwd))
            gate4_flux_dn_true_ra = GATE4_REACTANT.to_rarray($(sw.flux_dn_true))
            gate4_flux_up_true_ra = GATE4_REACTANT.to_rarray($(sw.flux_up_true))
            gate4_layer_weight_ra = GATE4_REACTANT.to_rarray($(sw.layer_weight))
            gate4_compile_start = time_ns()
            gate4_compiled = GATE4_REACTANT.@compile raise = true raise_first = true sync = true gate4_reactant_sw_loss(
                gate4_heating_fwd_ra, gate4_heating_true_ra,
                gate4_flux_dn_fwd_ra, gate4_flux_up_fwd_ra,
                gate4_flux_dn_true_ra, gate4_flux_up_true_ra,
                gate4_layer_weight_ra)
            (
                compiled = gate4_compiled,
                args = (gate4_heating_fwd_ra, gate4_heating_true_ra,
                        gate4_flux_dn_fwd_ra, gate4_flux_up_fwd_ra,
                        gate4_flux_dn_true_ra, gate4_flux_up_true_ra,
                        gate4_layer_weight_ra),
                compile_seconds = (time_ns() - gate4_compile_start) / 1.0e9,
            )
        end)
        first_call_start = time_ns()
        first_value = Base.invokelatest(probe.compiled, probe.args...)
        first_call_seconds = (time_ns() - first_call_start) / 1.0e9
        steady_state = gate4_median_timing(
            () -> Base.invokelatest(probe.compiled, probe.args...); samples)
        reactant_value = Base.invokelatest(Float64, first_value)
        plain_value = ecckd_sw_ckd_loss(;
            heating_rate_fwd = sw.heating_rate_fwd,
            heating_rate_true = sw.heating_rate_true,
            flux_dn_fwd = sw.flux_dn_fwd,
            flux_up_fwd = sw.flux_up_fwd,
            flux_dn_true = sw.flux_dn_true,
            flux_up_true = sw.flux_up_true,
            layer_weight = sw.layer_weight,
            flux_weight = 0.4,
            flux_profile_weight = 0.0,
            broadband_weight = 0.0,
        )
        relative_difference = abs(reactant_value - plain_value) /
                              max(abs(plain_value), eps(Float64))
        return (
            status = "reactant_ok",
            backend = "cpu",
            shape = shape,
            loss_function = "ecckd_sw_ckd_loss",
            path = "fast (early-return branch)",
            load_seconds = load_seconds,
            compile_seconds = probe.compile_seconds,
            first_call_seconds = first_call_seconds,
            steady_state = steady_state,
            plain_julia_relative_difference = relative_difference,
            matches_plain_julia = relative_difference < 1.0e-8,
            error = nothing,
        )
    catch err
        return (
            status = "reactant_compile_failed",
            backend = "cpu",
            shape = shape,
            loss_function = "ecckd_sw_ckd_loss",
            path = "fast (early-return branch)",
            load_seconds = nothing,
            compile_seconds = nothing,
            first_call_seconds = nothing,
            steady_state = nothing,
            plain_julia_relative_difference = nothing,
            matches_plain_julia = false,
            error = sprint(showerror, err),
        )
    end
end

# --- SW32 recovery-vector plumbing (published NetCDF, not CKDMIP data) --------

function gate4_recovery_vector_plumbing(; samples = GATE4_TIMING_SAMPLES)
    reference = official_ecckd_definition_path(:shortwave_32)
    names = vectorized_array_names(reference)
    flatten_timing = gate4_median_timing(
        () -> flatten_recovery_arrays(reference, names); samples)
    target, shapes = flatten_recovery_arrays(reference, names)
    write_timing, reflatten_timing, roundtrip = mktempdir() do dir
        candidate = joinpath(dir, "gate4_cost_probe_sw32_candidate.nc")
        write_timing = gate4_median_timing(
            () -> write_vector_candidate(reference, candidate, target, shapes);
            samples)
        reflatten_timing = gate4_median_timing(
            () -> flatten_recovery_arrays(candidate, names); samples)
        reflattened, _ = flatten_recovery_arrays(candidate, names)
        return write_timing, reflatten_timing,
               vector_roundtrip_error(target, reflattened)
    end
    return (
        reference_filename = basename(reference),
        flattened_array_names = names,
        array_count = length(names),
        parameter_count = length(target),
        expected_parameter_count = GATE4_EXPECTED_PARAMETER_COUNT,
        flatten = flatten_timing,
        write_candidate = write_timing,
        reflatten = reflatten_timing,
        roundtrip_max_abs_error = roundtrip.max_abs_error,
        roundtrip_l1_relative_error = roundtrip.l1_relative_error,
    )
end

# --- provenance ----------------------------------------------------------------

function gate4_manifest_version(manifest, name)
    haskey(manifest, "deps") && haskey(manifest["deps"], name) ||
        return "missing_from_test_manifest"
    entry = first(manifest["deps"][name])
    return get(entry, "version", "unversioned")
end

function gate4_provenance(plumbing)
    branch = try
        readchomp(setenv(`git rev-parse --abbrev-ref HEAD`; dir = ABR_ROOT))
    catch
        "unknown"
    end
    manifest = TOML.parsefile(joinpath(ABR_ROOT, "test", "Manifest.toml"))
    return (
        branch = branch,
        worktree_path = ABR_ROOT,
        sw32_definition_filename = plumbing.reference_filename,
        sw32_flattened_array_names = plumbing.flattened_array_names,
        julia_version_runtime = string(VERSION),
        julia_version_test_manifest = get(manifest, "julia_version", "unknown"),
        enzyme_version_test_manifest = gate4_manifest_version(manifest, "Enzyme"),
        reactant_version_test_manifest = gate4_manifest_version(manifest, "Reactant"),
    )
end

# --- main probe ----------------------------------------------------------------

function run_gate4_cost_probe()
    failures = String[]
    shape = (nlay = GATE4_NLAY, ninterface = GATE4_NLEV, ngpt = GATE4_NGPT,
             loss_input_vector_length = gate4_candidate_length(GATE4_NLAY, GATE4_NGPT))
    lw = gate4_synthetic_inputs(:longwave)
    sw = gate4_synthetic_inputs(:shortwave)
    variants = gate4_loss_variants(lw, sw)
    nheat = GATE4_NLAY * GATE4_NGPT
    subset = gate4_fd_subset_indices(GATE4_NLAY, GATE4_NGPT)

    println("Timing loss kernels at SW32/LW32 shapes ...")
    loss_timings = NamedTuple[]
    for variant in variants
        x0 = gate4_pack_candidate(variant.inputs)
        value = variant.f(x0)
        isfinite(value) ||
            push!(failures, "loss value not finite for $(variant.name)")
        timing = gate4_median_timing(() -> variant.f(x0))
        push!(loss_timings, (
            name = variant.name,
            loss_function = variant.loss_function,
            path = variant.path,
            weights = variant.weights,
            median_seconds = timing.median_seconds,
            samples_seconds = timing.samples_seconds,
        ))
    end

    println("Loading Enzyme and timing loss-input adjoints ...")
    enzyme = try
        Base.require(
            Base.PkgId(Base.UUID("7da242da-08ed-463a-9acd-ee780be4f1d9"), "Enzyme"))
    catch err
        push!(failures, "enzyme_load_failed: " * sprint(showerror, err))
        nothing
    end
    enzyme_loss_input_adjoint_timings = NamedTuple[]
    enzyme_loss_input_adjoint_fd_variants = NamedTuple[]
    for variant in variants
        enzyme === nothing && break
        x0 = gate4_pack_candidate(variant.inputs)
        try
            gradient = gate4_enzyme_loss_input_adjoint(enzyme, variant.f, x0)
            timing = gate4_median_timing(
                () -> gate4_enzyme_loss_input_adjoint(enzyme, variant.f, x0))
            fd = gate4_fd_max_rel_error(variant.f, x0, gradient, subset, nheat)
            fd.max_rel_error < GATE4_FD_GATE_THRESHOLD ||
                push!(failures,
                      "enzyme_loss_input_adjoint_fd_gate_failed[$(variant.name)]: " *
                      "max rel error $(fd.max_rel_error)")
            push!(enzyme_loss_input_adjoint_timings, (
                name = variant.name,
                loss_function = variant.loss_function,
                path = variant.path,
                median_seconds = timing.median_seconds,
                samples_seconds = timing.samples_seconds,
            ))
            push!(enzyme_loss_input_adjoint_fd_variants, (
                name = variant.name,
                max_rel_error = fd.max_rel_error,
                worst_index = fd.worst_index,
                gate = fd.max_rel_error < GATE4_FD_GATE_THRESHOLD ?
                       "passed" : "failed",
            ))
        catch err
            push!(failures,
                  "enzyme_loss_input_adjoint_failed[$(variant.name)]: " *
                  sprint(showerror, err))
        end
    end
    enzyme_fd_gate_passed = enzyme !== nothing &&
        length(enzyme_loss_input_adjoint_fd_variants) == length(variants) &&
        all(v -> v.gate == "passed", enzyme_loss_input_adjoint_fd_variants)

    println("Loading Reactant and compiling the real SW loss function with synthetic inputs (may take minutes) ...")
    reactant = gate4_reactant_probe(sw)
    if reactant.status != "reactant_ok"
        push!(failures, "reactant_compile_failed: $(reactant.error)")
    elseif !reactant.matches_plain_julia
        push!(failures,
              "reactant_value_mismatch: relative difference " *
              "$(reactant.plain_julia_relative_difference)")
    end

    println("Timing SW32 recovery-vector flatten/write/reflatten plumbing ...")
    plumbing = gate4_recovery_vector_plumbing()
    parameter_count_gate_passed =
        plumbing.parameter_count == GATE4_EXPECTED_PARAMETER_COUNT
    parameter_count_gate_passed ||
        push!(failures,
              "sw32_parameter_count_gate_failed: got $(plumbing.parameter_count), " *
              "expected $(GATE4_EXPECTED_PARAMETER_COUNT)")
    roundtrip_gate_passed = plumbing.roundtrip_max_abs_error == 0.0 &&
                            plumbing.roundtrip_l1_relative_error == 0.0
    roundtrip_gate_passed ||
        push!(failures,
              "sw32_roundtrip_zero_error_gate_failed: " *
              "($(plumbing.roundtrip_max_abs_error), " *
              "$(plumbing.roundtrip_l1_relative_error))")

    sw_general_timing = only(t for t in loss_timings if t.name == "sw_general")
    fd_evaluations = 2 * GATE4_EXPECTED_PARAMETER_COUNT
    extrapolated_fd_gradient_seconds =
        sw_general_timing.median_seconds * fd_evaluations
    fd_infeasibility = (
        basis = "median ecckd_sw_ckd_loss general-path evaluation at synthetic SW32 shapes",
        single_loss_median_seconds = sw_general_timing.median_seconds,
        parameter_count = GATE4_EXPECTED_PARAMETER_COUNT,
        loss_evaluations_for_central_fd = fd_evaluations,
        extrapolated_fd_gradient_seconds = extrapolated_fd_gradient_seconds,
        extrapolated_fd_gradient_hours = extrapolated_fd_gradient_seconds / 3600,
        note = "cost of ONE central-finite-difference gradient over the " *
               "204,896-parameter SW32 vector at a single-loss-evaluation " *
               "price; the real objective sums many profiles, so this is a " *
               "lower bound",
    )

    gates = (
        enzyme_loss_input_adjoint_fd_gate = enzyme_fd_gate_passed ?
                                            "passed" : "failed",
        sw32_parameter_count_gate = parameter_count_gate_passed ?
                                    "passed" : "failed",
        sw32_roundtrip_zero_error_gate = roundtrip_gate_passed ?
                                         "passed" : "failed",
        reactant_compile_gate = reactant.status == "reactant_ok" ?
                                "passed" : "failed",
    )

    return (
        case = "gate4_cost_probe",
        data_mode = "synthetic_shapes_only",
        status = isempty(failures) ? "probe_complete" : "probe_partial",
        timestamp_utc = string(Dates.now(Dates.UTC)),
        coefficient_gradient_status = "blocked_no_differentiable_forward_map",
        p2_dependency = "coefficients_to_optical_depth_to_flux_forward_map",
        disclaimer = GATE4_DISCLAIMER,
        provenance = gate4_provenance(plumbing),
        synthetic_shapes = merge(shape, (
            construction = "deterministic index-seeded ramps and sinusoids; no RNG",
            layer_weight_construction = "normalized sqrt-pressure increments " *
                "(ckdmip_layer_weight construction on a synthetic pressure grid)",
            flux_magnitude = "O(100) W m^-2",
            heating_magnitude = "O(1) K day^-1 (stored in K s^-1 as the loss expects)",
        )),
        timing_samples_per_measurement = GATE4_TIMING_SAMPLES,
        timing_protocol = "median of $(GATE4_TIMING_SAMPLES) samples after one discarded warmup",
        loss_timings = (shape = shape, variants = loss_timings),
        enzyme_loss_input_adjoint_note = "adjoints w.r.t. the assembled " *
            "candidate heating/flux arrays only; NOT coefficient gradients",
        enzyme_loss_input_adjoint_timings = (shape = shape,
                                             variants = enzyme_loss_input_adjoint_timings),
        enzyme_loss_input_adjoint_fd_check = (
            gate_threshold = GATE4_FD_GATE_THRESHOLD,
            subset_size = GATE4_FD_SUBSET_SIZE,
            subset_description = "16 heating entries (stride) + 8 surface " *
                "downwelling + 8 TOA upwelling entries, deterministic",
            fd_step_heating_block = GATE4_FD_STEP_HEATING,
            fd_step_flux_blocks = GATE4_FD_STEP_FLUX,
            step_note = "losses are exactly quadratic in their inputs, so " *
                "central differences are exact up to roundoff; block-scaled " *
                "steps control cancellation error",
            variants = enzyme_loss_input_adjoint_fd_variants,
        ),
        reactant = reactant,
        recovery_vector_plumbing = plumbing,
        fd_infeasibility = fd_infeasibility,
        gates = gates,
        failures = failures,
    )
end

# --- reporting -----------------------------------------------------------------

gate4_fmt(x) = x === nothing ? "n/a" : string(round(x; sigdigits = 4))
gate4_fmt_samples(samples) =
    samples === nothing ? "n/a" : join(gate4_fmt.(samples), ", ")

function markdown_gate4_cost_probe(result)
    lines = String[
        "# Gate-4 Cost Probe (P1a)",
        "",
        "Status: **$(result.status)**",
        "",
        "Data mode: `$(result.data_mode)`",
        "",
        "> Disclaimer: $(result.disclaimer)",
        "",
        "Coefficient-gradient status: `$(result.coefficient_gradient_status)` " *
        "(P2 dependency: `$(result.p2_dependency)`).",
        "",
        "Shapes: $(result.synthetic_shapes.nlay) layers, " *
        "$(result.synthetic_shapes.ninterface) interfaces, " *
        "$(result.synthetic_shapes.ngpt) g-points; loss-input vector length " *
        "$(result.synthetic_shapes.loss_input_vector_length). " *
        "$(result.timing_protocol).",
        "",
        "## Provenance",
        "",
        "| Field | Value |",
        "|---|---|",
        "| Branch | `$(result.provenance.branch)` |",
        "| Worktree | `$(result.provenance.worktree_path)` |",
        "| SW32 definition | `$(result.provenance.sw32_definition_filename)` |",
        "| Julia (runtime / test manifest) | $(result.provenance.julia_version_runtime) / $(result.provenance.julia_version_test_manifest) |",
        "| Enzyme (test manifest) | $(result.provenance.enzyme_version_test_manifest) |",
        "| Reactant (test manifest) | $(result.provenance.reactant_version_test_manifest) |",
        "",
        "## Loss-kernel timings",
        "",
        "| Variant | Path | Median s | Samples s |",
        "|---|---|---:|---|",
    ]
    for t in result.loss_timings.variants
        push!(lines, "| `$(t.name)` | $(t.path) | $(gate4_fmt(t.median_seconds)) | $(gate4_fmt_samples(t.samples_seconds)) |")
    end
    append!(lines, [
        "",
        "## Enzyme loss-input adjoints",
        "",
        "$(result.enzyme_loss_input_adjoint_note).",
        "",
        "| Variant | Median s | FD max rel error | Gate (< $(result.enzyme_loss_input_adjoint_fd_check.gate_threshold)) |",
        "|---|---:|---:|---|",
    ])
    for t in result.enzyme_loss_input_adjoint_timings.variants
        fd_rows = [v for v in result.enzyme_loss_input_adjoint_fd_check.variants
                   if v.name == t.name]
        fd = isempty(fd_rows) ? nothing : only(fd_rows)
        push!(lines,
              "| `$(t.name)` | $(gate4_fmt(t.median_seconds)) | " *
              (fd === nothing ? "n/a | n/a |" :
               "$(gate4_fmt(fd.max_rel_error)) | $(fd.gate) |"))
    end
    append!(lines, [
        "",
        "## Reactant (real SW loss function with synthetic inputs, $(result.reactant.backend) backend)",
        "",
        "| Metric | Value |",
        "|---|---:|",
        "| Status | $(result.reactant.status) |",
        "| Package load s | $(gate4_fmt(result.reactant.load_seconds)) |",
        "| Compile s | $(gate4_fmt(result.reactant.compile_seconds)) |",
        "| First call s | $(gate4_fmt(result.reactant.first_call_seconds)) |",
        "| Steady-state median s | $(result.reactant.steady_state === nothing ? "n/a" : gate4_fmt(result.reactant.steady_state.median_seconds)) |",
        "| Matches plain Julia | $(result.reactant.matches_plain_julia) |",
    ])
    if result.reactant.error !== nothing
        push!(lines, "", "Reactant error: `$(result.reactant.error)`")
    end
    plumbing = result.recovery_vector_plumbing
    append!(lines, [
        "",
        "## SW32 recovery-vector plumbing",
        "",
        "| Metric | Value |",
        "|---|---:|",
        "| Reference | `$(plumbing.reference_filename)` |",
        "| Arrays | $(plumbing.array_count) |",
        "| Parameters | $(plumbing.parameter_count) (expected $(plumbing.expected_parameter_count)) |",
        "| Flatten median s | $(gate4_fmt(plumbing.flatten.median_seconds)) |",
        "| Write-candidate median s | $(gate4_fmt(plumbing.write_candidate.median_seconds)) |",
        "| Reflatten median s | $(gate4_fmt(plumbing.reflatten.median_seconds)) |",
        "| Round-trip max abs error | $(plumbing.roundtrip_max_abs_error) |",
        "| Round-trip L1 relative error | $(plumbing.roundtrip_l1_relative_error) |",
        "",
        "## FD-infeasibility extrapolation",
        "",
        "| Metric | Value |",
        "|---|---:|",
        "| Single-loss median s | $(gate4_fmt(result.fd_infeasibility.single_loss_median_seconds)) |",
        "| Central-FD loss evaluations | $(result.fd_infeasibility.loss_evaluations_for_central_fd) |",
        "| Extrapolated FD gradient s | $(gate4_fmt(result.fd_infeasibility.extrapolated_fd_gradient_seconds)) |",
        "| Extrapolated FD gradient h | $(gate4_fmt(result.fd_infeasibility.extrapolated_fd_gradient_hours)) |",
        "",
        result.fd_infeasibility.note * ".",
        "",
        "## Gates",
        "",
        "| Gate | Outcome |",
        "|---|---|",
        "| Enzyme loss-input adjoint vs FD | $(result.gates.enzyme_loss_input_adjoint_fd_gate) |",
        "| SW32 parameter count == $(GATE4_EXPECTED_PARAMETER_COUNT) | $(result.gates.sw32_parameter_count_gate) |",
        "| SW32 round-trip exactly zero | $(result.gates.sw32_roundtrip_zero_error_gate) |",
        "| Reactant compile | $(result.gates.reactant_compile_gate) |",
        "",
        "## Failures",
        "",
    ])
    if isempty(result.failures)
        push!(lines, "None.")
    else
        append!(lines, ["- $(failure)" for failure in result.failures])
    end
    return join(lines, "\n") * "\n"
end

function gate4_cost_probe_main()
    result = run_gate4_cost_probe()
    write_json(GATE4_COST_PROBE_JSON, result)
    write(GATE4_COST_PROBE_MD, markdown_gate4_cost_probe(result))
    print(markdown_gate4_cost_probe(result))
    println("Wrote $GATE4_COST_PROBE_JSON")
    println("Wrote $GATE4_COST_PROBE_MD")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    gate4_cost_probe_main()
end
