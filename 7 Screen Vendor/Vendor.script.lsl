//start_unprocessed_text
/*/|/ NAME: MultiScreen Mobius Vendor
/|/ AUTHOR: JT Eyre
/|/ CREATED: 23/06/2021
/|/ EDITED: By LGG on 31/07/2022
/|/ WORLD: OpenSim
/|/ SCRIPT ENGINE: N/A
/|/ DESCRIPTION: 
/|/ LICENSE: Mobius Team Resources License
/|/
/|/  These resources are provided 'as-is', without any express or implied warranty.  In no event will the authors be held liable for any damages arising from the use of these resources.
/|/
/|/  Permission is granted to anyone to use these resources for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
/|/
/|/  1. The origin of this resource must not be misrepresented; you must not claim that you made the original resource. If you use this resource in a product, an acknowledgment in the product documentation would be appreciated but is not required.
/|/
/|/  2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original resource.
/|/
/|/  3. This resource is not to be used on Second Life. Only for use on Virtual Worlds based Opensim and its forks (Consortium, Halcyon, Sasquatch and Whitecore based Virtual Worlds, etc.).
/|/
/|/  4. This notice may not be removed or altered from any resource distribution.
#define USE_LAZY_LISTS
integer currentItemNum;
string currentItemName;
key sInUse = "fd0270e0-d890-46bf-a169-27485aef60c2"; /|/ In Use warning Sound.
key sNext = "d175326f-c937-444d-934b-ce9b13696244"; /|/ Next Listing Sound.
key sStartup = "076ab793-a249-468c-95e0-3f8e1e431a2e"; /|/ Startup Sound.
key sBack = "88ff55f6-fb99-4e0f-956b-edcb175c0635"; /|/ Previous Listing Sound.
key sSold = "6d9b7f65-d6e3-4fa1-b2de-70a3543988d1"; /|/ Sold Sound.
key sFreebie = "2f876f97-bc78-4138-9e22-766ad9d4c5d6"; /|/ Delivery Sound.
list items;
list prices;
list itemDesc;
integer debitPerms;
string option1;
integer menuChannel;
list options;
integer currentItemPrice;
string config = "*|*|*Vendor.cfg"; /|/Config file
string offPic = "*offline"; /|/Offline texture
integer totalItems;
/|/Button detection is now done via prim number and face, stored as vectors where x is the prim, and y is the face (or -1 for all faces)
#define btn_back <4,-1,0>
#define btn_next <3,-1,0>
#define btn_buy <2,-1,0>
#define btn_menu <7,-1,0>
#define screen <6,1,0>
list screens = [
<6,5,0>,
<6,6,0>,
<6,7,0>,
<6,2,0>,
<6,3,0>,
<6,4,0>
];
list screensChangedAmount = [
-1,
-2,
-3,
1,
2,
3
];
integer ncLine;
key ncKey = NULL_KEY;
key ncQuery;
integer vendorOn;
integer lockoutTimer = 60; /|/Customer lockout timer in seconds.
integer lTimer;
key currentCustomer = NULL_KEY;
integer listenId;

vector getScreenCord(integer screenNumber) {
    vector toUse;
    if(screenNumber == 0){
        toUse = screen;
    }else
    {
        toUse = (vector)screens[screenNumber-1];
        
    }
    return toUse;    
}

integer checkCords(integer primNumberTouched, integer faceNumberTouched, vector toCheck){
    if(primNumberTouched == (integer)toCheck.x && ( (integer)toCheck.y == -1 || faceNumberTouched ==  (integer)toCheck.y)){
        return 1;
    }
    return 0;
}

integer getScreensChangedAmount(integer screenNumber){
    return (integer)screensChangedAmount[screenNumber-1];
}

string getButtonName(integer primNumberTouched, integer faceNumberTouched){
    /|/llSay(0,"Checking "+(string)primNumberTouched+" and "+(string)faceNumberTouched);
    if(checkCords(primNumberTouched,faceNumberTouched,btn_back)){
        return "btn_back";
    }
    if(checkCords(primNumberTouched,faceNumberTouched,btn_next)){
        return "btn_next";
    }
    if(checkCords(primNumberTouched,faceNumberTouched,btn_buy)){
        return "btn_buy";
    }
    if(checkCords(primNumberTouched,faceNumberTouched,btn_menu)){
        return "btn_menu";
    }
    return "";    
}

integer getScreenNumberClicked(integer primNumberTouched, integer faceNumberTouched){
    integer i;
    integer max = llGetListLength(screens);
    for(i=0;i<=max;i++){
        vector toUse = getScreenCord(i);
        if(checkCords(primNumberTouched,faceNumberTouched,toUse))
        {
            return i;
        }
    }
    return -1;    
}

setScreen(string texture)
{
    setScreenNumber(0,texture);
}
setScreenNumber(integer screenNumber,string texture)
{
    vector toUse = getScreenCord(screenNumber);
    llSetLinkPrimitiveParamsFast((integer)toUse.x,[PRIM_TEXTURE,(integer)toUse.y,llGetInventoryKey(texture),<1,1,1>,<0,0,0>,0.0]);
}
setAllScreens(string texture)
{
    vector toUse = getScreenCord(0);
    llSetLinkPrimitiveParamsFast((integer)toUse.x,[PRIM_TEXTURE,(integer)toUse.y,llGetInventoryKey(texture),<1,1,1>,<0,0,0>,0.0]);
    integer i;
    integer max = llGetListLength(screens);
    for(i=0;i<=max;i++){
         vector toUse = getScreenCord(i);
        llSetLinkPrimitiveParamsFast((integer)toUse.x,[PRIM_TEXTURE,(integer)toUse.y,llGetInventoryKey(texture),<1,1,1>,<0,0,0>,0.0]);
    }
}

/|/Gives you the texture name, but also makes sure itemNumber is in range of 0 to totalItems
string getImageInRange(integer itemNumber){    
    return llList2String(items,getInRange(itemNumber)) + ".pic";    
}
integer getInRange(integer itemNumber){
    while(itemNumber <0){
        itemNumber += totalItems;
    }
    while(itemNumber >= totalItems){
        itemNumber -= totalItems;
    }
    return itemNumber;
}

showPicDisplayFor(integer currentItemNumber){
    setScreenNumber(0,getImageInRange(currentItemNumber));
    integer i;
    integer max = llGetListLength(screens);
    for(i=1;i<=max;i++){        
        setScreenNumber(i,getImageInRange(currentItemNumber+getScreensChangedAmount(i)));
    }    
}

initNC()
{
    key nc = llGetInventoryKey(config);
    if(nc == ncKey)
    {
        return;
    }
    ncKey = nc;
    ncLine = 0;
    ncQuery = llGetNotecardLine(config,ncLine);
}

default
{
    state_entry()
    {
        llPreloadSound(sInUse);
        llPreloadSound(sNext);
        llPreloadSound(sBack);
        llPreloadSound(sSold);
        llPreloadSound(sStartup);
        llPreloadSound(sFreebie);
        llSetClickAction(CLICK_ACTION_TOUCH);
        menuChannel = -1 - (integer)("0x" + llGetSubString( (string)llGetKey(), -7, -1) );
        totalItems = 0;
        initNC();
        llRequestPermissions(llGetOwner(), PERMISSION_DEBIT);
        currentItemNum = 0;
        setAllScreens(offPic);
    }
    run_time_permissions (integer perm)
    {
        if  (perm & PERMISSION_DEBIT)
            debitPerms = TRUE;
    }
    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llResetScript();
        }
        if(change & CHANGED_INVENTORY)
        {
            llOwnerSay("Inventory changed! Please ensure new stock is added to config notecard and select 'reload notecard' from controller menu when finished.");
        }
    }
    dataserver(key query_id,string data)
    {
        if(query_id == ncQuery)
        {
            if(data == EOF)
            {
                llOwnerSay("Vendor config loaded. Please click controller menu and select 'Turn On' to enable vendor.");
            }
            else
            {
                if(llSubStringIndex(data,"#") == -1 && llStringLength(data) > 0)
                {
                    list sData = llParseString2List(data," | ",[""]);
                    itemDesc += llList2String(sData,0);
                    items += llList2String(sData,1);
                    prices += llList2Integer(sData,2);
                    totalItems++;
                }
                ++ncLine;
                ncQuery = llGetNotecardLine(config,ncLine);
            }
        }
    }
    touch_start(integer num_detected)
    {
        string btnName = getButtonName(llDetectedLinkNumber(0),llDetectedTouchFace(0));
        if(btnName == "btn_menu" && llDetectedKey(0) == llGetOwner())
        {
            if(vendorOn == TRUE)
            {
                option1 = "Turn Off";
            }
            else
            {
                option1 = "Turn On";
            }
            options = [option1, "Reset Script", "Reload Notecard"];
            llDialog(llDetectedKey(0),"Welcome to the Mobius Vendor Menu. Please select an option.",options,menuChannel);
            listenId = llListen(menuChannel,"", llDetectedKey(0),"");
        }
        if(vendorOn == TRUE)
        {
            integer screenNumberClicked = getScreenNumberClicked(llDetectedLinkNumber(0),llDetectedTouchFace(0));
            if(screenNumberClicked!=-1){
                /|/llSay(0,"Screen clicked: #"+(string)screenNumberClicked);
                integer changeAmount = getScreensChangedAmount(screenNumberClicked);
                currentItemNum = getInRange(currentItemNum+changeAmount);
                llPlaySound(sNext,1.0);
                showPicDisplayFor(currentItemNum);
            }
            if(currentCustomer == NULL_KEY)
            {
                llSetClickAction(CLICK_ACTION_TOUCH);
                currentCustomer = llDetectedKey(0);
                lTimer = lockoutTimer;
                llSetTimerEvent(1.0);
            }
            if(llDetectedKey(0) == currentCustomer)
            {
                llSetClickAction(CLICK_ACTION_TOUCH);
                if(btnName == "btn_back")
                {
                    currentItemNum = getInRange(currentItemNum-1);
                    llPlaySound(sBack,1.0);
                    showPicDisplayFor(currentItemNum);
                }
                else
                if(btnName == "btn_next")
                {
                    currentItemNum = getInRange(currentItemNum+1);
                    llPlaySound(sNext,1.0);
                    showPicDisplayFor(currentItemNum);
                }
                if(btnName == "btn_buy")
                {
                    if(llList2Integer(prices,currentItemNum) > 0)
                    {
                        llSetPayPrice(llList2Integer(prices,currentItemNum),[llList2Integer(prices,currentItemNum),PAY_HIDE,PAY_HIDE,PAY_HIDE]);
                        llSetClickAction(CLICK_ACTION_PAY);
                        llInstantMessage(llDetectedKey(0),"Please click again to pay.");
                    }
                    else
                    {
                        llInstantMessage(currentCustomer,"Thanks! Enjoy your free item.");
                        llGiveInventory(currentCustomer,llList2String(items,currentItemNum));
                        llPlaySound(sFreebie,1.0);
                    }
                }
                lTimer = lockoutTimer;
            }
            else
            {
                llInstantMessage(llDetectedKey(0),"This vendor is currently in use. Please try again when it's free.");
            }
        }
    }
    money(key id, integer amount)
    {
        if(id == currentCustomer)
        {
            llInstantMessage(id, "Thank you for your purchase! Your item will be delivered shortly.");
            if(amount == llList2Integer(prices,currentItemNum))
            {
                llGiveInventory(id,llList2String(items,currentItemNum));
                llSetClickAction(CLICK_ACTION_TOUCH);
                llPlaySound(sSold,1.0);
                llSleep(1.0);
                llPlaySound(sFreebie,1.0);
            }
            else
            {
                llGiveMoney(id, amount);
                llInstantMessage(id, "That is not the correct amount. You have been refunded.");
                llPlaySound(sInUse,1.0);
            }
        }
        else
        {
            llGiveMoney(id, amount);
            llInstantMessage(id, "Please allow the current customer to finish shopping.");
            llPlaySound(sInUse,1.0);
        }
    }
    timer()
    {
        if(lTimer > 0)
        {
            lTimer--;
        }
        else
        {
            currentCustomer = NULL_KEY;
            llSay(0,"This vendor is now open.");
            llPlaySound(sStartup,1.0);
            llSetTimerEvent(0.0);
            llSetClickAction(CLICK_ACTION_TOUCH);
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        if(message == "Turn On")
        {
            vendorOn = TRUE;
            llPlaySound(sStartup,1.0);
            currentItemNum = 0;
            showPicDisplayFor(currentItemNum);
        }
        else if(message == "Turn Off")
        {
            vendorOn = FALSE;
            setAllScreens(offPic);
        }
        else if(message = "Reset Script")
        {
            llResetScript();
        }
        else if(message = "Reload Notecard")
        {
            initNC();
        }
    }
}*/
//end_unprocessed_text
//nfo_preprocessor_version 0
//program_version Firestorm-Releasex64 6.5.6.66221 - L GG
//last_compiled 07/31/2022 15:06:03
//mono
























