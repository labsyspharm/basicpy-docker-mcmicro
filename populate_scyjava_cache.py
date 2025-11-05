# Build script for pre-warming a cache of Java artifact files needed for
# bioformats image format support. Only used during docker build.

import bfio
import jpype
import os
import pathlib
import scyjava

# Set up our own location for maven and jgo to stash their files and configure
# scyjava and jgo to use it.
base = pathlib.Path('/opt/scyjava')
base.mkdir(exist_ok=True)
scyjava.config.set_cache_dir(base / '.jgo')
scyjava.config.set_m2_repo(base / '.m2' / 'repository')
# This is actually the easiest way to globally set the jgo cache dir.
os.environ['JGO_CACHE_DIR'] = str(scyjava.config.get_cache_dir())

# Using aicsimageio to read OME/Bioformats files can lead to the creation of two
# different jgo workspaces depending on which of the bioformats and bfio readers
# are loaded and in which order. The workspace configurations are actually
# identical but one has the same bioformats endpoint listed twice which results
# in a different hash. We want to ensure all possible workspaces already exist
# in the built container image to avoid downloading artifacts at runtime. The
# following specific sequence of calls is critical for populating both possible
# jgo workspaces. It is fragile and highly dependent on internal implementation
# details of these modules, so we will carefully document our understanding of
# what each step is doing.
#
# 1. bioformats_jar adds the bioformats jgo endpoint to scyjava at import time.
import bioformats_jar
# 2. Trigger jgo to populate the workspace for bioformats.
bioformats_jar.get_loci()
# 3. Shut down the JVM so bfio will later attempt its own initialization.
jpype.shutdownJVM()
try:
    # 4. bfio adds a second copy of the bioformats endpoint to scyjava here,
    # creating the other possible workspace. It then attempts to start the JVM.
    bfio.start()
except OSError:
    # 5. Starting the JVM after a shutdown isn't supported but we don't need it
    # anymore. Catch and ignore the exception.
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
