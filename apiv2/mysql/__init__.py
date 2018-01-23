#!/usr/bin/env python
# -*- coding: utf-8 -*-

import random
import logging

from tornado.options import options
from sqlalchemy import create_engine
from sqlalchemy.orm import scoped_session, sessionmaker

from settings import MYSQL_CONFS
from mysql.api import APIModel


def create_session(engine):
    if not engine:
        return None
    session = scoped_session(sessionmaker(bind=engine))
    return session()


class Database(object):

    def __init__(self):
        # self.schema = 'mysql://%s:%s@%s:%d/%s?charset=utf8mb4'
        self.schema = 'mysql://%s:%s@%s:%d/%s?charset=utf8'
        self.sessions = []
        self.kwargs = {
            'pool_recycle': 3600,
            'echo': options.debug,
            'echo_pool': options.debug
        }

        self.init_session()
        self.api = APIModel(self)

    def _session(self, user, passwd, host, port, db):
        schema = self.schema % (user, passwd, host, port, db)
        engine = create_engine(schema, **self.kwargs)
        session = create_session(engine)
        print('%s' % schema)
        return session

    def init_session(self):
        self.sessions = []
        for db in MYSQL_CONFS:
            session = self._session(db['user'], db['password'], db['host'], db['port'], db['db'])
            self.sessions.append(session)

    def get_session(self):
        session = random.choice(self.sessions)
        return session

    @classmethod
    def instance(cls):
        name = 'singleton'
        if not hasattr(cls, name):
            setattr(cls, name, cls())
        return getattr(cls, name)

    def close(self):
        def shut(ins):
            try:
                ins.commit()
            except:
                logging.error('MySQL server has gone away. ignore.')
            finally:
                ins.close()

        for session in self.sessions:
            shut(session)


# global, called by control
pdb = Database.instance()
