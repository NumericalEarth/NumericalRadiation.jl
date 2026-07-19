# # CKDMIP Data Inventory
#
# CKDMIP and ecCKD workflows use data in very different size classes. The
# package can resolve small ecRad/ecCKD assets through artifacts, while the full
# CKDMIP spectra and derived flux products live in a user-managed data tree.
# This example inventories local state without downloading anything.

using NumericalRadiation
using Printf

# ## Locate candidate data roots
#
# `RH_CKDMIP_DATA_PATH` is the training/recovery path. `CKDMIP_DATA_DIR` is
# accepted for compatibility with earlier examples, and `$HOME/data/ckdmip` is
# a conventional local fallback.

function candidate_ckdmip_roots()
    roots = String[]
    for key in ("RH_CKDMIP_DATA_PATH", "CKDMIP_DATA_DIR")
        value = strip(get(ENV, key, ""))
        isempty(value) || push!(roots, abspath(expanduser(value)))
    end
    push!(roots, abspath(joinpath(homedir(), "data", "ckdmip")))
    return unique(roots)
end

function first_existing_root(roots)
    for root in roots
        isdir(root) && return root
    end
    return first(roots)
end

ckdmip_root = first_existing_root(candidate_ckdmip_roots());
nothing #hide

# ## Check the layout

const EXPECTED_ITEMS = [
    ("data root", String[], true, "CKDMIP root"),
    ("evaluation1", ["evaluation1"], true, "primary evaluation set"),
    ("evaluation1 conc", ["evaluation1", "conc"], true, "gas concentrations"),
    ("evaluation1 LW spectra", ["evaluation1", "lw_spectra"], true, "line-by-line longwave spectra"),
    ("evaluation1 SW spectra", ["evaluation1", "sw_spectra"], true, "line-by-line shortwave spectra"),
    ("evaluation1 LW fluxes", ["evaluation1", "lw_fluxes"], false, "public and locally derived LW fluxes"),
    ("evaluation1 SW fluxes", ["evaluation1", "sw_fluxes"], false, "public and locally derived SW fluxes"),
    ("evaluation2", ["evaluation2"], false, "held-out evaluation set"),
]

function count_files(path)
    isdir(path) || return 0
    return count(name -> isfile(joinpath(path, name)), readdir(path))
end

function item_status(root, parts)
    path = isempty(parts) ? root : joinpath(root, parts...)
    return (path = path, present = isdir(path), files = count_files(path))
end

ckdmip_configured = any(key -> !isempty(strip(get(ENV, key, ""))),
                        ("RH_CKDMIP_DATA_PATH", "CKDMIP_DATA_DIR"))
ckdmip_status = isdir(ckdmip_root) ? "present" :
    ckdmip_configured ? "configured (missing)" : "missing"

println("ecRad data artifact: ",
        ecrad_data_path(; require = false) === nothing ? "missing" : "available")
println("ecCKD source artifact: ",
        ecckd_source_path(; require = false) === nothing ? "missing" : "available")
println("CKDMIP data root: ", ckdmip_status)
println("Official ecCKD definition files: ", length(official_ecckd_model_inventory()))

println()
println("Expected CKDMIP/ecCKD inventory")
println("--------------------------------------------------------------------------")
@printf("%-24s %-10s %-8s %-7s %s\n", "category", "status", "required", "files", "path")
println("--------------------------------------------------------------------------")

for (label, parts, required, _note) in EXPECTED_ITEMS
    status = item_status(ckdmip_root, parts)
    word = status.present ? "present" : required ? "missing" : "optional"
    rel = status.path == ckdmip_root ? "." : relpath(status.path, ckdmip_root)
    @printf("%-24s %-10s %-8s %-7d %s\n", label, word, required ? "yes" : "no", status.files, rel)
end

println("--------------------------------------------------------------------------")

# ## Interpret the result
#
# Missing public spectra block exact ecCKD objective reconstruction. Missing
# `5gas-*` or `rel-*` fluxes do not mean the public CKDMIP archive is
# incomplete; those are derived ecCKD training products generated locally from
# spectra.

