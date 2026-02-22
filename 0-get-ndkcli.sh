#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#------------------------------------------------------------------------------

# Copyright 2024 Nutanix, Inc
#
# Licensed under the MIT License;
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”),
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#------------------------------------------------------------------------------


# Prompt the user for the download link
echo 'open browser to site : https://portal.nutanix.com/page/downloads?product=ndk and find "CLI for Nutanix Data Services for Kubernetes (linux-amd64)" '
read -p "Enter download link: " url < /dev/tty

# Download the file with wget and check for errors
wget -O ndkcli.tgz "$url"
if [ $? -ne 0 ]; then
    echo "Download failed. Exiting."
    exit 1
fi

# Extract the downloaded file and check for errors
tar xzf ndkcli.tgz 
if [ $? -ne 0 ]; then
    echo "Extraction failed. Exiting."
    exit 1
fi

# Clean up downloaded files
rm -f ndkcli.tgz

#rename extracted file to ndkcli
mv ndkcli-linux-amd64 ndkcli

# Success message
echo "NDK CLI installed successfully!"
echo "checking version"
./ndkcli version