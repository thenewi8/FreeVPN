#!/usr/bin/env bash
#tar zcvf ../app.tar.gz --exclude=.git/ --exclude=__pycache__/ --exclude=.idea/ --exclude=deploy.sh .
#cd ../

rsync -r . stage_zlg:thunder/api/
#scp app.tar.gz stage_zlg:thunder/api/app.tar.gz
#
#ssh stage_zlg << 'END'
#    cd ~/thunder/api
#    tar zxvf app.tar.gz
#END
#
