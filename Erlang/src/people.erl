-module(people).
-export([spawn_people/6]).
-include("includes.hrl").
%% {@date}{@time}
%%
%% @doc Spawn the people that will be used in the simulation. 
%%
%% @param State The current state that you would like to add people to. Will be empty most of the time.
%% @param Amount The amount of people that you would like to spawn.
%% @param Movement_behaviour The behaviour the individuals will have when moving. 
%% path will make them move between three random points using the A*-algorithm.
%% bounce will make them bounce in a "natural way" when encodeuntering an obstacle.
%% bounce_random will make them bounce in a random direction. 
%% @param Starting_life How many 'ticks' an individual will continue to run after being infected.
%% @param Vaccine_status Whether or not vaccination should be possible.
%% @param Map_info Information about the map.
%%
%% @returns A state with Amount number of people with their status set to healthy. 
%%
-spec spawn_people(State :: state(), Amount :: integer(), Movement_behaviour :: atom(), Starting_life :: non_neg_integer(), Vaccine_status :: atom(), Map_info :: {[integer()], non_neg_integer(), non_neg_integer(), map(), map()}) -> state().
spawn_people(State, 0, _, _, _, _) ->
    State;

spawn_people(State, Amount, path, Starting_life, Vaccine_status, Map_info) ->
    Processes = erlang:system_info(logical_processors_available),
    {Map_name, Width, Height, Walls, Hospital} = Map_info,
    adj_map:adj_map(Map_name, {Width, Height, Walls, Hospital}),                    
    F = fun({X1, Y1}, {X2, Y2}) -> abs(X1 - X2) + abs(Y1 - Y2) end, %%%%NOT OURS
    G = graph:import("data/"++Map_name++".adjmap", fun parse/1), %%%%%NOT OURS 
    Spawned_processes = spawn_pathfinding(Amount, 0, Amount div Processes, Amount rem Processes, {Width, Height}, G, F),
    Paths = receive_paths(Spawned_processes, []),

      
    spawn_people_aux(State, Amount, Paths, Starting_life, Vaccine_status, G, F);
            
spawn_people(State, Amount, Movement_behaviour, Starting_life, Vaccine_status, Map_info) ->
    {_, X_max, Y_max, _, _} = Map_info, 
    Direction = movement:generate_direction(),
    {X, Y} = movement:generate_position({X_max, Y_max}),
    PID = spawn(fun() -> people(?HEALTHY, Starting_life, Starting_life, Movement_behaviour, {{X, Y}, Direction, {X_max, Y_max}}, Vaccine_status) end),
    spawn_people(State ++ [{PID, ?HEALTHY, X, Y}], Amount-1, Movement_behaviour, Starting_life, Vaccine_status, Map_info).

%%
%% @doc Spawn processes to run pathfinding in paralell
%%
%% @param Amount_of_people_left_to_spawn the number of people to spawn
%% @param Processes number of processes spawned
%% @param Load the number of paths a spawned process should spawn
%% @param Rem additional load for each process
%% @param Bounds The map bounds
%% @param G graph representing the map
%% @param F fun
%%
%% @returns number of processes spawned
-spec spawn_pathfinding(Amount_of_people_left_to_spawn :: integer(), Processes :: integer(), Load :: integer(), Rem :: integer(), Bounds :: bounds(), G :: position(), F :: function()) -> non_neg_integer().
spawn_pathfinding(0, Processes, _, _, _,_,_) ->
    Processes;
spawn_pathfinding(Amount_of_people_left_to_spawn,Processes, Load, Rem, Bounds, G, F) ->
    case Rem > 0 of
        true ->
            spawn(fun()->make_path(Load + 1 , Bounds, G, F, []) end),
            spawn_pathfinding(Amount_of_people_left_to_spawn - Load -1, Processes+1, Load, Rem-1, Bounds, G, F);
        _ ->
            spawn(fun()->make_path(Load , Bounds, G, F, []) end),
            spawn_pathfinding(Amount_of_people_left_to_spawn - Load, Processes+1, Load, Rem, Bounds, G, F)
    end.

