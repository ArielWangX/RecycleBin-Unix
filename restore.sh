#!/bin/bash

# Declare variables
fileNameWithINode=$1
recyclebin="$HOME/recyclebin"
restoreFile=“$HOME/.restore.info"

# Restore file from recyclebin
function restoreFromRecycleBin() {
        # Check if the file exists
        if [ ! -e $recyclebin/$fileName ]; then
                echo "Error: File '$fileName' does not exist."
                exit 2
        fi

        # Check if .restore.info file exists
        if [ ! -f "$restoreFile" ]; then
                echo "Error: .restore.info file not found."
                exit 3
        fi

        # Find original path
        originalPath=$(grep -F $fileNameWithINode $restoreFile | cut -d ':' -f 2)

        # Check if the restored file already exists in its original location
        if [ -e $originalPath ]; then
                read -p "File '$filename' already exists at '$originalPath'. Do you want to overwrite? (y/n): " response
                if [[ $response =~ ^[Yy].* ]]; then
                        rm $originalPath
                else
                        echo "Restore aborted."
                        exit 4
                fi
        fi

# Create the directory if it doesn't exist
        restoreDir=$(dirname $originalPath)
        mkdir -p $restoreDir

# Restore the file
        mv $recyclebin/$fileNameWithINode $originalPath
        echo "File '$fileNameWithINode' restored to its original location: $originalPath"

        # Remove the entity from the .restore.info
        temp=$(mktemp)
        grep -v "^$fileNameWithINode:" "$restoreFile" > "$temp"
        mv $temp $restoreFile

        echo "Restore information updated."

}

