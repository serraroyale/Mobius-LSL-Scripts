// NAME: Mobius Selfish Dice
// AUTHOR: LGG (lgg.greg@gmail.com)
// CREATED: 28/Feb/2021
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
//
//Written by LGG Greg aka L GG under commision for royale.mobian
//This could be optomized a bunch, please do it and let me know!


//Specify the yoptions we need
yoption arrays; //We use associative arrays instead of lists
yoption norighttoleft; //This is just a flat performance bonus by properly using parenthesis
yoption objects; //This is so we can use classes, we have one for the board representation, and one for scoreboard

//Try to keep global vars to a minimum.
//The board object, touch and sitting inputs are sent to it
Board board;

//This is a class to manage the prims and textrures that display the score
class ScoreBoard {
    //list of prims for each digit, in order of bits
    public array scorePrimNumbers;
    protected string indicatorNamePrefix = "Score Digit ";
    //Turn this to 1 to show some debug
    protected integer debug = 0;
    //overloading the constructor gets messy, just make the construction use a function we can override
    public constructor() {
        this.initialize();
    }
    //Scan all the prims, set the numbers
    virtual public initialize()
    {        
        this.loadPieces();
        this.debugOutPieces();
    }
    //Loop through all prims, record them to a class variable if they are important
    protected loadPieces() {
        integer i = llGetLinkNumber() != 0; // Start at zero (single prim) or 1 (two or more prims)
        integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
        integer checkerNumber = 0;
        integer checkerKingNumber = 0;
        string primName = "";
        //Loop through all possible prim numbers x
        for (; i < x; ++i) {
            primName = llGetLinkName(i);
            
            //for the indicators, they are named like "Score Digit 1, Score Digit 10" so we detect if the name starts with " Score Digit "
             if (llSubStringIndex(llGetLinkName(i), this.indicatorNamePrefix)==0 )
            {
                //if so, we can get the substring after skipping length characters characters , and use that to save the slot number (factor of 10) and its prim number    
                this.scorePrimNumbers[this.getPrimNumberFromName(llGetSubString(llGetLinkName(i), llStringLength(this.indicatorNamePrefix),-1))] = i;
    
            }
        }
    }
    //This is a function that we used to turn the prim detected number into the value we will use later
    //This will be overriden, for example, Score Digit 10,100,1000 is done by the length of that last part, where Dice 1,2,3 etc is done off the value directly
    virtual public integer getPrimNumberFromName(string name) {
        return (integer) llStringLength(name);
    }

    //Takes in a string score and adjusts the textures in world to show it
    virtual public displayScore(string score)
    {
        //Loop through each display prim, set its digit
        object x10;
        object primNumber;
        foreach (x10,primNumber in this.scorePrimNumbers) 
        {
            integer x10i = (integer)x10;
            integer primNumberi = (integer)primNumber;
            //We have the power x10i, need to get the corespondiong digit
            //We could convert to a integer and use math.. but we can just as easily use substring.  
            //lowest digit (1) is the last string character, so -x10i is our string location
            integer digit = (integer)llGetSubString(score,-1*x10i,-1*x10i);
            //llSay(0,(string)x10i + " should show digit "+(string)digit);
            //Convert the digit number to a texture offset on our texture to show the right number            
        
            float offset = ((float)360-(90*digit)) / 1000;
            llSetLinkPrimitiveParamsFast(primNumberi,[PRIM_TEXTURE, 0, "numbers", <1,0.09,0.0>, <0,offset,0>, 0]);
        }
    }
    //This is just for testing that our array makes sense
    public debugOutPieces()
    {
        if(!this.debug){
            return;
        }
        this.sayPieces();

        //Expected output 
        //indicatorSlot[1]= 9
        //indicatorSlot[2]= 8
        //indicatorSlot[3]= 7
        //indicatorSlot[4]= 5
        //indicatorSlot[5]= 6        
        this.displayScore("12345"); 
    }
    //This is mostly a debug function, loops through out array and llSays the info
    public sayPieces(){
    
        object x10;
        object primNumber;
        foreach (x10,primNumber in this.scorePrimNumbers) 
        {
            integer x10i = (integer)x10;
            integer primNumberi = (integer)primNumber;
            llSay(0,this.indicatorNamePrefix+ "[" + (string)x10i + "]= " + (string)primNumberi);
        } 
    }
}

//This is a class to manage the prims and textrures that display the dice
// modified from the score board as they work similarily
class DiceBoard : ScoreBoard {

    override public initialize()
    {
        //Setting class specific variables to change the behaviour
        this.indicatorNamePrefix  = "Dice ";
        this.debug = 0; 
        
        this.loadPieces();
        this.debugOutPieces();        
    }
    //Overloading this function to use the integer from Dice 1,2,3
    override public integer getPrimNumberFromName(string name) {
        return (integer)name;
    }
    //Takes in a string score and adjusts the textures in world to show it
    override public displayScore(string score)
    {
        //Loop through each display prim, set its digit
        object diceNumber;
        object primNumber;
        foreach (diceNumber,primNumber in this.scorePrimNumbers) 
        {
            integer diceNumberi = (integer)diceNumber;
            integer primNumberi = (integer)primNumber;
            integer digit = (integer)llGetSubString(score,-1*diceNumberi,-1*diceNumberi);
            if(this.debug)llSay(0,(string)diceNumberi + " should show digit "+(string)digit);
            this.setTexture(primNumberi,digit);
        }
    }    
    //We have 6 textures, one with each number on it
    //Based on what value we want to show, we pick one of the csv of the dice sides, which maps the texture to the right face to show that number up top
    private setTexture(integer link, integer val)
    {
        list    diceTextures =
            ["d528ab56-b8d7-4ed2-ad9c-df42d4d0ca0f",
            "9ef54d50-3129-48c6-8620-bd7be553146d",
            "4b270cfd-d42b-4f73-96b9-a165365998de",
            "c5526329-fb22-48d7-837f-8044121ce20a",
            "2b4912dc-b675-42d7-9a81-5501f16e6bbd",
            "902693c8-fb2f-4099-9ade-1ca461a330be"];

        list diceSides = ["0,4,1,3,2,5","2,0,1,3,5,4","3,4,0,5,2,1",
                        "1,4,5,0,2,3","4,5,1,1,0,2","5,2,1,3,4,0"]; // 0 on top
        integer i = 0;
        for (i = 0; i < 6; i++)
        {
            string faces = llList2String(diceSides, val-1);
            list sides = llParseString2List(faces, [","], [""]);

            key textureID = (key) llList2String(diceTextures, i);
            llSetLinkPrimitiveParamsFast(link,[PRIM_TEXTURE, llList2Integer(sides, i), textureID, <1,1,0.0>, <0,0,0>, 0]);
            
        }
    }
    
