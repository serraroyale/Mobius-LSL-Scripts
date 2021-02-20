// NAME: Mobius Four in a Row Table
// AUTHOR: LGG (lgg.greg@gmail.com)
// CREATED: 10/Feb/2021
// EDITED:
// WORLD: OpenSim
// SCRIPT ENGINE: YEngine with yoptions advflowctl, arrays, objects & norighttoleft
// DESCRIPTION: Written by LGG Greg aka L.GG @main.mobiusgrid.us under commision for royale.mobian @main.mobiusgrid.us
// This could be optomized a bunch, please do it and let me know!
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
//
//This is a script for a 2 player four in a row game
//Each turn, the alternating player gets to choose a column to drop a "checker"
//of their color.  If four of their checkers line up, they win the game

//Specify the yoptions we need
yoption arrays; //We use associative arrays instead of lists
yoption norighttoleft; //This is just a flat performance bonus by properly using parenthesis
yoption objects; //This is so we can use classes, we have one for the board representation, and one for the checker
yoption advflowctl; //This is so we can break out of loops

//Try to keep global vars to a minimum.
//The board object, touch and sitting inputs are sent to it
Board board;
//Easy way to define and change colors here
vector redColor = <1,0,0>;
vector yellowColor = <1,1,0>;

//This represents a single checker, and has functions to make them easier to code laterr
class Checker {
    //Variables the checker object will keep track of for us
    //The LL prim number for use in llSetLinkPrimitiveParams
    public integer primNumber;
    //This is more for identification and setup, apears in debug input, starts at 0 and each new checker has an incrimented number
    public integer checkerNumber;
    //Boolean if we are red or not checker
    public integer red = -1;
    //board starts at 0,0 and goes to 5,6 .  this is this checker's current location
    public vector boardLocation=<-1,-1,0>;
    //We dont need this, but it is nice to have for debug, save the llGetLinkPrimitiveParams here in case we need to check it later
    private list primInfo = [];
    //This is a boolean for debug if we should show text above the checker to see information in it
    private integer showInfo = 0;

    //This is the function to make a new checker, we require a prim number and checker number as inputs to create one
    public constructor(integer c, integer p) {
        //Take the function inputs and assign them to class variables
        this.primNumber = p;
        this.checkerNumber = c;
        this.primInfo = llGetLinkPrimitiveParams (this.primNumber, [ PRIM_NAME, PRIM_POS_LOCAL, PRIM_ROT_LOCAL, PRIM_DESC ]);
    }
    
    //helping getter to return the vector of the location pos that we retrieved earlier in this.primInfo 
    public vector getLocalPos()
    {
       return (vector)  this.primInfo[1];
    }

    //Public function that can be called to change this checkers location, and animate to it
    public setBoardLocation(vector bl)
    {
        this.boardLocation = bl;
        this.setState();
    }
    //This is a helper function to print out some information as a string if we need it for debugging
    public string toString()
    {
        return "Checker[checker#='"+this.checkerNumber+"', prim#='"+this.primNumber+"'] "
            +" @ "+(string)this.getLocalPos()
            ;
    }

    //This translates a board position <0,0,0> to <5,6,0> into an actual localPosition above the table in SL 
    public vector positionToLocalLocation(vector p)
    {
        //How far apart the pieces should be in each position change
        float incriment =.109;
        //X location of first checker
        float xstart = -0.3306915;
        //Y location of first checker
        float ystart = .195488;
        //Static Z location (note, we flip x and y here, its just easier to make Z be static as it is last)
        float z = .0032327;
        integer xpos = p.x;
        integer ypos = p.y;
        //Calculate our location position, start at xstart, then go up one incriment for each p.x, etc
        vector pos = <xstart+(incriment*xpos),z,ystart+(incriment*ypos)>;
        //If our position is not valid, hide the prim under the table
        if(p.x<0)pos = <0,0,0>;
        return pos;
    }

    //Should be called after a change in state, to actually apply it (move the prim, etc)
    public setState()
    {
        this.setPosition(this.boardLocation,1);
    }

