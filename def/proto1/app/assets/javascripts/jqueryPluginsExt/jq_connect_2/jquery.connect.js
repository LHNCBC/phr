/*jsl:option explicit*/
/*jsl:declare jQuery*/
/*jsl:declare self*/

jQuery.extend({
    /*
     *@param: refObj:optional(object|null) The source object for reference function. 
     *			Defaults to self(global) if null.
     *@param: refFunc:(string) The reference function name
     *@param: callObj:optional(object|null) connecting funcion this object
                        Defaults to self(global) if null
     *@param: callFunc: (object|string) The connection function or function name
     */
    connect: function(){
	var args = this._getArgs(arguments);
	jQuery._connect.apply(this,args);
    },
    /*
     *@param: refObj:optional(object|null) The source object for reference function. 
     *			Defaults to self(global) if null.
     *@param: refFunc:(string) The reference function name
     *@param: callObj:optional(object|null) connected funcion this object
                        Defaults to self(global) if null
     *@param: callFunc: (object|string) The connected function or function name
     */
    disconnect: function(){
	var args = this._getArgs(arguments);
	jQuery._disconnect.apply(this,args);
    },
    disconnectAll: function(){
	var args = this._getArgs(arguments);
	var refObj = args[0];
	var refFunc = args[1];
	var origFunc = refObj[refFunc];
	if(typeof origFunc._listeners == 'undefined')
	    return;
	var ls = origFunc._listeners;
	var t = origFunc.target;
	origFunc._listeners = null;
	delete origFunc['_listeners'];
	origFunc = refObj[refFunc] = t;
    },
    _connect: function(refObj, refFunc, callObj, callFunc){
	var origFunc = refObj[refFunc];
	if(typeof callFunc == 'string')
	    callFunc = callObj[callFunc];
	if(typeof origFunc._listeners == 'undefined'){
	    var newFunc = this._getNewFunc(refObj);
	    newFunc.target = origFunc;
	    newFunc._listeners = [];
	    origFunc = refObj[refFunc]= newFunc;
	}
	origFunc._listeners.push([callObj, callFunc]);
    },
    _disconnect:function(refObj, refFunc, callObj, callFunc){
	var origFunc = refObj[refFunc];
	if(typeof callFunc == 'string')
	    callFunc = callObj[callFunc];
	if(typeof origFunc._listeners == 'undefined')
	    return;
	var temp;
	for(var i=0; i<origFunc._listeners.length; i++){
	    temp = origFunc._listeners[i];
	    if(temp[0] == callObj && temp[1] == callFunc)
		origFunc._listeners.splice(i,1);
	    return;
	}
    },
    _getArgs: function(_args){
	// normalize arguments
	var a=_args, args=[], i=0;
	// if a[0] is a String, obj was ommited
	if(!a[0]) a[0] = self;
	/*jsl:ignore*/
	args.push(jQuery.isString(a[0]) ? self : a[i++], a[i++]);

	// if the arg-after-next is a String or Function, callObj was NOT omitted
	var a1 = a[i+1];
	if(!a1) a1 = self;
	args.push(jQuery.isString(a1)||jQuery.isFunction(a1) ? a[i++] : self, a[i++]);
	/*jsl:end*/
	// absorb any additional arguments
	for(var l=a.length; i<l; i++){	args.push(a[i]); }
	return args;
    },
    _getNewFunc: function(refObj){
	return function(){
	    var c = arguments.callee; 
	    var ls = c._listeners;
	    c.target.apply(refObj,arguments);
	    for(var i=0; i<ls.length; i++){
		ls[i][1].apply(ls[i][0]);
	    }
	};
    },
    isString: function(arg){
	if(typeof arg == 'string')
	    return true;
	return false;
    }
});