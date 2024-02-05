#!/bin/sh
set -x

# Define globals
release_version=$(cat "/RELEASE_VERSION") #backblaze-personal-wine version tag
local_version_file="$WINEPREFIX/dosdevices/c:/ProgramData/Backblaze/bzdata/bzreports/bzserv_version.txt"
install_exe_path="$WINEPREFIX/dosdevices/c:/"
log_file="$WINEPREFIX/dosdevices/c:/backblaze-wine-startapp.log"
custom_user_agent="backblaze-personal-wine/$release_version (JonathanTreffler, +https://github.com/JonathanTreffler/backblaze-personal-wine-container), CFNetwork"

# Extracting variables from the PINNED_VERSION file
pinned_bz_version_file="/PINNED_BZ_VERSION"
pinned_bz_version=$(sed -n '1p' "$pinned_bz_version_file")
pinned_bz_version_url=$(sed -n '2p' "$pinned_bz_version_file")

export WINEARCH="win64"

# Disclaimer
disclaimer_updatemode() {
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
}

disclaimer_updatemode

log_message() {
    if [ ! -d $(dirname $log_file) ]; then
        echo "$(date): $1" >> /tmp/backblaze-wine-startapp.log
    else
        echo "$(date): $1" >> "$log_file"
    fi
}

if [ -f "/config/wine/drive_c/Program Files (x86)/Backblaze/bzbui.exe" ]; then
    # Function to handle errors
    handle_error() {
        echo "Error: $1" >> "$log_file"
        start_app # Start app even if there is a problem with the updater
    }



    start_app() {
    log_message "STARTAPP: Starting Backblaze version $(cat "$local_version_file")"
    wine64 "/config/wine/drive_c/Program Files (x86)/Backblaze/bzbui.exe" -noqiet &
    sleep infinity
    }

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
            log_message "UPDATER: COMPARE: newer version found - local $local_version - remote $compare_version"
            return 0 # The compare_version is higher
        else
            log_message "UPDATER: COMPARE: no new version found - local $local_version - remote $compare_version"
            return 1 # The local version is higher or equal
        fi
    }

    fetch_and_install() {
        cd "$install_exe_path" || handle_error "UPDATER: can't navigate to $install_exe_path"
        if [ "$FORCE_LATEST_UPDATE" = "true" ]; then
            log_message "UPDATER: FORCE_LATEST_UPDATE=true - downloading latest version"
            curl -L "https://www.backblaze.com/win32/install_backblaze.exe" --output "install_backblaze.exe"
        else
            log_message "UPDATER: FORCE_LATEST_UPDATE=false - downloading known-good version from archive.org"
            curl -A "$custom_user_agent" -L "$pinned_bz_version_url" --output "install_backblaze.exe"
        fi
        log_message "UPDATER: Starting install_backblaze.exe"
        WINEARCH="$WINEARCH" WINEPREFIX="$WINEPREFIX" wine64 "./install_backblaze.exe" || handle_error "UPDATER: Failed to install Backblaze"
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
            log_message "UPDATER: FORCE_LATEST_UPDATE=true, updating to the latest version"
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
            log_message "UPDATER: FORCE_LATEST_UPDATE=false, Checking if newer version than $local_version_file is available."
            local_version=$(cat "$local_version_file") || handle_error "UPDATER: Failed to read local version file"

            if compare_versions "$local_version" "$pinned_bz_version"; then
                log_message "UPDATER: FORCE_LATEST_UPDATE=false, Newer version found - downloading and installing the newer version..."
                fetch_and_install
                start_app # Exit after successful download+installation and start app
            else
                log_message "UPDATER: FORCE_LATEST_UPDATE=false, The local version is up to date. There may be a newer version available when using FORCE_LATEST_UPDATE=true"
                start_app # Exit autoupdate and start app
            fi
        else
            handle_error "UPDATER: Local version file does not exist. Exiting updater."
        fi
    fi
else
    cd "/tmp"
    mkdir -p /config/wine/ &&
    if [ "$FORCE_LATEST_UPDATE" = "true" ]; then
        log_message "INSTALLER: FORCE_LATEST_UPDATE=true, Installing latest Backblaze version"
        curl -L "https://www.backblaze.com/win32/install_backblaze.exe" --output "install_backblaze.exe" &&
        ls -la &&
        wine64 "install_backblaze.exe" &
    else
        log_message "INSTALLER: FORCE_LATEST_UPDATE=false, Installing pinned Backblaze version"
        curl -A "$custom_user_agent" -L "$pinned_bz_version_url" --output "install_backblaze.exe"&&
        ls -la &&
        wine64 "install_backblaze.exe" &
    fi
    sleep infinity
fi
