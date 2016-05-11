/**
 * A few utility functions that will be useful in multiple files
 */


LAYER_HEIGHT_VAR = "layerHeight";
NOZZLE_DIAMETER_VAR = "nozzleDiameter";

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

// Function for converting special characters that could be interpreted as html to their escaped equivalent
// Thanks to https://css-tricks.com/snippets/javascript/htmlentities-for-javascript/
function htmlEntities(str) {
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}


function smartToString(number, digits) {
    // Rounds the number sort-of-automatically based on the magnitude. This is also used to sanitize strings obtained
    // from the url before displaying on a page.
    var num = parseFloat(number);
    if (num == 0)
        return "0";
    if (!digits)
        digits = 2;
    var order = Math.round(Math.log(Math.abs(num)) / Math.log(10));
    if (order >= -3 && order <= 6)
        return num.toFixed(Math.max(digits - order, 0));
    else
        return num.toExponential(digits);
}

function parseParams(json_data) {
    // Parses a json_data string (which comes from params.js), sorting it according to sort order
    var out = JSON.parse(json_data);
    out.sort(function(a,b) {return a.sortOrder - b.sortOrder});
    return out;
}

function encodeURIstring(str) {
    // Encodes a string using a url-safe and unicode-safe version of base64.
    // Code tweaked from from https://developer.mozilla.org/en-US/docs/Web/API/WindowBase64/Base64_encoding_and_decoding#The_.22Unicode_Problem.22
    return btoa(encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, function(match, p1) {
        return String.fromCharCode('0x' + p1);
    })).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '.');
}

function decodeURIstring(str) {
    // Decodes a string using a url-safe and unicode-safe version of base64.
    // Code tweaked from from https://developer.mozilla.org/en-US/docs/Web/API/WindowBase64/Base64_encoding_and_decoding#The_.22Unicode_Problem.22
    return decodeURIComponent(Array.prototype.map.call(atob(str.replace(/-/g, '+').replace(/_/g, '/').replace(/\./g, '=')),
        function(c) {
            return '%' + c.charCodeAt(0).toString(16);
        }).join(''));
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
        last_status_obj.html("Working...This may take up to two minutes...");
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
        $("#post-message").css({"display": "block"});
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
function startGenerate(new_part_params, status_obj, progress_obj) {
    // Starts the process of generating a new part.
    progress_obj.progressbar("option", "value", false);
    last_status_obj = status_obj;
    last_progress_obj = progress_obj;
    part_params = new_part_params;
    postJSON("/engine", jQuery.extend({}, new_part_params, {"Command": "Start"}), handleDone);
}
function checkDone() {
    // should only be called after calling startGenerate() or else part_params won't be set correctly.
    if(!generating)
        return;
    postJSON("/engine", jQuery.extend({}, part_params, {"Command": "Check"}), handleDone);
}
function submitResult(data) {
    // Submits results and form data from finish.html to the server
    postJSON("/engine", jQuery.extend({}, data, {"Command": "Submit"}), function (resp) {
        if (resp.Status == "OK") {
            alert("Submission Succeeded. Your confirmation number is " +
                    String(resp.Confirm) + '.');
            location.href = "index#message=" + encodeURIstring("Submission Succeeded. Your confirmation number is " +
                    String(resp.Confirm) + '.');
        }
        else {
            if (typeof resp.ErrMessage === "undefined" )
                $("#status").html("Unknown Error occurred");
            else 
                $("#status").html("Error occurred: " + resp.ErrMessage);
        }
    });

}