    //Static function to move this checker to a new board location, sets all prim info as well
    public setPosition(vector boardLocation, integer animate)
    {
        //Store the color we want in a single variable for later
        vector color = yellowColor;
        if(this.red){
            color = redColor;
        }
        //We can do an animation where we move the prim to the right column,
        //but a higher height, and then lower it one step at a time
        if(animate)
        {
            //first move to top
            integer animationHeight =7;
            //keep the column (x) but have a large y (height, row)
            vector animationLocation = <boardLocation.x,animationHeight,0>;
            //First animation step is special and makes it invisble
            llSetLinkPrimitiveParamsFast(this.primNumber,
                [
                PRIM_POS_LOCAL,
                //use our function to change a board location to a true local SL position
                //use the animationLocation instead of the final board location
                this.positionToLocalLocation(animationLocation),
                PRIM_COLOR,    ALL_SIDES,color,0.0,//Set the color, but also 0 alpha to make it invisible
                //We want it invisible first so that we do not see it as it moves to the top from the bottom hidden location

                PRIM_GLOW, ALL_SIDES, 0.0,//no glow, just in case there was one

                PRIM_TEXT, this.checkerNumber +" @ "+this.boardLocation, color, this.showInfo//if this.showInfo is 0, no text
                ]
                );
            //pause a moment before each change, otherwize it goes too fast
            llSleep(.4);
            //Start at a large (7) animation height, then lower it one at a time till we reach the target height (aka row, aka y)
            for(; animationHeight > boardLocation.y; --animationHeight)
            {
                //Normal animation frame, apply the new height, and then set it
                animationLocation = <boardLocation.x,animationHeight,0>;
                llSetLinkPrimitiveParamsFast(this.primNumber,
                    [
                        PRIM_POS_LOCAL,
                        this.positionToLocalLocation(animationLocation),

                        PRIM_COLOR,
                        ALL_SIDES,color,1.0,//Fully visible now
    
                        PRIM_GLOW, ALL_SIDES, 0.0,
    
                        PRIM_TEXT, this.checkerNumber +" @ "+this.boardLocation, color, this.showInfo
                    ]
                    );
                //pause a moment before each change, otherwize it goes too fast
                llSleep(.2);
            }
        }
        //Any animation if requested is complete, set the final location and color
        llSetLinkPrimitiveParamsFast(this.primNumber,
            [
            PRIM_POS_LOCAL,
            this.positionToLocalLocation(boardLocation),
            PRIM_COLOR,ALL_SIDES,color,1.0,
            PRIM_GLOW, ALL_SIDES, 0.0,
            PRIM_TEXT, this.checkerNumber +" @ "+this.boardLocation, color, this.showInfo
            ]
            );
    }
    
    //This is mostly used in setup, and to debug and make sure that we can move a prim to each location properly
    //We give this checker a board location based on it's number, and then set it to make sure each board location is filled by some checker
    public setDefaultPosition(integer offset)
    {
        //There is an animation that can be called by changing the offset, we just increase our checker number by it 
        integer fullOffset = this.checkerNumber+(offset*7);
        if(offset==7)
        {
            //If a high offset is given, also set a random color for animation effects, do not re-randomize for lower offset so it appears that we move
            this.red = llFrand(2)>1;
        }
        //Generate a unique board position based off our number
        vector fakePosition = <fullOffset % 7,llFloor(fullOffset/7),0>;
        if(offset<0)
        {
            //offset of -1 is set before the game is start, set a fake position to hide the prim
            fakePosition = <-1,-1,0>;
        }
        //go to that position
        this.setPosition(fakePosition,0);
    }
}

