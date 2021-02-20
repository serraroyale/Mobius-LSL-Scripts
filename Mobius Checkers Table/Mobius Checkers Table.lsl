// NAME: Mobius Checkers
// AUTHOR: LGG (lgg.greg@gmail.com)
// CREATED: 02/Feb/2021
// EDITED:
// WORLD: OpenSim
// SCRIPT ENGINE: YEngine with yoptions arrays, objects & norighttoleft
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


//Specify the yoptions we need
//We use associative arrays instead of lists
yoption arrays; //We use associative arrays instead of lists
yoption norighttoleft; //This is just a flat performance bonus by properly using parenthesis
yoption objects; //This is so we can use classes, we have one for the board representation, and one for the checker

//Try to keep global vars to a minimum.
//The board object, touch and sitting inputs are sent to it
Board board;
//Easy way to define and change colors here
vector redColor = < 1, 0, 0 > ;
vector blackColor = < .15, .15, .15 > ;

// A note about the board.  Instead of using x,y cordinants, we are going to have positions be done by a single int
//red siide bottom left starts at 0, then goes across to the right to end at 7 (8 slots total)
//Then one row up, starts at 8 on the left, then across to 15
//Set showInfo to 1, to see more details
//This gives us a few advantages, want to know if a position is in a certain column? positionNumber % columnNumber == 0
//aka to find out if it is in the first column, position % 8 == 0, (so if you divide the position number by 8, does the remainder == 0)
//This is only true for positions 0 8 16 24 32 40 48 56 which are all the left column.
//Another advantage is that in checkers, a valid move is always diagonal, which always means a 7 or 9 difference in positions


//This represents a single checker, and has functions to make them easier to code laterr
class Checker {
    //Variables the checker object will keep track of for us
    //The LL prim number for use in llSetLinkPrimitiveParams
    public integer primNumber;
    //Each cheker actually keeps track of two prim numbers, one for the bottom piece, and the second for another prim that will appear above it if kinged
    public integer kingPrimNumber;
    //There are 24 checkers on the board, we give each one a number to keep track of it. The first 12 are red
    public integer checkerNumber;
    //Boolean if we are red or not checker
    public integer red = 0;
    //Even thought the board object keeps track of our position, we save our position perminantly just incase we are clicked, we know what board position we are easily
    public integer boardLocation = -1;
    //We need to save our state, whether or not this checker has been kinged
    public integer kinged = 0;
    //Another state variable, whether or not we are dead. (the board keep semi track of this, so this is a tad redundant)
    public integer dead = 0;
    //A state variable, if we have been selected by the user as the piece they want to use
    public integer selected = 0;
    //We dont need this, but it is nice to have for debug, save the llGetLinkPrimitiveParams here in case we need to check it later
    private list primInfo = [];
    //This is a boolean for debug if we should show text above the checker to see information in it
    private integer showInfo = 0;

    //This is the function to make a new checker, we require a prim number and checker number as inputs to create one
    public constructor(integer c, integer p) {
        //Take the function inputs and assign them to class variables
        this.primNumber = p;
        this.checkerNumber = c;
        //If our number is in the first 12, then set to red instead of black
        this.red = checkerNumber < 12;
        this.primInfo = llGetLinkPrimitiveParams(this.primNumber, [PRIM_NAME, PRIM_POS_LOCAL, PRIM_ROT_LOCAL, PRIM_DESC]);
    }

    //helping getter to return the vector of the location pos that we retrieved earlier in this.primInfo 
    public vector getLocalPos() {
        return (vector) this.primInfo[1];
    }

    //Public function that can be called to change this checkers location
    //Will also check and see if we are a king, and visably update
    public setBoardLocation(integer bl) {
        this.boardLocation = bl;
        this.checkAndSetKing();
        this.setState();
    }

    //Checks and sets our local variable for kinged to true if we are in the correct end spot
    public checkAndSetKing() {
        //for a red checker, this means all across the board, positions 56 and above, for a black checker, all across the board to the low numbers, 7 or below
        if ((this.red && this.boardLocation >= 56) || (!this.red && this.boardLocation <= 7)) {
            this.kinged = 1;
        }
    }

    //We dont use this, but its just a setter if the board or someone wants to manually set us as a kinged piece or not
    public setKinged(integer k) {
        this.kinged = k;
        this.setState();
    }

