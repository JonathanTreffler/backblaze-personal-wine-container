#!/bin/bash
set -x

# Define globals
local_version_file="${WINEPREFIX}dosdevices/c:/ProgramData/Backblaze/bzdata/bzreports/bzserv_version.txt"
install_exe_path="${WINEPREFIX}dosdevices/c:/"
log_file="${STARTUP_LOGFILE:-${WINEPREFIX}dosdevices/c:/backblaze-wine-startapp.log}"
custom_user_agent="backblaze-personal-wine (JonathanTreffler, +https://github.com/JonathanTreffler/backblaze-personal-wine-container), CFNetwork"

# Extracting variables from the PINNED_VERSION file
pinned_bz_version_file="/PINNED_BZ_VERSION"
pinned_bz_version=$(sed -n '1p' "$pinned_bz_version_file")
pinned_bz_version_url=$(sed -n '2p' "$pinned_bz_version_file")

export FORCE_LATEST_UPDATE="true" #disable pinned version since URL is excluded from archive.org
export WINEARCH="win64"
export WINEDLLOVERRIDES="mscoree=" # Disable Mono installation

log_message() {
    echo "$(date): $1" >> "$log_file"
}

# Pre-initialize Wine
if [ ! -f "${WINEPREFIX}system.reg" ]; then
    echo "WINE: Wine not initialized, initializing"
    wineboot -i
    WINETRICKS_ACCEPT_EULA=1 winetricks -q -f dotnet48
    log_message "WINE: Initialization done"
fi

#Configure Extra Mounts
for x in {d..z}
do
    if test -d "/drive_${x}" && ! test -d "${WINEPREFIX}dosdevices/${x}:"; then
        log_message "DRIVE: drive_${x} found but not mounted, mounting..."
        ln -s "/drive_${x}/" "${WINEPREFIX}dosdevices/${x}:"
    fi
done

# Set Virtual Desktop
cd $WINEPREFIX
if [ "$DISABLE_VIRTUAL_DESKTOP" = "true" ]; then
    log_message "WINE: DISABLE_VIRTUAL_DESKTOP=true - Virtual Desktop mode will be disabled"
    winetricks vd=off
else
    # Check if width and height are defined
    if [ -n "$DISPLAY_WIDTH" ] && [ -n "$DISPLAY_HEIGHT" ]; then
    log_message "WINE: Enabling Virtual Desktop mode with $DISPLAY_WIDTH:$DISPLAY_WIDTH aspect ratio"
    winetricks vd="$DISPLAY_WIDTH"x"$DISPLAY_HEIGHT"
    else
        # Default aspect ratio
        log_message "WINE: Enabling Virtual Desktop mode with recommended aspect ratio"
        winetricks vd="900x700"
    fi
fi

# Disclaimer
    # Check if auto-updates are disabled
if [ "$DISABLE_AUTOUPDATE" = "true" ]; then
    echo "Auto-updates are disabled. Backblaze won't be updated."
else
    # Check the status of FORCE_LATEST_UPDATE
    if [ "$FORCE_LATEST_UPDATE" = "true" ]; then
        echo "FORCE_LATEST_UPDATE is enabled which may brick your installation."
    else
        echo "FORCE_LATEST_UPDATE is disabled. Using known-good version of Backblaze."
    fi
fi

# Function to handle errors
handle_error() {
    echo "Error: $1" >> "$log_file"
    start_app # Start app even if there is a problem with the updater
}

fetch_and_install() {
    cd "$install_exe_path" || handle_error "INSTALLER: can't navigate to $install_exe_path"
    if [ "$FORCE_LATEST_UPDATE" = "true" ]; then
        log_message "INSTALLER: FORCE_LATEST_UPDATE=true - downloading latest version"
        curl -L "https://www.backblaze.com/win32/install_backblaze.exe" --output "install_backblaze.exe"
    else
        log_message "INSTALLER: FORCE_LATEST_UPDATE=false - downloading pinned version $pinned_bz_version from archive.org"
        curl -A "$custom_user_agent" -L "$pinned_bz_version_url" --output "install_backblaze.exe" || handle_error "INSTALLER: error downloading from $pinned_bz_version_url"
    fi
    log_message "INSTALLER: Starting install_backblaze.exe"
    if [ -f "${WINEPREFIX}drive_c/Program Files (x86)/Backblaze/bzbui.exe" ]; then
        WINEARCH="$WINEARCH" WINEPREFIX="$WINEPREFIX" wine64 "install_backblaze.exe" -nogui || handle_error "INSTALLER: Failed to install Backblaze"
    else
        WINEARCH="$WINEARCH" WINEPREFIX="$WINEPREFIX" wine64 "install_backblaze.exe" || handle_error "INSTALLER: Failed to install Backblaze"
    fi

}

