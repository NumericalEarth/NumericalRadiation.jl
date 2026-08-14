# PAPER-ONLY X1 design draft, revision 3 (monitor ruling applied)
# X1-FIRST approved; C1 deferred; C2 deferred. No code, no submission,
# no experiment until monitor review of this revision.
# Baseline: S1 completion ledger committed at 5b6cea7.

## Ruling applied
- The earlier "clean trichotomy" is WITHDRAWN and replaced by the
  fail-closed three-axis lattice below.
- Removed: "x_local and ckd_model identical -> mapping/write origin";
  all "move to the foreground" language; "zero optimization-path
  effect by construction".
- Replacement stance: capture executes post-return; NON-PERTURBATION
  IS AN EMPIRICAL ALL-47-VARIABLE IDENTITY GATE against the in-job
  pristine arm, never a construction claim.

## Fail-closed three-axis lattice (monitor wording, binding)
Axis A: returned internal x vs the EXACT x_min/x_max vectors passed to
        minimize (log space, synthetic lowers included).
Axis B: callback mapping of x (exp with MIN_X zero-floor, replicating
        solve_adept.cpp:225-234) vs caller ckd_model.x.
Axis C: caller ckd_model.x vs serialized raw2 coefficients under a
        PROVEN index/write mapping (trace below; positional readback
        verified in-ledger).
NO mechanism conclusion is licensed unless the relevant mapping is
demonstrated. Required interpretations:
- A in-bounds + B differs: supports a LOCAL caller-state/mapping
  discrepancy -- not automatic desync causation.
- A out-of-bounds: establishes ONLY that the captured returned x lies
  outside the provided vectors for this run; algorithm vs
  bound-construction semantics remain to be distinguished.
- B equal + C differs: supports serialization/index mapping.
- A/B/C mutually inconsistent with the existing census: instrument
  REFUSAL, never elimination.

## Read-only source trace: ckd_model.x index ordering into raw2
(exact artifact lines; Agent 42 to audit independently)
1. State-vector layout (ckd_model.cpp read path): x is ONE flat
   vector; for each ACTIVE gas, a contiguous slice is SHARED-STORAGE
   soft-linked into that gas's coefficient array:
   - LUT gas (h2o): `this_gas.molar_abs_conc >>=
     x(range(ix, ix+nconc*nt_*np_*ng_-1)).reshape(nconc,nt_,np_,ng_)`
     (ckd_model.cpp:143), bounds slices likewise (:146-148),
     `this_gas.ix = ix; ix += nconc*nt_*np_*ng_` (:149-150).
   - linear/relative-linear gases: `this_gas.molar_abs >>=
     x(range(ix, ix+nt_*np_*ng_-1)).reshape(nt_,np_,ng_)` (:206),
     bounds likewise (:209-210), `ix += nt_*np_*ng_` (:213).
   - Slice ORDER = the model constituent / single_gas_data_ READ
     order (list built as gases are read from the model file),
     FILTERED by active membership -- NOT inherently the config
     gas-string order. The X1 ledger must GATE that this run
     resolves to composite, h2o, o3, co2 with block sizes 10,176 /
     122,112 / 10,176 / 10,176 (offsets 0 / 10,176 / 132,288 /
     142,464; total 152,640 = the census active count); the in-job
     log lines ("Reading absorption properties of ..." order,
     ACTIVE banners, "State variable size") cross-check it, and
     any deviation is instrument refusal.
2. Serialization (ckd_model.cpp write path): `file.write(
   (this_gas.molar_abs).inactive_link(), molecule + "_" + K_NAME)` at
   :565/:576/:586 writes THE SAME linked storage verbatim (physical
   values; inactive_link strips autodiff only, no transform) to
   variable `<gas>_molar_absorption_coeff` with dims matching raw2
   (temperature=6, pressure=53, g_point=32; +h2o_mole_fraction=12).
3. Storage/index equivalence between the x slice and the serialized
   variable is established ONLY by the source links above PLUS the
   required per-index positional round-trip in the ledger (readback
   comparison of the captured caller vector against raw2); no
   memory-layout convention is assumed or asserted.
4. Caveat retained: solve_adept's LOCAL x is log-space
   (x = log(ckd_model.x) with MIN_X floor, :315-321); its log-space
   bound copies are built at :324. ckd_model.x itself is physical.

## Complete per-index sidecar schema (all 152,640 active indices)
Fields per index i:
- gas_id + numeric intra-gas multi-index (iconc?, it, ip, ig) +
  global x index i + gas slice offset (this_gas.ix); gas names are
  recorded once as sidecar metadata
- returned_x_log: x_local[i] exactly as returned (float64)
- bound_lo_log, bound_hi_log: the EXACT log-space x_min/x_max
  entries passed to minimize, preserved verbatim even where a bound
  is inactive (no NaN or sentinel substitution ever)
- separate classification fields: lower_class (file-lower /
  synthetic-lower / none) and upper_active flag
- mapped_x_phys: exp/MIN_X-floor mapping of returned_x_log
  (replicating callback semantics :225-234)
