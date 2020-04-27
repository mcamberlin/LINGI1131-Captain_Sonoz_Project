functor
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
in

   %%%% Style of game %%%%

      IsTurnByTurn = false

   %%%% Description of the map %%%%

      NRow = 10
      NColumn = 10

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

   %%%% Players description %%%%

      NbPlayer = 2
      Players = [player018basic player018medium]
      Colors = [orange black]
      MaxDamage = 5

   %%%% Surface time/turns %%%%

      TurnSurface = 1

   %%%% Number of load for each item %%%%

      Missile = 2
      Mine = 2
      Sonar = 2
      Drone = 2

   %%%% Distances of placement %%%%

      MinDistanceMine = 1
      MaxDistanceMine = 2
      MinDistanceMissile = 1
      MaxDistanceMissile = 4

   %%%% Thinking parameters (only in simultaneous) %%%%

      ThinkMin = 50
      ThinkMax = 100

   %%%% Waiting time for the GUI between each effect %%%%

      GUIDelay = 500 %ms

end
