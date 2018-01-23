#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import uuid
import base64

from tornado import web
from tornado.options import options
from tornado.httpserver import HTTPServer
# from raven.contrib.tornado import AsyncSentryClient
from lib import uimethods

STATIC_PATH = os.path.join(sys.path[0], 'static')
TPL_PATH = os.path.join(sys.path[0], 'tpl')

URLS = [
    (r'freevpn\.ligulfzhou\.com',
        [(r'/', 'handler.page.IndexHandler'),
        (r'/feedback', 'handler.page.FeedbackHandler'),
        (r'/api/auth/init', 'handler.user.InitHandler'),
        (r'/api/auth/login', 'handler.user.LoginHandler'),
        (r'/api/auth/user', 'handler.user.UserHandler'),
        (r'/api/bind/email', 'handler.user.BindEmailHandler'),
        (r'/api/user/order', 'handler.order.OrderHandler'),
        (r'/api/afterpay', 'handler.order.AfterPayHandler'),
        (r'/api/beforepay', 'handler.order.BeforePayHandler'),
        # (r'/api/checkin', 'handlers.user.CheckInHandler'),
        # (r'/api/rate', 'handlers.user.RateHandler'),
        # (r'/feedback', FeedbackPageHandler),
        # (r'/api/feedback', ''),
        (r'/api/server', 'handler.server.ServersHandler')]
    )
]


class Application(web.Application):

    def __init__(self):
        settings = {
            'xsrf_cookies': False,
            'compress_response': True,
            'debug': options.debug,
            'ui_methods': uimethods,
            'static_path': STATIC_PATH,
            'template_path': TPL_PATH,
            'cookie_secret': base64.b64encode(uuid.uuid3(uuid.NAMESPACE_DNS, 'myktv').bytes),
            'sentry_url': ''# 'https://f008ef064b64423aa766039bb54a8aa6:171c226ecc9447d5b38125de569cefb5@sentry.ktvsky.com/5' if not options.debug else ''
        }
        web.Application.__init__(self, **settings)
        for spec in URLS:
            host = spec[0] if not options.debug else '.*$'
            handlers = spec[1]
            self.add_handlers(host, handlers)


def run():
    application = Application()
    # application.sentry_client = AsyncSentryClient(application.settings['sentry_url'])
    http_server = HTTPServer(application, xheaders=True)
    http_server.listen(options.port)
    print('Running on port %d' % options.port)

