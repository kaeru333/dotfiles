function submit
	if test (nvm current) != "v20.16.0"
		nvm use v20.16.0
	end
	acc s main.py -- --guess-python-interpreter pypy
end
