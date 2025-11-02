#!/usr/bin/env python3
"""
Simple patch to fix DispatchQueue.main.async trailing closure syntax
Swift 5 with strict concurrency (Xcode 16.4+) requires explicit execute: parameter
"""

import sys

PLUGIN_SWIFT = "node_modules/@codetrix-studio/capacitor-google-auth/ios/Plugin/Plugin.swift"

print("📝 Fixing DispatchQueue.main.async trailing closure syntax...")

try:
    with open(PLUGIN_SWIFT, 'r') as f:
        lines = f.readlines()
except FileNotFoundError:
    print(f"❌ Plugin.swift not found: {PLUGIN_SWIFT}")
    sys.exit(1)

# Backup
with open(PLUGIN_SWIFT + ".dispatch.bak", 'w') as f:
    f.writelines(lines)

# Track which lines need closing paren
lines_needing_close_paren = []

# Pass 1: Fix DispatchQueue.main.async { → DispatchQueue.main.async(execute: {
for i, line in enumerate(lines):
    if 'DispatchQueue.main.async {' in line:
        lines[i] = line.replace('DispatchQueue.main.async {', 'DispatchQueue.main.async(execute: {')
        lines_needing_close_paren.append(i)
        print(f"✅ Line {i+1}: Fixed DispatchQueue.main.async")

if not lines_needing_close_paren:
    print("⚠️  No DispatchQueue.main.async found - nothing to fix")
    sys.exit(0)

# Pass 2: Find the matching closing brace for each async block
# We need to add ) before the final }
for async_line_idx in lines_needing_close_paren:
    # Find the matching closing brace
    # Count braces starting from the async line
    brace_count = 0
    started = False

    for i in range(async_line_idx, len(lines)):
        line = lines[i]

        # Count opening and closing braces
        for char in line:
            if char == '{':
                brace_count += 1
                started = True
            elif char == '}':
                brace_count -= 1

                # When we reach 0, we found the matching closing brace
                if started and brace_count == 0:
                    # This is the closing brace for the async block
                    # We need to add ) before it
                    # Find the position of } in the line
                    close_brace_pos = line.rfind('}')
                    if close_brace_pos != -1:
                        lines[i] = line[:close_brace_pos] + '})' + line[close_brace_pos+1:]
                        print(f"✅ Line {i+1}: Added closing paren")
                        break
    else:
        print(f"❌ Warning: Could not find closing brace for async block starting at line {async_line_idx+1}")

# Write patched content
with open(PLUGIN_SWIFT, 'w') as f:
    f.writelines(lines)

# Verify
with open(PLUGIN_SWIFT, 'r') as f:
    content = f.read()

if 'DispatchQueue.main.async {' in content:
    print("❌ ERROR: Still has old syntax!")
    # Restore backup
    with open(PLUGIN_SWIFT + ".dispatch.bak", 'r') as f:
        backup = f.read()
    with open(PLUGIN_SWIFT, 'w') as f:
        f.write(backup)
    sys.exit(1)

if 'DispatchQueue.main.async(execute: {' in content:
    print("✅ Successfully patched DispatchQueue.main.async syntax!")
    sys.exit(0)
else:
    print("⚠️  Warning: No DispatchQueue.main.async found in file")
    sys.exit(0)
