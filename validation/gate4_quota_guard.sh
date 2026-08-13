# gate4_quota_guard.sh -- uid-quota headroom guards for large fetches on
# /shared (Lustre). Sourced by G2c-family sbatch scripts AND by the
# checkpoint's fixture tests, so the tested logic is the deployed logic.
#
# g4_quota_row -- shared row acquisition/parsing for the guards below:
#   echoes "used soft hard grace" (KiB fields, '*' stripped; grace
#   verbatim) or refuses. FAIL-CLOSED: missing lfs, missing aggregate
#   row, <5 fields, malformed numerics, and soft or hard reading 0
#   ("unlimited") all REFUSE. Callers enforce grace/headroom policy.
g4_quota_row() {
    command -v lfs >/dev/null 2>&1 || { echo "QUOTA-ROW REFUSED: lfs not available" >&2; return 67; }
    local row
    row=$(lfs quota -q -u "$(id -u)" /shared 2>/dev/null | awk '$1=="/shared"{print; exit}')
    [ -n "$row" ] || { echo "QUOTA-ROW REFUSED: no /shared aggregate row from lfs quota" >&2; return 67; }
    local nf
    nf=$(echo "$row" | awk '{print NF}')
    [ "$nf" -ge 5 ] || { echo "QUOTA-ROW REFUSED: aggregate row has $nf fields (<5): '$row'" >&2; return 67; }
    local used soft hard grace
    used=$(echo "$row" | awk '{gsub(/\*/,"",$2); print $2}')
    soft=$(echo "$row" | awk '{gsub(/\*/,"",$3); print $3}')
    hard=$(echo "$row" | awk '{gsub(/\*/,"",$4); print $4}')
    grace=$(echo "$row" | awk '{print $5}')
    local v
    for v in "$used" "$soft" "$hard"; do
        case "$v" in
            ''|*[!0-9]*) echo "QUOTA-ROW REFUSED: malformed numeric field '$v' in '$row'" >&2; return 67;;
        esac
    done
    [ "$soft" -gt 0 ] || { echo "QUOTA-ROW REFUSED: soft limit reads 0/unlimited; fail-closed (verify uid quota manually)" >&2; return 67; }
    [ "$hard" -gt 0 ] || { echo "QUOTA-ROW REFUSED: hard limit reads 0/unlimited; fail-closed (verify uid quota manually)" >&2; return 67; }
    echo "$used $soft $hard $grace"
    return 0
}

