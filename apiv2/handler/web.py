#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import datetime

from lib import utils
from handler.base import BaseHandler
from control import ctrl
from lib.decorator import check_openid
from tornado.gen import coroutine
from urllib.parse import quote, unquote


class VerifyHandler(BaseHandler):

    def _get_allowd_ktvids(self, coupon_id):
        ktvs = ctrl.web.get_ktvs_of_coupon_ctl(coupon_id)
        ktv_ids = [ktv['store_id'] for ktv in ktvs]
        return ktv_ids

    def check_code(self, ktv_id, code, fee):
        csid = ctrl.web.get_csid_of_coupon_code_ctl(code)

        if not csid:
            logging.info('使用了非法的code: %s, 原因是code过期或非法' % code)
            raise utils.APIError(errcode=5000, errmsg='code已过期或没有该code')

        csid = int(csid.decode())
        return self.check_coupon_send_id(csid, fee, ktv_id)

    def check_coupon_send_id(self, csid, fee, ktv_id):
        coupon_send = ctrl.web.get_coupon_send_ctl(csid, coupon_required=1)
        if not coupon_send:
            raise utils.APIError(errcode=11001, errmsg='不存在该优惠券')

        coupon = coupon_send.get('coupon', {})
        if coupon['charge'] > fee:
            logging.info('csid: %s,验证不通过, 对应coupon_send的id为: %s, 原因: 不符合满减要求, 金额%.02f元<满减金额%.02f元' % (
                csid, coupon_send['id'], fee / 100, coupon['charge'] / 100))
            raise utils.APIError(errcode=11001, errmsg='不符合满减要求, 金额%.02f元<满减金额%.02f元' % (fee / 100, coupon['charge'] / 100))

        if not coupon['stime'] < datetime.datetime.now() < coupon['etime']:
            logging.info('csid: %s,验证不通过, 对应coupon_send的id为: %s, 原因: 优惠券不满足时效' % (csid, coupon_send['id']))
            raise utils.APIError(errcode=11001, errmsg='优惠券不满足时效')

        allowd_ktv_ids = self._get_allowd_ktvids(coupon['id'])
        if 0 not in allowd_ktv_ids and int(ktv_id) not in allowd_ktv_ids:
            logging.info('csid: %s,验证不通过, 对应coupon_send的id为: %s, 原因: 该优惠券在这个ktv无法使用' % (csid, coupon_send['id']))
            raise utils.APIError(errcode=11001, errmsg='该优惠券在这个ktv无法使用')

        if coupon_send['status'] != 1:
            logging.info('csid: %s,验证不通过, 对应coupon_send的id为: %s, 原因: 优惠券已经使用' % (csid, coupon_send['id']))
            raise utils.APIError(errcode=11001, errmsg='优惠券已经使用')

        logging.info('csid: %s,验证通过, 对应coupon_send的id为: %s' % (csid, coupon_send['id']))
        data = dict(coupon_value=coupon['discount'], coupon_send_id=csid)
        return self.send_json(data=data)

    def post(self, ktv_id):
        try:
            code = self.get_argument('code', '')
            coupon_send_id = int(self.get_argument('coupon_send_id', 0))
            fee = float(self.get_argument('total_fee'))
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=10001)

        if (not code and not coupon_send_id) or (code and coupon_send_id):
            raise utils.APIError(errcode=10001, errmsg='至少需要一个code或者coupon_send_id')

        if code:
            self.check_code(ktv_id, code, fee)
        else:
            self.check_coupon_send_id(coupon_send_id, fee, ktv_id)


class MyCouponSendsPageHandler(BaseHandler):

    @coroutine
    @check_openid
    def get(self):
        '''wx_user: 该用户
        not_used_cs: 未使用的优惠券, 优惠券都已create_time倒序
        '''
        openid = self.get_cookie('openid')
        wx_user = yield utils.async_common_api('/wx/user/info', dict(openid=openid))

        used_cs = []
        not_used_cs = ctrl.web.get_user_coupon_send_list_ctl(openid)
        not_used_cs = sorted(not_used_cs, key=lambda x: x['create_time'], reverse=True)

        self.render('mycoupon_sends.tpl', wx_user=wx_user, used_cs=used_cs, not_used_cs=not_used_cs, openid=openid)


