publish:
	coffee -b -o ./js -c coffess_async_module.coffee
	mv js/coffess_async_module.js js/jquery.asyncModule.js
	git commit -am "auto commit, push by Makefile"
	git push origin