# quota_guard <dest_root> <manifest_tsv> <margin_bytes>
#   manifest_tsv: the audited selected-source manifest (basename, exact
#     size; optional ETag/LastModified provenance columns; '#' comments).
#     MUST contain exactly 70 unique basenames summing 329,989,234,896 B.
#   A local file counts toward "already have" ONLY if its stat size
#   EXACTLY matches its manifest size. A present-but-wrong-size file
#   REFUSES outright: the fetch would replace it, so any accounting
#   crediting it would understate the transfer, and the mismatch itself
#   demands investigation before spending quota.
#   FAIL-CLOSED: missing lfs/manifest, malformed rows, manifest count/sum
#   drift, soft or hard limit reading 0 ("unlimited"), used over soft, or
#   an active grace clock all REFUSE. The SOFT limit is the PRIMARY
#   ceiling (staying under soft keeps the account fully healthy; the
#   hard limit is where writes die and planning against it spends the
#   grace allowance); returns 0 only when
#   soft-headroom >= (manifest_total - exact_matched_bytes) + margin,
#   with hard-headroom as a secondary sanity ceiling on the same need.
quota_guard() {
    local dest="$1" manifest="$2" margin="$3"
    case "$margin" in
        ''|*[!0-9]*) echo "QUOTA-GUARD REFUSED: malformed margin byte count '$margin'" >&2; return 67;;
    esac
    [ -r "$manifest" ] || { echo "QUOTA-GUARD REFUSED: manifest not readable: $manifest" >&2; return 67; }
    local fields
    fields=$(g4_quota_row) || { echo "QUOTA-GUARD REFUSED: quota row unavailable/invalid" >&2; return 67; }
    local used_kib soft_kib hard_kib grace
    read -r used_kib soft_kib hard_kib grace <<< "$fields"
    [ "$grace" = "-" ] || { echo "QUOTA-GUARD REFUSED: grace clock active ($grace); already over soft limit" >&2; return 67; }
    [ "$used_kib" -le "$soft_kib" ] || { echo "QUOTA-GUARD REFUSED: used ${used_kib}KiB over soft ${soft_kib}KiB" >&2; return 67; }
    local headroom=$(( (soft_kib - used_kib) * 1024 ))
    [ "$headroom" -ge 0 ] || headroom=0
    local hard_headroom=$(( (hard_kib - used_kib) * 1024 ))
    [ "$hard_headroom" -ge 0 ] || hard_headroom=0
    # manifest validation: exactly 70 unique names, audited byte sum
    local mcount ucount msum
    mcount=$(awk -F'\t' '!/^#/ && NF>=2 {n++} END{print n+0}' "$manifest")
    ucount=$(awk -F'\t' '!/^#/ && NF>=2 {print $1}' "$manifest" | sort -u | wc -l)
    msum=$(awk -F'\t' '!/^#/ && NF>=2 {if ($2 !~ /^[0-9]+$/) {print "BAD"; exit} s+=$2} END{printf "%.0f", s}' "$manifest")
    [ "$mcount" = 70 ] && [ "$ucount" = 70 ] || { echo "QUOTA-GUARD REFUSED: manifest count/uniqueness $mcount/$ucount != 70/70" >&2; return 67; }
    [ "$msum" = 329989234896 ] || { echo "QUOTA-GUARD REFUSED: manifest sum $msum != audited 329989234896" >&2; return 67; }
    # exact-size matching against local finals; wrong size => refuse
    local have=0 name size sub f sz
    while IFS=$'\t' read -r name size _rest; do
        case "$name" in ''|'#'*) continue;; esac
        case "$name" in
            *_lw_spectra_*) sub=lw_spectra;;
            *_sw_spectra_*) sub=sw_spectra;;
            *) echo "QUOTA-GUARD REFUSED: manifest name without band dir: $name" >&2; return 67;;
        esac
        f="$dest/$sub/$name"
        if [ -e "$f" ]; then
            sz=$(stat -c %s "$f") || { echo "QUOTA-GUARD REFUSED: stat failed on $f" >&2; return 67; }
            if [ "$sz" = "$size" ]; then
                have=$(( have + sz ))
            else
                echo "QUOTA-GUARD REFUSED: size mismatch $f local=$sz manifest=$size (the fetch would replace it; investigate before spending quota)" >&2
                return 67
            fi
        fi
    done < "$manifest"
    local remaining=$(( 329989234896 - have )); [ "$remaining" -lt 0 ] && remaining=0
    local need=$(( remaining + margin ))
    echo "quota-guard: soft-headroom=${headroom}B hard-headroom=${hard_headroom}B exact-matched=${have}B remaining=${remaining}B need=${need}B (remaining+margin; soft is primary ceiling)"
    [ "$headroom" -ge "$need" ] || { echo "QUOTA-GUARD REFUSED: soft headroom ${headroom}B < need ${need}B" >&2; return 67; }
    [ "$hard_headroom" -ge "$need" ] || { echo "QUOTA-GUARD REFUSED: hard headroom ${hard_headroom}B < need ${need}B (secondary ceiling)" >&2; return 67; }
    return 0
}

