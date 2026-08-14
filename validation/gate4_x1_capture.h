// gate4_x1_capture.h - Gate-4 X1 direct post-minimize state-capture
// instrument (diagnosis unit; PRIVATE NetCDF sidecar; never canonical).
//
// Contract (Gate-4 X1 frozen design d4f8a689aa4fcadb91922120b7806939
// bba88c115fb6281d51b2fc3dbe325398):
// - capture executes strictly AFTER minimize() returns and before the
//   caller serializes; const reads plus ONE private atomic write
// - FAIL CLOSED: any capture problem (env/path/mapping/write/rename)
//   terminates the process with exit code 93 so the arm can never
//   silently continue uninstrumented; a missing GATE4_X1_CAPTURE_PATH
//   is a refusal, never a skip
// - lower_class/upper_active are computed PRE-minimize (record_pre)
//   from the PHYSICAL member state, because ckd_model.x is
//   callback-mutated during minimize and the synthetic-lower
//   predicate must be evaluated against the initial state
// - bound vectors are stored EXACTLY as passed to minimize, including
//   inactive -/+ std::numeric_limits<Real>::max() initialization
//   values from adept::minimizer_initialize_bounds; no NaN or
//   sentinel substitution ever
// - the x-index mapping is derived AT RUNTIME by pointer arithmetic
//   on the shared soft-linked storage and gated bijective; no
//   memory-layout convention is assumed or asserted
// - OutputDataFile infers format from the LAST filename extension, so
//   the same-directory temp name must itself end in ".nc"
#ifndef GATE4_X1_CAPTURE_H
#define GATE4_X1_CAPTURE_H 1

#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <string>
#include <vector>
#include <sys/stat.h>

#include <adept_arrays.h>
#include <adept/Minimizer.h>

#include "ckd_model.h"
#include "OutputDataFile.h"

