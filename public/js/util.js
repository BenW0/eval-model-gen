/**
 * A few utility functions that will be useful in multiple files
 */

/* QueryStringToHash() - converts a query string (parameters) back into an object.
 * From user 太極者無極而生 on stackoverflow:
 * http://stackoverflow.com/questions/1131630/the-param-inverse-function-in-javascript-jquery
 */

function QueryStringToHash(query) {

  if (query == '') return {};

  var hash = {};

  var vars = query.split("&");

  for (var i = 0; i < vars.length; i++) {
    var pair = vars[i].split("=");
    var k = decodeURIComponent(pair[0]);
    var v = decodeURIComponent(pair[1]);

    // If it is the first entry with this name
    if (typeof hash[k] === "undefined") {

      if (k.substr(k.length-2) != '[]')  // not end with []. cannot use negative index as IE doesn't understand it
        hash[k] = v;
      else
        hash[k] = [v];

    // If subsequent entry with this name and not array
    } else if (typeof hash[k] === "string") {
      hash[k] = v;  // replace it

    // If subsequent entry with this name and is array
    } else {
      hash[k].push(v);
    }
  }
  return hash;
}


function smartToString(number, digits) {
    // Rounds the number sort-of-automatically based on the magnitude
    if (number == 0)
        return "0";
    if (!digits)
        var digits = 2;
    var order = Math.round(Math.log(Math.abs(number)) / Math.log(10));
    if (order >= -3 && order <= 6)
        return number.toFixed(Math.max(digits - order, 0));
    else
        return number.toExponential(digits);
}


/*********** Code to support AJAX calls for generating parts ****************/
var generating = false;
var generated = false;
var part_params = {};   // This is an object with members for each part parameter for the part generated.
var timer;              // timer variable used for checking for server being finished
var last_status_obj;
var last_progress_obj;
function handleDone(resp) {
    // Function which handles the json response to posts to the server.
    // resp is an object populated with at least a Status element.
    if(resp.Status == "Error")
    {
        last_status_obj.html(resp.Status + ": " + resp.ErrMessage);
        window.clearInterval(timer);
        generating = false;
        last_progress_obj.progressbar("option", "value", 100);
    }
    else if(resp.Status == "Working")
    {
        last_status_obj.html(resp.Status);
        // if we're still working, check back later (only if we haven't already set the timer)
        if(!generating)
            timer = window.setInterval(checkDone, 700);
        generating = true;
    }
    else if(resp.Status == "Ready")
    {
        var link = "getmodel?name=" + resp.Filename;
        window.clearInterval(timer);
        last_progress_obj.progressbar("option", "value", 100);
        generating = false;
        generated = true;
        // download file and display a link in case that doesn't work...
        last_status_obj.html("Ready!  Click <a id='download_link' href='" + link + "'>here</a> if download doesn't begin automatically");
        $("a#download_link").attr({target: '_blank', href: link});
        $("body").append("<iframe src='" + link + "' style='display: none;'></iframe>");
    }
    else
    {
        last_status_obj.html("Server did something weird!");
        window.clearTimer(timer);
        generating = false;
        last_progress_obj.progressbar("option", "value", 100);
    }
    
}
function handleFail(){
    $("#status").html("Server Communication Error");
}
function handleAlways(){
}

function postJSON(url, data, callback) {
    $.ajaxSetup({ scriptCharset:"utf-8", 
                    contentType:"application/json; charset=utf-8" });
    var s = JSON.stringify(data);
    //$("#status").html(s);
    $.post(url, s, callback, "json")
        .fail(handleFail)
        .always(handleAlways);
}
function startGenerate(layer_height, col_min, col_max, bar_min, bar_max, status_obj, progress_obj) {
    // pass floats to all parameters.
    part_params = {"layer_height": layer_height,
            "col_min": col_min,
            "col_max": col_max,     
            "bar_min": bar_min,
            "bar_max": bar_max};
    progress_obj.progressbar("option", "value", false);
    last_status_obj = status_obj;
    last_progress_obj = progress_obj;
    postJSON("/engine", jQuery.extend({}, part_params, {"Command": "Start"}), handleDone);
}
function checkDone() {
    // should only be called after calling startGenerate() or else part_params won't be set correctly.
    if(!generating)
        return;
    postJSON("/engine", jQuery.extend({}, part_params, {"Command": "Check"}), handleDone);
}

