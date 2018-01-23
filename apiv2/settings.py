# -*- coding: utf-8 -*-

# redis
REDIS_CONF = {
    'host': '127.0.0.1',
    'port': 6379,
    'db': 0,
}

# mysql
MYSQL_CONFS = [{
        'host': '10.130.38.171',
        'port': 3306,
        'db': 'radius',
        'user': 'radius',
        'password': 'radiuszhouligang153'
    }, {
        'host': '10.130.38.205',
        'port': 3306,
        'db': 'radius',
        'user': 'radius',
        'password': 'radiuszhouligang153'
}]

MYSQL_CONFS = [{
    'db': 'radius',
    'host': 'localhost',
    'user': 'radius',
    'password': 'radiuszhouligang153',
    'port': 3306
}]

PLAN_IDS = {
    'com.ligulfzhou.freevpn.one_year_vpn_plan': 366,
    'com.ligulfzhou.freevpn.half_year_vpn_plan': 183,
    'com.ligulfzhou.freevpn.quarter_vpn_plan': 91,
    'com.ligulfzhou.freevpn.one_month_vpn_plan': 31,
    'com.ligulfzhou.freevpn_mac.one_year_vpn_plan': 366,
    'com.ligulfzhou.freevpn_mac.half_year_vpn_plan': 183,
    'com.ligulfzhou.freevpn_mac.quarter_vpn_plan': 91,
    'com.ligulfzhou.freevpn_mac.one_month_vpn_plan': 31,
}

PLAN_NAME = {
    'com.ligulfzhou.freevpn.one_year_vpn_plan': '12 Months Plan',
    'com.ligulfzhou.freevpn.half_year_vpn_plan': '6 Months Plan',
    'com.ligulfzhou.freevpn.quarter_vpn_plan': '3 Months Plan',
    'com.ligulfzhou.freevpn.one_month_vpn_plan': '1 Month Plan',
    'com.ligulfzhou.freevpn_mac.one_year_vpn_plan': '12 Months Plan',
    'com.ligulfzhou.freevpn_mac.half_year_vpn_plan': '6 Months Plan',
    'com.ligulfzhou.freevpn_mac.quarter_vpn_plan': '3 Months Plan',
    'com.ligulfzhou.freevpn_mac.one_month_vpn_plan': '1 Month Plan',
}

PLAN_SIMUL_ONLINE = {
    'com.ligulfzhou.freevpn.one_year_vpn_plan': '3',
    'com.ligulfzhou.freevpn.half_year_vpn_plan': '2',
    'com.ligulfzhou.freevpn.quarter_vpn_plan': '2',
    'com.ligulfzhou.freevpn.one_month_vpn_plan': '1',
    'com.ligulfzhou.freevpn_mac.one_year_vpn_plan': '3',
    'com.ligulfzhou.freevpn_mac.half_year_vpn_plan': '2',
    'com.ligulfzhou.freevpn_mac.quarter_vpn_plan': '2',
    'com.ligulfzhou.freevpn_mac.one_month_vpn_plan': '1',
}

# error msg
ERR_MSG = {
    100: '参数错误',
    200: '服务正常',
    401: '未登陆',
    40001: '用户已存在',
    40002: 'Your Have Already Checked In',
    403: '权限不足',
    404: '数据未找到',
    500: '接口出了点小问题',
    50001: '支付太频繁, 有猫腻'
}

# try to load debug settings
try:
    from tornado.options import options
    if options.debug:
        exec(compile(open('settings.debug.py')
             .read(), 'settings.debug.py', 'exec'))
except:
    pass

