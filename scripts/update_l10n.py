import os
import glob

locales_dir = r"c:\Users\shubh\Desktop\fsap\mobile\lib\l10n"
arb_files = glob.glob(os.path.join(locales_dir, "*.arb"))

replacements = {
    "₹299": "₹199",
    "₹99": "₹199",
    "3 days": "1 day",
    "3 दिनों": "1 दिन", 
    "3 दिवसांसाठी": "1 दिवसासाठी", 
}

for file in arb_files:
    with open(file, "r", encoding="utf-8") as f:
        content = f.read()
    
    for old, new in replacements.items():
        content = content.replace(old, new)
        
    with open(file, "w", encoding="utf-8") as f:
        f.write(content)

print(f"Updated {len(arb_files)} .arb files")
