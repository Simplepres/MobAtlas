from pathlib import Path
import zipfile,hashlib
root=Path(__file__).resolve().parents[1]
version=next(line.split(":",1)[1].strip() for line in (root/"MobAtlas/MobAtlas.toc").read_text().splitlines() if line.startswith("## Version:"))
output=root/"dist"/f"MobAtlas-{version}.zip"
output.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(output,"w",zipfile.ZIP_DEFLATED) as z:
    for p in sorted((root/"MobAtlas").rglob("*")):
        if p.is_file() and p.name!=".DS_Store":z.write(p,p.relative_to(root))
with zipfile.ZipFile(output) as z:
    assert z.testzip() is None
    assert "MobAtlas/MobAtlas.toc" in z.namelist()
(output.parent/"SHA256SUMS.txt").write_text(hashlib.sha256(output.read_bytes()).hexdigest()+"  "+output.name+"\n")
print(output)
