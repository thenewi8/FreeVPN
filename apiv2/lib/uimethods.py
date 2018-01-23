#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json
import logging

from decimal import Decimal
from datetime import datetime, date


def format_datetime(handler, dt, formatter='%Y年%m月%d日'):
    if not isinstance(dt, datetime):
        return ''
    return dt.strftime(formatter)

def is_coupon_overdue(handler, coupon):
    return not datetime.now() < coupon['etime']

def supportd_ktvs(handler, ktv_name):
    if ktv_name == '任意店可用':
        return 0
    if len(ktv_name.split(',')) > 1:
        return 0
    return 1