%%
%% @doc Receive paths from processes that calculate them and when all processes are finished return the paths
%%
%% @param Amount the number of processes
%% @param Paths the so far received paths
%%
%% @returns The received paths
-spec receive_paths(Amount :: non_neg_integer(), Paths :: path()) -> path().
receive_paths(0, Paths) ->
    Paths;

receive_paths(Amount, Paths) ->
    receive
        {paths, P} ->
            ok
    end,
    receive_paths(Amount-1, P ++ Paths).



%%
%% @doc Spawns people that will walk between three random points.
%%
%% @param State The state that you will add the people to.
%% @param Amount The amount of people that you would like to spawn.
%% @param Map_name The name of the map that you are using.
%% @param Bounds The bounds of the map.
%% @param Starting_life How much life that the processes will start with.
%% @param Vaccine_status Whether or not vaccination should be possible.
%% @param G The adjency map that you will use.
%% @param F A function that calculates the distance between 2 points.
%%
%% @returns The new state. 
%%


spawn_people_aux(State, 0, _, _, _, _, _) ->
    State;

spawn_people_aux(State, Amount, [Path | Path_list], Starting_life, Vaccine_status, G, F) ->               
            PID = spawn(fun() -> people(?HEALTHY, Starting_life, Starting_life, path, {Path, []}, Vaccine_status) end),
            [{X , Y} | _ ] = Path,
            spawn_people_aux(State ++ [{PID, ?HEALTHY, X, Y}], Amount-1, Path_list, Starting_life, Vaccine_status, G, F).
    


make_path(0, _, _, _, Result) ->
    master ! {paths, Result};

make_path(Amount, Bounds, G, F, Result) ->
 [P1, P2, P3] = [movement:generate_position(Bounds), movement:generate_position(Bounds), movement:generate_position(Bounds)],
    Result_1 =  a_star:run(G, P1, P2, F),
    Result_2 = a_star:run(G, P2, P3, F),
    Result_3 = a_star:run(G, P3, P1, F),
    case (Result_1 =:= unreachable) orelse (Result_2 =:= unreachable) orelse (Result_3 =:= unreachable) of
        true -> 
            make_path(Amount, Bounds, G, F, Result);    
        false ->
            {_, Path_1} = Result_1,
            {_, Path_2} = Result_2,
            {_, Path_3} = Result_3,
            Paths = Path_1 ++ (Path_2 ++ Path_3),     
            make_path(Amount-1, Bounds, G, F, [Paths | Result])
    end.

%%
%% @doc Loop untill it receives the atom stop. The process will update X and Y with a new random position
%% and send a tagged tuple with its new position and its pid to the registred processes master if it receives the atom ready. 
%% If a process becomes infected it will die after Life number of 'ticks' 
%% 
%% @param Status the new state of the person. Representing the health of the person.
%% @param Life How many 'ticks' an individual will continue to run after being infected.
%% @param Starting_life How much Life the individual had when it spawned
%% @param Movement_behaviour The behaviour the individuals will have when moving.
%% @param Movement_args The arguments the individual will use when moving
%% @param Vaccine_status Whether or not vaccination should be possible.
%%
%% @returns done
%%
-spec people(Status :: status(), Life :: non_neg_integer(), Starting_life :: non_neg_integer(), Bounce_behaviour :: atom(),
             Movement_args :: {position(), direction(), bounds()} | {pos_list(), pos_list()}, Vaccine_status :: atom()) -> done.
people(Status, Life, Starting_life, path, {[], Paths_visited}, Vaccine_status) ->
    people(Status, Life, Starting_life, path, {lists:reverse(Paths_visited),[]}, Vaccine_status);

