#!/bin/bash

# Declare variables
recyclebin="$HOME/recyclebin"
restoreFile="$HOME/.restore.info"
exitStatus=0

# Create recyclebin directory if not exists
function createRecycleBin() {
    if [ ! -d $recyclebin ]; then
        mkdir $recyclebin
        echo "Recycle bin directory created: $recyclebin"
    else
        echo "Recycle bin directory already exists: $recyclebin"
    fi
}

# Create a hidden file .restore.info if not exists
function createRestoreInfo() {
    if [ -e $restoreFile ]; then
        echo ".restore.info already exists."
    else
        touch $restoreFile
        echo ".restore.info created."
    fi
}

# Move file to recyclebin
function moveToRecycleBin() {
    local fileName=$1
    local recycleDirAllowed=$2

    # Check if the file exists
    if [ ! -e $fileName ]; then
        echo "Error: File '$fileName' does not exist."
        exitStatus=3
        continue
    fi

    # Check if the provided path is a directory
    if [ -d $fileName ]; then
        # check if user want to recycle a directory by using -r option
        if [ "$recycleDirAllowed" = "true" ]; then
            recycleDirectory $fileName
            rm -r $fileName
            continue
        else
            # User didn't use -r option
            echo "Error: Directory name '$fileName' provided instead of a filename."
            exitStatus=4
            continue
        fi
    fi

    # Check if the fileName is the recycle script
    if [ "$fileName" = "recycle" ]; then
        echo "Error: Attempting to delete recycle - operation aborted."
        exitStatus=5
        continue
    fi

    # Construct new filename using for after move to recyclebin
    inode=$(stat -c %i $fileName)
    newFileName=${fileName##*/}_${inode}

    # Gather file original path
    echo "$newFileName:$(realpath $fileName)" >>"$restoreFile"

    # Move the file to the recyclebin
    mv $fileName $recyclebin/$newFileName
    if [ $verboseMode = true ]; then
        echo "File '$fileName' moved to the recycle bin with new name: $newFileName"
    fi
}

function expandFileName() {
    for pattern in $@; do
        if [[ $pattern == *"*" ]]; then
            fileMatchingPattern=($pattern)
            for file in ${fileMatchingPattern[@]}; do
                expandFile+=("$file")
            done
        else
            for file in $pattern; do
                expandFile+=("$file")
            done
        fi
    done
}

function recycleDirectory() {
    local directory=$1

    for item in "$directory"/*; do
        if [ -f $item ]; then
            moveToRecycleBin $item
        elif [ -d $item ]; then
            recycleDirectory $item
        fi
    done

}

function isRecycleDirTrue() {
    local inputFile=$1
    local recycleDirState=$2

    if [ $recycleDirState = true ]; then
        moveToRecycleBin "$inputFile" true
    else
        moveToRecycleBin "$inputFile"
    fi
}

################## Main Execution ##################
createRecycleBin
createRestoreInfo

interactiveMode=false
verboseMode=false
recycleDir=false
expandFile=()

# Read in option
while getopts ":ivr" opt; do
    case $opt in
    i) interactiveMode=true ;;
    v) verboseMode=true ;;
    r) recycleDir=true ;;
    *)
        echo "Invalide option: -'$OPTARG'"
        exit 10
        ;;
    esac
done
shift $((OPTIND - 1))

# Check if arguments were provided
if [ $# -eq 0 ]; then
    echo "Error: No filename provided."
    exit 1
fi

# Read all files in array, also expand file name with "*"
expandFileName $@

# Iterate the file array to process recycle
for file in ${expandFile[@]}; do
    if [ $interactiveMode = true ]; then
        read -p "Do you want to move '$file' to the recycle bin? [y/n] " response
        if [[ $response =~ ^[Yy]$ ]]; then
            isRecycleDirTrue $file $recycleDir
        fi
    else
        isRecycleDirTrue $file $recycleDir
    fi
done

if [ "$exitStatus" -ne 0 ]; then
    exit "$exitStatus"
else
    exit 0
fi
