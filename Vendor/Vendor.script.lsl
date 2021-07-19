// NAME: Mobius Vendor
// AUTHOR: JT Eyre
// CREATED: 23/06/2021
// EDITED:
// WORLD: OpenSim
// SCRIPT ENGINE: N/A
// DESCRIPTION: 
// LICENSE: Mobius Team Resources License
//
//  These resources are provided 'as-is', without any express or implied warranty.  In no event will the authors be held liable for any damages arising from the use of these resources.
//
//  Permission is granted to anyone to use these resources for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this resource must not be misrepresented; you must not claim that you made the original resource. If you use this resource in a product, an acknowledgment in the product documentation would be appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original resource.
//
//  3. This resource is not to be used on Second Life. Only for use on Virtual Worlds based Opensim and its forks (Halcyon and Whitecore based Virtual Worlds, etc.).
//
//  4. This notice may not be removed or altered from any resource distribution.

integer currentItemNum;
string currentItemName;
key sInUse = "00000000-0000-0000-0000-000000000000"; // In Use warning Sound.
key sNext = "00000000-0000-0000-0000-000000000000"; // Next Listing Sound.
key sStartup = "00000000-0000-0000-0000-000000000000"; // Startup Sound.
key sBack = "00000000-0000-0000-0000-000000000000"; // Previous Listing Sound.
key sSold = "00000000-0000-0000-0000-000000000000"; // Sold Sound.
key sFreebie = "00000000-0000-0000-0000-000000000000"; // Delivery Sound.
list items;
list prices;
list itemDesc;
integer debitPerms;
string option1;
integer menuChannel;
list options;
integer currentItemPrice;
string config = "Vendor.cfg"; //Config file
string offPic = "offline"; //Offline texture
integer totalItems;
integer btn_back = 5;
integer btn_next = 2;
integer btn_buy = 1;
integer btn_menu = 3;
integer screen = 4;
integer ncLine;
key ncKey = NULL_KEY;
key ncQuery;
integer vendorOn;
integer lockoutTimer = 30; //Customer lockout timer in seconds.
integer lTimer;
key currentCustomer = NULL_KEY;
integer listenId;

setScreen(string texture)
{
    llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_TEXTURE,screen,llGetInventoryKey(texture),<1,1,1>,<0,0,0>,0.0]);
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
        setScreen(offPic);
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
        if(llDetectedTouchFace(0) == btn_menu && llDetectedKey(0) == llGetOwner())
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
                if(llDetectedTouchFace(0) == btn_back)
                {
                    currentItemNum--;
                    if(currentItemNum < 0)
                    {
                        currentItemNum = totalItems - 1;
                    }
                    llPlaySound(sBack,1.0);
                    string picName = llList2String(items,currentItemNum) + ".pic";
                    setScreen(picName);
                }
                else
                if(llDetectedTouchFace(0) == btn_next)
                {
                    currentItemNum++;
                    if(currentItemNum > totalItems - 1)
                    {
                        currentItemNum = 0;
                    }
                    llPlaySound(sNext,1.0);
                    string picName = llList2String(items,currentItemNum) + ".pic";
                    setScreen(picName);
                }
                if(llDetectedTouchFace(0) == btn_buy)
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
            string picName = llList2String(items,currentItemNum) + ".pic";
            setScreen(picName);
        }
        else if(message == "Turn Off")
        {
            vendorOn = FALSE;
            setScreen(offPic);
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