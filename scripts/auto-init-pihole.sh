#!/bin/bash
# Pi-hole auto-initialization script
# Runs automatically when container starts
# Processes whitelist.txt and blacklist.txt automatically

echo "=========================================="
echo "Pi-hole Auto-Init: Configuring lists..."
echo "=========================================="

# Wait for Pi-hole to be completely started
echo "Waiting for Pi-hole to start completely..."
sleep 15

# Function to process domain file
process_domain_file() {
    local file_path="$1"
    local list_type="$2"  # 0 = whitelist, 1 = blacklist
    local list_name="$3"  # "whitelist" or "blacklist"
    
    echo ""
    echo "--- Processing $list_name ---"
    
    if [ ! -f "$file_path" ]; then
        echo "WARNING: $file_path not found, skipping $list_name"
        return 0
    fi
    
    echo "File found: $file_path"
    
    # Install sqlite3 if not available
    if ! command -v sqlite3 > /dev/null 2>&1; then
        echo "Installing sqlite3..."
        apk update > /dev/null 2>&1
        apk add sqlite > /dev/null 2>&1
    fi
    
    local count=0
    local success_count=0
    
    # Process each line of the file
    while IFS= read -r line; do
        # Clean whitespace
        line=$(echo "$line" | xargs)
        
        # Ignore empty lines and comments
        if [ -z "$line" ] || [[ "$line" =~ ^#.* ]]; then
            continue
        fi
        
        # Separate domain and comment
        if [[ "$line" == *"#"* ]]; then
            domain=$(echo "$line" | cut -d'#' -f1 | xargs)
            comment=$(echo "$line" | cut -d'#' -f2- | xargs)
        else
            domain="$line"
            comment="Auto-added from $list_name.txt"
        fi
        
        # Validate domain is not empty
        if [ -z "$domain" ]; then
            continue
        fi
        
        # Basic domain format validation
        if [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            count=$((count + 1))
            echo "  -> Adding: $domain"
            
            # Escape quotes for SQL
            escaped_comment=$(echo "$comment" | sed "s/'/''/g")
            
            # Insert into database
            sqlite3 /etc/pihole/gravity.db "INSERT OR REPLACE INTO domainlist (type, domain, enabled, comment) VALUES ($list_type, '$domain', 1, '$escaped_comment');" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                success_count=$((success_count + 1))
            else
                echo "     ERROR: Could not add $domain"
            fi
        else
            echo "  WARNING: Invalid domain ignored: $domain"
        fi
    done < "$file_path"
    
    echo "$list_name result: $success_count/$count domains added successfully"
    return 0
}

# Process whitelist
process_domain_file "/etc/pihole/whitelist.txt" 0 "whitelist"

# Process blacklist
process_domain_file "/etc/pihole/blacklist.txt" 1 "blacklist"

echo ""
echo "--- Applying changes ---"

# Reload Pi-hole lists
echo "Reloading Pi-hole lists..."
pihole reloadlists > /dev/null 2>&1

echo ""
echo "--- Final verification ---"

# Show summary of configured lists
if command -v sqlite3 > /dev/null 2>&1; then
    whitelist_count=$(sqlite3 /etc/pihole/gravity.db "SELECT COUNT(*) FROM domainlist WHERE type = 0;" 2>/dev/null || echo "0")
    blacklist_count=$(sqlite3 /etc/pihole/gravity.db "SELECT COUNT(*) FROM domainlist WHERE type = 1;" 2>/dev/null || echo "0")
    
    echo "Final status:"
    echo "  • Whitelist: $whitelist_count domains"
    echo "  • Blacklist: $blacklist_count domains"
else
    echo "  • sqlite3 not available for verification"
fi

echo ""
echo "=========================================="
echo "Pi-hole Auto-Init: Configuration complete"
echo "=========================================="

# Create mark file to indicate script was executed
touch /etc/pihole/.auto-init-completed
echo "Completion mark created: $(date)" > /etc/pihole/.auto-init-completed