# -*- coding: utf-8 -*-

import logging
from lib import utils
from control import ctrl
from settings import PLAN_IDS, PLAN_NAME, PLAN_SIMUL_ONLINE
from handler.base import BaseHandler


class OrderHandler(BaseHandler):

    def get(self):
        try:
            username = self.get_argument('username')
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=100)

        try:
            orders = ctrl.web.get_user_orders_ctl(username)
            self.send_json(dict(orders=orders))
        except Exception as e:
            logging.error(e)
            raise utils.APIError(500)


class AfterPayHandler(BaseHandler):

    def post(self):
        '''支付只完成之后的调用'''
        try:
            username = self.get_argument('username')
            plan_identifier = self.get_argument('plan_identifier')
            assert plan_identifier in PLAN_IDS
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=100)

        allow = ctrl.web.check_user_order_timestamp_ctl(username)
        if not allow:
            return self.send_json(errcode=403, errmsg='YOU ARE CHEATTING')

        user = ctrl.web.get_user_info_ctl(username)
        fromtime = user.get('timelimit')
        ctrl.web.add_user_planorder(username, plan_identifier)
        user = ctrl.web.get_user_info_ctl(username)
        user.update({'fromtime': fromtime})

        ctrl.web.after_pay_ctl(username)
        self.send_json(user)


class BeforePayHandler(BaseHandler):

    def post(self):
        '''不让重复购买'''
        try:
            username = self.get_argument('username')
            plan_identifier = self.get_argument('plan_identifier')
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=100)

        allow = ctrl.web.check_user_order_timestamp_ctl(username)
        self.send_json(dict(allow=allow))
