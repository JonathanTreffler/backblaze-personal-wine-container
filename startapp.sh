#!/bin/sh
set -x

# Define globals
release_version=$(cat "/RELEASE_VERSION") #backblaze-personal-wine version tag
local_version_file="$WINEPREFIX/dosdevices/c:/ProgramData/Backblaze/bzdata/bzreports/bzserv_version.txt"
install_exe_path="$WINEPREFIX/dosdevices/c:/"
log_file="WINEPREFIX/dosdevices/c:/backblaze-autoupdate.log"
custom_user_agent="backblaze-personal-wine/$release_version (JonathanTreffler, +https://github.com/JonathanTreffler/backblaze-personal-wine-container), CFNetwork"

# Extracting variables from the PINNED_VERSION file
pinned_bz_version_file="/PINNED_BZ_VERSION"
pinned_bz_version=$(sed -n '1p' "$pinned_bz_version_file")
pinned_bz_version_url=$(sed -n '2p' "$pinned_bz_version_file")

export WINEARCH="win64"

# Disclaimer
log_force_latest_update() {
    if [ "$FORCE_LATEST_UPDATE" = "true" ]; then
        echo "FORCE_LATEST_UPDATE is enabled which may brick your installation."
    else
        echo "FORCE_LATEST_UPDATE is disabled. Using known-good version of Backblaze."
    fi
}

log_force_latest_update


if [ -f "/config/wine/drive_c/Program Files (x86)/Backblaze/bzbui.exe" ]; then
    # Function to handle errors
    handle_error() {
        echo "Error: $1" >> "$log_file"
        start_app # Start app even if there is a problem with the updater
    }

    log_message() {
        echo "$(date): $1" >> "$log_file"
    }

    start_app() {
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
            return 0 # The compare_version is higher
        else
            return 1 # The local version is higher or equal
        fi
    }

    fetch_and_install() {
        cd "$install_exe_path" || handle_error "Failed to change directory"
        if [ "$FORCE_LATEST_UPDATE" = "true" ]; then
            curl -L "https://www.backblaze.com/win32/install_backblaze.exe" --output "install_backblaze.exe"
        else
            curl -A "$custom_user_agent" -L "$pinned_bz_version_url" --output "install_backblaze.exe"
        fi
        WINEARCH="$WINEARCH" WINEPREFIX="$WINEPREFIX" wine64 "./install_backblaze.exe" || handle_error "Failed to install Backblaze"
    }

    # Update process for force_latest_update set to true or not set
    if [ "$FORCE_LATEST_UPDATE" = "true" ]; then
        # Main auto update logic
        if [ -f "$local_version_file" ]; then
            log_message "Auto update logic for force_latest_update=true."
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
                    xml_content=$(curl -s "$url") || handle_error "Failed to fetch XML content"
                    xml_version=$(echo "$xml_content" | grep -o '<update win32_version="[0-9.]*"' | cut -d'"' -f2)
                    local_version=$(cat "$local_version_file") || handle_error "Failed to read local version"

                    if compare_versions "$local_version" "$xml_version"; then
                        log_message "Downloading and installing the newer version..."
                        fetch_and_install
                        start_app # Exit after successful download+installation and start app
                    else
                        log_message "The local version is up to date."
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
            log_message "Checking for updates based on bzserv_version file."
            local_version=$(cat "$local_version_file") || handle_error "Failed to read local version"

            if compare_versions "$local_version" "$pinned_bz_version"; then
                log_message "Downloading and installing the newer version..."
                fetch_and_install
                start_app # Exit after successful download+installation and start app
            else
                log_message "The local version is up to date. There may be a newer version available when using force_latest_update=true"
                start_app # Exit autoupdate and start app
            fi
        else
            handle_error "Local version file not found. Exiting."
        fi
    fi
else
    mkdir -p /config/wine/ &&
    if [ "$FORCE_LATEST_UPDATE" = "true" ]; then
        log_message "Installing latest Backblaze version"
        curl -L "https://www.backblaze.com/win32/install_backblaze.exe" --output "install_backblaze.exe" &&
        ls -la &&
        wine64 "install_backblaze.exe" &
    else
        log_message "Installing pinned Backblaze"
        curl -A "$custom_user_agent" -L "$pinned_bz_version_url" --output "install_backblaze.exe"&&
        ls -la &&
        wine64 "install_backblaze.exe" &
    fi
    sleep infinity
fi