class CouponSendPageHandler(BaseHandler):

    def get_tip(self, openid, coupon_send):
        coupon_send_id = coupon_send['id']
        if coupon_send['shared_id'] != 0:  # 分享得到的红包不能重复分享
            return 6

        if coupon_send['openid'] == openid:   # 若该优惠券是这个用户的,就不用抢优惠券
            return 5

        cs_fetched = ctrl.web.get_coupon_send_openid_csid_ctl(openid, coupon_send_id)
        if cs_fetched:
            return 2

        count = ctrl.web.get_coupon_share_count_ctl(coupon_send_id)
        # '已抢完'
        if count >= 5:
            return 4

        ctrl.web.add_coupon_send_from_share_ctl(openid, coupon_send_id)
        # '恭喜你抢到优惠券'
        return 3

    @coroutine
    @check_openid
    def get(self, coupon_send_id):
        '''用户从自己的优惠券列表也点击某一个优惠券进入的优惠券详情页(可抢优惠券)
        首先查看该用户是否拥有该优惠券的
        '''
        openid = self.get_cookie('openid')
        try:
            coupon_send_id = utils.decode_id(coupon_send_id)
        except:
            return self.render_empty()

        wx_user = yield utils.async_common_api('/wx/user/info', dict(openid=openid))
        coupon_send_id = int(coupon_send_id)
        coupon_send = ctrl.web.get_coupon_send_ctl(coupon_send_id, user_required=1, coupon_required=1)
        if not coupon_send:
            raise utils.APIError(errcode=5001, errmsg='无该优惠券')

        coupon = coupon_send.get('coupon', {})
        # 分享该优惠券的人
        share_user_openid = coupon_send['openid']
        if share_user_openid == openid:
            share_user = wx_user
        else:
            share_user = coupon_send.get('wx_user', {})

        tip = self.get_tip(openid, coupon_send)
        coupon_share_list = ctrl.web.get_coupon_send_share_list_ctl(coupon_send_id)

        # 如果是用户原先抢到/现在抢到的, 都设置该页面的coupon_send设为他抢到的coupon_send(以便他能够直接使用)
        if tip in (2, 3):
            for item in coupon_share_list:
                if item['openid'] == openid:
                    coupon_send = item
                    break

        config = yield utils.async_common_api('/wx/share/config', dict(url=self.request.full_url()))
        self.render('coupon_send.tpl', openid=openid, coupon_share_list=coupon_share_list, coupon=coupon,
                    coupon_send=coupon_send, tip=tip, wx_user=wx_user, share_user=share_user, config=config)


class CouponPageHandler(BaseHandler):

    @coroutine
    @check_openid
    def get(self, coupon_id):
        '''给用户推的优惠券, 用户点击之后, 要是没有领取则领取, 领取过则不再领取, 最后跳转到优惠券详情页'''
        openid = self.get_cookie('openid')
        try:
            coupon_id = utils.decode_id(coupon_id)
        except:
            return self.render_empty()

        coupon = ctrl.web.get_coupon_ctl(coupon_id)
        if not coupon:
            logging.error('openid为%s的用户, 领取优惠券不合法, 没有coupon_id为%s的优惠券' % (openid,coupon_id))
            return self.render('coupon_send.tpl', openid='', coupon_share_list=[], coupon={}, coupon_send={}, tip=6,
                               wx_user={}, share_user={}, config={})

        fetch_count = coupon.get('fetch_count', -1)
        logging.error('fetch_count: '+str(fetch_count))
        if fetch_count <= 0:
            return self.render('coupon_send.tpl', openid='', coupon_share_list=[], coupon={}, coupon_send={}, tip=6,
                               wx_user={}, share_user={}, config={})

        coupon_send_id = ctrl.web.check_whether_user_get_this_coupon_ctl(openid, coupon_id)
        if not coupon_send_id:
            coupon_send = ctrl.web.add_user_coupon_send_from_push_ctl(openid, coupon_id)
            fetch_count -= 1
            ctrl.web.update_coupon_ctl(coupon_id, dict(fetch_count=fetch_count))
            coupon_send_id = str(coupon_send['id']).encode()

        return self.redirect('/coupon/send/%s' % utils.encode_id(coupon_send_id))


