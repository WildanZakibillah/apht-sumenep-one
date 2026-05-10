import os
import re
import sys

def main():
    lib_dir = "lib"
    for root, _, files in os.walk(lib_dir):
        for file in files:
            if not file.endswith('.dart'):
                continue
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Very aggressive but safe for UI code:
            # Whenever we see const  before a Widget or class, and AppTheme. is nearby, we remove const .
            # Since it's hard to parse Dart, we'll just remove const  everywhere in files that use AppTheme.
            # Wait, no, we shouldn't remove ALL const.
            
            lines = content.split('\n')
            changed = False
            
            # Fix 1: "const " on the same line as AppTheme
            for i in range(len(lines)):
                if "AppTheme." in lines[i] and "const " in lines[i]:
                    lines[i] = lines[i].replace("const ", "")
                    changed = True
                    
            # Fix 2: "const " on the line before AppTheme
            for i in range(len(lines)):
                if "AppTheme." in lines[i]:
                    # look upwards up to 10 lines for const  and remove it
                    for j in range(i, max(-1, i-10), -1):
                        if "const " in lines[j]:
                            # check if it's likely a widget/style instantiation
                            if re.search(r'const\s+[A-Z]', lines[j]) or "const [" in lines[j] or "const {" in lines[j]:
                                lines[j] = lines[j].replace("const ", "")
                                changed = True
            
            # Some constants might have been const AppTheme.xxx which we just broke to AppTheme.xxx.
            # What if there's const SizedBox? We removed it. That's fine, it just becomes SizedBox.
            
            if changed:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write('\n'.join(lines))
                    
if __name__ == '__main__':
    main()
