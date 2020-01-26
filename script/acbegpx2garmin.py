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

import requests
import logging
import os
import os.path
import re
import subprocess
import urllib.request
import sys
import re
import shutil
import time

"""
Functions
"""
def switch_re(patterns, text):
    """
    Find re matching a text. To simulate a SWITCH test
    Input (text), check to each regexp, il match return result
    If nothing, None

    Args:
        patterns (hash) : hash of regexp => result
        text : regexp
    
    Return:
        result associated with one regexp
    
    """
    for regexp, result in patterns.items():
        if regexp.match(text):
            return result
    return None

def eject_usb_device(device):
    """
    Eject one usb device
    Note:
        the full path is concatenate in the function. Use logging.
    
    Args:
        device (str) : usb name device to eject.
        
    Returns:
        None
    
    Raises:
        None. Propagate erros from subprocess
    """
    device = os.path.join('/dev', device)
    logging.info(device)
    subprocess.run(['udisksctl', 'unmount', '-b', device])
    subprocess.run(['udisksctl', 'power-off', '-b', device])

"""
Variables importantes / valeur par défaut
"""
url          = 'http://acbe.ffct.org/Calendrier/'
code_page    = 'iso8859-1'
download_dir = os.path.join(os.path.expanduser("~"), "Downloads", "gpx")

"""
Template expression régulière
"""

re_tag            = re.compile(r"""
        <td[^>]*prochain[^>]*>\w+\s+(\d+)\s+(\S+)\s+(\d+)</td><td[^>]*>([\dh]+).*? # la date
        <a\s+href="                                                                # le starter de lien
        (\S+openrunner[^"]+)                                                       # le lien openrunner
        "[^>]*>                                                                    # la fin du de la balise de lien
        <img\s+title="Open\w+\s+                                                   # l'image avec un titre
        ([^"]+)""", re.VERBOSE | re.MULTILINE | re.DOTALL)



re_replace_track = re.compile(r'<name>(\d+)-([^<]+)</name>')
"""
Fin template expression régulière
"""

re_id = re.compile(r'/(\d+)$')
def openrunner_id_from_url(url):
    """
    Args:
        url formed like openrunner track
    Rerturns:
        id in the url
    Raises:
        AttributeError
    """
    id = re_id.search(url).group(1)
    return id

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
def def_track_name_from_content(item, id):
    """
    Args:
        item : list
        url  : id of the track
    Returns:
        track_name
    """
    # Unpack list
    (day, month, year, start_time, url_openrunner, name) = item
    # Find month number from month name
    month = switch_re(patterns_compiled, month)
    id    = openrunner_id_from_url(url_openrunner)
    return (name, id, "{}_{}_{}-{}".format(name, id, day, month))

def download_openrunner_track_id(id, gpx_local_file):
    """
    Args:
        id (int): openrunner id
        gpx_local_file(path) : local path
    Returns:
        None
    """
    gpx_track_url = "https://www.openrunner.com/route/{}/gpx?type=0".format(id)
    logging.debug("Downloading {} in file '{}'...".format(gpx_track_url, gpx_local_file))
    urllib.request.urlretrieve(gpx_track_url, gpx_local_file)

def find_and_set_garmin_dir():
    """
    Args:
        None
    Returns:
        garmin_dir if garmin connected (could be used as flag)
    """
    garmin_inside_path  = ['Garmin', 'NewFiles']
    garmin_dir          = ""
    device              = ""
    
    reg          = re.compile(r'^(\w+).*?disk (/media/\S+)', re.MULTILINE)
    try:
        output     = subprocess.check_output(['lsblk']).decode('utf8')
        logging.debug(output)
        
        (device, garmin_mount) = reg.search(output).group(1,2)
        garmin_dir = os.path.join(garmin_mount, *garmin_inside_path)
        
        if not os.path.isdir(garmin_dir):
            # Unset garmin dir
            garmin_dir = ""
            raise NameError("Garmin dir {} not found.".format(garmin_dir))
        
        print("Garmin connected.")
        
    except NameError as err:
        logging.error("{}".format(err))
    except AttributeError as err:
        logging.error("no USB Garmin devices")
    except OSError as err:
        logging.error("OS Error: {}".format(err))
    
    return (device, garmin_dir)

if __name__ == '__main__':
#
# Fonction
#
    try:
        os.mkdir(download_dir)
    except OSError:
        pass

    print("Finding GARMIN...")
    device, garmin_dir = find_and_set_garmin_dir()

    print("Get url {}...".format(url))
    try:
        content = requests.get(url).text
    except:
        logging.fatal("Unable to get url {}".format(url))
        sys.exit(8)

    print("Finding track for openrunner {}...".format(id))
    for item in re_tag.findall(content):
        name, id, track_name = def_track_name_from_content(item)
        print("Found track {}".format(track_name))
        gpx_file = os.path.join(download_dir, "{}_{}.gpx".format(name, id))

        if not os.path.isfile(gpx_file):
            download_openrunner_track_id(id, gpx_file)
        else:
            print("/!\ {} already downloaded".format(os.path.basename(gpx_file)))
    
        tmp_file = os.path.join("/tmp", "{}.gpx".format(track_name))
        logging.warn("File {} renamed".format(tmp_file))
        with open(tmp_file, 'w') as gpx_dest:
            with open(gpx_file, 'r') as gpx_src:
                for line in gpx_src:
                    if re_replace_track.search(line):
                        line = re_replace_track.sub(r'<name>\2-\1_{}-{}</name>'.format(day, month), line)
                    gpx_dest.write(line)
        
        if garmin_dir:
            target = os.path.join(garmin_dir, os.path.basename(tmp_file))
            print("GARMIN Destination file: {}".format(target))
            shutil.move(tmp_file, target)
            time.sleep(10)

    if device:
        eject_usb_device(device)