    //Setter to change our dead state, call set state after to update visuals
    public setDead() {
        this.dead = 1;
        this.setState();
    }

    //setter to change selected state and update visuals
    public setSelected(integer s) {
        this.selected = s;
        this.setState();
    }

    //Outputs a string that describes this checker, used for debug
    public string toString() {
        return "Checker[checker#='" + this.checkerNumber + "', prim#='" + this.primNumber + "'] " +
            " @ " + (string) this.getLocalPos();
    }

    //Static function that translated a board position number, to the actual x, y ,z location in the game.
    //Also requires king or dead to be passed. If king, set the prim higher (to be aboe the normal prim), if dead, set the height low to hide under the board
    public vector positionToLocalLocation(integer p, integer king, integer dead) {
        //How far apart the pieces should be in each position change
        float incriment = .085;
        //X location of first checker
        float xstart = -0.306915;
        //Y location of first checker
        float ystart = -0.305488;
        //Height of checker, static, unless we are a king (higher) or dead (lower)
        float z = .082327;
        if (king != 0) {
            z = king * 0.100567;
        }
        if (dead) {
            z = -2 * 0.100567;
        }
        //As described before, column, aka X position, is boardNumber % 8
        integer xpos = p % 8;
        //Y location is the remainder
        integer ypos = llFloor(p / 8) % 8;
        //Calculate our location position, start at xstart, then go up one incriment for each xpos, etc
        return <xstart + (incriment * xpos), ystart + (incriment * ypos), z > ;
    }

    //This updates the visuals of our checker to match our state
    public setState() {
        this.setPosition(this.boardLocation, this.kinged, this.selected, this.dead);
    }

    //mostly static function, sets this checker to match the state passed in parameter wize
    //Should be called after a change in state, to actually apply it (move the prims, etc)
    public setPosition(integer boardLocation, integer kinged, integer selected, integer dead) {
        //Set the color vector based on state
        vector color = blackColor;
        if (this.red) {
            color = redColor;
        }
        //Set all the properties of this checker to match our params
        //Also do the same for our king prim
        llSetLinkPrimitiveParamsFast(this.primNumber,
            [
                PRIM_POS_LOCAL,
                //use our function to change a board location to a true local SL position
                this.positionToLocalLocation(boardLocation, 0, dead),

                PRIM_COLOR,
                ALL_SIDES, color, 1.0,//fully visible, of the red or black color

                PRIM_GLOW, ALL_SIDES, 1.0 * selected,//glowing if selected

                PRIM_TEXT, this.checkerNumber + "k" + this.kinged + " @ " + this.boardLocation, color, this.showInfo,//text showing if debug is on

                //Do all of this again, but now target the king prim number
                PRIM_LINK_TARGET, this.kingPrimNumber,

                PRIM_POS_LOCAL,
                //We pass in a 1 for kinged, to get the kinged position
                this.positionToLocalLocation(boardLocation, kinged, dead),

                PRIM_COLOR,
                ALL_SIDES, color, 1.0 * kinged,

                PRIM_GLOW, ALL_SIDES, 1.0 * selected
            ]


        );
    }

    //This is mostly used in setup, and to debug and make sure that we can move a prim to each location properly
    //We give this checker a board location based on it's number, and then set it to make sure each board location is filled by some checker    
    public setDefaultPosition(integer offset) {
        this.setPosition(this.checkerNumber + (offset * 8), 1, 1, 0);
    }
}

//This is our main object, tracks and acts on user input, loads up the board from SL names, and monitors it
class Board {
    //Keeps track of our checker objects for use later
    public array checkers;
    //Keeps track of various of prim number for later identification (touches, etc)
    public integer boardPrimNumber;
    public integer resetButtonPrimNumber;
    public integer redIndicatorPrimNumber;
    public integer blackIndicatorPrimNumber;
    public integer redChairPrimNumber;
    public integer blackChairPrimNumber;
    //Keep track of the keys of the people sitting in each chair
    public key blackPlayer;
    public key redPlayer;
    //Represents if there is a user in each chair, and that the board should be locked from all outside input other than from these players
    public integer locked = 0;
    //Boolean for controlling who's turn it is
    public integer turnIsBlack = 1;
    //this is for representing a special board state where on double jumps are allowed and the same player gets to play twice
    //in checkers, if you jump, you are allowed tooo double jump if one is avaliable and essentially go twice, or make two actions
    public integer doubleJumpOnly = 0;

