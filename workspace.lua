local menubar = hs.menubar.new()
local menuData = {}
local urlPath = '/.workspaces'
local urlFile = 'urls.txt'
local urlFileChrome = 'chromeurls.txt'
local shellCommandFile = 'ws_command.sh'
local currentWS = 0
local defaultWS_name = 'defaultws' 
local defaultWS_index = 0;

local wsEmoji = {
    notready = '🚌',
    openWS = '🗃',
    closeWS = '🗄',
    ReleaseWS = '🎪',
    default = ''
}

local queryFolder = {}
function getQueryFolder()    
    local dirname = os.getenv('HOME') .. urlPath
    local iterFn, dirObj = hs.fs.dir(dirname)
    for i = #queryFolder, 1, -1 do
        table.remove(queryFolder, i)
    end
    if iterFn then
        for file in iterFn, dirObj do
            if (file ~= '.' and file ~= '..') then
                local fileInfo = hs.fs.attributes(dirname .. '/' .. file)
                if (fileInfo.mode == 'directory') then
                    local defws = false;
                    if (file == defaultWS_name) then
                        defws = true;
                    end
                    table.insert(queryFolder, {
                        name=file,
                        dir=dirname..'/'..file,
                        defaultws=defws
                    })
                end
            end
        end
    else
        print(string.format('The following error occurred: %s', dirObj))
    end
    dirObj:close()
end

function openWorkSpaceURLs(WSindex)
    if currentWS == WSindex and currentWS ~= defaultWS_index then
        return
    end
    hs.alert.show('Open '..queryFolder[WSindex]['name']..' Work Space.')
    local fileInfo = hs.fs.attributes(queryFolder[WSindex]['dir'] .. '/' .. urlFile)
    if fileInfo ~= nil and fileInfo.mode == 'file' then
        for url in io.lines(queryFolder[WSindex]['dir']..'/'..urlFile) do
            hs.urlevent.openURLWithBundle(url, 'com.apple.Safari')
        end
    else
        print(queryFolder[WSindex]['dir']..'/'..urlFile..' not found.')
    end

    fileInfo = hs.fs.attributes(queryFolder[WSindex]['dir']..'/'..urlFileChrome)
    if fileInfo ~= nil and fileInfo.mode == 'file' then
        for url in io.lines(queryFolder[WSindex]['dir']..'/'..urlFileChrome) do
            hs.urlevent.openURLWithBundle(url, 'com.google.Chrome')
        end
    else
        print(queryFolder[WSindex]['dir']..'/'..urlFileChrome..' not found.')
    end

    currentWS = WSindex
    updateMenubar()
end

function openWorkSpace(WSindex)
    openWorkSpaceURLs(WSindex)
    runWorkSpaceCMDs(WSindex)
end

function shell(cmd)
    result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
end

function runWorkSpaceCMDs(WSindex)
    local fileInfo = hs.fs.attributes(queryFolder[WSindex]['dir'] .. '/' .. shellCommandFile)
    if fileInfo == nil then
        print(queryFolder[WSindex]['dir']..'/'..shellCommandFile..' not found.')
        return
    end
    local cmd = 'cd '..queryFolder[WSindex]['dir']..' && source '..shellCommandFile 
    print(cmd)
    shell(cmd)
end

function getChromeURLs()
    local js =
        [[
            var datastr = "";
            var gg = Application('Chrome');
            if(gg.running){
                const firstWindow = gg.windows[0]
                var alltabs = firstWindow.tabs
                var tabLen = alltabs.length		
                for (var i = 0; i < tabLen; i++) {
                    var name = alltabs[i].url() + "\n"
                    datastr += name;
                }	
            }
            datastr;
        ]]
    local status, object, descriptor = hs.osascript.javascript(js)
    if status == true then
        return object
    else
        return ''
    end
end

function getSafariURLs()
    local js = [[
        var datastr = "";
        var ss = Application('Safari');
        if(ss.running){
            const firstWindow = ss.windows[0]
            var alltabs = firstWindow.tabs
            var tabLen = alltabs.length		
            for (var i = 0; i < tabLen; i++) {
                var name = alltabs[i].url() + "\n"
                datastr += name;
            }	
        }
        datastr;
    ]]
    local status, object, descriptor = hs.osascript.javascript(js)
    if status == true then
        return object;
    else
        return "";
    end
end

function saveSafariURLs(content, ws_index)
    if ws_index > 0 and ws_index <= #queryFolder then
        local file_handler = io.open(queryFolder[ws_index]['dir']..'/'..urlFile, 'w');
        file_handler:write(content);
        file_handler:close();
    end
end

function saveChromeURLs(content, ws_index)
    if ws_index > 0 and ws_index <= #queryFolder then
        local file_handler = io.open(queryFolder[ws_index]['dir']..'/'..urlFileChrome, 'w');
        file_handler:write(content);
        file_handler:close();
    end
end

function closeSafariApp()
    local app = hs.application.get('Safari')
    app:kill()
end

function closeChromeApp()
    local app = hs.application.get('Google Chrome')
    app:kill()
end

function saveWorkSpace()
    -- file = io.open(os.getenv('HOME') .. urlPath)
    local ret = getSafariURLs();
    local ret1 = getChromeURLs();
    saveSafariURLs(ret, currentWS);
    saveChromeURLs(ret1, currentWS);
end

function closeWorkSpace()
    hs.alert.show('Close Work Space');
    saveWorkSpace();
    closeSafariApp();
    closeChromeApp();
    currentWS = defaultWS_index;
    updateMenubar()
end

function updateMenubar()
    if(currentWS == defaultWS_index)then
        menubar:setTitle('x')
        menubar:setTooltip('WorkSpace Info')
    else
        menubar:setTitle(queryFolder[currentWS]['name'])
        menubar:setTooltip(queryFolder[currentWS]['name']..' WorkSpace')
    end
end

function reloadWorkSpace()
    getQueryFolder()
    rescan()
    updateMenubar()
end

function rescan()
    local menuitems_table = {}
    local submenuitem_table = {}

    for i = 1, #queryFolder do
        if queryFolder[i]['defaultws'] == false then
            table.insert(submenuitem_table, {
                title = queryFolder[i]['name'],
                fn = function() openWorkSpace(i) end
            })
        else
            defaultWS_index = i;
            currentWS = i;
        end
    end

    table.insert(menuitems_table, {
        title = 'Open WorkSpace',
        menu=submenuitem_table
    })
    table.insert(menuitems_table, {
        title = 'Close WorkSpace',
        fn = function() closeWorkSpace() end
    })
    table.insert( menuitems_table, {
        title = 'Load Personal WorkSpace',
        fn = function() openWorkSpaceURLs(defaultWS_index) end
    })
    table.insert(menuitems_table, {title = '-'})
    table.insert( menuitems_table, {
        title = 'Reload WorkSpace',
        fn = function() reloadWorkSpace() end
    })
    table.insert( menuitems_table, {
        title = 'test item',
        fn = function() openWorkSpace(1) end
    })

    menubar:setMenu(menuitems_table)
end

reloadWorkSpace()
