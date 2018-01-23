#!/usr/bin/env bash
tar zcvf ../app.tar.gz --exclude=.git/ --exclude=__pycache__/ --exclude=.idea/ --exclude=deploy.sh .
cd ../

scp app.tar.gz do_sg01:test_api/app.tar.gz

ssh do_sg01 << 'END'
    cd ~/test_api
    tar zxvf app.tar.gz
END