    private show(integer link, vector color)
    {
        llSetLinkPrimitiveParamsFast(link,[PRIM_COLOR, ALL_SIDES, color, 1.0]);
    }
    public hideAllDice()
    {
         //Loop through each display prim, set its digit
        object diceNumber;
        object primNumber;
        foreach (diceNumber,primNumber in this.scorePrimNumbers) 
        {                
            llSetLinkPrimitiveParamsFast((integer)primNumber,[PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.0]);
        }
    }
}

//This class keeps track of each die (not the texture UI part)
//This includes its state, like whether it has been selected or scored, and the UI to show that color
class Die{
    public integer selected;
    public integer scored;
    public integer number;
    //We keep a copy of the prim number to change color based on selection
    public integer primNumber;
    private integer debug = 0;
    public constructor(integer prim)
    {
        this.selected = FALSE;
        this.number = 0;
        this.primNumber = prim;
    }
    //Will roll ourself if we are not selected to be held
    //If we are selected, the roll essentially means that we have already been scored, so set and change the value
    //Note, logic regulates that you can not be scored unless you have already been selected, so there will be some assumptions on that
    public roll()
    {
        if(!this.selected)
        {
            //llFrand gets you something betweem 0.0 and 5.9999, llFloor to get a int from 0 to 5 evenly, then add 1 so it is a die
            this.number = llFloor(llFrand(6.0))+1;        
            if(this.debug){
                llSay(0,this.toString());
            }
        }else
        {
            //already selected, switch to scored
            this.scored = TRUE;
        }
        //Update the UI
        this.display();
    }
    //Select if we are not selected, if we are selected, toggle instead, unless we are scored, scored sticks and can not be unselected
    public select()
    {
        if(!this.scored)
        {
            this.selected = !this.selected;
        }
        this.display();
    }
    //Mostly for debug
    public string toString()
    {
        return "Dice with primNumber "+(string)this.primNumber+" and selected is "+(string)this.selected+" and number "+(string)this.number;    
    }
    //Updates the dice color, white is normal,  red is selected, blue is scored
    public display()
    {
        vector color = <1, 1,1>;
        if(this.selected) color = <1,.5,.5>;
        if(this.scored)color = <.5,.5,1>;
        llSetLinkPrimitiveParamsFast(this.primNumber,[PRIM_COLOR, ALL_SIDES, color, 1.0]);
    }
}
//This keeps track of all of our dice backend representations
class Dice{

    //This is for our dice board object, this is the UI section which also grabs prim numbers
    private DiceBoard diceBoard;
    //This is to keep track of dice objects, number and if it is selected
    private array dice;
    
    private integer debug =0;
    
    public constructor()
    {
        this.diceBoard = new DiceBoard();
        //This lets us get the this.diceBoard.scorePrimNumbers later
        if(this.debug){
            this.diceBoard.sayPieces();
        }
        //Based on the boards found dice, create our own dice objects for score and selected storing
        object diceNumber;
        object primNumber;
        foreach (diceNumber,primNumber in this.diceBoard.scorePrimNumbers) 
        {   
            //Using our die object, which inits with state selected = scored = 0
            Die newDie = new Die((integer)primNumber);
            this.dice[diceNumber] = newDie;           
        }        
    }
    //Just relay this to the scoreboard, as the game board does not see the score board directly
    public hideAllDice(){ this.diceBoard.hideAllDice(); }
    //Roll all 6 dice, by calling their roll method individually
    public roll(integer freshRoll) {
        llPlaySound("NEW dice roll",1.0);
        object diceNumbero;
        object dieO;
        integer numberScored = 0;
        //We add in a loop here to "reroll the dice a few times so that the animation is more visibile
        //Only the last roll is kept
        for(integer i = 0; i<6; i++)
        {
            numberScored = 0;
            foreach (diceNumbero,dieO in this.dice) 
            {   
                Die die = (Die)dieO;
                if(freshRoll){
                    //On a fresh roll of a new player, it is okay to clear state
                    die.selected = FALSE;
                    die.scored = FALSE;
                }
                //For each of our 6 dice, roll it.  
                //To the dice, a roll will transistion a selected dice to a scored dice, 
                //And a non selected dice to a new dice
                die.roll();
                if(die.scored){
                    //Keep track of how many dice were scored, if all 6 are, then do a new roll
                    numberScored++;
                }
            }    
            this.displayDiceStatus(); 
            llSleep(.3);
        }
        llSleep(.5);


        this.displayDiceStatus();          
        if(numberScored==6)
        {
            this.roll(TRUE);
        }
    }
    //Returns an array of the new dice the user has chosen to keep
    //We are trying to return an array where the key is the dice number, and the value is the count
    //Ex 4=>1, 3=>3, means there are one dice with a four, and 3 dice with a 3 selected
    public array getNewSelectedDice()
    {
        array newSelectedDice;
        //return newSelectedDice;
        
        object diceNumbero;
        object dieO;
        foreach (diceNumbero,dieO in this.dice) 
        {   
            Die die = (Die)dieO;
            if(die.selected && ! die.scored)
            {
                integer digitCount = 0;
                //incriment the count of this digit;
                string digitCountO = (string)newSelectedDice[die.number];                
                if(digitCountO is undef)
                {
                    digitCount = 0;
                }else
                {
                    digitCount =(integer)digitCountO;
                }
                digitCount++;
                newSelectedDice[die.number] = digitCount;
            }            
        }
        return newSelectedDice;        
    }
    //Returns an array of the new dice  that the user could choose to keep
    //We do this so we can see if there is any chance of the user scoring, and if not end the turn
    public array getUnSelectedDice()
    {
        array newSelectedDice;
        object diceNumbero;
        object dieO;
        foreach (diceNumbero,dieO in this.dice) 
        {   
            Die die = (Die)dieO;
            if(!die.selected && ! die.scored)
            {
                integer digitCount = 0;
                //incriment the count of this digit;
                string digitCountO = (string)newSelectedDice[die.number];                
                if(digitCountO is undef)
                {
                    digitCount = 0;
                }else
                {
                    digitCount =(integer)digitCountO;
                }
                digitCount++;
                newSelectedDice[die.number] = digitCount;
            }            
        }
        return newSelectedDice;        
    }
    //Go over each dice , get its number (1-6), turn that into a string and then pass it to 
    //The scoreboard object as it is in charge of handling the textures
    public displayDiceStatus()
    {
        string outputText = "";
        object diceNumbero;
        object dieO;
        foreach (diceNumbero,dieO in this.dice) 
        {   
            Die die = (Die)dieO;
            outputText=(string)die.number+outputText;
        }         
        this.diceBoard.displayScore(outputText);
    }
    //This is to handle a touch even from the active user
    public processSelectedPrim(integer prim)
    {
        object diceNumbero;
        object dieO;
        foreach (diceNumbero,dieO in this.dice) 
        {   
            Die die = (Die)dieO;
            //Loops through the 6 dice, if the primNumber matches, run the select event on that die
            if(die.primNumber == prim)
            {    
                die.select();
                return;
            }
        }        
    }
}


