#!/usr/bin/env python3
# split-packagexml.py
# Splits a large package.xml into multiple batches of max 8000 members each
# Run from the root of your SF-CICD-HARDIS project:
#   python3 split-packagexml.py

import xml.etree.ElementTree as ET
import os

INPUT_FILE = "./packagexmlfull.xml"
MAX_MEMBERS = 8000
NAMESPACE = "http://soap.sforce.com/2006/04/metadata"

def create_package_xml(types_data, version, batch_num):
    """Create a package.xml string from types data"""
    lines = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>']
    lines.append(f'<Package xmlns="{NAMESPACE}">')
    for type_name, members in types_data.items():
        lines.append('    <types>')
        for member in members:
            lines.append(f'        <members>{member}</members>')
        lines.append(f'        <name>{type_name}</name>')
        lines.append('    </types>')
    lines.append(f'    <version>{version}</version>')
    lines.append('</Package>')
    return '\n'.join(lines)

# Parse the input file
print(f"📂 Reading {INPUT_FILE}...")
tree = ET.parse(INPUT_FILE)
root = tree.getroot()

# Extract version
version = "65.0"
version_elem = root.find(f'{{{NAMESPACE}}}version')
if version_elem is not None:
    version = version_elem.text

# Collect all types and their members
all_types = {}
for types_elem in root.findall(f'{{{NAMESPACE}}}types'):
    name_elem = types_elem.find(f'{{{NAMESPACE}}}name')
    if name_elem is None:
        continue
    type_name = name_elem.text
    members = [m.text for m in types_elem.findall(f'{{{NAMESPACE}}}members')]
    if members:
        all_types[type_name] = members

total_members = sum(len(m) for m in all_types.values())
print(f"📊 Total metadata types: {len(all_types)}")
print(f"📊 Total members: {total_members}")
print(f"📊 Will split into batches of max {MAX_MEMBERS} members\n")

# Split into batches
batches = []
current_batch = {}
current_count = 0

for type_name, members in all_types.items():
    # If a single type has more than MAX_MEMBERS, split it further
    if len(members) > MAX_MEMBERS:
        chunks = [members[i:i+MAX_MEMBERS] for i in range(0, len(members), MAX_MEMBERS)]
        for chunk in chunks:
            if current_count + len(chunk) > MAX_MEMBERS:
                if current_batch:
                    batches.append(current_batch)
                current_batch = {}
                current_count = 0
            current_batch[type_name] = current_batch.get(type_name, []) + chunk
            current_count += len(chunk)
    else:
        if current_count + len(members) > MAX_MEMBERS:
            batches.append(current_batch)
            current_batch = {}
            current_count = 0
        current_batch[type_name] = members
        current_count += len(members)

if current_batch:
    batches.append(current_batch)

# Write batch files
print(f"✂️  Creating {len(batches)} batch files...\n")
for i, batch in enumerate(batches, 1):
    filename = f"./packagexml-batch-{i}.xml"
    content = create_package_xml(batch, version, i)
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    member_count = sum(len(m) for m in batch.values())
    print(f"  ✅ Batch {i}: {filename} → {member_count} members, {len(batch)} types")

print(f"\n🎉 Done! Created {len(batches)} batch files.")
print("\n📋 Now run these commands one by one to retrieve metadata:")
for i in range(1, len(batches) + 1):
    print(f"  sf project retrieve start -x ./packagexml-batch-{i}.xml --ignore-conflicts")