start_app() {
    log_message "STARTAPP: Starting Backblaze version $(cat "$local_version_file")"
    wine64 "${WINEPREFIX}drive_c/Program Files (x86)/Backblaze/bzbui.exe" -noquiet &
    sleep infinity
}

if [ -f "${WINEPREFIX}drive_c/Program Files (x86)/Backblaze/bzbui.exe" ]; then
    check_url_validity() {
        url="$1"
        if http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url"); then
            if [ "$http_code" -eq 200 ]; then
                content_type=$(curl -s -I "$url" | grep -i content-type | cut -d ':' -f2)
                if echo "$content_type" | grep -q "xml"; then
                    return 0 # Valid XML content found
                fi
            fi
        fi
        return 1 # Invalid or unavailable content
    }

    compare_versions() {
        local_version="$1"
        compare_version="$2"

        if dpkg --compare-versions "$local_version" lt "$compare_version"; then
            return 0 # The compare_version is higher
        else
            return 1 # The local version is higher or equal
        fi
    }



    # Check if auto-updates are disabled
    if [ "$DISABLE_AUTOUPDATE" = "true" ]; then
        log_message "UPDATER: DISABLE_AUTOUPDATE=true, Auto-updates are disabled. Starting Backblaze without updating."
        start_app
    fi

    # Update process for force_latest_update set to true or not set
    if [ "$FORCE_LATEST_UPDATE" = "true" ]; then
        # Main auto update logic
        if [ -f "$local_version_file" ]; then
            log_message "UPDATER: FORCE_LATEST_UPDATE=true, checking for a new version"
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
                    xml_content=$(curl -s "$url") || handle_error "UPDATER: Failed to fetch XML content"
                    xml_version=$(echo "$xml_content" | grep -o '<update win32_version="[0-9.]*"' | cut -d'"' -f2)
                    local_version=$(cat "$local_version_file") || handle_error "UPDATER: Failed to read local version from $local_version_file"
                    log_message "UPDATER: Installed Version=$local_version"
                    log_message "UPDATER: Latest Version=$xml_version"
                    if compare_versions "$local_version" "$xml_version"; then
                        log_message "UPDATER: Newer version found - downloading and installing the newer version..."
                        fetch_and_install
                        start_app # Exit after successful download+installation and start app
                    else
                        log_message "UPDATER: The installed version is up to date."
                        start_app # Exit autoupdate and start app
                    fi
                fi
            done

            handle_error "No valid XML content found or all URLs are unavailable."
        else
            handle_error "Local version file not found. Exiting."
        fi
    else
        # Update process for force_latest_update set to false or anything else
        if [ -f "$local_version_file" ]; then
            local_version=$(cat "$local_version_file") || handle_error "UPDATER: Failed to read local version file"
            log_message "UPDATER: FORCE_LATEST_UPDATE=false"
            log_message "UPDATER: Installed Version=$local_version"
            log_message "UPDATER: Pinned Version=$pinned_bz_version"

            if compare_versions "$local_version" "$pinned_bz_version"; then
                log_message "UPDATER: Newer version found - downloading and installing the newer version..."
                fetch_and_install
                start_app # Exit after successful download+installation and start app
            else
                log_message "UPDATER: Installed version is up to date. There may be a newer version available when using FORCE_LATEST_UPDATE=true"
                start_app # Exit autoupdate and start app
            fi
        else
            handle_error "UPDATER: Local version file does not exist. Exiting updater."
        fi
    fi
else # Client currently not installed
    fetch_and_install &&
    start_app
fi