//This is small class to help us track text and highlight desired for the text
class HighlightedTextLine {
    public string text;
    public integer highlighted;
    public constructor(string newText,integer newHighlighted)
    {
        this.text = newText;
        this.highlighted = newHighlighted;
    }
}
//This is a class to help us show text that is in multiple colors by using multiple prims
//This object essentually stores a array of HighlightedTextLine s, and can display them
//Think of it like 1=> Hello World, (not bold)  2=>My name is greg (BOLD)
//The not bold ones go to one prim, and the bold ones to another
//We essentaully treat this like a string object, allowing people to append, or combine these together
class HighlightedText {
    //array of hightlighted text lines
    public array textLines;
    private integer debug = 0;
    public constructor()
    {
        this.textLines.clear();
    }
    //add a new text line, and its bold state
    public addTextLine(string text, integer highlighted)
    {
        //use our HighlightedTextLine object to save the data for our array
        this.textLines[this.textLines.count]=new HighlightedTextLine(text,highlighted);
    }    
    //Used to combine two hightlightText objects into one
    public addHighlightedText(HighlightedText otherHt)
    {
        object indexO;
        object htlO;
        foreach (indexO,htlO in otherHt.textLines) 
        {
            HighlightedTextLine htl  = (HighlightedTextLine)htlO;
            this.textLines[this.textLines.count]=htl;
        }
    }
    //This is to actually render it in world
    public setText(integer normalTextPrimNumber, integer highlightedTextPrimNumber)
    {
        string normalText = "";
        string hightlightText = "";
        //To display this, make two string with matching lines, one in each
        //ex "I am \n " and "\nGreg" to make the last line a different color and line up
        
        object indexO;
        object htlO;
        foreach (indexO,htlO in this.textLines) 
        {        
            HighlightedTextLine htl  = (HighlightedTextLine)htlO;            
            if(htl.highlighted)
            {
                hightlightText+=htl.text+"\n";
                normalText+="⠀\n";
            }else
            {
                normalText+=htl.text+"\n";
                hightlightText+="⠀\n";
            }
        }
    
        //Use set text on each prim for each string
        llSetLinkPrimitiveParamsFast(normalTextPrimNumber, [PRIM_TEXT, normalText, <1,1,1>,1.0]);
        llSetLinkPrimitiveParamsFast(highlightedTextPrimNumber, [PRIM_TEXT, hightlightText, <1,1,0>,1.0]);
        if(debug)
        {
            llSay(0,normalText);
            llSay(0,hightlightText);
        }
    }    
}
//Static function to asssist with getting names
//List of names to help our chacheKey2Name function
array names;
string cachedKey2Name(key id)
{
    //This is just a function that stores the results from llKey2Name so if the user leaves the sim, we can still display things
    string cachedName = (string)names[id];
    if(cachedName is undef)
    {
        //not found, grab and store
        cachedName = llKey2Name(id);
        if(cachedName == ""){
            //Still not found, make up a name
            cachedName = "Unknown";
        }else
        {
            //We got a good name, save it
            names[id]=cachedName;
        }
    }
    return cachedName;
}
//This is a relaivly basic class to represent a player and their score
class Player {
    private integer score = 0;
    private key id = NULL_KEY;
    //When instantiated, set score to 0
    public constructor(key playerId) {
        this.id = playerId;
        this.score = 0;
    }
    //basic getter and setters
    public integer getScore() { return this.score; }
    public key getID() { return this.id; }
    public string getName() { return cachedKey2Name(this.id); }
    public setScore(integer newScore) { this.score = newScore; }
    public integer increaseScore(integer incriment) { this.score += incriment;  return this.score; }
    
}
//This is our main object, tracks and acts on user input, loads up the board from SL names, and monitors it
class Board {
    //Keeps track of various of prim number for later identification (touches, etc)
    public integer helpPrimNumber;
    public integer resetButtonPrimNumber;
    public integer joinPrimNumber;
    public integer startPrimNumber;
    public integer textPrimNumber;
    public integer textHighlightPrimNumber;
    public integer passPrimNumber;
    public integer rollPrimNumber;
    public integer endPrimNumber;
    public integer startTurnPrimNumber;  
    
