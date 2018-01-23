tar zcvf ../app.tar.gz --exclude=.git/ --exclude=deploy.sh --exclude=__pycache__/ --exclude=.idea/ .
cd ../

scp app.tar.gz aws:source/freevpn/app.tar.gz
ssh aws<< 'END'
    cd source/freevpn
    tar zxvf app.tar.gz
    ~/py27venv/bin/supervisorctl restart freevpn:freevpn-8000
    ~/py27venv/bin/supervisorctl restart freevpn:freevpn-8001
    ~/py27venv/bin/supervisorctl restart freevpn:freevpn-8002
    ~/py27venv/bin/supervisorctl restart freevpn:freevpn-8003
END

#scp app.tar.gz do_sg02:source/freevpn/app.tar.gz
#ssh do_sg02 << 'END'
#    cd source/freevpn
#    tar zxvf app.tar.gz
#    ~/py27venv/bin/supervisorctl restart freevpn:freevpn-8000
#    ~/py27venv/bin/supervisorctl restart freevpn:freevpn-8001
#    ~/py27venv/bin/supervisorctl restart freevpn:freevpn-8002
#    ~/py27venv/bin/supervisorctl restart freevpn:freevpn-8003
#END
