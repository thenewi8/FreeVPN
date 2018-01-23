#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import logging
import base64
import time
from tornado import httpclient, web
from tornado.gen import coroutine


httpclient.AsyncHTTPClient.configure('tornado.simple_httpclient.SimpleAsyncHTTPClient', max_clients=300)


class APIError(web.HTTPError):
    '''自定义API异常'''
    def __init__(self, status_code=200, *args, **kwargs):
        super(APIError, self).__init__(status_code, *args, **kwargs)
        self.kwargs = kwargs


def dict_filter(target, attr=()):
    result = dict()
    for p in attr:
        if type(p) is dict:
            key = list(p.keys())[0]
            value = list(p.values())[0]
            result[value] = target[key] if target[key] else ''
        else:
            result[p] = target[p]
    return result


def start_stop(has_pn, page, page_size):
    if has_pn:
        start = (page - 1) * page_size
        stop = start + (page_size - 1)
    else:
        start = 0
        stop = -1
    return start, stop


def is_mobile(source):
    pattern = re.compile(r'\d{11}')
    match = pattern.match(source.strip())
    return True if match else False


def is_email(source):
    pattern = re.compile(r'^(\w)+(\.\w+)*@(\w)+((\.\w+)+)$')
    match = pattern.match(source.strip())
    return True if match else False


def is_qq(source):
    return source.strip().isnumeric()


def get_async_client():
    http_client = httpclient.AsyncHTTPClient()
    return http_client


def http_request(url, method='GET', **wargs):
    return httpclient.HTTPRequest(url=url, method=method, connect_timeout=10, request_timeout=10, **wargs)


@coroutine
def fetch(http_client, request):
    r = yield http_client.fetch(request)
    logging.info('\treq_url=%s\trequest_time=%s' % (r.effective_url, r.request_time))
    logging.info('\tbody=%s' % (r.body))
    return r


def encode_id(id_str):
    return base64.urlsafe_b64encode(id_str).decode()


def decode_id(decode_str):
    return base64.urlsafe_b64decode(decode_str).decode()


def total_seconds_to_midnight():
    now = time.localtime()
    drawn = time.mktime(now[:3] + (0, 0, 0) + now[6:])
    return int(drawn + 86400 - time.time())