    //Static prim names to help scan linked objects and populate the above prim numbers
    //These could eventually be pre-processed constants.. but leaving as is for compatibility
    private string helpPrimName = "Help Button";
    private string joinPrimName = "Join Button";
    private string startPrimName = "Start Button";
    private string resetPrimName = "Reset Button";
    private string textPrimName = "Text Display";
    private string textHighlightPrimName = "Text Display Highlight";
    private string passPrimName = "Pass Button";
    private string rollPrimName = "Roll Button";
    private string endPrimName = "End Game";
    private string startTurnPrimName = "Start Turn";
    
    
    //This is for our score board object
    private ScoreBoard scoreBoard;    
    //This is for our dice object
    private Dice dice;
    //These are varaibles to store the state of the board    
    public integer gameStarted = 0;     
    public integer gameEnded = 0;    
    private integer diceCount = 0;
    private integer turnScore = 0;
    private integer potentialTurnScore = 0;
    private integer gameScore = 0;
    private integer passFlag = FALSE;
    private integer firstRoll = TRUE;
    //This is a non-associative list of all the players who have joined
    //Lists cant hold objects, so this is an array instead
    private array  playerList;
    private integer currentPlayer = 0;
    
    //Boolean if we should run some text actions
    private integer debug =0;
    
    //Spaces are treated weird, use a special character about the width of a space for text to line up
    private string spacer =" ";// " ";//" ";// "⠀";
    
    //When instantiated, load up the prim numbers, and clear the board
    public constructor() {
        //Get all of our prim numbers for the UI loaded
        this.loadPieces();
        this.scoreBoard = new ScoreBoard();        
        this.dice = new Dice();

        
        //Intitalize the player and score
        this.gameStarted = 0;
        this.gameEnded = 0;
        this.playerList.clear();
        this.turnScore = 0;
        this.gameScore = 0;
        this.passFlag = FALSE;
        this.firstRoll = TRUE;
        //Update UI
        this.scoreBoard.displayScore("00000");
        this.displayPlayerName(NULL_KEY);
        this.showPassButton(0);
        this.showJoinButton(1);        
        this.showStartButton(1);
        this.showPrim(0,this.startTurnPrimNumber);
        this.showPrim(0,this.endPrimNumber);
        this.showPrim(0,this.rollPrimNumber);
        this.dice.hideAllDice();
        
        this.displayBoardState();
        this.doDebug();
        
    }
    private doDebug() {

        if(!this.debug){ return;}
        
        //Set in some debug names
        names["aaaaaaaa-f958-452d-b4aa-b6fb5d5a7e49"]="Test Player One";
        names["bbbbbbbb-f958-452d-b4aa-b6fb5d5a7e49"]="Player Two Test";
        
        this.addPlayerToGame("d8f0bd49-7e05-40de-9bca-d570365ab5bb");
        this.addPlayerToGame("aaaaaaaa-f958-452d-b4aa-b6fb5d5a7e49");    
        this.addPlayerToGame("bbbbbbbb-f958-452d-b4aa-b6fb5d5a7e49");
    }
    //This is a debug method to test basic name text
    private displayPlayerName(key playerUUID) {
        string name = "";
        if(playerUUID!=NULL_KEY)
        {
            name = llKey2Name(playerUUID);
        }
        this.showText(name);
    }
    //This takes a basic string, turns it into a highlighted text setup, and makes it appear
    //Usefull if you want to ignore the bold stuff completely
    private showText(string text) {
        HighlightedText ht = new HighlightedText();
        ht.addTextLine(text,0);
        this.showTextHT(ht);
    }
    //Calls the display function on the provided ht with the proper prims we detected earlier so it can display them
    private showTextHT(HighlightedText ht)
    {
        ht.setText(this.textPrimNumber,this.textHighlightPrimNumber);
    }
    private Player getPlayer(integer num) {
        //This is just a helper function to cast our array to the player object
        return (Player)this.playerList[num];
    }
    private Player getCurrentPlayer()
    {
        return this.getPlayer(this.currentPlayer);
    }
    //Searches our player list and returns the player number if found. -1 if not
    private integer getPlayerNumber(key id){
        object playerNumbero;
        object playero;
        foreach (playerNumbero,playero in this.playerList) 
        {
            integer playerNumberi = (integer)playerNumbero;
            Player player = (Player)playero;
            if(player.getID() == id)
            {
                return playerNumberi;
            }
        } 
        return -1;
    }
    
