# -*- coding: utf-8 -*-
import logging
import datetime

from control import ctrl
from lib import utils
from handler.base import BaseHandler


class InitHandler(BaseHandler):

    def get(self):
        self.write(dict(token=self.xsrf_token.decode()))


class LoginHandler(BaseHandler):

    def post(self):
        try:
            username = self.get_argument('username')
            password = self.get_argument('password')
        except Exception as e:
            logging.error(e)
            raise utils.APIError(100)

        user = ctrl.web.get_user_info_ctl(username)
        if password != user.get('password', ''):
            raise utils.APIError(errcode=401)

        is_payed_user = self._is_payed_user(username)
        user.update({'is_payed_user': is_payed_user})
        self.send_json(user)

    def put(self):
        try:
            username = self.get_argument('username')
            password = self.get_argument('password')
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=100)

        user = ctrl.web.get_user_info_ctl(username)
        if not user:
            raise utils.APIError(errcode=404)
        ctrl.web.update_user_ctl(username, ts=0, email='', password=password)
        user = ctrl.web.get_user_info_ctl(username)
        self.send_json(user)


class UserHandler(BaseHandler):

    def post(self):
        '''进入app后就会掉的接口， username是设备相关的，如果没有账号则创建，返回账号信息
        '''
        try:
            platform = self.get_argument('platform', 'iOS')
            username = self.get_argument('username')
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=100)

        user = ctrl.web.get_user_info_ctl(username)
        if user:
            return self.send_json(user)

        dt_7days_after = datetime.datetime.now() + datetime.timedelta(days=7)
        ts_7days_after = int(dt_7days_after.timestamp())
        user = ctrl.web.add_user_ctl(username, ts_7days_after)
        logging.info(user)
        is_payed_user = self._is_payed_user(username)
        user.update({'is_payed_user': is_payed_user})
        self.send_json(user)

    def get(self):
        '''获取用户信息： email， timelimit, password, sim_online'''
        try:
            username = self.get_argument('username')
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=100)

        user_info = ctrl.web.get_user_info_ctl(username)
        self.send_json(user_info)


class BindEmailHandler(BaseHandler):

    def post(self):
        try:
            username = self.get_argument('username')
            email = self.get_argument('email')
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=100)

        ctrl.web.update_user_ctl(username, ts=0, email=email, password='')
        user = ctrl.web.get_user_info_ctl(username)
        self.send_json(user)