//#line 22 "C:\\Program Files\\FirestormOS-Releasex64\\***Vendor.script"
integer currentItemNum;
key sInUse = "fd0270e0-d890-46bf-a169-27485aef60c2"; 
key sNext = "d175326f-c937-444d-934b-ce9b13696244"; 
key sStartup = "076ab793-a249-468c-95e0-3f8e1e431a2e"; 
key sBack = "88ff55f6-fb99-4e0f-956b-edcb175c0635"; 
key sSold = "6d9b7f65-d6e3-4fa1-b2de-70a3543988d1"; 
key sFreebie = "2f876f97-bc78-4138-9e22-766ad9d4c5d6"; 
list items;
list prices;
list itemDesc;
integer debitPerms;
string option1;
integer menuChannel;
list options;
string config = "***Vendor.cfg"; 
string offPic = "*offline"; 
integer totalItems;

//#line 47 "C:\\Program Files\\FirestormOS-Releasex64\\***Vendor.script"
list screens = [
<6,5,0>,
<6,6,0>,
<6,7,0>,
<6,2,0>,
<6,3,0>,
<6,4,0>
];
list screensChangedAmount = [
-1,
-2,
-3,
1,
2,
3
];
integer ncLine;
key ncKey = NULL_KEY;
key ncQuery;
integer vendorOn;
integer lockoutTimer = 60; 
integer lTimer;
key currentCustomer = NULL_KEY;
integer listenId;
setScreenNumber(integer screenNumber,string texture)
{
    vector toUse = getScreenCord(screenNumber);
    llSetLinkPrimitiveParamsFast((integer)toUse.x,[PRIM_TEXTURE,(integer)toUse.y,llGetInventoryKey(texture),<1,1,1>,<0,0,0>,0.0]);
}

