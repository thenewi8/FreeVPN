# -*- coding: utf-8 -*-

import datetime
import logging
import hashlib

from lib import utils
from urllib.parse import unquote
from settings import PLAN_IDS, PLAN_SIMUL_ONLINE, PLAN_NAME


class WebCtrl(object):

    def __init__(self, ctrl):
        self.ctrl = ctrl
        self.api = ctrl.pdb.api

    def __getattr__(self, name):
        return getattr(self.api, name)

    def get_vpn_servers_key(self):
        return 'vpn_servers'

    def get_feedbacks_key(self):
        return 'freevpn_feedbacks'
    def get_user_checkin_key(self, username):
        return '%s_checkin' % username

    def get_user_key(self, username):
        return '%s_list' % username

    def get_user_info_key(self, username):
        return '%s_user_info' % username

    def get_user_orders_key(self, username):
        return 'orders_of_%s' % username

    def get_payed_users_set_key(self):
        return 'pay_users'

    def get_user_sim_online_timegap_key(self, username):
        return '%s_sim_online' % username

    def get_user_last_order_key(self, username):
        return '%s_last_order' % username

    def get_vpn_servers(self):
        key = self.get_vpn_servers_key_ctl()
        vpn_servers = self.ctrl.rs.lrange(key, 0, -1)
        if vpn_servers:
            return [eval(vpn_server) for vpn_server in vpn_servers]
        vpn_servers = self.api.get_vpn_servers()
        vpn_servers.sort(key=lambda x: x.get('priority', 0))
        if vpn_servers:
            [server.update({'country_cn': unquote(server['country_cn']), 'city_cn': unquote(server['city_cn']) }) for server in vpn_servers]
            self.ctrl.rs.rpush(key, *vpn_servers)
        return vpn_servers

    def _get_user(self, username):
        '''获得这个用户的三条用户数据，只提供内部使用（_get_user_info），用于组装用户数据'''
        user_list_key = self.get_user_key_ctl(username)
        users = self.ctrl.rs.lrange(user_list_key, 0, -1)
        if users:
            users = [eval(user) for user in users]
        else:
            users = self.api.get_user(username)
            if users:
                self.ctrl.rs.rpush(user_list_key, *users)
            else:
                return {}

        timelimit, email, password, sim_online = '', 0, '', 1
        for user in users:
            if user['attribute'] == 'Deadline-Timestamp':
                timelimit, email = int(user['value']), user['email']
            elif user['attribute'] == 'Cleartext-Password':
                password = user['value']
            elif user['attribute'] == 'Simultaneous-Online':
                sim_online = int(user['value'])
        dt_str = datetime.datetime.fromtimestamp(timelimit).strftime('%Y-%m-%d %X')
        user = dict(timelimit=dt_str, email=email, sim_online=sim_online, password=password)
        self.ctrl.rs.set(self.get_user_info_key_ctl(username), user)
        return user

    def _get_user_info(self, username):
        '''获取用户信息'''
        user_info_key = self.get_user_info_key_ctl(username)
        user_info = self.ctrl.rs.get(user_info_key)
        if user_info:
            return eval(user_info)
        return self._get_user_ctl(username)

    def get_user_info(self, username):
        '''返回用户的email， 过期时间， 同时登录个数, 密码，用户名'''
        user_info_key = self.get_user_info_key_ctl(username)
        user_info = self.ctrl.rs.get(user_info_key)
        if user_info:
            return eval(user_info)
        return self._get_user_ctl(username)
        #user = self._get_user_ctl(username)
        #return user

    def update_user(self, username, ts=0, email='', password=''):
        '''更新用户信息，过期时间／email, 分别调用mysql层更新时间和email的方法
        不支持同时更新'''
        self.ctrl.rs.delete(self.get_user_key_ctl(username))
        if ts:
            self.api.update_user_deadline_timestamp(username, ts)
        if email:
            self.api.update_user_email(username, email)
        if password:
            self.api.update_user_password(username, password)

    def get_user_orders(self, username):
        '''获取用户的所有订单，并会更新是否是已支付的用户'''
        key = self.get_user_orders_key_ctl(username)
        orders = self.ctrl.rs.lrange(key, 0, -1)
        if orders:
            return [eval(order) for order in orders]

        payed_user_key = self.get_payed_users_set_key_ctl()
        #if not self.ctrl.rs.sismember(payed_user_key, username):
        #    return []

        orders = self.api.get_user_planorders(username)
        if not orders:
            return []
        self.ctrl.rs.sadd(payed_user_key, username)
        [order.update({'plan': PLAN_NAME.get(order.get('plan_identifier', ''))}) for order in orders]
        self.ctrl.rs.rpush(key, *orders)
        return orders

    def add_user_planorder(self, username, plan_identifier):
        '''添加用户订单，并直接rpush到用户订单列表的redis里'''
        # 添加订单
        planorder = self.api.add_user_planorder(username, plan_identifier)
        key = self.get_user_orders_key_ctl(username)
        self.ctrl.rs.rpush(key, planorder)

        # 更新用户信息, 并更新用户信息的redis数据
        user = self.get_user_info_ctl(username)
        ts_dt = datetime.datetime.strptime(user['timelimit'], '%Y-%m-%d %X') + datetime.timedelta(days=PLAN_SIMUL_ONLINE[plan_identifier])
        ts, ts_str  = int(ts_dt.timestamp()), ts_dt.strftime('%Y-%m-%d %X')
        self.update_user(username, ts=ts, email='', password='')
        user.update({'timelimit': ts_str})
        self.ctrl.rs.delete(self.get_user_key_ctl(username))
        self.ctrl.rs.set(self.get_user_info_key_ctl(username), user)
        self.ctrl.rs.sadd(self.get_payed_users_set_key_ctl(), username)

        # TODO
        #user_sim_online_key = self.get_user_sim_online_timegap_key_ctl(username)
        #v = self.ctrl.rs.get(user_sim_online_key)
        #if not v:
        #    pass
        #user_sim_online = eval(v)
        #if user_sim_online:
        #    user_sim_online = [eval(item) for item in user_sim_online]

    def add_user(self, username, ts):
        self.api.add_user(username, ts)
        timelimit = (datetime.datetime.now() + datetime.timedelta(days=7)).strftime('%Y-%m-%d %X')
        user_info = dict(username=username, password=username, sim_online=1, timelimit=timelimit, email='')
        self.ctrl.rs.set(self.get_user_info_key_ctl(username), user_info)
        return user_info

    def check_user_order_timestamp(self, username):
        key = self.get_user_last_order_key_ctl(username)
        if self.ctrl.rs.exists(key):
            return 0
        return 1

    def after_pay(self, username):
        key = self.get_user_last_order_key_ctl(username)
        self.ctrl.rs.set(key, 1)

    def get_feedbacks(self):
        key = self.get_feedbacks_key_ctl()
        feedbacks = self.ctrl.rs.get(key)
        if feedbacks:
            return eval(feedbacks)
        feedbacks = self.api.get_feedbacks()
        if feedbacks:
            self.ctrl.rs.set(key, feedbacks)
        return feedbacks