# quota_object_recheck <next_object_bytes> <margin_bytes> -- per-object
# live re-check run before EACH object allocation AND immediately before
# each publish: refuses unless the SOFT limit still has headroom for the
# next object PLUS the standing reserve. At publish time the .part bytes
# already count in `used`, so the caller passes next=0 there (the rename
# allocates nothing; the check is that the reserve is still intact).
# Reads lfs quota fresh on every call (job 4440 lesson: quota state can
# move mid-run; a single startup check is not sufficient). Same
# fail-closed row discipline as quota_guard.
quota_object_recheck() {
    local next="$1" margin="$2"
    local v
    for v in "$next" "$margin"; do
        case "$v" in
            ''|*[!0-9]*) echo "QUOTA-RECHECK REFUSED: malformed byte count '$v'" >&2; return 67;;
        esac
    done
    local fields
    fields=$(g4_quota_row) || { echo "QUOTA-RECHECK REFUSED: quota row unavailable/invalid" >&2; return 67; }
    local used_kib soft_kib hard_kib grace
    read -r used_kib soft_kib hard_kib grace <<< "$fields"
    [ "$grace" = "-" ] || { echo "QUOTA-RECHECK REFUSED: grace clock active ($grace); already over soft limit" >&2; return 67; }
    [ "$used_kib" -le "$soft_kib" ] || { echo "QUOTA-RECHECK REFUSED: used ${used_kib}KiB over soft ${soft_kib}KiB" >&2; return 67; }
    local headroom=$(( (soft_kib - used_kib) * 1024 ))
    [ "$headroom" -ge 0 ] || headroom=0
    local need=$(( next + margin ))
    [ "$headroom" -ge "$need" ] || { echo "QUOTA-RECHECK REFUSED: soft headroom ${headroom}B < next-object+reserve ${need}B" >&2; return 67; }
    return 0
}

# quota_health <reserve_bytes> -- output-write health gate for compute
# jobs (G3 executors): FAIL-CLOSED unless the uid quota is in a fully
# healthy state: used <= soft (no grace clock running, grace field "-"),
# soft>0, hard>0, SOFT-limit headroom >= reserve_bytes (PRIMARY ceiling:
# staying under soft keeps the account fully healthy and never starts
# the grace clock), and hard-limit headroom >= reserve_bytes retained as
# a SECONDARY sanity bound. Row acquisition/parsing via g4_quota_row.
quota_health() {
    local reserve="$1"
    case "$reserve" in
        ''|*[!0-9]*) echo "QUOTA-HEALTH REFUSED: malformed reserve byte count '$reserve'" >&2; return 67;;
    esac
    local fields
    fields=$(g4_quota_row) || { echo "QUOTA-HEALTH REFUSED: quota row unavailable/invalid" >&2; return 67; }
    local used soft hard grace
    read -r used soft hard grace <<< "$fields"
    [ "$used" -le "$soft" ] || { echo "QUOTA-HEALTH REFUSED: used ${used}KiB over soft ${soft}KiB (grace $grace)" >&2; return 67; }
    [ "$grace" = "-" ] || { echo "QUOTA-HEALTH REFUSED: grace clock active: $grace" >&2; return 67; }
    local soft_headroom=$(( (soft - used) * 1024 ))
    [ "$soft_headroom" -ge 0 ] || soft_headroom=0
    local hard_headroom=$(( (hard - used) * 1024 ))
    [ "$hard_headroom" -ge 0 ] || hard_headroom=0
    [ "$soft_headroom" -ge "$reserve" ] || { echo "QUOTA-HEALTH REFUSED: soft headroom ${soft_headroom}B < reserve ${reserve}B (primary ceiling)" >&2; return 67; }
    [ "$hard_headroom" -ge "$reserve" ] || { echo "QUOTA-HEALTH REFUSED: hard headroom ${hard_headroom}B < reserve ${reserve}B (secondary sanity)" >&2; return 67; }
    echo "quota-health: used=${used}KiB soft=${soft}KiB hard=${hard}KiB grace=- soft-headroom=${soft_headroom}B hard-headroom=${hard_headroom}B reserve=${reserve}B (soft primary)"
    return 0
}
