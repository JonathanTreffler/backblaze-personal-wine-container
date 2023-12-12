#!/bin/sh
set -x

# Define globals
local_version_file="$WINEPREFIX/dosdevices/c:/ProgramData/Backblaze/bzdata/bzreports/bzserv_version.txt"
install_exe_path="$WINEPREFIX/dosdevices/c:/"
log_file="/var/log/autoupdate.log"
export WINEARCH="win64"

if [ -f "/config/wine/drive_c/Program Files (x86)/Backblaze/bzbui.exe" ]; then
    # Errorhandling
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
        xml_version="$2"

        if dpkg --compare-versions "$local_version" lt "$xml_version"; then
            return 0 # The XML version is higher
        else
            return 1 # The local version is higher or equal
        fi
    }

    fetch_and_install() {
        cd "$install_exe_path" || handle_error "Failed to change directory"
        curl -L "https://www.backblaze.com/win32/install_backblaze.exe" --output "install_backblaze.exe"
        sudo -u app WINEARCH="$WINEARCH" WINEPREFIX="$WINEPREFIX" wine64 "./install_backblaze.exe" || handle_error "Failed to install Backblaze"
    }

    # Main auto update logic
    if [ -f "$local_version_file" ]; then
        log_message "Autoupdate script started"
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
    mkdir -p /config/wine/ &&
    cd /config/wine/ &&
    curl -L "https://www.backblaze.com/win32/install_backblaze.exe" --output "install_backblaze.exe" &&
    ls -la &&
    wine64 "install_backblaze.exe" &
    #sleep 10
    #ln -s /drive_d/ /config/wine/dosdevices/d:
    sleep infinity
fi