//This is our main object, tracks and acts on user input, loads up the board from SL names, and monitors it
class Board {
    //Main variable to keep track of the full state of the board
    //this will be an array of columns
    //and each column will be an array of rows and each row will just be an int of what color checker is there,
    //or -1 for nothing
    public array columns;
    //Keeps track of our checker objects for use later
    public array checkers;
    //We use a new checker each time a turn happens, so keep track of how far through our array we are so we can get the next
    public integer currentCheckerNumber = -1;
    //This is an array of the prim numbers of the invisible touchable prims above the game that the users click to drop a checker
    public array locationIndicators;
    //Keep track of the prim number of the reset button and chairs so we can detect if they are clicked later
    public integer resetButtonPrimNumber;
    public integer redChairPrimNumber;
    public integer blackChairPrimNumber;
    //Keep track of the keys of the people sitting in each chair
    public key blackPlayer;
    public key redPlayer;
    //Represents if there is a user in each chair, and that the board should be locked from all outside input other than from these players
    public integer locked = 0;
    //This is a debug variable to help us make sure the calculations on if the game has been won, are sane
    public integer maxConnectionsFound = 0;
    //Boolean for if the game is over, to stop further player input
    public integer gameOver = 0;
    //Boolean for controlling who's turn it is
    public integer turnIsBlack = 1;

    //Static prim names to help scan linked objects and populate the above prim numbers
    private string checkersName = "Checkers#1";
    private string indicatorName = "slot";
    private string resetButtonName = "resetbutton";
    private string blackChairName = "blackchair";
    private string redChairName = "redchair";

    //When instantiated, load up the prim numbers, and clear the board
    public constructor() {
        this.loadPieces();
        this.resetBoard();
    }
    //Clear the board for a new game
    public resetBoard(){
        //Set the turn so black (aka yellow) goes first
        this.turnIsBlack = 1;
        //Make the playing indicators visible
        this.setIndicator(0);
        //Update our locked variable based on sitters
        this.updateLocked();
        //Click the game over variable
        this.gameOver = 0;
        //Reset what checker we can use
        this.currentCheckerNumber = 0;
        //Set up empty array for the board tracking, 7 cols
        for (integer c = 0; c <= 6; c++)
        {
            array row;
            for (integer  r= 0; r <= 5; r++)
            {
                //Set everything to -1, aka no color is at this location
                row[r]=-1;
            }
            this.columns[c]=row;
        }
    }
    //Loop through all prims, record them to a class variable if they are important, move them to inital locations as well
    private loadPieces() {
        integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
        integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
        integer checkerNumber = 0;
        //Loop through all possible prim numbers x
        for (; i < x; ++i)
        {
            //If we find a checker, instantiate a new object with its number and prim number
            if (llGetLinkName(i) == this.checkersName)
            {
                //llSay(0,"tring to set normal number "+checkerNumber + " to "+i);
                Checker checker = new Checker(checkerNumber,i);
                this.checkers[checkerNumber++] = checker;
            }
            //for the indicators, they are named like "slot1, slot2" so we detect if the name starts with "slot"
            else if (llSubStringIndex(llGetLinkName(i), this.indicatorName)==0 )
            {
                //if so, we can get the substring after 4 characters "1" , and use that to save the slot number and its prim number    
                this.locationIndicators[(integer) llGetSubString(llGetLinkName(i), 4,-1)] = i;
    
            }
            //if the name matches, set the class vairable with the prim number
            else if(llGetLinkName(i) == this.resetButtonName)
            {
                this.resetButtonPrimNumber = i;
            }else if(llGetLinkName(i) == this.blackChairName)
            {
                this.blackChairPrimNumber = i;
            }else if(llGetLinkName(i) == this.redChairName)
            {
                this.redChairPrimNumber = i;
            }
        }
        //hide the indicators (looks better for boot animation)
        this.setIndicator(1);

        //Set the initial positions, run a loop from 7 to -1 to test and animate the positions,
        //see setDefaultPosition for more info

        //declare loop variables outside of the loop gives a slight performance boost
        object k;
        object c;

        for (i=8; i >= -1; --i)
        {
            //For each checker, set its default position with a new, incrimentally smaller offset
            foreach (k,c in this.checkers)
            {
                Checker checker = (Checker)c;
                checker.setDefaultPosition(i);
                llSleep(.01);
            }
            llSleep(.05);
        }
    }

