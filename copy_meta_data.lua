--[[----------------------------------------------------------------------------------------------------------

Jpeg2RawMetaCopy Lightoom Classic Plugin

Copyright 2023 by Frank Eberle (https://www.frank-eberle.de)

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
  and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

------------------------------------------------------------------------------------------------------------]]

local LrDialogs = import 'LrDialogs'
local LrApplication = import 'LrApplication'
local LrLogger = import 'LrLogger'
local LrTasks = import 'LrTasks'
local LrPathUtils = import "LrPathUtils"
local LrFileUtils = import "LrFileUtils"
local LrProgressScope = import "LrProgressScope"
local LrFunctionContext = import "LrFunctionContext"
local LrView = import "LrView"
local LrBinding = import "LrBinding"

-- Debugging is enabled by placing the file debug.txt in the plugin's directory.
-- If the file contents start with 'print', the output is sent to the Windows
-- debugger instead of a log file. On Windows the log file is located at
-- <UserDir>\Documents\LrClassicLogs\de.frank-eberle.Jpg2RawMetaCopy.log.
local logger = LrLogger(_PLUGIN.id)
local dbgFlagFile = LrPathUtils.child(_PLUGIN.path, "debug.txt")
if LrFileUtils.exists(dbgFlagFile) == "file" then
    local dbg = LrFileUtils.readFile(dbgFlagFile)
    if string.sub(dbg, 1, 5) == "print" then
        logger:enable('print')
    else
        logger:enable('logfile')
    end
end

--- Merge two integer-indexed tables into one table
--
-- @param t1 (table) First table
-- @param t2 (table) Second table
-- @return (table) Merged tables
local function mergeTables(t1, t2)
    local target = {}
    for _, v in ipairs(t1) do
        target[#target+1] = v
    end
    for _, v in ipairs(t2) do
        target[#target+1] = v
    end
    return target
end


--- Performs the actual meta-data copy operation
--
-- @param funcArgs (table) Table with kewyord arguments
-- @return (table) Integer-indexed table containing: number of processed images,
--   number of matched images, protocol
local function doCopy(funcArgs)
    local protocol = ""
    local processed = 0
    local matched = 0
    local copyStarRating = funcArgs.copyStarRating
    local copyColorLabel = funcArgs.copyColorLabel
    local copyGpsData = funcArgs.copyGpsData
    local copyTitle = funcArgs.copyTitle
    local copyCopyright = funcArgs.copyCopyright
    local copyCaption = funcArgs.copyCaption
    local copyPickStatus = funcArgs.copyPickStatus
    local copyKeywords = funcArgs.copyKeywords
    local dryRun = funcArgs.dryRun
    local copySettings = funcArgs.copySettings
    local catalog = LrApplication.activeCatalog()
    local photos = catalog:getTargetPhotos()
    catalog:withWriteAccessDo("copyMeta", function()
        for _, sourcePhoto in ipairs(photos) do
            if sourcePhoto:getFormattedMetadata("fileType") == "JPEG" then
                processed = processed + 1
                if funcArgs.copySettings then
                    sourcePhoto:copySettings()
                end
                local jpegName = sourcePhoto:getFormattedMetadata("fileName")
                local srcPath = LrPathUtils.child(sourcePhoto:getFormattedMetadata("folderName"), jpegName)
                local basename = LrPathUtils.removeExtension(jpegName) .. "."
                local dateTimeOriginal = sourcePhoto:getRawMetadata("dateTimeOriginal")
                if #protocol ~= 0 then
                    protocol = protocol .. "\n"
                end
                protocol = protocol .. "Source: " .. srcPath .. "\n"
                logger:debug(basename)
                local matches = catalog:findPhotos {
                    searchDesc = {
                        {
                            criteria = "filename",
                            operation = "beginsWith",
                            value = basename,
                        },
                        {
                            {
                                criteria = "fileFormat",
                                operation = "==",
                                value = "RAW",
                            },
                            {
                                criteria = "fileFormat",
                                operation = "==",
                                value = "DNG",
                            },
                            combine = "union"
                        },
                        {
                            criteria = "captureTime",
                            operation = "==",
                            value = dateTimeOriginal,
                        },
                        combine = "intersect"
                    }
                }
                if #matches > 0 then
                    local starRating = sourcePhoto:getRawMetadata("rating")
                    local colorLabel = sourcePhoto:getRawMetadata("colorNameForLabel")
                    local gps = sourcePhoto:getRawMetadata("gps")
                    local gpsAltitude = sourcePhoto:getRawMetadata("gpsAltitude")
                    local title = sourcePhoto:getFormattedMetadata("title")
                    local copyright = sourcePhoto:getFormattedMetadata("copyright")
                    local caption = sourcePhoto:getFormattedMetadata("caption")
                    local pickStatus = sourcePhoto:getRawMetadata("pickStatus")
                    local keywords = sourcePhoto:getRawMetadata("keywords")
                    for _, targetPhoto in pairs(matches) do
                        if targetPhoto:getRawMetadata("isVirtualCopy") == false then
                            matched = matched + 1
                            if funcArgs.copySettings then
                                targetPhoto:pasteSettings()
                            end            
                            local rawName = targetPhoto:getFormattedMetadata("fileName")
                            local dstPath = LrPathUtils.child(targetPhoto:getFormattedMetadata("folderName"), rawName)
                            logger:debug("Target: " .. rawName)
                            protocol = protocol .. "  Target: " .. dstPath .. "\n"
                            if not dryRun then
                                if copyStarRating then
                                    targetPhoto:setRawMetadata("rating", starRating)
                                end
                                if copyColorLabel then
                                    targetPhoto:setRawMetadata("colorNameForLabel", colorLabel)
                                end
                                if copyGpsData then
                                    targetPhoto:setRawMetadata("gps", gps)
                                    targetPhoto:setRawMetadata("gpsAltitude", gpsAltitude)
                                end
                                if copyTitle then
                                    targetPhoto:setRawMetadata("title", title)
                                end
                                if copyCaption then
                                    targetPhoto:setRawMetadata("caption", caption)
                                end
                                if copyCopyright then
                                    targetPhoto:setRawMetadata("copyright", copyright)
                                end
                                if copyPickStatus then
                                    targetPhoto:setRawMetadata("pickStatus", pickStatus)
                                end
                                if copyKeywords then
                                    for _, kw in ipairs(keywords) do
                                        targetPhoto:addKeyword(kw)
                                    end
                                end
                            end
                        end
                    end
                else
                    logger:debug("not found")
                    protocol = protocol .. "  no RAW/DNG found\n"
                end
            end
        end
    end)
    local protoHdr = ""
    if dryRun then protoHdr = protoHdr .. "!!! Dry Run !!!\n\n" end
    protoHdr = protoHdr .. string.format("Summary: %d JPEGs processed, %d RAWs matched\n\n", processed, matched)
    protoHdr = protoHdr .. "Selected meta data:\n"    
    if copyStarRating then protoHdr = protoHdr .. "  * Star Rating\n" end
    if copyColorLabel then protoHdr = protoHdr .. "  * Color Label\n" end
    if copyPickStatus then protoHdr = protoHdr .. "  * Pick Status\n" end
    if copyTitle then protoHdr = protoHdr .. "  * Title\n" end
    if copyCaption then protoHdr = protoHdr .. "  * Caption\n" end
    if copyKeywords then protoHdr = protoHdr .. "  * Keywords\n" end
    if copyCopyright then protoHdr = protoHdr .. "  * Copyright\n" end
    if copyGpsData then protoHdr = protoHdr .. "  * GPS Data\n" end
    protoHdr = protoHdr .. "\n"
    if funcArgs.copySettings then
        protoHdr = protoHdr .. "Copy Settings\n\n"
    end
    protocol =  protoHdr .. protocol
    return processed, matched, protocol
end


--- Retrieve the number of JPEG images in the current active LR selection
--
-- @return (integer) Number of JPEGs
local function countJpgInSelection()
    local count = 0
    local catalog = LrApplication.activeCatalog()
    local photos = catalog:getTargetPhotos()
    for _, sourcePhoto in ipairs(photos) do
        if sourcePhoto:getFormattedMetadata("fileType") == "JPEG" then
            count = count + 1
        end
    end
    return count
end


--- Displays a non-modal dialog to present the protocol
--
-- @param prototol (string) Protocol text to be displayed
local function protocolDialog(protocol)
    local f = LrView.osFactory()
    local close
    local dialog = f:column {
        margin = 10,
        spacing = 10,
        f:row {
            f:scrolled_view {
                width = 800,
                height = 500,
                horizontal_scroller = true,
                vertical_scroller,
                f:static_text  {
                    title = protocol
                },
            }
        },
        f:row {
            f:push_button {
                place_horizontal = 1,
                title = "Close",
                action = function()
                    close()
                end
            }
        }
    }
    LrDialogs.presentFloatingDialog(
        _PLUGIN,
        {
            title = "Protocol",
            contents = dialog,
            blockTask = true,
            onShow = function(winFuncs)
                close = winFuncs.close
            end
        }
    )
end


--- Displays a modal dialog presenting the options for the copy operation
--
-- A property table must be passed to the function. The property table
-- contains the initial state/contents of the input elements. It is also used
-- to return the user's selection.

-- @param properties (table) Property table to be bound to the input form
-- @return (boolean) TRUE if the OK button was pressed, FALSE otherwise.
local function settingsDialog(properties)
    local f = LrView.osFactory()
    local dialog = f:column {
        bind_to_object = properties,
        width = 600,
        f:group_box {
            title = "Meta Data",
            fill_horizontal = 1,
            spacing = f:control_spacing(),
            f:row {
                f:column {
                    f:checkbox {
                        title = "Star Rating",
                        value = LrView.bind("copyStarRating"),
                    },
                    f:checkbox {
                        title = "Color Label",
                        value = LrView.bind("copyColorLabel"),
                    },    
                    f:checkbox {
                        title = "Pick Status",
                        value = LrView.bind("copyPickStatus"),
                    },    
                },
                f:column {
                    f:checkbox {
                        title = "Title",
                        value = LrView.bind("copyTitle"),
                    },
                    f:checkbox {
                        title = "Caption",
                        value = LrView.bind("copyCaption"),
                    },
                    f:checkbox {
                        title = "Keywords",
                        value = LrView.bind("copyKeywords"),
                    },    
                    f:checkbox {
                        title = "Copyright",
                        value = LrView.bind("copyCopyright"),
                    },    
                },
                f:column {
                    f:checkbox {
                        title = "GPS Data",
                        value = LrView.bind("copyGpsData"),
                    },    
                }
            }
        },
        f:group_box {
            title = "Options",
            fill_horizontal = 1,
            spacing = f:control_spacing(),
            f:row {
                f:column {
                    f:checkbox {
                        title = "Show Protocol",
                        value = LrView.bind("showProtocol"),
                    },        
                    f:checkbox {
                        title = "Dry-Run",
                        value = LrView.bind("dryRun"),
                    },        
                },
                f:column {
                    f:checkbox {
                        title = "Copy Settings",
                        value = LrView.bind("copySettings"),
                    },        
                },
            }
        }
    }
    local res = LrDialogs.presentModalDialog(
        {
            title = "Copy Meta Data",
            contents = dialog,
        }
    )
    return "ok" == res
end


--- Plugin's main function
--
local function main()
    logger:debug("main() begin")
    LrFunctionContext.postAsyncTaskWithContext("copyMeta", function(context)
        context:addFailureHandler(function(status, err)
            LrDialogs.message("Internal Error: " .. err)
        end)
        if countJpgInSelection() == 0 then
            LrDialogs.message("No JPEG(s) selected", nil, "info")
        else
            local properties = LrBinding.makePropertyTable(context)
            properties.showProtocol = false
            properties.dryRun = false
            properties.copySettings = false
            local options = {"dryRun", "copySettings"}
            local metaTypes = {"copyStarRating", "copyColorLabel", "copyTitle", "copyGpsData",
              "copyKeywords", "copyCaption", "copyPickStatus", "copyCopyright"}
            for _, key in ipairs(metaTypes) do
                properties[key] = true
            end
            local res = settingsDialog(properties)
            if res then
                args = {}
                for _, key in ipairs(mergeTables(options, metaTypes)) do
                    logger:debug("Arg: " .. key)
                    logger:debug(properties[key])
                    args[key] = properties[key]
                end
                local processed, matched, protocol = doCopy(args)
                if properties.showProtocol then
                    protocolDialog(protocol)
                else
                    LrDialogs.showBezel(string.format("Completed: %d JPEGs processed, %d RAWs matched", processed, matched), 5)
                end
            end
        end
        logger:debug("main() end")
    end)
end


main()