class CouponUseHandler(AsyncHttpHandler):

    def post(self):
        try:
            coupon_send_id = int(self.get_argument('coupon_send_id'))
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=10001)

        coupon_send = ctrl.web.get_coupon_send_ctl(coupon_send_id, coupon_required=1)
        if not coupon_send:
            raise utils.APIError(errcode=11002, errmsg='无该优惠券')

        if coupon_send['status'] not in (0, 1):
            raise utils.APIError(errcode=11002, errmsg='优惠券已经使用')

        coupon = coupon_send['coupon']
        if not coupon['stime'] < datetime.datetime.now() < coupon['etime']:
            raise utils.APIError(errcode=11002, errmsg='优惠券不在时效内')

        openid = self.get_cookie('openid')
        if coupon_send['openid'] != openid:
            raise utils.APIError(errcode=11002, errmsg='非法的优惠劵')

        code = ctrl.web.get_coupon_code_ctl(coupon_send_id, openid)
        if code:
            logging.info('使用了优惠券%s, 对应code: %s' % (coupon_send_id, code))
            return self.send_json(data={'code': code})
        raise utils.APIError(errcode=11002, errmsg='传递的优惠券有误')


class WxCallBackHandler(BaseHandler):

    def add_card_member_info(self, openid, zktv_id):
        card_member = ctrl.web.get_card_member(openid, zktv_id)
        if not card_member:
            ctrl.web.add_card_member(openid=openid, phone_num='', zktv_id=zktv_id)

    @coroutine
    def get(self):
        state = self.get_argument('state', '/coupon/my')
        try:
            code = self.get_argument('code')
            # 有code, 是已经授权跳转回来的, 则获取openid
            wx_user = yield utils.async_common_api('/wx/web/user/info', dict(code=code))
            self.set_cookie('openid', wx_user['openid'])

            if state and state.startswith('/card/apply_or_bind'):
                self.add_card_member_info(wx_user['openid'], int(state.split('/')[-1]))

            return self.redirect(unquote(state))
        except Exception as e:
            pass

        url = WX_USERINFO_GRANT_URL.format(
            appid=WX_CONF['appid'],
            redirect_uri=quote(WX_REDIRECT_URL),
            state=state
        )
        # 跳转去授权
        return self.redirect(url)


class AfterPayHandler(AsyncHttpHandler):

    def post(self):
        try:
            coupon_send_id = int(self.get_argument('coupon_send_id'))
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=10001)

        coupon_send = ctrl.web.get_coupon_send_ctl(coupon_send_id)
        if not coupon_send:
            return

        ctrl.web.update_coupon_send_ctl(coupon_send_id, data={'status': 2})
        ctrl.rs.lrem(ctrl.web.get_user_coupon_list_key_ctl(coupon_send['openid']), 0, coupon_send_id)
        self.send_json()


class PushCouponHandler(AsyncHttpHandler):

    @coroutine
    def post(self):
        try:
            ktv_id = int(self.get_argument('ktv_id'))
            openid = self.get_argument('openid')
            fee = int(self.get_argument('fee'))
            order_id = self.get_argument('order_id')
        except Exception as e:
            logging.error(e)
            raise utils.APIError(errcode=10001)

        coupons = ctrl.web.get_coupons_spt_pay_push_of_ktv(ktv_id)  # 还需完善
        if not coupons:
            logging.info('用户所消费的ktv(ktv_id: %s),并不支持发优惠券. 其他参数: openid: %s, fee: %s, order_id: %s' % (
                ktv_id, openid, fee, order_id))
            return

        coupon_id = coupons[0].get('id')
        coupon_send = ctrl.web.add_coupon_send_ctl(
            dict(openid=openid, shared_id=0, status=0, coupon_id=coupon_id, type=1, order_id=order_id))
        logging.info('用户在ktv(ktv_id: %s)支付后，给用户添加一个coupon_send_id为%s的优惠券, 其他参数: openid: %s, fee: %s, order_id: %s' % (
            ktv_id, coupon_send.get('id', 0), openid, fee, order_id))

        yield utils.async_common_api('/wx/custom/send',
                dict(openid=openid, title='恭喜，骚年你的RP爆棚!', description='房费、酒水全场通用',
                    url='http://wx.handle.ktvdaren.com/coupon/send/%s'%utils.encode_id(str(coupon_send['id']).encode()), picurl=WX_COUPON_PUSH_PICURL))


class WxShareConfigHandler(BaseHandler):

    @coroutine
    def get(self):
        url=self.get_argument('url', '')
        if not url:
            raise utils.APIError(errcode=10000, errmsg='参数错误')

        config = yield utils.async_common_api('/wx/share/config', dict(url=url))
        self.set_header('Access-Control-Allow-Origin', '*')
        self.send_json(config)