    //In order to show strings in columns, we need to pad them with spaces to a set length so they line up
    private string getStaticLengthString(string input, integer length)    {
        //We have 3 options, input too long, right, or too short
        integer inputLength = llStringLength(input);
        if(inputLength == length) return input;
        if(inputLength < length)
        {
            //It is too shhort
            return input+this.repeateCharacterXTimes(" ",length - inputLength);
        }
        //it is too long
        return llGetSubString(input,0,length);
    }
    //This returns a string that is repeated, ex, "a",5 returns "aaaaa"
    private string repeateCharacterXTimes(string character, integer times)    {
        if(character == " ")
        {
            //pure space characters are ignored, replace with a fancy space
            character = this.spacer;
        }
        string output="";
        for(integer i  = 0; i<times; i++)
        {
            output+=character;
        }
        return output;
    }
    
    
    //Searches our player list and returns the player number if found. -1 if not
    //This returns at HighlightedText objectg which has some lines bold, this can be conbined with other HighlightedText objects later
    private HighlightedText getPlayerList(integer getScoreAndActiveIndicator) {
    
        HighlightedText ht = new HighlightedText();
        if(this.playerList.count == 0) {
            ht.addTextLine("No players added yet, please join!",0);
            return ht;
        }
        string line = "";
        //We are trying to make this a grid, so each line needs to have the same number of characters per column
        //Set up our headers with this in mind, and keep it set
        if(getScoreAndActiveIndicator){
            line+=this.getStaticLengthString("Active",7);//7 length
        }
        line+= this.getStaticLengthString("Name",15);//15 lenght
        if(getScoreAndActiveIndicator){
            line+=this.getStaticLengthString("Score",5);//5
        }
        ht.addTextLine(line,0);

        object playerNumbero;
        object playero;
        foreach (playerNumbero,playero in this.playerList) 
        {
            line="";
            integer playerNumberi = (integer)playerNumbero;
            Player player = (Player)playero;
            if(getScoreAndActiveIndicator)
            {
                if(this.currentPlayer == playerNumberi)
                {
                    line += this.getStaticLengthString("Yes",6)+this.spacer;//7 characters to line up in our column
                }else
                {
                    line += this.getStaticLengthString("",6)+this.spacer;//7 characters to line up in our column
                }
            }
            line += this.getStaticLengthString(player.getName(),14)+this.spacer;//15 total
            if(getScoreAndActiveIndicator){
                line += this.getStaticLengthString(player.getScore(),5);//no space needed after
            }            
            ht.addTextLine(line,getScoreAndActiveIndicator && (this.currentPlayer == playerNumberi));
        } 
        return ht;
    }
    //Check the current players end score, if it is high enough, end the game, update and lock the UI till reset
    private checkAndEndGame()
    {
        if( this.getCurrentPlayer().getScore() > 10000)
        {
            llSay(0,this.getCurrentPlayer().getName()+" has won the game with a score of "+ (string)this.getCurrentPlayer().getScore() );
            this.gameEnded = TRUE;
            
            this.displayBoardState();        
            this.dice.hideAllDice();
        }
    }
    
    //End of current players turn, increase saved score if any new is made, then start the next turn
    private endTurn() { 
        //incriment player score with turn scroe
        Player cp = this.getCurrentPlayer();
        cp.increaseScore(this.turnScore);
        llWhisper(0,cp.getName()+" ended their turn with an additional "+(string)this.turnScore+" points, for a total of "+(string)cp.getScore()+" points!");     

        this.checkAndEndGame();
        if(!this.gameEnded)
        {
            this.nextTurn();
        }
    }
    
    private nextTurn()    {
        //get the next player in the loop
        //Modules % is the remainder, so ex player is currently number 1 of 2 players, 
        //1 plus 1 is 2, but there is not player 2, (we only have player numbers 0 and 1), so the modulus is 2 % 2, = 0, and enforces our repeating loop
        //Next it will be 0+1 is 1, modulus 2 is still 1, so we keep going back and forth
        this.currentPlayer = (this.currentPlayer + 1) % this.playerList.count;
    
        llWhisper( 0, "It is now " + this.getCurrentPlayer().getName() + "'s turn.");
        this.turnScore = 0;
        this.firstRoll = TRUE;
        //just for testing
        if(this.debug)
        {
            this.turnScore =1;
        }
        
        this.displayBoardState();        
        this.dice.hideAllDice();
    }
    //Save the existing dice, move to next player with endturn
    private passTurn()    {
    
        //Need to first see if they selected any scoring dice
        if(!this.addSelectedDiceToScore())return;        
        this.endTurn();    
    }
    