vector getScreenCord(integer screenNumber) {
    vector toUse;
    if(screenNumber == 0){
        toUse = <6,1,0>;
    }else
    {
        toUse = llList2Vector(screens,screenNumber-1);
        
    }
    return toUse;    
}


string getImageInRange(integer itemNumber){    
    return llList2String(items,getInRange(itemNumber)) + ".pic";    
}

integer checkCords(integer primNumberTouched, integer faceNumberTouched, vector toCheck){
    if(primNumberTouched == (integer)toCheck.x && ( (integer)toCheck.y == -1 || faceNumberTouched ==  (integer)toCheck.y)){
        return 1;
    }
    return 0;
}

showPicDisplayFor(integer currentItemNumber){
    setScreenNumber(0,getImageInRange(currentItemNumber));
    integer i;
    integer max = llGetListLength(screens);
    for(i=1;i<=max;i++){        
        setScreenNumber(i,getImageInRange(currentItemNumber+getScreensChangedAmount(i)));
    }    
}
setAllScreens(string texture)
{
    vector toUse = getScreenCord(0);
    llSetLinkPrimitiveParamsFast((integer)toUse.x,[PRIM_TEXTURE,(integer)toUse.y,llGetInventoryKey(texture),<1,1,1>,<0,0,0>,0.0]);
    integer i;
    integer max = llGetListLength(screens);
    for(i=0;i<=max;i++){
         vector toUse = getScreenCord(i);
        llSetLinkPrimitiveParamsFast((integer)toUse.x,[PRIM_TEXTURE,(integer)toUse.y,llGetInventoryKey(texture),<1,1,1>,<0,0,0>,0.0]);
    }
}