    //Static prim names to help scan linked objects and populate the above prim numbers
    private string checkersKingName = "Checkers#1";
    private string checkersName = "Checkers";
    private string boardName = "Cheakerboard";
    private string resetButtonName = "resetbutton";
    private string redIndicatorName = "redturnindicator";
    private string blackIndicatorName = "blackturnindicator";
    private string blackChairName = "blackchair";
    private string redChairName = "redchair";

    //This is a static list that we part to put each checker number in the right star location, -1 is no checker
    private list initialPositions = [
        -1, 0, -1, 1, -1, 2, -1, 3,
        4, -1, 5, -1, 6, -1, 7, -1,
        -1, 8, -1, 9, -1, 10, -1, 11,
        -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1,
        12, -1, 13, -1, 14, -1, 15, -1,
        -1, 16, -1, 17, -1, 18, -1, 19,
        20, -1, 21, -1, 22, -1, 23, -1
    ];

    //Main variable to keep track of the full state of the board
    //This is an associative array of boardPosition to checkerNumber
    public array positions;

    //Keeps track of what checker the player has selected to move next, (this is the glowing prim)
    private integer selectedCheckerNumber = -1;
    //When instantiated, load up the prim numbers, and clear the board
    public constructor() {
        this.loadPieces();
        this.resetBoard();
    }

    //Clear the board for a new game
    public resetBoard() {
        //populate our intial positions
        this.initializeBoard();
        //Move all of the checkers into position by setting it to them
        this.setBoard();
        //Set the turn so black (aka yellow) goes first
        this.turnIsBlack = 1;
        //updates our turn indicatrror prim to be correct
        this.setIndicator();
        //Update our locked variable if people are sitting
        this.updateLocked();
    }
    //Load intital positions into our array
    public initializeBoard() {
        integer i = 0;
        integer length = llGetListLength(this.initialPositions);
        do {
            this.positions[i] = llList2Integer(this.initialPositions, i);
        }
        while (++i < length);
    }
    //Move all of the checkers into position by setting it to them
    public setBoard() {
        object boardPositionNumber;
        object checkerNumber;
        //Loop through everything in this.positions (probably just the start positons, but who knows)
        foreach(boardPositionNumber, checkerNumber in this.positions) {
            integer checkerNumber = (integer) checkerNumber;
            integer boardPositionNumber = (integer) boardPositionNumber;
            if (checkerNumber >= 0) {
                //Get the checker from the checkerNumber slot of our this.checkers array            
                Checker checker = (Checker) this.checkers[checkerNumber];
                //Use the checkers public method to set the location, and let the checker update visually to it
                checker.setBoardLocation(boardPositionNumber);
            }
        }
    }
    //Loop through all prims, record them to a class variable if they are important, move them to inital locations as well
    private loadPieces() {
        integer i = llGetLinkNumber() != 0; // Start at zero (single prim) or 1 (two or more prims)
        integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
        integer checkerNumber = 0;
        integer checkerKingNumber = 0;
        string primName = "";
        //Loop through all possible prim numbers x
        for (; i < x; ++i) {
            primName = llGetLinkName(i);
            //If the name of the prim matches our variable for a checker name, add a new one to our checkers array
            if (primName == this.checkersName) {
                //llSay(0,"tring to set normal number "+checkerNumber + " to "+i);
                Checker checker = new Checker(checkerNumber, i);
                this.checkers[checkerNumber++] = checker;
            } else if (primName == this.boardName) {
                this.boardPrimNumber = i;
            } else if (primName == this.resetButtonName) {
                this.resetButtonPrimNumber = i;
            } else if (primName == this.redIndicatorName) {
                this.redIndicatorPrimNumber = i;
            } else if (primName == this.blackIndicatorName) {
                this.blackIndicatorPrimNumber = i;
            } else if (primName == this.blackChairName) {
                this.blackChairPrimNumber = i;
            } else if (primName == this.redChairName) {
                this.redChairPrimNumber = i;
            }
        }
        //Do two loops so that we already have the checkers array set so we can add the king piece to it
        //The issue is that we might find all of the king prims first, and have no checker objects saved from our first detection pass to apply them to
        integer i = llGetLinkNumber() != 0; // Start at zero (single prim) or 1 (two or more prims)
        integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
        for (; i < x; ++i) {
            if (llGetLinkName(i) == checkersKingName) {
                //llSay(0,"tring to set king number "+checkerKingNumber + " to "+i);
                //Set the king prim number tro each checker as we find them, hope we have enough :)
                Checker checker = (Checker) this.checkers[checkerKingNumber++];
                checker.kingPrimNumber = i;
            }
        }

        //Set the initial positions
        //This is more about debug and testing the checker object positions than actual board state
        object k;
        object c;
        for (i = 8; i >= 0; --i) {
            //For each checker, set its default position with a new, incrimentally smaller offset so they sort of animate on start
            foreach(k, c in this.checkers) {
                Checker checker = (Checker) c;
                checker.setDefaultPosition(i);
                llSleep(.01);
            }
            llSleep(.25);
        }
    }

