#! SHELL=/bin/sh

css_path = static/css
combo_path = static/combo
js_path = static/js
supervisorctl = /home/work/supervisor/bin/supervisorctl

coupon_restart:
	@for port in {9200..9207}; \
	do\
		${supervisorctl} restart coupon:coupon-$$port; \
	done

coupon_restart1:
	@for port in {9200..9200}; \
	do\
		${supervisorctl} restart coupon:coupon-$$port; \
	done

compile:
	lessc --clean-css ${css_path}/base.css > ${combo_path}/base.min.css
	uglifyjs ${js_path}/index.js -o ${combo_path}/index.min.js -c
	uglifyjs ${js_path}/vote.js -o ${combo_path}/vote.min.js -c
