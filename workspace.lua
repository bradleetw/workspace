local menubar = hs.menubar.new()
local menuData = {}
local urlPath = '/.workspaces'
local urlFile = '/urls.txt'
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
    if currentWS == WSindex then
        return
    end
    hs.alert.show('Open '..queryFolder[WSindex]['name']..' Work Space.')
    for url in io.lines(queryFolder[WSindex]['dir']..urlFile) do
        hs.urlevent.openURLWithBundle(url, 'com.apple.Safari')
    end
    currentWS = WSindex
    updateMenubar()
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
        local file_handler = io.open(queryFolder[ws_index]['dir']..urlFile, 'w');
        file_handler:write(content);
        file_handler:close();
        closeSafariApp();
    end
end

function closeSafariApp()
    local app = hs.application.get('Safari')

    app:kill()
end

function saveWorkSpace()
    -- file = io.open(os.getenv('HOME') .. urlPath)
    local ret = getSafariURLs();
    saveSafariURLs(ret, currentWS)
    -- hs.alert.show('Save Work Space.')
    -- currentWS = 0
    -- updateMenubar()
end

function closeWorkSpace()
    hs.alert.show('Close Work Space');
    -- openWorkSpaceURLs(defaultWS_index);
    saveWorkSpace();
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
                fn = function() openWorkSpaceURLs(i) end
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

    menubar:setMenu(menuitems_table)
end

reloadWorkSpace()
