#python check_bill_daily.py --debug=False
import logging
import datetime

from tornado.options import options, define
define('debug', default=True, help='enable debug mode')
define('day', default=None, help='select the day analysis')
define('cache', default=None, help='all stat data > redis')

options.parse_command_line()

from mysql import pdb
from settings import ALI_PAY_RATE
DB = pdb.api
from control import ctrl

def main():
    yesterday=(datetime.datetime.now()-datetime.timedelta(1)).strftime('%Y-%m-%d')

    if options.day and len(options.day) == 10:
        yesterday = options.day
    try:
        DB.delete_stat_day(day=yesterday)
        logging.info("delete %s"%(yesterday))
        kids = DB.get_erp_day_distinct_kid(yesterday)
        logging.info(kids)
        sum_day_fee, sum_day_service_charge, sum_day_wx_service_charge, sum_day_account_money, sum_day_count = 0, 0, 0, 0, 0
        sum_day_ali_fee, sum_day_ali_thunder_service_charge, sum_day_ali_service_charge, sum_day_ali_account_money, sum_day_ali_count = 0, 0, 0, 0, 0
        sum_day_pos_fee, sum_day_pos_thunder_service_charge, sum_day_pos_service_charge, sum_day_pos_account_money, sum_day_pos_count = 0, 0, 0, 0, 0
        for kid in kids:
            kid = kid[0]
            if kid < 0: continue
            fee, service_charge, wx_rt_rate_fee = DB.get_ktv_trade_period_sum_money_active(kid, yesterday, yesterday)
            movie_fee = DB.get_ktv_trade_period_sum_money_active(kid, yesterday, yesterday, other='%movieid%')[1]

            wx_service_charge = DB.get_ktv_trade_period_wxrate_fee(kid, yesterday, yesterday)

            ali_fee, ali_thunder_service_charge = DB.get_ktv_trade_period_sum_money_active_ali(kid, yesterday, yesterday)
            ali_movie_fee = DB.get_ktv_trade_period_sum_money_active_ali(kid, yesterday, yesterday, other='%movieid%')[1]
            ali_service_charge = round(ali_fee * ALI_PAY_RATE)

            pos_fee, pos_thunder_service_charge, pos_rt_rate_fee, pos_service_charge = DB.get_ktv_trade_period_sum_money_active_pos(kid, yesterday, yesterday)

            account_money = fee - service_charge
            count = DB.get_erp_order_count(date=yesterday, ktv_id=kid)
            averrage = fee/max(int(count),1)

            ali_account_money = ali_fee - ali_thunder_service_charge
            ali_count = DB.get_erp_order_count_ali(date=yesterday, ktv_id=kid)
            ali_averrage = ali_fee/max(int(ali_count),1)

            pos_account_money = pos_fee - pos_thunder_service_charge
            pos_count = DB.get_erp_order_count_pos(date=yesterday, ktv_id=kid)
            pos_averrage = pos_fee/max(int(pos_count),1)

            stat_item = {
                    'ktv_id': kid,

                    'total_fee': fee,
                    'service_charge': service_charge,
                    'account_money': account_money,
                    'wx_service_charge': wx_service_charge,
                    'wx_rt_rate_fee': wx_rt_rate_fee,
                    'total_order': count,
                    'averrage_fee': averrage,
                    'movie_fee': movie_fee,

                    'ali_total_fee': ali_fee,
                    'ali_thunder_service_charge': ali_thunder_service_charge,
                    'ali_account_money': ali_account_money,
                    'ali_service_charge': ali_service_charge,
                    'ali_total_order': ali_count,
                    'ali_averrage_fee': ali_averrage,
                    'ali_movie_fee': ali_movie_fee,

                    'pos_total_fee': pos_fee,
                    'pos_thunder_service_charge': pos_thunder_service_charge,
                    'pos_account_money': pos_account_money,
                    'pos_service_charge': pos_service_charge,
                    'pos_rt_rate_fee': pos_rt_rate_fee,
                    'pos_total_order': pos_count,
                    'pos_averrage_fee': pos_averrage,

                    'date': yesterday,
                    }
            DB.insert_stat_day(stat_item)
            logging.info(stat_item)

            sum_day_fee += fee
            sum_day_service_charge += service_charge
            sum_day_wx_service_charge += wx_service_charge
            sum_day_account_money += account_money
            sum_day_count += count

            sum_day_ali_fee += ali_fee
            sum_day_ali_thunder_service_charge += ali_thunder_service_charge
            sum_day_ali_service_charge += ali_service_charge
            sum_day_ali_account_money += ali_account_money
            sum_day_ali_count += ali_count

            sum_day_pos_fee += pos_fee
            sum_day_pos_thunder_service_charge += pos_thunder_service_charge
            sum_day_pos_service_charge += pos_service_charge
            sum_day_pos_account_money += pos_account_money
            sum_day_pos_count += pos_count

        stat_item = {
            'ktv_id': -1,

            'total_fee': sum_day_fee,
            'service_charge': sum_day_service_charge,
            'account_money': sum_day_account_money,
            'wx_service_charge': sum_day_wx_service_charge,
            'total_order': sum_day_count,
            'averrage_fee': sum_day_fee / max(sum_day_count, 1),

            'ali_total_fee': sum_day_ali_fee,
            'ali_thunder_service_charge': sum_day_ali_thunder_service_charge,
            'ali_account_money': sum_day_ali_account_money,
            'ali_service_charge': sum_day_ali_service_charge,
            'ali_total_order': sum_day_ali_count,
            'ali_averrage_fee': sum_day_ali_fee / max(sum_day_ali_count, 1),

            'pos_total_fee': sum_day_pos_fee,
            'pos_thunder_service_charge': sum_day_pos_thunder_service_charge,
            'pos_account_money': sum_day_pos_account_money,
            'pos_service_charge': sum_day_pos_service_charge,
            'pos_total_order': sum_day_pos_count,
            'pos_averrage_fee': sum_day_pos_fee / max(sum_day_pos_count, 1),

            'date': yesterday,
        }
        logging.info(stat_item)
        DB.insert_stat_day(stat_item)

    except:
        logging.error("%s error"%yesterday)
        traceback.print_exc()

def stat_data_write_redis():
    yesterday=(datetime.datetime.now()-datetime.timedelta(1)).strftime('%Y-%m-%d')
    if options.day and len(options.day) == 10:
        yesterday = options.day
    today = datetime.datetime.now()
    ctrl.cms.set_in_out_money_date_ctl(yesterday)
    if today.day == 1:
        month_end = today - datetime.timedelta(1)
        month_start = '%d-%02d-01' % (month_end.year, month_end.month)
        ctrl.cms.set_in_out_money_month_ctl(month_start, str(month_end.date()))

def all_stat_data_write_redis():
    start_date = datetime.datetime.strptime('2016-03-07', '%Y-%m-%d')
    end_date = datetime.datetime.now() - datetime.timedelta(1)
    while start_date.date() <= end_date.date():
        ctrl.cms.set_in_out_money_date_ctl(str(start_date.date()))
        if start_date.day == 1:
            month_end = start_date - datetime.timedelta(1)
            month_start = '%d-%02d-01' % (month_end.year, month_end.month)
            ctrl.cms.set_in_out_money_month_ctl(month_start, str(month_end.date()))
        start_date += datetime.timedelta(1)

if __name__ == "__main__":
    if not options.cache:
        main()
    else:
        if options.cache == 'all':
            all_stat_data_write_redis()
        elif options.cache == 'date':
            stat_data_write_redis()