people(Status, Life, Starting_life, Movement_behaviour, Movement_args, Vaccine_status) ->
    receive
        ready ->
            case Movement_behaviour of
                path ->
                    {Paths, Paths_visited} = Movement_args,
                    [{X_new, Y_new}|Remaining_paths] = Paths,
                    New_movement_args = {Remaining_paths, [{X_new, Y_new} | Paths_visited]};
                _ ->
                    {{X, Y}, Direction, Bounds} = Movement_args,
                    case Movement_behaviour of
                        bounce ->
                            {X_new, Y_new, Direction_new} = movement:new_bounce_position(X,Y,Direction,Bounds); % Get new position          
                        bounce_random->
                            {X_new, Y_new, Direction_new} = movement:new_bounce_random_position(X,Y,Direction,Bounds)   
                    end,
                    New_movement_args = {{X_new, Y_new}, Direction_new, Bounds}
            end,

            master ! {work, {self(), Status, X_new, Y_new}, Life},      

            case Vaccine_status of

                off -> 
                     people(Status, Life - status_check(Status), Starting_life, Movement_behaviour, New_movement_args, Vaccine_status); %if process infected, decrease Life
                on ->
                    case(collision_checker:check_collision(h_checker,X_new,Y_new)) of
                        true ->	                   
                            people(?IMMUNE, Life, Starting_life, Movement_behaviour, New_movement_args, Vaccine_status);
                        _ ->                       
                            people(Status, Life - status_check(Status), Starting_life, Movement_behaviour, New_movement_args, Vaccine_status) %if process infected, decrease Life
                    end
            end;

        {infect_people, Probability, Targets} ->
            [PID ! get_infected || (rand:uniform())=<Probability, PID <- Targets], % Try to infect processes in its proximity

            people(Status, Life, Starting_life, Movement_behaviour, Movement_args, Vaccine_status);            

        get_infected ->
            case Status of
                ?IMMUNE ->
                    people(Status, Life, Starting_life, Movement_behaviour, Movement_args, Vaccine_status);
                _ ->
                    people(?INFECTED, Life, Starting_life, Movement_behaviour, Movement_args, Vaccine_status) %Change status to infected
            end;
        get_vaccinated ->            
                    people(?IMMUNE, Life, Starting_life, Movement_behaviour, Movement_args, Vaccine_status); %Change status to immune 
        stop ->
            done
    end.

%%
%% @doc Parse a string representation of a tuple with two integers.
%%
%% @param S The string to parse.
%%
%% @returns An Erlang tuple with the two integers from the string.
%%
-spec parse(S :: [non_neg_integer()]) -> {integer(),integer()}.
parse(S) ->
    [M, N] = string:tokens(S, "(),"),
    {O,_} = string:to_integer(M),
    {P,_} = string:to_integer(N),
    {O, P}.

%%
%% @doc Check the status of a proccess to see how much life it should loose after an iteration.
%%
%% @param The status to check.
%%
%% @returns How much life the process should loose. 
%%
-spec status_check(Status :: integer()) -> 0 | 1.
status_check(Status) ->
if
   Status == ?IMMUNE -> 0;
   Status == ?INFECTED -> 1;
   true -> 0
end. 


%% spawn_people_aux(State, 0, _, _, _, _, _, _) ->
%%     State;

%% spawn_people_aux(State, Amount, Map_name, Bounds, Starting_life, Vaccine_status, G, F) ->
%%     [P1, P2, P3] = [movement:generate_position(Bounds), movement:generate_position(Bounds), movement:generate_position(Bounds)],
%%     Result_1 =  a_star:run(G, P1, P2, F),
%%     Result_2 = a_star:run(G, P2, P3, F),
%%     Result_3 = a_star:run(G, P3, P1, F),
%%     case (Result_1 =:= unreachable) orelse (Result_2 =:= unreachable) orelse (Result_3 =:= unreachable) of
%%         true ->
%%             spawn_people_aux(State, Amount, Map_name, Bounds, Starting_life, Vaccine_status, G, F);
%%         false->
%%             {_, Path_1} = Result_1,
%%             {_, Path_2} = Result_2,
%%             {_, Path_3} = Result_3,
%%             Paths = Path_1 ++ (Path_2 ++ Path_3),           
%%             PID = spawn(fun() -> people(?HEALTHY, Starting_life, Starting_life, path, {Paths, []}, Vaccine_status) end),
%%             [{X , Y} | _ ] = Paths,
%%             spawn_people_aux(State ++ [{PID, ?HEALTHY, X, Y}], Amount-1,  Map_name, Bounds, Starting_life, Vaccine_status, G, F)
%%     end.
