# -*- coding: utf-8 -*-

from lib import utils
from control import ctrl
from handler.base import BaseHandler


class ServersHandler(BaseHandler):

    def get(self):
        servers = ctrl.web.get_vpn_servers_ctl()
        self.send_json(dict(servers=servers))