    //Sets a new checker as selected
    public select(integer checkerNum) {
        //first deselect, get our current selected checker and update its local state (and appearance)
        if (this.selectedCheckerNumber >= 0) {
            Checker selectedChecker = (Checker) this.checkers[this.selectedCheckerNumber];
            selectedChecker.setSelected(0);
        }
        //Get the next selected checker and update it's state
        if (checkerNum >= 0) {
            Checker newSelectedChecker = (Checker) this.checkers[checkerNum];
            newSelectedChecker.setSelected(1);
        }
        //Save the selected check for movement in the next click
        this.selectedCheckerNumber = checkerNum;
    }
    //Helper function, takes an input and makes sure it is not below min, or above max, sets to that if it is
    public float clamp(float input, float min, float max) {
        if (input > max) {
            input = max;
        } else if (input < min) {
            input = min;
        }
        return input;
    }

    //Player clicked some boardLocation number, handle it!
    //We also use this function to simulate clicking all locations, to find out if the tuyrn is over or has more moves for game over detection
    public integer processTouchedPos(integer boardLocation, integer simulateCheckForValid, key who) {
        //If we are locked (aka 2 people are seated), make sure the player who wants to move a checker is in the right chair)
        if (this.locked && !simulateCheckForValid &&
            ((who != this.blackPlayer && this.turnIsBlack) || (who != this.redPlayer && !this.turnIsBlack))
        ) {
            return 0;
        }

        integer checkerNumberAtThisLocation = (integer) this.positions[boardLocation];
        //from this.positions  a -1 means no checker here currently, could be a blank middle location or avaliable location
    

        //llSay(0,"Touched Location "+(string)boardLocation+" and found checker number "+(string)checkerNumberAtThisLocation);
        //There is already a checker here
        if (checkerNumberAtThisLocation == this.selectedCheckerNumber) {
            //CLicked existing selected, unselect

            //llSay(0,"use selected self, unselect "+checkerNumberAtThisLocation+" == "+this.selectedCheckerNumber+" not to jump, ending turn");
            this.select(-1);
            if (this.doubleJumpOnly) {
                //user chose not to jump
                //llSay(0,"use selected self, chose not to jump, ending turn");
                this.endTurn();
            }
        } else
        if (checkerNumberAtThisLocation >= 0)
        {
            //They clicked where there is already a checker, this is not a valid move, but if they are the same color, the user could just be wanting to select a different checker to move
            Checker touchedChecker = (Checker) this.checkers[checkerNumberAtThisLocation];
            if (this.turnIsBlack != touchedChecker.red && !this.doubleJumpOnly) {
                this.select(checkerNumberAtThisLocation);
            }
        } else {
            //the board was clicked where there are no checkers, this could be a move

            if (this.selectedCheckerNumber >= 0) {

                Checker selectedChecker = (Checker) this.checkers[this.selectedCheckerNumber];
                //we have a checker selected

                //So, if we are a red player, we are only allowed to move in a positive direction up the board
                //Sasve this as a variable for later.
                //We can also move either direction if the prim is a king
                integer positiveDirectionAllowed = !turnIsBlack || selectedChecker.kinged == 1;
                integer negativeDirectionAllowed = turnIsBlack || selectedChecker.kinged == 1;
                //A valid move is either 7 or 9 slots away always, but do not allow movement past the edge
                //There are a few calculation checks going on here, split into positive direction and negative (just inversed)
                //After checking that the new board location is in an allowed direction (boardLocation > selected location)
                //We need to make sure we are not hopping from one end to the other
                //One end of the board is column 7 and the other is column 0 (aka location % 8 = 0)
                //As mentioned above, a valid move is either + 7 (moving up and to the left) or +9 (moving up and to the right)
                //So we must make sure that is true (difference in locations is either + 7 or 9)
                //and also make sure that if we are in column 7, we do not try to go to the right ( difference % 9 = 0)
                //phew. this could be done different, but the idea of using % was to detect and allow multiple moves in a click, which is essentially what a jump is
                //if (
                //    (
                //        positiveDirectionAllowed && (boardLocation > selectedChecker.boardLocation) &&
                //        (
                //            (((boardLocation - selectedChecker.boardLocation) % 9 == 0) && (selectedChecker.boardLocation % 8 != 7)) ||
                //            (((boardLocation - selectedChecker.boardLocation) % 7 == 0) && (selectedChecker.boardLocation % 8 != 0))
                //        )
                //    ) ||
                //    (
                //        negativeDirectionAllowed && (boardLocation < selectedChecker.boardLocation) &&
                //        (
                //            (((boardLocation - selectedChecker.boardLocation) % 9 == 0) && (selectedChecker.boardLocation % 8 != 0)) ||
                //            (((boardLocation - selectedChecker.boardLocation) % 7 == 0) && (selectedChecker.boardLocation % 8 != 7))
                //        )
                //    )
                //    ) {

                //I am rewritting this anyhow.. so lets simplify this logic a bit
                integer differenceInPositions = boardLocation - selectedChecker.boardLocation;
                integer movedToTheRight  = ((differenceInPositions) % 9 == 0);
                integer movedToTheLeft =((differenceInPositions) % 7 == 0);

                if (
                    (
                        positiveDirectionAllowed && (boardLocation > selectedChecker.boardLocation) &&
                        (
                            (movedToTheRight && (selectedChecker.boardLocation % 8 != 7)) ||
                            (movedToTheLeft && (selectedChecker.boardLocation % 8 != 0))
                        )
                    ) ||
                    (
                        negativeDirectionAllowed && (boardLocation < selectedChecker.boardLocation) &&
                        (
                            (movedToTheRight && (selectedChecker.boardLocation % 8 != 0)) ||
                            (movedToTheLeft && (selectedChecker.boardLocation % 8 != 7))
                        )
                    )
                    ) {

                    //This huge if above is basically just a check to see if this is a valid move
                    integer movesMade = 0;
                    integer madeDirection = 0;
                    if (movedToTheLeft) {
                        movesMade = (differenceInPositions) / 7;
                        madeDirection = 7;
                    }
                    if (movedToTheRight) {
                        movesMade = (differenceInPositions) / 9;
                        madeDirection = 9;
                    }
                    //Only allow one jump at a time
                    if (llAbs(movesMade) == 2) {
                        //This is the logic for a jump! a normal move normall just has movesMade == 1
                        //Make sure the middle is a valid oposite color piece
                        integer middlePiecePosition = selectedChecker.boardLocation + ((movesMade / 2) * madeDirection);
                        //Cant jump over an edge, check its column
                        if (middlePiecePosition % 8 != 7 && middlePiecePosition % 8 != 0) {
                            integer checkerNumberAtThisMiddleLocation = (integer) this.positions[middlePiecePosition];
                            if (checkerNumberAtThisMiddleLocation >= 0) {
                                Checker middleChecker = (Checker) this.checkers[checkerNumberAtThisMiddleLocation];
                                //make sure the checker we want to jump has a different color
                                if (middleChecker.red != selectedChecker.red) {
                                    //At this poiont, we know this is a valid jump, process!
                                    
                                    //If we are just looking for valid moves, exitt
                                    if (simulateCheckForValid) {
                                        return 1;
                                    }
                                    //llSay(0,"jumped over "+(string)middlePiecePosition);
                                    //Set the new location for the selected checker
                                    this.moveSelectedChecker(boardLocation);
                                    //Remove the middle checker
                                    this.removeCheckerAtLocation(checkerNumberAtThisMiddleLocation);
                                    //Continue? jumps allowed only! no normal moves
                                    this.doubleJumpOnly = 1;
                                    if (selectedPrimHasAnyValidMoves()) {
                                        //llSay(0,"Double jump availiable, allowing");
                                    } else {
                                        //llSay(0,"no double jump found jump availiable, ending turn");
                                        this.endTurn();
                                    }
                                }
                            }
                        }
                    } else if (llAbs(movesMade) == 1 && !this.doubleJumpOnly) {
                        //no jumps detected distance wize here, and we are not in a double jump only move, so this is a valid single move
                        if (simulateCheckForValid) {
                            return 1;
                        }
                        this.moveSelectedChecker(boardLocation);
                        //llSay(0,"standard move made, ending turn");
                        this.endTurn();
                    }
                }
            }
        }
        return 0;
    }
    //Sets our selectedCheckers boardlocation and visable moves it
    public moveSelectedChecker(integer newBoardLocation) {
        Checker selectedChecker = (Checker) this.checkers[this.selectedCheckerNumber];
        //Update our positions array to represent the move. Old location is now -1, new location is now the selected checker
        this.positions[selectedChecker.boardLocation] = -1;
        this.positions[newBoardLocation] = this.selectedCheckerNumber;
        selectedChecker.setBoardLocation(newBoardLocation);
    }
    //Updates our state, and visably, if a checker is removed
    public removeCheckerAtLocation(integer checkerNumber) {
        Checker checkerToRemove = (Checker) this.checkers[checkerNumber];
        //Set our positions array to -1 at the position of the checker that was removed
        this.positions[checkerToRemove.boardLocation] = -1;
        checkerToRemove.setDead();
    }

