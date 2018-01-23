tar zcvf ../app.tar.gz --exclude=.git/ --exclude=deploy.sh --exclude=__pycache__/ --exclude=.idea/ .
cd ../

scp app.tar.gz aws:source/freevpntest/app.tar.gz
ssh aws<< 'END'
    cd source/freevpntest
    tar zxvf app.tar.gz
    ~/py27venv/bin/supervisorctl restart freevpntest:freevpntest-9000
    ~/py27venv/bin/supervisorctl restart freevpntest:freevpntest-9001
    ~/py27venv/bin/supervisorctl restart freevpntest:freevpntest-9002
    ~/py27venv/bin/supervisorctl restart freevpntest:freevpntest-9003
END