initNC()
{
    key nc = llGetInventoryKey(config);
    if(nc == ncKey)
    {
        return;
    }
    ncKey = nc;
    ncLine = 0;
    ncQuery = llGetNotecardLine(config,ncLine);
}

integer getScreensChangedAmount(integer screenNumber){
    return llList2Integer(screensChangedAmount,screenNumber-1);
}

integer getScreenNumberClicked(integer primNumberTouched, integer faceNumberTouched){
    integer i;
    integer max = llGetListLength(screens);
    for(i=0;i<=max;i++){
        vector toUse = getScreenCord(i);
        if(checkCords(primNumberTouched,faceNumberTouched,toUse))
        {
            return i;
        }
    }
    return -1;    
}
integer getInRange(integer itemNumber){
    while(itemNumber <0){
        itemNumber += totalItems;
    }
    while(itemNumber >= totalItems){
        itemNumber -= totalItems;
    }
    return itemNumber;
}

string getButtonName(integer primNumberTouched, integer faceNumberTouched){
    
    if(checkCords(primNumberTouched,faceNumberTouched,<4,-1,0>)){
        return "btn_back";
    }
    if(checkCords(primNumberTouched,faceNumberTouched,<3,-1,0>)){
        return "btn_next";
    }
    if(checkCords(primNumberTouched,faceNumberTouched,<2,-1,0>)){
        return "btn_buy";
    }
    if(checkCords(primNumberTouched,faceNumberTouched,<7,-1,0>)){
        return "btn_menu";
    }
    return "";    
}

