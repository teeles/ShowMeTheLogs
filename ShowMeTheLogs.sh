#!/bin/bash

###############################################
#  V1.0 - 02/11/23
#  Thomas Eeles. 
#  ShowMeTheLogs
#  Collects macOS logs and creates a ZIP file on the users desktop to be shared with helpdesk teams.       
###############################################

# Define paths
temp_logs_folder="/tmp/logs"
desktop_path="$HOME/Desktop"
hostname=$(hostname)
zip_filename="logs_backup_${hostname}_$(date +%Y%m%d%H%M%S).zip"
gp_script="/Applications/GlobalProtect.app/Contents/Resources/gp_support.sh"
loggedInUser=$(stat -f%Su /dev/console)

# Create a folder in /tmp called "logs"
mkdir -p "$temp_logs_folder"
mkdri -p "$temp_logs_folder/varlogs"
mkdir -p "$temp_logs_folder/userlibrarylogs"
mkdir -p "$temp_logs_folder/sysmlibrarylogs"
mkdir -p "$temp_logs_folder/sysdiagnose"

# GlobalProtect script and redirect its output to the /tmp/logs folder
"$gp_script" "$temp_logs_folder"

# Collect OneDrive logs
echo "Collect a diagnostic report..."
latest_diagreport=`ls -t ~/Library/Logs/DiagnosticReports/OneDrive* 2>/dev/null | head -1`
if [ "$latest_diagreport" != "" ]; then
    if [[ "`grep 'OneDrive \[' \"$latest_diagreport\"`" =~ [0-9]+ ]]; then
        latest_core=/cores/core."${BASH_REMATCH[0]}"
    fi
fi

# Collect defaults setting information
echo "Getting current setting information of OneDrive..."
log_path=~/Library/Logs/OneDrive
settings_path=~/Library/Application\ Support/OneDrive
settings_output=${log_path}/OneDrive_Settings.log
fp_log_path=~/Library/Group\ Containers/UBF8T346G9.OneDriveStandaloneSuite/FileProviderLogs

echo "com.microsoft.OneDrive settings:" > $settings_output
defaults read com.microsoft.OneDrive >> $settings_output

echo -e "\nUBF8T346G9.OneDriveStandaloneSuite settings:" >> $settings_output
/usr/libexec/PlistBuddy -c "Print" ~/Library/Group\ Containers/UBF8T346G9.OneDriveStandaloneSuite/Library/Preferences/UBF8T346G9.OneDriveStandaloneSuite.plist >> $settings_output

if [ -a ~/Library/Group\ Containers/sync.com.microsoft.OneDrive-mac/Library/Preferences/sync.com.microsoft.OneDrive-mac.plist ]; then
    echo -e "\nsync.com.microsoft.OneDrive-mac settings:" >> $settings_output
    /usr/libexec/PlistBuddy -c "Print" ~/Library/Group\ Containers/sync.com.microsoft.OneDrive-mac/Library/Preferences/sync.com.microsoft.OneDrive-mac.plist >> $settings_output
fi

if [ -a ~/Library/Group\ Containers/UBF8T346G9.OfficeOneDriveSyncIntegration/Library/Preferences/UBF8T346G9.OfficeOneDriveSyncIntegration.plist ]; then
    echo -e "\nUBF8T346G9.OfficeOneDriveSyncIntegration settings:" >> $settings_output
    /usr/libexec/PlistBuddy -c "Print" ~/Library/Group\ Containers/UBF8T346G9.OfficeOneDriveSyncIntegration/Library/Preferences/UBF8T346G9.OfficeOneDriveSyncIntegration.plist >> $settings_output
fi

echo -e "\nLaunch service list:" >> $settings_output
launchctl list >> $settings_output

echo "Creating logs package..."
package_name=$temp_logs_folder/OneDriveLogs_`date "+%Y%m%d_%H%M"`.zip
zip -Dqr $package_name $log_path "$fp_log_path" "$settings_path" "$latest_core" "$latest_diagreport"

#Copy over /Library/Logs

cp -r /Library/Logs "$temp_logs_folder/sysmlibrarylogs"

#Copy over user specific logs
cp -r /Users/$loggedInUser/Library/Logs "$temp_logs_folder/userlibrarylogs"

# Copy the contents of /var/log to /tmp/logs
cp -r /var/log "$temp_logs_folder/varlogs"

# Compress the contents of /tmp/logs into a zip file
zip -r "$desktop_path/$zip_filename" "$temp_logs_folder"

# Check if the zip command was successful
if [ $? -eq 0 ]; then
  echo "Backup completed successfully. Zip file saved to $desktop_path/$zip_filename"
else
  echo "Backup failed."
fi

# Delete the /tmp/logs folder
rm -r "$temp_logs_folder"