    //Player wants to drop a checker at this column location, process
    public processTouchedPos(integer columnSlot, key who)
    {
        //If the game is over, just quit
        if(this.gameOver) return;
        //If we are locked (aka 2 people are seated), make sure the player who wants to drop the checker is in the right chair)
        if(this.locked && (( who != this.blackPlayer && this.turnIsBlack) || ( who != this.redPlayer && !this.turnIsBlack)))
        {
            return;
        }
        //llSay(0,"Processing touched position "+(string)boardLocation);
        array columnInConcern = (array)this.columns[columnSlot];
        //need to see if this is valid, not allowed to go over 6 high
        //Check the top position (5) in this column, make sure it is -1 (no color here)
        if((integer)columnInConcern[5]==-1)
        {
            integer r = 0;
            //we know the column (from the slot clicked), find the row now
            //The row this goes too is the lowest row with no color currently (aka -1)
            //start at 0, and keep going higher (with backup safe limit of 7) until we find a empty slot
            for (r= 0; r <= 7; r++)
            {
                //llSay(0,"Checking "+(string)columnInConcern[r]);
                //If this slot is empty
                if((integer)columnInConcern[r]==-1)
                {
                    //Dont loose our r variable for the row slot, break the loop now
                    break;
                }
            }
            //Set the columns row value to our turn color (no more -1)
            columnInConcern[r] = this.turnIsBlack;//color
            //Set the column variable with our updated column that contains the new row info, for later use
            this.columns[columnSlot]=columnInConcern;
            
            //move a checker there
            //Grab a new checker from out list by incrimenting our checkerNumber
            currentCheckerNumber++;
            Checker nextChecker = (Checker)this.checkers[currentCheckerNumber];
            //Set the color of our picked checker to match the turn
            nextChecker.red = !this.turnIsBlack;
            //Hide the indicators so we can animate a drop nicely
            this.setIndicator(-1);
            //Set the location with the checker class, it handles the position and animation
            nextChecker.setBoardLocation(<columnSlot,r,0>);
            //end the turn, switch players, etc
            endTurn();
        }


        return;
    }

    //Scan the board, look and see if we have any winners, return the color if we do, or -1 if we do not
    public integer checkForWinner()
    {
        //thousands of ways to optomize this, but I think I am just going to go for brute force linear O(42*8*4)
        //42 slots, 8 directions, 4 connections needed

        //For every column,row that has a color (not -1)
        for (integer c = 0; c <= 6; c++)
        {
            for (integer  r= 0; r <= 5; r++)
            {
                if(this.getColorAtLocation(c,r)!=-1)
                {
                    //Check and see if a winning combo of 4 starts at this column,row
                    integer winningColor = doesThisLocationStartAFourConnection(c,r);
                    if(winningColor!=-1)
                    {
                        //if so, stop and return the winner
                        return winningColor;
                    }
                }
            }
        }
        //no winner
        return -1;
    }
    //helper function to make accessing our array easier, returns the color in this.columns in the rowNumber
    public integer getColorAtLocation(integer columnNumber,integer rowNumber)
    {
        array columnInConcern = (array)this.columns[columnNumber];
        return (integer)columnInConcern[rowNumber];
    }

    //Check and see if this position is the start of a 4 connect
    public integer doesThisLocationStartAFourConnection(integer columnNumber,integer rowNumber)
    {
        //go off in each of the 8 directions and see if any have a connected 4, return if found
        integer winningColor = doesThisLocationStartAFourConnectionInThisDirection(columnNumber,rowNumber,<0,1,0>);
        if(winningColor!=-1){ return winningColor;  }
        integer winningColor = doesThisLocationStartAFourConnectionInThisDirection(columnNumber,rowNumber,<0,-1,0>);
        if(winningColor!=-1){ return winningColor;  }
        integer winningColor = doesThisLocationStartAFourConnectionInThisDirection(columnNumber,rowNumber,<1,0,0>);
        if(winningColor!=-1){ return winningColor;  }
        integer winningColor = doesThisLocationStartAFourConnectionInThisDirection(columnNumber,rowNumber,<-1,0,0>);
        if(winningColor!=-1){ return winningColor;  }
        integer winningColor = doesThisLocationStartAFourConnectionInThisDirection(columnNumber,rowNumber,<1,1,0>);
        if(winningColor!=-1){ return winningColor;  }
        integer winningColor = doesThisLocationStartAFourConnectionInThisDirection(columnNumber,rowNumber,<-1,-1,0>);
        if(winningColor!=-1){ return winningColor;  }
        integer winningColor = doesThisLocationStartAFourConnectionInThisDirection(columnNumber,rowNumber,<-1,1,0>);
        if(winningColor!=-1){ return winningColor;  }
        integer winningColor = doesThisLocationStartAFourConnectionInThisDirection(columnNumber,rowNumber,<1,-1,0>);

        return winningColor;
    }

