#!/bin/sh
set -x

# Globals
local_version_file="${WINEPREFIX}dosdevices/c:/ProgramData/Backblaze/bzdata/bzreports/bzserv_version.txt"
install_exe_path="${WINEPREFIX}dosdevices/c:/"
log_file="${STARTUP_LOGFILE:-${WINEPREFIX}dosdevices/c:/backblaze-wine-startapp.log}"
installer_url="https://www.backblaze.com/win32/install_backblaze.exe"
wine_template="/defaults/wineprefix" # image-baked prefix, seeded into WINEPREFIX on first run

export WINEARCH="win64"
export WINEDLLOVERRIDES="mscoree=" # disable wine-mono; the prefix uses real .NET

# Modern WineHQ ships only "wine" (runs 64-bit prefixes too); fall back if present.
if command -v wine64 >/dev/null 2>&1; then
    WINE="wine64"
else
    WINE="wine"
fi

# Current installer uses "Program Files"; older releases used "(x86)".
if [ -f "${WINEPREFIX}drive_c/Program Files (x86)/Backblaze/bzbui.exe" ]; then
    backblaze_dir="${WINEPREFIX}drive_c/Program Files (x86)/Backblaze"
else
    backblaze_dir="${WINEPREFIX}drive_c/Program Files/Backblaze"
fi
bzbui_exe="${backblaze_dir}/bzbui.exe"

log_message() {
    echo "$(date): $1" >> "$log_file"
}

# First run: seed the prefix from the image-baked template (.NET 4.8 + Windows 11
# + a rundll32 "supportedOS" manifest; without it Backblaze's installer aborts
# with "MajorVerTooOld"). A copy is much faster than installing .NET at runtime,
# and /config is a volume so the template must live outside it.
if [ ! -f "${WINEPREFIX}system.reg" ]; then
    if [ -d "$wine_template" ]; then
        echo "WINE: Seeding prefix from template ($wine_template)" # log file doesn't exist yet
        mkdir -p "${WINEPREFIX}"
        cp -a "${wine_template}/." "${WINEPREFIX}"
        chown -R "$(id -u):$(id -g)" "${WINEPREFIX}" # else wine: "not owned by you"
        log_message "WINE: Prefix ready (.NET 4.8, Windows 11, version manifest)"
    else
        echo "WINE: No template found, initializing wine directly"
        wineboot -i
        log_message "WINE: Initialization done (no template)"
    fi
fi

# Resolve the host path a /drive_<letter> should link to. Wine reports NFS/SMB
# mounts as network drives, which Backblaze refuses to back up (#43/#67). Opt-in
# ENABLE_NETWORK_MOUNT_MASKING overlays such a mount with a kernel overlayfs so wine
# sees a local disk (reads pass through; .bzvol writes go to /config). Needs
# CAP_SYS_ADMIN + apparmor:unconfined, else the share is used as-is (and skipped).
wine_drive_target() {
    src="$1"
    case "$(stat -f -c %T "$src" 2>/dev/null)" in
        nfs|nfs4|smb|smb2|smb3|cifs) ;;
        *) echo "$src"; return ;;
    esac
    if [ "$ENABLE_NETWORK_MOUNT_MASKING" != "true" ]; then
        log_message "DRIVE: ${src} is a network mount; Backblaze will skip it. Set ENABLE_NETWORK_MOUNT_MASKING=true (needs CAP_SYS_ADMIN + apparmor:unconfined) to mask it as a local disk."
        echo "$src"; return
    fi
    letter=$(basename "$src" | sed 's/^drive_//')
    masked="/drive_${letter}_local"
    ovl="/config/.overlay/${letter}"
    if awk -v m="$masked" '$2==m && $3=="overlay"{f=1} END{exit !f}' /proc/mounts 2>/dev/null; then
        echo "$masked"; return # already mounted
    fi
    mkdir -p "$masked" "${ovl}/up"
    rm -rf "${ovl}/work"; mkdir -p "${ovl}/work" # overlay needs a pristine workdir
    if mount -t overlay "overlay_${letter}" -o "lowerdir=${src},upperdir=${ovl}/up,workdir=${ovl}/work" "$masked" 2>>"$log_file"; then
        log_message "DRIVE: ${src} masked as a local disk via overlayfs at ${masked}"
        echo "$masked"
    else
        log_message "DRIVE: ${src} overlay masking FAILED (needs CAP_SYS_ADMIN + apparmor:unconfined); using as-is, Backblaze will skip it"
        echo "$src"
    fi
}

# Set up drives BEFORE any other wine command: wine registers a drive as a volume
# only at wineserver startup, when it scans dosdevices/, so the symlinks must exist
# before the first wine call (the regedit below). Each drive is marked fixed ("hd");
# the whole Drives key is imported in one go.
drives_reg="${WINEPREFIX}drive_c/windows/temp/wine-drives.reg"
mkdir -p "$(dirname "$drives_reg")"
{
    echo "REGEDIT4"
    echo ""
    echo "[HKEY_LOCAL_MACHINE\\Software\\Wine\\Drives]"
    echo "\"c:\"=\"hd\""
    for x in d e f g h i j k l m n o p q r s t u v w x y z
    do
        if test -d "/drive_${x}"; then
            target=$(wine_drive_target "/drive_${x}")
            rm -f "${WINEPREFIX}dosdevices/${x}:"
            ln -s "${target}/" "${WINEPREFIX}dosdevices/${x}:"
            log_message "DRIVE: ${x}: -> ${target} (fixed disk)"
            echo "\"${x}:\"=\"hd\""
        fi
    done
} > "$drives_reg"
"$WINE" regedit "$drives_reg" >/dev/null 2>&1 # first wine call: registers the drives as volumes

