#!/bin/bash

# Installs the Virtual VE.Bus (dbus-multiplus-emulator) driver from GitHub.
#
# Usage:
#   bash download.sh            # installs the "main" branch
#   bash download.sh <branch>   # installs a specific branch/tag
#
# Because this repository keeps the driver in a sub-folder, this script knows
# how to find it inside the downloaded zip and copies it to the right place.

github_owner="sean-oelofse"
github_repo="virtual-ve-bus"
# path to the driver folder inside the repository
repo_subpath="venus-os_dbus-multiplus-emulator/dbus-multiplus-emulator"

driver_path="/data/etc"
driver_name="dbus-multiplus-emulator"

# branch to install (first argument), default "main"
branch="${1:-main}"

echo ""
echo "Installing '$driver_name' from https://github.com/${github_owner}/${github_repo} (branch: $branch)"
echo ""

if [ -d ${driver_path}/${driver_name} ]; then
    echo "Existing installation found -> updating..."
else
    echo "No existing installation found -> installing..."
fi

# change to temp folder
cd /tmp

# download the selected branch as a zip
url="https://github.com/${github_owner}/${github_repo}/archive/refs/heads/${branch}.zip"
echo ""
echo "Downloading from: $url"
wget -O /tmp/${github_repo}.zip "$url"

# check if download was successful
if [ ! -f /tmp/${github_repo}.zip ]; then
    echo ""
    echo "Download failed. Exiting..."
    exit 1
fi

# cleanup any previous extraction
rm -rf /tmp/${github_repo}-extracted

# unzip
echo "Unzipping..."
mkdir -p /tmp/${github_repo}-extracted
unzip -q /tmp/${github_repo}.zip -d /tmp/${github_repo}-extracted

# find the driver folder inside the extracted repository
source_dir=$(find /tmp/${github_repo}-extracted -maxdepth 3 -type d -path "*${repo_subpath}" | head -n 1)

if [ -z "$source_dir" ] || [ ! -f "$source_dir/${driver_name}.py" ]; then
    echo ""
    echo "Error: could not find '${repo_subpath}' inside the downloaded zip. Exiting..."
    exit 1
fi
echo "Found driver at: $source_dir"

# If updating: backup existing config file
if [ -f ${driver_path}/${driver_name}/config.ini ]; then
    echo ""
    echo "Backing up existing config file..."
    mv ${driver_path}/${driver_name}/config.ini ${driver_path}/${driver_name}_config.ini
fi

# If updating: cleanup existing driver
if [ -d ${driver_path}/${driver_name} ]; then
    echo ""
    echo "Cleaning up existing driver..."
    rm -rf ${driver_path}/${driver_name}
fi

# copy files
echo ""
echo "Copying new driver files..."
cp -R "$source_dir" ${driver_path}/${driver_name}

# remove temp files
echo ""
echo "Cleaning up temp files..."
rm -rf /tmp/${github_repo}.zip
rm -rf /tmp/${github_repo}-extracted

# If updating: restore existing config file
if [ -f ${driver_path}/${driver_name}_config.ini ]; then
    echo ""
    echo "Restoring existing config file..."
    mv ${driver_path}/${driver_name}_config.ini ${driver_path}/${driver_name}/config.ini
fi

# set permissions for files
echo ""
echo "Setting permissions for files..."
chmod 755 ${driver_path}/${driver_name}/${driver_name}.py
chmod 755 ${driver_path}/${driver_name}/install.sh
chmod 755 ${driver_path}/${driver_name}/restart.sh
chmod 755 ${driver_path}/${driver_name}/uninstall.sh
chmod 755 ${driver_path}/${driver_name}/service/run
chmod 755 ${driver_path}/${driver_name}/service/log/run

# copy default config file on first installation
if [ ! -f ${driver_path}/${driver_name}/config.ini ]; then
    echo ""
    echo "First installation detected. Copying default config file..."
    cp ${driver_path}/${driver_name}/config.sample.ini ${driver_path}/${driver_name}/config.ini
    echo ""
    echo "You can edit the config file with:"
    echo "  nano ${driver_path}/${driver_name}/config.ini"
    echo ""
    echo "** After editing the config, run install.sh to start the service: **"
    echo "  bash ${driver_path}/${driver_name}/install.sh"
    echo ""
else
    echo ""
    echo "Restarting driver to apply the new version..."
    /bin/bash ${driver_path}/${driver_name}/restart.sh
fi

echo
echo "Done."
echo
