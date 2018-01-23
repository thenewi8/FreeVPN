#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json
import logging
import control
import hashlib

from functools import wraps
from sqlalchemy.orm import class_mapper
from urllib.parse import quote, unquote
from tornado.httputil import url_concat

def model2dict(model):
    if not model:
        return {}
    fields = class_mapper(model.__class__).columns.keys()
    return dict((col, getattr(model, col)) for col in fields)

def model_to_dict(func):
    def wrap(*args, **kwargs):
        ret = func(*args, **kwargs)
        return model2dict(ret)
    return wrap

def models_to_list(func):
    def wrap(*args, **kwargs):
        ret = func(*args, **kwargs)
        return [model2dict(r) for r in ret]
    return wrap

def filter_update_data(func):
    def wrap(*args, **kwargs):
        if 'data' in kwargs:
            data = kwargs['data']
            data = dict([(key, value) for key, value in data.items() if value or value == 0])
            kwargs['data'] = data
        return func(*args, **kwargs)
    return wrap

def check_openid(func):
    @wraps(func)
    def wrap(*args, **kw):
        self = args[0]
        openid = self.get_cookie('openid')
        logging.info('openid: %s' % openid)
        if not openid:
            # 去掉一些没用的微信带上来的参数，from=singlemessage, isappinstalled=0/1, 因为state不能长过128
            state = self.request.uri
            if '?' in state:
                path, params = state.split('?', 1)
                param_list = params.split('&')
                param_list = list(filter(lambda x: 'from' not in x and 'isappinstalled' not in x, param_list))
                state = path+'?'+'&'.join(param_list)

            logging.error('request_uri: %s' % state)
            url = WX_USERINFO_GRANT_URL.format(
                appid=WX_CONF['appid'],
                redirect_uri=quote(WX_REDIRECT_URL),
                state=quote(state)
            )
            # 跳转去授权
            return self.redirect(url)
        return func(*args, **kw)
    return wrap

def check_alipay_user_id(func):

    def wrap(*args, **kw):
        self = args[0]
        alipay_user_id = self.get_cookie('openid')
        logging.info('alipay_user_id: %s' % alipay_user_id)
        if not alipay_user_id:
            url = ALI_GRANT_URL.format(
                appid=ALICONF['APPID'],
                redirect_uri=quote(ALICONF['AUTH_URL']),
                state=self.request.path
            )
            # 跳转去授权
            logging.info(url)
            return self.redirect(url)
        return func(*args, **kw)
    return wrap

def forbid_frequent_api_call(params={'cookie_keys': [], 'seconds': 1}):
    '''主要是限制前端的点击，所以加了cookie_keys'''
    def decorator(func):
        def wrap(*args, **kw):
            self = args[0]

            arguments = self.request.arguments
            ordered_keys = sorted(arguments.keys())
            ordered_values = [''.join(list(map(bytes.decode, arguments.get(key, '')))) for key in ordered_keys]
            arg_key = ''.join(ordered_values)

            cookie_key = ''
            cookie_keys = params.get('cookie_keys', [])
            if cookie_keys:
                ordered_cookie_keys = sorted(cookie_keys)
                ordered_cookie_values = [str(self.get_cookie(key, '')) for key in ordered_cookie_keys]
                cookie_key = ''.join(ordered_cookie_values)

            key = arg_key + cookie_key
            logging.error('forbid_key: %s' % key)
            if control.ctrl.rs.exists(key):
                return  # self.send_json(dict(errcode=50001, errmsg='为了避免前端的单次点击，请求多次'))
            control.ctrl.rs.set(key, 1, params.get('seconds', 1))
            return func(*args, **kw)
        return wrap
    return decorator

def save_args(func):
    def wrap(*args, **kw):
        ctrl = control.ctrl
        self = args[0]
        self.full_url = self.request.full_url()
        if self.has_argument('args'):
            # restore args
            key = self.get_argument('args')
            self.request.arguments.update(json.loads(unquote(ctrl.rs.get(key).decode())))
            # self.request.uri=unquote(ctrl.rs.get('uri_%s'%key).decode())
        else:
            # save args
            key = 'SSAT' + hashlib.md5(self.request.uri.encode()).hexdigest()
            ctrl.rs.set(key, quote(json.dumps(self.request.arguments, default=self.json_format)), A_DAY)
            ctrl.rs.set('uri_%s'%key, quote(self.request.uri), A_DAY)
            self.request.uri = url_concat(self.request.path, dict(args=key))
            self.request.arguments.update(dict(args=[key]))
        return func(*args, **kw)
    return wrap