    public endTurn() {
        //llSay(0,"turn ended");
        //Swap colors
        this.turnIsBlack = !this.turnIsBlack;
        //Remove the glow from the selected prim and clear its variable
        this.select(-1);
        //Double jumps are not longer required if they were before
        this.doubleJumpOnly = 0;
        //Check and see if there are any moves avaiable at all, and if so end the game
        this.checkAndDeclareWinner();
        //Update the turn indicator to the new color
        this.setIndicator();
    }

    public setIndicator() {
        //Make a color slightly darker than our red or black checker color
        vector color = blackColor * .7;
        if (!this.turnIsBlack) {
            color = redColor * .7;
        }
        //Set the visibility of the indicator color and it's color
        llSetLinkPrimitiveParamsFast(this.redIndicatorPrimNumber,
            [
                PRIM_COLOR,
                ALL_SIDES, color, !this.turnIsBlack,//hidden if not red turn

                PRIM_LINK_TARGET, this.blackIndicatorPrimNumber,
                PRIM_COLOR,
                ALL_SIDES, color, this.turnIsBlack //hidden if not black turn
            ]);

    }

    public checkAndDeclareWinner() {
        if (!this.isThereAnyValidMoves()) {
            string winner = "Black";
            if (this.turnIsBlack) {
                winner = "Red";
            }
            llSay(0, "Game over! " + winner + " is the winner!!!");
        }
    }

