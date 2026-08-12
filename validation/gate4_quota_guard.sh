# gate4_quota_guard.sh -- uid-quota headroom guard for large fetches on
# /shared (Lustre). Sourced by G2c-family sbatch scripts AND by the
# checkpoint's fixture tests, so the tested logic is the deployed logic.
#
# quota_guard <dest_root> <selected_source_total_bytes> <margin_bytes>
#   dest_root: directory containing {lw,sw}_spectra with any already-
#              finalized expected files (only the audited 70-name set is
#              counted toward "already have").
#   FAIL-CLOSED: missing lfs, missing/malformed aggregate row, or a hard
#   limit reading 0 ("unlimited" in lfs semantics) all REFUSE -- on this
#   cluster the uid quota is known to exist, so an unlimited reading most
#   likely means the wrong row was parsed. Returns 0 only when
#   headroom >= (source_total - finalized_bytes) + margin.
quota_guard() {
    local dest="$1" total="$2" margin="$3"
    command -v lfs >/dev/null 2>&1 || { echo "QUOTA-GUARD REFUSED: lfs not available" >&2; return 67; }
    local row
    row=$(lfs quota -q -u "$(id -u)" /shared 2>/dev/null | awk '$1=="/shared"{print; exit}')
    [ -n "$row" ] || { echo "QUOTA-GUARD REFUSED: no /shared aggregate row from lfs quota" >&2; return 67; }
    local nf
    nf=$(echo "$row" | awk '{print NF}')
    [ "$nf" -ge 4 ] || { echo "QUOTA-GUARD REFUSED: aggregate row has $nf fields (<4): '$row'" >&2; return 67; }
    local used_kib hard_kib
    used_kib=$(echo "$row" | awk '{gsub(/\*/,"",$2); print $2}')
    hard_kib=$(echo "$row" | awk '{gsub(/\*/,"",$4); print $4}')
    case "$used_kib" in
        ''|*[!0-9]*) echo "QUOTA-GUARD REFUSED: malformed used field '$used_kib'" >&2; return 67;;
    esac
    case "$hard_kib" in
        ''|*[!0-9]*) echo "QUOTA-GUARD REFUSED: malformed hard field '$hard_kib'" >&2; return 67;;
    esac
    if [ "$hard_kib" -eq 0 ]; then
        echo "QUOTA-GUARD REFUSED: hard limit reads 0/unlimited; fail-closed (verify uid quota manually)" >&2
        return 67
    fi
    local headroom=$(( (hard_kib - used_kib) * 1024 ))
    [ "$headroom" -ge 0 ] || headroom=0
    local have=0 band sp chunk f sz
    for band in lw sw; do
        for sp in h2o_present o3_present co2_present ch4_present n2o_present n2_constant o2_constant; do
            for chunk in 1-10 11-20 21-30 31-40 41-50; do
                f="$dest/${band}_spectra/ckdmip_evaluation2_${band}_spectra_${sp}_${chunk}.h5"
                if [ -s "$f" ]; then
                    sz=$(stat -c %s "$f") || { echo "QUOTA-GUARD REFUSED: stat failed on $f" >&2; return 67; }
                    have=$(( have + sz ))
                fi
            done
        done
    done
    local remaining=$(( total - have )); [ "$remaining" -lt 0 ] && remaining=0
    local need=$(( remaining + margin ))
    echo "quota-guard: headroom=${headroom}B finalized=${have}B remaining=${remaining}B need=${need}B (remaining+margin)"
    [ "$headroom" -ge "$need" ] || { echo "QUOTA-GUARD REFUSED: headroom ${headroom}B < need ${need}B" >&2; return 67; }
    return 0
}
