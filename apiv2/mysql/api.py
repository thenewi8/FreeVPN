# -*- coding: utf-8 -*-

import logging
import datetime

from sqlalchemy import Column, text
from sqlalchemy.sql.expression import func, desc
from sqlalchemy.dialects.mysql import INTEGER, VARCHAR, ENUM, TINYINT, DATETIME, TIMESTAMP

from lib import utils
from settings import MYSQL_CONFS
from mysql.base import NotNullColumn, Base
from lib.decorator import model_to_dict, models_to_list, filter_update_data

class PlanOrder(Base):
    __tablename__ = 'plan_order'

    id = Column(INTEGER(11), primary_key=True)
    username = NotNullColumn(VARCHAR(64), default='')
    plan_identifier = NotNullColumn(VARCHAR(64), default='')
    create_time = NotNullColumn(DATETIME)


class RadCheck(Base):
    __tablename__ = 'radcheck'

    id = Column(INTEGER(11), primary_key=True)
    username = NotNullColumn(VARCHAR(64), default='')
    attribute = NotNullColumn(VARCHAR(64), default='')
    op = NotNullColumn(VARCHAR(2), default='==')
    value = NotNullColumn(VARCHAR(253), default='')
    email = NotNullColumn(VARCHAR(64), default='')
    create_time = NotNullColumn(DATETIME)


class Feedback(Base):
    __tablename__ = 'feedback'

    id = Column(INTEGER(11), primary_key=True)
    name = NotNullColumn(VARCHAR(64), default='')
    qq = NotNullColumn(VARCHAR(64), default='')
    feedback = NotNullColumn(VARCHAR(256), default='')
    create_time = NotNullColumn(DATETIME)


class Server(Base):
    __tablename__ = 'server'

    id  = Column(INTEGER(11), primary_key=True)
    ip = NotNullColumn(VARCHAR(32))
    code = NotNullColumn(VARCHAR(2))
    country = NotNullColumn(VARCHAR(32))
    country_cn = NotNullColumn(VARCHAR(64))
    city = NotNullColumn(VARCHAR(32))
    city_cn = NotNullColumn(VARCHAR(64))
    remote_id = NotNullColumn(VARCHAR(32))
    priority = NotNullColumn(TINYINT(2), default=1)
    create_time = NotNullColumn(DATETIME)


class RadAcct(Base):
    __tablename__ = 'radacct'

    radacctid = Column(INTEGER(21), primary_key=True)
    acctsessionid = NotNullColumn(VARCHAR(64), default='')
    acctuniqueid = NotNullColumn(VARCHAR(32), default='')
    username = NotNullColumn(VARCHAR(64), default='')
    groupname = NotNullColumn(VARCHAR(64), default='')
    realm = NotNullColumn(VARCHAR(64), default='')
    nasipaddress = NotNullColumn(VARCHAR(15), default='')
    nasportid = NotNullColumn(VARCHAR(15), default=None)
    nasporttype = NotNullColumn(VARCHAR(32), default=None)
    acctstarttime = NotNullColumn(DATETIME, default=None)
    acctstoptime = NotNullColumn(DATETIME, default=None)
    acctsessiontime = NotNullColumn(INTEGER(12), default=None)
    acctauthentic = NotNullColumn(VARCHAR(32), default=None)
    connectinfo_start = NotNullColumn(VARCHAR(50), default=None)
    connectinfo_stop = NotNullColumn(VARCHAR(50), default=None)
    acctinputoctets = NotNullColumn(INTEGER(20), default=None)
    acctoutputoctets = NotNullColumn(INTEGER(20), default=None)
    calledstationid = NotNullColumn(VARCHAR(50), default='')
    callingstationid =  NotNullColumn(VARCHAR(50), default='')
    acctterminatecause = NotNullColumn(VARCHAR(32), default='')
    servicetype = NotNullColumn(VARCHAR(32), default=None)
    framedprotocol = NotNullColumn(VARCHAR(32), default=None)
    framedipaddress = NotNullColumn(VARCHAR(15), default='')
    acctstartdelay = NotNullColumn(INTEGER(12), default=None)
    acctstopdelay = NotNullColumn(INTEGER(12), default=None)
    xascendsessionsvrkey = NotNullColumn(VARCHAR(10), default=None)


class APIModel(object):

    def __init__(self, pdb):
        self.pdb = pdb
        self.db = pdb.get_session()

    @models_to_list
    def get_user(self, username):
        return self.db.query(RadCheck).filter_by(username=username).all()

    def add_user(self, username, ts):
        user1 = RadCheck(username=username, attribute='Cleartext-Password', op=':=', value=username, email='')
        user2 = RadCheck(username=username, attribute='Deadline-Timestamp', op=':=', value=ts, email='')
        user3 = RadCheck(username=username, attribute='Simultaneous-Online', op=':=', value=1, email='')
        self.db.add_all([user1, user2, user3])
        self.db.commit()

    def update_user_deadline_timestamp(self, username, ts):
        '''data: dict'''
        self.db.query(RadCheck).filter_by(username=username).filter_by(attribute='Deadline-Timestamp').update(dict(value=ts))
        self.db.commit()

    def update_user_email(self, username, email):
        self.db.query(RadCheck).filter_by(username=username).update(dict(email=email))
        self.db.commit()

    def update_user_password(self, username, password):
        self.db.query(RadCheck).filter_by(username=username).filter_by(attribute='Cleartext-Password').update(dict(value=password))
        self.db.commit()

    @models_to_list
    def get_vpn_servers(self):
        return self.db.query(Server).all()

    @models_to_list
    def get_user_planorders(self, username):
        return self.db.query(PlanOrder).filter_by(username=username).all()

    def add_user_planorder(self, username, plan_identifier):
        planorder = PlanOrder(username=username, plan_identifier=plan_identifier)
        self.db.add(planorder)
        self.db.commit()

    def add_feedback(self, data):
        feedback = Feedback(**data)
        self.db.add(feedback)
        self.db.commit()

    @models_to_list
    def get_feedbacks(self):
        return self.db.query(Feedback).order_by(Feedback.create_time.desc()).all()