    //If we start at this location, and go off in this direction, do we have 4 connections?
    //direction is a movement in <column, row, ignored>
    public integer doesThisLocationStartAFourConnectionInThisDirection(integer columnNumber,integer rowNumber, vector direction)
    {
        //We have a start color, that counts as 1!
        integer connectionsFound = 1;
        integer colorToMatch = this.getColorAtLocation(columnNumber,rowNumber);
        //sanity check, to make sure we actually have a start color :)
        if(colorToMatch == -1){ return -1;}
        
        //make sure this calculation does not lead us off the board, if it does, just exit,
        //wouldnt be possible to have a 4 connect this close to the board in this direction anyhow
        // check the color 3 away from our column and row in direction
        integer maxC = columnNumber + (direction.x * 3);
        integer maxR = rowNumber + (direction.y * 3);
        if(maxC > 6 || maxC < 0 || maxR > 5 || maxR < 0)
        {
            return -1;
        }
        //Declare variables out of the loop for speed
        //Declare step out of the loop so we can use it later (maybe)just to see how many steps we made it connected
        integer step = 1;
        integer nextColor=-1;
        for(; step<=3; step++)
        {
            //Get the color of the position 'step' steps away
            nextColor = this.getColorAtLocation(columnNumber + (direction.x * step),rowNumber + (direction.y * step));
            if(nextColor ==colorToMatch)
            {
                //we have a match this many steps away, keep going
                connectionsFound++;
            }else
            {
                //We no longer have a match, stop the loop
                break;
            }
        }

        //Save our maxConnectionsFound variable for debugging later
        if(connectionsFound>this.maxConnectionsFound)//this is not always true due to optomizations, but good for debug
        {
            this.maxConnectionsFound = connectionsFound;
        }
        //If we made it 4 connecitons, return success with the color (0 or 1)
        if(connectionsFound >=4)
        {
            return colorToMatch;
        }
        //No 4 connect, return no color
        return -1;
    }

    //End the turn, swap players, show the touch indicators, check for a winner
    public endTurn()
    {
        //llSay(0,"turn ended");
        this.turnIsBlack = !this.turnIsBlack;
        this.setIndicator(0);
        this.checkAndDeclareWinner();
        //llSay(0,"Max Connections Found so far are "+(string)this.maxConnectionsFound);
    }
    
    //Shows or hides, and changes the colors of the touchable indicators to match the turn
    public setIndicator(integer hide)
    {
        vector color = yellowColor;
        if(!this.turnIsBlack)
        {
            color = redColor;
        }
        //loop through each indicator
        object indicatorNum;
        object indicatorPrimNum;
        foreach (indicatorNum,indicatorPrimNum in this.locationIndicators)
        {
            integer indicatorNumInt = (integer)indicatorNum;
            //Set that indicators transparency and color to match the turn
            if(hide)
            {
                llSetLinkPrimitiveParamsFast((integer)indicatorPrimNum,
                    [
                    PRIM_COLOR,
                    ALL_SIDES,color,0.0,//0 alpha, hide the prim
                    PRIM_GLOW, ALL_SIDES, 0.0,//no glow, hide the prim
                    //debug, to show the indicator number if we edit the 0.0
                    PRIM_TEXT,(string)indicatorNumInt, color, 0.0
                    ]);
            }else
            {
                llSetLinkPrimitiveParamsFast((integer)indicatorPrimNum,
                [
                PRIM_COLOR,
                ALL_SIDES,color,.7,//semi transparent, and correct color
                PRIM_GLOW, ALL_SIDES, 0.05,//some glow
                PRIM_TEXT,(string)indicatorNumInt, color, 0.0//debug, hidden here for now
                ]);
            }
        }
    }