    //Called to see if the current player has ANY valid moves they can make. (do they have any pieces left? are they blocked and cant move foreward? etc)
    public integer isThereAnyValidMoves() {
        integer moveFound = 0;
        object checkerNumberKey;
        object checkerObject;
        // make each checked on our board that isnt dead, or isnt the wrong color, selected, and then try to move it anywhjere.  if we can, there is a valid move
        foreach(checkerNumberKey, checkerObject in this.checkers) {
            integer checkerNumber = (integer) checkerNumberKey;
            Checker checker = (Checker) checkerObject;
            if (!checker.dead && (checker.red != this.turnIsBlack)) {
                this.selectedCheckerNumber = checkerNumber;
                if (this.selectedPrimHasAnyValidMoves()) {
                    return 1;
                }
            }
        }
        this.selectedCheckerNumber = -1;
        return 0;
    }

    private integer selectedPrimHasAnyValidMoves() {
        object boardNumberKey;
        object checkerNumberValue;
        //loop over every existing position as if the user had touched it, simulate that touch and see if any are valid
        foreach(boardNumberKey, checkerNumberValue in this.positions) {
            integer boardNumber = (integer) boardNumberKey;
            integer checkerNumber = (integer) checkerNumberValue;
            //test any open space
            if (checkerNumber < 0) {
                //Note, setting 1 to the simulation variable, and using our same mega touch method for validity checking
                integer thisIsAValidMove = this.processTouchedPos(boardNumber, 1, NULL_KEY);
                if (thisIsAValidMove) {
                    return 1;
                }
            }
        }
        return 0;
    }

