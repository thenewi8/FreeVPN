#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Abstract: upyun

import json
import hashlib
import base64
import time
import upyun
import logging

from settings import UPYUN
from collections import OrderedDict


def signature_policy(params, form_api_secret=UPYUN['secret']):
    params.update({
        'expiration': int(time.time()) + 86400
    })
    params_str = ''.join([str(p[0]) + str(p[1]) for p in sorted(params.items())])

    signature = hashlib.md5((params_str + form_api_secret).encode()).hexdigest()
    policy = base64.b64encode(json.dumps(params).encode()).decode()

    return signature, policy

def form_signature_policy(params, form_api_secret=UPYUN['secret']):
    params.update({
        'expiration': int(time.time()) + 86400
    })

    policy = base64.b64encode(json.dumps(OrderedDict(sorted(params.items()))).encode()).decode()
    signature = hashlib.md5(('%s&%s' % (policy, form_api_secret)).encode()).hexdigest()

    return signature, policy

def delete_mtv(mtv):
    up = upyun.UpYun(UPYUN['bucket'], UPYUN['username'], UPYUN['password'], timeout=5, endpoint=upyun.ED_AUTO)

    cover_url, mpg_url, ts_url = mtv['cover_url'], mtv['mpg_url'], mtv['ts_url']
    cover_file = cover_url.replace(UPYUN['cdn'], '')
    mpg_file = mpg_url.replace(UPYUN['cdn'], '')
    ts_file = ts_url.replace(UPYUN['cdn'], '')

    is_success = True

    try:
        up.delete(mpg_file)
        logging.info('delete upyun file: %s' % mpg_file)
    except:
        logging.error('delete upyun file fail: %s' % mpg_file)
        is_success = False

    try:
        up.delete(ts_file)
        logging.info('delete upyun file: %s' % ts_file)
    except:
        logging.error('delete upyun file fail: %s' % ts_file)
        is_success = False

    try:
        up.delete(cover_file)
        logging.info('delete upyun file: %s' % cover_file)
    except:
        logging.error('delete upyun file fail: %s' % cover_file)
        is_success = False

    return is_success