    //Called at the end of each turn to see if we have a winner, if we do, speak it and end the game
    public checkAndDeclareWinner()
    {
        integer winner = this.checkForWinner();
        if(winner != -1)
        {
            //Set the game over vairbale
            this.gameOver = 1;
            //hide the indicators
            this.setIndicator(-1);
            //winner is based on the color we found to be the winner
            string winnerText = "Red";
            if(winner)
            {
                winnerText = "Yellow";
            }
            //declare it
            llSay(0,"Game over! "+winnerText+" is the winner!!!");
        }
    }

    //Process a touch event, figure out if anything important was clicked and act on it
    public touched(integer link, integer face, vector touchST,key who)
    {
        //if locked, then the key (person who touched it) must be one of the sitters
        //this mostly stops unauthorized people from resetting the board
        if(this.locked && (who != this.redPlayer && who != this.blackPlayer))
        {
            return;
        }

        //llSay(0,"touched link:"+(string)link+" face:"+(string)face+" ST:"+(string)touchST+" who:"+(string)who);
        //If they clicked the prim number (link) that we have saved as the reset button, reset
        if(link == this.resetButtonPrimNumber)
        {
            //We could probably also just do this.resetBoard()
            llResetScript();
        }
        //Loop through our indicator array and see if it was any of them that were clicked
        object indicatorNum;
        object indicatorPrimNum;
        foreach (indicatorNum,indicatorPrimNum in this.locationIndicators)
        {
            if(link == (integer)indicatorPrimNum)
            {
                //an indicator above was clicked, process this column as being clicked
                this.processTouchedPos((integer)indicatorNum,who);
            }
        }

    }
    //We are passed information from our linked prims when someone sits on them, process this infomation here
    public sitterUpdate(integer fromPrimNumber, key sitter)
    {
        //If the prim that was sat in is either of the chair prim numbers, set the appropriate key to that sitter
        if(fromPrimNumber == this.blackChairPrimNumber)
        {
            this.blackPlayer = sitter;
        }else  if(fromPrimNumber == this.redChairPrimNumber)
        {
            this.redPlayer = sitter;
        }
        //Check and see if we have two sitters and lock the board to only allow input from these two people
        this.updateLocked();
    }
    
    //Check and see if we have two sitters and lock the board to only allow input from these two people
    public updateLocked()
    {
        //If both sitters are not empty
        if(this.redPlayer != NULL_KEY && this.blackPlayer != NULL_KEY)
        {
            this.locked = 1;
        }else
        {
            this.locked=0;
        }
        //llSay(0," red player is "+(string)this.redPlayer+" and black is "+(string)this.blackPlayer +" and locked is "+this.locked);
    }
}

default
{
    //happens when the script is started or reset
    state_entry()
    {
        //initialize our board (call the constructor, save it's variable so we can send it information)
        board = new Board();

        //People could already be sitting when this script is reset, message all the chairs and ask them to report who is on top of them
        llMessageLinked(LINK_ALL_OTHERS, 0, "who is sitting","");        
    }
    //We got touched!
    touch_end(integer num_detected)
    {
        //Use LL methods to get what prim, what face, what location, and who touched us
        integer link    = llDetectedLinkNumber(0);
        integer face    = llDetectedTouchFace(0);
        vector  touchST = llDetectedTouchST(0);
        key who = llDetectedKey(0);
        //send all of this information to the board for processing
        board.touched(link,face,touchST,who);
    }
    //We got an incoming message from a chair
    link_message(integer sender_num, integer num, string msg, key id)
    {
        //send the board the information that the chair told us about the sitter (or removal of a sitter)
        board.sitterUpdate(sender_num,id);
    }
}


