#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import json
import logging
import traceback
import datetime

from decimal import Decimal
from tornado import web
from control import ctrl
from lib import utils
from settings import ERR_MSG
from tornado.options import options
# from raven.contrib.tornado import SentryMixin


# class BaseHandler(web.RequestHandler, SentryMixin):
class BaseHandler(web.RequestHandler):

    def initialize(self):
        ctrl.pdb.close()

    def on_finish(self):
        ctrl.pdb.close()

    def json_format(self, obj):
        if isinstance(obj, datetime.datetime):
            return obj.strftime('%Y-%m-%d %H:%M:%S')
        if isinstance(obj, Decimal):
            return ('%.2f' % obj)
        if isinstance(obj, bytes):
            return obj.decode()

    def has_argument(self, name):
        return name in self.request.arguments

    def send_json(self, data={}, errcode=200, errmsg='', status_code=200):
        res = {
            'errcode': errcode,
            'errmsg': errmsg if errmsg else ERR_MSG[errcode]
        }
        res.update(data)

        if errcode > 200:
            logging.error(res)

        json_str = json.dumps(res, default=self.json_format)
        if options.debug:
            logging.info('path: %s, arguments: %s, response: %s' % (self.request.path, self.request.arguments, json_str))

        jsonp = self.get_argument('jsonp', '')
        if jsonp:
            jsonp = re.sub(r'[^\w\.]', '', jsonp)
            self.set_header('Content-Type', 'text/javascript; charet=UTF-8')
            json_str = '%s(%s)' % (jsonp, json_str)
        else:
            self.set_header('Content-Type', 'application/json')

        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Headers", "x-requested-with")
        self.set_header('Access-Control-Allow-Methods', 'GET')

        self.set_status(status_code)
        self.write(json_str)
        self.finish()

    def render2(self, *args, **kwargs):
        if self.get_argument('json', ''):
            kwargs.pop('config', '')
            self.send_json(kwargs)
            return

        self.render(*args, **kwargs)

    def _is_payed_user(self, username):
        if ctrl.rs.sismember('pay_users', username):
            return 1
        return 0

    def render_empty(self):
        self.render('error.html')

    def write_error(self, status_code=200, **kwargs):
        if 'exc_info' in kwargs:
            err_object = kwargs['exc_info'][1]
            traceback.format_exception(*kwargs['exc_info'])

            if isinstance(err_object, utils.APIError):
                err_info = err_object.kwargs
                self.send_json(**err_info)
                return

        self.render_empty()
        # self.captureException(**kwargs)

    def render(self, template_name, **kwargs):
        if options.debug:
            logging.error('render args: %s' % kwargs)
        return super(BaseHandler, self).render(template_name, **kwargs)
