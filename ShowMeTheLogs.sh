#!/bin/bash

###############################################
#  V1.0 - 02/11/23
#  V2.0 - 18/04/25
#  Thomas Eeles. 
#  ShowMeTheLogs
#  Collects macOS logs and creates a ZIP file on the users desktop to be shared with helpdesk teams. 
#  V2.0 - Cleaned up with lots of lovely functions. 
#       - Added in sysdiagnose functionality
#       - Added in checks for each function to not waste time and error out. 
#       
###############################################

########## Variables ##########
temp_logs_folder="/tmp/logs"
desktop_path="$HOME/Desktop"
hostname=$(hostname)
zip_filename="logs_backup_${hostname}_$(date +%Y%m%d%H%M%S).zip"
gp_script="/Applications/GlobalProtect.app/Contents/Resources/gp_support.sh"
loggedInUser=$(stat -f%Su /dev/console)
log="$temp_logs_folder/SMTL.log"
log_path=~/Library/Logs/OneDrive
settings_path=~/Library/Application\ Support/OneDrive
settings_output=${log_path}/OneDrive_Settings.log
fp_log_path=~/Library/Group\ Containers/UBF8T346G9.OneDriveStandaloneSuite/FileProviderLogs

########## Functions ##########

write_log() {
    local current_date="$(date '+%Y-%m-%d %H:%M:%S')"
    local log_data="$1"
    local log_entry="--- DATE: $current_date: $log_data "
    echo "$log_entry" >> "$log"
}

set_up(){
    mkdir -p "$temp_logs_folder"
    mkdri -p "$temp_logs_folder/varlogs"
    mkdir -p "$temp_logs_folder/userlibrarylogs"
    mkdir -p "$temp_logs_folder/sysmlibrarylogs"
    mkdir -p "$temp_logs_folder/sysdiagnose"
    touch "$temp_logs_folder/SMTL.log"
}

sdiagnose(){

sysdiagnose -f $temp_logs_folder/sysdiagnose -n -b

if [ -d ""$temp_logs_folder/sysdiagnose ] && [ -z "$(ls -A "$temp_logs_folder/sysdiagnose")" ]; then
  write_log "the $temp_logs_folder/sysdiagnose folder is empty, something has gone wrong." 
  write_log "Moving on, try manually running the sysdiagnose comand later" 
else
  write_log "sysdiagnose has worked, moving on"
  write_log "checking that Global Protect VPN is installed"
fi
}

global_protect(){
    if [[ -d /Application/Global Protect.app ]]; then
        write_log "found Global Protect, running log collection script"
        "$gp_script" "$temp_logs_folder"  
    else
        write_log "Global Protect is not installed"
    fi
}

one_drive(){
if [[ -d /Applications/One Drive.app ]]; then
    
    write_log "Onedrive: Collect a diagnostic report..."
latest_diagreport=`ls -t ~/Library/Logs/DiagnosticReports/OneDrive* 2>/dev/null | head -1`
if [ "$latest_diagreport" != "" ]; then
    if [[ "`grep 'OneDrive \[' \"$latest_diagreport\"`" =~ [0-9]+ ]]; then
        latest_core=/cores/core."${BASH_REMATCH[0]}"
    fi
fi

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

write_log "Onedrive: Creating logs package..."
package_name=$temp_logs_folder/OneDriveLogs_`date "+%Y%m%d_%H%M"`.zip
zip -Dqr $package_name $log_path "$fp_log_path" "$settings_path" "$latest_core" "$latest_diagreport"

else 
    write_log "Onedrive not installed"
fi

}

########## The Script ##########

setup

write_log "Show Me The Logs - $date - $hostname"

#run the sysdiagnose tool first, this is the most comprehnsive collection

write_log "Running the systdiagnose tool sysdiagnose -f $temp_logs_folder/sysdiagnose -n -b"

sdiagnose

# GlobalProtect script and redirect its output to the /tmp/logs folder

global_protect

# Collect OneDrive logs

one_drive  
    

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