default
{
    state_entry()
    {
        llPreloadSound(sInUse);
        llPreloadSound(sNext);
        llPreloadSound(sBack);
        llPreloadSound(sSold);
        llPreloadSound(sStartup);
        llPreloadSound(sFreebie);
        llSetClickAction(CLICK_ACTION_TOUCH);
        menuChannel = -1 - (integer)("0x" + llGetSubString( (string)llGetKey(), -7, -1) );
        totalItems = 0;
        initNC();
        llRequestPermissions(llGetOwner(), PERMISSION_DEBIT);
        currentItemNum = 0;
        setAllScreens(offPic);
    }
    run_time_permissions (integer perm)
    {
        if  (perm & PERMISSION_DEBIT)
            debitPerms = TRUE;
    }
    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llResetScript();
        }
        if(change & CHANGED_INVENTORY)
        {
            llOwnerSay("Inventory changed! Please ensure new stock is added to config notecard and select 'reload notecard' from controller menu when finished.");
        }
    }
    dataserver(key query_id,string data)
    {
        if(query_id == ncQuery)
        {
            if(data == EOF)
            {
                llOwnerSay("Vendor config loaded. Please click controller menu and select 'Turn On' to enable vendor.");
            }
            else
            {
                if(llSubStringIndex(data,"#") == -1 && llStringLength(data) > 0)
                {
                    list sData = llParseString2List(data," | ",[""]);
                    itemDesc += llList2String(sData,0);
                    items += llList2String(sData,1);
                    prices += llList2Integer(sData,2);
                    totalItems++;
                }
                ++ncLine;
                ncQuery = llGetNotecardLine(config,ncLine);
            }
        }
    }
    touch_start(integer num_detected)
    {
        string btnName = getButtonName(llDetectedLinkNumber(0),llDetectedTouchFace(0));
        if(btnName == "btn_menu" && llDetectedKey(0) == llGetOwner())
        {
            if(vendorOn == TRUE)
            {
                option1 = "Turn Off";
            }
            else
            {
                option1 = "Turn On";
            }
            options = [option1, "Reset Script", "Reload Notecard"];
            llDialog(llDetectedKey(0),"Welcome to the Mobius Vendor Menu. Please select an option.",options,menuChannel);
            listenId = llListen(menuChannel,"", llDetectedKey(0),"");
        }
        if(vendorOn == TRUE)
        {
            integer screenNumberClicked = getScreenNumberClicked(llDetectedLinkNumber(0),llDetectedTouchFace(0));
            if(screenNumberClicked!=-1){
                
                integer changeAmount = getScreensChangedAmount(screenNumberClicked);
                currentItemNum = getInRange(currentItemNum+changeAmount);
                llPlaySound(sNext,1.0);
                showPicDisplayFor(currentItemNum);
            }
            if(currentCustomer == NULL_KEY)
            {
                llSetClickAction(CLICK_ACTION_TOUCH);
                currentCustomer = llDetectedKey(0);
                lTimer = lockoutTimer;
                llSetTimerEvent(1.0);
            }
            if(llDetectedKey(0) == currentCustomer)
            {
                llSetClickAction(CLICK_ACTION_TOUCH);
                if(btnName == "btn_back")
                {
                    currentItemNum = getInRange(currentItemNum-1);
                    llPlaySound(sBack,1.0);
                    showPicDisplayFor(currentItemNum);
                }
                else
                if(btnName == "btn_next")
                {
                    currentItemNum = getInRange(currentItemNum+1);
                    llPlaySound(sNext,1.0);
                    showPicDisplayFor(currentItemNum);
                }
                if(btnName == "btn_buy")
                {
                    if(llList2Integer(prices,currentItemNum) > 0)
                    {
                        llSetPayPrice(llList2Integer(prices,currentItemNum),[llList2Integer(prices,currentItemNum),PAY_HIDE,PAY_HIDE,PAY_HIDE]);
                        llSetClickAction(CLICK_ACTION_PAY);
                        llInstantMessage(llDetectedKey(0),"Please click again to pay.");
                    }
                    else
                    {
                        llInstantMessage(currentCustomer,"Thanks! Enjoy your free item.");
                        llGiveInventory(currentCustomer,llList2String(items,currentItemNum));
                        llPlaySound(sFreebie,1.0);
                    }
                }
                lTimer = lockoutTimer;
            }
            else
            {
                llInstantMessage(llDetectedKey(0),"This vendor is currently in use. Please try again when it's free.");
            }
        }
    }
    money(key id, integer amount)
    {
        if(id == currentCustomer)
        {
            llInstantMessage(id, "Thank you for your purchase! Your item will be delivered shortly.");
            if(amount == llList2Integer(prices,currentItemNum))
            {
                llGiveInventory(id,llList2String(items,currentItemNum));
                llSetClickAction(CLICK_ACTION_TOUCH);
                llPlaySound(sSold,1.0);
                llSleep(1.0);
                llPlaySound(sFreebie,1.0);
            }
            else
            {
                llGiveMoney(id, amount);
                llInstantMessage(id, "That is not the correct amount. You have been refunded.");
                llPlaySound(sInUse,1.0);
            }
        }
        else
        {
            llGiveMoney(id, amount);
            llInstantMessage(id, "Please allow the current customer to finish shopping.");
            llPlaySound(sInUse,1.0);
        }
    }
    timer()
    {
        if(lTimer > 0)
        {
            lTimer--;
        }
        else
        {
            currentCustomer = NULL_KEY;
            llSay(0,"This vendor is now open.");
            llPlaySound(sStartup,1.0);
            llSetTimerEvent(0.0);
            llSetClickAction(CLICK_ACTION_TOUCH);
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        if(message == "Turn On")
        {
            vendorOn = TRUE;
            llPlaySound(sStartup,1.0);
            currentItemNum = 0;
            showPicDisplayFor(currentItemNum);
        }
        else if(message == "Turn Off")
        {
            vendorOn = FALSE;
            setAllScreens(offPic);
        }
        else if(message = "Reset Script")
        {
            llResetScript();
        }
        else if(message = "Reload Notecard")
        {
            initNC();
        }
    }
}

