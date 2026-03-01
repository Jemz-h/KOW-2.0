import re

path = '/Users/lei/Desktop/KOW-2.0-main/lib/screens/start_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Build replacement using regex to be safe with whitespace
old_pattern = re.compile(
    r'( +)// Main title\n'
    r'\1Positioned\(\n'
    r'\s+top: h \* 0\.14,\n'
    r'\s+left: 20,\n'
    r'\s+right: 20,\n'
    r'\s+child: Text\(\n'
    r"\s+'KARUNUNGAN\\nON WHEELS',\n"
    r'.*?'
    r'\1\),\n'
    r'\n'
    r'\1// Subtitle\n'
    r'\1Positioned\(\n'
    r'\s+top: h \* 0\.28,\n'
    r'\s+left: 30,\n'
    r'\s+right: 30,\n'
    r'\s+child: Text\(\n'
    r'.*?'
    r'\1\),\n',
    re.DOTALL
)

m = old_pattern.search(content)
if not m:
    print("Pattern NOT found")
else:
    indent = m.group(1)
    print(f"Pattern found at {m.start()}-{m.end()}, indent='{indent}'")
    new_block = (
        f"{indent}// Main title \u2014 fade-in + slide-up entrance\n"
        f"{indent}Positioned(\n"
        f"{indent}  top: h * 0.14,\n"
        f"{indent}  left: 20,\n"
        f"{indent}  right: 20,\n"
        f"{indent}  child: AnimatedOpacity(\n"
        f"{indent}    opacity: _titleEntered ? 1.0 : 0.0,\n"
        f"{indent}    duration: const Duration(milliseconds: 600),\n"
        f"{indent}    curve: Curves.easeOut,\n"
        f"{indent}    child: AnimatedSlide(\n"
        f"{indent}      offset: _titleEntered\n"
        f"{indent}          ? Offset.zero\n"
        f"{indent}          : const Offset(0, 0.06),\n"
        f"{indent}      duration: const Duration(milliseconds: 600),\n"
        f"{indent}      curve: Curves.easeOut,\n"
        f"{indent}      child: Text(\n"
        f"{indent}        'KARUNUNGAN\\nON WHEELS',\n"
        f"{indent}        textAlign: TextAlign.center,\n"
        f"{indent}        style: TextStyle(\n"
        f"{indent}          fontFamily: 'SuperCartoon',\n"
        f"{indent}          fontSize: contentW * 0.15,\n"
        f"{indent}          fontWeight: FontWeight.w900,\n"
        f"{indent}          height: 1.0,\n"
        f"{indent}          color: Colors.white,\n"
        f"{indent}          shadows: const [\n"
        f"{indent}            Shadow(\n"
        f"{indent}              blurRadius: 4,\n"
        f"{indent}              color: Colors.black54,\n"
        f"{indent}              offset: Offset(2, 2),\n"
        f"{indent}            ),\n"
        f"{indent}          ],\n"
        f"{indent}        ),\n"
        f"{indent}      ),\n"
        f"{indent}    ),\n"
        f"{indent}  ),\n"
        f"{indent}),\n"
        f"\n"
        f"{indent}// Subtitle \u2014 fade-in + slide-up entrance (slight delay)\n"
        f"{indent}Positioned(\n"
        f"{indent}  top: h * 0.28,\n"
        f"{indent}  left: 30,\n"
        f"{indent}  right: 30,\n"
        f"{indent}  child: AnimatedOpacity(\n"
        f"{indent}    opacity: _subtitleEntered ? 1.0 : 0.0,\n"
        f"{indent}    duration: const Duration(milliseconds: 600),\n"
        f"{indent}    curve: Curves.easeOut,\n"
        f"{indent}    child: AnimatedSlide(\n"
        f"{indent}      offset: _subtitleEntered\n"
        f"{indent}          ? Offset.zero\n"
        f"{indent}          : const Offset(0, 0.06),\n"
        f"{indent}      duration: const Duration(milliseconds: 600),\n"
        f"{indent}      curve: Curves.easeOut,\n"
        f"{indent}      child: Text(\n"
        f"{indent}        '\u201cENHANCING FUNCTIONAL LITERACY THROUGH LOCALLY DEVELOPED INSTRUCTIONAL MATERIALS\u201d',\n"
        f"{indent}        textAlign: TextAlign.center,\n"
        f"{indent}        style: TextStyle(\n"
        f"{indent}          fontFamily: 'SuperCartoon',\n"
        f"{indent}          fontSize: contentW * 0.045,\n"
        f"{indent}          fontWeight: FontWeight.w800,\n"
        f"{indent}          height: 1.25,\n"
        f"{indent}          color: const Color(0xFFFFE34D),\n"
        f"{indent}          shadows: const [\n"
        f"{indent}            Shadow(\n"
        f"{indent}              blurRadius: 4,\n"
        f"{indent}              color: Colors.black45,\n"
        f"{indent}              offset: Offset(1, 1),\n"
        f"{indent}            ),\n"
        f"{indent}          ],\n"
        f"{indent}        ),\n"
        f"{indent}      ),\n"
        f"{indent}    ),\n"
        f"{indent}  ),\n"
        f"{indent}),\n"
    )
    new_content = content[:m.start()] + new_block + content[m.end():]
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Done! File updated successfully.")
