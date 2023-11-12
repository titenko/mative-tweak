#!/bin/bash

changelog_file="CHANGELOG.md"
script_version="0.0.1"  # Version
app_name="mative-tweak" # Application Name

# Check if the changelog file exists
if [ ! -e $changelog_file ]; then
    echo "# Changelog" > $changelog_file
fi

# Add the current date in the specified format
today=$(LC_TIME=en_US.utf8 date +"%a, %d %b %Y %H:%M:%S %z")

# Prompt the user for input to record changes
echo "Enter changes (press Enter on an empty line to finish):"

# Initialize an empty string to store changes
changes=""

# Continue prompting for changes until an empty line is entered
while true; do
    read -r line
    if [ -z "$line" ]; then
        break
    fi
    changes+="- $line\n    "
done

echo ""
echo "Document modified:"
# Formulate the entry for the changelog file
changelog_entry="$app_name ($script_version) RELEASED; urgency=high\n\n  * $changes\n -- $app_name <titenko.m@gmail.com>  $today"

# Output the current content of the changelog file to a temporary file
temp_file=$(mktemp)
cat $changelog_file > $temp_file

# Overwrite the changelog file with the new entry at the top
echo -e "$changelog_entry\n\n$(cat $temp_file)" > $changelog_file

# Remove the temporary file
rm $temp_file

# Output the content of the changelog file for verification
cat $changelog_file

# Optionally: Open the changelog file in an editor (e.g., nano)
# nano $changelog_file

