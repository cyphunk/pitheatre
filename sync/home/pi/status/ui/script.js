/* 
 * status update ui helper functions
 * 
 * http_get sends generic http ajax request and passes response
 *          to callback
 * 
 * parse_data parses shell script "Name=Value" lines into
 *            javascript data object
 * 
 * status_loop sends request to server to run status script, 
 *             passes result to parse_data,
 *             hands parsed data to callback
 * 
 * on_old_data_or_offline
 *             will check that data from status_loop is 
 *             fresh and if not it will run callback
 *             this may also get triggered if status server
 *             is crashed or is offline
 *                  
 * 
 * example_make_status_ui_elem
 *             calls status_loop and updates a HTML UI element
 *             element div has unique id based on command
 *             element div has class 'status'
 * 
 * see index.html for how they fit together
 * 
 */ 

var status_scripts_poll_uri_prefix = "status"
var elements_class = 'status'
var pause_looping = false; // set to true to debug a loop

function http_get(url, callback=console.log) {
    var xmlHttp     = new XMLHttpRequest();
    console.log('http_get','request',url);
    xmlHttp.callback = callback;
    xmlHttp.url = url;
    xmlHttp.onload  = function (e) {
      console.log('http_get','completed',e.target.responseURL);
      this.callback(this);
    } 
    xmlHttp.onerror = function (e) { 
        console.error('http_get',url,e, 'will try again') 
        // on error try again after n seconds
        setTimeout(function(){
            http_get(url, callback)
        }, 5000)
    }
    xmlHttp.open( "GET", url, true);
    xmlHttp.send( null );
}

/*
 *  parse_data(data_raw_string)
 *  parse "Variable = Value" lines and return data structure
 *
 *  data_raw_string = example:
 *      # ./processes.sh
 *      PROCESS_1="init"
 *      PROCESS_1_RUNNING=1
 *  returns:
 *      data = { 'PROCESS_1': 'init'
 *               'PROCESS_1_RUNNING': 1 }
 */
function parse_data(data_raw_string) {
    var data = {}
    data_raw_string.split('\n').forEach(function(line) {
        // remove leading spaces
        line = line.trim()
        // skip if comment
        if (line[0] == '#')
            return
        splitat = line.indexOf('=')
        // skip if line does have =
        if (splitat < 0)
            return
        var name = line.substring(0,splitat).trim()
        var value = line.substring(splitat+1).trim()
        // if the value is encapsulated in " " or ' ' then remove first and last
        if (value[0] == '"' && value[value.length-1] == '"')
            value = value.slice(1,-1)
        else if (value[0] == "'" && value[value.length-1] == "'")
            value = value.slice(1,-1)
        // value always string for now
        data[name] = value
    });
    return data
}

/* 
 * status_loop(command, updateIntervalMS, callback)
 * send http requst of status command every Interval
 * pass parsed return data to callback
 * 
 * example:
 *   command = ['process.sh', 'arg1', 'arg2']
 *      gets sent as http requst: '/status/process.sh?arg1,arg2'
 *   updateIntervalMS = 1000
 *      sends the http request every 1 second
 *   callback = function(parsed_data, response) {
 *                  console.log(parsed_data) // see parse_data()
 *                  console.log(response.responseText) // data is parsed from responseText
 *              });
 */
var glob_last_modified_time = null;
function status_loop(command, updateIntervalMS, callback=console.log) {
    // if command arguments (eg process list) convert to /status/command?arg1,arg2
    var commandId = command.join('-')
    console.log('status_loop start', commandId)
    if (command.length > 1) {
        var args = command.splice(1)
        command = command + '?' + args.join(',')
    }
    function _loop(){
        if (pause_looping) {
            setTimeout(_loop, updateIntervalMS);
            return;
        }
        http_get(status_scripts_poll_uri_prefix+'/'+command, 
          function(res){
            var parsed_data = parse_data(res.responseText)
            callback(commandId, parsed_data, res);
            glob_last_modified_time = Date.now()
            setTimeout(_loop, updateIntervalMS)
          }
        );
    }
    _loop()
}

// calls self every 2 seconds
// if glob_last_modified_time time is older than  thresholdSeconds
// then run callback with "false" (data is not old)
// if glob_last_modified_time time is not older than thresholdSeconds
// then runn callback with "true" (data is old)
function on_old_data_or_offline(thresholdSeconds, callback=console.log) {
    var thresholdMS = thresholdSeconds*1000;
    function _loop(){
        if (Date.now()-glob_last_modified_time > thresholdMS) {
            console.log('data is old')
            callback(true)
        }
        else {
            callback(false)
        }
        setTimeout(_loop, 2000);
    }
    _loop();
}

function example_make_status_ui_elem(command, updateIntervalMS, appendToElem, callback) {
    var elemId = command.join('-')
    // console.log('update:',elemId)
    // get or create element with elemId
    var elem = document.getElementById(elemId)
    if (elem == null) {
        elem = document.createElement('div')
        elem.id = elemId
        elem.className = elements_class
        appendToElem.append(elem)
    }
    // update
    status_loop(command, updateIntervalMS, 
        function(commandId, parsed_data, response) {
            elem.innerHTML = `<pre class=data_raw>Raw data: &#10549;\n${response.responseText}</pre>`
    
            // additionall callback can be used t   o further update element
            if (typeof(callback) == 'function')
                callback(parsed_data, elem)
    });
}