    //Process a touch event, figure out if anything important was clicked and act on it
    public touched(integer link, integer face, vector touchST, key who) {
        //if locked, then the key (person who touched it) must be one of the sitters
        //this mostly stops unauthorized people from resetting the board
        if (this.locked && (who != this.redPlayer && who != this.blackPlayer)) {
            return;
        }

        //llSay(0,"touched link:"+(string)link+" face:"+(string)face+" ST:"+(string)touchST+" who:"+(string)who);
        //Decode board ST
        integer touchedPosition = -1;
        //Frame touch, no longer used    //if(link == this.boardPrimNumber && (face!=0) && (face != 2))
        //If they clicked the prim number (link) that we have saved as the reset button, reset
        if (link == this.resetButtonPrimNumber) {
            llResetScript();
        } else if (link == this.boardPrimNumber && (face == 0 || face == 2)) {
            //user clicked the actual board prim, make sure it is on the face (face 2 and 0 are red and black checker slots of the front facing board)
            //This logic checks the X Y position the user clicked on the board, and translates it to the actual position
            //This is essentially the valid rectangle of the valid touch spots, we essentially divide this up by 8 each way to get what they clicked
            float minX = 0.06176;
            float maxX = 0.68833;
            float minY = 0.31150;
            float maxY = 0.93817;
            //clamp just incase our result was not perfect, and they somehow clicked lower than them by a tad
            touchST.x = this.clamp(touchST.x, minX, maxX);
            touchST.y = this.clamp(touchST.y, minY, maxY);
            //Subtract the min from the touch, so that we have a 0 reference, then divide by our total length to get a percentage down the board, then divide by 8 to get what x column they clicked
            integer x = llFloor((touchST.x - minX) / ((maxX - minX) / 8.0));
            integer y = llFloor((touchST.y - minY) / ((maxY - minY) / 8.0));
            //we have x y, turn this into a board location (int 0 to 64)
            touchedPosition = x + (y * 8);
            //llSay(0,"Board "+(string)x+","+(string)y+" => "+touchedPosition);
        } else //check to see if they touched a checker
        {
            object k;
            object c;
            foreach(k, c in this.checkers) {
                Checker checker = (Checker) c;
                //Do not forget to also check if this is the kinged prim
                if (link == checker.primNumber || link == checker.kingPrimNumber) {
                    //They touched a checker instead of the board, this is okay, just get the location from the checker object
                    touchedPosition = checker.boardLocation;
                }
            }
        }
        //If any way that we got touched, ended up with an actual tochedBoard position, send this for processing
        if (touchedPosition >= 0) {
            this.processTouchedPos(touchedPosition, 0, who);
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


default {
    //happens when the script is started or reset
    state_entry() {
        //initialize our board (call the constructor, save it's variable so we can send it information)
        board = new Board();

        //People could already be sitting when this script is reset, message all the chairs and ask them to report who is on top of them
        llMessageLinked(LINK_ALL_OTHERS, 0, "who is sitting", "");
    }

    //We got touched!
    touch_end(integer num_detected) {
        //Use LL methods to get what prim, what face, what location, and who touched us
        integer link = llDetectedLinkNumber(0);
        integer face = llDetectedTouchFace(0);
        vector touchST = llDetectedTouchST(0);
        key who = llDetectedKey(0);
        //send all of this information to the board for processing
        board.touched(link, face, touchST, who);
    }
    //We got an incoming message from a chair
    link_message(integer sender_num, integer num, string msg, key id) {
        //send the board the information that the chair told us about the sitter (or removal of a sitter)
        board.sitterUpdate(sender_num, id);
    }
}