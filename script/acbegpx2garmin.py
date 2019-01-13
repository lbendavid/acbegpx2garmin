#!/usr/bin/python3
# -*-coding:Utf-8 -*

"""
Ce module contient notre programme
"""


import os
import os.path
import tarfile
import zipfile
from datetime import datetime
from operator import itemgetter, attrgetter
import argparse
import time
import datetime
import re
import sys
import os
import signal
import logging
import subprocess
import math
import fractions
import random
from getpass import getpass
import hashlib

import urllib.request
import sys
import re


"""
Template expression régulière
"""
patterns = {
    r'^ja':   '01',
    r'^f':    '02', 
    r'^mar':  '03',
    r'^av':   '04',
    r'^mai':  '05',
    r'^juin': '06',
    r'^juil': '07',
    r'^a':    '08',
    r'^sep':  '09',
    r'^oct':  '10',
    r'^nov':  '11',
    r'^d':    '12',
}
patterns_compiled = { re.compile(p, re.I): v for p, v in patterns.items() }

re_tag       = re.compile(r"""
        <td[^>]*prochain[^>]*>\w+\s+(\d+)\s+(\S+)\s+(\d+)</td><td[^>]*>([\dh]+).*? # la date
        <a\s+href="                                                                # le starter de lien
        (\S+openrunner[^"]+)                                                       # le lien openrunner
        "[^>]*>                                                                    # la fin du de la balise de lien
        <img\s+title="Open\w+\s+                                                   # l'image avec un titre
        ([^"]+)""", re.VERBOSE | re.MULTILINE | re.DOTALL)

re_id        = re.compile(r'/(\d+)$')

re_replace_track = re.compile(r'<name>(\d+)-([^<]+)</name>')
"""
Fin template expression régulière
"""

#
# Fonction
#
def warn(message):
    print(message, file=sys.stderr)

def switch_re(patterns, text):
    for regexp, result in patterns.items():
        if regexp.match(text):
            return result

url          = 'http://acbe.ffct.org/Calendrier/'
code_page    = 'iso8859-1'

download_dir = os.path.join(os.path.expanduser("~"), "Downloads", "gpx")
try:
    os.mkdir(download_dir)
except:
    pass

print("Retrieving url {}...".format(url))
page    = urllib.request.urlopen(url)
content = page.read().decode(code_page)

print("Finding track...")
for item in re_tag.findall(content):
    (day, month, year, start_time, url, name) = item
    month      = switch_re(patterns_compiled, month)
    id         = re_id.search(url).group(1)
    track_name = "{}_{}_{}-{}".format(name, id, day, month)
    print("Found track {}".format(track_name))
    
    gpx_file = os.path.join(download_dir, "{}_{}.gpx".format(name, id))

    if not os.path.isfile(gpx_file):
        print("Downloading in file '{}'...".format(gpx_file))
        gpx_track_url = "https://www.openrunner.com/route/{}/gpx?type=0".format(id)
        urllib.request.urlretrieve(gpx_track_url, gpx_file)
    
    tmp_file = os.path.join("/tmp", "{}.gpx".format(track_name))
    with open(tmp_file, 'w') as gpx_dest:
        with open(gpx_file, 'r') as gpx_src:
            for line in gpx_src:
                if re_replace_track.search(line):
                    line = re_replace_track.sub(r'<name>\2-\1_{}-{}</name>'.format(day, month), line)

                gpx_dest.write(line)

#print(content)



#os.path.join(download_dir, 