# Apply the virtual-desktop setting every start (so DISABLE_VIRTUAL_DESKTOP takes
# effect on restart). Done via `wine reg`, not `winetricks vd`, because winetricks
# calls `wineserver -w` which hangs forever once bzserv is running.
if [ "$DISABLE_VIRTUAL_DESKTOP" = "true" ]; then
    log_message "WINE: Disabling virtual desktop"
    "$WINE" reg delete 'HKCU\Software\Wine\Explorer' /v Desktop /f >/dev/null 2>&1
else
    log_message "WINE: Enabling virtual desktop ${DISPLAY_WIDTH:-900}x${DISPLAY_HEIGHT:-700}"
    "$WINE" reg add 'HKCU\Software\Wine\Explorer' /v Desktop /t REG_SZ /d Default /f >/dev/null 2>&1
    "$WINE" reg add 'HKCU\Software\Wine\Explorer\Desktops' /v Default /t REG_SZ /d "${DISPLAY_WIDTH:-900}x${DISPLAY_HEIGHT:-700}" /f >/dev/null 2>&1
fi

handle_error() {
    echo "Error: $1" >> "$log_file"
    start_app # start app even if the updater had a problem
}

# Run the installer in the FOREGROUND so it blocks until the install -- including
# the user's web-GUI sign-in -- fully finishes. Old/pinned versions are no longer
# available (archive.org dropped them), so we always install the current release.
fetch_and_install() {
    cd "$install_exe_path" || handle_error "INSTALLER: can't navigate to $install_exe_path"
    log_message "INSTALLER: Downloading latest Backblaze installer from $installer_url"
    curl -L "$installer_url" --output "install_backblaze.exe" || handle_error "INSTALLER: error downloading from $installer_url"
    log_message "INSTALLER: Starting install_backblaze.exe (sign in via the web GUI to finish the install)"
    WINEARCH="$WINEARCH" WINEPREFIX="$WINEPREFIX" "$WINE" "install_backblaze.exe" || handle_error "INSTALLER: Failed to install Backblaze"
}

start_app() {
    log_message "STARTAPP: Starting Backblaze version $(cat "$local_version_file" 2>/dev/null)"
    cd "$backblaze_dir" 2>/dev/null
    # Backblaze is single-instance: the first launch hides in the system tray (black
    # screen); a second launch shows its control-panel window. Launch a few times so
    # the window reliably appears after a (re)start.
    for _ in 1 2 3; do
        "$WINE" bzbui.exe -noquiet &
        sleep 8
    done
    sleep infinity
}

check_url_validity() {
    url="$1"
    if http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url"); then
        if [ "$http_code" -eq 200 ]; then
            content_type=$(curl -s -I "$url" | grep -i content-type | cut -d ':' -f2)
            if echo "$content_type" | grep -q "xml"; then
                return 0
            fi
        fi
    fi
    return 1
}

compare_versions() {
    local_version="$1"
    compare_version="$2"
    if dpkg --compare-versions "$local_version" lt "$compare_version"; then
        return 0 # compare_version is higher
    else
        return 1 # local version is higher or equal
    fi
}

if [ ! -f "$bzbui_exe" ]; then
    # Not installed yet: download and run the installer.
    fetch_and_install
elif [ "$DISABLE_AUTOUPDATE" != "true" ] && [ -f "$local_version_file" ]; then
    # Auto-update: reinstall if the version feed reports a newer release.
    log_message "UPDATER: DISABLE_AUTOUPDATE is not true, checking for a new version"
    urls="
        https://ca000.backblaze.com/api/clientversion.xml
        https://ca001.backblaze.com/api/clientversion.xml
        https://ca002.backblaze.com/api/clientversion.xml
        https://ca003.backblaze.com/api/clientversion.xml
        https://ca004.backblaze.com/api/clientversion.xml
        https://ca005.backblaze.com/api/clientversion.xml
    "
    for url in $urls; do
        if check_url_validity "$url"; then
            xml_content=$(curl -s "$url")
            xml_version=$(echo "$xml_content" | grep -o '<update win32_version="[0-9.]*"' | cut -d'"' -f2)
            local_version=$(cat "$local_version_file")
            log_message "UPDATER: Installed Version=$local_version, Latest Version=$xml_version"
            if compare_versions "$local_version" "$xml_version"; then
                log_message "UPDATER: Newer version found - downloading and installing it"
                fetch_and_install
            else
                log_message "UPDATER: The installed version is up to date."
            fi
            break # one reachable feed is enough
        fi
    done
else
    log_message "UPDATER: DISABLE_AUTOUPDATE=true, starting Backblaze without updating."
fi

# Start the installed client and keep the container alive.
start_app
