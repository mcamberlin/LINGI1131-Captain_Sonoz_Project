functor
import OS
export
   %%%% description of the map %%%%
      nRow:NRow
      nColumn:NColumn
      map:Map % Array of {0;1} ; 0 = water; 1 = island
      
   %%%% Players %%%%
      nbPlayer:NbPlayer
      players:Players %describe the type of player: AI or Human
      colors:Colors
      maxDamage:MaxDamage %max damage before the submarine is destroyed
      
   %%%% loading parameters %%%%
      missile:Missile
      mine:Mine
      sonar:Sonar
      drone:Drone

   %%%% Bounds of distances for weapons according to Manhattan distances: D = |x1 - x2| + |y1-y2| %%%%
      minDistanceMine:MinDistanceMine
      maxDistanceMine:MaxDistanceMine
      minDistanceMissile:MinDistanceMissile
      maxDistanceMissile:MaxDistanceMissile

   %%%% Thinking parameters (for simultaneous mode only) %%%%
      thinkMin:ThinkMin %minimum time [ms] used when thinking
      thinkMax:ThinkMax %maximum time [ms] used when thinking
      
   %%%% Others %%%%
      isTurnByTurn:IsTurnByTurn %true = turn-by-turn mode; false = simultaneous mode
      turnSurface:TurnSurface %the number of turns (in turn-by-turn mode) or the number of seconds (in simultaneous mode) the submarine has to wait before continuing playing 
      guiDelay:GUIDelay %time between each GUI effects

define
   IsTurnByTurn

   NRow
   NColumn
   Map

   NbPlayer
   Players
   Colors
   MaxDamage
   
   TurnSurface
   
   Missile
   Mine
   Sonar
   Drone

   MinDistanceMine
   MaxDistanceMine
   MinDistanceMissile
   MaxDistanceMissile

   ThinkMin
   ThinkMax

   GUIDelay

   fun{MapGenerator NRow NColumn}
      fun{LineGenerator Acc Islands}
         if(Acc=<NRow *NColumn) then
               {Contains Acc Islands} | {LineGenerator Acc+1 Islands}            
         else
               nil
         end
      end

      /**
      @pre 
         return a list of random number representing
      */
      fun{ListIsland NIslands}
         if(NIslands >0) then
               Pos in 
                  Pos = {OS.rand}  mod (NRow * NColumn) 
                  if(Pos == 0) then 
                     1| {ListIsland NIslands -1}
                  else
                     Pos|{ListIsland NIslands-1}
                  end
         else
               nil
         end
      end
      
      fun{Contains Pos Islands}
         case Islands
         of H |T then 
               if(H == Pos) then
                  1
               else
                  {Contains Pos T}
               end
         else
               0
         end 
      end
      
      fun{Append L I}
         case L 
         of H|nil then
               local L1 in
                  L1 = H|I
                  L1 | {Append nil I}
               end
         []H|T then
               H|{Append T I}
         else
               nil
         end
      end


      fun{LineToMatrix LL AccX L}
         fun{Append L I}
               case L 
               of H|nil then
                  H|I|{Append nil I}

               []H|T then
                  H|{Append T I}
               else
                  nil
               end
         end
      in
         case LL
         of H|T then
               if(AccX == 1) then
                  {LineToMatrix T AccX+1 H}
               elseif(AccX ==2) then
                  {LineToMatrix T AccX+1 {Append [L] H}}
               elseif(AccX <NRow) then
                  {LineToMatrix T AccX+1 {Append L H}}
               else%if(AccX == NRow) then
                  {Append L H} | {LineToMatrix T 1  1}
               end
         else
               nil
         end
      end
      
      NIslands
      Islands
      LongList
      Ratio
   in
      Ratio = 0.10 % The approximative ratio of islands on the map (Ratio = numberOfIsland/(NRow*NColumn))
      NIslands = NIslands = {FloatToInt {IntToFloat NRow}  * {IntToFloat NColumn} * Ratio } %by default 10 percent of the map is an island
      Islands = {ListIsland NIslands}

      LongList = {LineGenerator 1 Islands}

      {LineToMatrix LongList 1 1}
   end

in

   %%%% Style of game %%%%

      IsTurnByTurn = true

   %%%% Description of the map %%%%

      NRow = 15
      NColumn = 10

      /*
      Map = [[0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 1 1 0 0 0 0 0]
      [0 0 1 1 0 0 1 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 1 0 0 1 1 0 0]
      [0 0 1 1 0 0 1 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]
      [0 0 0 0 0 0 0 0 0 0]]
      */
      Map = {MapGenerator NColumn NRow}



   %%%% Players description %%%%
      NbPlayer = 4
      Players = [player018basic player018basic player018medium player018hard]
      Colors = [white yellow orange red]
      MaxDamage = 5

   %%%% Surface time/turns %%%%

      TurnSurface = 2

   %%%% Number of load for each item %%%%

      Missile = 1
      Mine = 2
      Sonar = 1
      Drone = 1

   %%%% Distances of placement %%%%

      MinDistanceMine = 1
      MaxDistanceMine = 2
      MinDistanceMissile = 1
      MaxDistanceMissile = 6

   %%%% Thinking parameters (only in simultaneous) %%%%

      ThinkMin = 50
      ThinkMax = 100

   %%%% Waiting time for the GUI between each effect %%%%

      GUIDelay = 500 %ms

end
