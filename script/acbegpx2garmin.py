#!/usr/bin/python3
# -*-coding:Utf-8 -*


#import tarfile
#import zipfile
#from datetime import datetime
#from operator import itemgetter, attrgetter
#import argparse
#import time
#import datetime
#import signal
#import logging
#import math
#import fractions
#import random
#from getpass import getpass
#import hashlib

"""
Ce module contient notre programme
"""

import os
import os.path
import re
import subprocess
import urllib.request
import sys
import re
import shutil

"""
Variables importantes / valeur par défaut
"""
url          = 'http://acbe.ffct.org/Calendrier/'
code_page    = 'iso8859-1'
download_dir = os.path.join(os.path.expanduser("~"), "Downloads", "gpx")

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

re_tag            = re.compile(r"""
        <td[^>]*prochain[^>]*>\w+\s+(\d+)\s+(\S+)\s+(\d+)</td><td[^>]*>([\dh]+).*? # la date
        <a\s+href="                                                                # le starter de lien
        (\S+openrunner[^"]+)                                                       # le lien openrunner
        "[^>]*>                                                                    # la fin du de la balise de lien
        <img\s+title="Open\w+\s+                                                   # l'image avec un titre
        ([^"]+)""", re.VERBOSE | re.MULTILINE | re.DOTALL)

re_id             = re.compile(r'/(\d+)$')

re_replace_track = re.compile(r'<name>(\d+)-([^<]+)</name>')
"""
Fin template expression régulière
"""

if __name__ == '__main__':
#
# Fonction
#
    def eject_usb_device(device):
        device = os.path.join('/dev', device)
        print(device)
        subprocess.run(['udisksctl', 'unmount', '-b', device])
        subprocess.run(['udisksctl', 'power-off', '-b', device])

    def warn(message):
        print(message, file=sys.stderr)

    def switch_re(patterns, text):
        for regexp, result in patterns.items():
            if regexp.match(text):
                return result

    try:
        os.mkdir(download_dir)
    except:
        pass

    print("Finding GARMIN...")
    reg          = re.compile(r'^(\w+).*?disk (/media/\S+)', re.MULTILINE)
    output       = subprocess.check_output(['lsblk']).decode('utf8')
    (device, garmin_mount) = reg.search(output).group(1,2)
    garmin_dir   = os.path.join(garmin_mount, 'Garmin', 'NewFiles')
    flag_garmin  = False
    if os.path.isdir(garmin_dir):
        print("Found GARMIN")
        flag_garmin = True

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
        if flag_garmin:
            target = os.path.join(garmin_dir, os.path.basename(tmp_file))
            print(target)
            shutil.move(tmp_file, os.path.join(garmin_dir, os.path.basename(tmp_file)))

    if flag_garmin:
        eject_usb_device(device)
