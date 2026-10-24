"""Adds Lobster_Lagoon.gmd to your Geometry Dash created levels, without mods.

    python install_level.py                    # finds your save automatically
    python install_level.py --save PATH/CCLocalLevels.dat

Close Geometry Dash first. A timestamped backup of CCLocalLevels.dat is made
next to it before anything is written. The save format (XOR 11 -> base64 ->
gzip on Windows/Linux, AES-ECB on macOS) is documented in gd-docs
topics/localfiles_encrypt_decrypt.md; macOS needs `pip install pycryptodome`.

If you use Geode, importing the .gmd with a level import mod (for example
GDShare) is simpler and does not touch the save file.
"""

import argparse
import base64
import gzip
import os
import shutil
import sys
import time
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

MAC_KEY = (b"\x69\x70\x75\x39\x54\x55\x76\x35\x34\x79\x76\x5d\x69\x73\x46\x4d"
           b"\x68\x35\x40\x3b\x74\x2e\x35\x77\x33\x34\x45\x32\x52\x79\x40\x7b")


def default_save():
    home = Path.home()
    candidates = []
    if os.environ.get("LOCALAPPDATA"):
        candidates.append(Path(os.environ["LOCALAPPDATA"]) / "GeometryDash")
    candidates += [
        home / "Library/Application Support/GeometryDash",
        home / ".steam/steam/steamapps/compatdata/322170/pfx/drive_c/users/"
               "steamuser/AppData/Local/GeometryDash",
        home / ".local/share/Steam/steamapps/compatdata/322170/pfx/drive_c/"
               "users/steamuser/AppData/Local/GeometryDash",
    ]
    for c in candidates:
        if (c / "CCLocalLevels.dat").is_file():
            return c / "CCLocalLevels.dat"
    return None


def decode_save(data):
    if data.lstrip().startswith(b"<?xml"):
        return data.decode(), "plain"
    try:
        x = bytes(b ^ 11 for b in data).rstrip(b"\0")
        x = x.replace(b"+", b"-").replace(b"/", b"_")
        x += b"=" * (-len(x) % 4)
        return zlib.decompress(base64.urlsafe_b64decode(x), 15 | 32).decode(), "windows"
    except Exception:
        pass
    try:
        from Crypto.Cipher import AES
    except ImportError:
        sys.exit("This looks like a macOS save; run `pip install pycryptodome` first.")
    plain = AES.new(MAC_KEY, AES.MODE_ECB).decrypt(data)
    if plain and plain[-1] < 16:
        plain = plain[:-plain[-1]]
    return plain.decode(), "mac"


def encode_save(text, kind):
    raw = text.encode()
    if kind == "plain":
        return raw
    if kind == "windows":
        return bytes(b ^ 11 for b in base64.urlsafe_b64encode(gzip.compress(raw)))
    from Crypto.Cipher import AES
    pad = 16 - len(raw) % 16
    return AES.new(MAC_KEY, AES.MODE_ECB).encrypt(raw + bytes([pad]) * pad)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--save", help="path to CCLocalLevels.dat")
    ap.add_argument("--gmd", default=str(Path(__file__).with_name("Lobster_Lagoon.gmd")))
    args = ap.parse_args()

    save = Path(args.save) if args.save else default_save()
    if not save or not save.is_file():
        sys.exit("Could not find CCLocalLevels.dat - pass it with --save")
    level = ET.parse(args.gmd).getroot().find("dict")
    level.tag = "d"          # nested dictionaries in a save are <d>, not <dict>
    name = level[list(level).index(next(k for k in level if k.text == "k2")) + 1].text

    text, kind = decode_save(save.read_bytes())
    root = ET.fromstring(text)
    top = root.find("dict")
    kids = list(top)
    llm = None
    for i in range(0, len(kids) - 1, 2):
        if kids[i].text == "LLM_01":
            llm = kids[i + 1]
    if llm is None:
        key = ET.Element("k")
        key.text = "LLM_01"
        llm = ET.Element("d")
        top.insert(0, key)
        top.insert(1, llm)
        arr_k = ET.SubElement(llm, "k")
        arr_k.text = "_isArr"
        ET.SubElement(llm, "t")

    # shift k_0, k_1, ... down by one and put the new level first
    items = list(llm)
    for el in items:
        if el.tag == "k" and el.text and el.text.startswith("k_"):
            el.text = f"k_{int(el.text[2:]) + 1}"
    pos = 2 if len(items) >= 2 and items[0].text == "_isArr" else 0
    new_key = ET.Element("k")
    new_key.text = "k_0"
    llm.insert(pos, new_key)
    llm.insert(pos + 1, level)

    backup = save.with_name(f"CCLocalLevels.backup-{time.strftime('%Y%m%d-%H%M%S')}.dat")
    shutil.copy2(save, backup)
    out = '<?xml version="1.0"?>' + ET.tostring(root, encoding="unicode")
    save.write_bytes(encode_save(out, kind))
    print(f"Added '{name}' to {save}\nBackup saved as {backup.name}")


if __name__ == "__main__":
    main()
