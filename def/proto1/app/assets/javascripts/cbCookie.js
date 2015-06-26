/*
 *Adapted from the daniell bulli wrote.
-----------------------------------------------
Daniel Bulli
http://www.nuff-respec.com/technology/cross-browser-cookies-with-flash
----------------------------------------------- */

//set this to name of your flash object/embed
var cookie_id  = 'CBCookie';

var CB_Cookie =
{
	init: function(cookie_id)
	{
		this.cookie_id  		= cookie_id;
		this.flash_cookie_ready = false;
		this.flash_cookie_able  = false;
		this.flash_cookie  		= null;
		this.flash_alert  		= false;

		this.flash_is_ready();
	},

	flash_is_ready: function()
	{
		if(!document.getElementById || !document.getElementById(this.cookie_id)) return;
		if(!this.get_movie(this.cookie_id)) return;
 		if (this.flash_cookie.f_cookie_able != undefined ) {
      this.flash_cookie_able  = this.flash_cookie.f_cookie_able();
      this.flash_cookie_ready = true;
    }
	},

	is_able: function()
	{
		if(!this.flash_alert && !(this.flash_cookie_ready && this.flash_cookie_able))
		{
			// alert("CB_Cookie not initialized correctly.");
			this.flash_alert = true;
		}
		return (this.flash_cookie_ready && this.flash_cookie_able);
	},

	get: function(key)
	{
		if(!this.is_able()) return;
		var ret = this.flash_cookie.f_get_cookie(key);
		return ((ret == 'null') ? '' : ret);
	},

	set: function(key,val)
	{
		if(!this.is_able() || !this.flash_cookie.f_set_cookie) return;
		this.flash_cookie.f_set_cookie(key,val);
	},

	get_movie: function()
	{
    	if (navigator.appName.indexOf("Microsoft") != -1)
    	{
    		this.flash_cookie = window[this.cookie_id];
    	}
    	else
    	{
    		this.flash_cookie =  document[this.cookie_id];
    	}

    	return ((this.flash_cookie) ? true : false);
	}

};

function flash_ready()
{
	CB_Cookie.init(cookie_id);
}

function createCookie(name,value,days) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

function eraseCookie(name) {
	createCookie(name,"",-1);
}
