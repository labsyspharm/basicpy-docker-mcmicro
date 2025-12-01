# Build script for pre-warming a cache of Java artifact files needed for
# bioformats image format support. Only used during docker build.

import bioio_bioformats
import os
import pathlib
import scyjava

# Set up our own location for maven and jgo to stash their files and configure
# scyjava to use it. (jgo and maven are already configured via environment
# variables set in the container definition)
base = pathlib.Path('/opt/scyjava')
base.mkdir(exist_ok=True)
scyjava.config.set_cache_dir(base / '.jgo')
scyjava.config.set_m2_repo(base / '.m2' / 'repository')

# Initialize the Reader to trigger download of the artifacts. We need to pass a
# path that exists to bypass an initial check, but this isn't an image file so
# ultimately the Reader will error. We don't care since the artifacts will have
# been downloaded by then.
try:
    bioio_bioformats.Reader('/')
except Exception:
    pass

# Open up permissions on the artifacts so they can be read (and written if any
# new jgo workspace configurations arise) regardless of what uid is used for
# running in the container.
for root, dirs, files in os.walk(base):
    root = pathlib.Path(root)
    root.chmod(0o777)
    for dname in dirs:
        (root / dname).chmod(0o777)
    for fname in files:
        (root / fname).chmod(0o666)
