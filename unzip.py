#!/usr/bin/env python

import sys
from zipfile import ZipFile

with ZipFile(sys.argv[1]) as zip:
     for file in zip.namelist():
         if file.endswith("JndiManager.class") or file.endswith("JmsAppender.class"):
             zip.extract(file, sys.argv[2])