    //Loop through all prims, record them to a class variable if they are important
    private loadPieces() {
        integer i = llGetLinkNumber() != 0; // Start at zero (single prim) or 1 (two or more prims)
        integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
        integer checkerNumber = 0;
        integer checkerKingNumber = 0;
        string primName = "";
        //Loop through all possible prim numbers x
        for (; i < x; ++i) {
            primName = llGetLinkName(i);
            if (primName == this.helpPrimName) {
                this.helpPrimNumber = i;
            } else if (primName == this.joinPrimName) {
                this.joinPrimNumber = i;
            } else if (primName == this.startPrimName) {
                this.startPrimNumber = i;
            } else if (primName == this.resetPrimName) {
                this.resetButtonPrimNumber = i;
            } else if (primName == this.textPrimName) {
                this.textPrimNumber = i;
            }else if (primName == this.passPrimName) {
                this.passPrimNumber = i;
            }else if (primName == this.rollPrimName) {
                this.rollPrimNumber = i;
            }else if (primName == this.endPrimName) {
                this.endPrimNumber = i;
            }else if (primName == this.startTurnPrimName) {
                this.startTurnPrimNumber = i;
            }else if (primName == this.textHighlightPrimName) {
                this.textHighlightPrimNumber = i;
            }
        }
    }
    //Generic function to show or hide a prim
    private showPrim(integer show, integer primNumber) {
        llSetLinkPrimitiveParamsFast(primNumber,
        [
            PRIM_COLOR, ALL_SIDES, <0.3, 0.3, 0.3>, show,
            PRIM_COLOR, 0, <1.0, 1.0, 1.0>, show
        ]);
    }
    private showPassButton(integer show) {
        //Set the link params to hide or show the alpha for the prim color, and optionally set the colors and texture
        llSetLinkPrimitiveParamsFast(this.passPrimNumber,
        [
            PRIM_COLOR, ALL_SIDES, <0.3, 0.3, 0.3>, show,
            PRIM_COLOR, 0, <1.0, 1.0, 1.0>, show
            //,PRIM_BUMP_SHINY, 2, PRIM_SHINY_HIGH, PRIM_BUMP_SHINY,
            //PRIM_TEXTURE, ALL_SIDES, "f6612da4-1568-44e5-bd44-feb2c0a46729", <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
            //PRIM_TEXTURE, 0, "00397049-6d10-48ea-945e-c1e2e2df7f2c", <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0;
        ]);
    }
    private showJoinButton(integer show) {
        //Set the link params to hide or show the alpha for the prim color, and optionally set the colors and texture
        llSetLinkPrimitiveParamsFast(this.joinPrimNumber,
        [
            PRIM_COLOR, ALL_SIDES, <0.3, 0.3, 0.3>, show,
            PRIM_COLOR, 0, <1.0, 1.0, 1.0>, show
            //,PRIM_BUMP_SHINY, 2, PRIM_SHINY_HIGH, PRIM_BUMP_SHINY,
            //PRIM_TEXTURE, ALL_SIDES, "f6612da4-1568-44e5-bd44-feb2c0a46729", <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
            //PRIM_TEXTURE, 0, "88e10d06-43b1-469e-8e02-e230dac2fab4", <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0;
        ]);
    }    
    private showStartButton(integer show) {
        //Set the link params to hide or show the alpha for the prim color, and optionally set the colors and texture
        llSetLinkPrimitiveParamsFast(this.startPrimNumber,
        [
            PRIM_COLOR, ALL_SIDES, <0.3, 0.3, 0.3>, show,
            PRIM_COLOR, 0, <1.0, 1.0, 1.0>, show
            //,PRIM_BUMP_SHINY, 2, PRIM_SHINY_HIGH, PRIM_BUMP_SHINY,
            //PRIM_TEXTURE, ALL_SIDES, "f6612da4-1568-44e5-bd44-feb2c0a46729", <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
            //PRIM_TEXTURE, 0, "3b0fca1e-cbe8-48f3-b1d3-f4ef585b1487", <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0;
        ]);
    }
    private startGame() {    
        this.gameStarted = 1;
        //Update UI and show the new buttons
        this.showPassButton(1);
        this.showJoinButton(0);
        this.showStartButton(0);
        this.showPrim(1,this.startTurnPrimNumber);
        this.showPrim(1,this.rollPrimNumber);
        
        
        this.turnScore = 0;
        this.displayBoardState();
        
        this.currentPlayer = -1;
        this.nextTurn();
    }
    //Adds a new player to our list of players
    private addPlayerToGame(key id) {
    
        //first make sure the player does not already exist in our list
        integer playerNumber = this.getPlayerNumber(id);
        if(playerNumber==-1)
        {
            Player newPlayer = new Player(id);
            this.playerList[this.playerList.count] = newPlayer;
            llWhisper(0,  newPlayer.getName() + " has joined the game!");
        }else
        {            
            llWhisper(0,  this.getPlayer(playerNumber).getName() + " has already joined the game!");
        }
        this.displayBoardState();
    }
    //This uses our display text to show who and what is going on with the board
    public displayBoardState() {
        HighlightedText ht = new HighlightedText();
        if(this.gameStarted == 0)
        {
            ht.addTextLine("Waiting for new players, game not yet started!",0);
            ht.addHighlightedText(this.getPlayerList(0));
        }
        else
        {
            ht.addTextLine("Game Started!",0);
            ht.addHighlightedText(this.getPlayerList(1));
            ht.addTextLine("Current Score This Turn is "+(string)this.turnScore,1);
            
            integer currentPlayerScore = this.getCurrentPlayer().getScore();
            //Options for what we want the prim board to show
            //this.scoreBoard.displayScore((string)this.turnScore);            //this.scoreBoard.displayScore((string)(this.turnScore+currentPlayerScore));
            this.scoreBoard.displayScore((string)currentPlayerScore);
        }
        this.showTextHT(ht);
    }
    //see if we have this many of dicenumber
    public integer countOfDiceIsEnough(array selectedDice, integer diceNumber, integer diceNeededCount)
    {
        string diceCountO = (string)selectedDice[diceNumber];
        if(diceCountO is undef)
        {
            return FALSE;
        }
        integer diceNumber = (integer)diceCountO;
        if(diceNumber<diceNeededCount)
        {
            return FALSE;
        }
        return TRUE;    
    }
    //removes this many of each dice count from our scored array
    public array subtractCount(array selectedDice, integer ones, integer twos, integer threes, integer fours, integer fives, integer sixes)
    {
        if(ones>0)
        {
            integer diceCount = (integer)selectedDice[1];
            integer newCount= diceCount - ones;
            if(newCount > 0)
            {
                selectedDice[1] = newCount;
            }else
            {
                selectedDice[1] = undef;
            }           
        }
        if(twos>0)
        {
            integer diceCount = (integer)selectedDice[2];
            integer newCount= diceCount - twos;
            if(newCount > 0)
            {
                selectedDice[2] = newCount;
            }else
            {
                selectedDice[2] = undef;
            }    
        }
        if(threes>0)
        {
            integer diceCount = (integer)selectedDice[3];
            integer newCount= diceCount - threes;
            if(newCount > 0)
            {
                selectedDice[3] = newCount;
            }else
            {
                selectedDice[3] = undef;
            }    
        }
        if(fours>0)
        {
            integer diceCount = (integer)selectedDice[4];
            integer newCount= diceCount - fours;
            if(newCount > 0)
            {
                selectedDice[4] = newCount;
            }else
            {
                selectedDice[4] = undef;
            }  
        }
        if(fives>0)
        {
            integer diceCount = (integer)selectedDice[5];
            integer newCount= diceCount - fives;
            if(newCount > 0)
            {
                selectedDice[5] = newCount;
            }else
            {
                selectedDice[5] = undef;
            }  
        }
        if(sixes>0)
        {
            integer diceCount = (integer)selectedDice[6];
            integer newCount= diceCount - sixes;
            if(newCount > 0)
            {
                selectedDice[6] = newCount;
            }else
            {
                selectedDice[6] = undef;
            }  
        }
        
        return selectedDice;    
    }
    /*This is the big function that checks and see if we have any scores
    //We use this to see if a roll ends and wipes out the players score, and also to increase their score
    //We start with the biggest things first, like strights, 6 of  a kind, etc
    //If we find a match, we increase the score, subtract thoes selected dice, and then run this function again and again untill we stop getting more score
    //Examples, 1,4,4,4
    //First loop, we hit the 3 of a kind, remove the 4s, and then run again with 1
    //Second loop, we add the 0,
    //Third loop, we exit*/
    public array calculateScoreIncrease(array selectedDice, integer speak)
    {
        if(selectedDice.count==0)return selectedDice;
        array scoredDice;
        integer scoreInc = 0;
        object diceNumbero;
        object diceCounto;
        string output = "";
        foreach (diceNumbero,diceCounto in selectedDice) 
        {
            integer diceNumber = (integer)diceNumbero;
            integer diceCount = (integer)diceCounto;
            output+="\n"+(string)diceCount+" of number "+(string)diceNumber+".";
        } 
        /*Dice________________Scores
        a single 1 _____________100
        a single 5 ______________ 50
        triple of 1's (1,1,1) ____1,000
        triple of 2's (2,2,2)______  200
        triple of 3's (3,3,3)_______300
        triple of 4's (4,4,4)______ 400
        triple of 5's (5,5,5)_______ 500
        triple of 6's (6,6,6)______  600
        four-of-a-kind (2,2,2,2)_____Multiply triple score by 2
        five-of-a-kind (3,3,3,3,3)____Multiply triple score by 4
        six-of-a-kind (4,4,4,4,4,4)__Multiply triple score by 8
        three pairs (2,2,3,3,4,4) __800
        straight (1,2,3,4,5,6) ___1,500*/
        
        integer currentPlayerScore = this.getCurrentPlayer().getScore();
        integer trippleCurrentPlayerScore = (currentPlayerScore + this.potentialTurnScore) * 3;        
        //We need this incase the score gets trippled, we are trippling their full score
        //Keep in mind, we are showing an incriment here, so we subtract the current score from our incriment
        //Example, if they have 100, and tripple it, the incriment is score * 3 - score, aka 200 incriment
        
        //Straight
        if( this.countOfDiceIsEnough(selectedDice,1,1) &&
            this.countOfDiceIsEnough(selectedDice,2,1) &&
            this.countOfDiceIsEnough(selectedDice,3,1) &&
            this.countOfDiceIsEnough(selectedDice,4,1) &&
            this.countOfDiceIsEnough(selectedDice,5,1) &&
            this.countOfDiceIsEnough(selectedDice,6,1) )
        {    
            scoreInc+=1500;
            selectedDice = this.subtractCount(selectedDice,1,1,1,1,1,1);
        }
        
        //six of a kinds
        if( this.countOfDiceIsEnough(selectedDice,1,6) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 8)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,6,0,0,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,2,6) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 8)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,6,0,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,3,6) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 8)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,6,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,4,6) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 8)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,0,6,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,5,6) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 8)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,0,0,6,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,6,6) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 8)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,0,0,0,6);
        }
        
        //five of a kinds
        if( this.countOfDiceIsEnough(selectedDice,1,5) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 4)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,5,0,0,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,2,5) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 4)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,5,0,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,3,5) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 4)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,5,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,4,5) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 4)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,0,5,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,5,5) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 4)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,0,0,5,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,6,5) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 4)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,0,0,0,5);
        }
        
        //four of a kinds
        if( this.countOfDiceIsEnough(selectedDice,1,4) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 2)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,4,0,0,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,2,4) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 2)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,4,0,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,3,4) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 2)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,4,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,4,4) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 2)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,0,4,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,5,4) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 2)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,0,0,4,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,6,4) )
        {    
            scoreInc+=(trippleCurrentPlayerScore * 2)-currentPlayerScore;
            selectedDice = this.subtractCount(selectedDice,0,0,0,0,0,4);
        }
        
        //three of a kinds
        if( this.countOfDiceIsEnough(selectedDice,1,3) )
        {    
            scoreInc+=1000;
            selectedDice = this.subtractCount(selectedDice,3,0,0,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,2,3) )
        {    
            scoreInc+=200;
            selectedDice = this.subtractCount(selectedDice,0,3,0,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,3,3) )
        {    
            scoreInc+=300;
            selectedDice = this.subtractCount(selectedDice,0,0,3,0,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,4,3) )
        {    
            scoreInc+=400;
            selectedDice = this.subtractCount(selectedDice,0,0,0,3,0,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,5,3) )
        {    
            scoreInc+=500;
            selectedDice = this.subtractCount(selectedDice,0,0,0,0,3,0);
        }
        if( this.countOfDiceIsEnough(selectedDice,6,3) )
        {    
            scoreInc+=600;
            selectedDice = this.subtractCount(selectedDice,0,0,0,0,0,3);
        }
        
        integer twosOfAKindFound = 0;
        //two of a kinds, count them but dont subtract them till the end so we dont mess up other counts
        if( this.countOfDiceIsEnough(selectedDice,1,2) )
        {    
            twosOfAKindFound++;
        }
        if( this.countOfDiceIsEnough(selectedDice,2,2) )
        {    
            twosOfAKindFound++;
        }
        if( this.countOfDiceIsEnough(selectedDice,2,3) )
        {    
            twosOfAKindFound++;
        }
        if( this.countOfDiceIsEnough(selectedDice,2,4) )
        {    
            twosOfAKindFound++;
        }
        if( this.countOfDiceIsEnough(selectedDice,2,5) )
        {    
            twosOfAKindFound++;
        }
        if( this.countOfDiceIsEnough(selectedDice,2,6) )
        {    
            twosOfAKindFound++;
        }                
        
        //three pairs (2,2,3,3,4,4) __800
        if(twosOfAKindFound==3)
        {    
            scoreInc+=800;
            selectedDice.clear();        
        }
        
        //A single 1
        if( this.countOfDiceIsEnough(selectedDice,1,1) )
        {    
            scoreInc+=100;
            selectedDice = this.subtractCount(selectedDice,1,0,0,0,0,0);
        }
        //A singly 5        
        if( this.countOfDiceIsEnough(selectedDice,5,1) )
        {    
            scoreInc+=50;
            selectedDice = this.subtractCount(selectedDice,0,0,0,0,1,0);
        }
        
        
        if(speak)llSay(0,"Calculating score increase from "+output+"\nTotal: "+(string)scoreInc);        
        if(scoreInc>0)
        {
            //we got some incriment this loop, keep recursive this scorinng until we dont get any more score            
            this.potentialTurnScore+=scoreInc;
            selectedDice = this.calculateScoreIncrease(selectedDice,0);
        }
        return selectedDice;
    }
    //Checks the user input for validity, and then increases the score,
    //This is ran when a user passes their turn, or chooses to roll again
    public integer addSelectedDiceToScore()
    {
        //Need to first see if they selected any scoring dice
        array selectedDice = this.dice.getNewSelectedDice();
        if(selectedDice.count==0)
        {
            llSay(0,"You must select some dice to save before rolling again, or pass your turn");
            return FALSE;
        }
        this.potentialTurnScore = 0;
        array remainingDice = this.calculateScoreIncrease(selectedDice,1);
        integer scoreIncriment = this.potentialTurnScore;
        if(scoreIncriment==0)
        {    
            llSay(0,"Your selected dice do not help your score, you must select scoring dice or pass your turn");        
            return FALSE;                    
        }
        //We spend some good effort instructing the user exactly what dice to remove, in order to progress through the game
        if(remainingDice.count>0)
        {    
            object diceNumbero;
            object diceCounto;
            string nonScoringOutput = "";
            foreach (diceNumbero,diceCounto in remainingDice) 
            {
                integer diceNumber = (integer)diceNumbero;
                integer diceCount = (integer)diceCounto;
                nonScoringOutput+="\n"+(string)diceCount+" of number "+(string)diceNumber+".";
            } 
            llSay(0,"Not all of your dice scored, please remove non scoring dice and try again"+nonScoringOutput);        
            return FALSE;                    
        }
        this.turnScore+=scoreIncriment;                
        return TRUE;
    
    }
    //The user has chosen to roll instead of pass, add their current score , and roll the unselected dice
    //by usesing the this.dice object
    public rollDice()
    {    
        if(!this.firstRoll)
        {
            //Need to first see if they selected any scoring dice
            if(!this.addSelectedDiceToScore())return;
        }
        if(this.debug){llSay(0,"rolling");}
        this.dice.roll(this.firstRoll);
        //See if there is potential for any dice to score, if not, end the turn and wipe their turn score!
        array unselectedDice = this.dice.getUnSelectedDice();
        integer startingCountOfDice = unselectedDice.count;
        array remainingDice = this.calculateScoreIncrease(unselectedDice,0);
        if(startingCountOfDice == remainingDice.count)
        {   
            if(this.firstRoll){
                //This is their very first roll, we are going to give them a new roll so they at least have some points
                this.rollDice();
                return;
            }
            llSay(0,"OH NO!!! NONE OF THESE DICE CAN SCORE!! You loose any points made this turn :(");  
            llPlaySound("New Fail Sound",1.0);
            this.turnScore = 0;
            this.endTurn();
            return;
        }
        
        this.firstRoll = FALSE; 
        this.displayBoardState();
    }

    //Process a touch event, figure out if anything important was clicked and act on it
    public touched(integer link, integer face, vector touchST, key who) {
        //llSay(0,"touched link:"+(string)link+" face:"+(string)face+" ST:"+(string)touchST+" who:"+(string)who);
        //Frame touch, no longer used    //if(link == this.boardPrimNumber && (face!=0) && (face != 2))
        //If they clicked the prim number (link) that we have saved as the reset button, reset
        
        //Preproccess if the game is started, if the clicker is the current player
        integer currentPlayerDidTheClick=0;
        integer canStart = (this.playerList.count>0);
        if(canStart){
            currentPlayerDidTheClick=(this.gameStarted && this.getCurrentPlayer().getID()==who);
        }
        integer aJoinedPlayerDidTheClick=0; (this.getPlayerNumber(who)!=-1);

        //in debug mode, just act like we are always valid
        if(this.debug)
        {
            currentPlayerDidTheClick = 1;
            aJoinedPlayerDidTheClick = 1;
        }
        if (link == this.resetButtonPrimNumber) {              
            llPlaySound("NEW selection click", 1); 
            llSleep(.4);
            llResetScript();
        }
        if(this.gameEnded){
            return;
        }
        if (link == this.helpPrimNumber) {            
            llGiveInventory(who, "Greedy Dice Instructions");
        }     
        else if (link == this.passPrimNumber) {          
                 
            llPlaySound("NEW selection click", 1); 
            if(currentPlayerDidTheClick)
            {
                this.passTurn();
            }
        }else if (link == this.joinPrimNumber) {   
            //only alolowing joining when the game is not in progress
            if(this.gameStarted ==0) {
                llPlaySound("NEW selection click", 1); 
                this.addPlayerToGame(who);
            }
        }else if (link == this.startPrimNumber) {      
            if(this.gameStarted ==0 && canStart) {        
                llPlaySound("NEW selection click", 1); 
                this.startGame();
            }
        }     
        else if (link == this.rollPrimNumber) {          
                 
            llPlaySound("NEW selection click", 1); 
            if(currentPlayerDidTheClick)
            {
                this.rollDice();
            }
        }else
        {
            //check if a dice was clicked, process it seperatly in the object
            if(currentPlayerDidTheClick)
            {
                this.dice.processSelectedPrim(link);
            }
        }
    }
}
default
{
    state_entry()
    {
        board = new Board();
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
}


