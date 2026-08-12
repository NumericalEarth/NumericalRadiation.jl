# gate4_quota_guard.sh -- uid-quota headroom guard for large fetches on
# /shared (Lustre). Sourced by G2c-family sbatch scripts AND by the
# checkpoint's fixture tests, so the tested logic is the deployed logic.
#
# quota_guard <dest_root> <manifest_tsv> <margin_bytes>
#   manifest_tsv: the audited selected-source manifest (basename, exact
#     size; optional ETag/LastModified provenance columns; '#' comments).
#     MUST contain exactly 70 unique basenames summing 329,989,234,896 B.
#   A local file counts toward "already have" ONLY if its stat size
#   EXACTLY matches its manifest size. A present-but-wrong-size file
#   REFUSES outright: aws s3 sync will re-download it, so any accounting
#   crediting it would understate the transfer, and the mismatch itself
#   demands investigation before spending quota.
#   FAIL-CLOSED: missing lfs/manifest, malformed rows, manifest count/sum
#   drift, or a hard limit reading 0 ("unlimited") all REFUSE. Returns 0
#   only when headroom >= (manifest_total - exact_matched_bytes) + margin.
quota_guard() {
    local dest="$1" manifest="$2" margin="$3"
    command -v lfs >/dev/null 2>&1 || { echo "QUOTA-GUARD REFUSED: lfs not available" >&2; return 67; }
    [ -r "$manifest" ] || { echo "QUOTA-GUARD REFUSED: manifest not readable: $manifest" >&2; return 67; }
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
                echo "QUOTA-GUARD REFUSED: size mismatch $f local=$sz manifest=$size (sync would replace it; investigate before spending quota)" >&2
                return 67
            fi
        fi
    done < "$manifest"
    local remaining=$(( 329989234896 - have )); [ "$remaining" -lt 0 ] && remaining=0
    local need=$(( remaining + margin ))
    echo "quota-guard: headroom=${headroom}B exact-matched=${have}B remaining=${remaining}B need=${need}B (remaining+margin)"
    [ "$headroom" -ge "$need" ] || { echo "QUOTA-GUARD REFUSED: headroom ${headroom}B < need ${need}B" >&2; return 67; }
    return 0
}
