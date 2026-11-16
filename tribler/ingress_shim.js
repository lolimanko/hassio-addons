(function(){
var i=location.pathname.indexOf("/ui/");
var P=i>0?location.pathname.slice(0,i):"";
if(!P)return;
function fix(u){
 try{
  var s=(typeof u==="string")?u:(u&&u.href)?u.href:null;
  if(s===null)return u;
  var a=new URL(s,location.href);
  var h=a.protocol==="ws:"?"http:":a.protocol==="wss:"?"https:":a.protocol;
  if(h+"//"+a.host!==location.origin)return u;
  if(a.pathname.indexOf(P+"/")===0)return u;
  var out=P+a.pathname+a.search+a.hash;
  return(a.protocol==="ws:"||a.protocol==="wss:")?a.protocol+"//"+a.host+out:out;
 }catch(e){return u;}
}
var f=window.fetch;
window.fetch=function(x,o){
 if(typeof x==="string"||x instanceof URL)return f.call(this,fix(x),o);
 if(x&&x.url){var n=fix(x.url);if(n!==x.url)x=new Request(n,x);}
 return f.call(this,x,o);
};
var op=XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.open=function(m,u){arguments[1]=fix(u);return op.apply(this,arguments);};
if(window.EventSource){
 var ES=window.EventSource;
 window.EventSource=function(u,c){return new ES(fix(u),c);};
 window.EventSource.prototype=ES.prototype;
}
var WS=window.WebSocket;
window.WebSocket=function(u,p){return p===undefined?new WS(fix(u)):new WS(fix(u),p);};
window.WebSocket.prototype=WS.prototype;
})();
