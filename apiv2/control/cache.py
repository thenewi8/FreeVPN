#!/usr/bin/env python
# -*- coding: utf-8 -*-

import redis

from settings import REDIS_CONF

ktv_redis = redis.StrictRedis(host=REDIS_CONF['host'], port=REDIS_CONF['port'], db=REDIS_CONF['db'])
