"""Rebuild the bundled 60-second ambience mix with ffmpeg."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
AMBIENCE = ROOT / "Assets/Audio/Ambience"

filters = (
    "[0:a][1:a]acrossfade=d=4[b12];"
    "[b12][2:a]acrossfade=d=4,atrim=duration=60,volume=0.65[wind];"
    "[3:a]volume=0.3,afade=t=in:d=3,afade=t=out:st=42:d=6,adelay=8000:all=1[birds];"
    "[4:a]atrim=duration=18,lowpass=f=2200,volume=0.14,"
    "afade=t=in:d=3,afade=t=out:st=12:d=6,adelay=12000:all=1[bells];"
    "[wind][birds][bells]amix=inputs=3:duration=longest:normalize=0,"
    "atrim=duration=60,afade=t=in:d=2,afade=t=out:st=57:d=3[out]"
)

if __name__ == "__main__":
    command = ["ffmpeg", "-v", "error", "-y"]
    for source in ["breeze-and-birds.ogg"] * 3 + ["birds.ogg", "church-bells.ogg"]:
        command.extend(["-i", str(AMBIENCE / source)])
    command.extend([
        "-filter_complex", filters, "-map", "[out]",
        "-c:a", "libvorbis", "-q:a", "5", str(AMBIENCE / "courtyard.ogg"),
    ])
    subprocess.run(command, check=True)