- caller_phys: ckd_model.x[i] at capture time (pre-write), full
  double precision
- caller_phys_f32: the round-to-nearest-even Float32 projection of
  caller_phys (stored explicitly so the Axis-C comparison against the
  Float32 raw2 variables is exact and auditable per index; Agent 42
  amendment, adopted)
Record-level fields: minimizer status code (integer + string), arm id,
capture location tag (is_bounded branch), job id.
ENCODING: the sidecar exists for the X1 ARM ONLY (the pristine arm
is uninstrumented by definition); gas_id and multi-indices encoded
NUMERICALLY (int arrays) with the gas-name table recorded once as
metadata; Float64 fields stored as NetCDF DOUBLE and caller_phys_f32
as NetCDF FLOAT (no text formatting anywhere on the numeric path);
ATOMIC PRIVATE WRITE: dot-temp, close, rename within the job-private
RUNROOT, and a missing/unwritable private output path FAILS CLOSED
(job refusal, never a skip); sha-echoed in the job log; never
canonical.

## Instrument placement (Agent 42 design facts, adopted)
The bounded call at solve_adept.cpp:366 returns minimize(...) directly;
X1 restructures to `status = minimize(...); CAPTURE; return status;`
inside the is_bounded branch. The unbounded branch at :370 remains
unchanged and is gated as such. The call-site restructuring is small;
the separately pinned sidecar-writer helper is not included in a
line-count claim. Anchored-pin machinery is identical to S1
(original/patched pins, region hash, registered-file tree identity).
Capture executes post-return; const reads plus one private RUNROOT
write; non-perturbation is the empirical all-47-variable identity gate
against the pristine arm.

## Evidence contract (X1 job + completion ledger)
- Paired arms, one job, TWO immutable saved binaries built from ONE
  pinned source/configure tree: pristine control + X1 instrumented; S1 machinery reused (frozen template, tree pins,
  per-arm OMP logging, banner/bounded gates, dual receipts).
- Identity gate: X1-arm raw2 elementwise identical to pristine-arm
  raw2 (all 47 variables; typed attrs; exact-set config/history) --
  REFUSAL of the instrument if violated.
- Ledger computes the three axes with the committed log-space census
  kernel definitions; positional Axis-C readback under the traced
  mapping; census on returned/mapped/caller vectors; the lattice
  interpretations verbatim; all findings LOCAL to this rebuilt
  trajectory; ceiling discipline unchanged (no historical
  attribution; provenance conditional; Adept statements
  source-observed with pins).
- RUNTIME: build ~5 min + 2 arms ~35 min each (~75-80 min compute).

## Sequence (approved)
X1 first. C1 deferred (config-only bounds-off; ~40 min; quantifies the
flag factor for this fixed setup only; discriminates no mechanism;
run only if X1 makes the bounds factor decision-relevant). C2 deferred.

## AXIS-C REFINEMENT: serialization type conversion (monitor, binding)
ckd_model.cpp defines the coefficient variables as FLOAT (Float32) at
:396/:432/:459 while caller state is Float64; the write at
:565/:576/:586/:598 therefore projects. Axis C accordingly requires:
raw2 values EQUAL the correctly rounded Float32 projection
(Float32(caller_phys[i])) of caller state under the proven
gas/shape/index order -- covering BOTH the standard 3-D gas arrays
(composite/o3/co2: nt,np,ng) AND the LUT concentration slices
(h2o: nconc,nt,np,ng) -- with the active-gas concatenation order
itself gated (composite, h2o, o3, co2; block offsets 0 / 10,176 /
132,288 / 142,464; total 152,640). ANY mismatch in order, dimensions,
or the expected Float32 projection is INSTRUMENT REFUSAL, never a
finding.
Corollary for lattice-consistency checks: the committed census was
computed on raw2 (Float32-projected) values against Float64 bounds;
sidecar-based censuses on Float64 caller state may differ marginally
at bound-adjacent indices. The "A/B/C inconsistent with the existing
census -> REFUSAL" branch must therefore compare like-with-like:
raw2-domain census vs Float32-projected caller census; Float64-domain
comparisons reported separately.

## Agent 42 Axis-C audit convergence (independent, read-only)
Proven chain confirmed with exact citations (membership+order via
single_gas_data_ iteration; layout links :143/:206 with bounds
mirrors; write of the SAME linked storage :565/:576 with _min/_max
:567-568/:578; 10,176+122,112+10,176+10,176 = 152,640 = logged state
size). Confirmed: NO copy or transform between caller state and
serialization on this path other than the type projection above; the
relevant solver-to-caller mapping ON THIS TRACED PATH is the callback exp/MIN_X INTO
ckd_model.x (:225-234). The source links establish shared storage but
do not by themselves establish index order; the positional sidecar
round-trip is the sole index-order proof, now with the Float32
projection explicit.
Their sidecar schema matches this draft's (adding the applicability
class file-lower/synthetic-lower/none, adopted); lattice language and
the identity-gate-as-sole-non-perturbation-proof adopted verbatim on
both sides.
