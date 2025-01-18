#!/bin/bash

# Clear the screen
clear

# ANSI color codes
GREEN='\033[0;42m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[1;36m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Default malicious origin
malicious_origin="http://malicious.com"

# Initialize variables
url=""
file=""
output_prefix=""
save_to_files=false

banner() {
cat << 'EOF'
 .--..--. .--.  .-. --.-- .--.    .
:   :    :|   )(   )  |  :       / \    CORS (Cross-origin resource sharing)
|   |    ||--'  `-.   |  |      /___\   Vulnerability Scanner - Created By Trabbit
:   :    ;|  \ (   )  |  :     /     \
 `--'`--' '   ` `-' --'-- `--''       `

==================================================

EOF
}

# Help message
function show_help() {
    echo "Usage: $0 [-u <url> | -f <file>] [-o <output_filename_prefix>]"
    echo ""
    echo "Options:"
    echo "  -u <url>         Test a single URL."
    echo "  -f <file>        Test multiple URLs from a file (one URL per line)."
    echo "  -o <prefix>      Save results to files with the specified prefix."
    echo "                   If not provided, results will only be displayed in the terminal."
    echo "  -h               Show this help message."
}

# Test a single URL
function test_url() {
    local url=$1

    echo -e "[i] Testing: $url with Origin: $malicious_origin"

    # Send request with malicious Origin header
    response=$(curl -s -H "Origin: $malicious_origin" -H "Access-Control-Request-Method: GET" -I "$url" --max-time 2)

    # Extract headers
    access_control_origin=$(echo "$response" | grep -i "Access-Control-Allow-Origin" | awk '{print $2}' | tr -d '\r')
    access_control_credentials=$(echo "$response" | grep -i "Access-Control-Allow-Credentials" | awk '{print $2}' | tr -d '\r')

    # Determine vulnerability
    if [[ "$access_control_origin" == "$malicious_origin" && "$access_control_credentials" == "true" ]]; then
        echo -e "  ${GREEN}Vulnerable:${RESET} - [${CYAN}$url${RESET}] - (allows $malicious_origin and supports credentials)"
        [[ $save_to_files == true ]] && echo "$url" >> "$vulnerable_file"
    elif [[ "$access_control_origin" == "$malicious_origin" ]]; then
        echo -e "  ${YELLOW}Potentially Vulnerable:${RESET} - [${CYAN}$url${RESET}] - (allows $malicious_origin without credentials)"
        [[ $save_to_files == true ]] && echo "$url" >> "$potentially_vulnerable_file"
    elif [[ "$access_control_origin" == "*" ]]; then
        echo -e "  ${YELLOW}Potentially Vulnerable:${RESET} - [${CYAN}$url${RESET}] - (allows wildcard (*) but doesn't allow credentials)"
        [[ $save_to_files == true ]] && echo "$url" >> "$potentially_vulnerable_file"
    else
        echo -e "  ${RED}Not Vulnerable:${RESET} - [${CYAN}$url${RESET}] - (does not allow $malicious_origin)"
        [[ $save_to_files == true ]] && echo "$url" >> "$not_vulnerable_file"
    fi
}

# Main function
function main() {
    # Parse command-line arguments
    while getopts "u:f:o:h" opt; do
        case $opt in
            u) url="$OPTARG" ;;
            f) file="$OPTARG" ;;
            o) output_prefix="$OPTARG"; save_to_files=true ;;
            h) show_help; exit 0 ;;
            *) show_help; exit 1 ;;
        esac
    done

    # Validate input
    if [[ -z "$url" && -z "$file" ]]; then
        echo -e "${RED}Error:${RESET} You must specify a URL (-u) or a file (-f)."
        show_help
        exit 1
    fi

    # Set output file paths if -o is used
    if [[ $save_to_files == true ]]; then
        vulnerable_file="${output_prefix}_vulnerable.txt"
        potentially_vulnerable_file="${output_prefix}_potentially_vulnerable.txt"
        not_vulnerable_file="${output_prefix}_not_vulnerable.txt"

        # Prepare output files
        for file in "$vulnerable_file" "$potentially_vulnerable_file" "$not_vulnerable_file"; do
            > "$file" || { echo -e "${RED}Error:${RESET} Cannot write to file $file"; exit 1; }
        done
    fi

    # Display banner
    banner

    # Process input
    if [[ -n "$url" ]]; then
        test_url "$url"
    elif [[ -n "$file" ]]; then
        while IFS= read -r url; do
            [[ -n "$url" ]] && test_url "$url"
        done < "$file"
    fi

    # Summary
    if [[ $save_to_files == true ]]; then
        echo -e "${BLUE}Testing complete!${RESET}"
        echo -e "  ${GREEN}Vulnerable URLs:${RESET} saved in $vulnerable_file"
        echo -e "  ${YELLOW}Potentially Vulnerable URLs:${RESET} saved in $potentially_vulnerable_file"
        echo -e "  ${RED}Not Vulnerable URLs:${RESET} saved in $not_vulnerable_file"
    else
        echo -e "${BLUE}Testing complete!${RESET} Results displayed above."
    fi
}

# Call main function
main "$@"
