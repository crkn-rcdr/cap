# CAP stuff
CAP_LESS = ./styles/cap.less
BOOTSTRAP_LESS = ./bootstrap/less/*.less
BOOTSTRAP_JS = ./bootstrap/js
STYLE_IN = ./styles/portals
STYLE_OUT = ../static/css
SCRIPT_IN = ./js
SCRIPT_OUT = ../static/js
PORTALS = $(basename $(notdir $(wildcard $(STYLE_IN)/*.less)))
BOOTSTRAP_ORDER = transition alert button carousel collapse dropdown modal tooltip popover scrollspy tab typeahead
LIBS_ORDER = jquery-1.7.1 jquery.history jquery.placeholder
JS_ORDER = cap.preloader cap.pageViewer cap.matchingPages cap.main

#uglifyjs -nc bootstrap/js/bootstrap.js > bootstrap/js/bootstrap.min.js

all: less lessmin js

less: $(foreach portal,$(PORTALS),$(STYLE_OUT)/$(portal).css)

lessmin: $(foreach portal,$(PORTALS),$(STYLE_OUT)/$(portal).min.css)

js:
	cp $(SCRIPT_IN)/copy/*.js $(SCRIPT_OUT)
	cat $(foreach lib,$(LIBS_ORDER),$(SCRIPT_IN)/libs/$(lib).js) \
		$(foreach strap,$(BOOTSTRAP_ORDER),$(BOOTSTRAP_JS)/bootstrap-$(strap).js) \
		$(foreach jsfile,$(JS_ORDER),$(SCRIPT_IN)/$(jsfile).js) \
		> $(SCRIPT_OUT)/cap.js
	node_modules/uglify-js/bin/uglifyjs $(SCRIPT_OUT)/cap.js -mc > $(SCRIPT_OUT)/cap.min.js

$(STYLE_OUT)/%.css: $(STYLE_IN)/%.less $(CAP_LESS) $(BOOTSTRAP_LESS)
	node_modules/less/bin/lessc $< > $@

$(STYLE_OUT)/%.min.css: $(STYLE_IN)/%.less $(CAP_LESS) $(BOOTSTRAP_LESS)
	node_modules/less/bin/lessc --compress $< > $@

clean:
	@rm $(STYLE_OUT)/*.css
	@rm $(SCRIPT_OUT)/*.js

.PHONY: all less less-min clean js
