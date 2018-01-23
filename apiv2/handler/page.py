# -*- coding: utf-8 -*-
import logging
from lib import utils
from control import ctrl
from handler.base import BaseHandler


class IndexHandler(BaseHandler):

    def get(self):
        xsrf = self.xsrf_token
        self.render('index.html', xsrf=xsrf)


class FeedbackHandler(BaseHandler):

    def get(self):
        xsrf = self.xsrf_token
        feedbacks = ctrl.web.get_feedbacks_ctl()
        self.render('feedback.html', xsrf=xsrf, feedbacks=feedbacks)

    def post(self):
        try:
            email = self.get_argument('email')
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=100)

        ctrl.web.add_feedback_ctl(dict(qq=email, feedback=feedback))
        self.send_json()