namespace gate4_x1 {

static const int EXIT_CAPTURE_REFUSED = 93;

inline void refuse(const std::string& why) {
  std::fprintf(stderr, "X1 CAPTURE REFUSED: %s\n", why.c_str());
  std::fflush(stderr);
  std::exit(EXIT_CAPTURE_REFUSED);
}

inline std::string require_env(const char* name) {
  const char* v = std::getenv(name);
  if (!v || !*v) refuse(std::string(name) + " unset or empty");
  return std::string(v);
}

struct PreState {
  // 0 = none, 1 = file-lower, 2 = synthetic-lower
  std::vector<int> lower_class;
  std::vector<int> upper_active;
  bool recorded;
  PreState() : recorded(false) { }
};

// Must be called PRE-minimize: replicates the bound-construction
// predicates of solve_adept (file-lower: model x_min > 0;
// synthetic-lower: model x_min == 0 && initial physical x > 0 &&
// model x_max > 0; upper active: model x_max > 0) against the INITIAL
// physical state.
inline PreState record_pre(CkdModel<true>& m) {
  PreState p;
  int n = m.nx();
  if (n <= 0) refuse("record_pre: empty state vector");
  if ((int) m.x_min.size() != n || (int) m.x_max.size() != n)
    refuse("record_pre: physical bound vectors do not match nx");
  Vector xphys = m.x.inactive_link();
  p.lower_class.resize(n);
  p.upper_active.resize(n);
  for (int i = 0; i < n; ++i) {
    if (m.x_min(i) > 0.0) {
      p.lower_class[i] = 1;
    }
    else if (m.x_min(i) == 0.0 && xphys(i) > 0.0 && m.x_max(i) > 0.0) {
      p.lower_class[i] = 2;
    }
    else {
      p.lower_class[i] = 0;
    }
    p.upper_active[i] = (m.x_max(i) > 0.0) ? 1 : 0;
  }
  p.recorded = true;
  return p;
}

struct GasBlock {
  std::string name;
  int gas_id;
  int offset;
  int size;
  int nconc, nt, np, ng; // nconc = -1 for 3-D (non-LUT) gases
};

inline void write_capture(CkdModel<true>& m,
                          const Vector& x_returned,
                          const Vector& x_min_passed,
                          const Vector& x_max_passed,
                          const PreState& pre,
                          adept::MinimizerStatus status,
                          Real min_x_log_floor) {
  if (!pre.recorded) refuse("pre-minimize record missing");
  int n = m.nx();
  if (n <= 0) refuse("empty state vector");
  if ((int) x_returned.size() != n) refuse("returned x length != nx");
  if ((int) x_min_passed.size() != n || (int) x_max_passed.size() != n)
    refuse("passed bound vector length != nx");
  if ((int) pre.lower_class.size() != n
      || (int) pre.upper_active.size() != n)
    refuse("pre-minimize record length != nx");

  std::string target = require_env("GATE4_X1_CAPTURE_PATH");
  std::string arm    = require_env("GATE4_X1_ARM");
  std::string jobid  = require_env("SLURM_JOB_ID");

  // naming rule: format is inferred from the LAST extension, so both
  // the final target and the same-directory temp name must end ".nc"
  if (target.size() < 4
      || target.compare(target.size() - 3, 3, ".nc") != 0)
    refuse("GATE4_X1_CAPTURE_PATH must end in .nc: " + target);
  std::string::size_type slash = target.find_last_of('/');
  if (slash == std::string::npos || slash + 1 >= target.size()
      || target[0] != '/')
    refuse("GATE4_X1_CAPTURE_PATH must be an absolute file path: "
           + target);
  std::string dir  = target.substr(0, slash);
  std::string base = target.substr(slash + 1);
  if (base[0] == '.')
    refuse("target basename must not be hidden: " + base);
  std::string tmp = dir + "/.x1-capture." + jobid + "." + base;

  struct stat st;
  if (stat(target.c_str(), &st) == 0)
    refuse("target already exists (create-once): " + target);
  if (stat(tmp.c_str(), &st) == 0)
    refuse("temp already exists: " + tmp);
  if (stat(dir.c_str(), &st) != 0 || !S_ISDIR(st.st_mode))
    refuse("sidecar directory missing (fail closed, never a skip): "
           + dir);

  // Shared-storage base pointer of the caller state vector; the gas
  // coefficient arrays are soft-linked (>>=) into this storage, so
  // pointer arithmetic yields the TRUE flat x index of every array
  // element with no layout convention assumed.
  Vector xnow = m.x.inactive_link();
  if ((int) xnow.size() != n) refuse("caller state view length != nx");
  const Real* xbase = &xnow(0);
  if (&xnow(n - 1) - xbase != n - 1)
    refuse("caller state view is not contiguous");

  std::vector<int> vgas(n, -1), voff(n, -1), viconc(n, -1),
                   vit(n, -1), vip(n, -1), vig(n, -1);
  std::vector<GasBlock> blocks;
  long filled = 0;
  for (int igas = 0; igas < m.ngas(); ++igas) {
    SingleGasData<true>& g = m.single_gas(igas);
    if (!g.is_active) continue;
    GasBlock b;
    b.name = g.molecule;
    b.gas_id = (int) blocks.size();
    b.offset = g.ix;
    if (g.conc_dependence == LUT) {
      Array4D a = g.molar_abs_conc.inactive_link();
      b.nconc = a.dimension(0);
      b.nt    = a.dimension(1);
      b.np    = a.dimension(2);
      b.ng    = a.dimension(3);
      b.size  = b.nconc * b.nt * b.np * b.ng;
      for (int ic = 0; ic < b.nconc; ++ic)
      for (int it = 0; it < b.nt; ++it)
      for (int ip = 0; ip < b.np; ++ip)
      for (int ig = 0; ig < b.ng; ++ig) {
        long flat = &a(ic, it, ip, ig) - xbase;
        if (flat < 0 || flat >= n)
          refuse("mapped index out of range (gas " + b.name + ")");
        if (vgas[flat] != -1)
          refuse("duplicate mapping for x index (gas " + b.name + ")");
        vgas[flat] = b.gas_id;  voff[flat] = b.offset;
        viconc[flat] = ic; vit[flat] = it; vip[flat] = ip;
        vig[flat] = ig;
        ++filled;
      }
    }
    else {
      Array3D a = g.molar_abs.inactive_link();
      b.nconc = -1;
      b.nt    = a.dimension(0);
      b.np    = a.dimension(1);
      b.ng    = a.dimension(2);
      b.size  = b.nt * b.np * b.ng;
      for (int it = 0; it < b.nt; ++it)
      for (int ip = 0; ip < b.np; ++ip)
      for (int ig = 0; ig < b.ng; ++ig) {
        long flat = &a(it, ip, ig) - xbase;
        if (flat < 0 || flat >= n)
          refuse("mapped index out of range (gas " + b.name + ")");
        if (vgas[flat] != -1)
          refuse("duplicate mapping for x index (gas " + b.name + ")");
        vgas[flat] = b.gas_id;  voff[flat] = b.offset;
        vit[flat] = it; vip[flat] = ip; vig[flat] = ig;
        ++filled;
      }
    }
    blocks.push_back(b);
  }
  if (blocks.empty()) refuse("no active gases");
  if (filled != (long) n)
    refuse("index mapping does not cover the state vector exactly");

  int nblk = (int) blocks.size();
  Vector v_ret(n), v_lo(n), v_hi(n), v_map(n), v_phys(n);
  IntVector iv_gidx(n), iv_gas(n), iv_off(n), iv_iconc(n), iv_it(n),
            iv_ip(n), iv_ig(n), iv_lc(n), iv_ua(n);
  for (int i = 0; i < n; ++i) {
    iv_gidx(i) = i; // explicit zero-based global x index (frozen schema)
    v_ret(i)  = x_returned(i);
    v_lo(i)   = x_min_passed(i); // EXACT passed entries, incl. inactive
    v_hi(i)   = x_max_passed(i); // -/+ numeric_limits<Real>::max()
    // replicate the callback mapping semantics exactly:
    // if (xdata[ix] > MIN_X) x(ix) = exp(xdata[ix]); else x(ix) = 0.0;
    if (x_returned(i) > min_x_log_floor) {
      v_map(i) = std::exp(x_returned(i));
    }
    else {
      v_map(i) = 0.0;
    }
    v_phys(i) = xnow(i);
    iv_gas(i)   = vgas[i];
    iv_off(i)   = voff[i];
    iv_iconc(i) = viconc[i];
    iv_it(i)    = vit[i];
    iv_ip(i)    = vip[i];
    iv_ig(i)    = vig[i];
    iv_lc(i)    = pre.lower_class[i];
    iv_ua(i)    = pre.upper_active[i];
  }
  IntVector bv_off(nblk), bv_size(nblk), bv_nconc(nblk), bv_nt(nblk),
            bv_np(nblk), bv_ng(nblk);
  std::string gas_names;
  for (int k = 0; k < nblk; ++k) {
    bv_off(k)   = blocks[k].offset;
    bv_size(k)  = blocks[k].size;
    bv_nconc(k) = blocks[k].nconc;
    bv_nt(k)    = blocks[k].nt;
    bv_np(k)    = blocks[k].np;
    bv_ng(k)    = blocks[k].ng;
    if (k) gas_names += " ";
    gas_names += blocks[k].name;
  }

  OutputDataFile file;
  file.open_absolute(tmp, OUTPUT_MODE_NOCLOBBER, NETCDF);
  file.define_dimension("x_index", n);
  file.define_dimension("active_gas", nblk);
  file.define_variable("global_x_index", INT, "x_index");
  file.define_variable("gas_id", INT, "x_index");
  file.define_variable("gas_offset", INT, "x_index");
  file.define_variable("iconc", INT, "x_index");
  file.define_variable("itemp", INT, "x_index");
  file.define_variable("ipress", INT, "x_index");
  file.define_variable("igpoint", INT, "x_index");
  file.define_variable("lower_class", INT, "x_index");
  file.define_variable("upper_active", INT, "x_index");
  file.define_variable("returned_x_log", DOUBLE, "x_index");
  file.define_variable("bound_lo_log", DOUBLE, "x_index");
  file.define_variable("bound_hi_log", DOUBLE, "x_index");
  file.define_variable("mapped_x_phys", DOUBLE, "x_index");
  file.define_variable("caller_phys", DOUBLE, "x_index");
  file.define_variable("caller_phys_f32", FLOAT, "x_index");
  file.define_variable("gas_block_offset", INT, "active_gas");
  file.define_variable("gas_block_size", INT, "active_gas");
  file.define_variable("gas_block_nconc", INT, "active_gas");
  file.define_variable("gas_block_ntemperature", INT, "active_gas");
  file.define_variable("gas_block_npressure", INT, "active_gas");
  file.define_variable("gas_block_ng_point", INT, "active_gas");
  file.define_variable("minimizer_status", INT);
  file.define_variable("min_x_log_floor", DOUBLE);
  // Global attributes MUST use the 3-argument DATA_FILE_GLOBAL_SCOPE
  // overload: the 2-argument string write creates the attribute but
  // returns false unconditionally (OutputDataFile.cpp), which would
  // force a spurious refusal below.
  bool wok = true;
  wok = file.write(gas_names, DATA_FILE_GLOBAL_SCOPE, "gas_names") && wok;
  wok = file.write(0, DATA_FILE_GLOBAL_SCOPE, "index_base") && wok;
  wok = file.write(arm, DATA_FILE_GLOBAL_SCOPE, "arm") && wok;
  wok = file.write(jobid, DATA_FILE_GLOBAL_SCOPE, "job_id") && wok;
  wok = file.write(std::string("solve_adept.cpp is_bounded post-minimize"),
                   DATA_FILE_GLOBAL_SCOPE, "capture_location") && wok;
  wok = file.write(std::string(adept::minimizer_status_string(status)),
                   DATA_FILE_GLOBAL_SCOPE, "minimizer_status_string") && wok;
  wok = file.write(std::string("gate4-x1-sidecar-v1"),
                   DATA_FILE_GLOBAL_SCOPE, "contract") && wok;
  file.end_define_mode();
  wok = file.write(iv_gidx, "global_x_index") && wok;
  wok = file.write(iv_gas, "gas_id") && wok;
  wok = file.write(iv_off, "gas_offset") && wok;
  wok = file.write(iv_iconc, "iconc") && wok;
  wok = file.write(iv_it, "itemp") && wok;
  wok = file.write(iv_ip, "ipress") && wok;
  wok = file.write(iv_ig, "igpoint") && wok;
  wok = file.write(iv_lc, "lower_class") && wok;
  wok = file.write(iv_ua, "upper_active") && wok;
  wok = file.write(v_ret, "returned_x_log") && wok;
  wok = file.write(v_lo, "bound_lo_log") && wok;
  wok = file.write(v_hi, "bound_hi_log") && wok;
  wok = file.write(v_map, "mapped_x_phys") && wok;
  wok = file.write(v_phys, "caller_phys") && wok;
  // caller_phys_f32 is DEFINED as FLOAT: writing the same double
  // vector projects through the identical NetCDF double->float
  // conversion used when the model itself is serialized
  wok = file.write(v_phys, "caller_phys_f32") && wok;
  wok = file.write(bv_off, "gas_block_offset") && wok;
  wok = file.write(bv_size, "gas_block_size") && wok;
  wok = file.write(bv_nconc, "gas_block_nconc") && wok;
  wok = file.write(bv_nt, "gas_block_ntemperature") && wok;
  wok = file.write(bv_np, "gas_block_npressure") && wok;
  wok = file.write(bv_ng, "gas_block_ng_point") && wok;
  wok = file.write((int) status, "minimizer_status") && wok;
  wok = file.write(min_x_log_floor, "min_x_log_floor") && wok;
  if (!wok) refuse("sidecar variable/attribute write failed");
  file.close();

  if (stat(tmp.c_str(), &st) != 0 || st.st_size <= 0)
    refuse("temp sidecar missing or empty after close");
  if (stat(target.c_str(), &st) == 0)
    refuse("target appeared during capture");
  if (std::rename(tmp.c_str(), target.c_str()) != 0)
    refuse("atomic rename failed: " + tmp + " -> " + target);
  std::printf("X1 CAPTURE WRITTEN: %s rows=%d gases=%d status=%d (%s)"
              " arm=%s job=%s\n",
              target.c_str(), n, nblk, (int) status,
              adept::minimizer_status_string(status),
              arm.c_str(), jobid.c_str());
  std::fflush(stdout);
}

} // namespace gate4_x1

#endif
